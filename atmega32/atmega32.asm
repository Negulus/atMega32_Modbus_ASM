;������� ���������� �� 1���, �������� �������� �� 64, ����� 64 ��� �� ����. 11 ������ ����� �������, 28 ������ ����� �����������
;***** STK500 LEDS and SWITCH demonstration
.nolist
.include "m32def.inc"
;***** Initialization
.list

.def tmp1 = r17
.def ctumb = r18

.def mb_st = r2		;������ ModBus
.def mb_ctu = r3	;������� modBus
.def mb_num = r4	;���������� ���� ����������

.def crc_ctu_bit = r20
.def crc_ctu_byte = r8
.def crc_poll = r21
.def crc_polh = r22

.def tmp = r16
.def r00 = r5
.def r01 = r6

.DSEG
modbus: .BYTE 32 ;32 ����� ��� ���������� ����������
modbus1: .BYTE 32 ;32 ����� ��� �������� ����������
crc_16: .BYTE 2 ;2 ����� ��� ������� ����������� crc 16
coil: .BYTE 2 ;2 ����� ��� ������� ��������
din: .BYTE 2 ;2 ����� ��� ���������� �����
reghold: .BYTE 32 ;32 ����� ��� �������� ��������
regin: .BYTE 32 ;32 ����� ��� ������� ��������
regwr: .BYTE 32 ;32 ����� ��� ������������ ��������
digit: .BYTE 16 ;16 ����

.MACRO popf
cli
pop tmp
out SREG,tmp
sei
.ENDMACRO

.MACRO pushf
cli
in tmp,SREG
push tmp
sei
.ENDMACRO

.CSEG

RESET:
rjmp START
ret
ret
ret
ret
ret
ret
.org 0x000E
rjmp ctu_1a ; Timer0 Compare A Handler
rjmp ctu_1b ; Timer0 Compare B Handler
rjmp ctu_1b
ret
ret
ret
rjmp ctu_0
.org 0x001A
rjmp mb_rcvd ;USART, RX Complete Handler
rjmp mb_next_snd
rjmp mb_next_snd ;USART, TX Complete Handler
rjmp MAIN
rjmp MAIN
rjmp MAIN
rjmp MAIN
rjmp MAIN
rjmp MAIN
rjmp MAIN
rjmp MAIN
rjmp MAIN

START:

ldi tmp,high(RAMEND)
out SPH,tmp
ldi tmp,low(RAMEND)
out SPL,tmp

ldi tmp,0
mov r00,tmp
ldi tmp,1
mov r01,tmp

;������������� ������
;01 06 00 ad 04 2f
ldi r30,low(modbus)
ldi r31,high(modbus)
ldi tmp,0x01
st z,tmp
adiw z,1
ldi tmp,0x06
st z,tmp
adiw z,1
ldi tmp,0x00
st z,tmp
adiw z,1
ldi tmp,0xad
st z,tmp
adiw z,1
ldi tmp,0x04
st z,tmp
adiw z,1
ldi tmp,0x2f
st z,tmp

	ldi r30,low(coil)
	ldi r31,high(coil)
	ldi tmp,0
	st z,tmp
	adiw z,1
	st z,tmp

ldi r30,low(regwr)
ldi r31,high(regwr)
ldi tmp,10
st z,tmp

;-----------------------------
ldi r30,low(digit)
ldi r31,high(digit)
;0
ldi tmp,0b11000000 ;0
st z,tmp
adiw z,1
ldi tmp,0b11111001 ;1
st z,tmp
adiw z,1
ldi tmp,0b10100100 ;2
st z,tmp
adiw z,1
ldi tmp,0b10110000 ;3
st z,tmp
adiw z,1
ldi tmp,0b10011001 ;4
st z,tmp
adiw z,1
ldi tmp,0b10010010 ;5
st z,tmp
adiw z,1
ldi tmp,0b10000010 ;6
st z,tmp
adiw z,1
ldi tmp,0b11111000 ;7
st z,tmp
adiw z,1
ldi tmp,0b10000000 ;8
st z,tmp
adiw z,1
ldi tmp,0b10010000 ;9
st z,tmp
adiw z,1
ldi tmp,0b10001000 ;a
st z,tmp
adiw z,1
ldi tmp,0b10000011 ;b
st z,tmp
adiw z,1
ldi tmp,0b11000110 ;c
st z,tmp
adiw z,1
ldi tmp,0b10100001; d
st z,tmp
adiw z,1
ldi tmp,0b10000110 ;e
st z,tmp
adiw z,1
ldi tmp,0b10001110 ;f
st z,tmp
adiw z,1
;-----------------------------

