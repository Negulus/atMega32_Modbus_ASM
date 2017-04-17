;частота процессора на 1МГц, делитель счётчика на 64, тогда 64 мкс на такт. 11 тактов между байтами, 28 тактов между сообщениями
;***** STK500 LEDS and SWITCH demonstration
.nolist
.include "m32def.inc"
;***** Initialization
.list

.def tmp1 = r17
.def ctumb = r18

.def mb_st = r2		;статус ModBus
.def mb_ctu = r3	;счётчик modBus
.def mb_num = r4	;колчиество байт информации

.def crc_ctu_bit = r20
.def crc_ctu_byte = r8
.def crc_poll = r21
.def crc_polh = r22

.def tmp = r16
.def r00 = r5
.def r01 = r6

.DSEG
modbus: .BYTE 32 ;32 байта под отсылаемую информацию
modbus1: .BYTE 32 ;32 байта под принятую информацию
crc_16: .BYTE 2 ;2 байта под подсчёт контрольной crc 16
coil: .BYTE 2 ;2 байта под битовые регистры
din: .BYTE 2 ;2 байта под дискретные входы
reghold: .BYTE 32 ;32 байта под закрытые регистры
regin: .BYTE 32 ;32 байта под входные регистры
regwr: .BYTE 32 ;32 байта под записываемые регистры
digit: .BYTE 16 ;16 байт

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

;инициализация памяти
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

;инициализация счётчика
ldi tmp,0b10
out TCCR1A,r16
ldi tmp,21 ;максимум счётчика на 21
out OCR1AL,tmp
ldi tmp,9 ;второй компаратор на 19
out OCR1BL,tmp
;ldi tmp,0b11 ;делитель счётчика на 64
;sts 0x45,tmp
ldi tmp,0
out TCCR1B,tmp ;остановить счётчик
out TCNT1L,tmp ;сбросить счётчик
ldi tmp,0b11000 ;прерывание по A и B
out TIMSK,tmp

;инициализация USART0

ldi tmp,0
out UCSRA,tmp

ldi tmp,0b00000000 ;выключение USART
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

;инициализация портов
ldi tmp,0b11110000
out DDRD,tmp

ser tmp
out DDRA,tmp
out DDRC,tmp

;in r16,UBRRH
;in r16,UCSRC

;инициализация ModBus
;0 - готов, 1 - передача, 2 - приём, 3 - приём нового пакета, 4 - ошибка crc, 5 - ошибка выполнения
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

;подсчёт контрольной суммы байтов по начальному адресу в z и количеству в mb_num
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

;начало передачи
mb_start_snd:
	sbrs mb_st,0
	rjmp mb_start_snd_end

	mb_start_snd3:
	out TCCR1B,r00 ;остановить счётчик
	ldi tmp,0b00001000 ;включение USART на передачу и выключение прерывания
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

	ldi tmp,0b00101000 ;включение USART на передачу + прерывание по пустому регистру usart
	out UCSRB,tmp

	mb_start_snd_end:
ret

;посылка следующего байта
mb_next_snd:
push tmp
push r30
push r31

	cp mb_num,mb_ctu
	brne mb_next_snd1

	ldi tmp,0b00001000 ;включение USART на передачу + выключение прерываний
	out UCSRB,tmp

	out TCNT1L,r00 ;сбросить счётчик
	ldi tmp,0b101 ;делитель счётчика на 64
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

;окончание передачи
mb_snd_end:
push tmp

	out TCCR1B,r00 ;остановить счётчик
	mov mb_st,r01
	rcall mb_start_rcv

pop tmp
ret

;счётчик событие B
ctu_1b:
	sei
ret

;счётчик событие A
ctu_1a:
	sbrc mb_st,1
		rjmp mb_snd_end ;окончание передачи по счётчику
	sbrc mb_st,2
		rjmp mb_rcv_end ;окончание приёма по счётчику
ret

;окончание приёма
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

	ldi tmp,0b00001000 ;включение USART на передачу и выключение на приём
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

