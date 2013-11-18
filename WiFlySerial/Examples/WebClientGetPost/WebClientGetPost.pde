/*
 * HTTP Client examples for the WiFly.
 *
 * Provides http client examples for GET and POST.
 *
 * GET /userprog_get.php?DATA=abc
 * POST /userprog_post.php
 *
 *
 * Download Mikal Hart's NewSoftSerial, Streaming and PString libraries from http://arduiniana.org
 *
 * Remember to set:
 * MY_WIFI_SSID
 * MY_WIFI_PASSPHRASE to your local wifi values.
 * MY_SERVER_GET
 * MY_SERVER_GET_URL
 * MY_SERVER_POST
 * MY_SERVER_POST_URL to your local server values.
 * ...server-side php scripts are required for this example.
 *    userprog_get.php and userprog_post.php are included and
 *    are in the download package.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 
 Copyright GPL 2.1 Tom Waldock 2011
 */
#include <WProgram.h>
#include <Time.h>
#include <NewSoftSerial.h>
#include <Streaming.h>
#include <PString.h>
#include "WiFlySerial.h"
#include "MemoryFree.h"

// initialize WiFly
// loop
// send a parameterized GET to a web server
//    - show connection and response
// send a parameterized POST to a web server
//    - show connection and response
// 

// Set these to your local values
#define MY_WIFI_SSID "mySSID"
#define MY_WIFI_PASSPHRASE "MySecretPassphrase"
#define MY_NTP_SERVER "nist1-la.ustiming.org"

// Connect the WiFly TX pin to the Arduino RX pin  (Transmit from WiFly-> Receive into Arduino)
// Connect the WiFly RX pin to the Arduino TX pin  (Transmit from Arduino-> Receive into WiFly)
// 
// Connect the WiFly GND pin to an Arduino GND pin
// Finally, connect the WiFly BATT pin to the 3.3V pin (NOT the 5v pin)

#define ARDUINO_RX_PIN  2
#define ARDUINO_TX_PIN  3

// server hosting GET example php script
#define MY_SERVER_GET "localhost"
#define MY_SERVER_GET_URL "/cgi-bin/userprog_get.php"


// server hosting POST example php script
#define MY_SERVER_POST MY_SERVER_GET
#define MY_SERVER_POST_URL "/cgi-bin/userprog_post.php"

// prog_char s_WT_SETUP_00[] PROGMEM = "nist1-la.ustiming.org";  /* change to your favorite NTP server */
prog_char s_WT_SETUP_01[] PROGMEM = "set u m 0x1";
prog_char s_WT_SETUP_02[] PROGMEM = "set comm remote 0";
prog_char s_WT_SETUP_03[] PROGMEM = "set comm idle 30";
prog_char s_WT_SETUP_04[] PROGMEM = "set comm time 2000";
prog_char s_WT_SETUP_05[] PROGMEM = "set comm size 64";
prog_char s_WT_SETUP_06[] PROGMEM = "set comm match 0x9";
prog_char s_WT_SETUP_07[] PROGMEM = "time";
prog_char s_WT_STATUS_SENSORS[] PROGMEM = "show q 0x177 ";
prog_char s_WT_STATUS_TEMP[] PROGMEM = "show q t ";
prog_char s_WT_STATUS_RSSI[] PROGMEM = "show rssi ";
prog_char s_WT_STATUS_BATT[] PROGMEM = "show battery ";
prog_char s_WT_MSG_JOIN[] PROGMEM = "Credentials Set, Joining ";
prog_char s_WT_MSG_START_WEBCLIENT[] PROGMEM = "Starting WebClientGetPut - Please wait. ";
prog_char s_WT_MSG_RAM[] PROGMEM = "RAM :";
prog_char s_WT_MSG_START_WIFLY[] PROGMEM = "Started WiFly, RAM :";
prog_char s_WT_MSG_WIFI[] PROGMEM = "Initial WiFi Settings :";
prog_char s_WT_MSG_APP_SETTINGS[] PROGMEM = "Configure WebClientGetPut Settings...";
prog_char s_WT_MSG_WIRE_RX[] PROGMEM = "Arduino Rx Pin (connect to WiFly Tx):";
prog_char s_WT_MSG_WIRE_TX[] PROGMEM = "Arduino Tx Pin (connect to WiFly Rx):";
prog_char s_WT_MSG_FAIL_OPEN[] PROGMEM = "Failed on opening connection to:";
prog_char s_WT_HTML_HEAD_01[] PROGMEM = "HTTP/1.1 200 OK \r ";
prog_char s_WT_HTML_HEAD_02[] PROGMEM = "Content-Type: text/html;charset=UTF-8\r ";
prog_char s_WT_HTML_HEAD_03[] PROGMEM = " Content-Length: ";
prog_char s_WT_HTML_HEAD_04[] PROGMEM = "Connection: close \r\n\r\n";
prog_char s_WT_POST_HEAD_01[] PROGMEM = "HTTP/1.1\n";
prog_char s_WT_POST_HEAD_02[] PROGMEM = "Content-Type: application/x-www-form-urlencoded\n";
prog_char s_WT_POST_HEAD_03[] PROGMEM = "Content-Length: ";
prog_char s_WT_POST_HEAD_04[] PROGMEM = "Connection: close\n\n";


