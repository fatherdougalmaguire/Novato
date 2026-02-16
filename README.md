# Introduction
Novato is a SwiftUI/Swift emulator compatible with the [Microbee](https://www.microbee-mspp.org/wiki/tiki-index.php?page=Microbee) family of home computers.

© Tony Sanchez 2025-2026 All Rights Reserved

<div align=left>
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/9c6fc378-3184-44ff-a0e7-11361103483c"/>
</div>

It runs on MacOS Sonoma, MacOS Sequoia and MacOS Tahoe.

Universal binaries can be found in the [Releases](https://github.com/fatherdougalmaguire/Novato/releases) section.

At some point,  I may build iOS and iPadOS versions off the same codebase.
( And if I get super enthusiastic,  versions for Windows, Linux and WebAssembly. )

## Ackowledgements

The MicroWorld Basic v5.22e ROM and the MicroBee Font ROM have been bundled with the kind permission of Ewan J. Wordsworth of [Microbee Technology](http://www.microbeetechnology.com.au/)

## Current status

Initially I am looking to emulate the [Microbee 32IC](https://www.microbee-mspp.org/wiki/tiki-index.php?page=Microbee+Series+1+Models#Microbee_16K_32K_IC) model.

This emulator is still in what could charitably called *alpha* status.

* You can start and stop the emulator via button control.
* You can restart the emulator via button control.
* You can quit the emulator via button control.
* A small number of Z80 instructions are decoded.
* Current register statuses are displayed.
* The first 256 bytes of memory from the currrent PC value are displayed as hex and ASCII.
* ~The last 16 instructions are decoded and displayed~ Disassembly is currently broken.
* The screen buffer is output to the display using a metal shader.
* Shader will automatically scale the output resolution to the same display size.
* Colour support has been added ( green mono, amber mono, blue mono, white mono and colour )
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
  - Memory ranges can have different read and write devices.  This allows the capability to switch font rom and colour ram in and out of memory
* Splash screen displaying the application logo as PCG characters
* Settings module to set
  - Start-up mode ( automatic or splash screen )
  - Select boot code (  Basic demo, CP/M demo, Viatel demo, Microworld Basic 5.22e )
  - Colour mode
  - Aspect ratio
  - Screen scaling

## On the to-do list

* ROM selecton and load
* Machine state saving
* Full emulation of Z80 including undocumented instructions
* Interrupt processing
* Sound output
* Capture keyboard input
* Proper emulator state machine
  - rejig the basic state machine to allow start/pause, step, stop and stopping the emulator actor burning cycles when paused 
* Frame based emulation
  - The emulator now captures t-states
  - rewrite the emulator loop to run 50hz worth of cycles before emitting CPU state to view model
  - rewrite the emulator loop to process interrupts
  - rewrite the emulator loop to fill sound buffer
  - rewrite the emulator loop to trigger vblank update of 6545 for video and keypressed
* Cassette load/save functionality

## Emulator screenshots

### Emulator Window

<img width="2272" height="1762" alt="image" src="https://github.com/user-attachments/assets/b1a3c31c-8eac-42bb-b47f-28bfd4c665a4" />

### Port View

<img width="1084" height="1578" alt="image" src="https://github.com/user-attachments/assets/fab9d30d-6937-4fe0-b5e1-b4974aa21e3f" />

### Memory AND Instruction View

<img width="1486" height="1524" alt="image" src="https://github.com/user-attachments/assets/e78bd374-7af8-4057-934d-efb6c90087c1" />

### Register View

<img width="1734" height="924" alt="image" src="https://github.com/user-attachments/assets/4ee67221-22d3-4699-b9c9-dae6de76b8bf" />

## Demo Screens

Below are demo screens for the three video modes ( 64x16, 80x24, 40x24 ).  
These screens are drawn using internally loaded Z80 assembler.
The emulator is **NOT** currently booting BASIC, CP/M or Viatel ( as you can tell when you try the MicroWorld Basic 5.22e option )

### 64 columns x 16 rows 

<img width="2272" height="1762" alt="image" src="https://github.com/user-attachments/assets/bd0b2fe5-2e51-49bf-b18c-0474af1833bd" />

### 80 columns x 24 rows 

<img width="2272" height="1762" alt="image" src="https://github.com/user-attachments/assets/da0b5472-400d-4b5b-9e4b-31c0a41e1b85" />

### 40 columns x 25 rows 

<img width="2184" height="1674" alt="image" src="https://github.com/user-attachments/assets/bf22f597-08ff-4a0e-b575-316c8aa3178c" />