;начало приёма
mb_start_rcv:
	sbrc mb_st,0
		rjmp mb_start_rcv1
	rjmp mb_start_rcv_end

	mb_start_rcv1:
	ldi tmp,0b1100
	mov mb_st,tmp

	ldi tmp,0b10011000 ;включение USART на приём, передачу и прерывание по приёму
	out UCSRB,tmp

	;зачем там было 0xff я хз
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

	out TCNT1L,r00 ;сбросить счётчик

	sbrs mb_st,3
		rjmp mb_rcvd1

	clr mb_ctu
	ldi tmp,0b00000100
	mov mb_st,tmp
	ldi tmp,0b101 ;делитель счётчика на 64
	out TCCR1B,tmp

	mb_rcvd1:
	mov tmp,mb_ctu
	cpi tmp,32
	brne mb_rcvd2
	ldi tmp,0b00001000 ;выключение USART на приём и включение на передачу
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

;проверка принятых данных
check_rcv:
;загрузка принятого байта функции из памяти
	ldi r30,low(modbus1+1)
	ldi r31,high(modbus1+1)
	ld tmp,z

	;проверка номера функции для подсчёта количества байтов
	cpi tmp,7 ;tmp-7
	brpl check_rcv2 ;переход если >=0
	ldi tmp,6
	mov mb_num,tmp ;6 байт у функции (для функций 1-6)
	rjmp check_rcv5

	;установка количества байтов для функций 0f и 10
	check_rcv2:
	cpi tmp,0x0f ;проверка функции 0f
	brne check_rcv3 ;переход если другая
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
	cpi tmp,0x10 ;проверка функции 10
	brne check_rcv7er ;переход если другая
	ldi r30,low(modbus1+6)
	ldi r31,high(modbus1+6)
	ld mb_num,z
	ldi tmp,7
	add mb_num,tmp
	rjmp check_rcv5

	;подсчёт контрольной суммы
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

	cp tmp,tmp1 ;сравнение полученой crc с расчитанной (байт 0)
	brne check_rcv6 ;переход если не равны

	ldi r30,low(crc_16+1)
	ldi r31,high(crc_16+1)
	ld tmp,z
	ldi r30,low(modbus1+1)
	ldi r31,high(modbus1+1)
	add r30,mb_num
	adc r30,r00
	ld tmp1,z

	cp tmp,tmp1 ;сравнение полученой crc с расчитанной (байт 1)
	brne check_rcv6 ;переход если не равны

	rjmp check_rcv7 ;переход если всё совпало

	check_rcv6:
	ldi tmp,0b00010001 ;установка бита ошибки crc
	mov mb_st,tmp
	rjmp check_rcv7

	;финт ушами, иначе слишком далеко прыгать
	check_rcv7er:
	rjmp check_rcv_er

	check_rcv7:
	ldi r30,low(modbus1+1)
	ldi r31,high(modbus1+1)
	ld tmp,z ;загрузка номера функции

	cpi tmp,1 ;првоерка на функцию 1
	brne check_rcv702 ;переход если не функция 1
	rcall func01
	rjmp check_rcv_end

	check_rcv702:
	cpi tmp,2 ;првоерка на функцию 2
	brne check_rcv703 ;переход если не функция 2
	rcall func02
	rjmp check_rcv_end

	check_rcv703:
	cpi tmp,3 ;првоерка на функцию 3
	brne check_rcv704 ;переход если не функция 3
	rcall func03
	rjmp check_rcv_end

	check_rcv704:
	cpi tmp,4 ;првоерка на функцию 4
	brne check_rcv705 ;переход если не функция 4
	rcall func04
	rjmp check_rcv_end

	check_rcv705:
	cpi tmp,5 ;првоерка на функцию 5
	brne check_rcv706 ;переход если не функция 5
	rcall func05
	rjmp check_rcv_end

	check_rcv706:
	cpi tmp,6 ;првоерка на функцию 6
	brne check_rcv70f ;переход если не функция 6
	rcall func06
	rjmp check_rcv_end

	check_rcv70f:
	cpi tmp,0x0f ;првоерка на функцию 0f
	brne check_rcv710 ;переход если не функция 0f
	rcall func0f
	rjmp check_rcv_end

	check_rcv710:
	cpi tmp,0x10 ;првоерка на функцию 10
	brne check_rcv_er ;переход если не функция 10
	rcall func10
	rjmp check_rcv_end

	;ошибка - неправильная функция
	check_rcv_er:
	ldi r30,low(modbus1+1)
	ldi r31,high(modbus1+1)
	ld tmp1,z ;загрузка кода функции
	ldi r30,low(modbus)
	ldi r31,high(modbus)
	ldi tmp,0x01 ; запись адреса устройства
	st z,tmp
	ori tmp1,0b10000000 ;увеличение кода функции на 80h
	adiw z,1
	st z,tmp1
	adiw z,1
	ldi tmp,0x01
	st z,tmp
	ldi tmp,3
	mov mb_num,tmp
	rjmp check_rcv_end ;переход к концу процедуры

	check_rcv_end:
	rjmp mb_start_snd
