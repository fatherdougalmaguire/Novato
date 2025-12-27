# Introduction
Novato is a SwiftUI/Swift emulator compatible with the [Microbee](https://www.microbee-mspp.org/wiki/tiki-index.php?page=Microbee) family of home computers.

© Tony Sanchez 2025 All Rights Reserved

<div align=left>
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/9c6fc378-3184-44ff-a0e7-11361103483c"/>
</div>

It runs on MacOS Sonoma, MacOS Sequoia and MacOS Tahoe.

Universal binaries can be found in the [Releases](https://github.com/fatherdougalmaguire/Novato/releases) section.

At some point,  I may build iOS and iPadOS versions off the same codebase.

And if I get super enthusiastic,  versions for Windows, Linux and WebAssembly.

## Ackowledgements

The MicroWorld Basic v5.22e ROM and the MicroBee Font ROM are used within this emulator have been made available with the kind permission of Ewan J. Wordsworth of [Microbee Technology](http://www.microbeetechnology.com.au/)

## Current status

Initially I am looking to emulate the [Microbee 32IC](https://www.microbee-mspp.org/wiki/tiki-index.php?page=Microbee+Series+1+Models#Microbee_16K_32K_IC) model.

This emulator is still in what could charitably called *alpha* status.

* You can start and stop the emulator via button control.
* You can quit the emulator via button control.
* A small number of Z80 instructions are decoded.
* Current register statuses are displayed.
* The first 256 bytes of memory from the currrent PC value are displayed as hex and ASCII.
* The screen buffer is output to the display using a metal shader.
* Shader will automatically scale the output resolution to the same display size.
* Shader can magnify output up to 3x
* Rudimentary 6545 functionality is emulated:
  - Supports definition of the nummber of display rows and columns.
  - Supports definition of cursor position.
  - Supports selection of Character ROM address.
  - Supports selection of cursor start and end scanline.
  - Supports cursor flash mode ( On/Off/slow flash/fast flash ).
* Working MMU has been implemented
  - An arbitrary number of memory devices can be defined
  - Each memory device can be tagged as read-only or read/write
  - Devices can be switched into and out of memory ranges in RAM
  - Memory ranges can have different read and write devices.  This allows the capability to switch font rom and colour ram into memory
* Splash screen displaying the application logo as PCG characters

## On the to-do list

* Bank switching code to access font rom and colour ram
* Colour support in shader
* Full emulator of Z80 including undocumented instructions
* Capture keyboard input
* Cassette load/save functionality
* Sound output

## Emulator screenshots

### Splash Screen

<img width="2184" height="1752" alt="image" src="https://github.com/user-attachments/assets/bfb79869-5219-453f-8923-a18545b397f2" />

### Status window

<img width="2024" height="1402" alt="image" src="https://github.com/user-attachments/assets/c1e3d2a7-12fe-4920-88c1-a79f214a0603" />

## Demo Screens

Below are demo screens for the three video modes ( 64x16, 80x24, 40x24 ).  
These screens are drawn using internally loaded Z80 assembler.
The emulator is **NOT** currently booting BASIC nor CP/M

### 64 columns x 16 rows 
<img width="2272" height="1840" alt="image" src="https://github.com/user-attachments/assets/df230844-a809-446d-95f1-64558da7077f" />

### 80 columns x 24 rows 
<img width="2272" height="1840" alt="image" src="https://github.com/user-attachments/assets/8d3923a5-c4fa-4062-bd3d-59c4ec5dabf9" />

### 40 columns x 24 rows 
<img width="2272" height="1840" alt="image" src="https://github.com/user-attachments/assets/d7ac5e81-c878-46c8-b2b6-b99dfb4bb360" />







