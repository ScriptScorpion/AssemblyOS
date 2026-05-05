ASM := nasm
ASMF := -f bin
SRC := kernel.asm
OUT := $(basename $(SRC)).bin
main:
	@$(ASM) $(SRC) $(ASMF) -o $(OUT)
	@qemu-system-x86_64 -cpu qemu64 -drive format=raw,file=$(OUT)
