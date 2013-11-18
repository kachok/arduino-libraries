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

Copyright GPL 2.1 Tom Waldock 2011
*/

//#include <WProgram.h>
#include "WiFlySerial.h"

// Strings stored in Program space
prog_char s_WIFLYDEVICE_LIBRARY_VERSION[] PROGMEM = "WiFlySerial v0.84" ;   
prog_char s_WIFLYDEVICE_JOIN[] PROGMEM = "join " ;   
prog_char s_WIFLYDEVICE_ASSOCIATED[] PROGMEM = "ssociated" ;   
prog_char s_WIFLYDEVICE_ATTN[] PROGMEM = "$$$" ;   
prog_char s_WIFLYDEVICE_VER[] PROGMEM ="ver";
prog_char s_WIFLYDEVICE_LEAVE_CMD_MODE[] PROGMEM ="exit";
prog_char s_WIFLYDEVICE_GET_MAC[] PROGMEM =" get mac";
prog_char s_WIFLYDEVICE_GET_IP[] PROGMEM =" get ip";
prog_char s_WIFLYDEVICE_GET_GW[] PROGMEM = " "; // "GW=";
prog_char s_WIFLYDEVICE_GET_NM[] PROGMEM = " "; // "NM=";
prog_char s_WIFLYDEVICE_LEAVE[] PROGMEM ="leave";
prog_char s_WIFLYDEVICE_SET_SSID[] PROGMEM =" set wlan s ";
prog_char s_WIFLYDEVICE_SET_PASSPHRASE[] PROGMEM =" set w p ";
prog_char s_WIFLYDEVICE_NETWORK_SCAN[] PROGMEM ="scan ";
prog_char s_WIFLYDEVICE_AOK[] PROGMEM ="";
prog_char s_WIFLYDEVICE_SET_UART_BAUD[] PROGMEM ="set u b 9600";
prog_char s_WIFLYDEVICE_DEAUTH[] PROGMEM ="Deauth";
prog_char s_WIFLYDEVICE_SET_NTP[] PROGMEM =" set time a ";
prog_char s_WIFLYDEVICE_SET_NTP_ENABLE[] PROGMEM ="set time e ";
prog_char s_WIFLYDEVICE_SET_DEVICEID[] PROGMEM ="set opt deviceid ";
prog_char s_WIFLYDEVICE_IP_DETAILS[] PROGMEM ="get ip";
prog_char s_WIFLYDEVICE_GET_DNS_DETAILS[] PROGMEM ="get dns";
prog_char s_WIFLYDEVICE_GET_TIME[] PROGMEM ="show t t";
prog_char s_WIFLYDEVICE_SET_DHCP[] PROGMEM ="set ip dhcp ";
prog_char s_WIFLYDEVICE_SET_IP[] PROGMEM ="set ip a ";
prog_char s_WIFLYDEVICE_SET_NETMASK[] PROGMEM ="set ip n ";
prog_char s_WIFLYDEVICE_SET_GATEWAY[] PROGMEM ="set ip g ";
prog_char s_WIFLYDEVICE_SET_DNS[] PROGMEM ="set dns address ";
prog_char s_WIFLYDEVICE_ERR_REBOOOT[] PROGMEM ="Attempting reboot ";
prog_char s_WIFLYDEVICE_ERR_START_FAIL[] PROGMEM ="Failed to get command prompt - Halting. ";
prog_char s_WIFLYDEVICE_SET_UART_MODE[] PROGMEM ="set u m 0x1 ";
prog_char s_WIFLYDEVICE_GET_WLAN[] PROGMEM ="get wlan ";
prog_char s_WIFLYDEVICE_GET_RSSI[] PROGMEM ="show rssi ";
prog_char s_WIFLYDEVICE_GET_BATTERY[] PROGMEM ="show battery ";

// Index of strings
#define STI_WIFLYDEVICE_INDEX_JOIN        0
#define STI_WIFLYDEVICE_INDEX_ASSOCIATED  1
#define STI_WIFLYDEVICE_ATTN              2
#define STI_WIFLYDEVICE_VER               3 
#define STI_WIFLYDEVICE_GET_MAC           4 
#define STI_WIFLYDEVICE_GET_IP            5 
#define STI_WIFLYDEVICE_GET_GW            6 
#define STI_WIFLYDEVICE_GET_NM            7 
#define STI_WIFLYDEVICE_LEAVE             8 
#define STI_WIFLYDEVICE_SET_SSID          9
#define STI_WIFLYDEVICE_SET_PASSPHRASE    10
#define STI_WIFLYDEVICE_NETWORK_SCAN      11
#define STI_WIFLYDEVICE_AOK               12
#define STI_WIFLYDEVICE_SET_UART_BAUD     13
#define STI_WIFLYDEVICE_DEAUTH            14
#define STI_WIFLYDEVICE_SET_NTP           15
#define STI_WIFLYDEVICE_SET_NTP_ENABLE    16
#define STI_WIFLYDEVICE_SET_DEVICEID      17
#define STI_WIFLYDEVICE_GET_IP_DETAILS    18
#define STI_WIFLYDEVICE_LEAVE_CMD_MODE    19
#define STI_WIFLYDEVICE_GET_DNS_DETAILS   20
#define STI_WIFLYDEVICE_GET_TIME          21
#define STI_WIFLYDEVICE_SET_DHCP          22
#define STI_WIFLYDEVICE_SET_IP            23
#define STI_WIFLYDEVICE_SET_NETMASK       24
#define STI_WIFLYDEVICE_SET_GATEWAY       25
#define STI_WIFLYDEVICE_SET_DNS           26
#define STI_WIFLYDEVICE_ERR_REBOOT        27
#define STI_WIFLYDEVICE_ERR_START_FAIL    28
#define STI_WIFLYDEVICE_SET_UART_MODE     29
#define STI_WIFLYDEVICE_GET_WLAN          30
#define STI_WIFLYDEVICE_GET_RSSI          31
#define STI_WIFLYDEVICE_GET_BATTERY       32
#define STI_WIFLYDEVICE_LIBRARY_VERSION   33

