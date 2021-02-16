# Assignment Notes

## Requirments

For Ubuntu, install the flex version >= 2.5.34, which is support insensitive case patterns:w. 

The most easiest way, and check if flew is upper 2.5.34

```bash
sudo apt-get install flex
flex -V
```

if not, compile from source and install.

```bash
wget https://github.com/westes/flex/releases/download/flex-2.5.39/flex-2.5.39.tar.gz
tar -zxf flex-2.5.39.tar.gz
cd flex-2.5.39
./configure
make
sudo make install
```



## Fixed: libfl.so: undefined reference to `yylex'

This compile fail is cause by compiling with g++ and get C++ yylex while yylex in libfl.so is expecting a C linkage.l

Add `%option noyywrap` to cool.flex to avoid linking with libfl.so



## Tips for PA2

1. Place a "." rule at the end of cool.flex, so any missing character will be reported as ERROR

2. Try grading script, fix the fail case one by one

3. Remember regression test when a fixed apply

   

## Tips for PA3

1. Discover recursive grammar structure as much as possible, for example

   ```text
   expr ::= let ID : TYPE [ <- expr ] [[, ID : TYPE [ <- expr ]]]∗ in expr
   ```

   there are unlimited structure ` ID : TYPE [ <- expr]`, and they are recursive until meet `in expr`, so rules should be

   ```bison
   expression
   	: LET let_list
   		{ $$ = $2;}
   
   let_list
       : OBJECTID ':' TYPEID init IN expression
           {  $$ = let($1, $3, $4, $6); }
       | OBJECTID ':' TYPEID init ',' let_list
           {  $$ = let($1, $3, $4, $6); }
       ;
   ```

   



