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

PPI_PORT_A				:= 0xA8
PPI_PORT_B				:= 0xA9
PPI_PORT_C				:= 0xAA
PPI_PORT_CMD			:= 0xAB

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
; [BIOS ENTRY] CHKRAM
;
; input:
;   None
; output:
;   None
; -----------------------------------------------------------------------------
						scope	_chkram
_chkram::
						ld		a, 0x82					; PortA, C => Output, PortB => Input, With RESET
						out		[ PPI_PORT_CMD ], a
						ld		a, 0x50
						out		[ PPI_PORT_C ], a		; CAPS-LED OFF, CMT-MOTOR OFF
						xor		a, a
						ld		c, a

						; 拡張スロットの有無を調べる
						out		[ PPI_PORT_A ], a		; PrimarySlot
						sla		c
						ld		b, 0
						ld		hl, 0xFFFF
						ld		[hl], 0xF0				; 0x0Fを書く
						ld		a, [hl]					; 拡張スロットがあれば 0xF0が読まれる
						sub		a, 0x0Fh				; 拡張スロットがあれば 0 になる
						jr		nz, not_found_ext_slot

						ld		[hl], a					; まだ確実で無いので 0を書く
						ld		a, [hl]					; 拡張スロットがあれば 0xFF になる
						inc		a						; 拡張スロットがあれば 0 になる
						jr		nz, not_found_ext_slot

not_found_ext_slot:

						endscope

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