// String Table in Program space
PROGMEM const char *WiFlyDevice_string_table[] = 	   
{   
  s_WIFLYDEVICE_JOIN,
  s_WIFLYDEVICE_ASSOCIATED,
  s_WIFLYDEVICE_ATTN,
  s_WIFLYDEVICE_VER,
  s_WIFLYDEVICE_GET_MAC,
  s_WIFLYDEVICE_GET_IP,
  s_WIFLYDEVICE_GET_GW,
  s_WIFLYDEVICE_GET_NM,
  s_WIFLYDEVICE_LEAVE,
  s_WIFLYDEVICE_SET_SSID,
  s_WIFLYDEVICE_SET_PASSPHRASE,
  s_WIFLYDEVICE_NETWORK_SCAN,
  s_WIFLYDEVICE_AOK,
  s_WIFLYDEVICE_SET_UART_BAUD,
  s_WIFLYDEVICE_DEAUTH,
  s_WIFLYDEVICE_SET_NTP,
  s_WIFLYDEVICE_SET_NTP_ENABLE,
  s_WIFLYDEVICE_SET_DEVICEID,
  s_WIFLYDEVICE_IP_DETAILS,
  s_WIFLYDEVICE_LEAVE_CMD_MODE,  
  s_WIFLYDEVICE_GET_DNS_DETAILS,
  s_WIFLYDEVICE_GET_TIME,
  s_WIFLYDEVICE_SET_DHCP,
  s_WIFLYDEVICE_SET_IP,
  s_WIFLYDEVICE_SET_NETMASK,
  s_WIFLYDEVICE_SET_GATEWAY,
  s_WIFLYDEVICE_SET_DNS,
  s_WIFLYDEVICE_ERR_REBOOOT,
  s_WIFLYDEVICE_ERR_START_FAIL,
  s_WIFLYDEVICE_SET_UART_MODE,
  s_WIFLYDEVICE_GET_WLAN,
  s_WIFLYDEVICE_GET_RSSI,
  s_WIFLYDEVICE_GET_BATTERY,
  s_WIFLYDEVICE_LIBRARY_VERSION
};


/*
Command and Response
WiFly provides one of three results from commands:
1) ERR: Bad Args  , from malformed commands.
2) AOK , from accepted commands
3) nothing, after an inquiries' response.

Some commands will provide specific messages
e.g. join  has a possible result of
 mode=WPA1 SCAN OK followed by 'Associated!' and by ip values.
(bad SSID)  mode=NONE FAILED
(bad pwd)  mode=WPA1 SCAN OK followed by 'Disconn ...  AUTH-ERR'
           and followed by 'Disconn from <SSID>'
           
after a successful join, a 'cr' is needed to get the prompt

The 'command prompt' is currently the version number in angle-brackets e.g. <2.21>


*/


// begin
// Initializes WiFly interface and starts communication with WiFly device.
//
// Parameters: none.
// Returns: true on initialize success, false on failure.
boolean WiFlySerial::begin() {
  boolean bStart = false;
  char szCmd[SMALL_COMMAND_BUFFER_SIZE];
  char szResponse[COMMAND_BUFFER_SIZE];
//  char szIndicator[INDICATOR_BUFFER_SIZE];  

  //Device may or may not be:
  // awake / asleep
  // net-connected / connection lost
  // IP assigned / no IP
  // in command mode / data mode
  // in known state / confused
  
  // Start by setting command prompt.
  
  bWiFlyInCommandMode = false;
  startCommandMode(szCmd, COMMAND_BUFFER_SIZE);
  
  // turn off echo
  // set baud rate
  bStart = SendCommand( GetBuffer_P(STI_WIFLYDEVICE_SET_UART_MODE, szCmd, SMALL_COMMAND_BUFFER_SIZE), 
                         WiFlyFixedPrompts[WIFLY_MSG_AOK],
                         szResponse, 
                         COMMAND_BUFFER_SIZE );
  bStart = SendCommand( GetBuffer_P(STI_WIFLYDEVICE_SET_UART_BAUD, szCmd, SMALL_COMMAND_BUFFER_SIZE), 
                         WiFlyFixedPrompts[WIFLY_MSG_AOK],
                        szResponse,
                        COMMAND_BUFFER_SIZE );
  GetCmdPrompt();
  DebugPrint("GotPrompt:");
  DebugPrint(szWiFlyPrompt);
  
  
  // try, then try again after reboot.
  if (strlen(szWiFlyPrompt) < 1 ) {
    // got a problem
    DebugPrint(GetBuffer_P(STI_WIFLYDEVICE_ERR_REBOOT, szCmd, COMMAND_BUFFER_SIZE));
    reboot();
    
    delay(2000);
    // try again
    
    GetCmdPrompt();
    if (strlen(szWiFlyPrompt) < 1 ) {
      DebugPrint(GetBuffer_P(STI_WIFLYDEVICE_ERR_START_FAIL, szCmd, COMMAND_BUFFER_SIZE));
      bStart = false;
    }
  }
  return bStart;
}

