# AssemblyOS - is Operating system that have ability to execute your assembly instructions easily

## Requirements:
    * nasm
    * make
    * qemu-system-x86_64

## Installation:
    * Enter project directory and run `make`

## Guide:
    * How create your assembly instruction:
        1. Define opcode that is used for your assembly instruction (0x00-0xFF)
        2. Define name of the instruction
        3. Define how many argument it is accepts
        4. Create your instruction using available x64 instructions in 'NASM' tool
    * How to execute your instructions:
        1. Boot up OS
        2. Enter your instruction in terminal with amount of arguments you defined
        3. Press enter to execute it
