/*
 * UDP Server example for the WiFly.
 * Sends UDP packets showing the current time.
 *
 * Download Mikal Hart's NewSoftSerial, Streaming and PString libraries from http://arduiniana.org
 *
 * Remember to set the following to your local values:
 * MY_WIFI_SSID
 * MY_WIFI_PASSPHRASE
 * MY_UDP_RECEIVING_HOST_IP   (IP of host receiving UDP messages)
 * MY_UDP_RECEIVING_HOST_PORT. (port on above host where listening for UDP)
 * MY_NTP_SERVER   ( your favorite NTP server to get the time).
 
 * and 
 * ARDUINO_RX_PIN   (FROM the WiFly Tx pin TO the Arduino Rx pin)
 * ARDUINO_TX_PIN   (FROM the WiFly Rx pin TO the Arduino Tx pin)
 
 USAGE:
 Aim your favorite UDP listener on the receiving host at the receiving port, 
 and the UTC time should appear.
 
 e.g.   nc -uvl 17129 
 
 Exiting cleanly returns the WiFly back to TCP mode.
 Otherwise you'd need to use WiFlyTerminal and issue the following command:
 set ip protocol 2
 
 NOTES:
 The WiFly buffers outgoing data (received from the Arduino) and sends packets
 when its buffer is full, or when a trigger character is received.
 The buffer size is controlled with:
 set comm size nnn    where nnn is the buffer size.
 
 The trigger character is controlled with:
 set comm match 0xhh   where 0xhh is the (hex) Ascii value of the trigger character.
 
 Play with these to observe data flow effects.
 
 
 
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
#define MY_WIFI_SSID "mySSID"
#define MY_WIFI_PASSPHRASE "MySecurePassphrase"
#define MY_UDP_RECEIVING_HOST_IP "MyUDP_ListeningHost_IP"
#define MY_UDP_RECEIVING_HOST_PORT "17129"
#define MY_NTP_SERVER "nist1-la.ustiming.org"

// Connect the WiFly TX pin to the Arduino RX pin  (Transmit from WiFly-> Receive into Arduino)
// Connect the WiFly RX pin to the Arduino TX pin  (Transmit from Arduino-> Receive into WiFly)
// 
// Connect the WiFly GND pin to an Arduino GND pin
// Finally, connect the WiFly BATT pin to the 3.3V pin (NOT the 5v pin)

#define ARDUINO_RX_PIN  2
#define ARDUINO_TX_PIN  3


prog_char s_WT_SETUP_00[] PROGMEM = MY_NTP_SERVER;  /* change to your favorite NTP server */
prog_char s_WT_SETUP_01[] PROGMEM = "set u m 0x1";
prog_char s_WT_SETUP_02[] PROGMEM = "set comm remote 0";
prog_char s_WT_SETUP_03[] PROGMEM = "set comm idle 30";
prog_char s_WT_SETUP_04[] PROGMEM = "set comm time 2000";
prog_char s_WT_SETUP_05[] PROGMEM = "set comm size 64";
prog_char s_WT_SETUP_06[] PROGMEM = "set comm match 0x0d";
prog_char s_WT_SETUP_07[] PROGMEM = "time";
prog_char s_WT_TO_UDP_01[] PROGMEM = "set ip proto 1 ";
prog_char s_WT_TO_UDP_02[] PROGMEM = "set ip host ";
prog_char s_WT_TO_UDP_03[] PROGMEM = "set ip remote ";
prog_char s_WT_TO_UDP_04[] PROGMEM = "set ip local ";
prog_char s_WT_FROM_UDP_01[] PROGMEM = "set ip proto 2 ";
prog_char s_WT_FROM_UDP_02[] PROGMEM = "set ip host localhost";
prog_char s_WT_FROM_UDP_03[] PROGMEM = "set ip remote 80";
prog_char s_WT_FROM_UDP_04[] PROGMEM = "set ip local 2000";
prog_char s_WT_WIFLY_SAVE[] PROGMEM = "save ";
prog_char s_WT_WIFLY_REBOOT[] PROGMEM = "reboot ";
prog_char s_WT_STATUS_SENSORS[] PROGMEM = "show q 0x177 ";
prog_char s_WT_STATUS_TEMP[] PROGMEM = "show q t ";
prog_char s_WT_STATUS_RSSI[] PROGMEM = "show rssi ";
prog_char s_WT_STATUS_BATT[] PROGMEM = "show battery ";
prog_char s_WT_MSG_JOIN[] PROGMEM = "Credentials Set, Joining ";
prog_char s_WT_MSG_START_WEBTIME[] PROGMEM = "Starting UDPSample - Please wait. ";
prog_char s_WT_MSG_RAM[] PROGMEM = "RAM :";
prog_char s_WT_MSG_START_WIFLY[] PROGMEM = "Started WiFly, RAM :";
prog_char s_WT_MSG_WIFI[] PROGMEM = "Initial WiFi Settings :";
prog_char s_WT_MSG_APP_SETTINGS[] PROGMEM = "Configure UDPSample Settings...";
prog_char s_WT_MSG_TO_UDP[] PROGMEM = "Switching to UDP mode...";
prog_char s_WT_MSG_FROM_UDP[] PROGMEM = "Switching from UDP mode to TCP...";
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

