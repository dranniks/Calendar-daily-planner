; Константы для системных вызовов
SYS_OPEN   equ 2
SYS_READ   equ 0
SYS_WRITE  equ 1
SYS_CLOSE  equ 3
SYS_EXIT   equ 60

; Флаги для открытия файлов
O_RDONLY   equ 0
O_WRONLY   equ 1
O_CREAT    equ 64
O_TRUNC    equ 512

process_file:
    ; Открытие файлов
    mov  rax, SYS_OPEN
    lea  rdi, [event_filename]
    mov  rsi, O_RDONLY
    xor  rdx, rdx
    syscall
    cmp  rax, 0
    jl   exit_error
    mov  [event_fd], rax

    mov  rax, SYS_OPEN
    lea  rdi, [export_filename]
    mov  rsi, O_WRONLY or O_CREAT or O_TRUNC
    mov  rdx, 0644o
    syscall
    cmp  rax, 0
    jl   exit_error
    mov  [export_fd], rax

    mov  rax, SYS_WRITE
    mov  rdi, [export_fd]
    lea  rsi, [head]
    mov  rdx, 38
    syscall

.read_loop:
    ; Чтение символа
    mov  rax, SYS_READ
    mov  rdi, [event_fd]
    lea  rsi, [exp_buffer]
    mov  rdx, 1
    syscall

    cmp  rax, 1
    jne  .close_files

    ; Проверка специальных символов
    cmp  byte [exp_buffer], 0x0A  ; '\n'
    je   .print_1
    cmp  byte [exp_buffer], 0x5D  ; ']'
    je   .print_2
    cmp  byte [exp_buffer], 0x5B  ; '['
    je   .print_3

.write_char:
    ; Запись символа в файл
    mov  rax, SYS_WRITE
    mov  rdi, [export_fd]
    lea  rsi, [exp_buffer]
    mov  rdx, 1
    syscall
    jmp  .read_loop

.print_1:
    ; Запись символа в файл
    mov  rax, SYS_WRITE
    mov  rdi, [export_fd]
    lea  rsi, [exp_buffer]
    mov  rdx, 1
    syscall

    mov  rax, SYS_WRITE
    mov  rdi, [export_fd]
    lea  rsi, [l_line]
    mov  rdx, 43
    syscall
    
    jmp  .read_loop

.print_2:
    ; Запись символа в файл
    mov  rax, SYS_WRITE
    mov  rdi, [export_fd]
    lea  rsi, [exp_buffer]
    mov  rdx, 1
    syscall

    mov  rax, SYS_WRITE
    mov  rdi, [export_fd]
    lea  rsi, [n_line]
    mov  rdx, 3
    syscall
    
    jmp  .read_loop

.print_3:

    mov  rax, SYS_WRITE
    mov  rdi, [export_fd]
    lea  rsi, [h_line]
    mov  rdx, 44
    syscall

    ; Запись символа в файл
    mov  rax, SYS_WRITE
    mov  rdi, [export_fd]
    lea  rsi, [exp_buffer]
    mov  rdx, 1
    syscall



    jmp  .read_loop

.close_files:
    ; Закрытие файлов
    mov  rax, SYS_CLOSE
    mov  rdi, [event_fd]
    syscall
    mov  rax, SYS_CLOSE
    mov  rdi, [export_fd]
    syscall
    ret

exit_error:
    mov  rax, SYS_EXIT
    mov  rdi, 1
    syscall


    event_filename db "events.txt",0
    export_filename db "export.txt",0
    smile db 0xF0,0x9F,0x98,0x8A
    head db "======Your Events", 0xF0,0x9F,0x98,0x8A, "======         ", 0x0A, 0x0A
    l_line            db "-----------------------------------------", 0x0A, 0x0A
    n_line           db 0x0A, "|", 0x09
    h_line         db "-----------------------------------------", 0x0A, "|", 0x09
    event_fd       dq 0
    export_fd      dq 0
    exp_buffer         db 0