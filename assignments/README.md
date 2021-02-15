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

   

   

   