#define IDX_WT_TO_UDP_01 IDX_WT_SETUP_07 + 1
#define IDX_WT_TO_UDP_02 IDX_WT_TO_UDP_01 + 1
#define IDX_WT_TO_UDP_03 IDX_WT_TO_UDP_02 + 1
#define IDX_WT_TO_UDP_04 IDX_WT_TO_UDP_03 + 1

#define IDX_WT_FROM_UDP_01 IDX_WT_TO_UDP_04 + 1
#define IDX_WT_FROM_UDP_02 IDX_WT_FROM_UDP_01 + 1
#define IDX_WT_FROM_UDP_03 IDX_WT_FROM_UDP_02 + 1
#define IDX_WT_FROM_UDP_04 IDX_WT_FROM_UDP_03 + 1

#define IDX_WT_WIFLY_SAVE IDX_WT_FROM_UDP_04 + 1
#define IDX_WT_WIFLY_REBOOT IDX_WT_WIFLY_SAVE + 1

#define IDX_WT_STATUS_SENSORS    IDX_WT_WIFLY_REBOOT + 1 
#define IDX_WT_STATUS_TEMP       IDX_WT_STATUS_SENSORS +1
#define IDX_WT_STATUS_RSSI       IDX_WT_STATUS_TEMP +1
#define IDX_WT_STATUS_BATT       IDX_WT_STATUS_RSSI +1

#define IDX_WT_MSG_JOIN          IDX_WT_STATUS_BATT +1
#define IDX_WT_MSG_START_WEBTIME IDX_WT_MSG_JOIN +1
#define IDX_WT_MSG_RAM           IDX_WT_MSG_START_WEBTIME +1
#define IDX_WT_MSG_START_WIFLY   IDX_WT_MSG_RAM +1
#define IDX_WT_MSG_WIFI          IDX_WT_MSG_START_WIFLY +1
#define IDX_WT_MSG_APP_SETTINGS  IDX_WT_MSG_WIFI +1
#define IDX_WT_MSG_TO_UDP        IDX_WT_MSG_APP_SETTINGS +1
#define IDX_WT_MSG_FROM_UDP      IDX_WT_MSG_TO_UDP +1

#define IDX_WT_HTML_HEAD_01      IDX_WT_MSG_FROM_UDP + 1
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
  s_WT_TO_UDP_01,
  s_WT_TO_UDP_02,
  s_WT_TO_UDP_03,
  s_WT_TO_UDP_04,
  s_WT_FROM_UDP_01,
  s_WT_FROM_UDP_02,
  s_WT_FROM_UDP_03,
  s_WT_FROM_UDP_04,
  s_WT_WIFLY_SAVE,
  s_WT_WIFLY_REBOOT,
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
  s_WT_MSG_TO_UDP,
  s_WT_MSG_FROM_UDP,
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

// Switch_To_UDP_Mode
//
// Sets WiFly device into UDP mode.
//
// Parameters: none
// Returns: true for success, false on failure
int Switch_To_UDP_Mode() {
  
  // Per page 33
//  set ip proto 1
//  set ip host <destination ip>
//  set ip port <destination port>
//  set ip local
//  save
//  reboot

//  set ip proto 1
  WiFly.SendCommand(GetBuffer_P(IDX_WT_TO_UDP_01,bufTemp,TEMP_BUFFER_SIZE), WiFlyFixedPrompts[PROMPT_AOK],bufRequest, REQUEST_BUFFER_SIZE);
  
//  set ip host <destination ip>
  GetBuffer_P(IDX_WT_TO_UDP_02,bufTemp,TEMP_BUFFER_SIZE);
  strncat( bufTemp, MY_UDP_RECEIVING_HOST_IP, TEMP_BUFFER_SIZE - strlen(bufTemp) );
  WiFly.SendCommand(bufTemp, WiFlyFixedPrompts[PROMPT_AOK],bufRequest, REQUEST_BUFFER_SIZE);
  
//  set ip port <destination port>
  GetBuffer_P(IDX_WT_TO_UDP_03,bufTemp,TEMP_BUFFER_SIZE);
  strncat( bufTemp, MY_UDP_RECEIVING_HOST_PORT, TEMP_BUFFER_SIZE - strlen(bufTemp) );
  WiFly.SendCommand(bufTemp, WiFlyFixedPrompts[PROMPT_AOK],bufRequest, REQUEST_BUFFER_SIZE);
  
//  set my port to same as <destination port> just because it avoids another #define.
  GetBuffer_P(IDX_WT_TO_UDP_04,bufTemp,TEMP_BUFFER_SIZE);
  strncat( bufTemp, MY_UDP_RECEIVING_HOST_PORT, TEMP_BUFFER_SIZE - strlen(bufTemp) );
  WiFly.SendCommand(bufTemp, WiFlyFixedPrompts[PROMPT_AOK],bufRequest, REQUEST_BUFFER_SIZE);
  
//  save  
  WiFly.SendCommand(GetBuffer_P(IDX_WT_WIFLY_SAVE,bufTemp,TEMP_BUFFER_SIZE), WiFlyFixedPrompts[PROMPT_AOK],bufRequest, REQUEST_BUFFER_SIZE);
  
//  reboot - forces settings to take effect, after some re-init messages.  
  WiFly.SendCommand(GetBuffer_P(IDX_WT_WIFLY_REBOOT,bufTemp,TEMP_BUFFER_SIZE), WiFlyFixedPrompts[PROMPT_AOK],bufRequest, REQUEST_BUFFER_SIZE);
  
}


