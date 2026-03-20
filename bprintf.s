section .text

extern _printf
global _start
global _bprintf

_start:     


_bprintf:       mov     rax, 0x01
                
                mov     rdi, 1
                mov     rsi, Msg
                mov     rdx, MsgLen
                syscall


                mov     rax, 0x3C
                xor     rdi, rdi
                syscall

section     .data
            
Msg:        db "__Hllwrld", 0x0a
MsgLen      equ $ - Msg
