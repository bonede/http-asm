AS=as
CC=gcc
NASM=nasm
GNU_BIN=http
NASM_BIN=http-nasm

gnu: main.o io.o
	$(CC) -no-pie -o $(GNU_BIN) main.o io.o

nasm: main-nasm.o io.o
	$(CC) -no-pie -o $(NASM_BIN) main-nasm.o io.o

io.o: io.c
	$(CC) -no-pie -c -o io.o io.c

main.o: http.s
	$(AS) -no-pie -o main.o http.s

main-nasm.o: http.nasm
	$(NASM) -f elf64 -o main-nasm.o http.nasm

example: example.o
	$(CC) -no-pie -c -o example.o example.c && objdump -d example.o

clean:
	rm main.o io.o $(GNU_BIN) $(NASM_BIN) main-nasm.o example.o example
	