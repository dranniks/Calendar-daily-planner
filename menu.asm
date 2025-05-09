format elf64
public _start

include 'sys-calls.asm'
include 'file-service.asm'

section '.text' executable
;=======================================
; Точка входа
;=======================================
_start:
    call init_db_file
    main_loop:
        call show_menu
        call read_input
        call process_input
        jmp main_loop

    exit_program:
        mov rax, SYS_EXIT
        xor rdi, rdi
        syscall

;=======================================
; Инициализация файла БД
;=======================================
init_db_file:
    mov rdi, db_filename
    mov rsi, O_RDONLY
    call open_file
    cmp rax, 0
    jge .file_exists
    
    mov rdi, db_filename
    mov rsi, O_CREAT or O_WRONLY
    mov rdx, S_IRUSR or S_IWUSR
    call open_file
    mov [db_fd], rax
    mov rdi, rax
    call close_file
    ret
    
    .file_exists:
        mov [db_fd], rax
        mov rdi, rax
        call close_file
        ret

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
    mov rdx, 2
    syscall
    ret

;=======================================
; Обработка ввода
;=======================================
process_input:
    mov al, [input_buffer]
    cmp al, '1'
    je add_event
    cmp al, '2'
    je edit_event
    cmp al, '3'
    je delete_event
    cmp al, '4'
    je show_events
    cmp al, '5'
    je exit_program
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, error_msg
    mov rdx, error_len
    syscall
    ret

;=======================================
; Добавление события
;=======================================
add_event:
    ; Запрос даты
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, date_prompt
    mov rdx, date_prompt_len
    syscall
    
    ; Чтение даты
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, date_buffer
    mov rdx, 11
    syscall
    
    ; Запрос времени
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, time_prompt
    mov rdx, time_prompt_len
    syscall
    
    ; Чтение времени
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, time_buffer
    mov rdx, 6
    syscall
    
    ; Запрос описания
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, desc_prompt
    mov rdx, desc_prompt_len
    syscall
    
    ; Чтение описания
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, desc_buffer
    mov rdx, 100
    syscall
    
    ; Открываем файл для записи
    mov rdi, db_filename
    mov rsi, O_WRONLY or O_APPEND
    call open_file
    mov [db_fd], rax
    
    ; Формируем запись
    mov rsi, event_record
    mov byte [rsi], '['
    inc rsi
    
    ; Копируем дату
    mov rdi, rsi
    mov rsi, date_buffer
    call strcpy
    
    ; Добавляем разделитель
    mov byte [rdi], ' '
    inc rdi
    
    ; Копируем время
    mov rsi, time_buffer
    call strcpy
    
    ; Добавляем закрывающую скобку
    mov byte [rdi], ']'
    inc rdi
    
    ; Добавляем описание
    mov byte [rdi], ' '
    inc rdi
    mov rsi, desc_buffer
    call strcpy
    
    ; Записываем в файл
    mov rax, [db_fd]
    mov rsi, event_record
    call write_file
    
    ; Закрываем файл
    mov rdi, [db_fd]
    call close_file
    
    ret

edit_event:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, edit_msg
    mov rdx, edit_msg_len
    syscall
    ret

;=======================================
; Удаление события (заглушка)
;=======================================
delete_event:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, delete_msg
    mov rdx, delete_msg_len
    syscall
    ret

;=======================================
; Показать события
;=======================================
show_events:
    ; Открываем файл для чтения
    mov rdi, db_filename
    mov rsi, O_RDONLY
    call open_file
    mov [db_fd], rax
    
    ; Читаем содержимое
    mov rdi, rax
    call read_file
    
    ; Выводим в консоль
    call output_buffer_in_console
    
    ; Закрываем файл
    mov rdi, [db_fd]
    call close_file
    
    ret



;=======================================
; Копирование строки
; Вход: RSI = источник, RDI = назначение
; Выход: RAX = длина скопированной строки
;=======================================
strcpy:
    push rdi
    push rsi
    xor rcx, rcx
.copy_loop:
    lodsb                   ; Загружаем байт из [rsi] в AL
    test al, al             ; Проверяем на нуль-терминатор
    jz .copy_done           ; Если 0 - завершаем
    stosb                   ; Сохраняем AL в [rdi]
    inc rcx                 ; Увеличиваем счетчик
    jmp .copy_loop
.copy_done:
    mov byte [rdi], 0       ; Добавляем нуль-терминатор
    mov rax, rcx            ; Возвращаем длину
    pop rsi
    pop rdi
    ret

;=======================================
; Длина строки
; Вход: RAX = адрес строки
; Выход: RAX = длина строки
;=======================================
len_str:
    push rdi
    mov rdi, rax
    xor rax, rax
.count_loop:
    cmp byte [rdi], 0
    je .done
    inc rax
    inc rdi
    jmp .count_loop
.done:
    pop rdi
    ret

;=======================================
; Данные программы
;=======================================
section '.data' writable
    ; Основные сообщения меню
    menu_text db 10, '=== Daily Planner ===', 10
              db '1. Add new event', 10
              db '2. Edit event', 10
              db '3. Delete event', 10
              db '4. View all events', 10
              db '5. Exit', 10
              db 'Your choice: ', 0
    menu_len = $ - menu_text
    
    ; Сообщения об ошибках
    error_msg db 10, 'Error: Invalid input!', 10, 10, 0
    error_len = $ - error_msg
    
    open_error_msg db 'Error opening file!', 0xA, 0
    open_error_len = $ - open_error_msg
    
    read_error_msg db 'Error reading file!', 0xA, 0
    read_error_len = $ - read_error_msg
    
    write_error_msg db 'Error writing to file!', 0xA, 0
    write_error_len = $ - write_error_msg
    
    ; Сообщения для функций
    add_msg db 10, '=== Add New Event ===', 10, 0
    add_msg_len = $ - add_msg
    
    edit_msg db 10, '=== Edit Event ===', 10, 'Enter event number to edit: ', 0
    edit_msg_len = $ - edit_msg
    
    delete_msg db 10, '=== Delete Event ===', 10, 'Enter event number to delete: ', 0
    delete_msg_len = $ - delete_msg
    
    view_msg db 10, '=== All Events ===', 10, 0
    view_msg_len = $ - view_msg
    
    ; Подсказки для ввода
    date_prompt db 'Enter date (YYYY-MM-DD): ', 0
    date_prompt_len = $ - date_prompt
    
    time_prompt db 'Enter time (HH:MM): ', 0
    time_prompt_len = $ - time_prompt
    
    desc_prompt db 'Enter description: ', 0
    desc_prompt_len = $ - desc_prompt
    
    ; Сообщения об успехе
    success_add db 10, 'Event added successfully!', 10, 10, 0
    success_add_len = $ - success_add
    
    success_edit db 10, 'Event edited successfully!', 10, 10, 0
    success_edit_len = $ - success_edit
    
    success_delete db 10, 'Event deleted successfully!', 10, 10, 0
    success_delete_len = $ - success_delete
    
    ; Буферы для ввода
    input_buffer rb 3       ; Для выбора меню (2 цифры + enter)
    num_buffer rb 5         ; Для ввода номеров событий
    date_buffer rb 11       ; YYYY-MM-DD + null
    time_buffer rb 6        ; HH:MM + null
    desc_buffer rb 100      ; Описание события
    event_record rb 150    ; Полная запись события
    
    ; Технические переменные
    db_filename db "events.txt", 0
    db_fd dq 0              ; File descriptor
    event_counter dd 0      ; Счетчик событий

section '.bss' writable
    buffer rb 4096