// ScanForPattern
//
// General-purpose stream watcher.
// Monitors incoming stream until given prompt is detected, or error conditions, or until timer expired
////
// Parameters
// ResponseBuffer    buffer for WiFly response
// bufsize           size of buffer
// pExpectedPrompt   Marker to find
// bCollecting       true: collect chars in buffer UNTIL marker found, false: discard UNTIL marker found
// WaitTime          Timeout duration to wait for response 
// bPromptAfterResult true: version prompt after result, false: version prompt precedes results (scan, join).
// 
// Returns: (see .h file)  OR-ed flags of the following
// WiFly Responses:
//#define PROMPT_NONE 0
//#define PROMPT_EXPECTED_TOKEN_FOUND 1
//#define PROMPT_READY 2
//#define PROMPT_CMD_MODE 4
//#define PROMPT_AOK 8
//#define PROMPT_OTHER 16
//#define PROMPT_CMD_ERR 32
//#define PROMPT_TIMEOUT 64
//#define PROMPT_OPEN 128
//#define PROMPT_CLOSE 256

int WiFlySerial::ScanForPattern( char* responseBuffer, const int buflen,  const char *pExpectedPrompt, const boolean bCollecting,  const int WaitTime, const boolean bPromptAfterResult) {
  
  byte iPromptFound = PROMPT_NONE;  
  char chResponse = 'A';
  int  bufpos = 0;
  int  bufsize = buflen -1;  //terminating null for bufsize
  int  iPromptIndex = 0;
  boolean bWaiting = true;
  boolean bReceivedCR = false;
  
  
  
 
 WiFlyFixedPrompts[WIFLY_MSG_EXPECTED] = (char*) pExpectedPrompt;
 WiFlyFixedPrompts[WIFLY_MSG_PROMPT] = szWiFlyPrompt;
 char* pFixedCurrent[N_PROMPTS];
 int iFixedPrompt = 0;
  
 for (int i=0; i< N_PROMPTS; i++) {
  pFixedCurrent[i] = WiFlyFixedPrompts[i];
 }
    
  memset (responseBuffer, '\0', bufsize);
  unsigned long TimeOutTime = millis() + WaitTime ;
      
  while (bWaiting ) {    
    if (uart.available() > 0 ) {
      chResponse = uart.read(); 
      DebugPrint(chResponse);
      
      if ( bCollecting ) {     
        responseBuffer[bufpos]=chResponse;
        if ( ++bufpos == bufsize ) {     
          bufpos = 0;
        } // if buffer wrapped
      } // if capturing
            
      for ( iFixedPrompt = 0; iFixedPrompt< N_PROMPTS; iFixedPrompt++ ) {
        if ( chResponse == *pFixedCurrent[iFixedPrompt] ) {
          
          // deal with 'open' and 'scan' version-prompt appearing BEFORE result; ignore it
          if ( (!bPromptAfterResult) && (iFixedPrompt == WIFLY_MSG_PROMPT || iFixedPrompt == WIFLY_MSG_PROMPT2) /* standard version-prompt */  ) {
            bWaiting = true;
            iPromptFound |= PROMPT_READY;
          } else {
            bWaiting = ( *(++pFixedCurrent[iFixedPrompt]) == '\0' ? false : true ) ; // done when end-of-string encountered.
            if (!bWaiting) {
              iPromptFound |= WiFlyFixedFlags[iFixedPrompt];  // if a prompt found then grab its flag.
            }
          } // handle prompt-BEFORE-result case
        } else {
          pFixedCurrent[iFixedPrompt] = WiFlyFixedPrompts[iFixedPrompt];  // not next char expected; reset to beginning of string.
        } // if tracking expected response
      }
       // If the *OPEN* signal caught then a connection was opened.
       if (iPromptFound & PROMPT_OPEN ) {
         bWiFlyConnectionOpen = true;
         iPromptFound &= (!WiFlyFixedFlags[WIFLY_MSG_CLOSE]);  // clear prior close
       }
       // If the *CLOS* signal caught then a connection was closed.
       if (iPromptFound & PROMPT_CLOSE ) {
         bWiFlyConnectionOpen = false;
          iPromptFound &= (!WiFlyFixedFlags[WIFLY_MSG_OPEN]);  // clear prior open
       }
                
    } // if anything in uart
    if ( millis() > TimeOutTime) {
        bWaiting = false;        
    }
 }  // while waiting for a line
    // could capture and compare with known prompt
 if ( bCollecting ) {   
   responseBuffer[bufpos]='\0'; 
 }
  return (int) iPromptFound;
  
} // ScanForPattern

// Start Command Mode
// 
// Attempt up to 5 times
// test is "Get a command prompt matching results of 'ver' command".
// if InCommand mode, try a 'cr'.  
// If no useful result, assume not actually in command mode, force with $$$
// 
// Returns true for Command mode entered, false if not (something weird afoot).