#define IDX_WT_SETUP_00 0
#define IDX_WT_SETUP_01 IDX_WT_SETUP_00 
#define IDX_WT_SETUP_02 IDX_WT_SETUP_01 +1
#define IDX_WT_SETUP_03 IDX_WT_SETUP_02 +1
#define IDX_WT_SETUP_04 IDX_WT_SETUP_03 +1
#define IDX_WT_SETUP_05 IDX_WT_SETUP_04 +1
#define IDX_WT_SETUP_06 IDX_WT_SETUP_05 +1
#define IDX_WT_SETUP_07 IDX_WT_SETUP_06 +1

#define IDX_WT_STATUS_SENSORS    IDX_WT_SETUP_07 +1
#define IDX_WT_STATUS_TEMP       IDX_WT_STATUS_SENSORS +1
#define IDX_WT_STATUS_RSSI       IDX_WT_STATUS_TEMP +1
#define IDX_WT_STATUS_BATT       IDX_WT_STATUS_RSSI +1

#define IDX_WT_MSG_JOIN          IDX_WT_STATUS_BATT +1
#define IDX_WT_MSG_START_WEBCLIENT IDX_WT_MSG_JOIN +1
#define IDX_WT_MSG_RAM           IDX_WT_MSG_START_WEBCLIENT +1
#define IDX_WT_MSG_START_WIFLY   IDX_WT_MSG_RAM +1
#define IDX_WT_MSG_WIFI          IDX_WT_MSG_START_WIFLY +1
#define IDX_WT_MSG_APP_SETTINGS  IDX_WT_MSG_WIFI +1
#define IDX_WT_MSG_WIRE_RX       IDX_WT_MSG_APP_SETTINGS +1
#define IDX_WT_MSG_WIRE_TX       IDX_WT_MSG_WIRE_RX +1
#define IDX_WT_MSG_FAIL_OPEN     IDX_WT_MSG_WIRE_TX +1

#define IDX_WT_HTML_HEAD_01      IDX_WT_MSG_FAIL_OPEN + 1
#define IDX_WT_HTML_HEAD_02      IDX_WT_HTML_HEAD_01 + 1
#define IDX_WT_HTML_HEAD_03      IDX_WT_HTML_HEAD_02 + 1
#define IDX_WT_HTML_HEAD_04      IDX_WT_HTML_HEAD_03 + 1

#define IDX_WT_POST_HEAD_01      IDX_WT_HTML_HEAD_04 + 1
#define IDX_WT_POST_HEAD_02      IDX_WT_POST_HEAD_01 + 1
#define IDX_WT_POST_HEAD_03      IDX_WT_POST_HEAD_02 + 1
#define IDX_WT_POST_HEAD_04      IDX_WT_POST_HEAD_03 + 1


