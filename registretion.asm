format ELF64
public _start

; Системные вызовы
SYS_OPEN   equ 2
SYS_READ   equ 0
SYS_WRITE  equ 1
SYS_CLOSE  equ 3
SYS_EXIT   equ 60

; Флаги файлов
O_RDONLY   equ 0
O_WRONLY   equ 1
O_CREAT    equ 64
O_TRUNC    equ 512

STDOUT     equ 1
STDIN      equ 0

; ========== Функция проверки регистрации ==========


; ========== Точка входа ==========
_start:
    call check_registration
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall


    settings_file db "settings.txt",0
    fd dq 0

    hello_msg db "Hello, "
    hello_len = $ - hello_msg

    reg_msg db "Please register. Enter your name: ",0
    reg_len = $ - reg_msg

    reg_buffer rb 256