;ldi tmp,0b10000000
;sts CLKPR,r16
;ldi tmp,0b00000000
;sts CLKPR,r16

;01 10 00 ad 00 03 06 24 58 54 2d 3d fa

;������������� ��������
ldi tmp,0b10
out TCCR1A,r16
ldi tmp,21 ;�������� �������� �� 21
out OCR1AL,tmp
ldi tmp,9 ;������ ���������� �� 19
out OCR1BL,tmp
;ldi tmp,0b11 ;�������� �������� �� 64
;sts 0x45,tmp
ldi tmp,0
out TCCR1B,tmp ;���������� �������
out TCNT1L,tmp ;�������� �������
ldi tmp,0b11000 ;���������� �� A � B
out TIMSK,tmp

;������������� USART0

ldi tmp,0
out UCSRA,tmp

ldi tmp,0b00000000 ;���������� USART
out UCSRB,tmp

;ldi tmp,0b10000000
;out UCSRC,tmp

ldi tmp,0b10000110
out UCSRC,tmp

ldi tmp,0b00000110
out UCSRC,tmp

ldi tmp,0
out UBRRH,tmp

ldi tmp,25
out UBRRL,tmp

;������������� ������
ldi tmp,0b11110000
out DDRD,tmp

ser tmp
out DDRA,tmp
out DDRC,tmp

;in r16,UBRRH
;in r16,UCSRC

;������������� ModBus
;0 - �����, 1 - ��������, 2 - ����, 3 - ���� ������ ������, 4 - ������ crc, 5 - ������ ����������
mov mb_st,r01
clr mb_ctu

ldi tmp,100
out OCR0,tmp
ldi tmp,0b101
out TCCR0,tmp
in tmp,TIMSK
ori tmp,0b10
out TIMSK,tmp

clr r10
clr r12
clr r13

out PORTA,r01
out PORTC,r01

rcall mb_start_rcv
MAIN:
	ldi r26,low(coil)
	ldi r27,high(coil)
	ld tmp,x

	sbrc tmp,0
	sbi PORTD,6
	rjmp main_1
	sbrs tmp,0
	cbi PORTD,6
	main_1:

	cbr tmp,0

;-----------------
	ldi r26,low(modbus1)
	ldi r27,high(modbus1)
	add r26,r10
	adc r27,r00
	ld tmp,x
	lsr tmp
	lsr tmp
	lsr tmp
	lsr tmp
	rcall select
	out PORTA,tmp
	ld tmp,x
	lsl tmp
	lsl tmp
	lsl tmp
	lsl tmp
	lsr tmp
	lsr tmp
	lsr tmp
	lsr tmp
	rcall select
	out PORTC,tmp
;-----------------

	nop
rjmp MAIN

;������� ����������� ����� ������ �� ���������� ������ � z � ���������� � mb_num
crc_calc:
	ld tmp,z

	ldi crc_poll,0x01
	ldi crc_polh,0xa0

	ser r26
	ser r27
	mov crc_ctu_byte,r00

	crc_calc3:
	eor r26,tmp
	clr crc_ctu_bit

	crc_calc2:
	bclr 0
	ror r27
	ror r26
	brcc crc_calc1
	eor r26,crc_poll
	eor r27,crc_polh
	
	crc_calc1:
	inc crc_ctu_bit
	cpi crc_ctu_bit,8
	brne crc_calc2
	inc crc_ctu_byte
	adiw z,1
	ld tmp,z
	cp crc_ctu_byte,mb_num
	brne crc_calc3

	ldi r28,low(crc_16)
	ldi r29,high(crc_16)
	st y,r26
	adiw y,1
	st y,r27
ret

;������ ��������
mb_start_snd:
	sbrs mb_st,0
	rjmp mb_start_snd_end

	mb_start_snd3:
	out TCCR1B,r00 ;���������� �������
	ldi tmp,0b00001000 ;��������� USART �� �������� � ���������� ����������
	out UCSRB,tmp
	ldi tmp, 0b00000010
	mov mb_st,tmp

	ldi r30,low(modbus)
	ldi r31,high(modbus)
	rcall crc_calc

	ldi r28,low(crc_16)
	ldi r29,high(crc_16)
	ld tmp,y