PROGMEM const char *WT_string_table[] = 	   
{   
//  s_WT_SETUP_00,
  s_WT_SETUP_01,
  s_WT_SETUP_02,
  s_WT_SETUP_03,
  s_WT_SETUP_04,
  s_WT_SETUP_05,
  s_WT_SETUP_06,
  s_WT_SETUP_07,
  s_WT_STATUS_SENSORS,
  s_WT_STATUS_TEMP,
  s_WT_STATUS_RSSI,
  s_WT_STATUS_BATT,
  s_WT_MSG_JOIN,
  s_WT_MSG_START_WEBCLIENT,
  s_WT_MSG_RAM,
  s_WT_MSG_START_WIFLY,
  s_WT_MSG_WIFI,
  s_WT_MSG_APP_SETTINGS,
  s_WT_MSG_WIRE_RX,
  s_WT_MSG_WIRE_TX,
  s_WT_MSG_FAIL_OPEN,
  s_WT_HTML_HEAD_01,
  s_WT_HTML_HEAD_02,
  s_WT_HTML_HEAD_03,
  s_WT_HTML_HEAD_04,
  s_WT_POST_HEAD_01,
  s_WT_POST_HEAD_02,
  s_WT_POST_HEAD_03,
  s_WT_POST_HEAD_04
};

// various buffer sizes
#define REQUEST_BUFFER_SIZE 180
#define POST_BUFFER_SIZE 180
#define TEMP_BUFFER_SIZE 60

char chMisc;
int iRequest = 0;
int iTrack = 0;
int iLoopCounter = 0;

WiFlySerial WiFly(ARDUINO_RX_PIN ,ARDUINO_TX_PIN);


// Function for setSyncProvider
time_t GetSyncTime() {
  time_t tCurrent = (time_t) WiFly.GetTime();
  WiFly.exitCommandMode();
  return tCurrent;
}

// GetBuffer_P
// Returns pointer to a supplied Buffer, from PROGMEM based on StringIndex provided.
// based on example from http://arduino.cc/en/Reference/PROGMEM

char* GetBuffer_P(const int StringIndex, char* pBuffer, int bufSize) { 
  strncpy_P(pBuffer, (char*)pgm_read_word(&(WT_string_table[StringIndex])), bufSize);  
  return pBuffer; 
}

// Reconnects to a wifi network.
// DHCP is enabled explicitly.
// You may need to add the MAC address to your MAC filter list.
// Static IP settings available if needed.
boolean Reconnect() {
char bufRequest[REQUEST_BUFFER_SIZE];
char bufTemp[TEMP_BUFFER_SIZE];

  WiFly.SendCommand(GetBuffer_P(IDX_WT_SETUP_01,bufTemp,TEMP_BUFFER_SIZE), ">",bufRequest, REQUEST_BUFFER_SIZE);
  WiFly.setUseDHCP(true);
  WiFly.SendCommand(GetBuffer_P(IDX_WT_SETUP_02,bufTemp,TEMP_BUFFER_SIZE),">",bufRequest, REQUEST_BUFFER_SIZE);
  Serial << "Leave current wifi network:" << WiFly.leave() << endl;
  // join
  WiFly.setPassphrase(MY_WIFI_PASSPHRASE);    
  Serial << GetBuffer_P(IDX_WT_MSG_JOIN,bufTemp,TEMP_BUFFER_SIZE) << MY_WIFI_SSID << endl;
  WiFly.join(MY_WIFI_SSID);

  // Set NTP server, update frequency, 
  WiFly.setNTP(MY_NTP_SERVER); 
  WiFly.setNTP_Update_Frequency(" 15");
  // don't send *HELLO* on http traffic
  // close idle connections after n seconds
  // give enough time for packet data to arrive
  // make data packet size sufficiently large
  // send data packet when a \t appears in stream
  //  force time resync.

  // Configure application-specific settings

  Serial << GetBuffer_P(IDX_WT_MSG_APP_SETTINGS, bufTemp, TEMP_BUFFER_SIZE) << endl;
  for (int i = 1; i< 7 ; i++) {
    WiFly.SendCommand(GetBuffer_P(IDX_WT_SETUP_00 + i,bufTemp,TEMP_BUFFER_SIZE),">",bufRequest, REQUEST_BUFFER_SIZE);
  }

  setTime( WiFly.GetTime() );
  delay(1000);
  setSyncProvider( GetSyncTime );

  // reboot if not working right yet.
  iTrack++;
  if ( iTrack > 5 ) {
    WiFly.reboot();
    iTrack = 0;
  }

}


