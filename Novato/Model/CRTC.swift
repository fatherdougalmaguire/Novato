import Foundation

final class CRTC
{
    
    struct CRTCRegisters
    {
        var R0_HorizTotalMinus1 : UInt8 = 0x00                              // Ignored by emulator - Total length of line (displayed and non-displayed cycles (retrace) in CCLK cylces minus 1
        var R1_HorizDisplayed : UInt8 = 0x40                                // Number of characters displayed in a line
        var R2_HorizSyncPosition : UInt8 = 0x00                             // Ignored by emulator - The position of the horizontal sync pulse start in distance from line start
        var R3_VSynchHSynchWidths : UInt8 = 0x00                            // Ignored by emulator
        var R4_VertTotalMinus1 : UInt8 = 0x12                               // The number of character lines of the screen minus 1
        var R5_VertTotalAdjust : UInt8 = 0x00                               // Ignored by emulator - The additional number of scanlines to complete a screen
        var R6_VertDisplayed : UInt8 = 0x10                                 // Number character lines that are displayed
        var R7_VertSyncPosition : UInt8 = 0x00                              // Ignored by emulator - Position of the vertical sync pulse in character lines.
        var R8_ModeControl : UInt8 = 0x00                                   // Ignored by emulator
        var R9_ScanLinesMinus1 : UInt8 = 0x0F                               // Number of scanlines per character minus 1
        var R10_CursorStartAndBlinkMode : UInt8 = (0x01 << 5) & 0b01100000  // Cursor scanline start ( bits 0-4 ) and blink mode ( bits 5 and 6 )  - initialse as no cursor
        var R11_CursorEnd : UInt8 = 0b00000000 & 0b0011111                  // Cursor scanline end ( bits 0-4 )
        var R12_DisplayStartAddrH : UInt8 = 0x00                            // Character Generator Rom start address ( high byte )
        var R13_DisplayStartAddrL : UInt8 = 0x00                            // Character Generator Rom start address ( low byte )
        var R14_CursorPositionH : UInt8 = 0x00                              // Cursor address ( high byte )
        var R15_CursorPositionL : UInt8 = 0x00                              // Cursor address ( low byte )
        var R16_LightPenRegH : UInt8 = 0x00                                 // Ignored by emulator
        var R17_LightPenRegL : UInt8 = 0x00                                 // Ignored by emulator
        var R18_UpdateAddressRegH : UInt8 = 0x00                            // Ignored by emulator
        var R19_UpdateAddressRegL : UInt8 = 0x00                            // Ignored by emulator
        
        var StatusRegister : UInt8 = 0b10000000
        
        var redBackgroundIntensity : UInt8 = 0x00                         // red background intensity 0 = half 1 = full
        var greenBackgroundIntensity : UInt8 = 0x00                       // green background intensity 0 = half 1 = full
        var blueBackgroundIntensity : UInt8 = 0x00                        // blue background intensity 0 = half 1 = full
        
    }
    
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
        case 10: crtcRegisters.R10_CursorStartAndBlinkMode = RegValue
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
        case 10: return crtcRegisters.R10_CursorStartAndBlinkMode
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