;	add r30,mb_num
;	adc r31,r00
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp

	inc mb_num
	inc mb_num

	clr mb_ctu
	sei

	ldi tmp,0b00101000 ;��������� USART �� �������� + ���������� �� ������� �������� usart
	out UCSRB,tmp

	mb_start_snd_end:
ret

;������� ���������� �����
mb_next_snd:
push tmp
push r30
push r31

	cp mb_num,mb_ctu
	brne mb_next_snd1

	ldi tmp,0b00001000 ;��������� USART �� �������� + ���������� ����������
	out UCSRB,tmp

	out TCNT1L,r00 ;�������� �������
	ldi tmp,0b101 ;�������� �������� �� 64
	out TCCR1B,tmp
	rjmp mb_next_snd_end

	mb_next_snd1:

	ldi r30,low(modbus)
	ldi r31,high(modbus)
	add r30,mb_ctu
	adc r31,r00
	ld tmp,z
	out UDR,tmp

	inc mb_ctu

	mb_next_snd_end:
	sei

pop r31
pop r30
pop tmp
ret

;��������� ��������
mb_snd_end:
push tmp

	out TCCR1B,r00 ;���������� �������
	mov mb_st,r01
	rcall mb_start_rcv

pop tmp
ret

;������� ������� B
ctu_1b:
	sei
ret

;������� ������� A
ctu_1a:
	sbrc mb_st,1
		rjmp mb_snd_end ;��������� �������� �� ��������
	sbrc mb_st,2
		rjmp mb_rcv_end ;��������� ����� �� ��������
ret

;��������� �����
mb_rcv_end:
push tmp
push tmp1
push crc_poll
push crc_polh
push crc_ctu_bit
push crc_ctu_byte
push r0
push r1
push r26
push r27
push r28
push r29
push r30
push r31

	sei
	sbrs mb_st,2
	rjmp mb_rcv_end_end

	mov mb_st,r01
	clr mb_ctu

	ldi tmp,0b00001000 ;��������� USART �� �������� � ���������� �� ����
	out UCSRB,tmp

	rcall check_rcv

	mb_rcv_end_end:

pop r31
pop r30
pop r29
pop r28
pop r27
pop r26
pop r1
pop r0
pop crc_ctu_byte
pop crc_ctu_bit
pop crc_polh
pop crc_poll
pop tmp1
pop tmp
ret

;������ �����
mb_start_rcv:
	sbrc mb_st,0
		rjmp mb_start_rcv1
	rjmp mb_start_rcv_end

	mb_start_rcv1:
	ldi tmp,0b1100
	mov mb_st,tmp

	ldi tmp,0b10011000 ;��������� USART �� ����, �������� � ���������� �� �����
	out UCSRB,tmp

	;����� ��� ���� 0xff � ��
	ldi tmp,0x00
	mov mb_num,tmp
	
	mb_start_rcv_end:
	sei
ret


;RX Complete Handler
mb_rcvd:
push tmp
push r30
push r31

	out TCNT1L,r00 ;�������� �������

	sbrs mb_st,3
		rjmp mb_rcvd1

	clr mb_ctu
	ldi tmp,0b00000100
	mov mb_st,tmp
	ldi tmp,0b101 ;�������� �������� �� 64
	out TCCR1B,tmp

	mb_rcvd1:
	mov tmp,mb_ctu
	cpi tmp,32
	brne mb_rcvd2
	ldi tmp,0b00001000 ;���������� USART �� ���� � ��������� �� ��������
	out UCSRB,tmp
	rjmp mb_rcvd_end

	mb_rcvd2:
	ldi r30,low(modbus1)
	ldi r31,high(modbus1)
	add r30,mb_ctu
	adc r31,r00
	in tmp,UDR
;clr tmp

;sbic UDR,0
;sbr tmp,0
;sbis UDR,0
;cbr tmp,0

;sbic UDR,1
;sbr tmp,1
;sbis UDR,1
;cbr tmp,1

;sbic UDR,2
;sbr tmp,2
;sbis UDR,2
;cbr tmp,2

;sbic UDR,3
;sbr tmp,3
;sbis UDR,3
;cbr tmp,3

;sbic UDR,4
;sbr tmp,4
;sbis UDR,4
;cbr tmp,4

;sbic UDR,5
;sbr tmp,5
;sbis UDR,5
;cbr tmp,5

;sbic UDR,6
;sbr tmp,6
;sbis UDR,6
;cbr tmp,6

;sbic UDR,7
;sbr tmp,7
;sbis UDR,7
;cbr tmp,7

	st z,tmp

	inc mb_ctu
	mb_rcvd_end:
	sei

