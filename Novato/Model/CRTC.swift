import Foundation

class CRTC

{
//    6545 CRTC Registers                Hex  Dec    Binary
//    ------------------------------------------------------
//    0x00 (00d) Horiz Total-1           21    33   00100001    total length of line (displayed and non-displayed cycles (retrace) in CCLK cylces minus 1
//    0x01 (01d) Horiz Displayed         6b   107   01101011    number of characters displayed in a line
//    0x02 (02d) Horiz Sync Position     50    80   01010000    The position of the horizontal sync pulse start in distance from line start
//    0x03 (03d) VSYSNC, HSYNC Widths    58    88   01011000    
//    0x04 (04d) Vert Total-1            37    55   00110111    The number of character lines of the screen minus 1
//    0x05 (05d) Vert Total Adjust       1b    27   00011011    The additional number of scanlines to complete a screen
//    0x06 (06d) Vert Displayed          05     5   00000101    Number character lines that are displayed
//    0x07 (07d) Vert Sync Position      19    25   00011001    Position of the vertical sync pulse in character lines.
//    0x08 (08d) Mode Control            1a    26   00011010
//    0x09 (09d) Scan Lines-1            48    72   01001000    Number of scanlines per character minus 1
//    0x0a (10d) Cursor Start            0a    10   00001010
//    0x0b (11d) Cursor End              09     9   00001001
//    0x0c (12d) Display Start Addr (H)  0a    10   00001010    Bits 8-13 of the start of display memory address
//    0x0d (13d) Display Start Addr (L)  20    32   00100000    Bits 0-7 of the start of display memory address
//    0x0e (14d) Cursor Position (H)     00     0   00000000
//    0x0f (15d) Cursor Position (L)     00     0   00000000
//    0x10 (16d) Light Pen Reg (H)       00     0   00000000
//    0x11 (17d) Light Pen Reg (L)       00     0   00000000
//    0x12 (18d) Update Address Reg (H)  63    99   01100011
//    0x13 (19d) Update Address Reg (L)  63    99   01100011
    var R0_HorizTotalMinus1 : UInt8 = 0x21
    var R1_HorizDisplayed : UInt8 = 0x6b
    var R2_HorizSyncPosition : UInt8 = 0x50
    var R3_VSynchHSynchWidths : UInt8 = 0x58
    var R4_VertTotalMinus1 : UInt8 = 0x37
    var R5_VertTotalAdjust : UInt8 = 0x1b
    var R6_VertDisplayed : UInt8 = 0x05
    var R7_VertSyncPosition : UInt8 = 0x19
    var R8_ModeControl : UInt8 = 0x1a
    var R9_ScanLinesMinus1 : UInt8 = 0x48
    var R10_CursorStart : UInt8 = 0x0a
    var R11_CursorEnd : UInt8 = 0x09
    var R12_DisplayStartAddrH : UInt8 = 0x0a
    var R13_DisplayStartAddrL : UInt8 = 0x20
    var R14_CursorPositionH : UInt8 = 0x00
    var R15_CurorPositionL : UInt8 = 0x00
    var R16_LightPenRegH : UInt8 = 0x00
    var R17_LightPenRegL : UInt8 = 0x00
    var R18_UpdateAddressRegH : UInt8 = 0x63
    var R19_UpdateAddressRegL : UInt8 = 0x63
}
