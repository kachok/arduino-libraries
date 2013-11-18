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



#include "WProgram.h"
#include <Wire.h>
#include "I2C_Clock.h"


I2C_Clock::I2C_Clock() {
  _year = 0;
  _month = 0;
  _day = 0;
  _hour = 0;
  _minute = 0;
  _second = 0;

  _dayWeekNumber=0;
  _address = 0x68; // Possible address conflict (if ITG3200 not shown as 0x72)

} 


String I2C_Clock::WhoAmI() {
  String s="";
  if (_address < 0x10) s="0";
  s = s + String(_address, 0x10) +"h ";
  s = s + "DS1307 Real Time Clock (sensor)";
  return s ;
}


void I2C_Clock::begin() {
}


void I2C_Clock::get()
{
  Wire.beginTransmission(_address); // transmit to device
  Wire.send((uint16_t)0x00); // command  
  Wire.endTransmission(); // stop transmitting 

  Wire.requestFrom(_address, 7); // request 7 bytes from device 

  // A few of these need masks because certain bits are control bits
  _second = bcd2dec(Wire.receive() & 0x7f);
  _minute = bcd2dec(Wire.receive());
  _hour = bcd2dec(Wire.receive() & 0x3f); // 24 hours format

  _dayWeekNumber = bcd2dec(Wire.receive()); // 0 = Sunday
  _day = bcd2dec(Wire.receive());
  _month = bcd2dec(Wire.receive());
  _year = 2000 + bcd2dec(Wire.receive());
}

String I2C_Clock::time() {
  String _time = "";
  if (_hour<10) _time = _time + "0";
  _time = _time + String(_hour, 10) + ":";
  if (_minute<10) _time = _time + "0";
  _time = _time + String(_minute, 10) + ":";
  if (_second<10) _time = _time + "0";
  _time = _time + String(_second, 10);
  return _time;
}

String I2C_Clock::dayWeek() {
  // array is 0-6, but the dow register holds 1-7, so subtract 1.
  // 0 = Sunday
  String days[7] = {
    "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"  };
  return days[_dayWeekNumber - 1];    
}

String I2C_Clock::date() {
  String _date = "";
  if (_day<10) _date = _date + "0";
  _date = _date + String(_day, 10) + "/";
  if (_month<10) _date = _date + "0";
  _date = _date + String(_month, 10) + "/";
  _date = _date + String(_year, 10);
  return _date;
}

String I2C_Clock::datetime() {

  // Convenient mmddhhmm 8 characters string for file name 
  String _datetime = "";
  if (_month<10) _datetime = _datetime + "0";
  _datetime = _datetime + String(_month, 10);
  if (_day<10) _datetime = _datetime + "0";
  _datetime = _datetime + String(_day, 10);
  if (_hour<10) _datetime = _datetime + "0";
  _datetime = _datetime + String(_hour, 10);
  if (_minute<10) _datetime = _datetime + "0";
  _datetime = _datetime + String(_minute, 10);
  return _datetime;
}

uint16_t I2C_Clock::year() {
  return _year;
}

uint16_t I2C_Clock::month() {
  return bcd2dec(_month);
}

uint16_t I2C_Clock::day() {
  return _day;
}

uint16_t I2C_Clock::hour() {
  return _hour;
}

uint16_t I2C_Clock::minute() {
  return _minute;
}

uint16_t I2C_Clock::second() {
  _second;
}


void I2C_Clock::set(uint16_t year0, uint16_t month0, uint16_t day0, uint16_t hour0, uint16_t minute0, uint16_t second0)
{

  if (year0 < 100)  {
    year0 +=2000;
  }
  // Day of week calculation  
  // code by Tomohiko Sakamoto       0 = Sunday 
  // comp.lang.c on March 10th, 1993
  uint16_t y;
  uint16_t m;
  uint16_t d;
  uint16_t dow; // day of week
  static uint16_t t[] = {
    0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4            };

  y = year0;
  m = month0;
  d = day0;

  y -= m < 3;
  dow = (y + y/4 - y/100 + y/400 + t[m-1] + d) % 7;

  // The DS1306 requires 1 = Sunday
  dow = dow+1;   // Sunday=1

    _dayWeekNumber=dow;

  second0 |= 0x80;  // stop the clock
  Wire.beginTransmission(_address);
  Wire.send((uint16_t)0x00);
  Wire.send(dec2bcd(second0));  // 0 to bit 7 starts the clock
  Wire.send(dec2bcd(minute0));
  Wire.send(dec2bcd(hour0));    // If you want 12 hour am/pm you need to set
  // bit 6 (also need to change readDateDs1307)
  Wire.send(dec2bcd(dow));
  Wire.send(dec2bcd(day0));
  Wire.send(dec2bcd(month0));
  Wire.send(dec2bcd(year0-2000));   // 11 and not 2011
  Wire.endTransmission();

  second0 &= 0x7f;  // start the clock
  Wire.beginTransmission(_address);
  Wire.send(0x00);
  Wire.send(dec2bcd(second0));  // 0 to bit 7 starts the clock
  Wire.send(dec2bcd(minute0));
  Wire.send(dec2bcd(hour0));    // If you want 12 hour am/pm you need to set
  // bit 6 (also need to change readDateDs1307)
  Wire.send(dec2bcd(dow));
  Wire.send(dec2bcd(day0));
  Wire.send(dec2bcd(month0));
  Wire.send(dec2bcd(year0-2000));   // 11 and not 2011
  Wire.endTransmission();

  get();
}



// Convert normal decimal numbers to binary coded decimal
uint16_t I2C_Clock::dec2bcd(uint16_t val)
{
  return ( (val/10*16) + (val%10) );
}

// Convert binary coded decimal to normal decimal numbers
uint16_t I2C_Clock::bcd2dec(uint16_t val)
{
  return ( (val/16*10) + (val%16) );
}

