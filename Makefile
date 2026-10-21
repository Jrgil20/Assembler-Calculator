# Assembler-Calculator Makefile
# Architecture: x86 (IA-32) on Linux

ASM = nasm
ASMFLAGS = -f elf32

LD = ld
LDFLAGS = -m elf_i386

SRC_DIR = src
SRC = $(SRC_DIR)/Calculator.asm
OBJ = $(SRC_DIR)/Calculator.o
BIN = $(SRC_DIR)/Calculator

.PHONY: all build run clean

all: build

build: $(BIN)

$(OBJ): $(SRC)
	$(ASM) $(ASMFLAGS) $< -o $@

$(BIN): $(OBJ)
	$(LD) $(LDFLAGS) $< -o $@

run: build
	./$(BIN)

clean:
	rm -f $(OBJ) $(BIN)
