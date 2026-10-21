# Fundamentos de Lenguaje Ensamblador x86 (IA-32) y Linux Syscalls

Esta guía explica en profundidad los conceptos fundamentales de hardware, memoria y arquitectura que sustentan este proyecto, diseñada tanto para principiantes como para desarrolladores que desean comprender qué sucede en el procesador a bajo nivel.

---

## 1. ¿Qué es el Lenguaje Ensamblador?

A diferencia de los lenguajes de alto nivel (como Python, TypeScript o C) que introducen capas de abstracción sobre la máquina, el **lenguaje ensamblador (Assembly)** es una representación textual directa y legible por humanos de las instrucciones en código máquina que ejecuta el procesador (CPU).

```
[ Código Fuente C / Rust ]
           ↓ (Compilador)
[ Código Ensamblador (.asm) ]  <-- Mnemónicos legibles (mov, add, int)
           ↓ (Ensamblador: NASM)
[ Código Máquina (.o, ELF) ]   <-- Bytes binarios ejecutables (B8 04 00 00 00...)
           ↓ (CPU)
[ Microarquitectura / Silicio ]
```

En ensamblador no existen conceptos como clases, tipos automáticos, recolección de basura ni librerías estándar mágicas: **el desarrollador controla directamente los registros, la memoria y las llamadas al kernel del sistema operativo.**

---

## 2. La Arquitectura x86 de 32 Bits (IA-32)

Este proyecto está construido para la arquitectura **x86 de 32 bits**. En este modo de operación, las direcciones de memoria y los registros estándar tienen un tamaño de **32 bits (4 bytes)**.

### 2.1 Registros de Propósito General

Los registros son las unidades de almacenamiento más rápidas que existen en una computadora; residen físicamente dentro del chip del procesador.

| Registro | Nombre tradicional | Uso común / Convención |
| :--- | :--- | :--- |
| **`EAX`** | *Accumulator Register* | Resultados aritméticos y número de syscall en Linux |
| **`EBX`** | *Base Register* | Puntero base a datos y 1° argumento de syscall |
| **`ECX`** | *Counter Register* | Contador de bucles y 2° argumento de syscall (o puntero a buffer) |
| **`EDX`** | *Data Register* | Operaciones de E/S, multiplicación/división y 3° argumento de syscall (longitud) |

#### Sub-registros de compatibilidad histórica
Los registros de 32 bits pueden subdividirse para operar con datos de 16 bits o de 8 bits sin afectar los bits superiores:

```
┌─────────────────────────────────────────────────────────┐
│                      EAX (32 bits)                      │
├────────────────────────────┬────────────────────────────┤
│   (Bits superiores 31-16)  │        AX (16 bits)        │
│                            ├─────────────┬──────────────┤
│                            │ AH (8 bits) │ AL (8 bits)  │
└────────────────────────────┴─────────────┴──────────────┘
```