boolean WiFlySerial::startCommandMode(char* pBuffer, const int bufSize) {
  byte iPromptResult = 0;
  char* responseBuffer;
  boolean bWaiting = true;
  int nTries = 0;
  
  unsigned long TimeOutTime = millis() + 2000 ;

  if (pBuffer == NULL) {
      responseBuffer = (char*) malloc(bufSize); // defaults to COMMAND_BUFFER_SIZE
  } else {
    responseBuffer = pBuffer;
  }

  // check if actually in command mode:
  while  (!bWiFlyInCommandMode || bWaiting ) {
              
       // if not effectively in command mode, try $$$
       if ( !bWiFlyInCommandMode) {
        
         // Send $$$ , wait a moment, look for CMD
         delay(COMMAND_MODE_GUARD_TIME + 200);
         uart.print(GetBuffer_P(STI_WIFLYDEVICE_ATTN, responseBuffer, COMMAND_BUFFER_SIZE) );
         delay(COMMAND_MODE_GUARD_TIME + 200);
          if (nTries > 2)  {
            uart.print("\r");
          }
         // expect CMD without a cr
         iPromptResult = ScanForPattern( responseBuffer, bufSize, "CMD", false, ATTN_WAIT_TIME);
         
         if ( iPromptResult & ( PROMPT_EXPECTED_TOKEN_FOUND | PROMPT_READY |PROMPT_CMD_MODE |PROMPT_CMD_ERR ) ) {
               bWiFlyInCommandMode = true;
               bWaiting = false;
         } else {
               bWiFlyInCommandMode = false;
               //uart.print("\r");
         }      // if one of several indicators of command-mode received.     
          
       } else { 

        // think we are in a command-mode - try a cr, then add a version command to get through.
       // send a ver + cr, should see a prompt.
          if (nTries > 2)  {
            uart.print(GetBuffer_P(STI_WIFLYDEVICE_VER, responseBuffer, bufSize) );
          }
          uart.print("\r");
          // bring in a cr-terminated line
          
          // wait for up to time limit for a cr to flow by
          iPromptResult = ScanForPattern( responseBuffer, bufSize, szWiFlyPrompt, false);
          // could have timed out, or have *READY*, CMD or have a nice CR.
          
         if ( iPromptResult & ( PROMPT_EXPECTED_TOKEN_FOUND | PROMPT_READY |PROMPT_CMD_MODE |PROMPT_CMD_ERR ) ) {
               bWiFlyInCommandMode = true;
               bWaiting = false;
         } else {
               bWiFlyInCommandMode = false;
         }      // if one of several indicators of command-mode received.     

       } //  else in in command command mode
  
      if ( millis() > TimeOutTime) {
        bWaiting = false;
      }
      nTries++;
  } // while trying to get into command mode
  
  // clean up as needed
  if (pBuffer == NULL) {
    free (responseBuffer);
  }
  return bWiFlyInCommandMode;  
}


// GetCmdPrompt
// Obtains the WiFly command prompt string for use by other command functions.
// Parameters: None
// Sets global szWiFlyPrompt
// Returns command prompt on success or empty string on failure
boolean WiFlySerial::GetCmdPrompt () {
 
  boolean bOk = false;
  char responseBuffer[RESPONSE_BUFFER_SIZE];
    
  if ( startCommandMode(responseBuffer, RESPONSE_BUFFER_SIZE)  ) {
    uart << GetBuffer_P(STI_WIFLYDEVICE_VER, responseBuffer, RESPONSE_BUFFER_SIZE )  << "\r";
    ScanForPattern(responseBuffer, RESPONSE_BUFFER_SIZE, ">", true, COMMAND_MODE_GUARD_TIME);
    char* pPromptStart = strrchr(responseBuffer, '<') ;
    char* pPromptEnd = strrchr (responseBuffer, '>');
        
    if ( (pPromptStart < pPromptEnd ) && pPromptStart && pPromptEnd) {
      strncpy(szWiFlyPrompt, pPromptStart , (size_t) (pPromptEnd - pPromptStart)+1 );
      szWiFlyPrompt[(pPromptEnd - pPromptStart)+1] = '\0';
    
    }
  }
 
  if ( strlen (szWiFlyPrompt) > 1 ) {
      bOk = true;
  } else {
    bOk = false;
  }

  return bOk;  
}

// SendCommand
// Issues a command to the WiFly device
// Captures results in Returned result
// 
//
// Parameters: 
// Command          The inquiry-command to send
// SuccessIndicator String to indicate success 
// pResultBuffer    A place to put results of the command
// bufsize          Length of the pResultBuffer
// bCollecting      true = collect results, false=ignore results.
// iWaitTime        Time in milliseconds to wait for a result.
// bClear           true = drain any preceeding and subsequent characters, false=ignore
// bPromptAfterResult true=commands end with a version-prompt, false=version-prompt precedes results.
//
// Returns true on SuccessIndicator presence, false if absent.
boolean WiFlySerial::SendCommand( char *pCmd,  char *SuccessIndicator, char* pResultBuffer, const int bufsize, 
              const boolean bCollecting, const  int iWaitTime, const boolean bClear, const boolean bPromptAfterResult) {
  
  boolean bCommandOK = false;
  char ch;
  int iResponse = 0;
  int iTry = 0;
    
  char* Command  = pCmd;
  if (pCmd == pResultBuffer ) {
    Command = (char*) malloc( strlen(pCmd) +1 );
    strcpy( Command, pCmd);
  }
  //      
  // clear out leftover characters
  
  if ( bClear ) {
     ScanForPattern(pResultBuffer, bufsize, WiFlyFixedPrompts[WIFLY_MSG_CLOSE], false, 1000, true);
//     while ( (ch = uart.read() ) > -1 ) {
//       DebugPrint(ch);
//     }
  } 

  
  DebugPrint( "Cmd:");
  DebugPrint( Command );
  DebugPrint( " Ind:" );
  DebugPrint( SuccessIndicator);
    
 
  if ( startCommandMode(pResultBuffer, bufsize) ) {
    
      while ( ((iResponse & PROMPT_EXPECTED_TOKEN_FOUND) != PROMPT_EXPECTED_TOKEN_FOUND) && iTry < COMMAND_RETRY_ATTEMPTS ) {
        uart << Command << "\r" ;
        iResponse = ScanForPattern( pResultBuffer, bufsize, SuccessIndicator, bCollecting, iWaitTime, bPromptAfterResult );   
        
//        DebugPrint("Try#:");
//        DebugPrint( iTry ); 
//        DebugPrint(" Res:");
//        DebugPrint(iResponse);
        iTry++;
      }

  }
  if ( pCmd == pResultBuffer ) {
    free (Command);
  }
  
  if ( bClear ) {
     ScanForPattern(strchr(pResultBuffer, '\0') +1, bufsize - strlen(pResultBuffer) -1, WiFlyFixedPrompts[WIFLY_MSG_CLOSE], false, 1000, true);
//     while ( (ch = uart.read() ) > -1 ) {
//       DebugPrint(ch);
//     }
  } // clear out leftover characters
  
  bCommandOK = ( ((iResponse & PROMPT_EXPECTED_TOKEN_FOUND) == PROMPT_EXPECTED_TOKEN_FOUND) ? true : false );

  return bCommandOK;
}

