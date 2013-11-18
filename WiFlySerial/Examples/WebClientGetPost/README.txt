README for WebClientGetPost

This example demonstrates GET and POST functionality from an Arduino-WiFly combination.
It is intended for use with the WiFly breakout boards or with the WiFly chip directly, 
without SPI support.

Installation:
1. Install the WiFlySerial library per its instructions, found in the WiFlySerial README.
2. Ensure you have a accessible (preferably local) webserver with:
   1. an accessible cgi-bin folder.
   2. php support enabled.
   3. permissions to copy and execute php scripts installed in the cgi-bin folder (or its equivalent).
3. Copy the userprog_get.php and userprog_post.php to the cgi-bin (or equivalent) folder.
4. Edit the WebClientGetPost file and update at least the following:
 * MY_WIFI_SSID
 * MY_WIFI_PASSPHRASE to your local wifi values.
 * MY_SERVER_GET
 * MY_SERVER_GET_URL
 * MY_SERVER_POST
 * MY_SERVER_POST_URL to your local server values.

 Note that MY_SERVER_GET and MY_SERVER_POST should be IP's or URLs of your tame web server, 
  and will likely both be the same value.
 
 MY_SERVER_GET_URL and MY_SERVER_POST_URL will likely be /cgi-bin/userprog_get.php and /cgi-bin/userprog_post.php , although your scenario may differ.

5. Verify your installation by aiming your browser to http://<MY_SERVER_GET>/<MY_SERVER_GET_URL> 
   (substituting your values of course...).
6. Make sure your WiFly is connected...
7. Compile, upload and watch the console for demo output!
8. Enjoy!  
9. Constructive feedback is welcome at the Arduinology website.

This README is not an Apache2 or IIS configuration guide.  Please review appropriate resources to install, configure and operate your tame webserver of choice.



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