// Arduino Setup routine.

void setup() {
  Serial.begin(9600);
  char bufRequest[REQUEST_BUFFER_SIZE];
  char bufTemp[TEMP_BUFFER_SIZE];

  Serial << GetBuffer_P(IDX_WT_MSG_START_WEBCLIENT,bufTemp,TEMP_BUFFER_SIZE) << endl << GetBuffer_P(IDX_WT_MSG_RAM,bufTemp,TEMP_BUFFER_SIZE) << freeMemory() << endl
    << GetBuffer_P(IDX_WT_MSG_WIRE_RX,bufTemp,TEMP_BUFFER_SIZE) << ARDUINO_RX_PIN << endl << GetBuffer_P(IDX_WT_MSG_WIRE_TX,bufTemp,TEMP_BUFFER_SIZE) << ARDUINO_TX_PIN << endl;

  WiFly.begin();
  Serial << GetBuffer_P(IDX_WT_MSG_START_WIFLY,bufTemp,TEMP_BUFFER_SIZE) <<  freeMemory() << endl;

  // get MAC
  Serial << "MAC: " << WiFly.GetMAC(bufRequest, REQUEST_BUFFER_SIZE) << endl;

  Reconnect();
  Serial << "DateTime:" << year() << "-" << month() << "-" << day() << " " << hour() << ":" << minute() << ":" << second() << endl;

  Serial << GetBuffer_P(IDX_WT_MSG_WIFI,bufTemp,TEMP_BUFFER_SIZE) << endl  
    << "IP: " << WiFly.GetIP(bufRequest, REQUEST_BUFFER_SIZE) << endl
    << "Netmask: " << WiFly.GetNetMask(bufRequest, REQUEST_BUFFER_SIZE) << endl
    << "Gateway: " << WiFly.GetGateway(bufRequest, REQUEST_BUFFER_SIZE) << endl
    << "DNS: " << WiFly.GetDNS(bufRequest, REQUEST_BUFFER_SIZE) << endl;

  memset (bufRequest,'\0',REQUEST_BUFFER_SIZE);

  Serial << "RSSI: " << WiFly.GetRSSI(bufRequest, REQUEST_BUFFER_SIZE) << endl
   << "battery: " <<  WiFly.GetBattery(bufRequest, REQUEST_BUFFER_SIZE) << endl;

  // close any open connections
  WiFly.closeConnection();
  Serial << "After Setup RAM:" << freeMemory() << endl ;
  

}


void loop() {

  Serial << "Beginning of Loop RAM:" << freeMemory() << endl ;
  
  // Perform GET example
  float fSampleValue = iLoopCounter + (iLoopCounter / 10 );

  Do_GET_Example(   iLoopCounter, fSampleValue );
  

  Do_POST_Example ( iLoopCounter, fSampleValue );


  Do_POST_Switch ( iLoopCounter, fSampleValue );
  
  // Serial << "Clear leftovers" << endl;
  // flush the WiFly buffer by reading and showing anything left around.
  while ((chMisc = WiFly.uart.read()) > -1) {
    Serial << chMisc;
  }
  iLoopCounter++;
  
  // wait a bit
  delay(4000);
}


int Do_GET_Example(  int iLoopCounter, float fValue ) {
// Do_GET_Example
// 
// Performs a parameterized GET to communicate data to a server.
// Parameters: 
// iLoopCounter    A sample value.
// fValue          A sample float value
//
// Feed model: http://www.myserver.example/get_example.php?LOOPCOUNTER=1&value=3.21
//  
//                    ...etc

  char bufRequest[REQUEST_BUFFER_SIZE];
  char bufTemp[TEMP_BUFFER_SIZE];
  
  PString strRequest(bufRequest, REQUEST_BUFFER_SIZE);
  
  // Build GET expression
  
  strRequest << "GET " << MY_SERVER_GET_URL << "?counter=" << iLoopCounter << "&value=" << fValue 
     << " HTTP/1.1" << "\n"
     << "Host: " << MY_SERVER_GET << "\n"
     << "Connection: close" << "\n"
     << "\n\n";
  // send data via request
  // close connection
  WiFly.setDebugChannel( (Print*) &Serial );
  
  Serial << "GET request:"  << strRequest <<  endl << "RAM: " << freeMemory() << endl;

  // Open connection, then sent GET Request, and display response.
  if (WiFly.openConnection( MY_SERVER_GET ) ) {
    
    WiFly.uart <<  (const char*) strRequest << endl; 
    
    // Show server response
    unsigned long TimeOut = millis() + 8000;

    while ( millis()  < TimeOut) {
      if (  WiFly.uart.available() > 0 ) {
        Serial.print( WiFly.uart.read(), BYTE);
      }
    }
    
    // Force-close connection
    WiFly.closeConnection();
 
  } else {
    // Failed to open connection
    Serial << GetBuffer_P(IDX_WT_MSG_FAIL_OPEN,bufTemp,TEMP_BUFFER_SIZE) << MY_SERVER_GET << endl;
  }
  
  WiFly.setDebugChannel( NULL );
  return 0;
}


