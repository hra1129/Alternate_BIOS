Usage
===============================================================================
1. Overview
	Generate a compatible program for the startup logo display program stored 
	in Slot#0-3 7900h-7FFFh of MSXturboR FS-A1GT.

2. Advantage
	The following points are different from the original one.

	(1) The program itself is licensed under the MIT license.
	(2) The logo can be changed easily (just prepare 24bpp BMP).
	(3) It works on MSX2+.
	(4) The source code can be viewed and modified.

3. How to use
	Please follow the steps below.

	[1] Prepare a 24bpp BMP file of size 422 x 80, and name it logo.bmp.
	[2] Run make_altbootl.bat.

	If no problems occur, the following file will be generated.

	altbios_boot_logo.bin .... ROM image of 7900h-7FFFh
	BOOTLOGO.COM ............. Boot logo test program that runs on MSX-DOS (*for MSX2+/turboR)

===============================================================================
19th/Dec./2021  HRA!