// convenient and version with own small ignored response buffer.
boolean WiFlySerial::SendCommand( char* pCommand,  char* pSuccessIndicator) {
 
  char bufResponse[INDICATOR_BUFFER_SIZE];

  return SendCommand(  pCommand, pSuccessIndicator, bufResponse, INDICATOR_BUFFER_SIZE, false );
}




// SendInquiry
// Inquiries provide a device setting result, terminated with a command prompt.
// No specific 'ok/fail' result shown, only ERR or requested response.
// Results placed into global responsebuffer
//
// Parameters: 
// Command        The inquiry-command to send
// pBuffer        pointer to a buffer for the response
// bufsize        size of the buffer
//
// Returns true on command success, false on failure.
boolean WiFlySerial::SendInquiry( char *Command, char* pBuffer, const int bufsize) {

  boolean bSendInquiry = false;
  bSendInquiry = SendCommand(Command,  szWiFlyPrompt, pBuffer, bufsize, true);
  // should trim to returned result less ExpectedPrompt
  
  return bSendInquiry;
    
}
// SendInquiry
// Inquiries provide a device setting result, terminated with a command prompt.
// No specific 'ok/fail' result shown, only ERR or requested response.
// Results placed into global responsebuffer
//
// Parameters: 
// Command        The inquiry-command to send
//
// Returns true on command success, false on failure.
boolean WiFlySerial::SendInquiry( char *Command ) {
  char InquiryBuffer[RESPONSE_BUFFER_SIZE];

  boolean bSendInquiry = false;
  bSendInquiry = SendCommand(Command,  szWiFlyPrompt, InquiryBuffer, RESPONSE_BUFFER_SIZE, true);
  // should trim to returned result less ExpectedPrompt
  
  return bSendInquiry;
    
}

// exitCommandMode
// Exits from WiFly command mode.
//
// Watch the NSS for further traffic.
//
// Parameters: 
// None
// Returns true on command success, false on failure.
boolean WiFlySerial::exitCommandMode() {

  char szCmd[INDICATOR_BUFFER_SIZE]; // exit command is short
  char szResponse[INDICATOR_BUFFER_SIZE]; // small buffer for result

  bWiFlyInCommandMode = !SendCommand( GetBuffer_P(STI_WIFLYDEVICE_LEAVE_CMD_MODE, szCmd, INDICATOR_BUFFER_SIZE),
                      "EXIT",
                      szResponse, INDICATOR_BUFFER_SIZE, false );    
                      
  bWiFlyInCommandMode = false;
  return bWiFlyInCommandMode;
}

// showNetworkScan
// Displays list of available WiFi networks.
//
// Parameters: 
// pNetScan    Buffer for scan results (should be large)
// buflen      length of buffer
char* WiFlySerial::showNetworkScan( char* pNetScan, const int buflen) {
  
  SendCommand("scan","'", pNetScan, buflen, true, JOIN_WAIT_TIME, true, false) ;
  
  return pNetScan;
  
}


// openConnection
// Opens a TCP connection to the provided URL and port (defaults to 80)
//
// Parameters:
// pURL      IP or dns name of server to connect to.
// iPort     Server's port number for connection
//
// Returns: true on success, false on failure.
// Note that opened ports can be closed externally / lost connection at any time.
// Opening a connection switches to Data mode from Command mode.
//
// Note: Open and Scan each generate a version-prompt BEFORE results, not after.
boolean WiFlySerial::openConnection(const char* pURL, const int iPort , const int iWaitTime) {
  char bufOpen[INDICATOR_BUFFER_SIZE];
  char bufCommand[COMMAND_BUFFER_SIZE];
  
  memset (bufCommand, '\0', COMMAND_BUFFER_SIZE);
  strcpy (bufCommand, "open ");
  strcat (bufCommand, pURL);
  strcat (bufCommand, " ");
  itoa( iPort, strchr(bufCommand, '\0'), 10);
  bWiFlyConnectionOpen = SendCommand(bufCommand,WiFlyFixedPrompts[WIFLY_MSG_OPEN], bufOpen, INDICATOR_BUFFER_SIZE, false, iWaitTime , true, false); 
  
  return bWiFlyConnectionOpen;

}

// closeConnection
// closes an open connection
//
// returns true on closure, false on failure to close.
boolean WiFlySerial::closeConnection() {
    char bufClose[COMMAND_BUFFER_SIZE];
    bWiFlyConnectionOpen = false;
   return SendCommand("close",WiFlyFixedPrompts[WIFLY_MSG_CLOSE], bufClose, COMMAND_BUFFER_SIZE, false, 2000);

}


// GetMAC
// Returns WiFly MAC address
//
// Parameters: 
// bufMAC    buffer for MAC address
// buflen    length of buffer (should be at least 18 chars)
// Returns:  pointer to supplied buffer MAC address, or empty string on failure.
// Format expected: Mac Addr=xx:xx:xx:xx:xx:xx
char* WiFlySerial::GetMAC(char* pbuf, int buflen) {
  return ExtractDetail( STI_WIFLYDEVICE_GET_MAC, pbuf, buflen, "Addr=", "\r" ) ;
}