// Switch_From_UDP_Mode
//
// Resets WiFly device back to TCP mode.
//
// Parameters: none
// Returns: true for success, false on failure
int Switch_From_UDP_Mode() {
//  set ip proto 2
//  set ip host 
//  set ip port
//  set ip local
//  save
//  reboot
//  set ip proto 1
  WiFly.SendCommand(GetBuffer_P(IDX_WT_FROM_UDP_01,bufTemp,TEMP_BUFFER_SIZE), WiFlyFixedPrompts[PROMPT_AOK],bufRequest, REQUEST_BUFFER_SIZE);
  
//  set ip host localhost
  WiFly.SendCommand( GetBuffer_P(IDX_WT_FROM_UDP_02,bufTemp,TEMP_BUFFER_SIZE), WiFlyFixedPrompts[PROMPT_AOK],bufRequest, REQUEST_BUFFER_SIZE);
  
//  set ip port 2000
  WiFly.SendCommand(GetBuffer_P(IDX_WT_FROM_UDP_03,bufTemp,TEMP_BUFFER_SIZE), WiFlyFixedPrompts[PROMPT_AOK],bufRequest, REQUEST_BUFFER_SIZE);
  
//  set my port to same as <destination port> just because it avoids another #define.
  WiFly.SendCommand(GetBuffer_P(IDX_WT_FROM_UDP_04,bufTemp,TEMP_BUFFER_SIZE), WiFlyFixedPrompts[PROMPT_AOK],bufRequest, REQUEST_BUFFER_SIZE);
  
//  save  
  WiFly.SendCommand(GetBuffer_P(IDX_WT_WIFLY_SAVE,bufTemp,TEMP_BUFFER_SIZE), WiFlyFixedPrompts[PROMPT_AOK],bufRequest, REQUEST_BUFFER_SIZE);
  
//  reboot - forces settings to take effect, after some re-init messages.  
  WiFly.SendCommand(GetBuffer_P(IDX_WT_WIFLY_REBOOT,bufTemp,TEMP_BUFFER_SIZE), WiFlyFixedPrompts[PROMPT_AOK],bufRequest, REQUEST_BUFFER_SIZE);
  
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
  int iLoop = 0;
  int nLoops = 5;
  boolean bDone = false;
  char szMsg[HEADER_BUFFER_SIZE];
  PString sMsg(szMsg, HEADER_BUFFER_SIZE);
  
  memset (bufRequest,'\0',REQUEST_BUFFER_SIZE);
  Serial << "Loop RAM:" << freeMemory() << endl ;

  Serial << "Starting UDP Transmissions for " << nLoops << " iterations" << endl
    << " listen with ' nc -uv -l " << MY_UDP_RECEIVING_HOST_PORT << " on host " << MY_UDP_RECEIVING_HOST_IP << " '" << endl
    << "Press any key (and 'Send') to stop." << endl;

  // Set the debug channel if educational
  // WiFly.setDebugChannel( (Print*) &Serial);

  
  // Start UDP
  Serial << GetBuffer_P(IDX_WT_MSG_TO_UDP,bufTemp,TEMP_BUFFER_SIZE) << endl;
  Switch_To_UDP_Mode();
  
  // while not done iterating (or user quits)
  //   Generate unique (timestamped) string
  //   send it via UDP, echo on terminal
  //   check for user input
  //   if user input is 'done' 
  //     break;
  //   otherwise continue iterating.
  Serial.flush();
  
  iLoop = 0;
  while (!bDone) {
    sMsg.begin();
    sMsg << "UDP Message #" << iLoop
       << " Millis=" << millis() 
       << " DateTime:" << year() << "-" << month() << "-" << day() << " " << hour() << ":" << minute() << ":" << second() << endl;
    WiFly.uart.print(sMsg);
    WiFly.uart.print( (char) 0x0d );
    Serial << sMsg;
     
    iLoop++;
    
    if ( Serial.available() > 0  ) {
      bDone = true;
      Serial << "Stopping from received keypress..." << endl;
    }
    
    if ( iLoop > nLoops ) {
      bDone = true;
      Serial << "Iterations completed." << endl;
    }
  }  // loop
  Serial << GetBuffer_P(IDX_WT_MSG_FROM_UDP,bufTemp,TEMP_BUFFER_SIZE) << endl;
  Switch_From_UDP_Mode();
  
  
}



