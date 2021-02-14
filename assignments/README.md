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

