.global print_string
.global print_cstring
.global print_newline
.global strlen
.global exit_program
.global parse_base
.global parse_number
.global print_number
.global char_to_digit
.global digit_to_char
.align 2

.data
newline_char:
    .ascii "\n"

.text

// print_string: prints a string of known length
// x0: file descriptor (1 for stdout)
// x1: string address
// x2: string length
print_string:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
   
    mov x16, #4 // syscall for write
    svc #0x80
    
    ldp x29, x30, [sp], #16
    ret

// print_cstring: prints a null-terminated string
// x0: file descriptor (1 for stdout)
// x1: string address
print_cstring:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    
    mov x19, x0 // file descriptor
    mov x20, x1 // string address
    
    // calculate string length
    bl strlen
    mov x2, x0 // length to x2
    
    // print the string
    mov x0, x19 // restore file descriptor
    mov x1, x20 // restore string address
    bl print_string
    
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// print_newline: prints a newline character
// x0: file descriptor (1 for stdout)
print_newline:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    adrp x1, newline_char@PAGE
    add x1, x1, newline_char@PAGEOFF
    mov x2, #1
    bl print_string
    
    ldp x29, x30, [sp], #16
    ret

// strlen: calculates length of null-terminated string
// x1: string address
// returns: x0 = string length
strlen:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    mov x2, x1 // use x2 as moving pointer
    mov x0, #0 // use x0 as length counter

strlen_loop:
    ldrb w3, [x2], #1
    cmp w3, #0
    beq strlen_done
    add x0, x0, #1
    cmp x0, #1000 // safety limit
    bge strlen_done
    b strlen_loop
    
strlen_done:
    ldp x29, x30, [sp], #16
    ret

// exit_program: exits the program
// x0: exit code
exit_program:
    mov x16, #1 // syscall for exit on macos
    svc #0x80

// parse_base: parses a base from string (2-36)
// x1: string address
// returns: x0 = base (or negative on error)
parse_base:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    
    mov x19, x1 // save string address
    
    // convert string to integer
    bl atoi_simple
    mov x20, x0 // save result
    
    // validate base range (2-36)
    cmp x20, #2
    blt parse_base_error
    cmp x20, #36
    bgt parse_base_error
    
    mov x0, x20 // return base
    b parse_base_exit

parse_base_error:
    mov x0, #-1 // error return
    
parse_base_exit:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// atoi_simple: converts decimal string to integer
// x1: string address
// returns: x0 = integer value
atoi_simple:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    mov x2, x1 // string pointer
    mov x0, #0 // result
    
atoi_loop:
    ldrb w4, [x2], #1 // load next character
    cmp w4, #0 // check for null terminator
    beq atoi_done
    
    // check if character is digit
    cmp w4, #'0'
    blt atoi_done
    cmp w4, #'9'
    bgt atoi_done
    
    // convert char to digit and accumulate
    sub w4, w4, #'0'
    mov x3, #10 // base 10
    mul x0, x0, x3 // result *= 10
    add x0, x0, x4, sxtx // result += digit
    
    b atoi_loop

atoi_done:
    ldp x29, x30, [sp], #16
    ret

// char_to_digit: converts character to digit value
// x0: character
// returns: x0 = digit value (0-35) or -1 if invalid
char_to_digit:
    // check if digit 0-9
    cmp w0, #'0'
    blt check_upper
    cmp w0, #'9'
    bgt check_upper
    // it is a digit
    sub w0, w0, #'0'
    ret

check_upper:
    // check if uppercase letter A-Z
    cmp w0, #'A'
    blt check_lower
    cmp w0, #'Z'
    bgt check_lower
    // it is an uppercase letter
    sub w0, w0, #'A'
    add w0, w0, #10
    ret

check_lower:
    // check if lowercase letter a-z
    cmp w0, #'a'
    blt char_to_digit_error
    cmp w0, #'z'
    bgt char_to_digit_error
    // it is a lowercase letter
    sub w0, w0, #'a'
    add w0, w0, #10
    ret

char_to_digit_error:
    mov x0, #-1
    ret

// digit_to_char: converts digit value to character
// x0: digit value (0-35)
// returns: x0 = character
digit_to_char:
    cmp w0, #10
    blt digit_to_char_numeric
    
    // convert 10-35 to 'A'-'Z'
    sub w0, w0, #10
    add w0, w0, #'A'
    ret

digit_to_char_numeric:
    // convert 0-9 to '0'-'9'
    add w0, w0, #'0'
    ret

// parse_number: converts string to integer in given base
// x1: string address
// x2: base
// returns: x0 = integer value (or negative on error)
parse_number:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    
    mov x19, x1 // string address
    mov x20, x2 // base
    mov x21, #0 // result
    mov x22, x19 // string pointer
    
parse_number_loop:
    ldrb w0, [x22], #1 // load next character
    cmp w0, #0 // check for null terminator
    beq parse_number_done
    
    // convert character to digit
    bl char_to_digit
    cmp x0, #0
    blt parse_number_error // invalid character
    
    // check if digit is valid for base
    cmp x0, x20
    bge parse_number_error // digit >= base
    
    // check for overflow before multiplication
    mov x3, #-1 // x3 = MAX_UINT64
    udiv x4, x3, x20 // x4 = MAX_UINT64 / base
    cmp x21, x4
    bhi parse_number_error // if result > (MAX_UINT64 / base), potential overflow

    // accumulate: result = result * base + digit
    mul x21, x21, x20
    
    // check for overflow after multiplication (before addition)
    mov x3, #-1
    sub x3, x3, x0 // x3 = MAX_UINT64 - digit
    cmp x21, x3
    bhi parse_number_error // if result > (MAX_UINT64 - digit), overflow

    add x21, x21, x0
    
    b parse_number_loop

parse_number_done:
    mov x0, x21 // return result
    b parse_number_exit

parse_number_error:
    mov x0, #-1 // error return
    
parse_number_exit:
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// print_number: converts integer to string in given base and prints
// x0: number
// x1: base
print_number:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    str x23, [sp, #48]
    
    mov x19, x0 // number
    mov x20, x1 // base
    add x21, sp, #56 // buffer pointer (8 bytes from top)
    mov x22, x21 // save buffer start
    
    // handle zero case
    cmp x19, #0
    bne print_number_convert
    mov w0, #'0'
    strb w0, [x21], #1
    b print_number_output

print_number_convert:
    // convert number to string (reverse order)
    cmp x19, #0
    beq print_number_output
    
    udiv x23, x19, x20 // quotient
    msub x0, x23, x20, x19 // remainder = number - (quotient * base)
    
    // convert digit to character
    bl digit_to_char
    strb w0, [x21], #1 // store character
    
    mov x19, x23 // number = quotient
    b print_number_convert

print_number_output:
    // null terminate
    mov w0, #0
    strb w0, [x21]
    
    // reverse the string in place
    sub x21, x21, #1 // point to last character
    mov x0, x22                  // start
    mov x1, x21                  // end
    bl reverse_string
    
    // print the string
    mov x0, #1 // stdout
    mov x1, x22 // string
    bl print_cstring
    
    ldr x23, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

// reverse_string: reverse string in place
// x0: start pointer
// x1: end pointer
reverse_string:
    cmp x0, x1
    bge reverse_string_done
    
    ldrb w2, [x0] // load from start
    ldrb w3, [x1] // load from end
    strb w3, [x0], #1 // store end at start, increment start
    strb w2, [x1], #-1 // store start at end, decrement end
    
    b reverse_string
    
reverse_string_done:
    ret