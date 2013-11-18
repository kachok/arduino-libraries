//
// pic32_RTC
//
// © http://sites.google.com/site/vilorei
// CC = BY NC SA
// 
// Jun 19, 2011 version 1 - initial release
// Nov 21, 2011 version 2 - all functions made private 
//                          to avoid collusion between pic32_RTC and I2C_Clock 
// Dec 24, 2011 version 3 - fix added by majenko to support mpide build 20111215
// Jan 15, 2012 version 4 - dayWeek fixed
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

#ifndef __PIC32MX__
#error pic32_RTC requires PIC32 chip
#else

#ifndef pic32_RTC_h
#define pic32_RTC_h

#include "WProgram.h"

class pic32_RTC
{
public:
  pic32_RTC(); // constructor
  String WhoAmI();
  void begin();
  void get();
  void set(uint16_t year0, uint16_t month0, uint16_t day0, uint16_t hour0, uint16_t minute0, uint16_t second0);
  void reset();

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
  uint16_t _dayWeekNumber;
  uint16_t _year;
  uint16_t _month;
  uint16_t _day;
  uint16_t _hour;
  uint16_t _minute;
  uint16_t _second;

  void writeEnable();
  void writeDisable();
  uint16_t dec2bcd(uint16_t val);
  uint16_t bcd2dec(uint16_t val);
};

#endif // #ifndef pic32_RTC_h


#endif // #if defined(__PIC32MX__)




