// DS1307 Clock (sensor) 
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


#ifndef I2C_Clock_h
#define I2C_Clock_h

#include "WProgram.h"
// #include <Wire.h>

class I2C_Clock
{
public:
  I2C_Clock(); // constructor
  String WhoAmI();
  void begin();
  void get();
  void set(uint16_t year0, uint16_t month0, uint16_t day0, uint16_t hour0, uint16_t minute0, uint16_t second0);

  uint16_t year();
  uint16_t month();
  uint16_t day();
  uint16_t hour();
  uint16_t minute();
  uint16_t second();

  String dayWeek();
  String date();
  String time();
  String datetime();

private:
  int8_t _address;   // Wire.h asks for int = int8_t
  uint16_t _dayWeekNumber;
  uint16_t _year;
  uint16_t _month;
  uint16_t _day;
  uint16_t _hour;
  uint16_t _minute;
  uint16_t _second;

  uint16_t dec2bcd(uint16_t val);
  uint16_t bcd2dec(uint16_t val);

};

#endif