pop r31
pop r30
pop tmp
ret

;�������� �������� ������
check_rcv:
;�������� ��������� ����� ������� �� ������
	ldi r30,low(modbus1+1)
	ldi r31,high(modbus1+1)
	ld tmp,z

	;�������� ������ ������� ��� �������� ���������� ������
	cpi tmp,7 ;tmp-7
	brpl check_rcv2 ;������� ���� >=0
	ldi tmp,6
	mov mb_num,tmp ;6 ���� � ������� (��� ������� 1-6)
	rjmp check_rcv5

	;��������� ���������� ������ ��� ������� 0f � 10
	check_rcv2:
	cpi tmp,0x0f ;�������� ������� 0f
	brne check_rcv3 ;������� ���� ������
	ldi r30,low(modbus1+6)
	ldi r31,high(modbus1+6)
	ld mb_num,z
	ldi tmp,2
	mul mb_num,tmp
	mov mb_num,r0
	ldi tmp,7
	add mb_num,tmp
	rjmp check_rcv5

	check_rcv3:
	cpi tmp,0x10 ;�������� ������� 10
	brne check_rcv7er ;������� ���� ������
	ldi r30,low(modbus1+6)
	ldi r31,high(modbus1+6)
	ld mb_num,z
	ldi tmp,7
	add mb_num,tmp
	rjmp check_rcv5

	;������� ����������� �����
	check_rcv5:
	ldi r30,low(modbus1)
	ldi r31,high(modbus1)
	rcall crc_calc

	ldi r30,low(crc_16)
	ldi r31,high(crc_16)
	ld tmp,z
	ldi r30,low(modbus1)
	ldi r31,high(modbus1)
	add r30,mb_num
	adc r31,r00
	ld tmp1,z

	cp tmp,tmp1 ;��������� ��������� crc � ����������� (���� 0)
	brne check_rcv6 ;������� ���� �� �����

	ldi r30,low(crc_16+1)
	ldi r31,high(crc_16+1)
	ld tmp,z
	ldi r30,low(modbus1+1)
	ldi r31,high(modbus1+1)
	add r30,mb_num
	adc r30,r00
	ld tmp1,z

	cp tmp,tmp1 ;��������� ��������� crc � ����������� (���� 1)
	brne check_rcv6 ;������� ���� �� �����

	rjmp check_rcv7 ;������� ���� �� �������

	check_rcv6:
	ldi tmp,0b00010001 ;��������� ���� ������ crc
	mov mb_st,tmp
	rjmp check_rcv7

	;���� �����, ����� ������� ������ �������
	check_rcv7er:
	rjmp check_rcv_er

	check_rcv7:
	ldi r30,low(modbus1+1)
	ldi r31,high(modbus1+1)
	ld tmp,z ;�������� ������ �������

	cpi tmp,1 ;�������� �� ������� 1
	brne check_rcv702 ;������� ���� �� ������� 1
	rcall func01
	rjmp check_rcv_end

	check_rcv702:
	cpi tmp,2 ;�������� �� ������� 2
	brne check_rcv703 ;������� ���� �� ������� 2
	rcall func02
	rjmp check_rcv_end

	check_rcv703:
	cpi tmp,3 ;�������� �� ������� 3
	brne check_rcv704 ;������� ���� �� ������� 3
	rcall func03
	rjmp check_rcv_end

	check_rcv704:
	cpi tmp,4 ;�������� �� ������� 4
	brne check_rcv705 ;������� ���� �� ������� 4
	rcall func04
	rjmp check_rcv_end

	check_rcv705:
	cpi tmp,5 ;�������� �� ������� 5
	brne check_rcv706 ;������� ���� �� ������� 5
	rcall func05
	rjmp check_rcv_end

	check_rcv706:
	cpi tmp,6 ;�������� �� ������� 6
	brne check_rcv70f ;������� ���� �� ������� 6
	rcall func06
	rjmp check_rcv_end

	check_rcv70f:
	cpi tmp,0x0f ;�������� �� ������� 0f
	brne check_rcv710 ;������� ���� �� ������� 0f
	rcall func0f
	rjmp check_rcv_end

	check_rcv710:
	cpi tmp,0x10 ;�������� �� ������� 10
	brne check_rcv_er ;������� ���� �� ������� 10
	rcall func10
	rjmp check_rcv_end

	;������ - ������������ �������
	check_rcv_er:
	ldi r30,low(modbus1+1)
	ldi r31,high(modbus1+1)
	ld tmp1,z ;�������� ���� �������
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01 ; ������ ������ ����������
	st z,tmp
	ori tmp1,0b10000000 ;���������� ���� ������� �� 80h
	adiw z,1
	st z,tmp1
	adiw z,1
	ldi tmp,0x01
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp check_rcv_end ;������� � ����� ���������

	check_rcv_end:
	rjmp mb_start_snd
