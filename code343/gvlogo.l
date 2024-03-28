%{
#include "bison_file.tab.h" // Include the generated header file from Bison
%}

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
[0-9]+             { yylval.val = atoi(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.name = strdup(yytext); return IDENTIFIER; }
\"[^"]*\"          { yylval.name = strdup(yytext); return STRING; }
[ \t\r\n]          ; 
.                  ; 

%%

int yywrap() {
    return 1; // Indicate end of input
}
