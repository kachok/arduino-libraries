#ifndef __WIFLY_DEVICET_H__
#define __WIFLY_DEVICET_H__

/*
Arduino WiFly Device Driver
Driver for Roving Network's WiFly GSX (c) (tm) b/g WiFi device
 using a simple Tx/Rx serial connection.
 4-wires needed: Power, Gnd, Rx, Tx

Provides moderately-generic WiFi device interface.

- WiFlyGSX is a relatively intelligent peer.
- WiFlyGSX may have awoken in a valid configured state while Arduino asleep; 
    initialization and configuration to be polite and obtain state
- WiFlyGSX hardware CTS/RTS not enabled yet
- Can listen on multiple ports.
- most settings assumed volatile; fetched from WiFly where reasonable.

Expected pattern of use:
begin
issue commands, such as set SSID, passphrase etc
exit command mode / enter data mode
listen for web activity
Open a TCP connection to a peer
send / receive data
close connection

NewSoftSerial is exposed as serial i/o

Credits:
  NewSoftSerial    Mikal Hart   http://arduiniana.org/
  PString          Mikal Hart   http://arduiniana.org/
  Time             Michael Margolis http://www.arduino.cc/playground/uploads/Code/Time.zip
  WiFly            Roving Networks   www.rovingnetworks.com
  and to Massimo and the Arduino team.


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

Copyright GPL 2.0 Tom Waldock 2011
*/

#include <SoftwareSerial.h>
#include "MemoryFree.h"
#include "Streaming.h"
#include <avr/pgmspace.h>

#define COMMAND_BUFFER_SIZE 64
#define SMALL_COMMAND_BUFFER_SIZE 20
#define RESPONSE_BUFFER_SIZE 80
#define INDICATOR_BUFFER_SIZE 15

#define DEFAULT_SERVER_PORT 80

#define COMMAND_MODE_GUARD_TIME 250 // in milliseconds
#define DEFAULT_WAIT_TIME 1000  // waiting time for a command
#define ATTN_WAIT_TIME 2000  // waiting time for a reponse after a $$$ attention signal
#define JOIN_WAIT_TIME 10000  // joining a network could take longer

#define COMMAND_MODE_ENTER_RETRY_ATTEMPTS 5
#define COMMAND_RETRY_ATTEMPTS 3

// WiFly Responses  
#define PROMPT_NONE 0
#define PROMPT_EXPECTED_TOKEN_FOUND 1
#define PROMPT_READY 2
#define PROMPT_CMD_MODE 4
#define PROMPT_AOK 8
#define PROMPT_OTHER 16
#define PROMPT_CMD_ERR 32
#define PROMPT_TIMEOUT 64
#define PROMPT_OPEN 128
#define PROMPT_CLOSE 256

#define N_PROMPTS 8
#define WIFLY_MSG_EXPECTED  0
#define WIFLY_MSG_AOK  1
#define WIFLY_MSG_CMD  2
#define WIFLY_MSG_ERR  3
#define WIFLY_MSG_PROMPT  4
#define WIFLY_MSG_PROMPT2  5
#define WIFLY_MSG_CLOSE  6
#define WIFLY_MSG_OPEN  7

// WiFly-specific prompt codes
static char* WiFlyFixedPrompts[N_PROMPTS] = { "","AOK","CMD","ERR: ?", "",">","*CLOS*","*OPEN*" };
static byte  WiFlyFixedFlags[N_PROMPTS] = {PROMPT_EXPECTED_TOKEN_FOUND, PROMPT_AOK, PROMPT_CMD_MODE, PROMPT_CMD_ERR, PROMPT_READY,    	PROMPT_READY,PROMPT_CLOSE, PROMPT_OPEN};


class WiFlySerial {
  public:
    // Constructors
    WiFlySerial(byte pinReceive, byte pinSend);
    
    // Destructor
    
    // Initialization
    boolean begin();  // Initialises this interface Class.
    
    // Configuration Generic Wifi methods
    
    // Status
    boolean isConnected();
    char* showNetworkScan( char* pNetScan, const int buflen);
    char* GetLibraryVersion(char* buf, int buflen);
    
