section .text

extern _printf

global _start
global bprintf

%define NULL_TERM       0x0                   ; null-terminator
%define WB              2                     ; bytes in word
%define DB              4                     ; bytes in double word
%define QB              8                     ; bytes in quad

%define BUF_SZ          100     ; bprintf buf size

_start:     

main:           push    0x30A
                push    qword __FmtStr
                call    bprintf

                mov     rax, 0x3C
                xor     rdi, rdi
                syscall

;----------------------------------------------
; Printf; supports %c, %%, %b, %x, %o, %d, %s
;----------------------------------------------
bprintf:        mov     rbp, rsp
                push    rbp

                mov     rsi,  [rbp+QB]
                mov     rdi,  __buffer
                mov     r8, 2*QB            ; stack arg offset
                xor     rdx, rdx            ; length

.fmt_loop:      lodsb
                
                cmp     ax, '%'
                jne     .ascii_ch

                lodsb
                
                sub     rax, 'b'
                jmp     [__JmpTbl+rax*DB]

.jmp_c:         mov     ax, [rbp+r8]
                add     r8, WB
                stosb
                inc     rdx
                jmp     .eos

.jmp_b:         jmp     .eos
.jmp_d:         jmp     .eos
.jmp_o:         jmp     .eos
.jmp_s:         jmp     .eos
.jmp_x:         mov     ebx, [rbp+r8]
                add     r8, QB
                call    to_hex
                add     rdx, 8
                jmp     .eos
                
.ascii_ch:      stosb
                inc     rdx

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
; Convert qword string (base 16)
; Entry:        EBX   = value
;               EDI --> str
;               EDX   = str ptr
; Destr:        r12, EAX, EBX, ECX
;----------------------------------------------
to_hex:         mov     ecx, DB*8/4
                rol     ebx, 4

.skip_lead_zeros_loop:
                mov     r12, rbx
                and     r12, 0xF
                jnz     .cnvrt_loop 
                rol     ebx, 4
                loop    .skip_lead_zeros_loop

                jmp     .end

.cnvrt_loop:    mov     r12, rbx
                and     r12, 0xF
                mov     al, [__HexASCII_Tbl+r12]
                rol     ebx, 4
                stosb
.end:           loop    .cnvrt_loop

                ret

section .data

__buffer        db BUF_SZ dup(0)

section .rodata

__FmtStr        db "%x", NULL_TERM

__HexASCII_Tbl  db "0123456789ABCDEF"

__JmpTbl        dd bprintf.jmp_b
                dd bprintf.jmp_c
                dd bprintf.jmp_d
                dd 10 dup(0)
                dd bprintf.jmp_o
                dd 3 dup(0)
                dd bprintf.jmp_s
                dd 4 dup(0)
                dd bprintf.jmp_x


