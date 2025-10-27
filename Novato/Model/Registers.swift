struct Registers

{
    var A : UInt8 = 0           // Accumulator - 8 bit
    var F : UInt8 = 0           // Flags Register - 8 bit
    var B : UInt8 = 0           // General Purpose Register B - 8 bit
    var C : UInt8 = 0           // General Purpose Register C - 8 bit
    var D : UInt8 = 0           // General Purpose Register D - 8 bit
    var E : UInt8 = 0           // General Purpose Register E - 8 bit
    var H : UInt8 = 0           // General Purpose Register H - 8 bit
    var L : UInt8 = 0           // General Purpose Register L - 8 bit
    
    var AltA : UInt8 = 0        // Alternate Accumulator - 8 bit
    var AltF : UInt8 = 0        // Alternate Flags Register - 8 bit
    var AltB : UInt8 = 0        // Alternate General Purpose Register B - 8 bit
    var AltC : UInt8 = 0        // Alternate General Purpose Register C - 8 bit
    var AltD : UInt8 = 0        // Alternate General Purpose Register D - 8 bit
    var AltE : UInt8 = 0        // Alternate General Purpose Register E - 8 bit
    var AltH : UInt8 = 0        // Alternate General Purpose Register H - 8 bit
    var AltL : UInt8 = 0        // Alternate General Purpose Register L - 8 bit
 
    var AF : UInt16             // General Purpose Register Pair AF - 16 bit
    {
        get
        {
            return UInt16(A) << 8 | UInt16(F)
        }
        set
        {
            A = UInt8(newValue >> 8)
            F = UInt8(newValue & 0xFF)
        }
    }
    var BC : UInt16             // General Purpose Register Pair BC - 16 bit
    {
        get
        {
            return UInt16(B) << 8 | UInt16(C)
        }
        set
        {
            B = UInt8(newValue >> 8)
            C = UInt8(newValue & 0xFF)
        }
    }
    var DE : UInt16         // General Purpose Register Pair DE - 16 bit
    {
        get
        {
            return UInt16(D) << 8 | UInt16(E)
        }
        set
        {
            D = UInt8(newValue >> 8)
            E = UInt8(newValue & 0xFF)
        }
    }
    var HL : UInt16         // General Purpose Register Pair HL - 16 bit
    {
        get
        {
            return UInt16(H) << 8 | UInt16(L)
        }
        set
        {
            H = UInt8(newValue >> 8)
            L = UInt8(newValue & 0xFF)
        }
    }
    
    var AltAF : UInt16             // Alternate General Purpose Register Pair AF - 16 bit
    {
        get
        {
            return UInt16(AltA) << 8 | UInt16(AltF)
        }
        set
        {
            AltA = UInt8(newValue >> 8)
            AltF = UInt8(newValue & 0xFF)
        }
    }
    var AltBC : UInt16      // Alternate General Purpose Register Pair BC - 16 bit
    {
        get
        {
            return UInt16(AltB) << 8 | UInt16(AltC)
        }
        set
        {
            AltB = UInt8(newValue >> 8)
            AltC = UInt8(newValue & 0xFF)
        }
    }
    var AltDE : UInt16       // Alternate General Purpose Register Pair DE - 16 bit
    {
        get
        {
            return UInt16(AltD) << 8 | UInt16(AltE)
        }
        set
        {
            AltD = UInt8(newValue >> 8)
            AltC = UInt8(newValue & 0xFF)
        }
    }
    var AltHL : UInt16      // Alternate General Purpose Register Pair HL - 16 bit
    {
        get
        {
            return UInt16(AltH) << 8 | UInt16(AltL)
        }
        set
        {
            AltH = UInt8(newValue >> 8)
            AltL = UInt8(newValue & 0xFF)
        }
    }
    
    var I : UInt8 = 0           // Interrupt Page Address Register - 8 bit
    var R : UInt8 = 0           // Memory Refresh Register - 8 bit
    
    var IX : UInt16 = 0         // Index Register IX - 16 bit
    var IY : UInt16 = 0         // Index Register IY - 16 bit
    
    var SP : UInt16 = 0xFFFF    // Stack Pointer - 16 bit
    var PC : UInt16 = 0x0000    // Program Counter - 16 bit
}

