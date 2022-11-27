.intel_syntax noprefix
.global json_prettify

.section .rodata
fals:.long 0x66616C73

.section .text

/*
input rdi
output rsi
*/
json_prettify:

    mov al, [rdi]
    /*
    Literal check
    */
    cmp al, 'f'
    je literal_check_false
    cmp al, 't'
    je literal_check_true
    cmp al, 'n'
    je literal_check_null

    /*
    Number check
    */
    cmp al, '-'
    je number_check_start_negative
    cmp al, '0'
    je number_check_start_zero
    cmp al, '1'
    jl skip_number_check
    cmp al, '9'
    jg skip_number_check
    jmp number_check_start_number

    cmp al, '$'
    je end_of_data

end_of_data:
skip_number_check:

    /*
    continue code here
    */
   jmp not_valid_case

    mov rax, 0
    jmp end

not_valid_case:
    mov rax, -1
    jmp end
back_literal_check:
    mov rax, 0
    jmp end
number_check_exit:
    mov rax, 0
    jmp end
literal_error_false:
    mov rax, 1
    jmp end
literal_error_true:
    mov rax, 2
    jmp end
literal_error_null:
    mov rax, 3
    jmp end
literal_number_error:
    mov rax, 4
    jmp end
number_check_not_valid_number_after_negative:
    mov rax, 5
    jmp end
number_check_not_valid_number:
    mov rax, 6
    jmp end
number_check_after_minus_error:
    mov rax, 7
    jmp end
number_check_not_valid_after_first_integer:
    mov rax, 8
    jmp end
number_check_not_valid_after_zero:
    mov rax, 9
    jmp end
number_check_not_valid_after_exponent:
    mov rax, 10
    jmp end
number_check_not_valid_after_exponent_sign:
    mov rax, 11
    jmp end
number_check_not_valid_after_decimal:
    mov rax, 12
    jmp end
number_check_not_valid_decimal:
    mov rax, 13
    jmp end
end:
    ret

number_check_start_negative:
//There needs to be a number after a negative sign
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]
    cmp al, '0'
    je number_check_start_zero
    cmp al, '1'
    jl number_check_after_minus_error
    cmp al, '9'
    jg number_check_after_minus_error
    jmp number_check_start_number

number_check_start_number:
    xor rax, rax
    mov al, [rdi]
    cmp al, '1'
    jl number_check_not_valid_number
    cmp al, '9'
    jg number_check_not_valid_number

    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    cmp al, '}'
    je number_check_exit

    cmp al, 'e'
    je number_check_exponent
    cmp al, 'E'
    je number_check_exponent

    cmp al, '.'
    je number_check_decimal

    cmp al, '0'
    jl number_check_not_valid_after_first_integer
    cmp al, '9'
    jg number_check_not_valid_after_first_integer
    jmp number_check_after_first_integer

number_check_start_zero:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    cmp al, '}'
    je number_check_exit

    cmp al, 'e'
    je number_check_exponent
    cmp al, 'E'
    je number_check_exponent

    cmp al, '.'
    je number_check_decimal

    jmp number_check_not_valid_after_zero

number_check_after_first_integer:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    cmp al, '}'
    je number_check_exit

    cmp al, 'e'
    je number_check_exponent
    cmp al, 'E'
    je number_check_exponent

    cmp al, '.'
    je number_check_decimal

    cmp al, '0'
    jl number_check_not_valid_after_first_integer
    cmp al, '9'
    jg number_check_not_valid_after_first_integer
    jmp number_check_after_first_integer

number_check_exponent:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    cmp al, '+'
    je number_check_exponent_sign
    cmp al, '-'
    je number_check_exponent_sign

    cmp al, '0'
    jl number_check_not_valid_after_exponent
    cmp al, '9'
    jg number_check_not_valid_after_exponent

    jmp number_check_after_exponent

number_check_exponent_sign:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    cmp al, '0'
    jl number_check_not_valid_after_exponent_sign
    cmp al, '9'
    jg number_check_not_valid_after_exponent_sign

    jmp number_check_after_exponent

number_check_after_exponent:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    cmp al, '}'
    je number_check_exit

    cmp al, '0'
    jl number_check_not_valid_after_exponent_sign
    cmp al, '9'
    jg number_check_not_valid_after_exponent_sign

    jmp number_check_after_exponent

number_check_decimal:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    cmp al, '0'
    jl number_check_not_valid_decimal
    cmp al, '9'
    jg number_check_not_valid_decimal

    jmp number_check_after_decimal

number_check_after_decimal:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    cmp al, '}'
    je number_check_exit

    cmp al, 'e'
    je number_check_exponent
    cmp al, 'E'
    je number_check_exponent

    cmp al, '0'
    jl number_check_not_valid_after_decimal
    cmp al, '9'
    jg number_check_not_valid_after_decimal

    jmp number_check_after_decimal

literal_check_false:
    xor rax, rax
    mov al, [rdi]
    cmp al, 'f'
    jne literal_error_false
    mov [rsi], al
    inc rdi
    inc rsi
    mov al, [rdi]
    cmp al, 'a'
    jne literal_error_false
    mov [rsi], al
    inc rdi
    inc rsi
    mov al, [rdi]
    cmp al, 'l'
    jne literal_error_false
    mov [rsi], al
    inc rdi
    inc rsi
    mov al, [rdi]
    cmp al, 's'
    jne literal_error_false
    mov [rsi], al
    inc rdi
    inc rsi
    mov al, [rdi]
    cmp al, 'e'
    jne literal_error_false
    mov [rsi], al
    inc rdi
    inc rsi
    jmp back_literal_check

literal_check_true:
    xor rax, rax
    mov al, [rdi]
    cmp al, 't'
    jne literal_error_true
    mov [rsi], al
    inc rdi
    inc rsi
    mov al, [rdi]
    cmp al, 'r'
    jne literal_error_true
    mov [rsi], al
    inc rdi
    inc rsi
    mov al, [rdi]
    cmp al, 'u'
    jne literal_error_true
    mov [rsi], al
    inc rdi
    inc rsi
    mov al, [rdi]
    cmp al, 'e'
    jne literal_error_true
    mov [rsi], al
    inc rdi
    inc rsi
    jmp back_literal_check

literal_check_null:
    xor rax, rax
    mov al, [rdi]
    cmp al, 'n'
    jne literal_error_null
    mov [rsi], al
    inc rdi
    inc rsi
    mov al, [rdi]
    cmp al, 'u'
    jne literal_error_null
    mov [rsi], al
    inc rdi
    inc rsi
    mov al, [rdi]
    cmp al, 'l'
    jne literal_error_null
    mov [rsi], al
    inc rdi
    inc rsi
    mov al, [rdi]
    cmp al, 'l'
    jne literal_error_null
    mov [rsi], al
    inc rdi
    inc rsi
    jmp back_literal_check



