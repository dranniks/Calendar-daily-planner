format ELF64
public _start

extrn get_time  ; Объявляем внешнюю C-функцию

; Системные вызовы
SYS_WRITE equ 1
SYS_EXIT  equ 60
STDOUT    equ 1

section '.text' executable
_start:
    ; Вызываем C-функцию
    call get_time      ; Результат (указатель на строку) будет в RAX
    
    ; Вычисляем длину строки
    mov rdi, rax       ; Сохраняем указатель
    xor rcx, rcx       ; Счетчик длины
    
    .loop:
    cmp byte [rdi + rcx], 0
    je .print
    inc rcx
    jmp .loop
    
    .print:
    ; Выводим результат
    mov rdx, rcx       ; Длина строки
    mov rsi, rax       ; Указатель на строку
    mov rdi, STDOUT    ; Файловый дескриптор
    mov rax, SYS_WRITE
    syscall
    
    ; Завершаем программу
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall