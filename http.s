# GNU assembler Version
.set AF_INET, 2
.set SOCK_STREAM, 1
.set AI_PASSIVE, 1
.set SOL_SOCKET, 1
.set SO_REUSEADDR, 2
.set CLIENT_ADDR_LEN, 16
.set BUFF_LEN, 65535

.global main

.text
main:
    push %rbp
    mov  %rsp, %rbp

    mov  $http_ip, %edi     # getaddrinfo(&http_ip, &http_port, &addr_hint, &&addr)
    mov  $http_port, %esi
    mov  $addr_hint, %edx
    mov  $addr_ptr, %ecx
    call getaddrinfo

    mov  %eax, %edi         # assert_no_error()
    mov  $getaddrinfo_error_msg, %esi
    call assert_no_error

    mov  $AF_INET, %edi     # socket(AF_INET, SOCK_STREAM, 0);
    mov  $SOCK_STREAM, %esi
    mov  $0, %edx
    call socket
    mov  %eax, socket_fd    # store socket_fd in global
    
    mov  %eax, %edi         # assert_no_error()
    mov  $socket_error_msg, %esi
    call assert_no_error_n1

    mov  socket_fd, %edi    # setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, &option, sizeof(option));
    mov  $SOL_SOCKET, %esi
    mov  $SO_REUSEADDR, %edx
    mov  $socket_option, %ecx
    mov  $4, %r8d
    call setsockopt

    mov  %eax, %edi         # assert_no_error()
    mov  $setsockopt_error_msg, %esi
    call assert_no_error

    mov  socket_fd, %edi    # bind(socket_fd, addr_ptr->ai_addr, addr_ptr->ai_addrlen)

    mov  addr_ptr, %eax
    mov  0x18(%rax), %rax
    mov  %rax, %rsi

    mov  addr_ptr, %eax
    mov  0x10(%rax), %edx
    
    call bind
    
    mov  %eax, %edi         # assert_no_error()
    mov  $bind_error_msg, %esi
    call assert_no_error

    mov  socket_fd, %edi    # listen(socket_fd, socket_backlog)
    mov  socket_backlog, %esi
    call listen

    mov  %eax, %edi         # assert_no_error()
    mov  $listen_error_msg, %esi
    call assert_no_error
start_accept:
    mov  socket_fd, %edi    # accept(socket_fd, &client_addr, &client_addr_len)
    mov  $client_addr, %esi
    mov  $client_addr_len, %edx
    call accept
    mov  %eax, client_fd    # store client_fd in gloabl

    mov  %eax, %edi         # assert_no_error()
    mov  $accept_error_msg, %esi
    call assert_no_error_n1

start_recv:
    mov  client_fd, %edi    # recv(client_fd, &buf, buf_len, flags);
    mov  $buff, %esi
    mov  $BUFF_LEN, %edx
    mov  $0, %ecx
    call recv
    mov  %eax, recieved_len
    
    mov  %eax, %edi         # assert_no_error()
    mov  $recv_error_msg, %esi
    call assert_no_error_n1

    mov  recieved_len, %edi
    xor  %eax, %eax
    cmp  %eax, %edi
    je   handle_client_close

    mov  recieved_len, %eax  # recv until nothing to recv
    cmp  $BUFF_LEN, %eax
    jg   start_recv

    mov  client_fd, %edi     # send(client_fd, &buff, buff_len, flags)
    mov  $http_resp, %esi
    mov  http_resp_len, %edx
    mov  $0, %ecx
    call send
    mov  %eax, sent_len

    mov  %eax, %edi          # assert_no_error()
    mov  $send_error_msg, %esi
    call assert_no_error_n1

    # TODO handle partial sent
    
    mov  client_fd, %edi     # close(client_fd)
    call close

    jmp start_accept

    mov socket_fd, %edi      # close(socket_fd)
    call close 

    mov  $0, %eax
    pop  %rbp
    ret

assert_no_error: # assert_no_error(int return_code, char* msg)
    # return_code != 0 error
    push %rbp
    mov  %rsp, %rbp
    mov  %edi, -0x4(%rbp)
    mov  %esi, -0x8(%rbp)
    xor  %eax, %eax
    cmp  %eax, %edi
    jne  error
    pop  %rbp
    ret

assert_no_error_n1: # assert_no_error_n1(int return_code, char* msg)
    # return_code == -1 error
    push %rbp
    mov  %rsp, %rbp
    mov  %edi, -0x4(%rbp)
    mov  %esi, -0x8(%rbp)
    cmp  $-1, %edi
    je   error
    pop  %rbp
    ret

error:
    mov  -0x8(%rbp), %edi
    call perror
    mov  -0x4(%rbp), %edi
    call exit
    pop  %rbp
    ret

handle_client_close:
    pop  %rbp
    ret
    
.section .rodata
msg:
    .asciz "Hello, world\n"
getaddrinfo_error_msg:
    .asciz "getaddrinfo() error"
socket_error_msg:
    .asciz "socket() error"
setsockopt_error_msg:
    .asciz "setsockopt() error"
bind_error_msg:
    .asciz "bind() error"
listen_error_msg:
    .asciz "listen() error"
accept_error_msg:
    .asciz "accept() error"
recv_error_msg:
    .asciz "recv() error"
send_error_msg:
    .asciz "send() error"
http_port:
    .asciz "8080"
http_ip:
    .asciz "127.0.0.1"
addr_hint:              # sizeof(struct addrinfo) = 48
    .int AI_PASSIVE     # ai_flags = AI_PASSIVE
    .int AF_INET        # ai_family = AF_INET
    .int SOCK_STREAM    # ai_socktype = SOCK_STREAM
    .fill 48 - 12, 1, 0
socket_option:
    .int 1
socket_backlog:
    .int 10
http_resp:
    .ascii "HTTP/1.1 200 OK\nContent-Length: 15\nContent-Type: text/plain\r\n\r\nHello assembly!"
http_resp_len:
    .int . - http_resp
.data
addr_ptr:
    .long 0
socket_fd:
    .int 0
client_fd:
    .int 0
client_addr:
    .fill 16, 1, 0
client_addr_len:
    .int CLIENT_ADDR_LEN
buff:
    .fill 65535, 1, 0
recieved_len:
    .int 0
sent_len:
    .int 0


