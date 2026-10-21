# Toolchain, Compilación y Troubleshooting

Esta guía detalla los prerrequisitos, pasos de compilación/enlace y solución de problemas para ejecutar este proyecto en sistemas Linux modernos.

---

## 1. Cadena de Herramientas (*Toolchain*) Necesaria

Para compilar y ejecutar este proyecto se requieren dos herramientas clave:

1. **`nasm` (Netwide Assembler):** Traduce el código fuente en lenguaje ensamblador (`Calculator.asm`) a un archivo objeto en formato ELF de 32 bits (`Calculator.o`).
2. **`ld` (GNU Linker de binutils):** Resuelve símbolos y genera el binario ejecutable final enlazando las secciones correspondientes para la arquitectura `elf_i386`.

---

## 2. Instalación de Dependencias

### En distribuciones basadas en Debian / Ubuntu
```bash
sudo apt update
sudo apt install -y nasm binutils gcc-multilib
```
> **¿Por qué `gcc-multilib`?** Si tu sistema operativo es de 64 bits (x86_64), `gcc-multilib` provee las bibliotecas de soporte y compatibilidad para compilar y enlazar binarios de 32 bits (`IA-32`).

### En Fedora / RHEL
```bash
sudo dnf install -y nasm binutils glibc-devel.i686
```

### En Arch Linux / Manjaro
Asegúrate de tener habilitado el repositorio `[multilib]` en `/etc/pacman.conf` y luego ejecuta:
```bash
sudo pacman -Sy nasm binutils lib32-glibc
```

---

## 3. Flujo Manual de Compilación y Ejecución

Desde la raíz del repositorio, ejecuta los siguientes pasos:

### Paso 1: Ensamblar con NASM
```bash
nasm -f elf32 src/Calculator.asm -o src/Calculator.o
```
- `-f elf32`: Especifica el formato del archivo objeto de salida como **ELF de 32 bits** (Executable and Linkable Format).
- `-o src/Calculator.o`: Define el nombre del archivo objeto generado.

### Paso 2: Enlazar con GNU Linker (`ld`)
```bash
ld -m elf_i386 src/Calculator.o -o src/Calculator
```
- `-m elf_i386`: Instruye al linker de 64 bits a emular la arquitectura x86 de 32 bits para crear un binario compatible.
- `-o src/Calculator`: Nombre del ejecutable binario final.

### Paso 3: Dar permisos y ejecutar
```bash
chmod +x src/Calculator
./src/Calculator
```

---

## 4. Uso con Dev Containers (Docker)

Si no deseas instalar herramientas de compilación de 32 bits directamente en tu máquina host, puedes usar la configuración incluida en [.devcontainer/devcontainer.json](file:///home/jr_g/Develop/Assembler-Calculator/.devcontainer/devcontainer.json):

1. Abre el repositorio en **Visual Studio Code** o cualquier editor compatible con Dev Containers.
2. Asegúrate de tener instalada la extensión **Remote - Containers** (o Dev Containers).
3. Presiona `F1` y selecciona: **Dev Containers: Reopen in Container**.
4. El contenedor descargará e instalará automáticamente `nasm` y `binutils`.

---

## 5. Resolución de Problemas Comunes (*Troubleshooting*)

### Error 1: `command not found: nasm`
* **Causa:** El ensamblador no está instalado en tu sistema o no se encuentra en tu variable de entorno `$PATH`.
* **Solución:** Instala el paquete `nasm` siguiendo las instrucciones de la Sección 2.

### Error 2: `ld: unrecognised emulation mode: elf_i386`
* **Causa:** La versión instalada de `ld` no fue compilada con soporte para emulación de 32 bits.
* **Verificación:** Ejecuta `ld -V` en tu terminal y revisa la lista de *Supported emulations*. Debe aparecer `elf_i386`.
* **Solución:** Instala `binutils-multiarch` o `gcc-multilib`.

### Error 3: `./src/Calculator: No such file or directory` (en sistemas de 64 bits)
* **Causa:** El kernel no puede ejecutar el binario ELF de 32 bits porque faltan las bibliotecas de soporte de 32 bits en el sistema operativo.
* **Solución:**
  ```bash
  # En Ubuntu/Debian:
  sudo dpkg --add-architecture i386
  sudo apt update
  sudo apt install -y libc6:i386
  ```

### Error 4: `Calculator.asm:9: error: symbol `ResMessage' redefined`
* **Causa:** En NASM las etiquetas son sensibles a mayúsculas y minúsculas y no pueden duplicarse en la misma sección.
* **Solución:** Revisa que cada identificador en `section .data` y `section .text` sea único.
