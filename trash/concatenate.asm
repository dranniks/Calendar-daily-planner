format elf64
public _start

section '.data' writable
    str1 db 'Hello, ',0    ; Правильное размещение строк в секции .data
    str2 db 'world!',0

section '.bss' writable
    buffer rb 256          ; Буфер в секции .bss

section '.text' executable
_start:
    ; Загрузка адресов строк в 64-битные регистры
    lea rdi, [str1]
    call strlen
    mov rbx, rax           ; Сохраняем длину str1

    lea rdi, [str2]
    call strlen
    mov rdx, rax           ; Сохраняем длину str2

    ; Копирование строк в буфер
    lea rsi, [str1]
    lea rdi, [buffer]
    mov rcx, rbx
    rep movsb              ; Копируем str1

    lea rsi, [str2]
    mov rcx, rdx
    rep movsb              ; Копируем str2 следом

    ; Вывод результата (без нулевого терминатора)
    mov rax, 1             ; sys_write
    mov rdi, 1             ; stdout
    lea rsi, [buffer]
    add rdx, rbx           ; total length = len1 + len2
    syscall

    ; Корректное завершение
    mov rax, 60            ; sys_exit
    xor rdi, rdi
    syscall

; Исправленная функция strlen
strlen:
    xor rcx, rcx
    not rcx                ; rcx = -1 (максимальное значение)
    xor al, al             ; Ищем нулевой байт
    repne scasb            ; Сканируем байты в rdi
    not rcx
    dec rcx                ; Реальная длина
    mov rax, rcx
    ret