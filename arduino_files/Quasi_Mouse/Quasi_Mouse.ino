/*
A great portion of this code is copied from shared libraries or
open-source example codes, not for commercial use. Only tested on
Arduino Micro.

Project Name: Quasi-Mouse
Created by Ruicheng Xian on July 31, 2014
For EE 47 Final Project

This Arduino file is for controlling a remote car from an iPhone 5s
via Bluetooth Low Energy (4.0) protocol.

Purchased ICs as follow:
  * Arduino Micro from Arduino
  * nRF8001 Breakout v1.0 from Adafruit
    - Library: http://github.com/adafruit/Adafruit_nRF8001/
  * TB6612FNG Motor Driver from Sparkfun
  * WTV020SD Audio-Sound Breakout from Sparkfun
    - Library: http://forum.arduino.cc/index.php?&topic=117009/
  * MicroSD Card from Transcend
  * 6V Voltage Regulator from Jameco
  ^ Libraries are also included with the files 

Arduino is connected as below:
  * Pin 2 - nRF8001 RDY
  * Pin 4 - TB6612FNG STBY
  * Pin 5 - TB6612FNG AIN1
  * Pin 6 - TB6612FNG PWMA
  * Pin 7 - TB6612FNG AIN2
  * Pin 8 - TB6612FNG BIN1
  * Pin 9 - TB6612FNG BIN2
  * Pin 11 - TB6612FNG PWMB
  * Pin 12 - nRF8001 RESET
  * Pin 13 - nRF8001 REQ
  * Pin A0 - WTV020SD RESET
  * Pin A1 - WTV020SD DCLK
  * Pin A2 - WTV020SD DIN
  * Pin A3 - WTV020SD BUSY
  * Pin A5 - Battery indicator (voltage divider) Vout
  * MISO - nRF8001 MISO
  * MOSI - nRF8001 MOSI
  * SCK - nRF8001 SCK
  * VIN - 9V Battery +
  * GND - 9V Battery -

*/


#include <SPI.h>
#include <Wtv020sd16p.h>
#include "Adafruit_BLE_UART.h"


#define ADAFRUITBLE_REQ 13  // bluetooth pin define
#define ADAFRUITBLE_RDY 2
#define ADAFRUITBLE_RST 12
#define MOTOR_STBY 4  // motor pin define
#define MOTOR_PWMA 6  // motor A, speed control
#define MOTOR_AIN1 5  // motor A, direction 1
#define MOTOR_AIN2 7  // motor A, direction 2
#define MOTOR_PWMB 11  // motor B, speed control
#define MOTOR_BIN1 8  // motor B, direction 1
#define MOTOR_BIN2 9  // motor B, direction 2
#define AUDIO_RST  A0  // audio player pin define
#define AUDIO_DCLK  A1
#define AUDIO_DATA  A2
#define AUDIO_BUSY A3
#define BATT_INDICATOR A5
//#define DEBUG_SERIAL  // debug define


Wtv020sd16p wtv020sd16p(AUDIO_RST, AUDIO_DCLK, AUDIO_DATA, AUDIO_BUSY);
Adafruit_BLE_UART BTLEserial = Adafruit_BLE_UART(ADAFRUITBLE_REQ, ADAFRUITBLE_RDY, ADAFRUITBLE_RST); // bluetooth object instance
aci_evt_opcode_t bluetoothLaststatus = ACI_EVT_DISCONNECTED; // bluetooth status
long lastBattCheck = 0;
int motorASpeed = 255;
int motorBSpeed = 255;

void setup(void) { 
  #ifdef DEBUG_SERIAL
  Serial.begin(9600);
  //while(!Serial);  // Leonardo/Micro should wait for serial init
  #endif
  
  pinMode(MOTOR_STBY, OUTPUT);  // output pins setup
  pinMode(MOTOR_PWMA, OUTPUT);
  pinMode(MOTOR_AIN1, OUTPUT);
  pinMode(MOTOR_AIN2, OUTPUT);
  pinMode(MOTOR_PWMB, OUTPUT);
  pinMode(MOTOR_BIN1, OUTPUT);
  pinMode(MOTOR_BIN2, OUTPUT);
  
  wtv020sd16p.reset();  // audio player initialize
  BTLEserial.begin();  // bluetooth start broadcast
  motorStop();
}

void loop() {  
  bluetoothLoop();  // constantly check bluetooth signal
}
