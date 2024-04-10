#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>

int main(int argc, char *argv[]) {
    struct stat statBuf;

    if (argc < 2) {
        printf ("Usage: argument (filename) expected\n");
        exit(1);
    }

    if (stat(argv[1], &statBuf) < 0) {
        perror ("Program error: ");
        exit(1);
    }

    printf("value is: %u\n", statBuf.st_mode);
    printf("inode value is: %lu\n", statBuf.st_ino);
    if (S_ISDIR(statBuf.st_mode))
        printf("%s is a directory.\n", argv[1]);
    else
        printf("%s is not a directory.\n", argv[1]);

    return 0;
}
