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

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
int commentDepth;
int stringLength;

%}
%option noyywrap
%option yylineno

/* Once in a comment, it must exclude other INITIAL rules */
%x SIMPLE_COMMENT COMMENT
%x STRING STRING_LONG_ERROR

/*
 * Define names for regular expressions here.
 */

ASSIGN          <-
DARROW          =>
INT_CONST       [0-9]+
LE              <=
TYPEID          [A-Z][A-Za-z0-9_]*
OBJECTID        [a-z][A-Za-z0-9_]*
WHITE_SPACE     [ \n\f\r\t\v]+

%%

 /*
  *  Nested comments
  */
"--" {curr_lineno = yylineno; BEGIN(SIMPLE_COMMENT);}
"(*"    {
            curr_lineno = yylineno;
            commentDepth = 1;
            BEGIN(COMMENT);
        }

"*)"    {
            curr_lineno = yylineno;
            yylval.error_msg = "Unmatched *)";
            BEGIN(INITIAL);
            return ERROR;
        }

<SIMPLE_COMMENT>{
    /* Go no until meet a new line, or EOF, then return */
    [^\n]   {curr_lineno = yylineno;}
    [\n]    {curr_lineno = yylineno; BEGIN(INITIAL); }
    <<EOF>> {curr_lineno = yylineno; BEGIN(INITIAL); }
}

<COMMENT>{
    "(*"    {
                curr_lineno = yylineno;
                commentDepth++;
            }

    "*)"    {
                curr_lineno = yylineno;
                commentDepth--;
                if(0 == commentDepth){
                    BEGIN(INITIAL);
                }
            }

    <<EOF>> {
                curr_lineno = yylineno;
                yylval.error_msg = "EOF in comment";
                BEGIN(INITIAL);
                return ERROR;
            }

    . {
        /* Return anything no match */
        curr_lineno = yylineno;
    }
}

 /*
  *  The multiple-character operators.
  */
{ASSIGN}		{ curr_lineno = yylineno; return (ASSIGN); }
{DARROW}		{ curr_lineno = yylineno; return (DARROW); }
{LE}		    { curr_lineno = yylineno; return (LE); }


 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
(?i:class)      { curr_lineno = yylineno; return (CLASS); }
(?i:else)       { curr_lineno = yylineno; return (ELSE);  }
f(?i:alse)      { 
                    curr_lineno = yylineno;
                    yylval.boolean = false;
                    return (BOOL_CONST); 
                }
(?i:fi)         { curr_lineno = yylineno; return (FI); }
(?i:if)         { curr_lineno = yylineno; return (IF); }
(?i:in)         { curr_lineno = yylineno; return (IN); }
(?i:inherits)   { curr_lineno = yylineno; return (INHERITS); }
(?i:let)        { curr_lineno = yylineno; return (LET);  }
(?i:loop)       { curr_lineno = yylineno; return (LOOP); }
(?i:pool)       { curr_lineno = yylineno; return (POOL); }
(?i:then)       { curr_lineno = yylineno; return (THEN); }
t(?i:rue)       {
                    curr_lineno = yylineno;
                    yylval.boolean = true;
                    return (BOOL_CONST);
                }
(?i:while)      { curr_lineno = yylineno; return (WHILE); }
(?i:case)       { curr_lineno = yylineno; return (CASE);  }
(?i:esac)       { curr_lineno = yylineno; return (ESAC);  }
(?i:of)         { curr_lineno = yylineno; return (OF); }
(?i:new)        { curr_lineno = yylineno; return (NEW); }
(?i:isvoid)     { curr_lineno = yylineno; return (ISVOID); }
(?i:not)        { curr_lineno = yylineno; return (NOT); }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
\"      {
            curr_lineno = yylineno;
            strcpy(string_buf, "");
            stringLength = 0;
            BEGIN(STRING);
        }

<STRING>{
    \"  {
        curr_lineno = yylineno;
        yylval.symbol = stringtable.add_string(string_buf);
        BEGIN(INITIAL);
        return (STR_CONST);
    }

    \n  {
        curr_lineno = yylineno;
        cool_yylval.error_msg = "Unterminated string constant";
        BEGIN(INITIAL);
        return ERROR;
    }

    \\\n {
        curr_lineno = yylineno;
        stringLength++;
        if(stringLength < MAX_STR_CONST){
            strcat(string_buf, "\n");
        }else{
            BEGIN(STRING_LONG_ERROR);
        }
    }

    \\0 {
        curr_lineno = yylineno;
        cool_yylval.error_msg = "String contains escaped null character.";
        BEGIN(INITIAL);
        return ERROR;
    }
    
    \\. {
        /* Match for \c, including \n\t\b\f */
        curr_lineno = yylineno;
        stringLength++;
        if(stringLength < MAX_STR_CONST){
            strcat(string_buf, yytext+1);
        }else{
            BEGIN(STRING_LONG_ERROR);
        }
    }


    ([^"\0\n\\])+ {
        curr_lineno = yylineno;
        stringLength = stringLength + strlen(yytext);
        if(stringLength < MAX_STR_CONST){
            strcat(string_buf, yytext);
        }else{
           BEGIN(STRING_LONG_ERROR);
        }
    }

    <<EOF>> {
        curr_lineno = yylineno;
        cool_yylval.error_msg = "EOF in string constant";
        BEGIN(INITIAL);
        return ERROR;
    }

    . {
        /* Return anything no match */
        curr_lineno = yylineno;
        cool_yylval.error_msg = yytext;
        return ERROR;
    }
}

<STRING_LONG_ERROR>{
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
{OBJECTID}      {
                    yylval.symbol = idtable.add_string(yytext);
                    curr_lineno = yylineno;
                    return (OBJECTID);
                }
{TYPEID}        {
                    yylval.symbol = idtable.add_string(yytext);
                    curr_lineno = yylineno;
                    return (TYPEID);
                }
{INT_CONST}     {
                    yylval.symbol = inttable.add_string(yytext);
                    curr_lineno = yylineno;
                    return (INT_CONST);
                }
{WHITE_SPACE}   { curr_lineno = yylineno; }

[,:;{}()='\*\.\-\+\[\]\<\>]    {
                    curr_lineno = yylineno;
                    return *yytext;
                }

. {
    /* Return anything no match */
    curr_lineno = yylineno;
    cool_yylval.error_msg = yytext;
    return ERROR;
}

%%

/* vim ft=lex */
