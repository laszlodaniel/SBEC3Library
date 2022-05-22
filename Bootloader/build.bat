asm68hc16 -o 01_LdBoot_128k.hex 01_LdBoot_128k.asm
asm68hc16 -o 01_LdBoot_256k.hex 01_LdBoot_256k.asm
asm68hc16 -o 02_LdPartNumberRead.hex 02_LdPartNumberRead.asm
asm68hc16 -o 10_LdFlashRead.hex 10_LdFlashRead.asm
asm68hc16 -o 11_LdFlashID.hex 11_LdFlashID.asm
hex2bin 01_LdBoot_128k.hex
hex2bin 01_LdBoot_256k.hex
hex2bin 02_LdPartNumberRead.hex
hex2bin 10_LdFlashRead.hex
hex2bin 11_LdFlashID.hex
bin2header 01_LdBoot_128k.bin LdBoot_128k > 01_LdBoot_128k.h
bin2header 01_LdBoot_256k.bin LdBoot_256k > 01_LdBoot_256k.h
bin2header 02_LdPartNumberRead.bin LdPartNumberRead > 02_LdPartNumberRead.h
bin2header 10_LdFlashRead.bin LdFlashRead > 10_LdFlashRead.h
bin2header 11_LdFlashID.bin LdFlashID > 11_LdFlashID.h