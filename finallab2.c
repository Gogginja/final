#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>

int main(int argc, char *argv[])
{
    struct flock fileLock;
    int fd;
    char buf[1024];

    if (argc < 2) {
        printf("usage: filename\n");
        exit(1);
    }

    if ((fd = open(argv[1], O_RDONLY)) < 0) {
        perror("Open failed");
        exit(1);
    }

    fileLock.l_type = F_RDLCK;
    fileLock.l_whence = SEEK_SET;
    fileLock.l_start = 0;
    fileLock.l_len = 0;
    if (fcntl(fd, F_SETLKW, &fileLock) < 0) {
        perror("Unable to acquire lock");
        exit(1);
    }

    if (read(fd, buf, sizeof(buf) - 1) > 0) {
        printf("First line: %s\n", buf);
    }

    fileLock.l_type = F_UNLCK;
    fcntl(fd, F_SETLK, &fileLock); // Unlock the file
    close(fd);
    return 0;
}
