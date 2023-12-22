section .data
    Welcome db 'Bienvenidos a CalculatorNasm', 0

section .text
    global _start

_start:
    ; Escribir el mensaje en la consola
    mov eax, 4
    mov ebx, 1
    mov ecx, Welcome
    mov edx, 27
    int 0x80

    ; Salir del programa
    mov eax, 1
    xor ebx, ebx
    int 0x80