struct CPUState
{
    let PC : UInt16
    let SP : UInt16
    
    let BC : UInt16
    let DE : UInt16
    let HL : UInt16
    
    let AltBC : UInt16
    let AltDE : UInt16
    let AltHL : UInt16
    
    let IX : UInt16
    let IY : UInt16
    
    let I : UInt8
    let R : UInt8
    
    let A : UInt8
    let F : UInt8
    let B : UInt8
    let C : UInt8
    let D : UInt8
    let E : UInt8
    let H : UInt8
    let L : UInt8
    
    let AltA : UInt8
    let AltF : UInt8
    let AltB : UInt8
    let AltC : UInt8
    let AltD : UInt8
    let AltE : UInt8
    let AltH : UInt8
    let AltL : UInt8
    
    let memoryDump : [UInt8]
    let VDU : [Float]
    let CharRom : [Float]
    
    let vmR1_HorizDisplayed : UInt8
    let vmR6_VertDisplayed : UInt8
    let vmR9_ScanLinesMinus1 : UInt8
    let vmR10_CursorStartAndBlinkMode : UInt8
    let vmR11_CursorEnd : UInt8
    let vmR12_DisplayStartAddrH : UInt8
    let vmR13_DisplayStartAddrL : UInt8
    let vmR14_CursorPositionH : UInt8
    let vmR15_CursorPositionL : UInt8
}

enum Z80Flags : UInt8
{
    case Carry = 0x01               // 00000001
    case Negative = 0x02            // 00000010
    case Parity_Overflow = 0x04     // 00000100
    case Y = 0x08                   // 00001000
    case Half_Carry = 0x10          // 00010000
    case X = 0x20                   // 00100000
    case Zero = 0x40                // 01000000
    case Sign = 0x80                // 10000000
}


struct CRTCRegisters
{
    var R0_HorizTotalMinus1 : UInt8 = 0x6B              // Ignored by emulator - Total length of line (displayed and non-displayed cycles (retrace) in CCLK cylces minus 1
    var R1_HorizDisplayed : UInt8 = 0x40                // Number of characters displayed in a line
    var R2_HorizSyncPosition : UInt8 = 0x51             // Ignored by emulator - The position of the horizontal sync pulse start in distance from line start
    var R3_VSynchHSynchWidths : UInt8 = 0x37            // Ignored by emulator
    var R4_VertTotalMinus1 : UInt8 = 0x12               // The number of character lines of the screen minus 1
    var R5_VertTotalAdjust : UInt8 = 0x09               // Ignored by emulator - The additional number of scanlines to complete a screen
    var R6_VertDisplayed : UInt8 = 0x10                 // Number character lines that are displayed
    var R7_VertSyncPosition : UInt8 = 0x11              // Ignored by emulator - Position of the vertical sync pulse in character lines.
    var R8_ModeControl : UInt8 = 0x48                   // Ignored by emulator
    var R9_ScanLinesMinus1 : UInt8 = 0x0F               // Number of scanlines per character minus 1
    var R10_CursorStartAndBlinkMode : UInt8 = 0x6F      // Cursor scanline start ( 5 bits ) and blink mode ( 2 bits )
    var R11_CursorEnd : UInt8 = 0x0F                    // Cursor scanline end ( 5 bits )
    var R12_DisplayStartAddrH : UInt8 = 0x00            // Character Generator Rom start address ( high byte )
    var R13_DisplayStartAddrL : UInt8 = 0x00            // Character Generator Rom start address ( low byte )
    var R14_CursorPositionH : UInt8 = 0x00              // Ignored by emulator
    var R15_CursorPositionL : UInt8 = 0x00              // Ignored by emulator
    var R16_LightPenRegH : UInt8 = 0x00                 // Ignored by emulator
    var R17_LightPenRegL : UInt8 = 0x00                 // Ignored by emulator
    var R18_UpdateAddressRegH : UInt8 = 0x00            // Ignored by emulator
    var R19_UpdateAddressRegL : UInt8 = 0xD0            // Ignored by emulator
    
    var StatusRegister : UInt8 = 0b10000000
}