ret

;������� 01 - ������ ������� ���������
func01:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func01_er1_1 ;������� �� ������ (������������ �����) ���� ���� 2 ������ 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func01_er1_1 ;������� �� ������ (������������ �����) ���� ���� 3 ������ 15

	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func01_er1_1 ;������� �� ������ (������������ �����) ���� ���� 4 ������ 0
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	breq func01_er2_1 ;������� �� ������ (�������� ������) ���� ���� 5 ����� 0
	mov crc_ctu_byte,tmp1
	add tmp1,tmp
	cpi tmp1,17
	brpl func01_er1_1 ;������� �� ������ (������������ �����) ���� ���� 4 + ���� 5 ������ 15
	;---------------------
	;��������� �������
	rjmp func01_2

	func01_1:
	ldi tmp1,2
	mul r28,tmp1
	mov r28,r0
	mul r29,tmp1
	mov r29,r0
	add r28,r01
	adc r29,r00
	inc crc_ctu_bit
	rjmp func01_3

	func01_2:
	mov crc_ctu_bit,r01
	ldi r28,1
	ldi r29,0

	func01_3:
	cp crc_ctu_bit,crc_ctu_byte
	brmi func01_1
	rjmp func01_4

	func01_5:
	lsl r28
	rol r29
	inc crc_ctu_bit
	rjmp func01_6

	func01_4:
	mov crc_ctu_bit,r00
	func01_6:
	cp crc_ctu_bit,tmp
	brmi func01_5

	ldi r30,low(coil)
	ldi r31,high(coil)
	ld tmp1,z
	and r28,tmp1
	adiw z,1
	ld tmp1,z
	and r29,tmp1
	mov crc_ctu_bit,r00
	rjmp func01_7

	func01_8:
	lsr r29
	ror r28
	inc crc_ctu_bit
	rjmp func01_7

	func01_7:
	cp crc_ctu_bit,tmp
	brmi func01_8
	;---------------------

	;����� �����
	rjmp func01_er1_2
	func01_er1_1:
	rjmp func01_er1
	func01_er1_2:

	rjmp func01_er2_2
	func01_er2_1:
	rjmp func01_er2
	func01_er2_2:

	;����������� ���������� ������ � ������
	mov tmp,crc_ctu_byte
	cpi tmp,9
	brpl func01_10
	ldi tmp1,01
	ldi tmp,4
	mov mb_num,tmp
	rjmp func01_11
	func01_10:
	ldi tmp1,02
	ldi tmp,5
	mov mb_num,tmp
	ldi r30,low(modbus+5)
	ldi r31,high(modbus+5)
	st z,r29

	func01_11:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,01
	st z,tmp
	adiw z,1
	ldi tmp,01
	st z,tmp
	adiw z,1
	st z,tmp1
	adiw z,1
	st z,r28

	rjmp func01_end

	func01_er1:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x81
	st z,tmp
	adiw z,1
	ldi tmp,0x02
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp func01_end

	func01_er2:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x81
	st z,tmp
	adiw z,1
	ldi tmp,0x03
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp func01_end

func01_end:
ret

