
                section         .text
 
                global          _start
_start:
 
                sub             rsp, 2 * 128 * 8
                lea             rdi, [rsp + 128 * 8]
                mov             rcx, 128
                call            read_long
                mov             rdi, rsp
                call            read_long
                lea             rsi, [rsp + 128 * 8]
                sub             rsp, 256 * 8
                mov             r9, rsp
                call            mul_long_long
               
                mov             rcx, 256
                mov             rdi, r9
                call            write_long
 
                mov             al, 0x0a
                call            write_char
 
                jmp             exit
 
; multiplies two long number
;    rdi -- address of term #1 (long number)
;    rsi -- address of term #2 (long number)
;    rcx -- length of long numbers in qwords
; result:
;    product is written to r9
mul_long_long:
        push             rdi
        push             rsi
        push             rcx
        push             r8
        push             r10
        push             r11
        push             r12
       
        lea              r14, [8 * rcx]   ; size_t size = 8 * 128
 
        xor              r10, r10         ; for (size_t i = 0; i < size; ++i) {
.loop_a:
        xor              r8, r8           ;         size_t carry = 0;
        xor              r11, r11         ;         for (size_t j = 0; j < size; ++j) {
.loop_b:
        xor              r12, r12         ;             size_t tmp = 0;
        add              r12, r8          ;             tmp += carry;
        xor              r8, r8           ;             carry = 0;
       
        push             r14
        mov              r14, r9
        add              r14, r10         ;             tmp += c[i + j], update(carry);
        add              r14, r11
        add              r12, [r14]
        adc              r8, 0
       
        push             r13
        push             rdi
        mov              r13, rdi         ;             tmp += a[i] * b[j], update(carry);
        mov              r14, rsi
        add              r13, r10
        add              r14, r11
        mov              rax, [r13]
        mov              rdi, [r14]
        mul              rdi
        add              r8, rdx
        add              r12, rax
        adc              r8, 0
       
        mov              r13, r9
        add              r13, r10
        add              r13, r11
        mov              [r13], r12
       
        pop              rdi
        pop              r13
        pop              r14
       
        lea              r11, [r11 + 8]
        cmp              r11, r14
        jnz              .loop_b          ;         }
       
        push             r9
        add              r9, r14
        add              r9, r10          ;         c[i + size] = carry;
        mov              [r9], r8
        pop              r9
       
        lea              r10, [r10 + 8]
        cmp              r10, r14
        jnz              .loop_a          ;         }
 
 
        pop              r12
        pop              r11
        pop              r10
        pop              r8
        pop              rcx
        pop              rsi
        pop              rdi
        ret
 
 
 
 
 
 
; adds two long number
;    rdi -- address of summand #1 (long number)
;    rsi -- address of summand #2 (long number)
;    rcx -- length of long numbers in qwords
; result:
;    sum is written to rdi
add_long_long:
                push            rdi
                push            rsi
                push            rcx
 
                clc
.loop:
                mov             rax, [rsi]
                lea             rsi, [rsi + 8]
                adc             [rdi], rax
                lea             rdi, [rdi + 8]
                dec             rcx
                jnz             .loop
 
                pop             rcx
                pop             rsi
                pop             rdi
                ret
 
; adds 64-bit number to long number
;    rdi -- address of summand #1 (long number)
;    rax -- summand #2 (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    sum is written to rdi
add_long_short:
                push            rdi
                push            rcx
                push            rdx
 
                xor             rdx,rdx
.loop:
                add             [rdi], rax
                adc             rdx, 0
                mov             rax, rdx
                xor             rdx, rdx
                add             rdi, 8
                dec             rcx
                jnz             .loop
 
                pop             rdx
                pop             rcx
                pop             rdi
                ret
 
; multiplies long number by a short
;    rdi -- address of multiplier #1 (long number)
;    rbx -- multiplier #2 (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    product is written to rdi
mul_long_short:
                push            rax
                push            rdi
                push            rcx
 
                xor             rsi, rsi
