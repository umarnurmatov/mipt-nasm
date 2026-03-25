#!/bin/bash

BUILD_DIR=build
ASM_FILE=bprintf
C_FILE=bprintf_extern_call

mkdir -p $BUILD_DIR
nasm -g -f elf64 -l $BUILD_DIR/$ASM_FILE.lst -o $BUILD_DIR/$ASM_FILE.o $ASM_FILE.s
gcc -no-pie -g -o $BUILD_DIR/$C_FILE.out $C_FILE.c $BUILD_DIR/$ASM_FILE.o
./$BUILD_DIR/$C_FILE.out
