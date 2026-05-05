ASM := nasm
ASMF := -f bin
SRC := boot.asm
OUT := $(basename $(SRC))
main:
	@$(ASM) $(SRC) $(ASMF) -o $(OUT)
	@qemu-system-x86_64 -cpu qemu64 -drive format=raw,file=$(OUT)
