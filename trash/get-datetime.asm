section '.bss' writable

input db "time"

section '.text' executable
get_time:
    mov rax, 57
    syscall

    cmp rax, 0
    jnz .parent

    .child:
    mov rax, 59
    mov rdi, input
    syscall
    call exit

    .parent:
    .wait:
        mov rax, 61
        mov rdi, -1
        mov rdx, 0
        mov r10, 0
        syscall
    ret        