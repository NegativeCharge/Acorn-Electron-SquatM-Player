;SquatM beeper music engine
;Originally written by Shiru 06'17 for ZX Spectrum 48K
;Ported to Atari 8-bit by Shiru 07'21
;Ported to the Acorn Electron by Negative Charge 11'22

SHEILA_COUNTER          = $FE06
SHEILA_MISC_CONTROL     = $FE07
OSBYTE                  = $FFF4

OP_NOP 					= $EA
OP_ROL_A 				= $2A

.segment "ZEROPAGE"

control_register_value:                 .res 1
speaker_on:                           	.res 1
speaker_off:                            .res 1
ula_control_register_previous_value:    .res 1

vars_start:
loop_ptr:								.res 2
pattern_ptr: 							.res 2
sample_ptr:								.res 2
sample_mask:							.res 1		;$00 or $ff
sample_bit:								.res 1
sample_out:								.res 1
row_length:								.res 1
row_flags:								.res 1
ch0_add:								.res 2
ch1_add:								.res 2
ch2_add:								.res 2
ch3_add:								.res 2
ch0_acc:								.res 2
ch1_acc:								.res 2
ch2_acc:								.res 2
ch3_acc:								.res 2
ch_mixer:								.res 1
ch_acc:									.res 1
noise_acc:								.res 2
noise_add:								.res 2
noise_cnt:								.res 1
noise_div:								.res 1
noise_pitch:							.res 1
noise_volume:							.res 1
temp:									.res 1
vars_end:



.segment "CODE"

.export start

start:

	cld

	lda 	#143
	ldx 	#12
	ldy 	#$FF
	jsr 	OSBYTE                                              ; Claim NMI

	lda 	#$40
	sta 	$D00                                                ; Store RTI as NMI routine

	lda 	#163
	ldx 	#128
	ldy 	#1
	jsr 	OSBYTE                                              ; Disable printer and ADCs

	lda 	#0
	sta 	$2B2                                                ; Clear type byte for ROM 12 (Plus 1) in Paged ROM type table

	LDA     #$0F                                            ; Flush selected wait class
	LDX     #$00                                            ; All waits flushed
	JSR     OSBYTE

	SEI                                                     ; Set interrupt disable
	LDA     #$F2                                            ; Read RAM copy of location &FE07 (ULA SHEILA Misc. Control)
	LDX     #$00
	LDY     #$FF
	JSR     OSBYTE                                          ; Old value returned in X

	STX     ula_control_register_previous_value             ; Store old value
	TXA
	AND     #$F8                                            ; Mask - 11111000
	STA     speaker_off                                     ; Store previous FE07 values for CAPS LOCK LED, CASSETTE MOTOR, and DISPLAY MODE 
	ORA     #$02                                            ; Switch on sound generation - 00000010
	STA     speaker_on                                      ; Store previous FE07 value with sound generation enabled
	LDA     #$00
	STA     SHEILA_COUNTER                                  ; Zero the ULA SHEILA counter (FE06), creating a toggle speaker (inaudible frequency)
	LDX     #$00                                            ; Clear X
	CLI

	; Clear the vsync interrupt by setting a bit.

    lda 	$f4
    ora 	#$10
    sta 	$fe05

    ; Wait until the vsync bit is cleared.

    lda 	#$04
:
    bit 	$fe00
    bne 	:-

    ; Wait until the vsync bit is set, indicating the start of a new frame.

:
    bit 	$fe00
    beq 	:-

    lda 	$f4
    ora 	#$10
    sta 	$fe05
	
	sei

	lda 	#<music_data
	ldx 	#>music_data

play:

	pha
	txa
	pha
	
	lda 	#0
	tax
:
	sta 	vars_start,x
	inx
	cpx 	#vars_end-vars_start
	bne :-

	lda 	#OP_NOP
	sta 	<noise_opcode
	
	pla
	sta 	<pattern_ptr+1
	pla
	sta 	<pattern_ptr+0

	ldy 	#0
	lda 	(pattern_ptr),y
	iny
	sta 	<loop_ptr+0
	lda 	(pattern_ptr),y
	sta		<loop_ptr+1
	
	lda 	<pattern_ptr+0
	clc
	adc 	#2
	sta 	<pattern_ptr+0
	bcc 	:+
	inc 	<pattern_ptr+1
:
	
play_loop:

	ldy 	#1
	lda 	(pattern_ptr),y		;duration of the row (0=loop), bit 7 percussion
	bne 	no_loop
	
