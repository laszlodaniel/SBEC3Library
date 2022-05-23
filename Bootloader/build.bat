asm68hc16 -o LdBoot_128k_SBEC3.hex LdBoot_128k_SBEC3.asm
asm68hc16 -o LdBoot_256k_SBEC3.hex LdBoot_256k_SBEC3.asm
asm68hc16 -o LdPartNumberRead_SBEC3.hex LdPartNumberRead_SBEC3.asm
asm68hc16 -o LdFlashRead_SBEC3.hex LdFlashRead_SBEC3.asm
asm68hc16 -o LdFlashID_SBEC3.hex LdFlashID_SBEC3.asm
hex2bin LdBoot_128k_SBEC3.hex
hex2bin LdBoot_256k_SBEC3.hex
hex2bin LdPartNumberRead_SBEC3.hex
hex2bin LdFlashRead_SBEC3.hex
hex2bin LdFlashID_SBEC3.hex
bin2header LdBoot_128k_SBEC3.bin LdBoot_128k_SBEC3 > LdBoot_128k_SBEC3.h
bin2header LdBoot_256k_SBEC3.bin LdBoot_256k_SBEC3 > LdBoot_256k_SBEC3.h
bin2header LdPartNumberRead_SBEC3.bin LdPartNumberRead_SBEC3 > LdPartNumberRead_SBEC3.h
bin2header LdFlashRead_SBEC3.bin LdFlashRead_SBEC3 > LdFlashRead_SBEC3.h
bin2header LdFlashID_SBEC3.bin LdFlashID_SBEC3 > LdFlashID_SBEC3.h