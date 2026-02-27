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

integer         (0|[1-9][0-9]*)            // clean 0 integers

character       \'[^\'\n]\'                // character in the set not including ' and newline between ''

string_lit      \"([^\"\\\n]|\\.)*\"       // 0 or more characters between the "" in the set not including newline, \, and "
stringmulti     \"([^\"\\]|\\.)*\"         // same as string but it allows newline to catch the error
untermstring    \"([^\"\\\r\n]|\\.)*$      // same as string unless read until the end of file

comment         \/\/[^\n]*                 // "//" and any character after except newline
multlncomment   \/\*([^*]|\*+[^*/])*\*+\/  // same as string but allows newlines and all characters between /**/
untermcomment   \/\*([^*]|\*+[^*/])*$      // same as multiline comments but with finds eof instead of */  

identifier      [A-Za-z][A-Za-z0-9]*       // a Upper or lowercase letter followed by 0 or more letters or numbers
illidentifier   [0-9]+[A-Za-z][A-Za-z0-9]* // case where at least one number is followed by a letter and 0 or more combinations after

newline         (\r\n|\n|\r)               // newline and windows escape case
whitespace      [ \t]+                     // spaces and tabs

/*  keywords top section:
    1. special characters with returns defined in tokendef.h
    2. rules when a definition is found by scanner
    3. EXIT token breaks loop in driver.c and outputs error
    NOTE: flex does not like comments in rules portion */

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
    yylineno = scanlineno; // update for multiline cases
    yycol = scancol;       // scanner column saved into yycol
    scancol += yyleng;     // increment scanner col by token length
}

/*  function for multiline counting:
    if scanner finds a newline character the it will increment scan line number,
    keeps track of where the last line ended to calculate correct column on return. */

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

// increment line and reset col
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
                case 'n': *dest++ = '\n'; break;    // newline
                case 't': *dest++ = '\t'; break;    // tab escape
                case '"': *dest++ = '"'; break;     // "
                case '\\': *dest++ = '\\'; break;   // \
                default:
                    yycol = scancol - (yyleng - i - 1);   //find where \ is in the escape sequence
                    yyerror = "Illegal escape sequence";
                    return ERROR;
            }
        } else {
            *dest++ = src[i];  // regular character
        }
        i++;
    }

    *dest = '\0';             // null-terminate the string
    return STRCONST;          // token to parser
}
