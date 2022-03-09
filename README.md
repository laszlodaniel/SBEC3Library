# SBEC3Library
Collection of hard to find stuff regarding Chrysler's SBEC3 engine controller.

This ongoing project is based on the collaboration between 3 people: [Dino](https://github.com/dino2gnt), [Konstantin](https://github.com/GkvJeep) and myself [Daniel](https://github.com/laszlodaniel).

## Bootstrap codes
The bootstrap code is an immutable, small piece of program residing in the engine controller's MCU. Most of the time it controls the normal startup of the system. However, under special circumstances it allows the upload of arbitrary executable code to the MCU's RAM. This opens up a wide range of possibilities to influence the engine controller's behavior, including but not limited to the re-programming of its external flash memory or to simply extract the current calibration from it.

HTML preview of the disassembled and partially reverse engineered [SBEC3_1995_Bootstrap.bin](https://htmlpreview.github.io/?https://github.com/laszlodaniel/SBEC3Library/blob/main/Bootstrap/SBEC3_1995_Bootstrap.html) code.

HTML preview of the disassembled and partially reverse engineered [SBEC3_Bootstrap.bin](https://htmlpreview.github.io/?https://github.com/laszlodaniel/SBEC3Library/blob/main/Bootstrap/SBEC3_Bootstrap.html) code.

These two are quite similar, except in the year 1995 no security measures were implemented to prevent easy access.

## Bootloader codes

The bootloader code acts as a host, configures the MCU and makes it possible to upload worker functions performing different tasks.