// GetIP
// Returns WiFly IP address
//
// Parameters
// bufIP     buffer for IP address
// buflen    length of buffer (should be at least 18 chars for IPv4 and longer for IPv6)
// Returns:  pointer to supplied buffer with IP address, will be empty string on failure.
// 
char* WiFlySerial::GetIP(char* pbuf, int buflen) {
  return ExtractDetail( STI_WIFLYDEVICE_GET_IP_DETAILS, pbuf, buflen, "IP=", "\r" ) ;
}

// GetNetMask
// Returns WiFly Netmask
//
// Parameters
// buf     buffer for Netmask 
// buflen    length of buffer (should be at least 18 chars for IPv4 and longer for IPv6)
// Returns:  pointer to supplied buffer with GW address, will be empty string on failure.
char* WiFlySerial::GetNetMask(char* pbuf, int buflen) {
  return ExtractDetail( STI_WIFLYDEVICE_GET_IP_DETAILS, pbuf, buflen, "NM=", "\r" ) ;
}


// GetGateway
// Returns WiFly Gateway address
//
// Parameters
// bufGW     buffer for IP address
// buflen    length of buffer (should be at least 18 chars for IPv4 and longer for IPv6)
// Returns:  pointer to supplied buffer with GW address, will be empty string on failure.
char* WiFlySerial::GetGateway(char* pbuf, int buflen) {
  return ExtractDetail( STI_WIFLYDEVICE_GET_IP_DETAILS, pbuf, buflen, "GW=", "\r" ) ;
}


// GetDNS
// Returns WiFly DNS address
//
// Parameters
// bufDNS    buffer for IP address
// buflen    length of buffer (should be at least 18 chars for IPv4 and longer for IPv6)
// Returns:  pointer to supplied buffer with DNS address, will be empty string on failure.
char* WiFlySerial::GetDNS(char* pbuf, int buflen) {
  return ExtractDetail( STI_WIFLYDEVICE_GET_DNS_DETAILS, pbuf, buflen, "DNS=", "\r" ) ;
  
}

// GetSSID
// Returns current SSID
//
// Parameters
// bufSSID   buffer for SSID
// buflen    length of buffer (should be at least 18 chars for IPv4 and longer for IPv6)
// Returns:  pointer to supplied buffer with SSID, will be empty string on failure.
// 
char* WiFlySerial::GetSSID(char* pbuf, int buflen) {
  return ExtractDetail( STI_WIFLYDEVICE_GET_WLAN, pbuf, buflen, "SSID=", "\r" ) ;
}

// GetRSSI
// Returns current RSSI
//
// Parameters
// pbuf      buffer for RSSI
// buflen    length of buffer 
// Returns:  pointer to supplied buffer with RSSI, will be empty string on failure.
// 
char* WiFlySerial::GetRSSI(char* pbuf, int buflen) {
  return ExtractDetail( STI_WIFLYDEVICE_GET_RSSI, pbuf, buflen, "RSSI=", "\r" ) ;
}

// GetBattery
// Returns current Battery voltage
//
// Parameters
// pbuf      buffer for voltage
// buflen    length of buffer 
// Returns:  pointer to supplied buffer with battery voltage, will be empty string on failure.
// 
char* WiFlySerial::GetBattery(char* pbuf, int buflen) {
  return ExtractDetail( STI_WIFLYDEVICE_GET_BATTERY, pbuf, buflen, "Batt=", "\r" ) ;
}

// GetDeviceID
// Returns current DeviceID
//
// Parameters
// bufSSID   buffer for DeviceID
// buflen    length of buffer (should be at least 18 chars for IPv4 and longer for IPv6)
// Returns:  pointer to supplied buffer with DeviceID, will be empty string on failure.
// 
char* WiFlySerial::GetDeviceID(char* pbuf, int buflen) {
  return ExtractDetail( STI_WIFLYDEVICE_GET_WLAN, pbuf, buflen, "DeviceID=", "\r" ) ;
}


// GetTime
// Returns (in milliseconds) time since bootup or Unix epoch if NTP server updated.
//
// Parameters: 
// Returns:  32-bit value.
// Format expected: RTC=tttttttt ms
unsigned long WiFlySerial::GetTime() {
  char bufTimeSerial[COMMAND_BUFFER_SIZE];
  
  return atol(ExtractDetail( STI_WIFLYDEVICE_GET_TIME, bufTimeSerial, COMMAND_BUFFER_SIZE, "RTC=", "\r" ) );
}


// ExtractDetail
// Returns substring from a response.
//
// Parameters: 
// idxCommand     StringID of command
// pDetail        pointer to destination buffer
// buflen         length of destination buffer
// pFrom          String to extract AFTER
// pTo            String to extract UNTIL
//
// Returns:       pointer to destination buffer
char* WiFlySerial::ExtractDetail(const int idxCommand, char* pDetail, int buflen, const char* pFrom, const char* pTo) {
  char bufCmd[COMMAND_BUFFER_SIZE];
  GetBuffer_P(idxCommand, bufCmd, COMMAND_BUFFER_SIZE);
  return ExtractDetail( bufCmd, pDetail, buflen, pFrom, pTo);
    
}

