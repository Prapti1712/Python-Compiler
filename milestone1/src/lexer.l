%option yylineno
%option case-insensitive
%option noyywrap
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <iostream>
#include <stack>
#include "parser.tab.h"
// #include "Python_1_new.tab.h"
using namespace std;
int current_indent = 0;
int flag=0;
stack<int> s;
int c=0;
int d=0;
int a=0;

%}


LETTER_UPPER [A-Z]
LETTER_LOWER [a-z]
DIGIT_DECIMAL [0-9]
ID_START {LETTER_UPPER}|{LETTER_LOWER}|"_"
ID_CONTINUE {ID_START}|{DIGIT_DECIMAL}
stringescapeseq [\\][\s\S]
longstringchar [^\\]|\\n
strongstringchar [^\\\"\'\n]
longstringitem {longstringchar}|{stringescapeseq}
shortstringitem {strongstringchar}|{stringescapeseq}
longstring \"\"\"{longstringitem}*\"\"\"|\'\'\'{longstringitem}*\'\'\'
shortstring \"({shortstringitem})*\"|\'({shortstringitem})*\'
stringprefix "r"|"u"|"R"|"U"|"f"|"F"|"fr"|"Fr"|"fR"|"FR"|"rf"|"rF"|"Rf"|"RF"
bytesescapeseq [\\][ -~]
longbyteschar [^\\]|\\n
shortbyteschar [^\\\"\'\n]
longbytesitem {longbyteschar}|{bytesescapeseq}
shortbytesitem {shortbyteschar}|{bytesescapeseq}
longbytes \"\"\"{longbytesitem}*\"\"\" | \'\'\'{longbytesitem}*\'\'\'
shortbytes \"({shortbytesitem})*\" | \'({shortbytesitem})*\'
bytesprefix "b" | "B" | "br" | "Br" | "bR" | "BR" | "rb" | "rB" | "Rb" | "RB"
literal_char [^\{\}\0]
format_spec ({literal_char}|{\0}|{replacement_field})*
conversion [sra]
comp_operator "<" | ">" | "==" | ">=" | "<=" | "!=" | "is"("not")? | ("not")? "in"
comparison    ::=  {or_expr} ({comp_operator} {or_expr})*
digit [0-9]
hexdigit [0-9a-fA-F]
octdigit [0-7]
bindigit [01]
nonzerodigit [1-9]
hexinteger [0][xX]{[_]?hexdigit}+
octinteger [0][oO]{[_]?octdigit}+
bininteger [0][bB]{[_]?bindigit}+
decinteger {nonzerodigit}{[_]?digit}*|[0]+{[_]?[0]}*
digitpart {digit}([_]?{digit})*
exponent [eE][+-]?{digitpart}
fraction [.]{digitpart}
pointfloat {digitpart}?{fraction}|{digitpart}[.] 
exponentfloat ({digitpart}|{pointfloat}){exponent}
floatnumber {pointfloat}|{exponentfloat}
%s end
%%
        {       if(s.empty()){
                //cout<<"empty"<<endl;
                    s.push(0);
                }
                if(flag==1)
                {
                    //cout<<"flag:1"<<endl;
                    if(c>s.top()){
                    s.push(c);
                    c=0;
                    flag=0;
                    //cout<<"Indent"<<endl;
                    return INDENT;
                }
                    while(c<s.top()){
                        d=1;
                        s.pop();
                        if(s.empty()){
                            exit(1);
                        }
                        //cout<<"Dedent"<<endl;
                       return DEDENT;
                    }
                    // if(d==1){
                    //     d=0;
                    //     flag=0;
                    // return DEDENT;
                    // }
                    if(c!=s.top()){
                        exit(1);
                    }
                    flag=0;
                }
        }
"def" {yylval.strValue = strdup(yytext);   
//cout<<"defination"<<endl; 
return DEF;}
":" {yylval.strValue = strdup(yytext);   return COLON;}
"->" {yylval.strValue = strdup(yytext);   return ARROW;}
"(" {yylval.strValue = strdup(yytext);  
 return LPAREN;}
")" {yylval.strValue = strdup(yytext);  return RPAREN;}
"*" {yylval.strValue = strdup(yytext);   return STAR;}
"**" {yylval.strValue = strdup(yytext);   return DOUBLESTAR;}
"," {yylval.strValue = strdup(yytext);   return COMMA;}
"=" {yylval.strValue = strdup(yytext);   return EQUAL;}
";" {yylval.strValue = strdup(yytext);   return SEMI;}
"+=" {yylval.strValue = strdup(yytext);   return PLUSEQUAL;}
"-=" {yylval.strValue = strdup(yytext);   return MINEQUAL;}
"*=" {yylval.strValue = strdup(yytext);   return STAREQUAL;}
"/=" {yylval.strValue = strdup(yytext);   return SLASHEQUAL;}
"//=" {yylval.strValue = strdup(yytext);   return DOUBLESLASHEQUAL;}
"%=" {yylval.strValue = strdup(yytext);   return PERCENTEQUAL;}
"@=" {yylval.strValue = strdup(yytext);   return ATEQUAL;}
"&=" {yylval.strValue = strdup(yytext);   return AMPEQUAL;}
"|=" {yylval.strValue = strdup(yytext);   return VBAREQUAL;}
"^=" {yylval.strValue = strdup(yytext);   return CIRCUMFLEXEQUAL;}
">>=" {yylval.strValue = strdup(yytext);   return RIGHTSHIFTEQUAL;}
"<<=" {yylval.strValue = strdup(yytext);   return LEFTSHIFTEQUAL;}
"**=" {yylval.strValue = strdup(yytext);   return DOUBLESTAREQUAL;}
"break" {yylval.strValue = strdup(yytext);   return BREAK;}
"continue" {yylval.strValue = strdup(yytext);   return CONTINUE;}
"return" {yylval.strValue = strdup(yytext);   return RETURN;}
"raise" {yylval.strValue = strdup(yytext);   return RAISE;}
"from" {yylval.strValue = strdup(yytext);   return FROM;}
"global" {yylval.strValue = strdup(yytext);   return GLOBAL;}
"nonlocal" {yylval.strValue = strdup(yytext);   return NONLOCAL;}
"assert" {yylval.strValue = strdup(yytext);   return ASSERT;}
"if" {yylval.strValue = strdup(yytext);   return IF;}
"elif" {yylval.strValue = strdup(yytext);   return ELIF;}
"else" {yylval.strValue = strdup(yytext);   return ELSE;}
"while" {yylval.strValue = strdup(yytext);   return WHILE;}
"for" {yylval.strValue = strdup(yytext);   return FOR;}
"in" {yylval.strValue = strdup(yytext);   return IN;}
"try" {yylval.strValue = strdup(yytext);   return TRY;}
"finally" {yylval.strValue = strdup(yytext);   return FINALLY;}
"except" {yylval.strValue = strdup(yytext);   return EXCEPT;}
"as" {yylval.strValue = strdup(yytext);   return AS;}
"or" {yylval.strValue = strdup(yytext);   return OR;}
"and" {yylval.strValue = strdup(yytext);   return AND;}
"not" {yylval.strValue = strdup(yytext);   return NOT;}
"is" {yylval.strValue = strdup(yytext);   return IS;}
"<" {yylval.strValue = strdup(yytext);   return LESS;}
">" {yylval.strValue = strdup(yytext);   return GREATER;}
"==" {yylval.strValue = strdup(yytext);   return EQEQUAL;}
">=" {yylval.strValue = strdup(yytext);   return GREATEREQUAL;}
"<=" {yylval.strValue = strdup(yytext);   return LESSEQUAL;}
"<>" {yylval.strValue = strdup(yytext);   return NOTEQUAL;}
"!=" {yylval.strValue = strdup(yytext);   return NOEQUAL;}
"^" {yylval.strValue = strdup(yytext);   return POWER;}
"&" {yylval.strValue = strdup(yytext);   return AMPER;}
"<<" {yylval.strValue = strdup(yytext);   return LEFTSHIFT;}
">>" {yylval.strValue = strdup(yytext);   return RIGHTSHIFT;}
"+" {yylval.strValue = strdup(yytext);   return PLUS;}
"-" {yylval.strValue = strdup(yytext);   return MINUS;}
"@" {yylval.strValue = strdup(yytext);   return AT;}
"/" {yylval.strValue = strdup(yytext);   return BACKSLASH;}
"%" {yylval.strValue = strdup(yytext);   return PERCENT;}
"//" {yylval.strValue = strdup(yytext);   return DOUBLEBACKSLASH;}
"~" {yylval.strValue = strdup(yytext);   return TILDE;}
"["  {yylval.strValue = strdup(yytext);   return LSQBRACKET;}
"]" {yylval.strValue = strdup(yytext);   return RSQBRACKET;}
"{" {yylval.strValue = strdup(yytext);   return LCBRACE;}
"}" {yylval.strValue = strdup(yytext);   return RCBRACE;}
"..." {yylval.strValue = strdup(yytext);   return TRIPLEDOT;}
"None" {yylval.strValue = strdup(yytext);   return NONE;}
"True" {yylval.strValue = strdup(yytext);   return RIGHT;}
"False" {yylval.strValue = strdup(yytext);   return WRONG;}
"." {yylval.strValue = strdup(yytext);   return DOT;}
"class" {yylval.strValue = strdup(yytext);   return CLASS;}
({ID_START}{ID_CONTINUE}*) {yylval.strValue = strdup(yytext);   return NAME;}
[stringprefix]?({shortstring}|{longstring}) {yylval.strValue = strdup(yytext);   return STRING;}
{nonzerodigit}([_]?{digit})* {yylval.strValue = strdup(yytext); return NUMBER;}
[0]+([_]?[0])*  {yylval.strValue = strdup(yytext); return NUMBER;}
[0][bB]([_][01])+ {yylval.strValue = strdup(yytext); return NUMBER;}
[0][oO]([_][0-7])+ {yylval.strValue = strdup(yytext); return NUMBER;}
[0][xX]([_][0-9a-fA-F])+ {yylval.strValue = strdup(yytext); return NUMBER;}
({pointfloat}|{exponentfloat}) {yylval.strValue = strdup(yytext); return NUMBER;}
{floatnumber}[jJ] {yylval.strValue = strdup(yytext); return NUMBER;}
{digitpart}[jJ] {yylval.strValue = strdup(yytext); return NUMBER;}

[\n]+[ \t\f]*  {
     //cout<<"newline"<<endl;
     int i=0;
     while(yytext[i]=='\n'){
     i++;
     }
     c=yyleng-i;
     
    if(c!=s.top()){
    //cout<<"top"<<endl; 
    flag=1;}
    flag=1;
    return NEWLINE;
}
<INITIAL><<EOF>> {BEGIN(end); yylval.strValue = strdup(yytext); a++; 
//cout<<"endmarker "<<yylineno<<endl; 
return ENDMARKER;}
[ \t\f\n]+ {}
"#"(.|\n)*\n 
%%