;������� 02 - ������ ���������� ������ (���������� func01)
func02:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func02_er1_1 ;������� �� ������ (������������ �����) ���� ���� 2 ������ 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func02_er1_1 ;������� �� ������ (������������ �����) ���� ���� 3 ������ 15

	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func02_er1_1 ;������� �� ������ (������������ �����) ���� ���� 4 ������ 0
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	breq func02_er2_1 ;������� �� ������ (�������� ������) ���� ���� 5 ����� 0
	mov crc_ctu_byte,tmp1
	add tmp1,tmp
	cpi tmp1,17
	brpl func02_er1_1 ;������� �� ������ (������������ �����) ���� ���� 4 + ���� 5 ������ 15
	;---------------------
	;��������� �������
	rjmp func02_2

	func02_1:
	ldi tmp1,2
	mul r28,tmp1
	mov r28,r0
	mul r29,tmp1
	mov r29,r0
	add r28,r01
	adc r29,r00
	inc crc_ctu_bit
	rjmp func02_3

	func02_2:
	mov crc_ctu_bit,r01
	ldi r28,1
	ldi r29,0

	func02_3:
	cp crc_ctu_bit,crc_ctu_byte
	brmi func02_1
	rjmp func02_4

	func02_5:
	lsl r28
	rol r29
	inc crc_ctu_bit
	rjmp func02_6

	func02_4:
	mov crc_ctu_bit,r00
	func02_6:
	cp crc_ctu_bit,tmp
	brmi func02_5

	ldi r30,low(din)
	ldi r31,high(din)
	ld tmp1,z
	and r28,tmp1
	adiw z,1
	ld tmp1,z
	and r29,tmp1
	mov crc_ctu_bit,r00
	rjmp func02_7

	func02_8:
	lsr r29
	ror r28
	inc crc_ctu_bit
	rjmp func02_7

	func02_7:
	cp crc_ctu_bit,tmp
	brmi func02_8
	;---------------------

	;����� �����
	rjmp func02_er1_2
	func02_er1_1:
	rjmp func02_er1
	func02_er1_2:

	rjmp func02_er2_2
	func02_er2_1:
	rjmp func02_er2
	func02_er2_2:

	;����������� ���������� ������ � ������
	mov tmp,crc_ctu_byte
	cpi tmp,8
	brpl func02_10
	ldi tmp1,01
	ldi tmp,4
	mov mb_num,tmp
	rjmp func02_11
	func02_10:
	ldi tmp1,02
	ldi tmp,5
	mov mb_num,tmp
	ldi r30,low(modbus+5)
	ldi r31,high(modbus+5)
	st z,r29

	func02_11:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,01
	st z,tmp
	adiw z,1
	ldi tmp,02
	st z,tmp
	adiw z,1
	st z,tmp1
	adiw z,1
	st z,r28

	rjmp func02_end

	func02_er1:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x82
	st z,tmp
	adiw z,1
	ldi tmp,0x02
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp func02_end

	func02_er2:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x82
	st z,tmp
	adiw z,1
	ldi tmp,0x03
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp func02_end

func02_end:
ret

;������� 03 - ������ �������� ���������
func03:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func03_er1 ;������� �� ������ (������������ �����) ���� ���� 2 ������ 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func03_er1 ;������� �� ������ (������������ �����) ���� ���� 3 ������ 15

	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func03_er1 ;������� �� ������ (������������ �����) ���� ���� 4 ������ 0
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	breq func03_er2 ;������� �� ������ (�������� ������) ���� ���� 5 ����� 0
	mov crc_ctu_byte,tmp1
	add tmp1,tmp
	cpi tmp1,17
	brpl func03_er1 ;������� �� ������ (������������ �����) ���� ���� 4 + ���� 5 ������ 15
	;---------------------
	;��������� �������

	ldi tmp1,2
	mul tmp1,crc_ctu_byte
	mov crc_ctu_byte,r0
	mul tmp1,tmp
	mov tmp,r0

	ldi r28,low(reghold)
	ldi r29,high(reghold)
	add r28,tmp
	adc r29,r00
	ldi r30,low(modbus+3)
	ldi r31,high(modbus+3)

	mov crc_ctu_bit,r00
	func03_1:
	cp crc_ctu_bit,crc_ctu_byte
	brpl func03_2
	inc crc_ctu_bit
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	rjmp func03_1

	func03_2:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x03
	st z,tmp
	adiw z,1
	st z,crc_ctu_byte
	mov mb_num,crc_ctu_byte
	rjmp func03_end

	func03_er1:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x83
	st z,tmp
	adiw z,1
	ldi tmp,0x02
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp func03_end

	func03_er2:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x83
	st z,tmp
	adiw z,1
	ldi tmp,0x03
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp func03_end

func03_end:
ret

