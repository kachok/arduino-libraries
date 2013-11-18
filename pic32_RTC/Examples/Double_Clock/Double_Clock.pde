//
// Double Clock
//
// Uses DS1307 clock to initialise PIC32 internal clock
//
//
//
// ** DS1307 Clock (sensor) 
//
// © http://sites.google.com/site/vilorei
// CC = BY NC SA
// 
// Jan 16, 2011 version 1 - Library
// Jan 18, 2010 version 2 - Example with set
// Sep 21, 2011 version 3 - chipKIT compatibility - don't forget 4,7 k pull-up resistors
// Nov 21, 2011 version 4 - all functions made private 
//                          to avoid collusion between pic32_RTC and I2C_Clock 
//
//
// ** pic32_RTC
//
// © http://sites.google.com/site/vilorei
// CC = BY NC SA
// 
// Jun 19, 2011 version 1 - initial release
// Nov 21, 2011 version 2 - all functions made private 
//                          to avoid collusion between pic32_RTC and I2C_Clock 
//
// based on Paul_L chipKITRTCC library
//
// Additional 32.768 kHz crystal required.
//
// See 
// 	Section 6: Oscillators 
// 	Section 29: Real-Time Clock and Calendar (RTCC)
// from 
// 	PIC32 Family Reference Manual on Microchip website
//

#include <Wire.h>
#include "I2C_Clock.h"
#include "pic32_RTC.h"

I2C_Clock myClock;
pic32_RTC myRTC;
//uint16_t y, mt, d, h, mn, s


void setup() {
  Wire.begin();

  Serial.begin(19200);
  Serial.print("\n\n\n\n***\n");
  
//  myClock.get();
//  myClock.set(myClock.year(), myClock.month(), myClock.day(), myClock.hour() -1, myClock.minute() +10, myClock.second());
//  myClock.set(myClock.year(), myClock.month(), myClock.day(), 17, 0, myClock.second());

  Serial.print(myClock.WhoAmI());
  Serial.print("\n");
  myClock.get();
  Serial.print(myClock.dayWeek());
  Serial.print("\t");
  Serial.print(myClock.date());
  Serial.print("\t");
  Serial.print(myClock.time());
  Serial.print("\n");

  Serial.print("\n");
  Serial.print(myRTC.WhoAmI());
  Serial.print("\n");
  myRTC.get();
  Serial.print(myRTC.dayWeek());
  Serial.print("\t");
  Serial.print(myRTC.date());
  Serial.print("\t");
  Serial.print(myRTC.time());
  Serial.print("\n");

  myClock.get();
  myRTC.set(myClock.year(), myClock.month(), myClock.day(), myClock.hour(), myClock.minute(), myClock.second());

  Serial.print(myRTC.WhoAmI());
  Serial.print("\n");
  myRTC.get();
  Serial.print(myRTC.dayWeek());
  Serial.print("\t");
  Serial.print(myRTC.date());
  Serial.print("\t");
  Serial.print(myRTC.time());
  Serial.print("\n");

  Serial.print(myClock.WhoAmI());
  Serial.print("\t");
  Serial.print(myRTC.WhoAmI());
  Serial.print("\n");


}

void loop() {
  myClock.get();
  myRTC.get();

  Serial.print(myClock.dayWeek());
  Serial.print("\t");
  Serial.print(myClock.date());
  Serial.print("\t");
  Serial.print(myClock.time());

  Serial.print("\t");

  Serial.print(myRTC.dayWeek());
  Serial.print("\t");
  Serial.print(myRTC.date());
  Serial.print("\t");
  Serial.print(myRTC.time());

  Serial.print("\n");

} 




