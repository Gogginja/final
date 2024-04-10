#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <pwd.h>
#include <grp.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <directory>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    DIR *dir;
    struct dirent *entry;
    struct stat statbuf;
    struct passwd *pwd;
    struct group *grp;

    dir = opendir(argv[1]);
    if (dir == NULL) {
        perror("opendir");
        exit(EXIT_FAILURE);
    }

    while ((entry = readdir(dir)) != NULL) {
        char path[1024];
        snprintf(path, sizeof(path), "%s/%s", argv[1], entry->d_name);
        
        if (stat(path, &statbuf) == -1) {
            perror("stat");
            continue;
        }

        pwd = getpwuid(statbuf.st_uid);
        if (pwd == NULL) {
            perror("getpwuid");
            continue;
        }

        grp = getgrgid(statbuf.st_gid);
        if (grp == NULL) {
            perror("getgrgid");
            continue;
        }

        printf("File: %-20s | User ID: %-10d | Group ID: %-10d | Inode: %-10ld\n",
               entry->d_name, statbuf.st_uid, statbuf.st_gid, statbuf.st_ino);
    }

    closedir(dir);
    return 0;
}
