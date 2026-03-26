section .text

extern printf
global bprintf

default rel

%define NULL_TERM       0x0                   ; null-terminator
%define WBYTES          2                     ; bytes in word
%define DBYTES          4                     ; bytes in double word
%define QBYTES          8                     ; bytes in quad
%define MAX_STR_LEN     0xffffffff

struc SaveRegs
    .rdi:    resq 1
    .rsi:    resq 1
    .rdx:    resq 1
    .rcx:    resq 1
    .r8 :    resq 1
    .r9 :    resq 1
endstruc

;----------------------------------------------
%macro PROLOGUE 0
                push    rbp
                mov     rbp, rsp
%endmacro
;----------------------------------------------


;----------------------------------------------
%macro EPILOGUE 0
                pop     rbp
%endmacro

%macro EPILOGUE 1
                add     rsp, QBYTES*%1
                pop     rbp
%endmacro
;----------------------------------------------


;----------------------------------------------
; Push n entities (in same order)
; Entry: %1-* = reg/imm
;----------------------------------------------
%macro MULTIPUSH 1-*
                %rep %0
                    push %1
                %rotate 1
                %endrep
%endmacro
;----------------------------------------------


;----------------------------------------------
; Pop n entities (in reverse order)
; Entry: %1-* = reg/imm
;----------------------------------------------
%macro MULTIPOP 1-*
                %rep %0
                %rotate -1
                    pop %1
                %endrep
%endmacro
;----------------------------------------------


;----------------------------------------------
; Write (syscall) to stdout
; Entry: %1 --> src
; Assum: rdx = string len
;----------------------------------------------
%macro WRITE_STDOUT 1
                mov     rax, 1
                mov     rdi, 0
                lea     rsi, [%1]
                syscall
%endmacro
;----------------------------------------------


_start:           
                mov     rax, 0x3C
                xor     rdi, rdi
                syscall

;----------------------------------------------
; Printf; supports %c, %%, %b, %x, %o, %d, %s
; (System-V-compliant)
; Entry:    RDI             --> fmt string
;           RSI, RDX, ... =/--> VA-args
; Exit:     none
;----------------------------------------------

%define BUF_SZ 164                           ; bprintf buf size, >64!

%define MAX_CNVRTD_NUM_LEN 64

%macro FLUSH_BUF 0
                WRITE_STDOUT __buffer
%endmacro

%macro FLUSH_BUF_AND_RESET 0
                push    rsi
                FLUSH_BUF 
                lea     rdi,  [__buffer]
                pop     rsi
                xor     rdx, rdx
%endmacro

%macro JMP_CNVRT_TO_POWER_OF_2 1
                mov     rbx, qword [rbp+r8]
                add     r8, QBYTES
                push rsi
                call    %1
                add     rdx, rax
                pop rsi
                jmp     .flush_buf_chk
%endmacro

%macro JMP_S 0
                MULTIPUSH rsi, rdi
                mov     rbx, qword [rbp+r8] 
                mov     rdi, rbx
                add     r8, QBYTES
                mov     rcx, MAX_STR_LEN
                xor     al, al

                repne scasb

                sub     rdi, rbx
                cmp     rdi, BUF_SZ - MAX_CNVRTD_NUM_LEN
                jb      .jmp_s_end 

                push    rdi
                FLUSH_BUF

                pop     rdx
                WRITE_STDOUT rbx

                MULTIPOP rsi, rdi

                lea     rdi, [__buffer]
                xor     rdx, rdx

                jmp     .fmt_loop

.jmp_s_end:     add     rdx, rdi
                mov     rcx, rdi
                pop     rdi
                mov     rsi, rbx
                rep movsb
                pop     rsi
                jmp     .fmt_loop

%endmacro


bprintf:        
                mov     qword [__save_regs+SaveRegs.rdi], rdi
                mov     qword [__save_regs+SaveRegs.rsi], rsi
                mov     qword [__save_regs+SaveRegs.rdx], rdx
                mov     qword [__save_regs+SaveRegs.rcx], rcx
                mov     qword [__save_regs+SaveRegs.r8], r8
                mov     qword [__save_regs+SaveRegs.r9], r9

                pop     rax                 ; save return address

                MULTIPUSH r9, r8, rcx, rdx, rsi, rdi

                push    rax                 ; pop return address 
                                            ; on top of stack
                
                PROLOGUE

                mov     rsi,  [rbp+QBYTES*2]
                lea     rdi,  [__buffer]
                mov     r8, QBYTES*3        ; stack arg offset
                xor     rdx, rdx            ; length
                xor     rax, rax
                cld

.fmt_loop:      lodsb
                
                cmp     al, '%'         
                jne     .regular_char

                lodsb
                
                cmp     al, '%'
                je      .jmp_percent
                cmp     al, 'a'
                jbe     .jmp_default
                cmp     al, 'y'
                jae     .jmp_default 
                sub     rax, 'b'
                lea     rbx, [__JmpTbl]
                movsxd  r13, dword [rbx + rax * QBYTES]
                add     rbx, r13
                jmp     rbx

.jmp_c:         mov     rax, qword [rbp+r8]
                add     r8, QBYTES
                stosb
                inc     rdx
                jmp     .flush_buf_chk

.jmp_b:         JMP_CNVRT_TO_POWER_OF_2 to_bin

.jmp_d:         movsxd  rbx, dword [rbp+r8]
                push    rsi
                add     r8, QBYTES
                call    to_dec
                add     rdx, r12
                pop     rsi
                jmp     .flush_buf_chk