*En [Calculator.asm](file:///home/jr_g/Develop/Assembler-Calculator/src/Calculator.asm), se usa con frecuencia `AL` (los 8 bits menos significativos de `EAX`) para inspeccionar caracteres ASCII individuales leídos desde el teclado.*

### 2.2 Registros de Índice y Punteros

| Registro | Nombre | Función |
| :--- | :--- | :--- |
| **`ESI`** | *Source Index* | Puntero de origen en operaciones con cadenas de bytes (`lodsb`) |
| **`EDI`** | *Destination Index* | Puntero de destino en operaciones de copia o llenado de memoria |
| **`ESP`** | *Stack Pointer* | Dirección del tope de la pila en memoria (Stack) |
| **`EBP`** | *Base Pointer* | Puntero al marco de pila actual (Stack Frame) |
| **`EIP`** | *Instruction Pointer* | Dirección de la próxima instrucción que la CPU va a ejecutar (controlado por saltos y llamadas) |

### 2.3 Registro de Estado: `EFLAGS`
Contiene bits individuales (flags) que el procesador activa o desactiva automáticamente tras operaciones aritméticas o lógicas (`cmp`, `sub`, `add`):
- **`ZF` (Zero Flag):** Se enciende en `1` si el resultado de una operación fue cero (por ejemplo, si dos valores comparados son iguales). Usado por `je` (*jump if equal*).
- **`SF` (Sign Flag):** Se enciende en `1` si el resultado fue negativo. Usado por saltos con signo como `jl` (*jump if less*).

---

## 3. Modelo de Memoria de un Programa en Ensamblador

Cuando el kernel de Linux carga un binario ELF en memoria, organiza el espacio de direcciones en distintas secciones:

### 3.1 Sección `.data` (Datos Inicializados)
Contiene constantes y variables cuyo valor ya se conoce al momento de ensamblar el archivo binario.
```nasm
section .data
    Welcome db 'Bienvenidos a CalculatorNasm', 0   ; Cadena terminada en null
    WelcomeLen equ $-Welcome                        ; Constante evaluada en ensamblado
    Operacion times 100 db 0                        ; Reserva de 100 bytes en cero
```
- **`db` (Define Byte):** Reserva espacio en unidades de 1 byte (8 bits).
- **`dw` (Define Word):** Reserva palabras de 2 bytes (16 bits).
- **`dd` (Define Double Word):** Reserva palabras dobles de 4 bytes (32 bits).
- **`equ $-label`:** Directiva del ensamblador que calcula la longitud en bytes restando la posición de memoria actual (`$`) de la dirección de inicio de `label`.

### 3.2 Sección `.text` (Código de Instrucciones)
Contiene el código máquina ejecutable. El sistema operativo la mapea en memoria con permisos de lectura y ejecución (`r-x`), impidiendo que el código se modifique a sí mismo durante la ejecución.

En esta sección debe declararse el punto de entrada que el enlazador (`ld`) buscará por defecto:
```nasm
section .text
    global _start
_start:
    ; Aquí inicia la ejecución
```

### 3.3 La Pila (Stack)
Estructura LIFO (Last-In, First-Out) que crece hacia abajo (hacia direcciones de memoria más bajas). Las instrucciones `call` y `ret` la utilizan para almacenar la dirección de retorno de una subrutina:
- Al invocar `call print_newline`, el procesador empuja el valor actual de `EIP` al stack y salta a la función.
- Al llegar a `ret`, el procesador saca del stack la dirección guardada y la devuelve a `EIP`, reanudando el flujo original.

---

## 4. Llamadas al Sistema en Linux x86 (`int 0x80`)

Un programa de usuario en espacio de usuario (*User Space*) no puede interactuar directamente con la tarjeta de video, el teclado o la consola por motivos de seguridad del procesador (Anillos de protección / *Ring 3* vs *Ring 0*). 

Para imprimir un carácter o leer del teclado, el programa debe pedirle al **Kernel de Linux** que lo haga por él mediante una **Syscall** (*System Call*).

En la arquitectura x86 de 32 bits en Linux, esto se solicita mediante la interrupción por software `int 0x80`.

### 4.1 Convención de Registros para Syscalls x86-32

1. **`EAX`:** Número identificador de la syscall.
2. **`EBX`:** 1° argumento.
3. **`ECX`:** 2° argumento.
4. **`EDX`:** 3° argumento.
5. **`int 0x80`:** Transición al modo kernel para ejecutar la rutina solicitada.

### 4.2 Las Syscalls utilizadas en este proyecto

#### A. `sys_write` (Syscall 4)
Escribe bytes hacia un descriptor de archivo (*file descriptor*).

```nasm
mov eax, 4           ; sys_write
mov ebx, 1           ; stdout (salida estándar, terminal)
mov ecx, Welcome     ; Puntero al inicio del buffer en memoria
mov edx, WelcomeLen  ; Cantidad de bytes a escribir
int 0x80             ; Ejecutar llamada al sistema
```

#### B. `sys_read` (Syscall 3)
Lee bytes desde un descriptor de archivo hacia un buffer en memoria.

```nasm
mov eax, 3           ; sys_read
mov ebx, 0           ; stdin (entrada estándar, teclado)
mov ecx, Operacion   ; Puntero al buffer donde guardar los caracteres
mov edx, 100         ; Cantidad máxima de bytes a leer
int 0x80             ; Bloquea esperando entrada del usuario
```

#### C. `sys_exit` (Syscall 1)
Termina la ejecución del proceso y devuelve un código de estado al sistema operativo.

```nasm
mov eax, 1           ; sys_exit
xor ebx, ebx         ; ebx = 0 (Código de salida exitoso: return 0)
int 0x80             ; El kernel finaliza el proceso
```

> **Nota técnica:** `xor ebx, ebx` es el estándar en ensamblador para poner un registro en cero. Es más rápido y genera menos bytes de código máquina que `mov ebx, 0`.

---

## 5. Sintaxis Intel (NASM) vs Sintaxis AT&T (GNU Assembler)

Existen dos sintaxis principales en el ecosistema x86:

| Concepto | Sintaxis Intel (NASM - Este repo) | Sintaxis AT&T (as / GCC por defecto) |
| :--- | :--- | :--- |
| **Orden de operandos** | `instrucción destino, origen` | `instrucción origen, destino` |
| **Prefijo de registros** | Sin prefijo (`eax`, `ebx`) | Prefijo `%` (`%eax`, `%ebx`) |
| **Constantes / Inmediatos** | Sin prefijo (`4`, `100`) | Prefijo `$` (`$4`, `$100`) |
| **Desreferencia de memoria** | Corchetes: `[edi]` | Paréntesis: `(%edi)` |
| **Ejemplo `mov`** | `mov eax, 4` | `movl $4, %eax` |

---

## 6. Análisis Técnico de las Instrucciones de `Calculator.asm`

### 6.1 Procesamiento de Strings con `lodsb`
```nasm
mov esi, Operacion
loop_operacion:
    lodsb
    cmp al, 0
    je end_loop_operacion
```
- **`lodsb` (Load String Byte):** Carga un byte desde la dirección apuntada por `[ESI]` en el registro `AL`, y de manera automática incrementa `ESI` en 1 byte (si la flag de dirección `DF` está en 0).
- **`cmp al, 0`:** Compara si el byte cargado es el delimitador nulo (final de cadena).
- **`je end_loop_operacion`:** Si es igual a cero (`ZF=1`), sale del bucle.

### 6.2 El Bug Identificado en el Buffer de Dígitos
En las líneas 78-80 del código original encontramos:
```nasm
mov edi, buffer ; Puntero de destino en el buffer
mov [edi], al   ; Almacena el carácter numérico en el buffer
inc edi         ; Incrementa el puntero de destino
```

#### ¿Por qué es un error arquitectónico?
En cada iteración del bucle, la instrucción `mov edi, buffer` reinicializa `EDI` a la primera dirección del array `buffer`. En consecuencia:
1. Siempre se escribe en `buffer[0]`.
2. Cada nuevo dígito sobreescribe al anterior.
3. El incremento `inc edi` se pierde en la siguiente iteración.

**Solución canónica en x86:**  
`mov edi, buffer` debe inicializarse una única vez **antes** de comenzar el bucle `loop_operacion`.

---

## 7. El Salto a una Calculadora Real: Aritmética y Conversión

Para transformar este parser de caracteres en una calculadora operativa real, en lenguaje ensamblador se deben resolver tres problemas que en lenguajes de alto nivel damos por sentados:

### 7.1 Algoritmo `atoi` (ASCII to Integer)
Cuando el usuario teclea `'4'` y `'2'`, el buffer recibe los códigos ASCII `0x34` (52) y `0x32` (50). La CPU no puede sumar directamente los caracteres ASCII. El algoritmo de conversión opera acumulando:

$$\text{acumulado} = (\text{acumulado} \times 10) + (\text{carácter} - '0')$$

En x86-32:
```nasm
; ESI apunta al string ("42"), EAX contendrá el entero resultante
xor eax, eax            ; acumulador = 0
atoi_loop:
    movzx ecx, byte [esi]
    cmp ecx, '0'
    jl atoi_done
    cmp ecx, '9'
    jg atoi_done
    sub ecx, '0'         ; Convierte ASCII a dígito binario (0-9)
    imul eax, eax, 10    ; acumulador * 10
    add eax, ecx         ; acumulador + nuevo dígito
    inc esi
    jmp atoi_loop
atoi_done:
```

### 7.2 Operaciones Aritméticas del Procesador
Una vez convertidos los operandos a enteros binarios (por ejemplo, en `EAX` y `EBX`):

- **Suma:** `add eax, ebx`
- **Resta:** `sub eax, ebx`
- **Multiplicación:** `imul eax, ebx` (para enteros con signo)
- **División:** `cdq` (extiende el signo de `EAX` en `EDX:EAX`) seguido de `idiv ebx` (el cociente queda en `EAX` y el resto en `EDX`).

### 7.3 Algoritmo `itoa` (Integer to ASCII)
Para imprimir el resultado con `sys_write`, el número binario debe descomponerse de vuelta a caracteres ASCII mediante divisiones sucesivas por 10:

```nasm
; Convierte EAX en string dentro de un buffer de salida
mov ebx, 10
mov edi, buffer_resultado_fin ; Escribir de derecha a izquierda
itoa_loop:
    xor edx, edx
    div ebx              ; EAX / 10 -> Cociente en EAX, Resto en EDX
    add dl, '0'          ; Convierte el dígito restante a ASCII
    dec edi
    mov [edi], dl
    test eax, eax
    jnz itoa_loop
    ; EDI ahora apunta al inicio del string formateado listo para sys_write
```

