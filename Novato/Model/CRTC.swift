import Foundation

final class CRTC
{
    
    struct crtcRegisters
    {
        var R0 : UInt8 = 0x00                               // Ignored by emulator - Total length of line (displayed and non-displayed cycles (retrace) in CCLK cylces minus 1
        var R1 : UInt8 = 0x40                               // Number of characters displayed in a line - initialise as 64
        var R2 : UInt8 = 0x00                               // Ignored by emulator - The position of the horizontal sync pulse start in distance from line start
        var R3 : UInt8 = 0x00                               // Ignored by emulator
        var R4 : UInt8 = 0x12                               // The number of character lines of the screen minus 1 - initialise as 18
        var R5 : UInt8 = 0x00                               // Ignored by emulator - The additional number of scanlines to complete a screen
        var R6 : UInt8 = 0x10                               // Number character lines that are displayed - initialise as 16
        var R7 : UInt8 = 0x00                               // Ignored by emulator - Position of the vertical sync pulse in character lines.
        var R8 : UInt8 = 0x00                               // Ignored by emulator
        var R9 : UInt8 = 0x0F                               // Number of scanlines per character minus 1 - initialise as 15
        var R10 : UInt8 = 0x20                              // Cursor scanline start ( bits 0-4 ) and blink mode ( bits 5 and 6 )  - initialse as no cursor and scanline start of 0
        var R11 : UInt8 = 0x00                              // Cursor scanline end ( bits 0-4 ) - initialise as scanlin end of 0
        var R12 : UInt8 = 0x00                              // Character Generator Rom start address ( high byte )
        var R13 : UInt8 = 0x00                              // Character Generator Rom start address ( low byte )
        var R14 : UInt8 = 0x00                              // Cursor address ( high byte )
        var R15 : UInt8 = 0x00                              // Cursor address ( low byte )
        var R16 : UInt8 = 0x00                              // Ignored by emulator
        var R17 : UInt8 = 0x00                              // Ignored by emulator
        var R18 : UInt8 = 0x00                              // Ignored by emulator
        var R19 : UInt8 = 0x00                              // Ignored by emulator
        
        var statusRegister : UInt8 = 0b10000000
        
        var redBackgroundIntensity : UInt8 = 0x00                         // red background intensity 0 = half 1 = full
        var greenBackgroundIntensity : UInt8 = 0x00                       // green background intensity 0 = half 1 = full
        var blueBackgroundIntensity : UInt8 = 0x00                        // blue background intensity 0 = half 1 = full
        
    }
    
    var registers = crtcRegisters()
    
    func readStatusRegister() -> UInt8
    {
     return registers.statusRegister
    }
    
    func writeRegister(RegNum:UInt8, RegValue:UInt8)
    {
        switch RegNum
        {
        case 0: registers.R0 = RegValue
        case 1: registers.R1 = RegValue
        case 2: registers.R2 = RegValue
        case 3: registers.R3 = RegValue
        case 4: registers.R4 = RegValue
        case 5: registers.R5 = RegValue
        case 6: registers.R6 = RegValue
        case 7: registers.R7 = RegValue
        case 8: registers.R8 = RegValue
        case 9: registers.R9 = RegValue
        case 10: registers.R10 = RegValue
        case 11: registers.R11 = RegValue
        case 12: registers.R12 = RegValue
        case 13: registers.R13 = RegValue
        case 14: registers.R14 = RegValue
        case 15: registers.R15 = RegValue
        case 16: registers.R16 = RegValue
        case 17: registers.R17 = RegValue
        case 18: registers.R18 = RegValue
        case 19: registers.R19 = RegValue
        default: break
        }
    }
    
    func readRegister(RegNum:UInt8) -> UInt8
    {
        switch RegNum
        {
        case 0: return registers.R0
        case 1: return registers.R1
        case 2: return registers.R2
        case 3: return registers.R3
        case 4: return registers.R4
        case 5: return registers.R5
        case 6: return registers.R6
        case 7: return registers.R7
        case 8: return registers.R8
        case 9: return registers.R9
        case 10: return registers.R10
        case 11: return registers.R11
        case 12: return registers.R12
        case 13: return registers.R13
        case 14: return registers.R14
        case 15: return registers.R15
        case 16: return registers.R16
        case 17: return registers.R17
        case 18: return registers.R18
        case 19: return registers.R19
        default: return 0
        }
    }
}
