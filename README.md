# Intelligent Agent for Remediating Database Blockings
Intelligent Agent built using ECLiPSe CLP interface and faster/lighter framework using C with embedded Lua.

## Requirements
Manual requirements (if not using automated build script):

* Download and install Eclipse CLP: http://eclipseclp.org/download.html
  - Installation steps for Unix: http://eclipseclp.org/Distribution/Builds/7.0_43/x86_64_linux/README_UNIX
  - Installation steps for Mac OSX: http://eclipseclp.org/Distribution/Builds/7.0_43/x86_64_linux/README_MACOSX
* Download and install Lua 5.3: https://www.lua.org/download.html

## Compiling the agent
Manual compilation (if not using automated build script):

Based on your environment, please change the paths accordingly in these export commands and run them.
* $ export ARCH=x86_64_macosx
* $ export ECLIPSEDIR=/Users/tpham103/Desktop/CLPEclipse
* $ export DYLD_LIBRARY_PATH=/Users/tpham103/Desktop/CLPEclipse/lib/x86_64_macosx
* $ export LUADIR=/usr/local/Cellar/lua/5.3.5_1

After exporting paths, run this command in the agent root folder to compile:
* $ gcc -o BlockingDetect -Wall -I$LUADIR/include/lua5.3 -llua5.3 -I$ECLIPSEDIR/include/$ARCH -L$ECLIPSEDIR/lib/$ARCH -leclipse BlockingDetect.c

## How to change Configurations
To specify credentials and DNS for database connection, please modify the file **config.lua.sample** and then rename it to **config.lua**

To specify mailing list recipient, please modify the rcpt list in the file **alert_smtp.lua**.

## Running the agent
Next, run this command to start the agent:
* $ ./BlockingDetect [param1]

where param1 is the name of the main luascript you want to run. We currently have two:
* BlockingDetectTextfile.lua (for testing)
* BlockingDetectProd.lua (for production)
