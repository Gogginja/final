%{
#include <stdio.h>
#include <stdlib.h>
#include "gvlogo.tab.h"

extern void yyerror(const char* s);
%}

%%
"penup"    { return PENUP; }
"pendown"  { return PENDOWN; }
"print"    { return PRINT; }
"save"     { return SAVE; }
"color"    { return COLOR; }
"clear"    { return CLEAR; }
"turn"     { return TURN; }
"move"     { return MOVE; }
"*goto"    { return GOTO; }
"*where"   { return WHERE; }
[0-9]+     { yylval.num = atoi(yytext); return NUMBER; }
[ \t\r\n]  ;
.          { yyerror("Lexing Syntax error.\n"); } 
%%
