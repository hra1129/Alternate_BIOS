; -----------------------------------------------------------------------------
; Altenate BIOS Boot Logo Test Program
;
; MIT License
; 
; Copyright (c) 2021 HRA!
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; -----------------------------------------------------------------------------

rdslt			:= 0x000C
calslt			:= 0x001C
main_rom_slot	:= 0xFCC1
version_id		:= 0x002D
chgcpu			:= 0x0180
getcpu			:= 0x0183

				org		0x100

				ld		hl, altbios_boot_logo_start
				ld		de, 0x7900
				ld		bc, altbios_boot_logo_end - altbios_boot_logo_start
				ldir

				ld		a, [main_rom_slot]
				ld		hl, version_id
				call	rdslt

				cp		a, 3
				jr		c, skip_for_msx2_2p

				ld		ix, getcpu
				ld		iy, [main_rom_slot - 1]
				call	calslt
				ld		[_chgcpu + 1], a

				ld		ix, chgcpu
				ld		iy, [main_rom_slot - 1]
				ld		a, 0x80
				call	calslt

				call	0x7900

				ld		ix, chgcpu
				ld		iy, [main_rom_slot - 1]
_chgcpu:
				ld		a, 3
				or		a, 0x80
				call	calslt
				jp		exit_program

skip_for_msx2_2p::
				call	0x7900
exit_program::
				jp		exit_program

altbios_boot_logo_start::
				binary_link "altbios_boot_logo.bin"
altbios_boot_logo_end::
