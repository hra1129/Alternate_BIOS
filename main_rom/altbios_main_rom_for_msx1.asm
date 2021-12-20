; -----------------------------------------------------------------------------
; Altenate BIOS MAIN-ROM for MSX1
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

						org		0x0000

chkram::
						di
						jp		_chkram
font_address::
						dw		font_data			; ROM Font Data Address
vdp_read_port0::
						db		0x98				; VDP I/O Address
vdp_write_port1::
						db		0x98				; VDP I/O Address
synchr::
						jp		_synshr

font_data::
						include	"altbios_font.asm"

; -----------------------------------------------------------------------------
; [BIOS ENTRY] SYNCHR
;
; input:
;   HL .... チェックする文字のアドレス
;   [SP] .. チェックする文字
; output:
;   HL .... HL + 1
; comment:
;   [HL] と [SP] を比較する。下記のように使われることを想定。
;   target_char1 と target_char2 が比較される。
;
;       LD    HL, target_char1_address
;       RST   SYNCHR
;       DB    target_char2
;      :
;   target_char1_address:
;       DB   target_char1
; -----------------------------------------------------------------------------
						scope	_synshr
_synshr::
						ex		hl, [sp]
						ld		a, [hl]				; A = target_char2
						inc		hl
						ex		hl, [sp]
						cp		a, [hl]				; [hl] = target_char1
						
						endscope					; _synshr
