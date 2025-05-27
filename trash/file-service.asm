; input		rdi - file name
;			rsi - mode
; output	rax - file descriptor
open_file:
	mov rax, SYS_OPEN 
  	mov rdx, 777o	; Права доступа (rwx для всех)
  	syscall 
	ret

; input		rdi - file descriptor
close_file:
	mov rax, SYS_CLOSE
	syscall
	ret

; input		rax - file descriptor
;			rsi - string
write_file:

	mov r8, rax 	; Сохраняем файловый дескриптор
	
	mov r9, rsi		; Сохраняем сторку для записи в файл
	
	mov rax, r9
	call len_str	; Получаем длинну строки и сохраняем в rax

	mov rdx, rax
	mov rax, SYS_WRITE
	mov rdi, r8
	mov rsi, r9
	syscall
	ret

; input		rdi - file descriptor
; output	buffer - text
read_file:
	mov rax, SYS_READ
    mov rsi, buffer		; Буфер
    mov rdx, 4096      	; Размер буфера
    syscall
	ret

; input		buffer - text
output_buffer_in_console:
	mov rdx, 4096        ; Количество байт
    mov rax, SYS_WRITE
    mov rdi, STDOUT		; Вывод в консоль
    mov rsi, buffer		; Данные
    syscall
	ret


section '.bss' writable
	msg db "I love FASM" , 0xa, 0