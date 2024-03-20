#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main() {
    char *data1 = NULL;
    printf("Please input username: ");
    size_t size = 0;
    ssize_t chars_read = getline(&data1, &size, stdin);
    if (chars_read == -1) {
        fprintf(stderr, "Error reading input.\n");
        exit(EXIT_FAILURE);
    }
    data1[strcspn(data1, "\n")] = '\0';
    printf("You entered: [%s]\n", data1);
    free(data1); 
    return 0;
}
