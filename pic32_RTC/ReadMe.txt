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
//
// Double Clock Example
//
// Uses DS1307 clock to initialise PIC32 internal clock
//