// ExtractDetail
// Returns substring from a response.
//
// Parameters: 
// pCommand       pointer to command
// pDetail        pointer to destination buffer
// buflen         length of destination buffer
// pFrom          String to extract AFTER
// pTo            String to extract UNTIL
//
// Returns:       pointer to destination buffer
char* WiFlySerial::ExtractDetail(char* pCommand, char* pDetail, int buflen, const char* pFrom, const char* pTo) {
  char* pEndToken = NULL;
  char ch;
    
  //send command and ignore results up to after pFrom
  SendCommand(pCommand,  
             (char*) pFrom,
             pDetail,
             buflen,
             false,  DEFAULT_WAIT_TIME, false  );
   // then collect results up to after pTo.
  ScanForPattern(pDetail, buflen, pTo, true,  DEFAULT_WAIT_TIME  );                           
  
  // trim result to not include end token.
  
  if ( (pEndToken = strstr(pDetail, pTo) ) != NULL) {
     *pEndToken = '\0';
  }
  
  // clear buffer of remaining characters
  ScanForPattern(strchr(pDetail,'\0')+1, buflen - strlen(pDetail) -1 , "\0\0", false,  1000  );                           
//   while ( uart.available() > 0 ) {
//     ch = uart.read();
//     DebugPrint(ch);
//   }
//
  
  return pDetail;
}

// GetLibraryVersion
// Returns WiFly Driver Library version
//
// Parameters 
// pDetail        pointer to destination buffer
// buflen         length of destination buffer
// Returns:  pointer to supplied buffer with library version; empty string on failure.
// 
char* WiFlySerial::GetLibraryVersion(char* pbuf, int buflen) {
  return GetBuffer_P( STI_WIFLYDEVICE_LIBRARY_VERSION ,pbuf, buflen) ;
}


// isConnected
// Returns true if currently connected to Access Point.
//
// Parameters: None
// Returns:  IP netmask, or empty string on failure.
boolean WiFlySerial::isConnected() {
  boolean bReturn = false;
  char buf[INDICATOR_BUFFER_SIZE];
  
  ExtractDetail( STI_WIFLYDEVICE_GET_IP_DETAILS, buf, INDICATOR_BUFFER_SIZE, "F=", "\r" ) ;
  bReturn = ( strcmp(buf,"UP" ) == 0 ? true : false ) ;
    
  return bReturn;
       
}

// ExtractLineFromBuffer
// Returns string extracted from provided buffer.
//
//
// Parameters: 
// idString         StringID of command to send 
// pBuffer          pointer to provided buffer
// bufsize          expected size of required buffer
// pStartPattern    pointer to null-terminated string identifying the start of desired line
// chTerminator     character to terminate desired line.

// Returns:  pointer to within provided buffer, with result or empty string on failure.
char* WiFlySerial::ExtractLineFromBuffer(const int idString,  char* pBuffer, const int bufsize, const char* pStartPattern, const char* pTerminator) {
  char* pStart;
  char* pTerm;
  boolean bOk = false;
  char szCommand[COMMAND_BUFFER_SIZE];
  char* pResponse = pBuffer;
   
  if ( !SendInquiry( GetBuffer_P(idString, szCommand, COMMAND_BUFFER_SIZE) , pBuffer, bufsize) ) {
    bOk = false;
  } else {
    pStart= strstr(pBuffer, pStartPattern);
    if (pStart != NULL ) {
      // Move pointer past the start pattern
      pStart += strlen(pStartPattern);
      pResponse = pStart;
    }
    pTerm = strstr( pStart, pTerminator);
    if (pTerm == NULL ) {
      bOk=false;
    } else {
      *(pTerm) = '\0';
      bOk = true;
    } // if end-of-line found
  
  }
  if (!bOk) {
    *(pResponse) = '\0';
  }
  return pResponse;
}



// leave
// Disconnects from current WIFI lan
//
// Parameters: 
//
// Returns true on command success, false on failure.
boolean WiFlySerial::leave() {

  boolean bSendLeave = false;
  char szCmd[COMMAND_BUFFER_SIZE];
  char szReply[INDICATOR_BUFFER_SIZE];
//  char szBuffer[RESPONSE_BUFFER_SIZE];
  
  bSendLeave = SendCommand(GetBuffer_P(STI_WIFLYDEVICE_LEAVE, szCmd, COMMAND_BUFFER_SIZE),  
                           GetBuffer_P(STI_WIFLYDEVICE_DEAUTH, szReply, INDICATOR_BUFFER_SIZE),
                           szCmd,  
                           COMMAND_BUFFER_SIZE, 
                           false );
  
  return bSendLeave;
    
}

boolean WiFlySerial::setSSID( const char* pSSID){

  return issueSetting( STI_WIFLYDEVICE_SET_SSID, pSSID );

}


boolean WiFlySerial::setPassphrase( const char* pPassphrase) {
 
  return issueSetting( STI_WIFLYDEVICE_SET_PASSPHRASE, pPassphrase );

 }


// Sets NTP server address
boolean WiFlySerial::setNTP(const char* pNTP) {
  
  return issueSetting( STI_WIFLYDEVICE_SET_NTP, pNTP );
  
 }

// Sets frequency for NTP updates
boolean WiFlySerial::setNTP_Update_Frequency(const char* pNTP_Update) {
  
  return issueSetting( STI_WIFLYDEVICE_SET_NTP_ENABLE, pNTP_Update );
}

// Sets WiFly DNS name
boolean WiFlySerial::setDeviceID( const char* pDeviceID) {
 
  return issueSetting( STI_WIFLYDEVICE_SET_DEVICEID, pDeviceID );

}

