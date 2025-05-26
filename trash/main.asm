format elf64
public _start

include 'func.asm'
include 'file-service.asm'



section '.text' executable

_start:
	mov rdi, [rsp+16] 
	mov rsi, 1089 	; O_WRONLY | O_CREAT | O_APPEND
	call open_file

	cmp rax, 0 
	jl .l1 
	
	mov rsi, msg
	call write_file

    mov rdi, [rsp+16] 
    call close_file

	mov rdi, [rsp+16]
	mov rsi, 0
	call open_file

	mov rdi, rax
	call read_file

	call output_buffer_in_console


.l2:  
	mov rdi, r8
	call close_file

.l1:
  	call exit
