#!/bin/bash

BUILD_DIR=build
PROJ_NAME=bprintf

mkdir -p $BUILD_DIR
nasm -g -f elf64 -l $BUILD_DIR/$PROJ_NAME.lst -o $BUILD_DIR/$PROJ_NAME.o $PROJ_NAME.s
ld --warn-common -o $BUILD_DIR/$PROJ_NAME $BUILD_DIR/$PROJ_NAME.o
./$BUILD_DIR/$PROJ_NAME

