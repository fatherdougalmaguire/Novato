import Foundation

class CRTC
{
    var crtcRegisters = CRTCRegisters()
    
    func ReadStatusRegister() -> UInt8
    {
     return crtcRegisters.StatusRegister
    }
    
    func WriteRegister(RegNum:UInt8, RegValue:UInt8)
    {
        switch RegNum
        {
        case 0: crtcRegisters.R0_HorizTotalMinus1 = RegValue
        case 1: crtcRegisters.R1_HorizDisplayed = RegValue
        case 2: crtcRegisters.R2_HorizSyncPosition = RegValue
        case 3: crtcRegisters.R3_VSynchHSynchWidths = RegValue
        case 4: crtcRegisters.R4_VertTotalMinus1 = RegValue
        case 5: crtcRegisters.R5_VertTotalAdjust = RegValue
        case 6: crtcRegisters.R6_VertDisplayed = RegValue
        case 7: crtcRegisters.R7_VertSyncPosition = RegValue
        case 8: crtcRegisters.R8_ModeControl = RegValue
        case 9: crtcRegisters.R9_ScanLinesMinus1 = RegValue
        case 10: crtcRegisters.R10_CursorStart = RegValue
        case 11: crtcRegisters.R11_CursorEnd = RegValue
        case 12: crtcRegisters.R12_DisplayStartAddrH = RegValue
        case 13: crtcRegisters.R13_DisplayStartAddrL = RegValue
        case 14: crtcRegisters.R14_CursorPositionH = RegValue
        case 15: crtcRegisters.R15_CursorPositionL = RegValue
        case 16: crtcRegisters.R16_LightPenRegH  = RegValue
        case 17: crtcRegisters.R17_LightPenRegL = RegValue
        case 18: crtcRegisters.R18_UpdateAddressRegH = RegValue
        case 19: crtcRegisters.R19_UpdateAddressRegL = RegValue
        default: break
        }
    }
    
    func ReadRegister(RegNum:UInt8) -> UInt8
    {
        switch RegNum
        {
        case 0: return crtcRegisters.R0_HorizTotalMinus1
        case 1: return crtcRegisters.R1_HorizDisplayed
        case 2: return crtcRegisters.R2_HorizSyncPosition
        case 3: return crtcRegisters.R3_VSynchHSynchWidths
        case 4: return crtcRegisters.R4_VertTotalMinus1
        case 5: return crtcRegisters.R5_VertTotalAdjust
        case 6: return crtcRegisters.R6_VertDisplayed
        case 7: return crtcRegisters.R7_VertSyncPosition
        case 8: return crtcRegisters.R8_ModeControl
        case 9: return crtcRegisters.R9_ScanLinesMinus1
        case 10: return crtcRegisters.R10_CursorStart
        case 11: return crtcRegisters.R11_CursorEnd
        case 12: return crtcRegisters.R12_DisplayStartAddrH
        case 13: return crtcRegisters.R13_DisplayStartAddrL
        case 14: return crtcRegisters.R14_CursorPositionH
        case 15: return crtcRegisters.R15_CursorPositionL
        case 16: return crtcRegisters.R16_LightPenRegH
        case 17: return crtcRegisters.R17_LightPenRegL
        case 18: return crtcRegisters.R18_UpdateAddressRegH
        case 19: return crtcRegisters.R19_UpdateAddressRegL
        default: return 0
        }
    }
}

//64x16
//6545 CRTC Registers                Hex  Dec    Binary
//------------------------------------------------------
//0x00 (00d) Horiz Total-1           6b   107   01101011
//0x01 (01d) Horiz Displayed         40    64   01000000
//0x02 (02d) Horiz Sync Position     51    81   01010001
//0x03 (03d) VSYSNC, HSYNC Widths    37    55   00110111
//0x04 (04d) Vert Total-1            12    18   00010010
//0x05 (05d) Vert Total Adjust       09     9   00001001
//0x06 (06d) Vert Displayed          10    16   00010000
//0x07 (07d) Vert Sync Position      11    17   00010001
//0x08 (08d) Mode Control            48    72   01001000
//0x09 (09d) Scan Lines-1            0f    15   00001111
//0x0a (10d) Cursor Start            6f   111   01101111
//0x0b (11d) Cursor End              0f    15   00001111
//0x0c (12d) Display Start Addr (H)  00     0   00000000
//0x0d (13d) Display Start Addr (L)  00     0   00000000
//0x0e (14d) Cursor Position (H)     00     0   00000000
//0x0f (15d) Cursor Position (L)     00     0   00000000
//0x10 (16d) Light Pen Reg (H)       00     0   00000000
//0x11 (17d) Light Pen Reg (L)       00     0   00000000
//0x12 (18d) Update Address Reg (H)  00     0   00000000
//0x13 (19d) Update Address Reg (L)  00     0   00000000

//80x24
//6545 CRTC Registers                Hex  Dec    Binary
//------------------------------------------------------
//0x00 (00d) Horiz Total-1           6b   107   01101011
//0x01 (01d) Horiz Displayed         50    80   01010000
//0x02 (02d) Horiz Sync Position     5c    92   01011100
//0x03 (03d) VSYSNC, HSYNC Widths    37    55   00110111
//0x04 (04d) Vert Total-1            1b    27   00011011
//0x05 (05d) Vert Total Adjust       05     5   00000101
//0x06 (06d) Vert Displayed          18    24   00011000
//0x07 (07d) Vert Sync Position      1a    26   00011010
//0x08 (08d) Mode Control            48    72   01001000
//0x09 (09d) Scan Lines-1            0a    10   00001010
//0x0a (10d) Cursor Start            2a    42   00101010
//0x0b (11d) Cursor End              0a    10   00001010
//0x0c (12d) Display Start Addr (H)  20    32   00100000
//0x0d (13d) Display Start Addr (L)  00     0   00000000
//0x0e (14d) Cursor Position (H)     00     0   00000000
//0x0f (15d) Cursor Position (L)     00     0   00000000
//0x10 (16d) Light Pen Reg (H)       00     0   00000000
//0x11 (17d) Light Pen Reg (L)       00     0   00000000
//0x12 (18d) Update Address Reg (H)  00     0   00000000
//0x13 (19d) Update Address Reg (L)  00     0   00000000
