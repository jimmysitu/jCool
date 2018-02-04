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

%x COMMENT SIMPLE_COMMENT STRING

%%

 /*
  *  Nested comments
  */
"--" { BEGIN(SIMPLE_COMMENT);}
"(*" { BEGIN(COMMENT);}
"*)" { 
    curr_lineno = yylineno;
    cool_yylval.error_msg = "Unmatched *)";
    BEGIN(INITIAL);
    return ERROR;
}


<SIMPLE_COMMENT>{
    [\n]    {   BEGIN(INITIAL); }
    [^\n]   {}
    <<EOF>> {   BEGIN(INITIAL); }
}

<COMMENT>{
    "*)"    { 
                BEGIN(INITIAL);
            }
    [^*)]|[^*]")"|"*"[^)] {}
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
{DARROW}		{ return (DARROW); }
{ASSIGN}		{ return (ASSIGN); }
{LE}            { return (LE);     }
isvoid          { return (ISVOID); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
(?i:class)         {curr_lineno = yylineno; return (CLASS);     }
(?i:else)          { return (ELSE);      }
t(?i:rue)          {
                        cool_yylval.boolean = true;
                        return (BOOL_CONST);
                   }
(?i:fi)            { return (FI);        }
f(?i:alse)         { 
                        cool_yylval.boolean = false;
                        return (BOOL_CONST);
                   }
(?i:if)            { return (IF);        }
(?i:in)            { return (IN);        }
(?i:inherits)      { return (INHERITS);  }
(?i:let)           { return (LET);       }
(?i:loop)          { return (LOOP);      }
(?i:pool)          { return (POOL);      }
(?i:then)          { return (THEN);      }
(?i:while)         { return (WHILE);     }
(?i:case)          { return (CASE);      }
(?i:esac)          { return (ESAC);      }
(?i:new)           { return (NEW);       }
(?i:of)            { return (OF);        }
(?i:not)           { return (NOT);       }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
\"  {
        strcpy(string_buf, "");
        BEGIN(STRING); 
    }

<STRING>{
    \"  {
        cool_yylval.symbol = stringtable.add_string(string_buf);
        BEGIN(INITIAL);
        return (STR_CONST);
    }
    \n  {
        cool_yylval.error_msg = "Unterminated string constant";
        curr_lineno = yylineno;
        BEGIN(INITIAL);
        return ERROR;
    }
    \\b {   
       curr_lineno = yylineno;
       if(strlen(string_buf) < MAX_STR_CONST){
           strcat(string_buf, "\b");
       }else{
           cool_yylval.error_msg = "String constant too long";
           return ERROR;
       }
    }
    \\t {   
       curr_lineno = yylineno;
       if(strlen(string_buf) < MAX_STR_CONST){
           strcat(string_buf, "\t");
       }else{
           cool_yylval.error_msg = "String constant too long";
           return ERROR;
       }
    }
    \\n {   
       curr_lineno = yylineno;
       if(strlen(string_buf) < MAX_STR_CONST){
           strcat(string_buf, "\n");
       }else{
           cool_yylval.error_msg = "String constant too long";
           return ERROR;
       }
    }
    \\f {   
       curr_lineno = yylineno;
       if(strlen(string_buf) < MAX_STR_CONST){
           strcat(string_buf, "\f");
       }else{
           cool_yylval.error_msg = "String constant too long";
           return ERROR;
       }
    }
    \\\n {
       curr_lineno = yylineno;
       if(strlen(string_buf) < MAX_STR_CONST){
           strcat(string_buf, "\n");
       }else{
           cool_yylval.error_msg = "String constant too long";
           return ERROR;
       }
    }
    \\\0.*[\n]* {
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
       if(strlen(string_buf) < MAX_STR_CONST){
           strcat(string_buf, yytext+1);
       }else{
           cool_yylval.error_msg = "String constant too long";
           return ERROR;
       }
    }
    ([^"\0\n\\])+ {
        curr_lineno = yylineno;
        if((strlen(string_buf) + strlen(yytext)) < MAX_STR_CONST){
            strcat(string_buf, yytext);
        }else{
            cool_yylval.error_msg = "String constant too long";
            return ERROR;
        }
    }
}

[:;{}().+\-*/<,~@=] { return *yytext; }
{WHITESPACE} {}
[0-9]+ {
    cool_yylval.symbol = inttable.add_int(atoi(yytext)); 
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
