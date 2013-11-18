WiFly Driver for the Arduino platform
Provides WiFi wireless communications for Arduino-based systems.


============
TRADEMARKS
============
"WiFly", "RN-131","RN-171" "RN-174" are trademarks / tradenames of Roving Networks Inc.
"Arduino" is a trademark of Arduino LLC.
Other trademarks referenced are the property of their respective owners.

============
LICENSE
============

(C) 2011, Tom Waldock

   Permission is hereby granted, free of charge, to any person
   obtaining a copy of this software and associated documentation
   files (the "Software"), to deal in the Software without
   restriction, including without limitation the rights to use, copy,
   modify, merge, publish, distribute, sublicense, and/or sell copies
   of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.

============
INSTALLATION
============

Library version:
Copy the WiFlySerial files and Examples folders to a new folder in your Arduino Libraries path
(e.g. /usr/share/arduino/libraries/WiFlySerial)
Restart the IDE, the examples and libraries should then become available.


WebTime.pde is a simple example webserver that shows the current time.
Aim your browser at the Arduino+WiFly's IP address for the current UTC time.
Add "/status" to the URL for additional status items.

WiFly_Test.pde is a simple terminal for communicating to and from the WiFly.
It is useful for exploring its features and debugging issues.

=======
SUPPORT
=======

Current code and support forums are available from http://arduinowifly.sourceforge.net.
Additional commentary on http://www.arduinology.tumblr.com


=======
HISTORY
=======
*** 2011-Apr-07 Removed bug in ExtractDetail introduced yesterday.

*** Initial library release.

2011-Apr-06 Added status methods, corrected memory handling, re-packaged for library.

*** Initial release.
