section .data
    hello db 'Hola Mundo!', 0

section .text
    global _start

_start:
    ; Escribir el mensaje en la consola
    mov eax, 4
    mov ebx, 1
    mov ecx, hello
    mov edx, 12
    int 0x80

    ; Salir del programa
    mov eax, 1
    xor ebx, ebx
    int 0x80
