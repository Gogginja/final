#include <stdio.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>

int main() {
    DIR *dirPtr;
    struct dirent *entryPtr;
    struct stat fileStat;

    dirPtr = opendir(".");
    if (dirPtr == NULL) {
        perror("Unable to open directory");
        return 1;
    }

    while ((entryPtr = readdir(dirPtr))) {
        stat(entryPtr->d_name, &fileStat);
        printf("%-20s\t%ld bytes\n", entryPtr->d_name, fileStat.st_size);
    }

    closedir(dirPtr);
    return 0;
}
