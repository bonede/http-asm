#include <string.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netdb.h>
#include <stdio.h>

// int foo(int x){
//     return x + 2;
// }
// struct addrinfo *foo;
extern int x;
void foo();
int main(){
    // printf("sizeof addrinfo: %d\n", sizeof(struct addrinfo));
    // printf("sizeof int: %d\n", sizeof(int));
    // printf("sizeof socklen_t: %d\n", sizeof(socklen_t));
    // printf("sizeof char *ai_canonname: %d\n", sizeof(char *));
    // struct addrinfo *res;
    // struct addrinfo addr;
   
    // getaddrinfo((char *) 1, (char *)2, (struct addrinfo *) 3, (struct addrinfo **)4);
    // printf("res->ai_flags: %d\n", res->ai_flags);
    // int x = ***(int ***) argc;
    // if(argc == 0){
    //     foo();
    // }else{
    //     bar();
    // }

    // print_int_ptr((int *)1);

    // setsockopt(1, 2, 3, (void *)4, sizeof(int));
    // foo(2);
    if(x < 65535){
        foo();
    }
}