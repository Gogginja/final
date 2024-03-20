#include <stdio.h>
#include <stdlib.h>

int global_initialized_var = 5;
int global_uninitialized_var;

int main() {
    int local_var = 10;
    int *dynamic_var = malloc(sizeof(int) * 5);

    printf("Address of initialized global variable: %p\n", &global_initialized_var);
    printf("Address of uninitialized global variable: %p\n", &global_uninitialized_var);
    printf("Address of local variable: %p\n", &local_var);
    printf("Address of dynamically allocated variable: %p\n", dynamic_var);

    free(dynamic_var);
    return 0;
}
