section .data
    Welcome db 'Bienvenidos a CalculatorNasm', 0
    WelcomeLen equ $-Welcome
    NewLine db 0Ah, 0Dh
    InputPrompt db 'Ingrese la operacion: ', 0
    InputPromptLen equ $-InputPrompt
    OutputPrompt db 'El Resultado es: ', 0
    OutputPromptLen equ $-OutputPrompt
    Buffer times 100 db 0

section .text
    global _start

 ; Función para imprimir un salto de línea
print_newline:
    mov eax, 4 ; Número de la llamada al sistema para 'write'
    mov ebx, 1 ; Descriptor de archivo para la salida estándar
    mov ecx, NewLine ; Puntero a la cadena a imprimir
    mov edx, 2 ; Longitud de la cadena
    int 0x80 ; Realizar la llamada al sistema
    ret ; Regresar al punto de llamada


_start:
    ; Escribir el mensaje de bienvenida en la consola
    mov eax, 4
    mov ebx, 1
    mov ecx, Welcome
    mov edx, WelcomeLen
    int 0x80

    call print_newline

    ; Solicitar al usuario que ingrese una cadena de texto
    mov eax, 4
    mov ebx, 1
    mov ecx, InputPrompt
    mov edx, InputPromptLen
    int 0x80

    ; Leer la cadena de texto ingresada por el usuario
    mov eax, 3
    mov ebx, 0
    mov ecx, Buffer
    mov edx, 100
    int 0x80

    ; Escribir el mensaje de salida en la consola
    mov eax, 4
    mov ebx, 1
    mov ecx, OutputPrompt
    mov edx, OutputPromptLen
    int 0x80

    ; Imprimir la cadena de texto ingresada por el usuario
    mov eax, 4
    mov ebx, 1
    mov ecx, Buffer
    mov edx, 100
    int 0x80

    ; Salir del programa
    mov eax, 1
    xor ebx, ebx
    int 0x80
