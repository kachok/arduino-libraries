//
// Double Clock
//
// NTP time through WiFly to initialise PIC32 internal clock
//
// © http://sites.google.com/site/vilorei
// CC = BY NC SA
//
//
// *** WiFly configuration
//
// set uart baud 38400
// set wlan auth 3
// set wlan channel 0
// set wlan ssid "your LAN name"
// set wlan phrase "your LAN key"
// set wlan hide 1
// set ip dhcp 1
// set wlan join 1
// save
// reboot
//
// See
//     User Manual and Command Reference 802.11 b/g Wireless LAN Modules
//     WIFLY GSX
//     RN-131G, RN-131C, RN-134, RN-121, RN-123 & RN-125, RN-370
// from
//     Roving Networks http://www.rovingnetworks.com
//
// *** for Unix -> date time conversion 
//  time.c - low level time and date functions
//  Copyright (c) Michael Margolis 2009
//
//
// *** pic32_RTC
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

#include "pic32_RTC.h"
#include "time.h"

pic32_RTC myRTC;
time_t myTime;


void setup() {
  Serial.begin(19200);
  Serial.print("\n\n\n***\n");

  Serial.print("\n");
  Serial.print("* NTP acquisition");

  Serial1.begin(38400);
  delay(200);

  // exit previous command mode, if any
  Serial1.print("exit\r");
  delay(100);
  Serial1.flush();

  // enter command mode
  Serial1.print("$$$");
  while (!Serial1.available());
  Serial1.flush();

  Serial1.print("show t t\r");
  while (!Serial1.available());

  uint8_t c;
  boolean flagLoop = false;
  boolean flagRTC = false;
  uint8_t offset = 0;
  char buffer[6];
  for (int i=0; i<6; i++) buffer[i]=0;

  while ( (flagLoop==false) && (Serial1.available()) ) {
    c = Serial1.read();
    delay(1);

    switch(c) {
    case '\r':      
    case '\n':      // new line
      if (flagRTC) { 
        flagLoop = true;
      } 
      else {
        offset = 0;
        for (int i=0; i<6; i++) buffer[i]=0;
        flagRTC = false;
      }
      break;

    case '=':       // first term
      if (strcmp(buffer, "RTC")==0) {
        flagRTC = true;
        myTime = 0;
      }
      break;

    default:
      if (flagRTC) {
        myTime *= 10;
        myTime += (c-0x30);
      } 
      else {
        buffer[offset] = c;
        offset++;          
      }
    }
  }

  if (!flagLoop) { 
    Serial.print("\n Error \n");
  } 
  else {
    Serial.print("\n year   \t");
    Serial.print(year(myTime), DEC);
    Serial.print("\n month  \t");
    Serial.print(month(myTime), DEC);
    Serial.print("\n day   \t");
    Serial.print(day(myTime), DEC);

    Serial.print("\n hour   \t");
    Serial.print(hour(myTime), DEC);
    Serial.print("\n minute \t");
    Serial.print(minute(myTime), DEC);
    Serial.print("\n second \t");
    Serial.print(second(myTime), DEC);
    Serial.print("\n");

    myRTC.set(year(myTime), month(myTime), day(myTime), hour(myTime), minute(myTime), second(myTime));

    Serial.print("\n");
    Serial.print("* pic32 RTC");
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
  }

  // flush Serial1 and potential messages
  Serial1.flush();

  // exit command mode  
  Serial1.print("exit\r");
  delay(100);
  Serial1.flush();


}

void loop() {
  myRTC.get();

  Serial.print(myRTC.dayWeek());
  Serial.print("\t");
  Serial.print(myRTC.date());
  Serial.print("\t");
  Serial.print(myRTC.time());

  Serial.print("\n");
  delay(800);
} 






