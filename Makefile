ASM := nasm
ASMF := -f bin
KERN := kernel.asm
BOOT := bootloader.asm
OUT := os.img
main:
	@$(ASM) $(BOOT) $(ASMF) -o $(basename $(BOOT)).bin
	@$(ASM) $(KERN) $(ASMF) -o $(basename $(KERN)).bin
	
	@cat $(basename $(BOOT)).bin $(basename $(KERN)).bin > $(OUT)
	@rm -f $(basename $(BOOT)).bin $(basename $(KERN)).bin 
	@qemu-system-x86_64 -cpu qemu64 -d int -drive format=raw,file=$(OUT)
