format ELF64
public _start

section '.text' executable

_start:
    ; Открытие файла (sys_open)
    mov rax, 2
    mov rdi, filename
    xor rsi, rsi        ; O_RDONLY
    syscall
    cmp rax, 0
    jl error
    mov [fd], rax

    ; Определение размера файла (sys_lseek)
    mov rax, 8
    mov rdi, [fd]
    xor rsi, rsi        ; offset 0
    mov rdx, 2          ; SEEK_END
    syscall
    mov [file_size], rax

    ; Перемещение в начало файла
    mov rax, 8
    mov rdi, [fd]
    xor rsi, rsi        ; offset 0
    xor rdx, rdx        ; SEEK_SET
    syscall

    ; Выделение памяти (sys_brk)
    mov rax, 12
    mov rdi, 0
    syscall
    mov [heap_start], rax
    add rax, [file_size]
    inc rax
    mov rdi, rax
    mov rax, 12
    syscall

    ; Чтение файла (sys_read)
    mov rax, 0
    mov rdi, [fd]
    mov rsi, [heap_start]
    mov rdx, [file_size]
    syscall

    ; Закрытие файла (sys_close)
    mov rax, 3
    mov rdi, [fd]
    syscall

    ; Разделение на строки
    mov rsi, [heap_start]
    lea rdi, [array_ptr]
    xor rcx, rcx
    mov [rdi], rsi
    inc rcx

process_buffer:
    cmp byte [rsi], 0
    je done_split
    cmp byte [rsi], 0x0A
    jne next_char
    mov byte [rsi], 0
    inc rsi
    mov [rdi + rcx*8], rsi
    inc rcx
    jmp process_buffer
next_char:
    inc rsi
    jmp process_buffer

done_split:
    mov [num_lines], rcx

    ; Сортировка пузырьком
    mov rcx, [num_lines]
    dec rcx
    jbe print_lines

outer_loop:
    push rcx
    lea rsi, [array_ptr]
    xor rdx, rdx

inner_loop:
    mov rax, [rsi]
    mov rbx, [rsi + 8]
    mov rdi, rax
    mov rsi_saved, rsi  ; Сохраняем rsi
    mov rdi, rax
    mov rsi, rbx
    call compare_dates
    mov rsi, rsi_saved  ; Восстанавливаем rsi
    cmp rax, 1
    jle no_swap
    mov rax, [rsi]
    mov rbx, [rsi + 8]
    mov [rsi + 8], rax
    mov [rsi], rbx
    mov rdx, 1
no_swap:
    add rsi, 8
    loop inner_loop

    pop rcx
    test rdx, rdx
    jz print_lines
    dec rcx
    jnz outer_loop

print_lines:
    ; Вывод строк
    mov rcx, [num_lines]
    lea rsi, [array_ptr]

print_loop:
    test rcx, rcx
    jz exit
    mov rdi, [rsi]
    call strlen
    mov rdx, rax
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, [rsi]
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    add rsi, 8
    dec rcx
    jmp print_loop

exit:
    ; Завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall

error:
    ; Обработка ошибки
    mov rax, 1
    mov rdi, 2
    mov rsi, error_msg
    mov rdx, error_len
    syscall
    mov rax, 60
    mov rdi, 1
    syscall

compare_dates:
    ; Сохраняем регистры
    push r12
    push r13
    push r14
    push r15
    
    mov r12, rdi  ; Первая строка
    mov r13, rsi  ; Вторая строка
    
    ; Парсинг первой даты
    lea rdi, [r12 + 1]
    call parse_date
    mov r14, rax  ; year1
    mov r15, rbx  ; month1
    mov r8, rcx   ; day1
    mov r9, rdx   ; hour1
    mov r10, rsi  ; minute1

    ; Парсинг второй даты
    lea rdi, [r13 + 1]
    call parse_date

    ; Сравнение
    cmp r14, rax
    jl .less
    jg .greater
    cmp r15, rbx
    jl .less
    jg .greater
    cmp r8, rcx
    jl .less
    jg .greater
    cmp r9, rdx
    jl .less
    jg .greater
    cmp r10, rsi
    jl .less
    jg .greater
    xor rax, rax
    jmp .done
.less:
    mov rax, -1
    jmp .done
.greater:
    mov rax, 1
.done:
    ; Восстанавливаем регистры
    pop r15
    pop r14
    pop r13
    pop r12
    ret

parse_date:
    ; Парсинг даты из rdi (64-битный вариант)
    call atoi_4
    push rax       ; year
    add rdi, 5
    call atoi_2
    push rax       ; month
    add rdi, 3
    call atoi_2
    push rax       ; day
    add rdi, 3
    call atoi_2
    push rax       ; hour
    add rdi, 3
    call atoi_2
    push rax       ; minute
    
    ; Извлекаем значения в 64-битные регистры
    pop rsi        ; minute
    pop rdx        ; hour
    pop rcx        ; day
    pop rbx        ; month
    pop rax        ; year
    ret

atoi_4:
    ; Конвертация 4 символов (64-битная)
    xor eax, eax
    mov ecx, 4
.loop:
    imul rax, 10
    movzx edx, byte [rdi]
    sub edx, '0'
    add rax, rdx
    inc rdi
    loop .loop
    ret

atoi_2:
    ; Конвертация 2 символов (64-битная)
    xor eax, eax
    movzx edx, byte [rdi]
    sub edx, '0'
    imul rax, 10
    add rax, rdx
    inc rdi
    movzx edx, byte [rdi]
    sub edx, '0'
    imul rax, 10
    add rax, rdx
    inc rdi
    ret

strlen:
    ; Длина строки в rdi (64-битная)
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

section '.data' writable

filename db "events.txt",0
error_msg db "Error!",0xA
error_len = $ - error_msg
newline db 0xA

fd dq 0
file_size dq 0
heap_start dq 0
array_ptr dq 100 dup(0)
num_lines dq 0
rsi_saved dq 0  ; Для временного хранения rsi