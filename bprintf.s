section .text

extern _printf

global _start
global bprintf

%define NULL_TERM       0x0                   ; null-terminator
%define WB              2                     ; bytes in word
%define DB              4                     ; bytes in double word
%define QB              8                     ; bytes in quad

%macro PROLOGUE 0
                push    rbp
                mov     rbp, rsp
%endmacro

;----------------------------------------------

%macro EPILOGUE 0
                pop     rbp
%endmacro

%macro EPILOGUE 1
                add     rsp, QB*%1
                pop     rbp
%endmacro

;----------------------------------------------

%macro MULTIPUSH 1-*
                %rep %0
                    push %1
                %rotate 1
                %endrep
%endmacro

;----------------------------------------------

%macro MULTIPOP 1-*
                %rep %0
                %rotate -1
                    pop %1
                %endrep
%endmacro

;----------------------------------------------

_start:     

main:           push    50
                push    50
                push    50
                push    qword __FmtStr
                call    bprintf

                mov     rax, 0x3C
                xor     rdi, rdi
                syscall

;----------------------------------------------
; Printf; supports %c, %%, %b, %x, %o, %d, %s
;----------------------------------------------

%define BUF_SZ 50                           ; bprintf buf size

bprintf:        
                push    rbp
                mov     rbp, rsp

                mov     rsi,  [rbp+QB*2]
                mov     rdi,  __buffer
                mov     r8, QB*3            ; stack arg offset
                xor     rdx, rdx            ; length

.fmt_loop:      lodsb
                
                cmp     ax, '%'             ; add boundcheck
                jne     .ascii_ch

                lodsb
                
                sub     rax, 'b'
                jmp     qword [__JmpTbl+rax*QB]

.jmp_c:         mov     ax, [rbp+r8]
                add     r8, WB
                stosb
                inc     rdx
                jmp     .flush_buf_chk

.jmp_b:         
                cmp     rdx, BUF_SZ-QB
                jae     .flush_buf
                mov     ebx, [rbp+r8]
                add     r8, QB
                MULTIPUSH rax, rsi
                call    to_bin
                add     rdx, rax
                MULTIPOP rax, rsi
                jmp     .flush_buf_chk

.jmp_d:         jmp     .flush_buf_chk

.jmp_o:         cmp     rdx, BUF_SZ-QB
                jae     .flush_buf
                mov     ebx, [rbp+r8]
                add     r8, QB
                MULTIPUSH rax, rsi
                call    to_oct
                add     rdx, rax
                MULTIPOP rax, rsi
                jmp     .flush_buf_chk

.jmp_s:         jmp     .flush_buf_chk

.jmp_x:         
                cmp     rdx, BUF_SZ-QB
                jae     .flush_buf
                mov     ebx, [rbp+r8]
                add     r8, QB
                MULTIPUSH rax, rsi
                call    to_hex
                add     rdx, rax
                MULTIPOP rax, rsi
                jmp     .flush_buf_chk
                
.ascii_ch:      stosb
                inc     rdx

.flush_buf_chk:
                cmp     rdx, BUF_SZ
                jb      .eos

.flush_buf:     
                push    rsi
                mov     rax, 1
                mov     rdi, 0
                mov     rsi, __buffer
                ; rdx already equals buffer len
                syscall
                mov     rdi,  __buffer
                pop     rsi
                xor     rdx, rdx
                jmp     .fmt_loop

.eos:           cmp     ax, NULL_TERM
                je      .end  
                jmp     .fmt_loop

.end:           mov     rax, 1
                mov     rdi, 0
                mov     rsi, __buffer
                ; rdx already equals buffer len
                syscall

                pop     rbp
                ret

;----------------------------------------------
; Convert qword to string (base 16)
; Entry:        EBX   = value
;               EDI --> str
; Exit:         EAX   = printed length
; Destr:        r12, EAX, EBX, ECX
;----------------------------------------------
; to_hex:         lzcnt   rcx, rbx
;                 shr     rcx, 2
;                 push    rcx
;                 sal     rcx, 2
;                 add     rcx, 4
;                 rol     rbx, cl
;
;                 pop     rcx
;                 not     rcx
;                 lea     rcx, [rcx+QB*8/4+1]
;                 mov     rax, rcx
;
; .cnvrt_loop:    mov     r12, rbx
;                 and     r12, 0xF
;                 mov     al, [__Ascii_Lut+r12]
;                 rol     rbx, 4
;                 stosb
;                 loop    .cnvrt_loop
;
; .end            ret
;

%macro          CNVRT_TO_POW_OF_2 3
%1:         
                push    rdi
                mov     rdi, __cnvrt_buf
                mov     rcx, QB*8/%2

.cnvrt_loop:    
                mov     r12, rbx
                and     r12, %3
                mov     al, [__Ascii_Lut+r12]
                stosb
                shr     rbx, %2
                jz      .cnvrt_loop_end
                loop    .cnvrt_loop

.cnvrt_loop_end:
                neg     rcx
                lea     rcx, [rcx+QB*8/%2+1]
                mov     rax, rcx
                
                lea     rsi, [rdi-1]
                pop     rdi

.cpy_loop:      
                mov     bl, byte [rsi]
                dec     rsi 
                mov     byte [rdi], bl
                inc     rdi
                loop    .cpy_loop

                ret
%endmacro

;----------------------------------------------
; Convert qword to string (base 16)
; Entry:        EBX   = value
;               EDI --> str
; Exit:         EAX   = printed length
; Destr:        r12, EAX, EBX, ECX, RSI
;----------------------------------------------
CNVRT_TO_POW_OF_2 to_hex, 4, 0xF

;----------------------------------------------
; Convert qword to string (base 8)
; Entry:        EBX   = value
;               EDI --> str
; Exit:         EAX   = printed length
; Destr:        r12, EAX, EBX, ECX, RSI
;----------------------------------------------
CNVRT_TO_POW_OF_2 to_oct, 3, 0x7

;----------------------------------------------
; Convert qword to string (base 2)
; Entry:        EBX   = value
;               EDI --> str
; Exit:         EAX   = printed length
; Destr:        r12, EAX, EBX, ECX, RSI
;----------------------------------------------
CNVRT_TO_POW_OF_2 to_bin, 1, 0x1

section .data

__buffer        db BUF_SZ dup(0)

__cnvrt_buf     db 64 dup(0)

section .rodata

__FmtStr        db "%x %o %b", NULL_TERM

__Ascii_Lut     db "0123456789ABCDEF"

__JmpTbl        dq bprintf.jmp_b
                dq bprintf.jmp_c
                dq bprintf.jmp_d
                dq 10 dup(0)
                dq bprintf.jmp_o
                dq 3 dup(0)
                dq bprintf.jmp_s
                dq 4 dup(0)
                dq bprintf.jmp_x