int Do_POST_Example(  int iLoopCounter, float fValue ) {
// Do_POST_Example
// 
// Performs a parameterized POST to communicate data to a server.
// Parameters: 
// iLoopCounter    A sample value.
// fValue          A sample float value
//
// Feed model: http://www.myserver.example/get_example.php?LOOPCOUNTER=1&value=3.21
//  
//                    ...etc
  Serial << "POST Example RAM: " << freeMemory() << endl;

  char bufRequest[REQUEST_BUFFER_SIZE];
  char bufTemp[TEMP_BUFFER_SIZE];
  char bufPayLoad[TEMP_BUFFER_SIZE];
  
  memset (bufPayLoad,'\0', TEMP_BUFFER_SIZE);
  
  PString strRequest(bufRequest, REQUEST_BUFFER_SIZE);
  PString strPayLoad(bufPayLoad, TEMP_BUFFER_SIZE);
  
  // Build POST expression
  
  strPayLoad << "counter=" << iLoopCounter << "&value=" << fValue;
   
//  strRequest << "POST /cgi-bin/userprog_post.php HTTP/1.1\n"
//    << "Host: 192.168.1.11\n"
//    << "Content-Type: application/x-www-form-urlencoded\n"
//    << "Content-Length: " << strPayLoad.length() << "\n"
//    << "Connection: close\n\n"
//    << strPayLoad << "\n\n";
  strRequest << "POST " << MY_SERVER_POST_URL << " " << GetBuffer_P(IDX_WT_POST_HEAD_01,bufTemp,TEMP_BUFFER_SIZE)
     << "Host: " << MY_SERVER_POST << "\n"
     << GetBuffer_P(IDX_WT_POST_HEAD_02,bufTemp,TEMP_BUFFER_SIZE)
     << GetBuffer_P(IDX_WT_POST_HEAD_03,bufTemp,TEMP_BUFFER_SIZE) << strPayLoad.length() << "\n"
     << GetBuffer_P(IDX_WT_POST_HEAD_04,bufTemp,TEMP_BUFFER_SIZE) 
     << strPayLoad << "\n\n" ;
  // send data via request
  // close connection
  WiFly.setDebugChannel( (Print*) &Serial );
  
  Serial << "POST Request:"  << endl << strRequest << endl << "RAM:" << freeMemory() << endl;

  // Open connection, then sent GET Request, and display response.
  if (WiFly.openConnection( MY_SERVER_POST ) ) {
    
    WiFly.uart <<  (const char*) strRequest ; 
    
    // Show server response
    unsigned long TimeOut = millis() + 8000;

    while ( millis()  < TimeOut) {
      if (  WiFly.uart.available() > 0 ) {
        Serial.print( WiFly.uart.read(), BYTE);
      }
    }
    
    // Force-close connection
    WiFly.closeConnection();
 
  } else {
    // Failed to open
    Serial << GetBuffer_P(IDX_WT_MSG_FAIL_OPEN,bufTemp,TEMP_BUFFER_SIZE) << MY_SERVER_POST << endl;
  }
  
  WiFly.setDebugChannel( NULL );
  return 0;
}


// Utility function to get a value from a given web page.
// Caller supplies key buffers - limited free space.
//
// returns 0 for off, 1 for on, and 100 for errors.

