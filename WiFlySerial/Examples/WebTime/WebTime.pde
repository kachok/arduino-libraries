/*
 * Web Server example for the WiFly showing the current time and some status items.
 *
 * Download Mikal Hart's NewSoftSerial, Streaming and PString libraries from http://arduiniana.org
 *
 * Remember to set MY_WIFI_SSID and MY_WIFI_PASSPHRASE to your local values.
 
 Aim your browser at your WiFly address for a simple UTC time report.
 Add /status to the URL to get battery voltage and RSSI.
 
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


// Set these to your local values
#define MY_WIFI_SSID "YourSSID"
#define MY_WIFI_PASSPHRASE "YourWiFiPassphrase"

// Connect the WiFly TX pin to the Arduino RX pin  (Transmit from WiFly-> Receive into Arduino)
// Connect the WiFly RX pin to the Arduino TX pin  (Transmit from Arduino-> Receive into WiFly)
// 
// Connect the WiFly GND pin to an Arduino GND pin
// Finally, connect the WiFly BATT pin to the 3.3V pin (NOT the 5v pin)

#define ARDUINO_RX_PIN  2
#define ARDUINO_TX_PIN  3


prog_char s_WT_SETUP_00[] PROGMEM = "nist1-la.ustiming.org";  /* change to your favorite NTP server */
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
prog_char s_WT_MSG_START_WEBTIME[] PROGMEM = "Starting WebTime - Please wait. ";
prog_char s_WT_MSG_RAM[] PROGMEM = "RAM :";
prog_char s_WT_MSG_START_WIFLY[] PROGMEM = "Started WiFly, RAM :";
prog_char s_WT_MSG_WIFI[] PROGMEM = "Initial WiFi Settings :";
prog_char s_WT_MSG_APP_SETTINGS[] PROGMEM = "Configure WebTime Settings...";
prog_char s_WT_HTML_HEAD_01[] PROGMEM = "HTTP/1.1 200 OK \r ";
prog_char s_WT_HTML_HEAD_02[] PROGMEM = "Content-Type: text/html;charset=UTF-8\r ";
prog_char s_WT_HTML_HEAD_03[] PROGMEM = " Content-Length: ";
prog_char s_WT_HTML_HEAD_04[] PROGMEM = "Connection: close \r\n\r\n ";

#define IDX_WT_SETUP_00 0
#define IDX_WT_SETUP_01 IDX_WT_SETUP_00 +1
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
#define IDX_WT_MSG_START_WEBTIME IDX_WT_MSG_JOIN +1
#define IDX_WT_MSG_RAM           IDX_WT_MSG_START_WEBTIME +1
#define IDX_WT_MSG_START_WIFLY   IDX_WT_MSG_RAM +1
#define IDX_WT_MSG_WIFI          IDX_WT_MSG_START_WIFLY +1
#define IDX_WT_MSG_APP_SETTINGS  IDX_WT_MSG_WIFI +1

#define IDX_WT_HTML_HEAD_01      IDX_WT_MSG_APP_SETTINGS + 1
#define IDX_WT_HTML_HEAD_02      IDX_WT_HTML_HEAD_01 + 1
#define IDX_WT_HTML_HEAD_03      IDX_WT_HTML_HEAD_02 + 1
#define IDX_WT_HTML_HEAD_04      IDX_WT_HTML_HEAD_03 + 1



PROGMEM const char *WT_string_table[] = 	   
{   
  s_WT_SETUP_00,
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
  s_WT_MSG_START_WEBTIME,
  s_WT_MSG_RAM,
  s_WT_MSG_START_WIFLY,
  s_WT_MSG_WIFI,
  s_WT_MSG_APP_SETTINGS,
  s_WT_HTML_HEAD_01,
  s_WT_HTML_HEAD_02,
  s_WT_HTML_HEAD_03,
  s_WT_HTML_HEAD_04
};

#define REQUEST_BUFFER_SIZE 80
#define HEADER_BUFFER_SIZE 120 
#define BODY_BUFFER_SIZE 180
#define TEMP_BUFFER_SIZE 40

char bufRequest[REQUEST_BUFFER_SIZE];
char bufTemp[TEMP_BUFFER_SIZE];
char chMisc;
int iRequest = 0;
int iTrack = 0;

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

  WiFly.SendCommand(GetBuffer_P(IDX_WT_SETUP_01,bufTemp,TEMP_BUFFER_SIZE), ">",bufRequest, REQUEST_BUFFER_SIZE);
  WiFly.setUseDHCP(true);
  WiFly.SendCommand(GetBuffer_P(IDX_WT_SETUP_02,bufTemp,TEMP_BUFFER_SIZE),">",bufRequest, REQUEST_BUFFER_SIZE);
  Serial << "Leave current wifi network:" << WiFly.leave() << endl;
  // join
  WiFly.setPassphrase(MY_WIFI_PASSPHRASE);    
  Serial << GetBuffer_P(IDX_WT_MSG_JOIN,bufTemp,TEMP_BUFFER_SIZE) << MY_WIFI_SSID << endl;
  WiFly.join(MY_WIFI_SSID);

  // Set NTP server, update frequency, 
  WiFly.setNTP(GetBuffer_P(IDX_WT_SETUP_00,bufTemp,TEMP_BUFFER_SIZE)); 
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

