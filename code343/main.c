#include <stdio.h>
#include "gvlogo.tab.h"

int main() {
    // Call the parser
    yyparse();

    penup;
    pendown;
    move 50;
    turn 90;
    move 100;
    color 255 0 0;
    move 50;
    turn -90;
    move 50;
    clear;
    save "drawing.bmp";

    printf("Example commands executed.\n");

    return 0;
}
