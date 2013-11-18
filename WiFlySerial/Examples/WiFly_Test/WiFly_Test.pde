/*
 * WiFly_Device Test Platform
 * A simple tester for communicating with the WiFly GSx RN-131b/g series.
 * LGPL 2.0
 * Tom Waldock, 2011 
 */

#include <WProgram.h>
#include <Streaming.h>
#include <NewSoftSerial.h>
#include "WiFlySerial.h"
#include "MemoryFree.h"
#include "Credentials.h"

#define ConsoleSerial Serial

// Pins are 3 for INCOMING TO Arduino, 5 for OUTGOING TO Wifly
// Arduino       WiFly
//  2 - receive  TX   (Send from Wifly, Receive to Arduino)
//  3 - send     RX   (Send from Arduino, Receive to WiFly) 
WiFlySerial WiFly(2,3); 

#define REQUEST_BUFFER_SIZE 100
#define HEADER_BUFFER_SIZE 150 
#define BODY_BUFFER_SIZE 100

char bufRequest[REQUEST_BUFFER_SIZE];
char bufHeader[HEADER_BUFFER_SIZE];
char bufBody[BODY_BUFFER_SIZE];

//Server server(80);

void setup() {
  
  Serial.begin(9600);
  Serial.println("Starting WiFly Tester." );
  Serial << "Free memory:" << freeMemory() << endl;  

  WiFly.setDebugChannel( (Print*) &Serial);
  WiFly.begin();
  Serial << "Starting WiFly." << endl;
  Serial << "Free memory:" << freeMemory() << endl;

  Serial << "WiFly begin mem:" <<  freeMemory() << endl;
  
  // get MAC
  Serial << "MAC: " << WiFly.GetMAC(bufRequest, REQUEST_BUFFER_SIZE) << endl;
  // is connected ?

  // if not connected restart link
  if (! WiFly.isConnected() ) {
    Serial << "Leave:" <<  ssid << WiFly.leave() << endl;
    // join
    if (WiFly.setSSID(ssid) ) {    
      Serial << "SSID Set :" << ssid << endl;
    }
    if (WiFly.setPassphrase(passphrase)) {
      Serial << "Passphrase Set :" << endl;
    }
    Serial << "Joining... :" << ssid << endl;

    if ( WiFly.join() ) {
      Serial << "Joined " << ssid << " successfully." << endl;
      WiFly.setNTP( ntp_server ); // use your favorite NTP server
    } else {
      Serial << "Join to " << ssid << " failed." << endl;
    }
  } // if not connected

  Serial << "IP: " << WiFly.GetIP(bufRequest, REQUEST_BUFFER_SIZE) << endl <<
    "Netmask: " << WiFly.GetNetMask(bufRequest, REQUEST_BUFFER_SIZE) << endl <<
    "Gateway: " << WiFly.GetGateway(bufRequest, REQUEST_BUFFER_SIZE) << endl <<
    "DNS: " << WiFly.GetDNS(bufRequest, REQUEST_BUFFER_SIZE) << endl ;

  memset (bufBody,'\0',BODY_BUFFER_SIZE);
  WiFly.SendCommand("show q 0x177 ",">", bufBody, BODY_BUFFER_SIZE);
  Serial << "WiFly Sensors: " << bufBody << endl;
  WiFly.SendCommand("show q t ",">", bufBody, BODY_BUFFER_SIZE);
  Serial << "WiFly Temp: " << bufBody << endl;
  WiFly.SendCommand("show battery ",">", bufBody, BODY_BUFFER_SIZE);
  Serial << "WiFly battery: " << bufBody << endl;

  WiFly.SendCommand("set comm remote 0",">");
  WiFly.closeConnection();
  Serial << "After Setup mem:" << freeMemory() << endl ;

  WiFly.exitCommandMode();
  
  // clear out prior requests.
  WiFly.uart.flush();
  while (WiFly.uart.available() )
    WiFly.uart.read();
  
}

char chOut;
void loop() {
  // Terminal routine

  // Always display a response uninterrupted by typing
  // but note that this makes the terminal unresponsive
  // while a response is being received.
  
  while(WiFly.uart.available() > 0) {
    Serial.print(WiFly.uart.read(), BYTE);
  }
  
  if(Serial.available()) { // Outgoing data
    WiFly.uart.print( (chOut = Serial.read()) , BYTE);
    Serial.print (chOut, BYTE);
  }

} //loop
