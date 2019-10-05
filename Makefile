#
# Using the "xa" 6502 cross-assembler to generate executables from assembly.
# All programs are compiled from a single source file, so this is trivial.
#
prg: prg/snakes.prg \
     prg/dino_eggs.prg \
     prg/10_miles_runner.prg

prg/%.prg: src/%.asm
	xa -o $@ $<
