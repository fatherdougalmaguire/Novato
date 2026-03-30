# Novato

![macOS](https://img.shields.io/badge/platform-macOS-000000?logo=apple&logoColor=white&style=flat-square)
![SwiftUI](https://img.shields.io/badge/SwiftUI-F05138?style=flat-square&logo=swift&logoColor=white) 
![Universal Binary](https://img.shields.io/badge/architecture-universal-007AFF?style=flat-square&logo=apple&logoColor=white)
![Signed](https://img.shields.io/badge/security-Signed%20%26%20Notarized-brightgreen?logo=apple&style=flat-square)
![Latest Version](https://img.shields.io/github/v/release/fatherdougalmaguire/novato?style=flat-square&color=blue)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Novato is a SwiftUI/Swift emulator compatible with the [Microbee](https://www.microbee-mspp.org/wiki/tiki-index.php?page=Microbee) family of home computers.



© Tony Sanchez 2025-2026 All Rights Reserved
<div>
  <br>
</div>
<div align=left>
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/9c6fc378-3184-44ff-a0e7-11361103483c"/>
</div>
<div>
  <br>
</div>

> For those that are curious, novato is a Spanish word denoting novice, beginner or rookie.
>
> It also means **newbie**.  
> So I couldn't resist the obvious dad joke.
<div>
  <br>
</div>
It runs on MacOS Sonoma, MacOS Sequoia and MacOS Tahoe.

Universal binaries can be found in the [Releases](https://github.com/fatherdougalmaguire/Novato/releases) section.

At some point,  I may build iOS and iPadOS versions off the same codebase.  
And if I get super enthusiastic,  versions for Windows, Linux and WebAssembly.

## Acknowledgements

The MicroWorld Basic v5.22e ROM and the MicroBee Font ROM have been bundled with the kind permission of Ewan J. Wordsworth of [Microbee Technology](http://www.microbeetechnology.com.au/)

## Current status

Initially I am looking to emulate the [Microbee 32IC](https://www.microbee-mspp.org/wiki/tiki-index.php?page=Microbee+Series+1+Models#Microbee_16K_32K_IC) model.

This emulator is still in what could charitably called *alpha* status.

### UI controls
* You can start and stop the emulator via button control.
* You can restart the emulator via button control.
* You can quit the emulator via button control.
* There is a splash screen displaying the application logo as PCG characters
* You can choose to start the emulator automatically or go to the splash screen first
* Current register statuses are displayed.
* The first 256 bytes of memory from the currrent PC value are displayed as hex and ASCII.
* The last 16 instructions are decoded and displayed
* You can define up to 16 breakpoints
* There is now a **Settings** module so you can dynamically set ( and retain ):
  
  - Start-up mode ( automatic or splash screen )
  - Select boot code ( Basic demo, CP/M demo, Viatel demo, Microworld Basic 5.22e )
  - Colour mode
  - Aspect ratio
  - Screen scaling
  - Visible scanline mode
  - Apperance of debug windows
  
### Instruction decoding
* All non-flag affecting instructions are decoded
* Flags are now precomputed for S,P and Z general instructions
* Flags are now precomputed for 8 bit increment and decrement instructions
* A small number of flag affecting instructions are decoded
* t-states are captured

### Display output
* The screen buffer is output to the display using a SwiftUI Shader library .ColorEffect shader
* Rudimentary 6545 functionality is emulated:
  
  - Supports definition of the nummber of display rows and columns.
  - Supports definition of cursor position.
  - Supports selection of Character ROM address.
  - Supports selection of cursor start and end scanline.
  - Supports cursor flash mode ( On/Off/slow flash/fast flash ).

* Shader will automatically scale the output resolution to the same display size.
* Colour support has been added ( green mono, amber mono, blue mono, white mono and non-premium colour )

### Memory
* Working MMU has been implemented
  
  - An arbitrary number of memory devices can be defined
  - Each memory device can be tagged as read-only or read/write
  - Devices can be switched into and out of memory ranges in RAM
  - Memory ranges can have different read and write devices.  This allows the capability to switch font rom and colour ram in and out of memory
    
## On the to-do list

* Test harness for JSON test files ( most likely the [JSMoo single step tests](https://github.com/SingleStepTests/z80) )
* Watch breakpoints for registers and memory locations
* Display PCG characters in the memory dump window
* ROM selection and load
* Machine state saving
* Full emulation of Z80 including undocumented instructions
* Interrupt processing
* Sound output
* Capture keyboard input
* Proper emulator state machine
  
  - rejig the basic state machine to stop the emulator actor burning cycles when paused
    
* Frame based emulation
  
  - rewrite the emulator loop to run 50hz worth of cycles before emitting CPU state to view model
  - rewrite the emulator loop to process interrupts
  - rewrite the emulator loop to fill sound buffer
  - rewrite the emulator loop to trigger vblank update of 6545 for video and keypressed
    
* Cassette load/save functionality

## Emulator screenshots

### Splash Screen

<img width="2272" height="1762" alt="image" src="https://github.com/user-attachments/assets/b1a3c31c-8eac-42bb-b47f-28bfd4c665a4" />

### Breakpoints

<img width="536" height="1232" alt="image" src="https://github.com/user-attachments/assets/df78c080-2505-41b4-b982-9ca47428137f" />

### Port View

<img width="1084" height="1578" alt="image" src="https://github.com/user-attachments/assets/fab9d30d-6937-4fe0-b5e1-b4974aa21e3f" />

### Memory AND Instruction View

<img width="1486" height="1524" alt="image" src="https://github.com/user-attachments/assets/e78bd374-7af8-4057-934d-efb6c90087c1" />

### Register View

<img width="1734" height="924" alt="image" src="https://github.com/user-attachments/assets/4ee67221-22d3-4699-b9c9-dae6de76b8bf" />

## Demo Screens

Below are demo screens for all three video modes ( 64x16, 80x24 and 40x25 ).  
These screens are drawn using internally loaded Z80 assembler.

### 64 columns x 16 rows 

<img width="2272" height="1660" alt="image" src="https://github.com/user-attachments/assets/9a00e753-b8c9-498a-a738-21a67b8665bb" />

### 80 columns x 24 rows 

<img width="2272" height="1762" alt="image" src="https://github.com/user-attachments/assets/da0b5472-400d-4b5b-9e4b-31c0a41e1b85" />

### 40 columns x 25 rows 

<img width="2184" height="1674" alt="image" src="https://github.com/user-attachments/assets/bf22f597-08ff-4a0e-b575-316c8aa3178c" />










