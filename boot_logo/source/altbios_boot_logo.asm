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

work_area		:=			0xF975				; PLAY文のワークエリア 384byte

; -----------------------------------------------------------------------------
; Initialize VDP
; -----------------------------------------------------------------------------
				scope		init_vdp
init_vdp::
				di

				call		write_vdp_regs

vdp_init_data::
				db			0x80 |  1, 0x23				; R#1  = モードレジスタ SCREEN6, 画面非表示
				db			0x80 |  0, 0x08				; R#0  = モードレジスタ SCREEN6
				db			0x80 |  8, 0x28				; R#8  = モードレジスタ palette0は不透明
				db			0x80 |  9, 0x00				; R#9  : モードレジスタ
				db			0x80 |  2, 0x1F | (1 << 5)	; R#2  : パターンネームテーブル (表示ページ 1)
				db			0x80 |  5, 0x7780 >> 7		; R#5  : スプライトアトリビュートテーブルの下位
				db			0x80 | 11, 0x00				; R#11 : スプライトアトリビュートテーブルの上位
				db			0x80 |  6, 0x7800 >> 11		; R#6  : スプライトパターンジェネレータテーブルのアドレス
				db			0x80 |  7, 0x55				; R#7  : 背景色 
				db			0x80 | 15, 2				; R#15 : ステータスレジスタ 2
				db			0x80 | 16, 0				; R#16 : パレットレジスタ 0
				db			0x80 | 25, 3				; R#25 : モードレジスタ
				db			0x80 | 26, 0x20				; R#26 : 水平スクロールレジスタ
				db			0x80 | 27, 0x01				; R#27 : 水平スクロールレジスタ
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

				endscope


; -----------------------------------------------------------------------------
; Initialize VDP palette
; -----------------------------------------------------------------------------
				scope		init_palette