    boolean isDHCP();
    char* GetSSID(char* buf, int buflen);
    char* GetDeviceID(char* buf, int buflen);
    
    char* GetIP(char* buf, int buflen);
    char* GetNetMask(char* buf, int buflen);
    char* GetGateway(char* buf, int buflen);
    char* GetDNS(char* buf, int buflen);
    char* GetMAC(char* buf, int buflen);
    char* GetNTP(char* buf, int buflen);
    char* GetNTP_Update_Frequency(char* buf, int buflen);
    unsigned long GetTime();
    char* GetRSSI(char* pBuf, int buflen);
    char* GetBattery(char* pBuf, int buflen);

    // Transmit / Receive / available through exposed NewSoftSerial
	// FIX:Replaced with SoftwareSerial
    SoftwareSerial uart;    
    boolean bWiFlyInCommandMode;
    boolean bWiFlyConnectionOpen;
    
    // Generic Wifi methods
    boolean setSSID( const char* pSSID);    
    boolean setPassphrase( const char* pPassphrase);
    boolean setDeviceID( const char* pHostname);
    boolean setNTP(const char* pNTP_IP);
    boolean setNTP_Update_Frequency(const char* pFreq);
    boolean setIP( const char* pIP);
    boolean setNetMask( const char* pNM);
    boolean setGateway( const char* pGW);
    boolean setDNS( const char* pDNS);
        
    boolean setUseDHCP(const boolean bDHCP);
    
    // join and leave wifi network
    
    // Joins ssid set with setSSID
    boolean join();
    
    // Joins listed SSID
    boolean join( char* pSSID);
    
    // Leaves current SSID.
    boolean leave();
                 
    // Generic utility
    boolean startCommandMode(char* pBuffer = NULL, const int bufSize = COMMAND_BUFFER_SIZE );
    boolean exitCommandMode();     
    void reboot();
    boolean openConnection(const char* pURL, const int iPort = 80, const int WaitTime = JOIN_WAIT_TIME  );
    boolean closeConnection();
    
    // Open-format for RN 131C/G commands
    boolean SendInquiry(char *Command, char* pBuffer, const int bufsize = RESPONSE_BUFFER_SIZE );
    boolean SendInquiry(char *Command);
    boolean SendCommand( char *Command,   char *SuccessIndicator, char* pBuffer, const int bufsize, 
        const boolean bCollecting = true, const int WaitTime = DEFAULT_WAIT_TIME , const boolean bClear = true, const boolean bPromptAfterResult = true );
    boolean SendCommand( char *Command,   char *SuccessIndicator);

    // utilities for collecting results or scanning for indicators.
    int  ScanForPattern( char* responseBuffer, const int bufsize, const char *pExpectedPrompt, 
        const boolean bCapturing = true, const int WaitTime = DEFAULT_WAIT_TIME, const boolean bPromptAfterResult = true   );
    char* ExtractDetail(char* pCommand, char* pDetail, const int buflen, const char* pFrom, const char* pTo);
    int  CaptureUntilPrompt( char* responseBuffer, const int bufsize, const char *pExpectedPrompt, const int WaitTime = DEFAULT_WAIT_TIME  );

    // debug utilities - use Serial : not NewSoftSerial as it will affect incoming stream.
    // should change these to use stream <<
    void setDebugChannel( Print* pDebug);
    Print* getDebugChannel( )  { return pDebugChannel; };
    void clearDebugChannel();
    void DebugPrint( const char* pMessage);
    void DebugPrint( const int iNumber);
    void DebugPrint( const char ch);


    
  private:
    // internal buffer for command-prompt
    char szWiFlyPrompt[INDICATOR_BUFFER_SIZE ];
   
    boolean GetCmdPrompt();
    char* GetBuffer_P(const int StringIndex, char* pBuffer, int bufSize);
    char* ExtractLineFromBuffer(const int idString,  char* pBuffer, const int bufsize, const char* pStartPattern, const char* chTerminator);
    char* ExtractDetail(const int idxCommand, char* pDetail, const int buflen, const char* pFrom, const char* pTo);

    boolean issueSetting( int idxCommand, const char* pParam);

    Print* pDebugChannel;

};

#endif

