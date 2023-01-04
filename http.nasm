; NASM assembler Version
%define AF_INET          2
%define SOCK_STREAM      1
%define AI_PASSIVE       1
%define SOL_SOCKET       1
%define SO_REUSEADDR     2
%define CLIENT_ADDR_LEN  16
%define BUFF_LEN         65535
%define ADDR_INFO_SIZE   48

; Functions provided by glibc
extern getaddrinfo
extern exit
extern perror
extern socket
extern setsockopt
extern bind
extern listen
extern accept
extern recv
extern send
extern close
; Debuger functions in io.c
extern print_int_ptr
extern print_int

global main

section .text
main:
    push rbp
    mov  rbp, rsp

    mov  edi, http_ip    ; getaddrinfo(&http_ip, &http_port, &addr_hint, &&addr)
    mov  esi, http_port
    mov  edx, addr_hint
    mov  ecx, addr_ptr
    call getaddrinfo

    mov  edi, eax        ; assert_no_error()
    mov  esi, getaddrinfo_error_msg
    call assert_no_error

    mov  edi, AF_INET     ; socket(AF_INET, SOCK_STREAM, 0);
    mov  esi, SOCK_STREAM
    mov  edx, 0
    call socket
    mov  [socket_fd], eax   ; store socket_fd in global

    mov  edi, eax           ; assert_no_error()
    mov  esi, socket_error_msg
    call assert_no_error_n1

    mov  edi, [socket_fd]    ; setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, &option, sizeof(option));
    mov  esi, SOL_SOCKET
    mov  edx, SO_REUSEADDR
    mov  ecx, socket_option
    mov  r8d, 4
    call setsockopt

    mov  edi, eax            ; assert_no_error()
    mov  esi, setsockopt_error_msg
    call assert_no_error


    mov  edi, [socket_fd]  ; bind(socket_fd, addr_ptr->ai_addr, addr_ptr->ai_addrlen)
                       
    mov  eax, [addr_ptr]   ;  (* addr_ptr).ai_addr a.k.a addr_ptr->ai_addr
    mov  rax, [0x18 + rax]
    mov  rsi, rax

    mov  eax, [addr_ptr]   ; addr_ptr->ai_addrlen
    mov  edx, [0x10 + rax]
    call bind

    mov  edi, eax            ; assert_no_error()
    mov  esi, bind_error_msg
    call assert_no_error

    mov  edi, [socket_fd]    ; listen(socket_fd, socket_backlog)
    mov  esi, [socket_backlog]
    call listen

    mov  edi, eax            ; assert_no_error()
    mov  esi, listen_error_msg
    call assert_no_error

start_accept:
    mov  edi, [socket_fd]    ; accept(socket_fd, &client_addr, &client_addr_len)
    mov  esi, client_addr
    mov  edx, client_addr_len
    call accept
    mov  [client_fd], eax,   ; store client_fd in gloabl

    mov  edi, eax            ; assert_no_error()
    mov  esi, accept_error_msg
    call assert_no_error_n1

start_recv:
    mov  edi, [client_fd]     ; recv(client_fd, &buf, buf_len, flags);
    mov  esi, buff
    mov  edx, BUFF_LEN
    mov  ecx, 0
    call recv
    mov  [recieved_len], eax 


    mov  edi, eax            ; assert_no_error()
    mov  esi, recv_error_msg
    call assert_no_error_n1

    mov  edi, [recieved_len]
    xor  eax, eax
    cmp  edi, eax
    je   handle_client_close

    mov  eax, [recieved_len]  ; recv until nothing to recv
    cmp  eax, BUFF_LEN
    jg   start_recv
    
    mov  edi, [client_fd]     ; send(client_fd, &buff, buff_len, flags)
    mov  esi, http_resp
    mov  edx, [http_resp_len]
    mov  ecx, 0
    call send
    mov  [sent_len], eax

    mov  edi, eax            ; assert_no_error()
    mov  esi, send_error_msg
    call assert_no_error_n1

    ; TODO handle partial sent
    mov  edi, [client_fd]    ; close(client_fd)
    call close

    jmp start_accept
    
    mov edi, [socket_fd]     ; close(socket_fd)
    call close 

    mov  eax, 0
    pop  rbp
    ret

assert_no_error: ; assert_no_error(int return_code, char* msg)
    ; return_code != 0 error
    push rbp
    mov  rbp, rsp
    mov  [rbp - 4], edi
    mov  [rbp - 8], esi
    xor  eax, eax
    cmp  eax, edi
    jne  error
    pop  rbp
    ret

assert_no_error_n1: ; assert_no_error_n1(int return_code, char* msg)
    ; return_code == -1 error
    push rbp
    mov  rbp, rsp
    mov  [rbp - 4], edi
    mov  [rbp - 8], esi
    cmp  edi, -1
    je   error
    pop  rbp
    ret

error:
    mov  edi, [rbp - 8]
    call perror
    mov  edi, [rbp - 4]
    call exit
    pop  rbp
    ret

handle_client_close:
    pop  rbp
    ret

section .rodata
getaddrinfo_error_msg:
    db "getaddrinfo() error", 0
socket_error_msg:
    db "socket() error", 0
setsockopt_error_msg:
    db "setsockopt() error", 0
bind_error_msg:
    db "bind() error", 0
listen_error_msg:
    db "listen() error", 0
accept_error_msg:
    db "accept() error", 0
recv_error_msg:
    db "recv() error", 0
send_error_msg:
    db "send() error", 0
http_port:
    db "8080", 0
http_ip:
    db "127.0.0.1", 0
addr_hint:              ; sizeof(struct addrinfo) = 48
    dd AI_PASSIVE       ; ai_flags = AI_PASSIVE
    dd AF_INET          ; ai_family = AF_INET
    dd SOCK_STREAM      ; ai_socktype = SOCK_STREAM
    times 64 - $+addr_hint db 0
socket_option:
    dd 1
socket_backlog:
    dd 10
http_resp:
    db `HTTP/1.1 200 OK\nContent-Length: 15\nContent-Type: text/plain\r\n\r\nHello assembly!`
http_resp_len:
    dd $ - http_resp

section .data
client_addr_len:
    dd CLIENT_ADDR_LEN

section .bss
addr_ptr:
    resq 1
socket_fd:
    resd 1
client_fd:
    resd 1
client_addr:
    resb 16
buff:
    resb 65535
recieved_len:
    resd 1
sent_len:
    resd 1