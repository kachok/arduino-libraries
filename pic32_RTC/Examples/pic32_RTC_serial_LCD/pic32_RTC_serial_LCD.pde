// pic32_RTC
//
// © http://sites.google.com/site/vilorei
// CC = BY NC SA
// 
// Jun 19, 2011 - Library
//
// based on Paul_L chipKITRTCC library
//

#include <pic32_RTC.h>

pic32_RTC myRTC;

void setup() {
  Serial1.begin(9600);
  Serial1.print(0x0C, BYTE); // clear
  delay(10);

  Serial.begin(19200);
  Serial.print("\n\n\n***\n");

  myRTC.begin();
Serial1.print(0);
Serial1.print(myRTC.WhoAmI());
  delay(500);
    Serial1.print(0x0C, BYTE); // clear
  delay(10);
  Serial1.print(0x01, BYTE); // home
  delay(10);
  Serial1.print(0x04, BYTE); // no cursor
  delay(10);
  Serial1.print(0x13, BYTE); // backlight on
  delay(10);


  myRTC.set(11, 10, 19, 18, 45, 30);
}

uint32_t l;

void loop() {

  myRTC.get();

  Serial1.print(0x01, BYTE); // home
  delay(10);
  Serial1.print(myRTC.date());
  delay(10);
  Serial1.print("\r");
  Serial1.print(myRTC.time());
  delay(10);
  Serial1.print("\r");
  Serial1.print("\r");


  Serial1.print(millis()-l, DEC);
  Serial1.print("  ");
  l=millis();
  delay(333);




}