ret

;функция 01 - чтение битовых регистров
func01:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func01_er1_1 ;переход на ошибку (недопустимый адрес) если байт 2 больше 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func01_er1_1 ;переход на ошибку (недопустимый адрес) если байт 3 больше 15

	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func01_er1_1 ;переход на ошибку (недопустимый адрес) если байт 4 больше 0
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	breq func01_er2_1 ;переход на ошибку (неверные данные) если байт 5 равен 0
	mov crc_ctu_byte,tmp1
	add tmp1,tmp
	cpi tmp1,17
	brpl func01_er1_1 ;переход на ошибку (недопустимый адрес) если байт 4 + байт 5 больше 15
	;---------------------
	;обработка запроса
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

	;финты ушами
	rjmp func01_er1_2
	func01_er1_1:
	rjmp func01_er1
	func01_er1_2:

	rjmp func01_er2_2
	func01_er2_1:
	rjmp func01_er2
	func01_er2_2:

	;определение количества байтов в ответе
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

;функция 02 - чтение дискретных входов (аналогично func01)
func02:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func02_er1_1 ;переход на ошибку (недопустимый адрес) если байт 2 больше 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func02_er1_1 ;переход на ошибку (недопустимый адрес) если байт 3 больше 15

	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func02_er1_1 ;переход на ошибку (недопустимый адрес) если байт 4 больше 0
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	breq func02_er2_1 ;переход на ошибку (неверные данные) если байт 5 равен 0
	mov crc_ctu_byte,tmp1
	add tmp1,tmp
	cpi tmp1,17
	brpl func02_er1_1 ;переход на ошибку (недопустимый адрес) если байт 4 + байт 5 больше 15
	;---------------------
	;обработка запроса
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

	;финты ушами
	rjmp func02_er1_2
	func02_er1_1:
	rjmp func02_er1
	func02_er1_2:

	rjmp func02_er2_2
	func02_er2_1:
	rjmp func02_er2
	func02_er2_2:

	;определение количества байтов в ответе
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

;функция 03 - чтение закрытых регистров
func03:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func03_er1 ;переход на ошибку (недопустимый адрес) если байт 2 больше 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func03_er1 ;переход на ошибку (недопустимый адрес) если байт 3 больше 15

	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func03_er1 ;переход на ошибку (недопустимый адрес) если байт 4 больше 0
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	breq func03_er2 ;переход на ошибку (неверные данные) если байт 5 равен 0
	mov crc_ctu_byte,tmp1
	add tmp1,tmp
	cpi tmp1,17
	brpl func03_er1 ;переход на ошибку (недопустимый адрес) если байт 4 + байт 5 больше 15
	;---------------------
	;обработка запроса

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

;функция 04 - чтение входных регистров (аналогично func03)
func04:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func04_er1 ;переход на ошибку (недопустимый адрес) если байт 2 больше 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func04_er1 ;переход на ошибку (недопустимый адрес) если байт 3 больше 15

	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func04_er1 ;переход на ошибку (недопустимый адрес) если байт 4 больше 0
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	breq func04_er2 ;переход на ошибку (неверные данные) если байт 5 равен 0
	mov crc_ctu_byte,tmp1
	add tmp1,tmp
	cpi tmp1,17
	brpl func04_er1 ;переход на ошибку (недопустимый адрес) если байт 4 + байт 5 больше 15
	;---------------------
	;обработка запроса

	;увеличение адреса и количества байт в 2 раза
	ldi tmp1,2
	mul tmp1,crc_ctu_byte
	mov crc_ctu_byte,r0
	mul tmp1,tmp
	mov tmp,r0
	
	;подготовка адресов памяти (y - регистры, z - сообщение)
	ldi r28,low(reghold)
	ldi r29,high(reghold)
	add r28,tmp
	adc r29,r00
	ldi r30,low(modbus+3)
	ldi r31,high(modbus+3)

	;цикл копирования памяти
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

	;системные байты сообщения
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

	;создание сообщения об ошибке 01
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

	;создание сообщения об ошибке 02
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

;функция 05 - запись битового регистра
func05:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func05_er1_1 ;переход на ошибку (недопустимый адрес) если байт 2 больше 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func05_er1_1 ;переход на ошибку (недопустимый адрес) если байт 3 больше 15

	adiw z,1
	ld tmp1,z
	cpi tmp1,0x00
	breq func05_1
	cpi tmp1,0xff
	breq func05_1
	rjmp func05_er2_1 ;переход на ошибку (неверные данные) если байт 4 не равен 00 или FF

	func05_1:
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func05_er2_1 ;переход на ошибку (неверные данные) если байт 5 не равен 00
	;---------------------
	;обработка запроса
	
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
	;получение кода операции (00 или FF)
	ldi r30,low(modbus1+4)
	ldi r31,high(modbus1+4)
	ld tmp,z
	cpi tmp,0xff
	brne func05_4 ;если не FF, то перейти

	;установка бита в памяти методом OR
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
	;снятие бита в памяти методом AND
	com r28 ;инвертирование
	com r29 ;инвертирование
	ldi r30,low(coil)
	ldi r31,high(coil)
	ld tmp,z
	and tmp,r28
	st z,tmp
	adiw z,1
	ld tmp,z
	and tmp,r29
	st z,tmp

	;финты ушами
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

	;создание сообщения об ошибке 01
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

	;создание сообщения об ошибке 02
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

;функция 06 - запись одного регистра
func06:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func06_er1 ;переход на ошибку (недопустимый адрес) если байт 2 больше 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func06_er1 ;переход на ошибку (недопустимый адрес) если байт 3 больше 15
	;---------------------
	;обработка запроса
	adiw z,1
	ld r28,z
	adiw z,1
	ld r29,z

	;сохранение в память новых данных по адресу
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

	;создание сообщения об ошибке 01
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

;функция 0f - запись нескольких битовых регистров
func0f:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func0f_er1 ;переход на ошибку (недопустимый адрес) если байт 2 больше 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func0f_er1 ;переход на ошибку (недопустимый адрес) если байт 3 больше 15
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func0f_er1 ;переход на ошибку (недопустимый адрес) если байт 4 не равен 00
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	breq func0f_er2 ;переход на ошибку (неверные данные) если байт 5 равен 0
	mov crc_ctu_byte,tmp1
	add tmp1,tmp
	cpi tmp1,17
	brpl func0f_er1 ;переход на ошибку (недопустимый адрес) если байт 3 + байт 5 больше 15

	;---------------------
	;обработка запроса
	
	;пока ничего не придумал работающего

	;создание сообщения об ошибке 01
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

	;создание сообщения об ошибке 02
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

;функция 10 - запись нескольких регистров
func10:
	ldi r30,low(modbus1+2)
	ldi r31,high(modbus1+2)
	ld tmp,z
	cpi tmp,0
	brne func10_er1 ;переход на ошибку (недопустимый адрес) если байт 2 больше 0
	adiw z,1
	ld tmp,z
	cpi tmp,16
	brpl func10_er1 ;переход на ошибку (недопустимый адрес) если байт 3 больше 15
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	brne func10_er1 ;переход на ошибку (недопустимый адрес) если байт 4 не равен 00
	adiw z,1
	ld tmp1,z
	cpi tmp1,0
	breq func10_er2 ;переход на ошибку (неверные данные) если байт 5 равен 0
	add tmp1,tmp
	cpi tmp1,17
	brpl func10_er1 ;переход на ошибку (недопустимый адрес) если байт 3 + байт 5 больше 15

	;---------------------
	;обработка запроса
	adiw z,1
	ld tmp1,z ;количество байт

	mov crc_ctu_bit,r01
	ldi r28,low(regwr)
	ldi r29,high(regwr)
	add r28,tmp
	adc r29,r00

	func10_1:
	;загрузка новых данных
	adiw z,1
	ld tmp,z

	;сохранение в память новых данных по адресу
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

	;создание сообщения об ошибке 01
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

	;создание сообщения об ошибке 02
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
