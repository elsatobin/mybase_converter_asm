.global _main
.align 2

.data
usage_msg:
    .ascii "usage: base_converter <number> <from_base> <to_base>\n"
    .ascii "bases must be between 2 and 36\n"
    .ascii "example: base_converter FF 16 10\n"
    usage_msg_len = . - usage_msg

error_argc_msg:
    .ascii "error: expected exactly 3 arguments\n"
    error_argc_msg_len = . - error_argc_msg

error_base_msg:
    .ascii "error: base must be between 2 and 36\n"
    error_base_msg_len = . - error_base_msg

error_digit_msg:
    .ascii "error: invalid digit for specified base\n"
    error_digit_msg_len = . - error_digit_msg

error_overflow_msg:
    .ascii "error: number too large\n"
    error_overflow_msg_len = . - error_overflow_msg

.text
_main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    
    mov x19, x0 // argc
    mov x20, x1 // argv
    
    cmp x19, #4 // check for 4 arguments (program name + 3 args)
    bne usage_error
    
    ldr x21, [x20, #8] // argv[1] (number string)
    ldr x1, [x20, #16] // argv[2] (from_base string)
    
    bl parse_base // parse from_base
    cmp x0, #0
    blt base_error
    mov x22, x0 // from_base
    
    ldr x1, [x20, #24] // argv[3] (to_base string)
    
    bl parse_base // parse to_base
    cmp x0, #0
    blt base_error
    mov x23, x0 // to_base
    
    mov x1, x21 // number string
    mov x2, x22 // from_base
    bl parse_number // convert number from source base to integer
    cmp x0, #0
    blt digit_error
    mov x24, x0 // parsed number
    
    mov x0, x24 // number
    mov x1, x23 // to_base
    bl print_number // convert integer to target base and print
    
    mov x0, #1 // print newline
    bl print_newline
    
    mov x0, #0 // exit with success
    b main_exit

usage_error:
    mov x0, #2 // stderr
    adrp x1, usage_msg@PAGE
    add x1, x1, usage_msg@PAGEOFF
    mov x2, usage_msg_len
    bl print_string
    mov x0, #1
    b main_exit

base_error:
    mov x0, #2 // stderr
    adrp x1, error_base_msg@PAGE
    add x1, x1, error_base_msg@PAGEOFF
    mov x2, error_base_msg_len
    bl print_string
    mov x0, #1
    b main_exit

digit_error:
    mov x0, #2 // stderr
    adrp x1, error_digit_msg@PAGE
    add x1, x1, error_digit_msg@PAGEOFF
    mov x2, error_digit_msg_len
    bl print_string
    mov x0, #1
    b main_exit

main_exit:
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