int GetSwitchReqState( PString& hRequest, char* pTempBuf, int iBufLen) {
  
  int iSwitchState = 100;
  
     hRequest << "GET " << MY_SERVER_SWITCH_URL << " HTTP/1.1\n"
     << "Host: " << MY_SERVER_SWITCH << "\n"
     << "Connection: close\n"
     << "\n\n";
  // send data via request
  // close connection
  WiFly.setDebugChannel( (Print*) &Serial );
  
  Serial << "GetSwitchState request:"  << hRequest <<  endl << "RAM: " << freeMemory() << endl;

  // Open connection, then sent GET Request, and display response.
  if (WiFly.openConnection( MY_SERVER_SWITCH ) ) {
    
    WiFly.uart <<  (const char*) hRequest << endl; 
    
//    // Scan for keywords
//    WiFly.ScanForPattern(  pTempBuf, iBufLen, "req_state=", false, DEFAULT_WAIT_TIME, false);
//        
//    WiFly.ScanForPattern(  pTempBuf, iBufLen, ", ", true, DEFAULT_WAIT_TIME, false);

    // Show server response
    unsigned long TimeOut = millis() + 8000;

    while ( millis()  < TimeOut) {
      if (  WiFly.uart.available() > 0 ) {
        Serial.print( WiFly.uart.read(), BYTE);
      }
    }

    strcpy(pTempBuf,"on");
    
    if ( strcmp(pTempBuf,"on") == 0  ) {
       iSwitchState = 1;
    }
    if ( strcmp(pTempBuf,"off") == 0 ) {
       iSwitchState = 0;
    }
            
//    unsigned long TimeOut = millis() + 8000;
//
//    while ( millis()  < TimeOut) {
//      if (  WiFly.uart.available() > 0 ) {
//        Serial.print( WiFly.uart.read(), BYTE);
//      }
//    }
    
    // Force-close connection
    WiFly.closeConnection();
 
  } else {
    // Failed to open connection
    Serial << GetBuffer_P(IDX_WT_MSG_FAIL_OPEN,pTempBuf,iBufLen) << MY_SERVER_SWITCH << endl;
  }
  return iSwitchState;
}  

int Do_POST_Switch(  int iLoopCounter, float fValue ) {
// Do_POST_Switch
// 
// Checks a web server and retreives a value from a page, 
//  then turns on or off a switch, and reports the action.
//
// Parameters: 
// iLoopCounter    A sample value.
// fValue          A sample float value.
//
// Feed model: http://www.myserver.example/get_example.php?LOOPCOUNTER=1&value=3.21
//  
//                    ...etc
  Serial << "POST Switch RAM: " << freeMemory() << endl;

  char bufRequest[REQUEST_BUFFER_SIZE];
  char bufTemp[TEMP_BUFFER_SIZE];
  char bufPayLoad[TEMP_BUFFER_SIZE];
  int iSwitchReqState = 100;
  
  memset (bufTemp,'\0', TEMP_BUFFER_SIZE);
  
  PString strRequest(bufRequest, REQUEST_BUFFER_SIZE);
  
  // Get the current requested state: Grab a web page and inspect it.
 
  iSwitchReqState = GetSwitchReqState( strRequest, bufTemp ,TEMP_BUFFER_SIZE);
  
  strRequest.begin();
  // Based on requested state, Build POST expression
  PString strPayLoad(bufPayLoad, TEMP_BUFFER_SIZE); 
  
  strPayLoad << "action=report&rep_state=off&rep_action=" ;
  switch (iSwitchReqState) {
    // Turn off switch
    case 0: 
      strPayLoad << "off";
      break;
      
    // Turn on switch  
    case 1: 
      strPayLoad << "on";
      break;
      
    // no clue  
    default:   
      strPayLoad << "eh?";
      break;
  }
 
 
  strRequest << "POST " << MY_SERVER_SWITCH_URL << " " << GetBuffer_P(IDX_WT_POST_HEAD_01,bufTemp,TEMP_BUFFER_SIZE) 
     << "Host: " << MY_SERVER_SWITCH << "\n"
     << GetBuffer_P(IDX_WT_POST_HEAD_02,bufTemp,TEMP_BUFFER_SIZE) 
     << GetBuffer_P(IDX_WT_POST_HEAD_03,bufTemp,TEMP_BUFFER_SIZE) << strPayLoad.length() << "\n"
     << GetBuffer_P(IDX_WT_POST_HEAD_04,bufTemp,TEMP_BUFFER_SIZE);
  // send data via request
  // close connection
  WiFly.setDebugChannel( (Print*) &Serial );
  
  Serial << "POST Request:"  << endl<< strRequest <<  strPayLoad << endl << strRequest.length() << "RAM:" << freeMemory() << endl;

  // Open connection, then sent GET Request, and display response.
  if (WiFly.openConnection( MY_SERVER_SWITCH ) ) {
    
    WiFly.uart <<  (const char*) strRequest <<  (const char*) strPayLoad << "\n\n" ;

    
    // Show server response
    unsigned long TimeOut = millis() + 8000;

    while ( millis()  < TimeOut) {
      if (  WiFly.uart.available() > 0 ) {
        Serial.print( WiFly.uart.read(), BYTE);
      }
    }
    
    // Force-close connection
    WiFly.closeConnection();
    
    
 
  } else {
    // Failed to open
    Serial << GetBuffer_P(IDX_WT_MSG_FAIL_OPEN,bufTemp,TEMP_BUFFER_SIZE) << MY_SERVER_SWITCH << endl;
  }
  
  WiFly.setDebugChannel( NULL );
  return 0;
}


