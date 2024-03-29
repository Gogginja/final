#include <stdio.h>
#include "gvlogo.tab.h"

int main() {
    startup();
    penup();
    move(50);
    turn(90);
    pendown();
    move(100);
    turn(-45);

    clear();
    shutdown();
    return 0;
}
