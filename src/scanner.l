
/* definitions */

%{
#include <stdio.h>
#include <stdlib.h>
#include "tokendef.h"

 /* integers to track line and column numbers */
int scancol = 1;
int yycol = 1;
int scanlineno = 1;

 /* char pointer to pass error messages to driver.c */
char *yyerror;

 /* TODO: functions to update line and column numbers */
void updateCol();
void countLines();

 /* TODO: function to process a string literal */
int processString();

%}

integer         0|[1-9][0-9]*
integerlead0    0[0-9]+
character       '[^'\n]'

string_lit      "\"([^\"\\\n]|\\\\[nt\"\\\\])*\""

untermstring    "\"([^"\n])*$" 

comment         "//".*
multlncomment   "/\\*([^*]|\\*+[^*/])*\\*+/"
untermcomment   "/\\*([^*]|\\*+[^*/])*$"

identifier      [A-Za-z][A-Za-z0-9]*
illidentifier   [^a-zA-Z][A-Za-z0-9]*

newline         \n
whitespace      [ \t\n]+

yylineno = 1;

%%

 /* rules */

 /* KWD_s */

"if"              { updateCol(); return KWD_IF; }
"else"            { updateCol(); return KWD_ELSE; }
"while"           { updateCol(); return KWD_WHILE; }
"int"           { updateCol(); return KWD_INT; }
"String"        { updateCol(); return KWD_STRING; }
"char"          { updateCol(); return KWD_CHAR; }
return          { updateCol(); return KWD_RETURN; }
void            { updateCol(); return KWD_VOID; }

 /* Operators */

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

 /* Identifiers */
{identifier}    { updateCol(); return ID;}
{illidentifier} { updateCol(); yyerror = "Illegal identifier"; return ERROR;}

 /* Constants and Comments */

{integer}       { updateCol(); return INTCONST; }
{integerlead0}  { updateCol(); yyerror = "Integers cannot lead with 0"; return ERROR; }
{character}     { updateCol(); return CHARCONST; }
{comment}       { updateCol(); /* ignore */}
{multlncomment} { countLines(); /* ignore */}
{untermcomment} { updateCol(); yyerror = "Unterminated comment"; return ERROR; }
{string_lit}    { updateCol(); return processString(); }
{untermstring}  { updateCol(); yyerror = "Unterminated string constant"; return ERROR; }

 /* Other */
{newline}       { scanlineno++; scancol = 1; }
{whitespace}    { updateCol(); /* ignore spaces/tabs */ }
.               {return ILLEGAL_TOK;}

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