// issueSetting
// Issues a WiFly setting command
// Parameters:
// IdxCommand    Index into string table of command
// pParam        null-terminated string of parameter. 
//               Command and parameter must be less than COMMAND_BUFFER_SIZE
//
// Returns - true on Command success, false on fail.
boolean WiFlySerial::issueSetting( int idxCommand, const char* pParam) {
 
  char szReply[INDICATOR_BUFFER_SIZE];
//  char szIndicator[INDICATOR_BUFFER_SIZE];
  char szBuffer[COMMAND_BUFFER_SIZE];
  
  GetBuffer_P(idxCommand,szBuffer, COMMAND_BUFFER_SIZE );
  strncat( szBuffer, pParam, COMMAND_BUFFER_SIZE - strlen(szBuffer) );
    
  return SendCommand( szBuffer, WiFlyFixedPrompts[WIFLY_MSG_AOK], szReply,  INDICATOR_BUFFER_SIZE, true );
}

// SetUseDCHP
// Sets DHCP ON or OFF 

boolean WiFlySerial::setUseDHCP(const boolean bDHCP) {

  return issueSetting( STI_WIFLYDEVICE_SET_DHCP, ( bDHCP ? " 3" : " 0" ) );
}

// SetIP
// Sets static IP address
// Parameters:
// pIP      null-terminated character string of the IP address e.g. '192.168.1.3'
boolean WiFlySerial::setIP( const char* pIP) {

  return issueSetting( STI_WIFLYDEVICE_SET_IP, pIP );
}

// SetNetMask
// Sets static IP netmask
// Parameters:
// pNM      null-terminated character string of the netmask e.g. '255.255.255.0'
boolean WiFlySerial::setNetMask( const char* pNM) {

  return issueSetting( STI_WIFLYDEVICE_SET_NETMASK, pNM );
}

// SetGateway
// Sets static Gateway address
// Parameters:
// pGW      null-terminated character string of the Gateway address e.g. '192.168.1.254'
boolean WiFlySerial::setGateway( const char* pGW) {

  return issueSetting( STI_WIFLYDEVICE_SET_GATEWAY, pGW );
}

// SetDNS
// Sets static DNS address
// Parameters:
// pDNS      null-terminated character string of the DNS address e.g. '192.168.1.1'
boolean WiFlySerial::setDNS( const char* pDNS) {

  return issueSetting( STI_WIFLYDEVICE_SET_DNS, pDNS );
}


  
 WiFlySerial::WiFlySerial(byte pinReceive, byte pinSend) : uart (pinReceive, pinSend) {
  
  //   
  bWiFlyInCommandMode = false;
  strcpy(szWiFlyPrompt, ">");
  
    // ensure a default sink
  pDebugChannel = NULL;
  

  
  uart.begin(9600);
  
}


#define SOFTWARE_REBOOT_RETRY_ATTEMPTS 5

void WiFlySerial::reboot() {
    char szCommand[COMMAND_BUFFER_SIZE];

  /*
   */

  DebugPrint("reboot");

  if (!SendCommand( "reboot" ,   "AOK")) {
    DebugPrint( GetBuffer_P(STI_WIFLYDEVICE_ERR_START_FAIL, szCommand, COMMAND_BUFFER_SIZE));
    while (1) {}; // Hang. TODO: Handle differently?
  }
}

// join
// Parameters: None
// Joins a network with previously supplied setSSID and passphrase.
//
// returns true on success, false on failure
boolean WiFlySerial::join() {

  char szSSID[COMMAND_BUFFER_SIZE];
  GetSSID( szSSID, COMMAND_BUFFER_SIZE );
  
  return join( szSSID );    
}

// join
// Parameters: None
// Joins a network with given SSID and previously-provided passphrase.
//
// returns true on success, false on failure.
// Todo: support spaces in passphrase.
boolean WiFlySerial::join(char* pSSID) {

  boolean bJoined = false;
  char szCmd[COMMAND_BUFFER_SIZE];
  setSSID(pSSID);
  GetBuffer_P(STI_WIFLYDEVICE_INDEX_JOIN, szCmd, COMMAND_BUFFER_SIZE);
  strncat( szCmd, pSSID, COMMAND_BUFFER_SIZE - strlen(szCmd) );
  
  char bufIndicator[INDICATOR_BUFFER_SIZE];
  char bufResponse [RESPONSE_BUFFER_SIZE];
    
  bJoined = SendCommand( szCmd,
                       GetBuffer_P(STI_WIFLYDEVICE_INDEX_ASSOCIATED, bufIndicator, INDICATOR_BUFFER_SIZE),
                       bufResponse, 
                       RESPONSE_BUFFER_SIZE, 
                       true, 
                       JOIN_WAIT_TIME, false);
  
  return bJoined;
    
}


// GetBuffer_P
// Returns pointer to a supplied Buffer, from PROGMEM based on StringIndex provided.
// based on example from http://arduino.cc/en/Reference/PROGMEM

char* WiFlySerial::GetBuffer_P(const int StringIndex, char* pBuffer, int bufSize) {
  
  memset(pBuffer, '\0', bufSize);
  strncpy_P(pBuffer, (char*)pgm_read_word(&(WiFlyDevice_string_table[StringIndex])), bufSize);
  
  return pBuffer; 

}

// setDebugChannel
// Conduit for debug output
// must not be a NewSoftSerial instance as incoming interrupts conflicts with outgoing data.
void WiFlySerial::setDebugChannel( Print* pChannel) {
  pDebugChannel = pChannel; 
}
void WiFlySerial::clearDebugChannel() {
 pDebugChannel = NULL; 
}

void WiFlySerial::DebugPrint( const char* pMessage) {
  if ( pDebugChannel )
    pDebugChannel->println(pMessage);
}
void WiFlySerial::DebugPrint( const int iNumber) {
  if ( pDebugChannel )
    pDebugChannel->println(iNumber);
}
void WiFlySerial::DebugPrint( const char ch) {
  if ( pDebugChannel )
    pDebugChannel->print(ch);
}

