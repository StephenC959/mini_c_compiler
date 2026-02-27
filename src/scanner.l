%{
#include <stdio.h>
#include <stdlib.h>
#include "tokendef.h"

int scancol = 1;
int yycol = 1;
int scanlineno = 1;
int charCount;
char *yyerror;

void updateCol();
void countLines();
void multiCountLines();

int processString();

%}

yylineno = 1;

integer         (0|[1-9][0-9]*)

character       \'[^\'\n]\'

string_lit      \"([^\"\\\n]|\\.)*\"
stringmulti     \"([^\"\\]|\\.)*\"
untermstring    \"([^\"\\\r\n]|\\.)*$ 

comment         \/\/[^\n]*
multlncomment   \/\*([^*]|\*+[^*/])*\*+\/
untermcomment   \/\*([^*]|\*+[^*/])*$        

identifier      [A-Za-z][A-Za-z0-9]*
illidentifier   [0-9]+[A-Za-z][A-Za-z0-9]*

newline         (\r\n|\n|\r)
whitespace      [ \t]+



%%


if                { updateCol(); return KWD_IF; }
else              { updateCol(); return KWD_ELSE; }
while             { updateCol(); return KWD_WHILE; }
int               { updateCol(); return KWD_INT; }
string            { updateCol(); return KWD_STRING; }
char              { updateCol(); return KWD_CHAR; }
return            { updateCol(); return KWD_RETURN; }
void              { updateCol(); return KWD_VOID; }

"=="              { updateCol(); return OPER_EQ; }
"!="              { updateCol(); return OPER_NEQ; }
"<="              { updateCol(); return OPER_LTE; }
">="              { updateCol(); return OPER_GTE; }
"++"              { updateCol(); return OPER_INC; }
"--"              { updateCol(); return OPER_DEC; }
"&&"              { updateCol(); return OPER_AND; }
"||"              { updateCol(); return OPER_OR; }

"+"               { updateCol(); return OPER_ADD; }
"-"               { updateCol(); return OPER_SUB; }
"*"               { updateCol(); return OPER_MUL; }
"/"               { updateCol(); return OPER_DIV; }
"%"               { updateCol(); return OPER_MOD; }
"<"               { updateCol(); return OPER_LT; }
">"               { updateCol(); return OPER_GT; }
"="               { updateCol(); return OPER_ASGN; }
"!"               { updateCol(); return OPER_NOT; }

"["               { updateCol(); return LSQ_BRKT; }
"]"               { updateCol(); return RSQ_BRKT; }
"{"               { updateCol(); return LCRLY_BRKT; }
"}"               { updateCol(); return RCRLY_BRKT; }
"("               { updateCol(); return LPAREN; }
")"               { updateCol(); return RPAREN; }
","               { updateCol(); return COMMA; }
";"               { updateCol(); return SEMICLN; }
"@"               { updateCol(); return OPER_AT; }

{illidentifier}   { updateCol(); yyerror = "Illegal identifier"; return ERROR;}
0[0-9]+           { updateCol(); yyerror = "Integers can not lead with 0"; return ERROR; }
{identifier}      { updateCol(); return ID;}
{integer}         { updateCol(); return INTCONST; }
{character}       { updateCol(); return CHARCONST; }
{comment}         { updateCol(); /* ignore */ }
{multlncomment}   { multiCountLines(); /* ignore spaces/tabs */ }
{untermcomment}   { countLines(); yyerror = "Unterminated comment"; return EXIT; }


{string_lit}      { updateCol(); return processString(); }
{stringmulti}     { multiCountLines(); yyerror = "String spans multiple lines"; return ERROR; }
{untermstring}    { countLines(); yyerror = "Unterminated string constant"; return EXIT; }


{newline}         { countLines(); }
{whitespace}      { updateCol(); /* ignore spaces/tabs */ }
.                 { return ILLEGAL_TOK; }

%%

/* user routines */

void updateCol() {
    yylineno = scanlineno; //update for multiline cases
    yycol = scancol;
    scancol += yyleng;
}

void multiCountLines(){
    yylineno = scanlineno;
    scanlineno++;
    int i;
    charCount = 0;
    yycol = scancol;

    for (i = 0; yytext[i] != '\0'; i++) {
        if (yytext[i] == '\r') {
            scanlineno++;
            charCount = i;
            if (yytext[i+1] == '\n') i++;   /* CRLF counts as one newline */
        } else if (yytext[i] == '\n') {
            scanlineno++;
            charCount = i;
        } 
    }
    scanlineno--;
    scancol = i - charCount;
}

void countLines() {
    yylineno = scanlineno;
    scanlineno++;
    scancol = 1;
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
                    yycol = scancol - (yyleng - i - 1);
                    yyerror = "Illegal escape sequence";
                    return ERROR;
            }
        } else {
            *dest++ = src[i];  // regular character
        }
        i++;
    }

    *dest = '\0';           // null-terminate the string
    return STRCONST;          // token to parser
}
