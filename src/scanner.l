%{
#include <stdio.h>
#include <stdlib.h>
#include "tokendef.h"

int scancol = 1;
int yycol = 1;
int scanlineno = 1;

char *yyerror;

void updateCol();
void countLines();

int processString();

%}

%option yylineno

%x COMMENT

integer         0|[1-9][0-9]*

character       \'[^\'\n]\'

string_lit      \"([^\"\\]|\\.)*\"

untermstring    \"([^\"\\\n]|\\.)*$

comment         \/\/[^\n]*

         

identifier      [A-Za-z][A-Za-z0-9]*
illidentifier   [0-9][A-Za-z0-9]+

newline         \n
whitespace      [ \t]+



%%

 "/*"           { BEGIN(COMMENT); countLines(); }
if              { updateCol(); return KWD_IF; }
else            { updateCol(); return KWD_ELSE; }
while           { updateCol(); return KWD_WHILE; }
int             { updateCol(); return KWD_INT; }
String          { updateCol(); return KWD_STRING; }
char            { updateCol(); return KWD_CHAR; }
return          { updateCol(); return KWD_RETURN; }
void            { updateCol(); return KWD_VOID; }

"=="            { updateCol(); return OPER_EQ; }
"!="            { updateCol(); return OPER_NEQ; }
"<="            { updateCol(); return OPER_LTE; }
">="            { updateCol(); return OPER_GTE; }
"++"            { updateCol(); return OPER_INC; }
"--"            { updateCol(); return OPER_DEC; }
"&&"            { updateCol(); return OPER_AND; }
"||"            { updateCol(); return OPER_OR; }

"+"             { updateCol(); return OPER_ADD; }
"-"             { updateCol(); return OPER_SUB; }
"*"             { updateCol(); return OPER_MUL; }
"/"             { updateCol(); return OPER_DIV; }
"%"             { updateCol(); return OPER_MOD; }
"<"             { updateCol(); return OPER_LT; }
">"             { updateCol(); return OPER_GT; }
"="             { updateCol(); return OPER_ASGN; }
"!"             { updateCol(); return OPER_NOT; }

"["             { updateCol(); return LSQ_BRKT; }
"]"             { updateCol(); return RSQ_BRKT; }
"{"             { updateCol(); return LCRLY_BRKT; }
"}"             { updateCol(); return RCRLY_BRKT; }
"("             { updateCol(); return LPAREN; }
")"             { updateCol(); return RPAREN; }
","             { updateCol(); return COMMA; }
";"             { updateCol(); return SEMICLN; }
"@"             { updateCol(); return OPER_AT; }

{identifier}    { updateCol(); return ID;}
{illidentifier} { updateCol(); yyerror = "Illegal identifier"; return ERROR;}


{integer}       { updateCol(); return INTCONST; }
{character}     { updateCol(); return CHARCONST; }
{comment}       { updateCol(); /* ignore */ }
<COMMENT>\*/    { countLines(); BEGIN(INITIAL); }
<COMMENT>\r?\n     { scanlineno++; scancol = 1; }
<COMMENT>.      { scancol++; }


{string_lit}    { updateCol(); return processString(); }
{untermstring}  { updateCol(); yyerror = "Unterminated string constant"; return ERROR; }

{newline}       { scanlineno++; scancol = 1; }
{whitespace}    { updateCol(); /* ignore spaces/tabs */ }
.               { return ILLEGAL_TOK; }

%%

/* user routines */

void updateCol() {
    for (int i = 0; i < yyleng; i++) {
        if (yytext[i] == '\n') {
            scancol = 1;      // reset column at newline
            scanlineno++;     // increment line number
        } else {
            scancol++;        // increment column for every other character
        }
    }
}

void countLines() {
    for (int i = 0; i < yyleng; i++) {
        if (yytext[i] == '\n') {
            scanlineno++;     // increment line number
            scancol = 1;      // reset column at line start
        } else {
            scancol++;        // increment column for other chars
        }
    }
}

int processString() {
    char *src = yytext + 1;  // skip the opening quote
    char *dest = src;        // in-place processing
    int i = 0;

    while (src[i] != '"' && src[i] != '\0') {
        if (src[i] == '\\') {  // escape sequence
            i++;
            switch (src[i]) {
                case 'n': *dest++ = '\n'; break;
                case 't': *dest++ = '\t'; break;
                case '"': *dest++ = '"'; break;
                case '\\': *dest++ = '\\'; break;
                default:
                    yyerror = "Illegal escape sequence";
                    return ERROR;
            }
        } else {
            *dest++ = src[i];  // regular character
        }
        i++;
    }

    *dest = '\0';           // null-terminate the string
    updateCol();            // update column position for the whole string
    return STRCONST;          // token to parser
}