init_palette::

				ld			a, 13				; read ModeRegister(R#13) of RTC
				out			[rtc_address], a
				in			a, [rtc_data]
				and			a, 0x0C
				or			a, 0x02				; [X][X][1][0]
				out			[rtc_data], a		; Set BLOCK2

				ld			a, 0x0B
				out			[rtc_address], a	; Logo Screen設定
				in			a, [rtc_data]
				and			a, 0x03
				add			a, a
				add			a, a

				ld			h, 0xFF & (color_data1 >> 8)
				add			a, 0xFF & color_data1
				ld			l, a

				ld			bc, (4 << 8) | vdp_port2
				otir

				ld			l, 0xFF & color_data2
				ld			b, 4
				otir
				endscope

; -----------------------------------------------------------------------------
; Initialize VRAM
; -----------------------------------------------------------------------------
				scope		init_vram
				ld			hl, 0x7400			; sprite color table
				ld			bc, 16 * 32			; 16[line/sprite] * 32[sprite]
				ld			a, 0x05				; palette#1, palette#1
				call		fill_vram

				ld			h, 0x78				; sprite generator table
				ld			c, 0x30				; pattern#0 and pattern#1 (half)
				ld			a, 0xFF
				call		fill_vram

				ld			l, 0x30				; sprite generator table
				ld			c, 0x10				; pattern#1 (half)
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
				call		write_vdp_regs

				db			0x80 | 25, 3		; MSK = 1, SP2 = 1
				db			0x80 |  2, 0x3F		; set page 1
_run_lmcm_command:								; dummy execution
				db			0x80 | 46, 0xA0
_run_lmmc_command:
				db			0x80 | 17, 36		; R#17 = 36
				db			0x00

				ld			hl, logo_draw_command
				ld			bc, (logo_draw_command_size << 8) | vdp_port3
				otir

				call		write_vdp_regs

				db			0x80 | 17, 0x80 | 44	; R#17 = 0x80 | 44 (非オートインクリメント)
				db			0x00

				; RLEを展開する
				; HL ... 圧縮データのアドレス
				; A .... 着目位置の圧縮データの値
				; C .... VDP port#3
				; E .... 現在の色: 0=黒, 3=白
				ld			hl, logo_data
				ld			c, vdp_port3
				; _decompress_loop ループ開始時点で A = 0 (return value of write_vdp_regs)
_decompress_loop:
				ld			e, a
				ld			a, [hl]
				inc			hl
				add			a, a
				ld			d, a
				jr			nc, _fixed_data					; [0][C1][C2][C3][N]タイプなら fixed_data へ。

				; [1]の場合
				; Cy' .... 灰色が付く場合 1, 付かない場合 0
				add			a, a
				ex			af, af'							; GRAY情報を保存
				ld			a, d

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
				jr			nz, _gray_process				; RUNが0でなかった場合は、ループ終了。
				ld			d, [hl]							; 次のRUNを取得。
				inc			hl
				ld			b, d
				inc			b
				djnz		_run_length_loop
				dec			b
				jr			_run_length_loop
_gray_process:
				ex			af, af'
				jr			nc, _next_color					; 灰色が付かない場合は何もせずに戻る
				call		wait_tansfer_ready
				ld			a, 2							; 灰色
				out			[c], a
_next_color:
				ld			a, e
				xor			a, 3							; 次の色は反転
				jr			_decompress_loop

				; [0][C1][C2][C3][N]の場合
_fixed_data:
				ld			b, 3
_fixed_data_loop:
				xor			a, a
				rl			d
				rla
				rl			d
				rla
				ld			e, a
				call		wait_tansfer_ready
				out			[c], e							; R#44 = C1
				djnz		_fixed_data_loop
				rlc			d								; Cy = D = [N] 0 または 1
				ld			a, d
				adc			a, d							; A = 0 または 3
				jr			_decompress_loop

				endscope

				scope		wait_tansfer_ready
loop:
				and			a, 0x40
				ret			nz
wait_tansfer_ready::
				in			a, [vdp_port1]
				rrca
				jr			c, loop
_lmmc_end:
				pop			de								; dump return address
				endscope

; -----------------------------------------------------------------------------
; アニメーション処理
; -----------------------------------------------------------------------------
				scope		animation_process
animation_process::
				call		_fill_work_area
				dw			0x00FF, 0x0120

_wait_vsync1:
				in			a, [vdp_port1]
				and			a, 0x40
				jr			z, _wait_vsync1
_wait_vsync2:
				in			a, [vdp_port1]
				and			a, 0x40
				jr			nz, _wait_vsync2

				call		write_vdp_regs

				db			0x80 | 15, 0		; R#15 = 0 (S#0)
				db			0x80 |  1, 0x63		; R#1  = 63h : 画面表示ON
				db			0x00

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
				; 値が減っていくライン
				ld			l, [ix + 0]
				ld			h, [ix + 1]
				ld			e, [iy + 0]
				;or			a, a				; Cy = 0
				sbc			hl, de
				jr			nc, _not_borrow1
				ld			l, d
				ld			h, d
_not_borrow1:
				call		calc_reg_value

				; 値が増えていくライン
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

				call		write_vdp_regs

				db			0x80 | 25, 0		; R#25 = 0
				db			0x80 |  2, 0x1F		; R#2  = 1Fh : 表示ページ0
				db			0x00

				call		_fill_work_area
				dw			0, 0
				ei
				ret

_fill_work_area:
				pop			hl
				ld			de, work_area
				push		de
				ld			bc, 4
				ldir
				ex			[sp], hl
				ld			bc, (80 - 1) * 4
				ldir
				ret

				endscope

; -----------------------------------------------------------------------------
; 水平スクロールレジスタに設定する値に変換する
; -----------------------------------------------------------------------------
				scope		calc_reg_value
calc_reg_value::
				ld			[ix + 0], l
				ld			[ix + 1], h
				; R#26 の値
				dec			hl								; HL = [???????][S8][S7][S6][S5][S4][S3][S2][S1][S0]
				ld			a, l							; A  = [S7][S6][S5][S4][S3][S2][S1][S0]
				rrc			h								; Cy = [S8]
				rra											; A  = [S8][S7][S6][S5][S4][S3][S2][S1]
				rra											; A  = [? ][S8][S7][S6][S5][S4][S3][S2]
				rra											; A  = [? ][? ][S8][S7][S6][S5][S4][S3]
				inc			a
				and			a, 0x3F							; A  = [0 ][0 ][S8][S7][S6][S5][S4][S3]
				ld			[ix + 2], a

				; R#27 の値
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
; 水平スクロールレジスタを更新する
; -----------------------------------------------------------------------------
				scope		set_scroll
set_scroll::
				ld			b, 80
				ld			hl, work_area + 2
_line_loop:
				ld			d, [hl]		; R#26の値
				inc			hl
				ld			e, [hl]		; R#27の値
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
; VDPのコントロールレジスタへ値を書き込む
;
; input:
;	none
; break:
;	AF,HL,E
; comment:
;	呼び出し元に書き込むデータ列を配置する
; -----------------------------------------------------------------------------
				scope		write_vdp_regs
write_vdp_regs::
				pop			hl
				jr			start1
loop1:
				ld			e, a
				ld			a, [hl]
				inc			hl
				out			[vdp_port1], a
				ld			a, e
				out			[vdp_port1], a
start1:
				ld			a, [hl]
				inc			hl
				or			a, a
				jr			nz, loop1
				jp			hl
				endscope

; -----------------------------------------------------------------------------
;	fill vram
;
; input:
;	HL .... 書き込みアドレス Address[15:0] ※Address[16] は 0 に設定される
;	BC .... 書き込むバイト数
;	A ..... 書き込む値
; output:
;	none
; break:
;	A,B,C,E,F,A',F'
; comment:
;	割り込み禁止で呼ぶこと。
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
				djnz		loop
				ret
				endscope

; -----------------------------------------------------------------------------
;	set write vram address
;
; input:
;	HL .... 書き込みアドレス Address[15:0] ※Address[16] は 0 に設定される
; output:
;	none
; break:
;	A,F,A',F'
; comment:
;	割り込み禁止で呼ぶこと。
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
; 色設定データ
;	[palette#0 RB], [palette#0 G], [palette#1 RB], [palette#1 G]
; -----------------------------------------------------------------------------
color_data1::
				db			0x00, 0x00, 0x07, 0x00		; Logo Screen 設定が 0 の場合の色
				db			0x27, 0x02, 0x20, 0x04		; Logo Screen 設定が 1 の場合の色
				db			0x56, 0x00, 0x72, 0x02		; Logo Screen 設定が 2 の場合の色
				db			0x70, 0x00, 0x70, 0x05		; Logo Screen 設定が 3 の場合の色

color_data2::
				db			0x44, 0x04					; palette#2 : gray
				db			0x77, 0x07					; palette#3 : white

; -----------------------------------------------------------------------------
; スプライトアトリビュートテーブル初期化データ
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
				db			0x0D8, 0x000, 0x000, 0x000	; Sprite#9 (   0, 216 ), Pattern 0, Color 0 ※ Y = 216 で、これ以降のスプライトを表示禁止
sprite_attrib_end::

sprite_attrib_size	:= sprite_attrib_end - sprite_attrib

; -----------------------------------------------------------------------------
; アニメーションデータ
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
; ロゴデータ描画用 LMMCコマンド
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
; ロゴデータ
; -----------------------------------------------------------------------------
logo_data::
				binary_link "logo.bin"
end_of_program::
				if (color_data1 & 0xFF) + 16 > 0xFF
					error "COLOR DATA BOUNDARY EXCEEDED"
				endif 
				if end_of_program > 0x8000
					error "LOGO DATA IS TOO BIG!! (Over " + (end_of_program - 0x8000) + "Bytes)"
				else
					message	"FILE SIZE IS OK! (Remain " + (0x8000 - end_of_program) + "Bytes)"
					space	0x8000 - end_of_program, 0xFF
				endif
