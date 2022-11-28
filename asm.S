.intel_syntax noprefix
.global json_prettify

.section .rodata
fals:.long 0x66616C73

.section .text

/*
Whitespace
0x20              ; Space
0x09              ; Horizontal tab
0x0A              ; Line feed or New line
0x0D              ; Carriage return
/*

input rdi
output rsi
*/
json_prettify:

    //Indentation counter
    mov r8, 0

    xor r11, r11 //Boolean if another array value is expected

    //Push for the bottom level json file, TODO don't forget to pop this or fix RSP
    xor r9, r9
    mov r9, ' '
    push r9

    //Move first character to al
    mov al, [rdi]
value_check:
    mov al, [rdi]

    /*
    EOF check
    */
    cmp al, 0x00
    je end_of_data

    /*
    Check if current value check is in array, and re-push into r9
    */
    pop r9
    push r9
    cmp r9, ']'
    je in_array
    jmp not_array
in_array:
    //Skip through all whitespace
    cmp al, 0x20
    je skip_whitespace
    cmp al, 0x09
    je skip_whitespace
    cmp al, 0x0A
    je skip_whitespace
    cmp al, 0x0D
    je skip_whitespace

    cmp al, ','
    je array_comma
    cmp al, ']'
    je array_close

    cmp r11, 1
    je next_array_value
    jmp array_element_error
array_comma:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]
    
    //Boolean if a value is expected, 1 is another array value expected, otherwise not.
    mov r11, 1
    jmp value_check
not_array:
    /*
    Array check
    */
    cmp al, '['
    je array_open
    jmp no_array_open
array_open:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    mov r11, 1

    inc r8  //Increment indentation counter
    xor r9, r9
    mov r9, ']' //push closing bracket in
    push r9 //#WARNING TODO: ALL THE PUSHED ELEMENTS NEED TO BE POPPED IN THE CASE OF AN ERROR
    
    //add rsp, 8 //TODO: This is how you clear the remaining stack, multiplied by the amount of indentations

    jmp value_check

skip_whitespace:
    inc rdi
    jmp value_check
array_close:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    add r8, -1
    add rsp, 8
    jmp value_check
no_array_open:
next_array_value:
    mov r11, 0
    /*
    Literal check
    */
    cmp al, '['
    je array_open

literal_check:
    cmp al, 'f'
    je literal_check_false
    cmp al, 't'
    je literal_check_true
    cmp al, 'n'
    je literal_check_null
    
    /*
    String check
    */
string_check:
    cmp al, '"'
    je string_check_start

    /*
    Number check
    */
number_check:
    cmp al, '-'
    je number_check_start_negative
    cmp al, '0'
    je number_check_start_zero
    cmp al, '1' 
    jae number_check_upper_bound
    jmp not_number_check
number_check_upper_bound:
    cmp al, '9'
    ja not_number_check
    jmp number_check_start_number

not_number_check:
    /*
    Fail
    */
   jmp invalid_character
/*
=======================================================================================================================
RETURNS
=======================================================================================================================
*/
array_element_error:
    mov rax, 16
    jmp end
invalid_character:
//If you land here, comment the error code below to see the last character read!
    mov rax, -42
    jmp end
end_of_data:
    mov rax, 0
    jmp end
back_literal_check:
    jmp value_check
number_check_exit:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]
    jmp value_check
string_check_exit:
    jmp value_check
invalid_number_check:
    mov rax, -2
    jmp end
not_valid_case:
    mov rax, -1
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
string_check_escaped_character_invalid:
    mov rax, 14
    jmp end
string_check_invalid_unescaped_character:
    mov rax, 15
    jmp end
end:
    //Pop base value json indicator TODO
    add rsp, 8
    ret
/*
=======================================================================================================================
STRING CHECKS
=======================================================================================================================
*/

string_check_start:
    //print the quotation mark, move pointer forward
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]
string_check_loop:
    //Check control character
    cmp al, 0x5C
    je string_check_control_character
    
    cmp al, '"'
    je string_check_done

    cmp al, 0x20
    je string_check_valid_unescaped_character
    cmp al, 0x21
    je string_check_valid_unescaped_character

    cmp al, 0x23
    jae string_check_unescaped_character_first
string_check_unescaped_character_not_first:
    cmp al, 0x5D
    jae string_check_unescaped_character_second
string_check_unescaped_character_not_second:
    jmp string_check_invalid_unescaped_character

string_check_unescaped_character_first:
    cmp al, 0x5B
    jbe string_check_valid_unescaped_character
    jmp string_check_unescaped_character_not_first
