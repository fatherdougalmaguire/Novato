# Introduction
Novato is a SwiftUI/Swift emulator compatible with the [Microbee 32IC home computer](https://www.microbee-mspp.org/wiki/tiki-index.php?page=Microbee+Series+1+Models#Microbee_16K_32K_IC)

Requires MacOS Sonoma or later

The MicroWorld Basic v5.22e ROM and the MicroBee Font ROM are used in this emulator with kind permission from Ewan J. Wordsworth of [Microbee Technology](http://www.microbeetechnology.com.au/)

© Tony Sanchez 2025 All Rights Reserved

## Current status

This emulator is still in what could charitablity called *alpha* status.

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

## On the to-do list

* Capture keyboard input
* Sound output
* Cassette load/save functionality
* Full emulator of Z80 including undocumented instructions

## Demo Screens

Below are demo screens for the three video modes ( 64x16, 80x24, 40x24 ).  
These screens are drawn using internally loaded Z80 assembler.
The emulator is **NOT** currently booting BASIC nor CP/M

### 64 columns x 16 rows 
<img width="2272" height="1840" alt="image" src="https://github.com/user-attachments/assets/df230844-a809-446d-95f1-64558da7077f" />

### 80 columns x 24 rows 
<img width="2272" height="1840" alt="image" src="https://github.com/user-attachments/assets/8d3923a5-c4fa-4062-bd3d-59c4ec5dabf9" />

### 40 columns x 24 rows 
<img width="2272" height="1840" alt="image" src="https://github.com/user-attachments/assets/fd0b64ae-3cbe-4dbf-abd2-a24640c0e67c" />

### The real emulator status window

<img width="2024" height="1402" alt="image" src="https://github.com/user-attachments/assets/c1e3d2a7-12fe-4920-88c1-a79f214a0603" />






