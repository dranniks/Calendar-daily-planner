format ELF64 executable 3

; Системные вызовы
SYS_WRITE = 1
SYS_READ  = 0
SYS_EXIT  = 60

; Дескрипторы файлов
STDIN  = 0
STDOUT = 1

segment readable executable
entry _start

;=======================================
; Точка входа
;=======================================
_start:
    main_loop:
        call show_menu        ; Показать меню
        call read_input       ; Прочитать ввод
        call process_input    ; Обработать выбор
        jmp main_loop         ; Повторить цикл

    exit_program:
        mov rax, SYS_EXIT
        xor rdi, rdi
        syscall

;=======================================
; Показать меню
;=======================================
show_menu:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, menu_text
    mov rdx, menu_len
    syscall
    ret

;=======================================
; Прочитать ввод пользователя
;=======================================
read_input:
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, input_buffer
    mov rdx, 2               ; Читаем 1 символ + \n
    syscall
    ret

;=======================================
; Обработка ввода
;=======================================
process_input:
    mov al, [input_buffer]
    cmp al, '1'
    je .option1
    cmp al, '2'
    je .option2
    cmp al, '3'
    je exit_program
    
    ; Неверный ввод
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, error_msg
    mov rdx, error_len
    syscall
    ret
    
    .option1:
        mov rax, SYS_WRITE
        mov rdi, STDOUT
        mov rsi, msg1
        mov rdx, msg1_len
        syscall
        ret
        
    .option2:
        mov rax, SYS_WRITE
        mov rdi, STDOUT
        mov rsi, msg2
        mov rdx, msg2_len
        syscall
        ret

;=======================================
; Данные программы
;=======================================
segment readable writeable
    menu_text db 10, '=== Menu ===', 10
              db '1. Show message 1', 10
              db '2. Show message 2', 10
              db '3. Exit', 10
              db 'Your choice: '
    menu_len = $ - menu_text
    
    error_msg db 10, 'Invalid input!', 10, 10
    error_len = $ - error_msg
    
    msg1 db 10, 'Hello from option 1!', 10, 10
    msg1_len = $ - msg1
    
    msg2 db 10, 'Hello from option 2!', 10, 10
    msg2_len = $ - msg2
    
    input_buffer rb 2    ; Буфер для ввода (1 символ + \n)