.jmp_o:         JMP_CNVRT_TO_POWER_OF_2 to_oct

.jmp_s:         JMP_S

.jmp_x:         JMP_CNVRT_TO_POWER_OF_2 to_hex

.jmp_percent:   stosb
                inc     rdx
                jmp     .flush_buf_chk

.jmp_default:   push    rax 
                mov     al, byte '%'
                stosb
                pop     rax
                stosb
                add     rdx, 2
                jmp     .eos_chk

.regular_char:  stosb
                inc     rdx

.eos_chk:       cmp     al, NULL_TERM
                je      .end  
                jmp     .fmt_loop

.flush_buf_chk:
                cmp     rdx, BUF_SZ - MAX_CNVRTD_NUM_LEN
                jb      .fmt_loop

.flush_buf:     FLUSH_BUF_AND_RESET
                jmp     .fmt_loop

.end:           FLUSH_BUF

                pop     rbp
                pop     r13
                add     rsp, 6*QBYTES

                mov     rdi, qword [__save_regs+SaveRegs.rdi]
                mov     rsi, qword [__save_regs+SaveRegs.rsi]
                mov     rdx, qword [__save_regs+SaveRegs.rdx]
                mov     rcx, qword [__save_regs+SaveRegs.rcx]
                mov     r8, qword [__save_regs+SaveRegs.r8]
                mov     r9, qword [__save_regs+SaveRegs.r9]

                call    printf wrt ..plt

                push    r13
                ret

%undef JMP_CNVRT_TO_POWER_OF_2

%undef FLUSH_BUF

%undef FLUSH_BUF_AND_RESET
;----------------------------------------------

%macro          CNVRT_TO_POW_OF_2 3
%1:         
                push    rdi
                lea     rdi, [__cnvrt_buf]
                mov     rcx, QBYTES*8/%2

.cnvrt_loop:    
                mov     r12, rbx
                and     r12, %3
                lea     rax, [__Ascii_Lut]
                lea     rax, [rax+r12]
                mov     al, [rax]
                stosb
                shr     rbx, %2
                jz      .cnvrt_loop_end
                loop    .cnvrt_loop

.cnvrt_loop_end:
                neg     rcx
                lea     rcx, [rcx+QBYTES*8/%2+1]
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
; Entry:        RBX   = value
;               EDI --> str
; Exit:         EAX   = printed length
; Destr:        r12, EAX, EBX, ECX, 
;               RSI, __cnvrt_buf
;----------------------------------------------
CNVRT_TO_POW_OF_2 to_hex, 4, 0xF

;----------------------------------------------
; Convert qword to string (base 8)
; Entry:        RBX   = value
;               EDI --> str
; Exit:         EAX   = printed length
; Destr:        r12, EAX, EBX, ECX, 
;               RSI, __cnvrt_buf
;----------------------------------------------
CNVRT_TO_POW_OF_2 to_oct, 3, 0x7

;----------------------------------------------
; Convert qword to string (base 2)
; Entry:        RBX   = value
;               EDI --> str
; Exit:         EAX   = printed length
; Destr:        r12, EAX, EBX, ECX, 
;               RSI, __cnvrt_buf
;----------------------------------------------
CNVRT_TO_POW_OF_2 to_bin, 1, 0x1

;----------------------------------------------
; Convert qword to string (base 10)
; Entry:        RBX   = value
;               EDI --> str
; Exit:         R12   = printed length
; Destr:        RAX, RCX, RDX, RDI, __cnvrt_buf
;----------------------------------------------
to_dec:         xor     r12, r12

                mov     rcx, 10
                cmp     rbx, 0
                jge     .cnvrt_loop_prep

                mov     al, '-'
                stosb
                inc     rdi

                xor     rbx, -1
                add     rbx, 1

.cnvrt_loop_prep:
                push    rdi
                lea     rdi, [__cnvrt_buf]

.cnvrt_loop:    xor     rdx, rdx
                mov     rax, rbx
                div     rcx
                mov     rbx, rax
                add     rdx, '0'
                mov     al, dl
                stosb
                inc     r12

                cmp     rbx, 0
                jz      .cpy_loop_prep
                jmp     .cnvrt_loop

.cpy_loop_prep: pop     rdi
                lea     rsi, [__cnvrt_buf]
                lea     rsi, [rsi+r12-1]
                mov     rcx, r12

.cpy_loop:      mov     al, byte [rsi]
                dec     rsi
                mov     byte [rdi], al
                inc     rdi
                loop    .cpy_loop

                ret
;----------------------------------------------

section .data

__buffer        db BUF_SZ dup(0)

__cnvrt_buf     db 64 dup(0)

__save_regs     dq 0 dup(6)

section .rodata

__FmtStr        db `%d alpha %A %x %o %b \nbeta %% %s %s`, NULL_TERM

__Str1          db `gamma`, NULL_TERM

__Str2          db 10 dup(`delta`), NULL_TERM

__Ascii_Lut     db "0123456789abcdef"

__JmpTbl        dq bprintf.jmp_b - __JmpTbl
                dq bprintf.jmp_c - __JmpTbl
                dq bprintf.jmp_d - __JmpTbl
                dq 10 dup(bprintf.jmp_default - __JmpTbl)
                dq bprintf.jmp_o - __JmpTbl
                dq 3 dup(bprintf.jmp_default - __JmpTbl)
                dq bprintf.jmp_s - __JmpTbl
                dq 4 dup(bprintf.jmp_default - __JmpTbl)
                dq bprintf.jmp_x - __JmpTbl
