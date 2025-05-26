
; Аргументы:
; rdi - указатель на первую строку (нуль-терминированную)
; rsi - указатель на вторую строку (нуль-терминированную)

; Возвращает:
; rax - указатель на результат (buffer)
; rdx - общая длина строки (без нуль-терминатора)
concat_strings:
    push rbx
    push r12
    push rdi
    push rsi

    ; Сохраняем исходные указатели
    mov rbx, rdi      ; Первая строка
    mov r12, rsi      ; Вторая строка

    ; Вычисляем длину первой строки
    call strlen
    mov r8, rax       ; r8 = длина первой строки

    ; Вычисляем длину второй строки
    mov rdi, r12
    call strlen
    mov r9, rax       ; r9 = длина второй строки

    ; Проверка переполнения буфера
    mov rcx, r8
    add rcx, r9
    cmp rcx, 255
    jbe .copy_data

    ; Если переполнение - обрезаем до максимального размера
    mov r8, 255
    sub r8, r9
    jns .copy_data
    xor r8, r8        ; Если даже одна строка длиннее 255

.copy_data:
    lea rdi, [concat_buffer] ; Начало буфера
    mov rsi, rbx      ; Копируем первую строку
    mov rcx, r8
    rep movsb

    mov rsi, r12      ; Копируем вторую строку
    mov rcx, r9
    rep movsb

    ; Устанавливаем возвращаемые значения
    lea rax, [concat_buffer]
    mov rdx, r8
    add rdx, r9

    pop rsi
    pop rdi
    pop r12
    pop rbx
    ret

strlen:
    xor rcx, rcx
    not rcx
    xor al, al
    repne scasb
    not rcx
    dec rcx
    mov rax, rcx
    ret