// Make Response Body
// Based on GET request string, generate a response.
int MakeReponseBody( char* pBody,  char* pRequest, const int sizeRequest ) {

  PString strBody( pBody, BODY_BUFFER_SIZE);

  if ( strstr(pRequest, "/status" ) ) {
    strBody << "<html>WebTime Status:</br>Free RAM:" << freeMemory() << "</br>"
      << "DateTime:" << year() << "-" << month() << "-" << day() << " " << _DEC(hour()) << ":" << minute() << ":" << second() << "</br>";
    strBody << "Battery: " << WiFly.GetBattery(bufTemp,TEMP_BUFFER_SIZE) << "</br>";    
    strBody << "RSSI: " << WiFly.GetRSSI(bufTemp,TEMP_BUFFER_SIZE) << "</br>";
    strBody << "</html>\r\n\r\n";

    // need to exit command mode to be able to send data
    WiFly.exitCommandMode();

  } 
  else {
    strBody << "<html>Current request:" << pRequest << "</br>Millis:" << millis() << " Micros:" << micros()
      << "</br>DateTime:" << year() << "-" << month() << "-" << day() << " " << hour() << ":" << minute() << ":" << second()
        << "</html>\r\n\r\n";
    // No calls back to WiFly command mode; hence no need to exit Command mode that wasn't entered.
  }
  return strBody.length();
}

// MakeResponseHeader
// Form a HTML header, including length of body.
int MakeResponseHeader( char* pHeader, char* pBody ) {

  PString strHeader( pHeader, HEADER_BUFFER_SIZE);
  // send a standard http response header    

  strHeader << GetBuffer_P(IDX_WT_HTML_HEAD_01,bufTemp,TEMP_BUFFER_SIZE)
    << GetBuffer_P(IDX_WT_HTML_HEAD_02,bufTemp,TEMP_BUFFER_SIZE)
      << GetBuffer_P(IDX_WT_HTML_HEAD_03,bufTemp,TEMP_BUFFER_SIZE) << (int) strlen(pBody) << " \r"
        << GetBuffer_P(IDX_WT_HTML_HEAD_04,bufTemp,TEMP_BUFFER_SIZE);

  return strHeader.length();
}


// Arduino Setup routine.

void setup() {
  Serial.begin(9600);

  Serial << GetBuffer_P(IDX_WT_MSG_START_WEBTIME,bufTemp,TEMP_BUFFER_SIZE) << endl << GetBuffer_P(IDX_WT_MSG_RAM,bufTemp,TEMP_BUFFER_SIZE) << freeMemory() << endl;

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

  Serial << "RSSI: " << WiFly.GetRSSI(bufRequest, REQUEST_BUFFER_SIZE) << endl;
  Serial << "battery: " <<  WiFly.GetBattery(bufRequest, REQUEST_BUFFER_SIZE) << endl;

  // close any open connections
  WiFly.closeConnection();
  Serial << "After Setup RAM:" << freeMemory() << endl ;

  WiFly.exitCommandMode();
  //  WiFly.setDebugChannel( (Print*) &Serial);

}


void loop() {

  memset (bufRequest,'\0',REQUEST_BUFFER_SIZE);
  Serial << "Loop RAM:" << freeMemory() << endl ;

  //  WiFly.clearDebugChannel();
  // if not connected restart link
  while (! WiFly.isConnected() ) {
    Reconnect();
  } // while not connected
  //  WiFly.setDebugChannel( (Print*) &Serial);

  Serial << "Clear leftovers" << endl;
  // read past the browser's header details
  while ((chMisc = WiFly.uart.read()) > -1) {
    Serial << chMisc;
  }
  Serial << "Ready for HTTP:" << freeMemory() << endl ;

  iRequest = WiFly.ScanForPattern( bufRequest, REQUEST_BUFFER_SIZE, "*OPEN*", false,20000 );
  if ( ( iRequest &  PROMPT_EXPECTED_TOKEN_FOUND) == PROMPT_EXPECTED_TOKEN_FOUND ) {
    memset (bufRequest,'\0',REQUEST_BUFFER_SIZE);
    WiFly.bWiFlyInCommandMode = false;

    // analyse request for GET;
    WiFly.ScanForPattern( bufRequest, REQUEST_BUFFER_SIZE, " HTTP/1.1", 1000 );
    Serial << "GET request,  bytes: " << strlen(bufRequest) << endl << bufRequest << endl;

    // read past the browser's header details
    while ((chMisc = WiFly.uart.read()) > -1)
      Serial << chMisc;

    char* pHeader = (char*) malloc(HEADER_BUFFER_SIZE);
    char* pBody = (char*) malloc(BODY_BUFFER_SIZE);

    // Form header and body of response
    MakeReponseBody(pBody,  bufRequest, REQUEST_BUFFER_SIZE);
    MakeResponseHeader( pHeader,  pBody);

    // send reply
    WiFly.uart << pHeader << pBody << "\t";

    Serial << endl << "Header:" << endl << pHeader << "Body:" << pBody << endl;
    // give the web browser time to receive the data
    // NewSoftSerial will trickle data up to the WiFly after print stmt completed.
    // settings are conservative ... more rapid responses possible.
    delay(1000);
    free(pHeader);
    free(pBody);
    pHeader = NULL;
    pBody = NULL;
    // close connection
    WiFly.closeConnection();
    WiFly.exitCommandMode();
  } // if Open connection found.
}



