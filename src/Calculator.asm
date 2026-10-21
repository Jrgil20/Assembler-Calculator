section .data
    Welcome db 'Bienvenidos a CalculatorNasm', 0
    WelcomeLen equ $-Welcome
    NewLine db 0Ah, 0Dh
    InputPrompt db 'Ingrese la operacion: ', 0
    InputPromptLen equ $-InputPrompt
    SumMessage db ' Se detecto una Suma', 0
    SumMessageLen equ $-SumMessage
    ResMessage db ' Se detecto una Resta', 0
    ResMessageLen equ $-ResMessage
    OutputPrompt db 'El Resultado es: ', 0
    OutputPromptLen equ $-OutputPrompt
    Operacion times 100 db 0
    buffer times 20 db 0

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

    ; Imprimir dos salto de línea
    call print_newline
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
    mov ecx, Operacion
    mov edx, 100
    int 0x80

    ; imprime un salto de línea
    call print_newline

    ; Establezca el puntero de origen en el inicio del búfer
    mov esi, Operacion

    ; Realice un bucle a través de Operacion hasta que se encuentre un byte nulo
    loop_operacion:
        ; Cargue el siguiente carácter en AL
        lodsb

        ;  Compruebe si el carácter es nulo (final de la cadena)
        cmp al, 0
        je end_loop_operacion

        ; Compruebe si el carácter es numérico
        cmp al, '0'
        jl continue_loop_operacion
        cmp al, '9'
        jg continue_loop_operacion

        ; Procesa el carácter aquí (es numérico)
        ; Almacena el carácter numérico en una cadena buffer
        mov edi, buffer ; Puntero de destino en el buffer
        mov [edi], al ; Almacena el carácter numérico en el buffer
        inc edi ; Incrementa el puntero de destino
        

        ; Continuar con el siguiente carácter
        jmp loop_operacion

    continue_loop_operacion:
        ; Procesa el carácter aquí (no es numérico)
        
        cmp al, '+'
        je print_sum
        cmp al, '-'
        je print_res

        ; Continuar con el siguiente carácter
        jmp loop_operacion

            print_sum:
                ; Imprimir el mensaje de suma en la consola
                mov eax, 4
                mov ebx, 1
                mov ecx, SumMessage
                mov edx, SumMessageLen
                int 0x80
            
                ; Imprimir un salto de línea
                call print_newline

            end_print_sum:

            print_res:
                ; Imprimir el mensaje de suma en la consola
                mov eax, 4
                mov ebx, 1
                mov ecx, ResMessage
                mov edx, ResMessageLen
                int 0x80
            
                ; Imprimir un salto de línea
                call print_newline
            end_print_res:

    end_loop_operacion:

    ; Imprimir un salto de línea
    call print_newline

    ; Escribir el mensaje de salida en la consola
    mov eax, 4
    mov ebx, 1
    mov ecx, OutputPrompt
    mov edx, OutputPromptLen
    int 0x80

    ; Imprimir la cadena de texto ingresada por el usuario
    mov eax, 4
    mov ebx, 1
    mov ecx, Operacion
    mov edx, 100
    int 0x80

    ; Salir del programa
    mov eax, 1
    xor ebx, ebx
    int 0x80
