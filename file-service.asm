format elf64
public _start

include 'func.asm'

section '.bss' writable
  
  buffer rb 100

section '.text' executable

_start:
  pop rcx 
  cmp rcx, 1 
  je .l1 

  mov rdi,[rsp+8] 
  mov rax, 2 
  ;;Формируем O_WRONLY|O_TRUNC|O_CREAT
  mov rsi, 577
  mov rdx, 777o
  syscall 
  cmp rax, 0 
  jl .l1 
  
  ;;Сохраняем файловый дескриптор
  mov r8, rax

  ;;Читаем n в r9
  mov rsi, [rsp+16]
  mov r9, rsi
  
   mov rax, r9
   call len_str

   mov rdx, rax
   mov rax, 1
   mov rdi, r8
   mov rsi, r9
   syscall


.l2:  
  mov rdi, r8
  mov rax, 3
  syscall

.l1:
  call exit