return_loop:

	lda 	<loop_ptr+0
	sta 	<pattern_ptr+0
	lda 	<loop_ptr+1
	sta 	<pattern_ptr+1
	jmp 	play_loop

no_loop:

	sta 	<row_length
	
	dey
	lda 	(pattern_ptr),y		;flags DDDN4321 (Drum, Noise, 1-4 channel update)
	iny
	iny
	sta 	<row_flags
	
	lsr 	<row_flags
	bcc 	skip_note_0
	
	lda 	(pattern_ptr),y
	iny
	sta 	<ch0_add+0
	lda 	(pattern_ptr),y
	iny
	sta 	<ch0_add+1
	
skip_note_0:

	lsr 	<row_flags
	bcc 	skip_note_1
	
	lda 	(pattern_ptr),y
	iny
	sta 	<ch1_add+0
	lda 	(pattern_ptr),y
	iny
	sta 	<ch1_add+1
	
skip_note_1:

	lsr 	<row_flags
	bcc 	skip_note_2
	
	lda 	(pattern_ptr),y
	iny
	sta 	<ch2_add+0
	lda 	(pattern_ptr),y
	iny
	sta 	<ch2_add+1
	
skip_note_2:

	lsr 	<row_flags
	bcc 	skip_note_3
	
	lda 	(pattern_ptr),y
	iny
	sta 	<ch3_add+0
	lda 	(pattern_ptr),y
	iny
	sta 	<ch3_add+1
	
skip_note_3:

	lsr 	<row_flags
	bcc 	skip_mode_change
	
	ldx 	#OP_NOP
	lda 	(pattern_ptr),y
	beq 	:+
	ldx 	#OP_ROL_A
:
	stx 	<noise_opcode
	iny
	iny
	
skip_mode_change:

	lda 	<row_flags
	beq 	skip_drum

	asl 	a
	tax
	lda 	sample_list+0-2,x
	sta 	<sample_ptr+0
	lda 	sample_list+1-2,x
	sta 	<sample_ptr+1
	lda 	#$80
	sta 	<sample_mask
	
skip_drum:

	lda 	<row_length
	bpl 	skip_percussion
	
	and 	#$7f			;clear percussion flag
	sta 	<row_length

	lda 	(pattern_ptr),y	;read noise volume
	iny
	sta 	<noise_volume
	
	lda 	(pattern_ptr),y	;read noise pitch
	iny
	sta 	<noise_div
	sta 	<noise_pitch

	tya
	pha
	
	lda 	#<2174			;utz's rand seed
	sta 	<noise_add+0
	sta 	<noise_acc+0
	lda 	#>2174
	sta 	<noise_add+1
	sta 	<noise_acc+1
	
	ldx 	#<(177*64*2/72)	;noise duration, takes as long as inner sound loop
	lda 	#>(177*64*2/72)
	sta 	<noise_cnt
	
noise_loop:

	dec 	<noise_div		;5
	beq 	noise_update	;2/3

noise_skip:

	.repeat 14				;28
	nop
	.endrepeat
	lda 	<0				;3
	jmp 	noise_next		;3
	
noise_update:

	lda 	<noise_acc+0	;3
	adc 	<noise_add+0	;3
	sta 	<noise_acc+0	;3
	lda 	<noise_acc+1	;3
	adc 	<noise_add+1	;3
	cmp 	#$80			;2
	rol 	a				;2
	sta 	<noise_acc+1	;3
	inc 	<noise_add+1	;5
	lda 	<noise_pitch	;3
	sta 	<noise_div		;3
	
noise_next:

	lda 	<noise_acc+1	;3
	;sta 	COLOR4			;4
	jsr		COLOR4			;6
	cmp 	<noise_volume	;3
	bcc 	:+				;2/3
	lda 	#$00			;2
	jmp 	:++				;3
:
	lda 	#$ff			;2
	nop						;2 dummy
:
	;sta	CONSOL			;4
	jsr		CONSOL			;6
	
	txa						;2
	bne 	:+				;2/3
	lda 	<noise_cnt		;3
	beq 	noise_done		;2/3
	dec 	<noise_cnt		;5
:

.ifdef NTSC
	nop						;2	to make pitch and speed match between PAL/NTSC
.endif

	dex						;2
	jmp 	noise_loop		;3=72t
	
noise_done:

	pla
	tay


skip_percussion:

	tya
	clc
	adc 	<pattern_ptr+0
	sta 	<pattern_ptr+0
	bcc 	:+
	inc 	<pattern_ptr+1
