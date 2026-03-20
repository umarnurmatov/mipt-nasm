#!/bin/bash

BUILD_DIR=build
PROJ_NAME=bprintf

mkdir -p $BUILD_DIR
nasm -f elf64 -l $BUILD_DIR/$PROJ_NAME.lst -o $BUILD_DIR/$PROJ_NAME.o $PROJ_NAME.s
ld -s -o $BUILD_DIR/$PROJ_NAME.out $BUILD_DIR/$PROJ_NAME.o
./$BUILD_DIR/$PROJ_NAME.out

