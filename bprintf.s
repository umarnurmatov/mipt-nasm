section .text

extern _printf

global _start
global bprintf

%define NULL_TERM       0x0                   ; null-terminator
%define WB              2                     ; bytes in word
%define DB              4                     ; bytes in double word
%define QB              8                     ; bytes in quad

_start:     

main:           push    word 'x'
                push    word 'y'
                push    __FmtStr
                call    bprintf

                mov     rax, 0x3C
                xor     rdi, rdi
                syscall

bprintf:        mov     rbp, rsp
                push    rbp

                mov     rsi,  [rbp+QB]
                mov     rdi,  __buffer
                mov     r8, 2*QB            ; first arg offset
                xor     rdx, rdx            ; length

.fmt_loop:      lodsb
                
                cmp     ax, '%'
                jne     .regular_ch

                lodsb
                
                sub     rax, 'a'
                jmp     [__JmpTbl+rax*DB]

.jmp_c:         mov     al, [rbp+r8]
                add     r8, WB
                stosb
                jmp     .NULL_TERM

.jmp_b:         jmp     .NULL_TERM
                
.regular_ch:    stosb

.NULL_TERM:           inc     rdx
                cmp     ax, NULL_TERM
                je      .end  


                jmp     .fmt_loop

.end:           mov     rax, 1
                mov     rdi, 0
                mov     rsi, __buffer
                ; rdx already equals buffer len
                syscall

                pop     rbp
                ret

section .data

__buffer        db 100 dup(0)

section .rodata

__FmtStr        db "%c %c", NULL_TERM

__JmpTbl        dd  0
                dd  bprintf.jmp_b
                dd  bprintf.jmp_c
