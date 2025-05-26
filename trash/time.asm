format ELF64 
public _start

extrn time
extrn localtime

section '.text' executable
_start:
    ; Получаем текущее время
    xor rdi, rdi
    call time
    mov [time_var], rax

    ; Преобразуем в локальное время
    mov rdi, time_var
    call localtime
    mov rbx, rax

    ; Извлекаем компоненты даты
    mov eax, [rbx + 20]    ; tm_year
    add eax, 1900
    mov [year], eax

    mov eax, [rbx + 16]    ; tm_mon
    inc eax
    mov [month], eax

    mov eax, [rbx + 12]    ; tm_mday
    mov [day], eax

    ; Извлекаем время
    mov eax, [rbx + 8]     ; tm_hour
    add eax, 3
    mov [hour], eax
    mov eax, [rbx + 4]     ; tm_min
    mov [minute], eax

    ; Конвертируем компоненты даты
    mov edi, [year]
    lea rsi, [year_str]
    call int_to_str

    mov edi, [month]
    lea rsi, [month_str]
    call int_to_str
    call add_leading_zero

    mov edi, [day]
    lea rsi, [day_str]
    call int_to_str
    call add_leading_zero

    ; Конвертируем время
    mov edi, [hour]
    lea rsi, [hour_str]
    call int_to_str
    call add_leading_zero

    mov edi, [minute]
    lea rsi, [minute_str]
    call int_to_str
    call add_leading_zero

    ; Формируем выходную строку
    lea rdi, [output]
    lea rsi, [year_str]
    call strcpy            ; Год
    mov byte [rdi], '-'
    inc rdi
    lea rsi, [month_str]
    call strcpy            ; Месяц
    mov byte [rdi], '-'
    inc rdi
    lea rsi, [day_str]
    call strcpy            ; День

    ; Добавляем приветствие
    mov byte [rdi], ' '
    inc rdi
    call add_greeting

    ; Добавляем время
    mov byte [rdi], ' '
    inc rdi
    lea rsi, [hour_str]
    call strcpy            ; Часы
    mov byte [rdi], ':'
    inc rdi
    lea rsi, [minute_str]
    call strcpy            ; Минуты

    ; Завершаем строку
    mov byte [rdi], 0x0A   ; Переход строки
    inc rdi

    ; Рассчитываем длину вывода
    lea rsi, [output]
    sub rdi, rsi
    mov [output_len], rdi

    ; Выводим результат
    mov rax, 1
    mov rdi, 1
    lea rsi, [output]
    mov rdx, [output_len]
    syscall

    ; Завершаем программу
    mov rax, 60
    xor rdi, rdi
    syscall

;---------------------------------------------------
add_greeting:
    mov eax, [hour]
    cmp eax, 5
    jl .night
    cmp eax, 12
    jl .morning
    cmp eax, 17
    jl .day
    cmp eax, 24
    jl .evening

.night:
    lea rsi, [greet_night]
    jmp .copy

.morning:
    lea rsi, [greet_morning]
    jmp .copy

.day:
    lea rsi, [greet_day]
    jmp .copy

.evening:
    lea rsi, [greet_evening]

.copy:
    call strcpy
    ret

;---------------------------------------------------
add_leading_zero:
    cmp byte [rsi + 1], 0  ; Проверка длины строки
    jne .done
    mov al, [rsi]          ; Переносим цифру
    mov [rsi + 1], al
    mov byte [rsi], '0'    ; Добавляем ведущий ноль
.done:
    ret

;---------------------------------------------------
int_to_str:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov eax, edi           ; Число для конвертации
    lea rcx, [rsp + 16]   ; Временный буфер
    mov byte [rcx], 0      ; Нуль-терминатор
    dec rcx

    mov ebx, 10            ; Делитель
.loop:
    xor edx, edx
    div ebx                ; Делим на 10
    add dl, '0'            ; Преобразуем остаток в символ
    mov [rcx], dl          ; Сохраняем в буфер
    dec rcx
    test eax, eax          ; Проверяем, осталось ли число
    jnz .loop

    inc rcx                ; Корректируем указатель
    mov rdi, rsi           ; Целевой буфер
.copy:
    mov al, [rcx]
    test al, al            ; Проверка на конец строки
    jz .done
    mov [rdi], al          ; Копируем символ
    inc rdi
    inc rcx
    jmp .copy
.done:
    mov byte [rdi], 0      ; Завершаем строку
    leave
    ret

;---------------------------------------------------
strcpy:
.loop:
    lodsb                  ; Загружаем символ из RSI
    test al, al            ; Проверка на конец строки
    jz .done
    stosb                  ; Сохраняем в RDI
    jmp .loop
.done:
    ret

section '.data' writable
time_var   dq 0
year       dd 0
month      dd 0
day        dd 0
hour       dd 0
minute     dd 0

year_str   db "0000",0
month_str  db "00",0
day_str    db "00",0
hour_str   db "00",0
minute_str db "00",0

greet_morning db "Доброе утро!",0
greet_day     db "Добрый день!",0
greet_evening db "Добрый вечер!",0
greet_night   db "Доброй ночи!",0

output  :  times 100 db 0
output_len dq 0