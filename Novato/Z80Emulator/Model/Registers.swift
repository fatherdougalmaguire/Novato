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
}