:

	lda 	<sample_mask
	sta 	<sample_bit

sound_loop_0:

	ldx 	#64				;internal loop runs 64 times
	ldy 	#0				;sample ptr inside the loop
	
sound_loop:
	
	lda 	(sample_ptr),y	;5+
	and 	<sample_bit		;3
	beq 	:+				;2/3
	lda 	#$ff			;2
	jmp 	:++				;3
:
	nop						;2
	nop						;2
:
	sta 	<sample_out		;3
;18
	lsr 	<sample_bit		;5
	beq 	sample_inc		;2/3

	lda 	<0				;3 dummy
	lda 	<0				;3 dummy
	jmp 	sample_next		;3

sample_inc:

	lda 	<sample_mask	;3
	sta 	<sample_bit		;3
	iny						;2

sample_next:

	lda 	#0				;2
	sta 	<ch_mixer		;3
	
;39
	lda 	<ch0_acc+0		;3
	clc						;2
	adc 	<ch0_add+0		;3
	sta 	<ch0_acc+0		;3
	lda 	<ch0_acc+1		;3
	adc 	<ch0_add+1		;3
	rol 	<ch_mixer		;5
	sta 	<ch0_acc+1		;3
	
	lda 	<ch1_acc+0		;3
	clc						;2
	adc 	<ch1_add+0		;3
	sta 	<ch1_acc+0		;3
	lda 	<ch1_acc+1		;3
	adc 	<ch1_add+1		;3
	rol 	<ch_mixer		;5
	sta 	<ch1_acc+1		;3
	
	lda 	<ch2_acc+0		;3
	clc						;2
	adc 	<ch2_add+0		;3
	sta 	<ch2_acc+0		;3
	lda 	<ch2_acc+1		;3
	adc 	<ch2_add+1		;3
	rol 	<ch_mixer		;5
	sta 	<ch2_acc+1		;3

	lda 	<ch3_acc+0		;3
	clc						;2
	adc 	<ch3_add+0		;3
	sta 	<ch3_acc+0		;3
	lda 	<ch3_acc+1		;3
	adc 	<ch3_add+1		;3
	rol 	<ch_mixer		;5
	cmp 	#$80			;2 needed for rol a, to match Z80's srl h

noise_opcode:
	nop						;2 nop or rol a, self-modifying code here!
	
	sta 	<ch3_acc+1		;3
	
;141

	lda 	<ch_acc			;3
	clc						;2
	adc 	<ch_mixer		;3
	bne 	:+				;2/3
	dec		<temp			;5 dummy
	jmp 	:++				;3
:
	adc 	#$ff			;2
	sta 	<ch_acc			;3
	lda 	#$ff			;2
:
	ora 	<sample_out		;3

	;sta 	COLOR4			;4
	jsr		COLOR4			;6
	
	;sta 	CONSOL			;4	output sound bit
	jsr		CONSOL			;6

.ifdef NTSC
	nop						;2	to make pitch and speed match between PAL/NTSC
.endif

	dex						;2
	bne sound_loop			;2/3=177t
	
	dey						;last byte of a 64/8 byte sample packet is #80 means it was the last packet
	lda (sample_ptr),y
	cmp #$80
	bne sample_no_stop
	
	lda #0					;disable sample reading
	sta <sample_mask

sample_no_stop:

	iny
	tya
	clc
	adc 	<sample_ptr+0
	sta 	<sample_ptr+0
	bcc 	:+
	inc 	<sample_ptr+1
:

	dec 	<row_length
	beq 	:+
	jmp 	sound_loop_0
:
	jmp 	play_loop
	
CONSOL:
    beq 	:+                  ;2/3
    lda 	speaker_on          ;2
    jmp 	:++                 ;3
:
	nop							;2
    lda 	speaker_off         ;2
	nop							;2
:
    sta 	SHEILA_MISC_CONTROL ;4
    rts

COLOR4:
	pha
	beq		:+
	lda 	#$f0
  	sta 	$fe08
  	lda 	#$f0
  	sta 	$fe09
	jmp		:++
:
	lda 	#$ff
  	sta 	$fe08
  	sta 	$fe09
:
	pla
	rts

sample_list:

	.word 	sample_1
	.word 	sample_2
	.word 	sample_3
	.word 	sample_4
	.word 	sample_5
	.word 	sample_6
	.word 	sample_7
	
	.include "tracks\lets_go.track.s"
	
end:
