@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "C:\Atmel\atmega32\labels.tmp" -fI -W+ie -C V2E -o "C:\Atmel\atmega32\atmega32.hex" -d "C:\Atmel\atmega32\atmega32.obj" -e "C:\Atmel\atmega32\atmega32.eep" -m "C:\Atmel\atmega32\atmega32.map" "C:\Atmel\atmega32\atmega32.asm"