.loop:
                mov             rax, [rdi]
                mul             rbx
                add             rax, rsi
                adc             rdx, 0
                mov             [rdi], rax
                add             rdi, 8
                mov             rsi, rdx
                dec             rcx
                jnz             .loop
 
                pop             rcx
                pop             rdi
                pop             rax
                ret
 
; divides long number by a short
;    rdi -- address of dividend (long number)
;    rbx -- divisor (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    quotient is written to rdi
;    rdx -- remainder
div_long_short:
                push            rdi
                push            rax
                push            rcx
 
                lea             rdi, [rdi + 8 * rcx - 8]
                xor             rdx, rdx
 
.loop:
                mov             rax, [rdi]
                div             rbx
                mov             [rdi], rax
                sub             rdi, 8
                dec             rcx
                jnz             .loop
 
                pop             rcx
                pop             rax
                pop             rdi
                ret
 
; assigns a zero to long number
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
set_zero:
                push            rax
                push            rdi
                push            rcx
 
                xor             rax, rax
                rep stosq
 
                pop             rcx
                pop             rdi
                pop             rax
                ret
 
; checks if a long number is a zero
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
; result:
;    ZF=1 if zero
is_zero:
                push            rax
                push            rdi
                push            rcx
 
                xor             rax, rax
                rep scasq
 
                pop             rcx
                pop             rdi
                pop             rax
                ret
 
; read long number from stdin
;    rdi -- location for output (long number)
;    rcx -- length of long number in qwords
read_long:
                push            rcx
                push            rdi
 
                call            set_zero
.loop:
                call            read_char
                or              rax, rax
                js              exit
                cmp             rax, 0x0a
                je              .done
                cmp             rax, '0'
                jb              .invalid_char
                cmp             rax, '9'
                ja              .invalid_char
 
                sub             rax, '0'
                mov             rbx, 10
                call            mul_long_short
                call            add_long_short
                jmp             .loop
 
.done:
                pop             rdi
                pop             rcx
                ret
 
.invalid_char:
                mov             rsi, invalid_char_msg
                mov             rdx, invalid_char_msg_size
                call            print_string
                call            write_char
                mov             al, 0x0a
                call            write_char
 
.skip_loop:
                call            read_char
                or              rax, rax
                js              exit
                cmp             rax, 0x0a
                je              exit
                jmp             .skip_loop
 
; write long number to stdout
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
write_long:
                push            rax
                push            rcx
 
                mov             rax, 20
                mul             rcx
                mov             rbp, rsp
                sub             rsp, rax
 
                mov             rsi, rbp
 
.loop:
                mov             rbx, 10
                call            div_long_short
                add             rdx, '0'
                dec             rsi
                mov             [rsi], dl
                call            is_zero
                jnz             .loop
 
                mov             rdx, rbp
                sub             rdx, rsi
                call            print_string
 
                mov             rsp, rbp
                pop             rcx
                pop             rax
                ret
 
; read one char from stdin
; result:
;    rax == -1 if error occurs
;    rax \in [0; 255] if OK
read_char:
                push            rcx
                push            rdi
 
                sub             rsp, 1
                xor             rax, rax
                xor             rdi, rdi
                mov             rsi, rsp
                mov             rdx, 1
                syscall
 
                cmp             rax, 1
                jne             .error
                xor             rax, rax
                mov             al, [rsp]
                add             rsp, 1
 
                pop             rdi
                pop             rcx
                ret
.error:
                mov             rax, -1
                add             rsp, 1
                pop             rdi
                pop             rcx
                ret
 
; write one char to stdout, errors are ignored
;    al -- char
write_char:
                sub             rsp, 1
                mov             [rsp], al
 
                mov             rax, 1
                mov             rdi, 1
                mov             rsi, rsp
                mov             rdx, 1
                syscall
                add             rsp, 1
                ret
 
exit:
                mov             rax, 60
                xor             rdi, rdi
                syscall
 
; print string to stdout
;    rsi -- string
;    rdx -- size
print_string:
                push            rax
 
                mov             rax, 1
                mov             rdi, 1
                syscall
 
                pop             rax
                ret
 
 
                section         .rodata
invalid_char_msg:
                db              "Invalid character: "
invalid_char_msg_size: equ             $ - invalid_char_msg
