; -----------------------------------------------------------------------------
; Altenate BIOS Boot Logo Program
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

				org			0x7900

vdp_port0		:=			0x98
vdp_port1		:=			0x99
vdp_port2		:=			0x9A
vdp_port3		:=			0x9B
rtc_address		:=			0xB4
rtc_data		:=			0xB5

work_area		:=			0xF975				; PLAY���̃��[�N�G���A 384byte

; -----------------------------------------------------------------------------
; Initialize VDP
; -----------------------------------------------------------------------------
				scope		init_vdp
init_vdp::
				di
				ld			hl, vdp_init_data
loop1:
				ld			a, [hl]
				inc			hl
				or			a, a
				jr			z, wait_vdp_command
				ld			e, a
				ld			a, [hl]
				inc			hl
				out			[vdp_port1], a
				ld			a, e
				out			[vdp_port1], a
				jr			loop1

vdp_init_data::
				db			0x80 |  1, 0x23				; R#1  = ���[�h���W�X�^ SCREEN6, ��ʔ�\��
				db			0x80 |  0, 0x08				; R#0  = ���[�h���W�X�^ SCREEN6
				db			0x80 |  8, 0x28				; R#8  = ���[�h���W�X�^ palette0�͕s����
				db			0x80 |  9, 0x00				; R#9  : ���[�h���W�X�^
				db			0x80 |  2, 0x1F | (1 << 5)	; R#2  : �p�^�[���l�[���e�[�u�� (�\���y�[�W 1)
				db			0x80 |  5, 0x7780 >> 7		; R#5  : �X�v���C�g�A�g���r���[�g�e�[�u���̉���
				db			0x80 | 11, 0x00				; R#11 : �X�v���C�g�A�g���r���[�g�e�[�u���̏��
				db			0x80 |  6, 0x7800 >> 11		; R#6  : �X�v���C�g�p�^�[���W�F�l���[�^�e�[�u���̃A�h���X
				db			0x80 |  7, 0x55				; R#7  : �w�i�F 
				db			0x80 | 15, 2				; R#15 : �X�e�[�^�X���W�X�^ 2
				db			0x80 | 16, 0				; R#16 : �p���b�g���W�X�^ 0
				db			0x80 | 25, 3				; R#25 : ���[�h���W�X�^
				db			0x80 | 26, 0x20				; R#26 : �����X�N���[�����W�X�^
				db			0x80 | 27, 0x01				; R#27 : �����X�N���[�����W�X�^
				db			0x80 | 36, 0				; R#36 : DX  = 0
				db			0x80 | 37, 0				; R#37 :
				db			0x80 | 38, 0				; R#38 : DY  = 0
				db			0x80 | 39, 0				; R#39 :
				db			0x80 | 40, 0				; R#40 : NX  = 512
				db			0x80 | 41, 2				; R#41 :
				db			0x80 | 42, 0				; R#42 : NY  = 512
				db			0x80 | 43, 2				; R#43 :
				db			0x80 | 44, 0x55				; R#44 : CLR = 0x55
				db			0x80 | 45, 0				; R#45 : ARG = 0
				db			0x80 | 46, 0b11000000		; R#46 : CMR = HMMV
				db			0x00

wait_vdp_command:
				in			a, [vdp_port1]
				and			a, 1
				jr			nz, wait_vdp_command
init_vdp_end:
				endscope

; -----------------------------------------------------------------------------
; Initialize VDP palette
; -----------------------------------------------------------------------------
				scope		init_palette
				ld			a, 13				; read ModeRegister(R#13) of RTC
				out			[rtc_address], a
				in			a, [rtc_data]
				and			a, 0x0C
				or			a, 0x02				; [X][X][1][0]
				out			[rtc_data], a		; Set BLOCK2

				ld			a, 0x0B
				out			[rtc_address], a	; Logo Screen�ݒ�
				in			a, [rtc_data]
				and			a, 0x03
				add			a, a
				add			a, a
				ld			c, a
				ld			b, 0
				ld			hl, color_data
				add			hl, bc
				ld			bc, (4 << 8) | vdp_port2
loop:
				ld			a, [hl]
				inc			hl
				out			[c], a
				djnz		loop
				ld			hl, 0x0444			; palette#2 : gray
				out			[c], l
				out			[c], h
				ld			hl, 0x0777			; palette#3 : white
				out			[c], l
				out			[c], h
				endscope

; -----------------------------------------------------------------------------
; Initialize VRAM
; -----------------------------------------------------------------------------
				scope		init_vram
				ld			hl, 0x7400			; sprite color table
				ld			bc, 16 * 32			; 16[line/sprite] * 32[sprite]
				ld			a, 0x05				; palette#1, palette#1
				call		fill_vram

				ld			hl, 0x7800			; sprite generator table
				ld			bc, 0x30			; pattern#0 and pattern#1 (half)
				ld			a, 0xFF
				call		fill_vram

				ld			hl, 0x7830			; sprite generator table
				ld			bc, 0x10			; pattern#1 (half)
				ld			a, 0xF0
				call		fill_vram

				ld			hl, 0x7600			; sprite attribute table
				call		set_write_vram_address
				ld			hl, sprite_attrib
				ld			bc, (sprite_attrib_size << 8) | vdp_port0
				otir
				endscope

; -----------------------------------------------------------------------------
; decompress logo image
; -----------------------------------------------------------------------------
				scope		decompress_logo_image
decompress_logo_image::
				ld			de, ((0x80 | 25) << 8) | 3		; MSK = 1, SP2 = 1
				call		write_vdp_reg
				ld			de, ((0x80 | 2 ) << 8) | 0x3F	; set page 1
				call		write_vdp_reg

_run_lmcm_command:											; dummy execution
				ld			de, ((0x80 | 46) << 8) | 0xA0
				call		write_vdp_reg

_run_lmmc_command:
				ld			de, ((0x80 | 17) << 8) | 36		; R#17 = 36
				call		write_vdp_reg

				ld			hl, logo_draw_command
				ld			bc, (logo_draw_command_size << 8) | vdp_port3
				otir

				ld			de, ((0x80 | 17) << 8) | (0x80 | 44)	; R#17 = 0x80 | 44 (��I�[�g�C���N�������g)
				call		write_vdp_reg

				; RLE��W�J����
				; HL ... ���k�f�[�^�̃A�h���X
				; A .... ���ڈʒu�̈��k�f�[�^�̒l
				; C .... VDP port#3
				; E .... ���݂̐F: 0=��, 3=��
				ld			hl, logo_data
				ld			e, 0
				ld			c, vdp_port3
_decompress_loop:
				ld			a, [hl]
				inc			hl
				rlca
				jr			nc, _fixed_data					; [0][C1][C2][C3][N]�^�C�v�Ȃ� fixed_data �ցB

				; [1]�̏ꍇ
				; D .... �D�F���t���ꍇ 1, �t���Ȃ��ꍇ 0
				ld			d, 0
				rlca
				rl			d
				push		de								; GRAY����ۑ�
				rrca
				rrca
				and			a, 0b0011_1111					;  0, 1, 2, ... , 63
				ld			d, a
				jr			nz, _skip_non_zero
				ld			a, 63
_skip_non_zero:
				ld			b, a							; 63, 1, 2, ... , 63
_run_length_loop:
				call		wait_tansfer_ready
				out			[c], e							; output current color
				djnz		_run_length_loop
				ld			a, d
				or			a, a
				jr			nz, _gray_process				; RUN��0�łȂ������ꍇ�́A���[�v�I���B
				ld			d, [hl]							; ����RUN���擾�B
				inc			hl
				ld			b, d
				inc			b
				dec			b
				jr			nz, _run_length_loop
				dec			b
				jr			_run_length_loop
_gray_process:
				pop			af
				or			a, a
				jr			z, _next_color					; �D�F���t���Ȃ��ꍇ�͉��������ɖ߂�
				push		af
				call		wait_tansfer_ready
				pop			af
				ld			a, 2							; �D�F
				out			[c], a
_next_color:
				ld			a, e
				xor			a, 3
				ld			e, a							; ���̐F�͔��]
				jr			_decompress_loop

				; [0][C1][C2][C3][N]�̏ꍇ
_fixed_data:												; ���̎��_�� Cy=0
				ld			b, 3
				ld			d, a
				push		de								; dummy gray data
_fixed_data_loop:
				ld			e, 0
				rl			d
				rl			e
				rl			d
				rl			e
				call		wait_tansfer_ready
				out			[c], e							; R#44 = C1
				djnz		_fixed_data_loop
				rlc			d								; D = [N] 0 �܂��� 1
				ld			a, d
				add			a, d
				add			a, d							; A = 0 �܂��� 3
				pop			de
				ld			e, a
				jr			_decompress_loop

wait_tansfer_ready::
				in			a, [vdp_port1]
				rrca
				jr			nc, _lmmc_end
				and			a, 0x40
				jp			z, wait_tansfer_ready
				ret

_lmmc_end:
				pop			de								; dump return address
				pop			de								; dump gray data
				endscope

; -----------------------------------------------------------------------------
; �A�j���[�V��������
; -----------------------------------------------------------------------------
				scope		animation_process
animation_process::
				ld			hl, 0x00FF
				ld			[work_area + 0], hl
				ld			hl, 0x0120
				ld			[work_area + 2], hl
				ld			hl, work_area
				ld			de, work_area + 4
				ld			bc, (80 - 1) * 4
				ldir

_wait_vsync1:
				in			a, [vdp_port1]
				and			a, 0x40
				jr			z, _wait_vsync1
_wait_vsync2:
				in			a, [vdp_port1]
				and			a, 0x40
				jr			nz, _wait_vsync2

				ld			de, ((0x80 | 15) << 8) | 0			; R#15 = 0 (S#0)
				call		write_vdp_reg

				ld			de, ((0x80 | 1 ) << 8) | 0x63		; R#1  = 63h : ��ʕ\��ON
				call		write_vdp_reg

				ld			bc, (21 << 8) | vdp_port3
_main_loop:
				push		bc
				call		set_scroll

_update_scroll_position:
				ld			ix, work_area
				ld			iy, animation_data
				ld			b, 40
				ld			d, 0
_update_scroll_loop:
				; �l�������Ă������C��
				ld			l, [ix + 0]
				ld			h, [ix + 1]
				ld			e, [iy + 0]
				or			a, a
				sbc			hl, de
				jr			nc, _not_borrow1
				ld			l, d
				ld			h, d
_not_borrow1:
				call		calc_reg_value

				; �l�������Ă������C��
				ld			l, [ix + 0]
				ld			h, [ix + 1]
				ld			e, [iy + 0]
				add			hl, de
				ld			a, h
				cp			a, 2
				jr			c, _not_carry1
				ld			hl, 512
_not_carry1:
				call		calc_reg_value
				djnz		_update_scroll_loop

				pop			bc
				djnz		_main_loop

				ld			de, ((0x80 | 25) << 8) | 0		; R#25 = 0
				call		write_vdp_reg
				ld			de, ((0x80 | 2 ) << 8) | 0x1f	; R#2  = 1Fh : �\���y�[�W0
				call		write_vdp_reg

				xor			a, a
				ld			[work_area], a
				ld			hl, work_area
				ld			de, work_area + 1
				ld			bc, 80 * 4 - 1
				ldir
				ei
				ret
				endscope

; -----------------------------------------------------------------------------
; �����X�N���[�����W�X�^�ɐݒ肷��l�ɕϊ�����
; -----------------------------------------------------------------------------
				scope		calc_reg_value
calc_reg_value::
				ld			[ix + 0], l
				ld			[ix + 1], h
				; R#26 �̒l
				dec			hl								; HL = [???????][S8][S7][S6][S5][S4][S3][S2][S1][S0]
				ld			a, l							; A  = [S7][S6][S5][S4][S3][S2][S1][S0]
				rrc			h								; Cy = [S8]
				rra											; A  = [S8][S7][S6][S5][S4][S3][S2][S1]
				rra											; A  = [? ][S8][S7][S6][S5][S4][S3][S2]
				rra											; A  = [? ][? ][S8][S7][S6][S5][S4][S3]
				inc			a
				and			a, 0x3f							; A  = [0 ][0 ][S8][S7][S6][S5][S4][S3]
				ld			[ix + 2], a

				; R#27 �̒l
				ld			a, 7
				sub			a, l							; A  = 7 - [?????][S2][S1][S0]
				and			a, 0x07
				ld			[ix + 3], a

				inc			ix
				inc			ix
				inc			ix
				inc			ix
				inc			iy
				ret
				endscope

; -----------------------------------------------------------------------------
; �����X�N���[�����W�X�^���X�V����
; -----------------------------------------------------------------------------
				scope		set_scroll
set_scroll::
				ld			b, 80
				ld			hl, work_area + 2
_line_loop:
				ld			d, [hl]		; R#26�̒l
				inc			hl
				ld			e, [hl]		; R#27�̒l
				inc			hl
				inc			hl
				inc			hl

				ld			a, 26
				out			[vdp_port1], a
				ld			a, 0x80 | 17
				out			[vdp_port1], a			; R#17 = 26

				in			a, [vdp_port1]
_wait_clash_sprite:
				in			a, [vdp_port1]			; S#0
				and			a, 0x20
				jp			z, _wait_clash_sprite

				out			[c], d					; R#26
				out			[c], e					; R#27
				djnz		_line_loop

				ld			a, 26
				out			[vdp_port1], a
				ld			a, 0x80 | 17
				out			[vdp_port1], a			; R#17 = 26
				xor			a, a
				out			[c], a					; R#26 = 0
				out			[c], a					; R#27 = 0
				ret
				endscope

; -----------------------------------------------------------------------------
; VDP�̃R���g���[�����W�X�^�֒l����������
;
; input:
;	D ..... VDP���W�X�^�ԍ�
;	E ..... VDP���W�X�^�ɏ������ޒl
; break:
;	none
; -----------------------------------------------------------------------------
				scope		write_vdp_reg
write_vdp_reg::
				push		af
				ld			a, e
				out			[vdp_port1], a
				ld			a, d
				out			[vdp_port1], a
				pop			af
				ret
				endscope

; -----------------------------------------------------------------------------
;	fill vram
;
; input:
;	HL .... �������݃A�h���X Address[15:0] ��Address[16] �� 0 �ɐݒ肳���
;	BC .... �������ރo�C�g��
;	A ..... �������ޒl
; output:
;	none
; break:
;	A,B,C,E,F,A',F'
; comment:
;	���荞�݋֎~�ŌĂԂ��ƁB
; -----------------------------------------------------------------------------
				scope		fill_vram
fill_vram::
				ld			e, a
				call		set_write_vram_address

				ld			a, c
				or			a, a
				ld			a, e
				jr			z, skip
				inc			b
skip:
loop:
				out			[vdp_port0], a
				dec			c
				jr			nz, loop
				dec			b
				jr			nz, loop
				ret
				endscope

; -----------------------------------------------------------------------------
;	set write vram address
;
; input:
;	HL .... �������݃A�h���X Address[15:0] ��Address[16] �� 0 �ɐݒ肳���
; output:
;	none
; break:
;	A,F,A',F'
; comment:
;	���荞�݋֎~�ŌĂԂ��ƁB
; -----------------------------------------------------------------------------
				scope		set_write_vram_address
set_write_vram_address::
				ld			a, h
				and			a, 0x3F
				or			a, 0x40
				ex			af, af'
				ld			a, h
				rlca
				rlca
				and			a, 0x03
				out			[vdp_port1], a
				ld			a, 0x80 | 14
				out			[vdp_port1], a
				ld			a, l
				out			[vdp_port1], a
				ex			af, af'
				out			[vdp_port1], a
				ret
				endscope

; -----------------------------------------------------------------------------
; �F�ݒ�f�[�^
;	[palette#0 RB], [palette#0 G], [palette#1 RB], [palette#1 G]
; -----------------------------------------------------------------------------
color_data::
				db			0x00, 0x00, 0x07, 0x00		; Logo Screen �ݒ肪 0 �̏ꍇ�̐F
				db			0x27, 0x02, 0x20, 0x04		; Logo Screen �ݒ肪 1 �̏ꍇ�̐F
				db			0x56, 0x00, 0x72, 0x02		; Logo Screen �ݒ肪 2 �̏ꍇ�̐F
				db			0x70, 0x00, 0x70, 0x05		; Logo Screen �ݒ肪 3 �̏ꍇ�̐F

; -----------------------------------------------------------------------------
; �X�v���C�g�A�g���r���[�g�e�[�u���������f�[�^
; -----------------------------------------------------------------------------
sprite_attrib::
				db			0x01F, 0x0E8, 0x000, 0x000	; Sprite#0 ( 232,  31 ), Pattern 0, Color 0
				db			0x01F, 0x0E8, 0x000, 0x000	; Sprite#1 ( 232,  31 ), Pattern 0, Color 0
				db			0x03F, 0x0E8, 0x000, 0x000	; Sprite#2 ( 232,  63 ), Pattern 0, Color 0
				db			0x03F, 0x0E8, 0x000, 0x000	; Sprite#3 ( 232,  63 ), Pattern 0, Color 0
				db			0x04F, 0x0E8, 0x000, 0x000	; Sprite#4 ( 232,  79 ), Pattern 0, Color 0
				db			0x04F, 0x0E8, 0x000, 0x000	; Sprite#5 ( 232,  79 ), Pattern 0, Color 0
				db			0x01F, 0x000, 0x004, 0x000	; Sprite#6 (   0,  31 ), Pattern 4, Color 0
				db			0x03F, 0x000, 0x004, 0x000	; Sprite#7 (   0,  63 ), Pattern 4, Color 0
				db			0x04F, 0x000, 0x004, 0x000	; Sprite#8 (   0,  79 ), Pattern 4, Color 0
				db			0x0D8, 0x000, 0x000, 0x000	; Sprite#9 (   0, 216 ), Pattern 0, Color 0 �� Y = 216 �ŁA����ȍ~�̃X�v���C�g��\���֎~
sprite_attrib_end::

sprite_attrib_size	:= sprite_attrib_end - sprite_attrib

; -----------------------------------------------------------------------------
; �A�j���[�V�����f�[�^
; -----------------------------------------------------------------------------
animation_data::
				db			0x13, 0x0D
				db			0x15, 0x12
				db			0x14, 0x0E
				db			0x10, 0x17
				db			0x13, 0x11
				db			0x15, 0x11
				db			0x0E, 0x0D
				db			0x11, 0x15
				db			0x0C, 0x11
				db			0x13, 0x11
				db			0x15, 0x15
				db			0x12, 0x0C
				db			0x0F, 0x10
				db			0x0E, 0x0E
				db			0x15, 0x0D
				db			0x0F, 0x11
				db			0x11, 0x11
				db			0x17, 0x14
				db			0x0D, 0x0D
				db			0x0C, 0x0C
				db			0x0D, 0x10
				db			0x15, 0x12
				db			0x17, 0x10
				db			0x0E, 0x17
				db			0x11, 0x0C
				db			0x12, 0x13
				db			0x17, 0x0E
				db			0x16, 0x14
				db			0x14, 0x0E
				db			0x14, 0x15
				db			0x0E, 0x0E
				db			0x13, 0x0F
				db			0x11, 0x13
				db			0x13, 0x0F
				db			0x17, 0x15
				db			0x0D, 0x15
				db			0x0F, 0x17
				db			0x0C, 0x0D
				db			0x16, 0x0C
				db			0x11, 0x0E

; -----------------------------------------------------------------------------
; ���S�f�[�^�`��p LMMC�R�}���h
; -----------------------------------------------------------------------------
logo_draw_command::
				dw			45							; R#36, 37: DX
				dw			32							; R#38, 39: DY
				dw			422							; R#40, 41: NX
				dw			80							; R#42, 43: NY
				db			0							; R#44: CLR
				db			0							; R#45: ARG
				db			0b1011_0000					; R#46: CMD    LMMC command
logo_draw_command_end:

logo_draw_command_size := logo_draw_command_end - logo_draw_command

; -----------------------------------------------------------------------------
; ���S�f�[�^
; -----------------------------------------------------------------------------
logo_data::
				binary_link "logo.bin"
end_of_program::
				if end_of_program > 0x8000
					error "LOGO DATA IS TOO BIG!! (Over " + (end_of_program - 0x8000) + "Bytes)"
				else
					message	"FILE SIZE IS OK! (Remain " + (0x8000 - end_of_program) + "Bytes)"
					space	0x8000 - end_of_program, 0xFF
				endif