//int Do_PUT_Example(  int iLoopCounter, float fValue ) {
// Do_PUT_Example
// 
// Performs a HTTP PUT to communicate data to a server.
// Parameters: 
// iLoopCounter    A sample integer value.
// fValue          A sample floating-point value
//
// Feed model:
//                << " PUT /v2/feeds/19824.csv HTTP/1.1\r\n"
//                   "Host: www.myputserver.example\r\n"
//                   "Content-Length: 20\r\n"
//                   "Connection: close\r\n\r\n";
//                  
//                    0,<reading1>\r\n
//                    1,<reading2>\r\n
//
//                    ...etc

//
//  char bufMessage[POST_BUFFER_SIZE];
//  char bufContent[TEMP_BUFFER_SIZE];
//  char bufTmp[TEMP_BUFFER_SIZE];
//  
//  // set connection to pachube
//  // send data
//  // close connection
//  WiFly.setDebugChannel( (Print*) &Serial );
//  
//  Serial << "Start PUT example Memory:" << freeMemory() ;
//  memset (bufMessage, '\0', POST_BUFFER_SIZE);
//  memset (bufTmp, '\0', TEMP_BUFFER_SIZE);
// 
//  PString strMessage(bufMessage, POST_BUFFER_SIZE);
//  PString strContent(bufContent, TEMP_BUFFER_SIZE);
//  
//  // two-part build:  Form the message contents so we know how big it is, then form the message header.
//  strContent << "counter," << iLoopCounter << "\r\nvalue," << fValue << "\r\n\r\n";
//  
//  strMessage << "PUT " << MY_SERVER_PUT_URL << " HTTP/1.1\r\n" 
//       <<  "Host: " << MY_SERVER_PUT  << " Content-Length: " << strContent.length() << "\r\n"
//       << strContent;
//  
//  Serial <<"Put Message"<< (const char*) strMessage  << endl<< strMessage.length() << "***" << endl;
//    
//  if (WiFly.openConnection(MY_SERVER_PUT) ) {
//    delay(1000);
//    WiFly.uart.print(strMessage);
//    //  WiFly.uart.print(strContent);
//    //  WiFly.ScanForPattern( bufMessage, POST_BUFFER_SIZE, "OK", true, 4000 );
//    // Show server response
//    unsigned long TimeOut = millis() + 8000;
//
//    while ( millis()  < TimeOut) {
//      if (  WiFly.uart.available() > 0 ) {
//        Serial.print( WiFly.uart.read(), BYTE);
//      }
//    }
//WiFly.closeConnection();
//    
//  } else {
//    Serial << "Failed to open connection to " << MY_SERVER_PUT << endl;
//  }
//  
//  WiFly.setDebugChannel( NULL );
//  return 0;
//}




