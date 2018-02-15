/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;
int commentDepth;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
%}
%option  yylineno

/*
 * Define names for regular expressions here.
 */

DARROW          =>
ASSIGN          <-
LE              <=
TYPEID          [A-Z][a-zA-Z0-9_]*
OBJECTID        [a-z][a-zA-Z0-9_]*

SELFID          "self"
SELF_TYPEID     "SELF_TYPE"

WHITESPACE     [ \n\f\r\t\v]

%x COMMENT SIMPLE_COMMENT STRING STRINGLONGERR

%%

 /*
  *  Nested comments
  */
"--" {curr_lineno = yylineno; BEGIN(SIMPLE_COMMENT);}
"(*" { 
        curr_lineno = yylineno;
        commentDepth = 1;
        BEGIN(COMMENT);
     }
"*)" { 
    curr_lineno = yylineno;
    cool_yylval.error_msg = "Unmatched *)";
    BEGIN(INITIAL);
    return ERROR;
}


<SIMPLE_COMMENT>{
    [\n]    {curr_lineno = yylineno;   BEGIN(INITIAL); }
    [^\n]   {curr_lineno = yylineno;}
    <<EOF>> {curr_lineno = yylineno;   BEGIN(INITIAL); }
}

<COMMENT>{
    "(\*"   {   
                curr_lineno = yylineno;
                commentDepth++;
            }
    "\*)"   {   
                curr_lineno = yylineno;
                commentDepth--;
                if(0 == commentDepth)
                    BEGIN(INITIAL);
            }
    [*)]|[^*)] {curr_lineno = yylineno;}
    <<EOF>> {
                curr_lineno = yylineno;
                cool_yylval.error_msg = "EOF in comment";
                BEGIN(INITIAL);
                return ERROR;
            }
}


 /*
  *  The multiple-character operators.
  */
{DARROW}		{curr_lineno = yylineno; return (DARROW); }
{ASSIGN}		{curr_lineno = yylineno; return (ASSIGN); }
{LE}            {curr_lineno = yylineno; return (LE);     }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
(?i:class)         {curr_lineno = yylineno; return (CLASS);     }
(?i:else)          {curr_lineno = yylineno; return (ELSE);      }
t(?i:rue)          {
                        cool_yylval.boolean = true;
                        return (BOOL_CONST);
                   }
(?i:fi)            {curr_lineno = yylineno; return (FI);        }
f(?i:alse)         { 
                        curr_lineno = yylineno;
                        cool_yylval.boolean = false;
                        return (BOOL_CONST);
                   }
(?i:if)            {curr_lineno = yylineno; return (IF);        }
(?i:in)            {curr_lineno = yylineno; return (IN);        }
(?i:inherits)      {curr_lineno = yylineno; return (INHERITS);  }
(?i:isvoid)        {curr_lineno = yylineno; return (ISVOID);    }
(?i:let)           {curr_lineno = yylineno; return (LET);       }
(?i:loop)          {curr_lineno = yylineno; return (LOOP);      }
(?i:pool)          {curr_lineno = yylineno; return (POOL);      }
(?i:then)          {curr_lineno = yylineno; return (THEN);      }
(?i:while)         {curr_lineno = yylineno; return (WHILE);     }
(?i:case)          {curr_lineno = yylineno; return (CASE);      }
(?i:esac)          {curr_lineno = yylineno; return (ESAC);      }
(?i:new)           {curr_lineno = yylineno; return (NEW);       }
(?i:of)            {curr_lineno = yylineno; return (OF);        }
(?i:not)           {curr_lineno = yylineno; return (NOT);       }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
\"  {
        curr_lineno = yylineno;
        strcpy(string_buf, "");
        BEGIN(STRING); 
    }

<STRING>{
    \"  {
        curr_lineno = yylineno;
        cool_yylval.symbol = stringtable.add_string(string_buf);
        BEGIN(INITIAL);
        return (STR_CONST);
    }
    \n  {
        curr_lineno = yylineno;
        cool_yylval.error_msg = "Unterminated string constant";
        BEGIN(INITIAL);
        return ERROR;
    }
    \\b {   
       curr_lineno = yylineno;
       if((strlen(string_buf)+1) < MAX_STR_CONST){
           strcat(string_buf, "\b");
       }else{
           BEGIN(STRINGLONGERR);
       }
    }
    \\t {   
       curr_lineno = yylineno;
       if((strlen(string_buf)+1) < MAX_STR_CONST){
           strcat(string_buf, "\t");
       }else{
           BEGIN(STRINGLONGERR);
       }
    }
    \\n {   
       curr_lineno = yylineno;
       if((strlen(string_buf)+1) < MAX_STR_CONST){
           strcat(string_buf, "\n");
       }else{
           BEGIN(STRINGLONGERR);
       }
    }
    \\f {   
       curr_lineno = yylineno;
       if((strlen(string_buf)+1) < MAX_STR_CONST){
           strcat(string_buf, "\f");
       }else{
           BEGIN(STRINGLONGERR);
       }
    }
    \\\n {
       curr_lineno = yylineno;
       if((strlen(string_buf)+1) < MAX_STR_CONST){
           strcat(string_buf, "\n");
       }else{
           BEGIN(STRINGLONGERR);
       }
    }
    \\\0.*[\n]* {
        curr_lineno = yylineno;
        cool_yylval.error_msg = "String contains escaped null character.";
        BEGIN(INITIAL);
        return ERROR;
    }
    <<EOF>> {
       curr_lineno = yylineno;
       cool_yylval.error_msg = "EOF in string constant";
       BEGIN(INITIAL);
       return ERROR;
    }
    \\. {
       curr_lineno = yylineno;
       if((strlen(string_buf)+1) < MAX_STR_CONST){
           strcat(string_buf, yytext+1);
       }else{
           BEGIN(STRINGLONGERR);
       }
    }
    ([^"\0\n\\])+ {
        curr_lineno = yylineno;
        if((strlen(string_buf) + strlen(yytext)) < MAX_STR_CONST){
            strcat(string_buf, yytext);
        }else{
           BEGIN(STRINGLONGERR);
        }
    }
}
<STRINGLONGERR>{
    \"  {
            curr_lineno = yylineno;
            cool_yylval.error_msg = "String constant too long";
            BEGIN(INITIAL);
            return ERROR;
    }
    <<EOF>> {
       curr_lineno = yylineno;
       cool_yylval.error_msg = "EOF in string constant";
       BEGIN(INITIAL);
       return ERROR;
    }
}
[:;{}().+\-*/<,~@=] {
                        curr_lineno = yylineno;
                        return *yytext;
                    }
{WHITESPACE} {
                curr_lineno = yylineno;
             }
[0-9]+ {
    cool_yylval.symbol = inttable.add_string(yytext); 
    curr_lineno = yylineno;     
    return (INT_CONST);
}
{TYPEID} { 
    cool_yylval.symbol = idtable.add_string(yytext);
    curr_lineno = yylineno;     
    return (TYPEID);
}
{OBJECTID} { 
    cool_yylval.symbol = idtable.add_string(yytext);
    curr_lineno = yylineno;     
    return (OBJECTID);  
}

. {
    curr_lineno = yylineno;
    cool_yylval.error_msg = yytext;
    return ERROR;  
}
%%

// vim: ft=lex 
