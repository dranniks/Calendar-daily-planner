; sort.inc

struc event_entry {
    .ptr   dq ?
    .len   dq ?
    .year  dq ?
    .month dq ?
    .day   dq ?
    .hour  dq ?
    .minute dq ?
}

section '.text' executable

;=======================================
; Сортировка событий в файле
;=======================================
sort_events:
    push r12
    push r13
    push r14
    push r15
    push rbx
    
    ; 1. Чтение файла в буфер
    mov rdi, db_filename
    mov rsi, O_RDWR
    call open_file
    cmp rax, -1
    je .error
    mov r12, rax                 ; Сохраняем файловый дескриптор
    
    mov rdi, rax
    mov rsi, buffer
    mov rdx, 4096
    call read_file
    mov r13, rax                 ; Сохраняем размер файла
    
    ; 2. Разбиение на записи
    call parse_entries
    test rax, rax
    jz .close_file
    
    ; 3. Сортировка записей
    call qsort_events
    
    ; 4. Перезапись файла
    mov rdi, buffer
    mov rsi, temp_buffer
    call rebuild_buffer
    
    mov rdi, r12
    mov rsi, temp_buffer
    mov rdx, r13
    call write_file
    mov rdi, r12
    call close_file
    
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret
    
.error:
    mov rsi, sort_error_msg
    mov rdx, sort_error_len
    call print_message
.close_file:
    mov rdi, r12
    call close_file
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

parse_entries:
    ; Инициализация
    mov rsi, buffer
    lea rdi, [buffer + r13]
    xor rcx, rcx                ; Счетчик записей
    
.parse_loop:
    cmp rsi, rdi
    jge .done
    
    ; Поиск новой строки
    mov rdx, rsi
.search_newline:
    cmp byte [rdx], 0xA
    je .found
    inc rdx
    cmp rdx, rdi
    jl .search_newline
    jmp .done
    
.found:
    ; Сохраняем запись
    mov r14, rsi                ; Начало строки
    mov r15, rdx                ; Конец строки
    
    ; Создаем структуру entry
    lea rax, [event_entries + rcx*56]
    mov [rax + event_entry.ptr], r14
    mov [rax + event_entry.len], r15
    sub [rax + event_entry.len], r14
    
    ; Парсинг даты
    call parse_datetime
    test rax, rax
    jz .invalid
    
    inc rcx
    mov rsi, r15
    inc rsi                     ; Пропускаем \n
    jmp .parse_loop
    
.invalid:
    ; Пропускаем битую запись
    mov rsi, r15
    inc rsi
    jmp .parse_loop
    
.done:
    mov [num_entries], rcx
    mov rax, rcx
    ret

parse_datetime:
    ; R14 = начало строки
    lea rbx, [r14 + 1]          ; Пропускаем '['
    
    ; Год (4 цифры)
    mov rdi, rbx
    call parse_number
    mov [rax + event_entry.year], rdx
    add rbx, 4
    
    ; Месяц (2 цифры)
    inc rbx                     ; Пропускаем '-'
    mov rdi, rbx
    call parse_number
    mov [rax + event_entry.month], rdx
    add rbx, 2
    
    ; День (2 цифры)
    inc rbx                     ; Пропускаем '-'
    mov rdi, rbx
    call parse_number
    mov [rax + event_entry.day], rdx
    add rbx, 2
    
    ; Час (2 цифры)
    inc rbx                     ; Пропускаем ' '
    mov rdi, rbx
    call parse_number
    mov [rax + event_entry.hour], rdx
    add rbx, 2
    
    ; Минуты (2 цифры)
    inc rbx                     ; Пропускаем ':'
    mov rdi, rbx
    call parse_number
    mov [rax + event_entry.minute], rdx
    
    ret

parse_number:
    xor rdx, rdx
    movzx rax, byte [rdi]
    sub al, '0'
    imul rdx, 10
    add rdx, rax
    movzx rax, byte [rdi+1]
    sub al, '0'
    imul rdx, 10
    add rdx, rax
    ret

qsort_events:
    ; Реализация быстрой сортировки
    mov rcx, [num_entries]
    dec rcx
    jle .done
    
    mov rsi, event_entries      ; Массив
    mov rdi, 0                  ; low
    mov rdx, rcx                ; high
    
    call quicksort
.done:
    ret

quicksort:
    push rdi
    push rdx
    cmp rdi, rdx
    jge .end
    
    call partition
    mov rcx, rax
    
    mov rdx, rcx
    dec rdx
    call quicksort
    
    mov rdi, rcx
    inc rdi
    pop rdx
    push rdx
    call quicksort
    
.end:
    pop rdx
    pop rdi
    ret

partition:
    mov rax, rdx
    imul rax, 56
    add rax, event_entries
    mov r8, [rax + event_entry.year]
    mov r9, [rax + event_entry.month]
    mov r10, [rax + event_entry.day]
    mov r11, [rax + event_entry.hour]
    mov r12, [rax + event_entry.minute]
    
    mov r13, rdi
    dec r13
    
    mov r14, rdi
.loop:
    cmp r14, rdx
    jge .end_loop
    
    mov rax, r14
    imul rax, 56
    add rax, event_entries
    
    call compare_entry
    cmp rax, -1
    jne .no_swap
    
    inc r13
    mov r15, r13
    imul r15, 56
    add r15, event_entries
    
    call swap_entries
    
.no_swap:
    inc r14
    jmp .loop
.end_loop:
    inc r13
    mov r15, r13
    imul r15, 56
    add r15, event_entries
    
    mov rax, rdx
    imul rax, 56
    add rax, event_entries
    
    call swap_entries
    
    mov rax, r13
    ret

compare_entry:
    ; Сравнение двух записей
    mov rbx, [rax + event_entry.year]
    cmp rbx, r8
    jl .less
    jg .greater
    
    mov rbx, [rax + event_entry.month]
    cmp rbx, r9
    jl .less
    jg .greater
    
    mov rbx, [rax + event_entry.day]
    cmp rbx, r10
    jl .less
    jg .greater
    
    mov rbx, [rax + event_entry.hour]
    cmp rbx, r11
    jl .less
    jg .greater
    
    mov rbx, [rax + event_entry.minute]
    cmp rbx, r12
    jl .less
    jg .greater
    
    xor rax, rax
    ret
.less:
    mov rax, -1
    ret
.greater:
    mov rax, 1
    ret

swap_entries:
    ; Обмен записями
    mov rcx, 14                 ; 56 bytes / 4 = 14 dwords
.swap:
    mov eax, [rax]
    mov edx, [r15]
    mov [r15], eax
    mov [rax], edx
    add rax, 4
    add r15, 4
    loop .swap
    ret

rebuild_buffer:
    ; Сборка буфера из отсортированных записей
    xor rcx, rcx
    mov rsi, temp_buffer
.loop:
    cmp rcx, [num_entries]
    jge .done
    
    mov rax, rcx
    imul rax, 56
    add rax, event_entries
    
    mov rdi, [rax + event_entry.ptr]
    mov rdx, [rax + event_entry.len]
    sub rdx, rdi
    add rdx, 1                  ; Добавляем \n
    
    rep movsb
    
    inc rcx
    jmp .loop
.done:
    ret

section '.data' writable
    num_entries dq 0
    event_entries rb 100*56     ; Максимум 100 событий
    sort_error_msg db 'Error sorting events!', 0xA, 0
    sort_error_len = $ - sort_error_msg