;������� 04 - ������ ������� ��������� (���������� func03)
func04:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func04_er1 ;������� �� ������ (������������ �����) ���� ���� 2 ������ 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func04_er1 ;������� �� ������ (������������ �����) ���� ���� 3 ������ 15

	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func04_er1 ;������� �� ������ (������������ �����) ���� ���� 4 ������ 0
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	breq func04_er2 ;������� �� ������ (�������� ������) ���� ���� 5 ����� 0
	mov crc_ctu_byte,tmp1
	add tmp1,tmp
	cpi tmp1,17
	brpl func04_er1 ;������� �� ������ (������������ �����) ���� ���� 4 + ���� 5 ������ 15
	;---------------------
	;��������� �������

	;���������� ������ � ���������� ���� � 2 ����
	ldi tmp1,2
	mul tmp1,crc_ctu_byte
	mov crc_ctu_byte,r0
	mul tmp1,tmp
	mov tmp,r0
	
	;���������� ������� ������ (y - ��������, z - ���������)
	ldi r28,low(reghold)
	ldi r29,high(reghold)
	add r28,tmp
	adc r29,r00
	ldi r30,low(modbus+3)
	ldi r31,high(modbus+3)

	;���� ����������� ������
	mov crc_ctu_bit,r00
	func04_1:
	cp crc_ctu_bit,crc_ctu_byte
	brpl func04_2
	inc crc_ctu_bit
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	rjmp func04_1

	;��������� ����� ���������
	func04_2:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x03
	st z,tmp
	adiw z,1
	st z,crc_ctu_byte
	mov mb_num,crc_ctu_byte
	rjmp func04_end

	;�������� ��������� �� ������ 01
	func04_er1:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x84
	st z,tmp
	adiw z,1
	ldi tmp,0x02
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp func04_end

	;�������� ��������� �� ������ 02
	func04_er2:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x84
	st z,tmp
	adiw z,1
	ldi tmp,0x03
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp func04_end

func04_end:
ret

;������� 05 - ������ �������� ��������
func05:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func05_er1_1 ;������� �� ������ (������������ �����) ���� ���� 2 ������ 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func05_er1_1 ;������� �� ������ (������������ �����) ���� ���� 3 ������ 15

	adiw z,1
	ld tmp1,z
	cpi tmp1,0x00
	breq func05_1
	cpi tmp1,0xff
	breq func05_1
	rjmp func05_er2_1 ;������� �� ������ (�������� ������) ���� ���� 4 �� ����� 00 ��� FF

	func05_1:
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func05_er2_1 ;������� �� ������ (�������� ������) ���� ���� 5 �� ����� 00
	;---------------------
	;��������� �������
	
	mov crc_ctu_bit,r00
	mov r28,r01
	mov r29,r00

	func05_2:
	cp crc_ctu_bit,tmp
	brpl func05_3
	lsl r28
	rol r29
	inc crc_ctu_bit
	rjmp func05_2

	func05_3:
	;��������� ���� �������� (00 ��� FF)
	ldi r30,low(modbus1+4)
	ldi r31,high(modbus1+4)
	ld tmp,z
	cpi tmp,0xff
	brne func05_4 ;���� �� FF, �� �������

	;��������� ���� � ������ ������� OR
	ldi r30,low(coil)
	ldi r31,high(coil)
	ld tmp,z
	or tmp,r28
	st z,tmp
	adiw z,1
	ld tmp,z
	or tmp,r29
	st z,tmp
	rjmp func05_5

	func05_4:
	;������ ���� � ������ ������� AND
	com r28 ;��������������
	com r29 ;��������������
	ldi r30,low(coil)
	ldi r31,high(coil)
	ld tmp,z
	and tmp,r28
	st z,tmp
	adiw z,1
	ld tmp,z
	and tmp,r29
	st z,tmp

	;����� �����
	rjmp func05_er1_2
	func05_er1_1:
	rjmp func05_er1
	func05_er1_2:

	rjmp func05_er2_2
	func05_er2_1:
	rjmp func05_er2
	func05_er2_2:

	func05_5:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi r28,low(modbus1)
	ldi r29,high(modbus1)
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	ldi tmp,6
	mov mb_num,tmp

	rjmp func05_end

	;�������� ��������� �� ������ 01
	func05_er1:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x85
	st z,tmp
	adiw z,1
	ldi tmp,0x02
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp func05_end

	;�������� ��������� �� ������ 02
	func05_er2:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x85
	st z,tmp
	adiw z,1
	ldi tmp,0x03
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp func05_end

func05_end:
ret

;������� 06 - ������ ������ ��������
func06:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func06_er1 ;������� �� ������ (������������ �����) ���� ���� 2 ������ 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func06_er1 ;������� �� ������ (������������ �����) ���� ���� 3 ������ 15
	;---------------------
	;��������� �������
	adiw z,1
	ld r28,z
	adiw z,1
	ld r29,z

	;���������� � ������ ����� ������ �� ������
	ldi r30,low(regwr)
	ldi r31,high(regwr)
	add r30,tmp
	adc r31,r00
	st z,r28
	adiw z,1
	st z,r29

	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi r28,low(modbus1)
	ldi r29,high(modbus1)
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	ldi tmp,6
	mov mb_num,tmp
	rjmp func06_end

	;�������� ��������� �� ������ 01
	func06_er1:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x86
	st z,tmp
	adiw z,1
	ldi tmp,0x02
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp

