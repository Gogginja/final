%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "gvlogo.tab.h"
%}

%option noyywrap
%option yylineno

%%
"penup"            { return PENUP; }
"pendown"          { return PENDOWN; }
"print"            { return PRINT; }
"save"             { return SAVE; }
"color"            { return COLOR; }
"clear"            { return CLEAR; }
"turn"             { return TURN; }
"move"             { return MOVE; }
"goto"             { return GOTO; }
"where"            { return WHERE; }
[0-9]+             { yylval.f = atof(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.s = strdup(yytext); return VARIABLE; }
\"[^"]*\"          { yylval.s = strdup(yytext); return STRING; }
[ \t\r\n]          ;
.                  { yyerror("Lexing Syntax error.\n"); } 
%%

void yyerror(const char* s){
    fprintf(stderr, "Lexer Error: %s\n", s);
}

int yywrap(){
    return 1;
}