string_check_unescaped_character_second:
    cmp al, 0x10FFFF
    jbe string_check_valid_unescaped_character
    jmp string_check_unescaped_character_not_second

string_check_valid_unescaped_character:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]
    jmp string_check_loop

string_check_done:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]
    jmp string_check_exit

string_check_control_character:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    //Check escaped control characters
    cmp al,'"'
    je string_check_control_character_ok
    cmp al,0x5C
    je string_check_control_character_ok
    cmp al,0x2F
    je string_check_control_character_ok
    cmp al,0x62
    je string_check_control_character_ok
    cmp al,0x66
    je string_check_control_character_ok
    cmp al,0x6E
    je string_check_control_character_ok
    cmp al,0x72
    je string_check_control_character_ok
    cmp al,0x74
    je string_check_control_character_ok
    cmp al, 0x75
    je string_check_escaped_character

string_check_control_character_ok:
    //Print escaped control characters
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    jmp string_check_loop

string_check_escaped_character:
    //Print escaped 'u' character
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    //count 4 hex digits, check if every input is a valid hex input.
    xor rcx, rcx
    mov rcx, 0
string_check_escaped_character_loop:
    cmp al, '0'
    jae string_check_escaped_character_number
string_check_escaped_character_not_number:
    cmp al, 'a'
    jae string_check_escaped_character_lower_character
string_check_escaped_character_not_lower_character:
    cmp al, 'A'
    jae string_check_escaped_character_upper_character
string_check_escaped_character_not_upper_character:
    jmp string_check_escaped_character_invalid
string_check_escaped_character_valid:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    inc rcx
    cmp rcx, 4
    //Jump back to normal character loop
    je string_check_loop
    jmp string_check_escaped_character_loop

string_check_escaped_character_number:
    cmp al, '9'
    jbe string_check_escaped_character_valid
    jmp string_check_escaped_character_not_number
string_check_escaped_character_lower_character:
    cmp al, 'f'
    jbe string_check_escaped_character_valid
    jmp string_check_escaped_character_not_lower_character
string_check_escaped_character_upper_character:
    cmp al, 'F'
    jbe string_check_escaped_character_valid
    jmp string_check_escaped_character_not_upper_character



/*
=======================================================================================================================
NUMBER CHECKS
=======================================================================================================================
*/
number_check_start_negative:
//There needs to be a number after a negative sign
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]
    cmp al, '0'
    je number_check_start_zero
    cmp al, '1'
    jb number_check_after_minus_error
    cmp al, '9'
    ja number_check_after_minus_error
    jmp number_check_start_number

number_check_start_number:
    xor rax, rax
    mov al, [rdi]
    cmp al, '1'
    jb number_check_not_valid_number
    cmp al, '9'
    ja number_check_not_valid_number

    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    cmp al, 'e'
    je number_check_exponent
    cmp al, 'E'
    je number_check_exponent

    cmp al, '.'
    je number_check_decimal

    cmp al, '0'
    jae number_check_after_first_integer_upper_bound
    jmp value_check
number_check_after_first_integer_upper_bound:
    cmp al, '9'
    ja value_check
    jmp number_check_after_first_integer

    

number_check_start_zero:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    cmp al, 'e'
    je number_check_exponent
    cmp al, 'E'
    je number_check_exponent

    cmp al, '.'
    je number_check_decimal

    jmp value_check

number_check_after_first_integer:
    mov [rsi], al
    inc rsi
    inc rdi
    mov al, [rdi]

    cmp al, 'e'
    je number_check_exponent
    cmp al, 'E'
    je number_check_exponent

    cmp al, '.'
    je number_check_decimal

    cmp al, '0'
    jae number_check_not_valid_after_first_integer_upper_bound
    jmp value_check
number_check_not_valid_after_first_integer_upper_bound:
    cmp al, '9'
    ja value_check
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
    jb number_check_not_valid_after_exponent
    cmp al, '9'
    ja number_check_not_valid_after_exponent

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

    cmp al, '0'
    jae number_check_not_valid_after_exponent_sign_upper_bound
    jmp value_check
number_check_not_valid_after_exponent_sign_upper_bound:
    cmp al, '9'
    ja value_check

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

    cmp al, 'e'
    je number_check_exponent
    cmp al, 'E'
    je number_check_exponent

    cmp al, '0'
    jae number_check_not_valid_after_decimal_upper_bound
    jmp value_check
number_check_not_valid_after_decimal_upper_bound:
    cmp al, '9'
    ja number_check_not_valid_after_decimal

    jmp number_check_after_decimal

/*
=======================================================================================================================
LITERAL CHECKS
=======================================================================================================================
*/
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




