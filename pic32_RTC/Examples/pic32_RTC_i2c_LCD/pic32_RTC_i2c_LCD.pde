// pic32_RTC
//
// © http://sites.google.com/site/vilorei
// CC = BY NC SA
// 
// Jun 19, 2011 - Library
//
// based on Paul_L chipKITRTCC library
//
#include "WProgram.h"
#include <Wire.h>
#include "I2C_20x4.h"
#include "pic32_RTC.h"

pic32_RTC myRTC;
I2C_20x4 myLCD;

void setup() {
  Wire.begin();
  myLCD.begin();

//  Serial.begin(19200);
//  Serial.print("\n\n\n***\n");

  myLCD.print(myLCD.WhoAmI());
  delay(500);
  myLCD.backlight(true);

  myRTC.begin();
  myLCD.clear();
  myLCD.print(myRTC.WhoAmI());
  delay(500);
  myLCD.backlight(true);

  myLCD.clear();
//  myRTC.set(11, 10, 19, 18, 52, 30);
}

uint32_t l;

void loop() {

  myRTC.get();


  myLCD.print(myRTC.date());
  myLCD.print("    ");
  myLCD.print(myRTC.time());


//  myLCD.setCursor(3,3);  
//  myLCD.print(millis()-l, DEC);
//  l=millis();
  delay(333);




}