func06_end:
ret

;������� 0f - ������ ���������� ������� ���������
func0f:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func0f_er1 ;������� �� ������ (������������ �����) ���� ���� 2 ������ 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func0f_er1 ;������� �� ������ (������������ �����) ���� ���� 3 ������ 15
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func0f_er1 ;������� �� ������ (������������ �����) ���� ���� 4 �� ����� 00
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	breq func0f_er2 ;������� �� ������ (�������� ������) ���� ���� 5 ����� 0
	mov crc_ctu_byte,tmp1
	add tmp1,tmp
	cpi tmp1,17
	brpl func0f_er1 ;������� �� ������ (������������ �����) ���� ���� 3 + ���� 5 ������ 15

	;---------------------
	;��������� �������
	
	;���� ������ �� �������� �����������

	;�������� ��������� �� ������ 01
	func0f_er1:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x8f
	st z,tmp
	adiw z,1
	ldi tmp,0x02
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp func0f_end

	;�������� ��������� �� ������ 02
	func0f_er2:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x8f
	st z,tmp
	adiw z,1
	ldi tmp,0x03
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp

func0f_end:
ret

;������� 10 - ������ ���������� ���������
func10:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func10_er1 ;������� �� ������ (������������ �����) ���� ���� 2 ������ 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func10_er1 ;������� �� ������ (������������ �����) ���� ���� 3 ������ 15
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func10_er1 ;������� �� ������ (������������ �����) ���� ���� 4 �� ����� 00
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	breq func10_er2 ;������� �� ������ (�������� ������) ���� ���� 5 ����� 0
	add tmp1,tmp
	cpi tmp1,17
	brpl func10_er1 ;������� �� ������ (������������ �����) ���� ���� 3 + ���� 5 ������ 15

	;---------------------
	;��������� �������
	adiw z,1
	ld tmp1,z ;���������� ����

	mov crc_ctu_bit,r01
	ldi r28,low(regwr)
	ldi r29,high(regwr)
	add r28,tmp
	adc r29,r00

	func10_1:
	;�������� ����� ������
	adiw z,1
	ld tmp,z

	;���������� � ������ ����� ������ �� ������
	st y,tmp
	adiw y,1
	inc crc_ctu_bit
	cp tmp1,crc_ctu_bit
	brpl func10_1

	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi r28,low(modbus1)
	ldi r29,high(modbus1)
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	adiw y,1
	adiw z,1
	ld tmp,y
	st z,tmp
	ldi tmp,6
	mov mb_num,tmp
	rjmp func10_end

	;�������� ��������� �� ������ 01
	func10_er1:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x90
	st z,tmp
	adiw z,1
	ldi tmp,0x02
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp func10_end

	;�������� ��������� �� ������ 02
	func10_er2:
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01
	st z,tmp
	adiw z,1
	ldi tmp,0x90
	st z,tmp
	adiw z,1
	ldi tmp,0x03
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp

func10_end:
ret

ctu_0:
push tmp
push r30
push r31
pushf
	inc r11
	ldi r30,low(regwr)
	ldi r31,high(regwr)
	ld tmp,z
	cp r11,tmp
	brmi ctu_0_end
	clr r11

clr tmp
sbic PIND,2
sbr tmp,2
sbis PIND,2
cbr tmp,2

cp tmp,r12
breq main_2
brpl main_2
inc r10
mov tmp1,r10
cpi tmp1,8
brne main_2
clr r10
main_2:
mov r12,tmp

clr tmp
sbic PIND,3
sbr tmp,3
sbis PIND,3
cbr tmp,3

cp tmp,r13
breq main_3
brpl main_3
clr r10
main_3:
mov r13,tmp


	sbic PORTD,7
	rjmp ctu_0_1
	sbi PORTD,7
	rjmp ctu_0_end

	ctu_0_1:
	cbi PORTD,7

	ctu_0_end:
popf
pop r31
pop r30
pop tmp
sei
reti

select:
push r30
push r31
ldi r30,low(digit)
ldi r31,high(digit)
add r30,tmp
adc r31,r00
ld tmp,z
pop r31
pop r30
ret
