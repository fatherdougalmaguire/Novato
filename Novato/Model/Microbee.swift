import Foundation

actor microbee
{
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
        
        var altA : UInt8 = 0        // Alternate Accumulator - 8 bit
        var altF : UInt8 = 0        // Alternate Flags Register - 8 bit
        var altB : UInt8 = 0        // Alternate General Purpose Register B - 8 bit
        var altC : UInt8 = 0        // Alternate General Purpose Register C - 8 bit
        var altD : UInt8 = 0        // Alternate General Purpose Register D - 8 bit
        var altE : UInt8 = 0        // Alternate General Purpose Register E - 8 bit
        var altH : UInt8 = 0        // Alternate General Purpose Register H - 8 bit
        var altL : UInt8 = 0        // Alternate General Purpose Register L - 8 bit
        
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
        
        var altAF : UInt16             // Alternate General Purpose Register Pair AF - 16 bit
        {
            get
            {
                return UInt16(altA) << 8 | UInt16(altF)
            }
            set
            {
                altA = UInt8(newValue >> 8)
                altF = UInt8(newValue & 0xFF)
            }
        }
        var altBC : UInt16      // Alternate General Purpose Register Pair BC - 16 bit
        {
            get
            {
                return UInt16(altB) << 8 | UInt16(altC)
            }
            set
            {
                altB = UInt8(newValue >> 8)
                altC = UInt8(newValue & 0xFF)
            }
        }
        var altDE : UInt16       // Alternate General Purpose Register Pair DE - 16 bit
        {
            get
            {
                return UInt16(altD) << 8 | UInt16(altE)
            }
            set
            {
                altD = UInt8(newValue >> 8)
                altC = UInt8(newValue & 0xFF)
            }
        }
        var altHL : UInt16      // Alternate General Purpose Register Pair HL - 16 bit
        {
            get
            {
                return UInt16(altH) << 8 | UInt16(altL)
            }
            set
            {
                altH = UInt8(newValue >> 8)
                altL = UInt8(newValue & 0xFF)
            }
        }
        
        var I : UInt8 = 0           // Interrupt Page Address Register - 8 bit
        var R : UInt8 = 0           // Memory Refresh Register - 8 bit
        
        var IM : UInt8 = 0          // Interrupt Mode
        var IFF1 : Bool = false        // Interrupt Flip-flop 1
        var IFF2 : Bool = false       // Interrupt Flip-flop 2
        
        var IX : UInt16 = 0         // Index Register IX - 16 bit
        var IY : UInt16 = 0         // Index Register IY - 16 bit
        
        var SP : UInt16 = 0x0000    // Stack Pointer - 16 bit
        var PC : UInt16 = 0x0900  // Program Counter - 16 bit
        
        var lastPC : UInt16 = 0x0000 // Program Counter - 16 bit
    }
    
    struct Stack
    {
        private var elements = ContiguousArray<UInt8>()
        
        mutating func push(value: UInt8)
        {
            elements.append(value)
        }
        
        mutating func pop() -> UInt8?
        {
            return elements.popLast()
        }
    }
    
    var myz80Queue = z80Queue()
    
    var registers = Registers()
    
    var ports = [UInt8](repeating: 0, count: 256)
    
    //    00 or 10 PIO port A data port
    //    01 or 11 PIO port A control port
    //    02 or 12 PIO port B data port
    //    03 or 13 PIO port B control port
    //    08 or 18 COLOUR control port
    //    09 or 19 Colour "Wait off"
    //    0A or 1A Extended addressing port
    //    OB or 1B Character ROM CPU access - makes character generator ROM appear from F000h to F7FFh when bit 0 of this port is set.
    //    OC or 1C 6545 CRTC address/status port
    //    OD or 1D 6545 CRTC data port
    //    44 FDC command/status
    //    45 FDC track register
    //    46 FDC sector register
    //    47 FDC data register
    //    48 Controller select/side/DD latch
    
    //    PORT B DATA PORT BIT ASSIGNMENTS
    //    bit 0 Cassette data in
    //    bit 1 Cassette data outddd
    //    bit 2 RS232 CLOCK or DTR line
    //    bit 3 RS232 CTS line (0-> clear to send)
    //    bit 4 RS232 input (0 = mark)
    //    bit 5 RS232 output (1 = mark)
    //    bit 6 Speaker bit (1 = on)
    //    bit 7 Network interrupt bit
    
    //    FLOPPY DISC CONTROLLER
    //    Controller select/side/DD latch bit assignments (write only)
    //    bit 0 LSB of drive address
    //    bit 1 MSB of drive address
    //    bit 2 Side select (0 = side 0; 1 = side 1)
    //    bit 3 DD select (0 = single density)
    //
    //    Controller TRANSFER status bit - bit 7 when port 48H is read gives (INTRQ or DRQ)
    
    //    COLOUR PORT BIT ASSIGNMENT
    //    bit 0 Not used
    //    bit 1 RED background intensity (1 = full)
    //    bit 2 GREEN backgroung intensity
    //    bit 3 BLUE background intensity
    //    bit 6 COLOUR RAM enable (0 = PCG, 1= RAM)
    
    var tStates : UInt64 = 0
    var CPUstarttime : Date = Date()
    var CPUendtime : Date = Date()
    
    private(set) var emulatorState : emulatorState = .stopped
    private(set) var executionMode : executionMode = .continuous
    
    private var interruptPending = false
    
    var crtc = CRTC()
    
    var mmu = memoryMapper()
    
    let mainRAM = memoryBlock(size: 0x8000, label: "mainRAM")
    let basicROM = memoryBlock(size: 0x4000, deviceType : .ROM, label: "basicROM")
    let pakROM = memoryBlock(size: 0x2000, deviceType : .ROM, label: "pakROM")
    let netROM = memoryBlock(size: 0x1000, deviceType : .ROM, label: "netROM")
    let videoRAM = memoryBlock(size: 0x800, label: "videoRAM", fillValue: 0x20)
    let pcgRAM = memoryBlock(size: 0x800, label: "pcgRAM")
    let colourRAM = memoryBlock(size: 0x800,  label: "colourRAM", fillValue: 0x02)
    let fontROM = memoryBlock(size: 0x1000, deviceType : .ROM,  label: "fontROM")
    
    init()
    {
        mmu.map(readDevice: mainRAM, writeDevice: mainRAM, memoryLocation: 0x0000)       // 32K System RAM
        mmu.map(readDevice: basicROM, writeDevice: basicROM, memoryLocation: 0x8000)     // 16K BASIC ROM
        mmu.map(readDevice: pakROM, writeDevice: pakROM , memoryLocation: 0xC000)        // 8K Optional ROM
        mmu.map(readDevice: netROM, writeDevice: netROM, memoryLocation: 0xE000)         // 4K Net ROM
        mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)     // 2K Video RAM
        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)         // 2K PCG RAM
    
        videoRAM.fillMemoryFromArray(memValues: [87,101,108,99,111,109,101,32,116,111,32,78,111,118,97,116,111], memOffset: 88) // Welome to Novato
        videoRAM.fillMemoryFromArray(memValues:  [128,129,130,131,132,133,134,135,
                                                   136,137,138,139,140,141,142,143], memOffset : 280)
        videoRAM.fillMemoryFromArray(memValues:  [144,145,146,147,148,149,150,151,
                                                   152,153,154,155,156,157,158,159], memOffset : 344)
        videoRAM.fillMemoryFromArray(memValues:  [160,161,162,163,164,165,166,167,
                                                   168,169,170,171,172,173,174,175], memOffset : 408)
        videoRAM.fillMemoryFromArray(memValues:  [176,177,178,179,180,181,182,183,
                                                   184,185,186,187,188,189,190,191], memOffset : 472)
        videoRAM.fillMemoryFromArray(memValues:  [192,193,194,195,196,197,198,199,
                                                   200,201,202,203,204,205,206,207], memOffset : 536)
        videoRAM.fillMemoryFromArray(memValues:  [208,209,210,211,212,213,214,215,
                                                   216,217,218,219,220,221,222,223], memOffset : 600)
        videoRAM.fillMemoryFromArray(memValues:  [224,225,226,227,228,229,230,231,
                                                   232,233,234,235,236,237,238,239], memOffset : 664)
        videoRAM.fillMemoryFromArray(memValues:  [240,241,242,243,244,245,246,247,
                                                   248,249,250,251,252,253,254,255], memOffset : 728)
        videoRAM.fillMemoryFromArray(memValues: [80,114,101,115,115,32,83,116,97,114,116], memOffset: 923) // Press Start
        basicROM.fillMemoryFromFile(fileName: "basic_5.22e", fileExtension: "rom")
        //pakROM.fillMemoryFromFile(fileName: "wordbee_1.2", fileExtension: "rom")
        //netROM.fillMemoryFromFile(fileName: "telcom_1.0", fileExtension: "rom")
        fontROM.fillMemoryFromFile(fileName: "charrom", fileExtension: "bin")
        mainRAM.fillMemoryFromFile(fileName: "demo", fileExtension: "bin", memOffset: 0x900)
        pcgRAM.fillMemoryFromArray(memValues :
                                    [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x02, 0x04, 0x04,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x80, 0x00, 0x55, 0x02, 0xA8, 0x02,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x41, 0x14, 0x42, 0x11, 0x88,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0x20, 0x10, 0x50, 0x08, 0x4C, 0x10,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x02, 0x02,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x77, 0x80, 0x2A, 0x00, 0x54, 0x01,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xBD, 0x00, 0x55, 0x80, 0x2A, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xE0, 0x10, 0x10, 0x48, 0x24, 0x88,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x15, 0x10, 0x12, 0x20, 0x4A, 0x40,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x92, 0x55, 0x00, 0xAA, 0x00, 0xAA, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x48, 0x56, 0x02, 0xA9, 0x04, 0xA1, 0x14,
                                     0x09, 0x08, 0x12, 0x20, 0x2A, 0x40, 0x4A, 0x90, 0x85, 0xA0, 0x4A, 0x41, 0x28, 0xA4, 0x12, 0x88,
                                     0x50, 0x0A, 0xA1, 0x08, 0xA5, 0x10, 0x85, 0x50, 0x0A, 0x40, 0x2A, 0x01, 0xA8, 0x05, 0xA8, 0x02,
                                     0x45, 0x28, 0x42, 0x10, 0x4A, 0x21, 0x08, 0xA4, 0x11, 0x84, 0x51, 0x04, 0x52, 0x08, 0xA2, 0x08,
                                     0x46, 0x12, 0x89, 0x41, 0x2A, 0x00, 0xAA, 0x00, 0x55, 0x08, 0x52, 0x00, 0xAA, 0x01, 0xAA, 0x02,
                                     0x00, 0x00, 0x00, 0x00, 0x80, 0x80, 0x40, 0xA0, 0x20, 0x20, 0xA5, 0x8A, 0x88, 0x11, 0x24, 0x21,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x55, 0x92, 0x20, 0x0A, 0x40, 0x2A,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x54, 0x4A, 0x81, 0x2A, 0x80, 0x2A,
                                     0x04, 0x04, 0x09, 0x10, 0x15, 0x20, 0x25, 0x40, 0x95, 0x80, 0x55, 0x40, 0x2A, 0xA0, 0x95, 0x48,
                                     0xA8, 0x04, 0x52, 0x00, 0x55, 0x00, 0x55, 0x00, 0x55, 0x00, 0x55, 0x00, 0xAA, 0x10, 0x45, 0x20,
                                     0xAA, 0x00, 0xAA, 0x01, 0x54, 0x02, 0x50, 0x8A, 0x21, 0x08, 0x52, 0x04, 0xA1, 0x14, 0x42, 0x90,
                                     0x26, 0x89, 0x22, 0x11, 0x88, 0x25, 0x90, 0x05, 0x50, 0x0A, 0xA0, 0x15, 0x40, 0x2A, 0x80, 0x2A,
                                     0x00, 0x00, 0x00, 0x00, 0x80, 0x40, 0x40, 0x20, 0x20, 0x90, 0x20, 0x40, 0x40, 0x80, 0x80, 0x80,
                                     0x00, 0x00, 0x01, 0x02, 0x02, 0x04, 0x04, 0x09, 0x10, 0x0A, 0x08, 0x04, 0x05, 0x02, 0x01, 0x01,
                                     0x95, 0x80, 0x2A, 0x40, 0x15, 0x80, 0x55, 0x00, 0x55, 0x00, 0xAA, 0x41, 0x14, 0x42, 0x10, 0x4A,
                                     0x55, 0x00, 0xAA, 0x00, 0x55, 0x02, 0x54, 0x01, 0x54, 0x22, 0x88, 0x22, 0x08, 0xA2, 0x11, 0x8A,
                                     0x40, 0x2A, 0x80, 0x55, 0x00, 0x54, 0x02, 0x50, 0x0A, 0xA0, 0x15, 0x80, 0x54, 0x02, 0x50, 0x0A,
                                     0x4A, 0xA4, 0x25, 0x12, 0xA9, 0x09, 0xA4, 0x14, 0x82, 0x54, 0x04, 0xA8, 0x09, 0xA9, 0x12, 0xA2,
                                     0xA8, 0x04, 0x52, 0x08, 0x42, 0x28, 0x82, 0xBB, 0x00, 0x24, 0xD5, 0x82, 0x28, 0x02, 0x51, 0x08,
                                     0xA2, 0x08, 0xA5, 0x10, 0x85, 0x50, 0x05, 0xF5, 0x00, 0x12, 0xD5, 0x08, 0x42, 0x28, 0x02, 0xA8,
                                     0xAA, 0x04, 0x54, 0x08, 0x51, 0x12, 0x52, 0x44, 0x04, 0xA9, 0x44, 0x35, 0x88, 0x2A, 0x85, 0x25,
                                     0x54, 0x42, 0x90, 0x8A, 0x20, 0x4A, 0x00, 0xAA, 0x00, 0x55, 0x20, 0x0A, 0xA1, 0x14, 0x41, 0x14,
                                     0x01, 0xA8, 0x04, 0xA9, 0x02, 0xA8, 0x04, 0xA2, 0x10, 0x4A, 0x80, 0x2A, 0x01, 0x54, 0x09, 0xA0,
                                     0x00, 0xAA, 0x00, 0x55, 0x00, 0xAA, 0x00, 0xAA, 0x04, 0xA9, 0x00, 0xAA, 0x00, 0x55, 0x02, 0xA8,
                                     0x4A, 0xA4, 0x15, 0x52, 0x09, 0xA9, 0x04, 0xA4, 0x12, 0x45, 0x12, 0x8A, 0x44, 0x28, 0x08, 0xA8,
                                     0x94, 0x42, 0x10, 0x45, 0x10, 0x24, 0x82, 0xA9, 0x56, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x25, 0x88, 0x42, 0x14, 0x80, 0x55, 0x00, 0x55, 0xAB, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x01, 0xAA, 0x04, 0xA4, 0x14, 0x48, 0x10, 0x50, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x80, 0xAA, 0x41, 0x28, 0x22, 0x11, 0x14, 0x0A, 0x04, 0x00, 0x05, 0x0A, 0x08, 0x12, 0x20, 0x2A,
                                     0x40, 0x2A, 0x01, 0xA8, 0x05, 0x50, 0x0A, 0xD5, 0x48, 0x00, 0xAA, 0x55, 0x00, 0xAA, 0x00, 0xA4,
                                     0xA0, 0x15, 0x40, 0x15, 0x41, 0x2A, 0x82, 0x5A, 0xA4, 0x00, 0xAA, 0x25, 0x41, 0x14, 0x82, 0x50,
                                     0x44, 0x49, 0x88, 0x12, 0x29, 0x20, 0x4A, 0x40, 0x95, 0x40, 0x54, 0x22, 0x28, 0x92, 0x90, 0x4A,
                                     0xA2, 0x08, 0x44, 0x22, 0x10, 0x8A, 0x40, 0x2A, 0x01, 0xAA, 0x00, 0xAA, 0x10, 0x85, 0x50, 0x0A,
                                     0x02, 0xA8, 0x05, 0xA0, 0x15, 0xA0, 0x0A, 0xA0, 0x0A, 0x41, 0x28, 0x85, 0x50, 0x04, 0xA2, 0x14,
                                     0x92, 0x44, 0x12, 0x41, 0x14, 0x82, 0x28, 0x84, 0x52, 0x01, 0x54, 0x02, 0xA8, 0x02, 0xA9, 0x05,
                                     0xA0, 0x8A, 0x40, 0x6A, 0x91, 0x50, 0x8A, 0x68, 0x27, 0x20, 0xA5, 0x4A, 0x90, 0x94, 0x21, 0x24,
                                     0x14, 0x82, 0x50, 0x0A, 0x50, 0x05, 0xA0, 0x15, 0xD5, 0x00, 0x6F, 0x10, 0xA4, 0x02, 0x50, 0x0A,
                                     0x04, 0xA2, 0x10, 0xA5, 0x08, 0x42, 0x29, 0x42, 0x5A, 0x00, 0x76, 0x8A, 0x21, 0x89, 0x22, 0x88,
                                     0x10, 0xA0, 0x20, 0x40, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x40,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x02, 0x04, 0x04, 0x09, 0x04, 0x04, 0x02, 0x02, 0x01, 0x00,
                                     0x40, 0x4A, 0x90, 0x85, 0x20, 0x4A, 0x10, 0x85, 0x50, 0x0A, 0x40, 0x2A, 0x81, 0x28, 0x45, 0x90,
                                     0x12, 0x81, 0x54, 0x02, 0x50, 0x8A, 0x20, 0x0A, 0xA1, 0x14, 0x81, 0x54, 0x02, 0x50, 0x0A, 0xA0,
                                     0x0A, 0x51, 0x04, 0xA1, 0x14, 0x82, 0x54, 0x01, 0x54, 0x02, 0x54, 0x01, 0xA8, 0x12, 0x84, 0x51,
                                     0x49, 0x24, 0x25, 0x52, 0x09, 0xA9, 0x04, 0x52, 0x04, 0xA3, 0x14, 0x42, 0x14, 0x89, 0x52, 0x15,
                                     0x40, 0x2A, 0x01, 0x54, 0x02, 0x54, 0x80, 0x6F, 0x10, 0x00, 0xEF, 0x00, 0xA9, 0x04, 0x51, 0x04,
                                     0x81, 0x54, 0x02, 0x50, 0x0A, 0xA0, 0x0A, 0xEA, 0x01, 0x10, 0xDF, 0x00, 0x24, 0x42, 0x10, 0x4A,
                                     0x52, 0x04, 0xA4, 0x15, 0x89, 0x52, 0x12, 0xE4, 0x04, 0x09, 0x64, 0x2A, 0x92, 0x2A, 0x89, 0x24,
                                     0x42, 0x50, 0x8A, 0x20, 0x0A, 0x41, 0x28, 0x85, 0x50, 0x04, 0x52, 0x08, 0xA2, 0x09, 0x50, 0x85,
                                     0xA0, 0x15, 0x80, 0x55, 0x00, 0x55, 0x08, 0x52, 0x80, 0x2A, 0x81, 0x54, 0x02, 0x50, 0x0A, 0x51,
                                     0x22, 0x49, 0x04, 0x51, 0x08, 0x45, 0x20, 0x95, 0x40, 0x15, 0x40, 0x2A, 0x81, 0x54, 0x02, 0x51,
                                     0x40, 0x20, 0x50, 0x10, 0x48, 0x10, 0x4C, 0x02, 0x54, 0x02, 0xAA, 0x04, 0x55, 0x09, 0x52, 0x14,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xDD, 0x82, 0x28, 0x02, 0x50, 0x0A,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xDD, 0x22, 0x88, 0x22, 0x88, 0x22,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0x20, 0x90, 0x28, 0x88, 0x24,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x84, 0x51, 0x44, 0x29, 0x20, 0x15, 0x08, 0x0A, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x0A, 0x50, 0x05, 0x50, 0x0A, 0x40, 0x2A, 0x91, 0x6D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x84, 0x29, 0x00, 0xAA, 0x01, 0xA8, 0x05, 0x52, 0x6D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x52, 0x24, 0x89, 0x52, 0x50, 0x8A, 0x20, 0x54, 0x42, 0x90, 0x4A, 0x20, 0x2A, 0x10, 0x12, 0x08,
                                     0x51, 0x04, 0x51, 0x08, 0xA4, 0x02, 0xA8, 0x05, 0xA0, 0x15, 0x80, 0x55, 0x00, 0xAA, 0x11, 0xA4,
                                     0x00, 0x54, 0x02, 0xA9, 0x04, 0xA1, 0x14, 0x42, 0x28, 0x02, 0xA8, 0x04, 0x51, 0x04, 0x52, 0x08,
                                     0x84, 0x52, 0x09, 0x45, 0x20, 0x14, 0x82, 0x28, 0x84, 0x22, 0x90, 0x4A, 0x00, 0x54, 0x02, 0xA9,
                                     0x90, 0x8A, 0x50, 0x22, 0xA8, 0x92, 0x48, 0xAA, 0x25, 0xA0, 0x24, 0x8A, 0xC8, 0x92, 0x90, 0x25,
                                     0x04, 0xA2, 0x10, 0xA5, 0x08, 0xA2, 0x08, 0xA5, 0x5A, 0x00, 0x92, 0xAA, 0x00, 0xAA, 0x00, 0x55,
                                     0x08, 0xA4, 0x12, 0x40, 0x2A, 0x81, 0x54, 0x03, 0xFC, 0x00, 0x44, 0xB6, 0x01, 0xA9, 0x02, 0x50,
                                     0xA5, 0x28, 0x92, 0xD0, 0x0A, 0xA0, 0x4A, 0x41, 0x94, 0x81, 0xAA, 0x40, 0x2A, 0x20, 0xA4, 0x92,
                                     0x40, 0x2A, 0x81, 0x28, 0x84, 0x52, 0x01, 0x54, 0x02, 0x50, 0x0A, 0xA1, 0x08, 0xA5, 0x10, 0x85,
                                     0x88, 0x22, 0x10, 0x8A, 0x41, 0x28, 0x44, 0x12, 0x80, 0x55, 0x00, 0x55, 0x08, 0x52, 0x01, 0x54,
                                     0x88, 0x26, 0x82, 0x29, 0x05, 0xA0, 0x14, 0x82, 0x54, 0x01, 0xA8, 0x04, 0x52, 0x08, 0x42, 0x29,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x80, 0x40, 0x60, 0x20, 0x80, 0x40, 0x80, 0x80, 0x80, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x0A, 0x04, 0x02, 0x02, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x02, 0xA8, 0x05, 0xA0, 0x15, 0x20, 0x8A, 0xD5, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0xA2, 0x11, 0x44, 0x12, 0x48, 0x22, 0x88, 0x55, 0x4A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x12, 0x44, 0x14, 0x89, 0x49, 0x29, 0x92, 0x44, 0x49, 0x08, 0x0A, 0x04, 0x02, 0x02, 0x01, 0x01,
                                     0x48, 0x42, 0x90, 0x4A, 0x00, 0x2A, 0x40, 0x95, 0x00, 0x55, 0x00, 0xAA, 0x00, 0xAA, 0x04, 0x29,
                                     0x00, 0xAA, 0x00, 0xAA, 0x00, 0xAA, 0x04, 0x51, 0x88, 0x22, 0x09, 0xA4, 0x11, 0xA4, 0x01, 0x54,
                                     0x0A, 0xA0, 0x14, 0x82, 0x51, 0x88, 0x25, 0x10, 0x85, 0x50, 0x04, 0x52, 0x08, 0x42, 0x28, 0x02,
                                     0x50, 0x8A, 0x68, 0x15, 0x52, 0x0A, 0x49, 0x24, 0x0A, 0xA2, 0x0A, 0xA4, 0x04, 0xA8, 0x10, 0x90,
                                     0x50, 0x8A, 0x20, 0x0A, 0x50, 0x05, 0x50, 0x85, 0xBA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x02, 0xA8, 0x12, 0xA0, 0x0A, 0x40, 0x2A, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x85, 0x22, 0x8C, 0x24, 0x88, 0x28, 0x90, 0x20, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x80, 0xAA, 0x40, 0x2A, 0x20, 0x15, 0x10, 0x0A, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x02, 0xA8, 0x05, 0xA0, 0x15, 0x40, 0x2A, 0x80, 0xBF, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0xA8, 0x05, 0x50, 0x0A, 0x40, 0x2A, 0x81, 0x55, 0x56, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x50, 0x20, 0x40, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    }
    
    //private(set) var isRunning = false
    private var runTask: Task<Void, Never>?
    
    func ClearVideoMemory()
    {
        videoRAM.fillMemory(memValue : 0x20)
    }
    
    func start()
    {
        guard emulatorState == .paused || emulatorState == .stopped else { return }
        executionMode = .continuous
        emulatorState = .running
        runLoop()
    }
    
    func stop()
    {
        emulatorState = .stopped
        runTask?.cancel()
        runTask = nil
    }
    
    func pause()
    {
        guard emulatorState == .running else { return }
        emulatorState = .paused
        runTask?.cancel()
        runTask = nil
    }
    
    func step()
    {
        guard emulatorState == .paused || emulatorState == .stopped else { return }
        if emulatorState == .stopped
        {
            emulatorState = .paused
        }
        executionMode = .singleStep
        nextInstruction()
        appLog.cpu.debug("Cumulative T-states: \(String(self.tStates))")
    }
    
    private func runLoop()
    {
        runTask = Task
        {
            let instructionsPerChunk = 500
            while !Task.isCancelled
            {
                switch emulatorState
                {
                case .running:
                    guard executionMode == .continuous else { break }
                    for _ in 0..<instructionsPerChunk
                    {
                        guard !Task.isCancelled, emulatorState == .running, executionMode == .continuous else { break }
                        nextInstruction()
                    }
                case .halted:
                    nextInstruction()
                    appLog.cpu.debug("Cumulative T-states: \(String(self.tStates))")
                case .paused, .stopped: break
                }
                await Task.yield()
            }
        }
    }
    
    func requestInterrupt()
    {
        interruptPending = true
    }
    
    private func pollInterrupt() {
        guard interruptPending, registers.IFF1 else { return }
        serviceInterrupt()
    }
    
    private func serviceInterrupt() {
        // Interrupts disabled → ignore
        guard registers.IFF1 else { return }
        
        interruptPending = false
        emulatorState = .running   // ← EXIT HALT
        
        // Z80 interrupt entry
        registers.IFF1 = false
        registers.IFF2 = false
        
        // check this
        registers.SP &-= 2
        mmu.writeByte(address: registers.SP, value: UInt8((registers.PC >> 8) & 0xFF))
        mmu.writeByte(address: registers.SP + 1, value: UInt8(registers.PC & 0xFF))
        registers.PC = 0x0038 // IM 1 vector
    }
    
    func writeToMemory(address: UInt16, value: UInt8)
    {
        mmu.writeByte(address: address, value: value)
    }
    
    func fetch( ProgramCounter : UInt16) -> (UInt8,UInt8,UInt8,UInt8)
    {
        return ( opcode1 : mmu.readByte(address: ProgramCounter),
                 opcode2 : mmu.readByte(address: ProgramCounter &+ 1),
                 opcode3 : mmu.readByte(address: ProgramCounter &+ 2),
                 opcode4 : mmu.readByte(address: ProgramCounter &+ 3)
        )
    }
    
    func TestFlags ( FlagRegister : UInt8, Flag : Z80Flags ) -> Bool
    
    {
        return FlagRegister & Flag.rawValue != 0
    }
    
    func UpdateFlags ( FlagRegister : UInt8, Flag : Z80Flags, SetFlag : Bool ) -> UInt8
    {
        if (SetFlag)
        {
            return FlagRegister | Flag.rawValue
        }
        else
        {
            return FlagRegister & ~Flag.rawValue
        }
    }
    
    func testBit (value: UInt8, bitPosition : UInt8  ) -> Bool
    {
        return (value & (1 << bitPosition)) != 0
    }
    
    func returnParity(value: UInt8) -> Bool
    {
        var tempValue : UInt8 = value
        tempValue = tempValue ^ tempValue >> 4
        tempValue = tempValue ^ tempValue >> 2
        tempValue = tempValue ^ tempValue >> 1
        return ((~tempValue) & 1) == 1
    }
    
    func logInstructionDetails(instructionDetails: String = "Unknown opcode", opcode: [UInt8], values: [UInt8] = [], programCounter: UInt16)
    {
#if DEBUG
        var instructionString : String = instructionDetails
        
        switch values.count
        {
        case 1 :
            instructionString = instructionString.replacingOccurrences(of: "$n", with: "0x"+String(format:"%02X",values[0]))
            instructionString = instructionString.replacingOccurrences(of: "$d", with: "0x"+String(format:"%02X",values[0]))
        case 2 :
            instructionString = instructionString.replacingOccurrences(of: "$nn", with: "0x"+String(format:"%04X",UInt16(values[1]) << 8 | UInt16(values[0])))
            instructionString = instructionString.replacingOccurrences(of: "$d", with: "0x"+String(format:"%02X",values[0]))
            instructionString = instructionString.replacingOccurrences(of: "$n", with: "0x"+String(format:"%02X",values[1]))
        default: break
        }
        let noValues = values.count == 0
        let opcodeString = opcode.map { String(format:"%02X",$0) }.joined(separator: " ") + (noValues ? "" : " ") + values.map { String(format:"%02X",$0) }.joined(separator: " ")
        let logString = String(format:"0x%04X",registers.PC) + "   " + opcodeString + "    " + instructionString
        appLog.cpu.debug("\(logString)")
#endif
    }
    
    func nextInstruction()
    
    {
        if emulatorState == .halted
        {
            tStates &+= 4
            pollInterrupt()
            return
        }
        executeInstruction()
        appLog.cpu.debug("Cumulative T-states: \(String(self.tStates))")
        pollInterrupt()
    }
    
    func incrementR(opcodeCount: UInt8)
    {
        let msb = registers.R & 0x80
        let lsb = ( registers.R & 0x7F) &+ opcodeCount
        registers.R  = msb | (lsb & 0x7F)
    }
    
    
    func executeInstruction()
    {
        let opcode1 = mmu.readByte(address: registers.PC)
        let opcode2 = mmu.readByte(address: registers.PC &+ 1)
        let opcode3 = mmu.readByte(address: registers.PC &+ 2)
        let opcode4 = mmu.readByte(address: registers.PC &+ 3)
        registers.lastPC = registers.PC
        switch opcode1
        {
        case 0x00: // NOP - 00 - No operation is performed
            logInstructionDetails(instructionDetails: "NOP", opcode: [0x00], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x00])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x01: // LD BC,nn - 01 n n - Loads $nn into BC
            registers.BC = UInt16(opcode3) << 8 | UInt16(opcode2)
            logInstructionDetails(instructionDetails: "LD BC,$nn", opcode: [0x01], values: [opcode2,opcode3], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x01], dataBytes: [opcode2,opcode3])
            registers.PC = registers.PC &+ 3
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0x02: // LD (BC),A - 02 - Stores A into the memory location pointed to by BC
            mmu.writeByte(address: registers.BC, value: registers.A)
            logInstructionDetails(instructionDetails: "LD (BC),A", opcode: [0x02], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x02])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x03: // INC BC - 03 - Adds one to BC
            registers.DE = registers.BC &+ 1
            logInstructionDetails(instructionDetails: "INC BE", opcode: [0x03], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x03])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x04: // INC B
            registers.B = registers.B &+ 1
            //            H    Half-Carry    Set if there was a carry from bit 3 to bit 4 (useful for BCD math).
            //            P/V    Overflow    Set if B was 127 (7F) and became -128 (80) indicating a signed overflow.
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign,SetFlag:(registers.B & 0x80) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:registers.B == 0)
            //registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:((registers.A & 0x0F) < (opcode2 & 0x0F)))
            //registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:((registers.A ^ opcode2) & (registers.A ^ temporaryResult) & 0x80 ) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
            logInstructionDetails(instructionDetails: "INC B", opcode: [0x04], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x04])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x05: // DEC B
            registers.B = registers.B &- 1
            //            H    Half-Carry    Set if there was a borrow from bit 4 to bit 3.
            //            P/V    Overflow    Set if B was 127 (7F) and became -128 (80) indicating a signed overflow.
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign,SetFlag:(registers.B & 0x80) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:registers.B == 0)
            //registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:((registers.A & 0x0F) < (opcode2 & 0x0F)))
            //registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:((registers.A ^ opcode2) & (registers.A ^ temporaryResult) & 0x80 ) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:true)
            logInstructionDetails(instructionDetails: "DEC B", opcode: [0x05], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x05])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x06: // LD B,$n - 06 n - Loads $n into B
            registers.B = opcode2
            logInstructionDetails(instructionDetails: "LD B,$n", opcode: [0x06], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x06], dataBytes: [opcode2])
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x08: // EX AF,AF' - 08 - Adds one to Exchanges the 16-bit contents of AF and AF'
            let tempResult = registers.AF
            registers.AF = registers.altAF
            registers.altAF = tempResult
            logInstructionDetails(instructionDetails: "EX AF,AF'", opcode: [0x08], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x08])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x0A: // LD A,(BC) - 0A - Loads the value pointed to by BC into A
            registers.A = mmu.readByte(address: registers.BC)
            logInstructionDetails(instructionDetails: "LD A,(BC)", opcode: [0x0A], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x0A])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x0B: // DEC BC - 0B - Subtracts one from BC
            registers.BC = registers.BC &- 1
            logInstructionDetails(instructionDetails: "DEC BC", opcode: [0x0B], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x0B])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x0E: // LD C,$n - 0E n - Loads n into C
            registers.C = opcode2
            registers.PC = registers.PC &+ 2
            logInstructionDetails(instructionDetails: "LD C,$n", opcode: [0x0E], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x0E], dataBytes: [opcode2])
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x10: // DJNZ $d - 10 d - The B register is decremented, and if not zero, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode.
            registers.B = registers.B &- 1
            logInstructionDetails(instructionDetails: "DJNZ $d", opcode: [0x10], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x10], dataBytes: [opcode2])
            if registers.B != 0
            {
                let signedOffset = Int8(bitPattern: opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            }
            else
            {
                registers.PC = registers.PC &+ 2
            }
            tStates = tStates + 13
            incrementR(opcodeCount:1)
        case 0x11: // LD DE,$nn - 11 n n - Loads $nn into DE
            registers.DE = UInt16(opcode3) << 8 | UInt16(opcode2)
            logInstructionDetails(instructionDetails: "LD DE,$nn", opcode: [0x11], values: [opcode2,opcode3], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x11], dataBytes: [opcode2,opcode3])
            registers.PC = registers.PC &+ 3
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0x12: // LD (DE),A - 12 - Stores A into the memory location pointed to by DE
            mmu.writeByte(address: registers.DE, value: registers.A)
            logInstructionDetails(instructionDetails: "LD (DE),A", opcode: [0x12], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x12])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x13: // INC DE - 13 - Adds one to DE
            registers.DE = registers.DE &+ 1
            logInstructionDetails(instructionDetails: "INC DE", opcode: [0x13], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x13])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x16: // LD D,$n - 16 n - Loads $n into D
            registers.D = opcode2
            logInstructionDetails(instructionDetails: "LD D,$n", opcode: [0x16], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x16], dataBytes: [opcode2])
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x18: // JR d - 18 d - The signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR $d", opcode: [0x18], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x18], dataBytes: [opcode2])
            let signedOffset = Int8(bitPattern: opcode2)
            let displacement = Int16(signedOffset)
            registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            tStates = tStates + 12
        case 0x1A: // LD A,(DE) - 1A - Loads the value pointed to by DE into A
            registers.A = mmu.readByte(address: registers.DE)
            logInstructionDetails(instructionDetails: "LD A,(DE)", opcode: [0x1A], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x1A])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x1B: // DEC DE - 1B - Subtracts one from DE
            registers.DE = registers.DE &- 1
            logInstructionDetails(instructionDetails: "DEC DE", opcode: [0x1B], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x1B])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x1E: // LD E,$n - 1E n - Loads $n into E
            registers.E = opcode2
            logInstructionDetails(instructionDetails: "LD E,$n", opcode: [0x1E], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x1E], dataBytes: [opcode2])
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
        case 0x20: // JR NZ,$d - 20 d - If the zero flag is unset, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR NZ,$d", opcode: [0x20], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x20], dataBytes: [opcode2])
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                registers.PC = registers.PC &+ 2
            }
            else
            {
                let signedOffset = Int8(bitPattern: opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            }
            tStates = tStates + 12
            incrementR(opcodeCount:1)
        case 0x21: // LD HL,$nn - 21 n n - Loads $nn into HL
            logInstructionDetails(instructionDetails: "LD HL,$nn", opcode: [0x21], values: [opcode2,opcode3], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x21], dataBytes: [opcode2,opcode3])
            registers.HL = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.PC = registers.PC &+ 3
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0x22: // LD ($nn),HL - 22 n n - Stores HL into the memory location pointed to by $nn.
            let tempResult = UInt16(opcode3) << 8 | UInt16(opcode2)
            mmu.writeByte(address: tempResult, value: registers.L)
            mmu.writeByte(address: tempResult &+ 1, value: registers.H)
            logInstructionDetails(instructionDetails: "LD ($nn),HL", opcode: [0x22], values: [opcode2,opcode3], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x22], dataBytes: [opcode2,opcode3])
            registers.PC = registers.PC &+ 3
            tStates = tStates + 16
            incrementR(opcodeCount:1)
        case 0x23: // INC HL - 23 - Adds one to HL
            registers.HL = registers.HL &+ 1
            logInstructionDetails(instructionDetails: "INC HL", opcode: [0x23], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x23])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x26: // LD H,$n - 26 n - Loads $n into H
            registers.H = opcode2
            logInstructionDetails(instructionDetails: "LD H,$n", opcode: [0x26], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x26], dataBytes: [opcode2])
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x28: // JR Z,$d - 28 d - If the zero flag is set, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR Z,$d", opcode: [0x28], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x28], dataBytes: [opcode2])
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                let signedOffset = Int8(bitPattern: opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            }
            else
            {
                registers.PC = registers.PC &+ 2
            }
            tStates = tStates + 12
            incrementR(opcodeCount:1)
        case 0x2A: // LD HL,($nn) - 2A n n - Loads the value pointed to by $nn into HL
            let tempResult = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.HL = UInt16(mmu.readByte(address: tempResult))
            logInstructionDetails(instructionDetails: "LD HL,($nn)", opcode: [0x2A], values: [opcode2,opcode3], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x2A], dataBytes: [opcode2,opcode3])
            registers.PC = registers.PC &+ 3
            tStates = tStates + 16
            incrementR(opcodeCount:1)
        case 0x2B: // DEC HL - 2B - Subtracts one from HL
            registers.HL = registers.HL &- 1
            logInstructionDetails(instructionDetails: "DEC HL", opcode: [0x2B], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x2B])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x2E: // LD L,$n - 2E n - Loads n into L.
            registers.L = opcode2
            logInstructionDetails(instructionDetails: "LD H,$n", opcode: [0x2E], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x2E], dataBytes: [opcode2])
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x2F: // CPL
            registers.A = ~registers.A
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:true)
            logInstructionDetails(instructionDetails: "CPL", opcode: [0x2F], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x2F])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x30: // JR NC,d
            logInstructionDetails(instructionDetails: "JR NC,$d", opcode: [0x30], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x30], dataBytes: [opcode2])
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry))
            {
                registers.PC = registers.PC &+ 2
            }
            else
            {
                let signedOffset = Int8(bitPattern: opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            }
            tStates = tStates + 12
            incrementR(opcodeCount:1)
        case 0x38: // JR C,d
            logInstructionDetails(instructionDetails: "JR C,$d", opcode: [0x38], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x38], dataBytes: [opcode2])
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry))
            {
                let signedOffset = Int8(bitPattern: opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            }
            else
            {
                registers.PC = registers.PC &+ 2
            }
            tStates = tStates + 12
            incrementR(opcodeCount:1)
        case 0x3C: // INC A
            // flags
            registers.A = registers.A &+ 1
            logInstructionDetails(instructionDetails: "INC A", opcode: [0x3C], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x3C])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x3E: // LD A,n
            registers.A = opcode2
            logInstructionDetails(instructionDetails: "LD A,$n", opcode: [0x3E], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x3E], dataBytes: [opcode2])
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x70: // LD (HL),B
            mmu.writeByte(address: registers.HL, value: registers.B)
            logInstructionDetails(instructionDetails: "LD (HL),B", opcode: [0x70], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x70])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x71: // LD (HL),C
            mmu.writeByte(address: registers.HL, value: registers.C)
            logInstructionDetails(instructionDetails: "LD (HL),C", opcode: [0x71], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x71])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x72: // LD (HL),D
            mmu.writeByte(address: registers.HL, value: registers.D)
            logInstructionDetails(instructionDetails: "LD (HL),D", opcode: [0x72], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x72])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x73: // LD (HL),E
            mmu.writeByte(address: registers.HL, value: registers.E)
            tStates = tStates + 7
            logInstructionDetails(instructionDetails: "LD (HL),E", opcode: [0x73], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x73])
            registers.PC = registers.PC &+ 1
            incrementR(opcodeCount:1)
        case 0x74: // LD (HL),H
            mmu.writeByte(address: registers.HL, value: registers.H)
            logInstructionDetails(instructionDetails: "LD (HL),H", opcode: [0x74], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x74])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x75: // LD (HL),L
            mmu.writeByte(address: registers.HL, value: registers.L)
            logInstructionDetails(instructionDetails: "LD (HL),L", opcode: [0x75], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x75])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x76: // HALT
            emulatorState = .halted
            logInstructionDetails(instructionDetails: "HALT", opcode: [0x76], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x76])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x77: // LD (HL),A
            mmu.writeByte(address: registers.HL, value: registers.A)
            logInstructionDetails(instructionDetails: "LD (HL),A", opcode: [0x77], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x77])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x78: // LD A,B
            registers.A = registers.B
            logInstructionDetails(instructionDetails: "LD A, B", opcode: [0x78], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x78])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x79: // LD A,C
            registers.A = registers.C
            logInstructionDetails(instructionDetails: "LD A,C", opcode: [0x79], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x79])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7A: // LD A,D
            registers.A = registers.D
            logInstructionDetails(instructionDetails: "LD A,D", opcode: [0x7A], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x7A])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7B: // LD A,E
            registers.A = registers.E
            logInstructionDetails(instructionDetails: "LD A,E", opcode: [0x7B], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x7B])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7C: // LD A,H
            registers.A = registers.H
            logInstructionDetails(instructionDetails: "LD A,H", opcode: [0x7C], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x7C])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7D: // LD A,L
            registers.A = registers.L
            logInstructionDetails(instructionDetails: "LD A,L", opcode: [0x7D], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x7D])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7E: // LD A,(HL)
            registers.A = mmu.readByte(address: registers.HL)
            logInstructionDetails(instructionDetails: "LD A,(HL)", opcode: [0x7E], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0x7E])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xB1: // OR C
            registers.A = registers.C | registers.A
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign,SetFlag:(registers.A & 0x80) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:registers.A == 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:false)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:returnParity(value: registers.A))
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry,SetFlag:false)
            logInstructionDetails(instructionDetails: "OR C", opcode: [0xB1], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0xB1])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xC2: // JP NZ,nn
            logInstructionDetails(instructionDetails: "OR C", opcode: [0xB1], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0xB1])
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xC3: // JP nn
            logInstructionDetails(instructionDetails: "JP $nn", opcode: [0xC3], values: [opcode2,opcode3], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0xC3], dataBytes: [opcode2,opcode3])
            registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xCA: // JP Z,nn
            logInstructionDetails(instructionDetails: "JP Z,$nn", opcode: [0xCA], values: [opcode2,opcode3], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCA], dataBytes: [opcode2,opcode3])
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xCB: //start CB opcodes
            switch opcode2
            {
            case 0x47: // BIT 0, A
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b00000001) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b00000001) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                logInstructionDetails(instructionDetails: "BIT 0, A", opcode: [0xCB,0x47], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0x47])
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x4F: // BIT 1, A
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b00000010) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b00000010) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "BIT 1, A", opcode: [0xCB,0x4F], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0x4F])
                incrementR(opcodeCount:2)
            case 0x57: // BIT 2, A
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b00000100) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b00000100) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "BIT 2, A", opcode: [0xCB,0x57], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0x57])
                incrementR(opcodeCount:2)
            case 0x5F: // BIT 3, A
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b00001000) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b00001000) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "BIT 3, A", opcode: [0xCB,0x5F], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0x5F])
                incrementR(opcodeCount:2)
            case 0x67: // BIT 4, A
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b00010000) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b00010000) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "BIT 4, A", opcode: [0xCB,0x67], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0x67])
                incrementR(opcodeCount:2)
            case 0x6F: // BIT 5, A
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b0010000) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b0010000) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "BIT 5, A", opcode: [0xCB,0x6F], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0x6F])
                incrementR(opcodeCount:2)
            case 0x77: // BIT 6, A
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b01000000) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b01000000) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "BIT 6, A", opcode: [0xCB,0x77], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0x77])
                incrementR(opcodeCount:2)
            case 0x7F: // BIT 7, A
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign,SetFlag:(registers.A & 0b10000000) == 1)
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b10000000) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b10000000) == 1))
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "BIT 7, A", opcode: [0xCB,0x7F], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0x7F])
                incrementR(opcodeCount:2)
            case 0xC7: // SET 0, A
                registers.A = registers.A | 0b00000001
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "SET 0, A", opcode: [0xCB,0xC7], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0xC7])
                incrementR(opcodeCount:2)
            case 0xCF: // SET 1, A
                registers.A = registers.A | 0b00000010
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "SET 1, A", opcode: [0xCB,0xCF], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0xCF])
                incrementR(opcodeCount:2)
            case 0xD7: // SET 2, A
                registers.A = registers.A | 0b00000100
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "SET 2, A", opcode: [0xCB,0xD7], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0xD7])
                incrementR(opcodeCount:2)
            case 0xDF: // SET 3, A
                registers.A = registers.A | 0b00001000
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "SET 3, A", opcode: [0xCB,0xDF], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0xDF])
                incrementR(opcodeCount:2)
            case 0xE7: // SET 4, A
                registers.A = registers.A | 0b00010000
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "SET 4, A", opcode: [0xCB,0xE7], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0xE7])
                incrementR(opcodeCount:2)
            case 0xEF: // SET 5, A
                registers.A = registers.A | 0b00100000
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "SET 5, A", opcode: [0xCB,0xEF], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0xEF])
                incrementR(opcodeCount:2)
            case 0xF7: // SET 6, A
                registers.A = registers.A | 0b01000000
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "SET 6, A", opcode: [0xCB,0xF7], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0xF7])
            case 0xFF: // SET 7, A
                registers.A = registers.A | 0b10000000
                tStates = tStates + 8
                logInstructionDetails(instructionDetails: "SET 7, A", opcode: [0xCB,0xFF], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,0xFF])
                incrementR(opcodeCount:2)
            default:
                tStates = tStates + 0 // check if this is correct
                logInstructionDetails(opcode: [0xCB,opcode2], programCounter: registers.PC)
                myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,opcode2])
                incrementR(opcodeCount:2)
            } // end CB opcodes
            registers.PC = registers.PC &+ 2
        case 0xD2: // JP NC,nn
            logInstructionDetails(instructionDetails: "JP NC,$nn", opcode: [0xD2], values: [opcode2,opcode3], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0xD2], dataBytes: [opcode2,opcode3])
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xD3: // OUT (n),A
            ports[Int(opcode2)] = registers.A
            switch opcode2
            {
            case 0x08:
                if testBit(value: registers.A, bitPosition: 1)
                {
                   crtc.registers.redBackgroundIntensity = 1  // set global background red intensity to 1 = full
                }
                if !testBit(value: registers.A, bitPosition: 1)
                {
                    crtc.registers.redBackgroundIntensity = 0 // set global background red intensity to 0 = half
                }
                if testBit(value: registers.A, bitPosition: 2)
                {
                    crtc.registers.greenBackgroundIntensity = 1 // set global background blue intensity to 1 = full
                }
                if !testBit(value: registers.A, bitPosition: 2)
                {
                    crtc.registers.greenBackgroundIntensity = 0 // set global background blue intensity to 0 = half
                }
                if testBit(value: registers.A, bitPosition: 3)
                {
                    crtc.registers.blueBackgroundIntensity = 1 // set global background green intensity to 1 = full
                }
                if !testBit(value: registers.A, bitPosition: 3)
                {
                    crtc.registers.blueBackgroundIntensity = 0 // set global background green intensity to 0 = half
                }
                if testBit(value: registers.A, bitPosition: 6)
                {
                    mmu.map(readDevice: colourRAM, writeDevice: colourRAM, memoryLocation: 0xF800)  // swap in colour ram
                }
                if !testBit(value: registers.A, bitPosition: 6)
                {
                    mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)        // swap in pcg ram
                }
            case 0x0A: break //PAK N selection - need some mechanism to map PAK number to memory device
            case 0x0B:
                if registers.A == 1
                {
                    mmu.map(readDevice: fontROM, writeDevice: videoRAM, memoryLocation: 0xF000)     // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                    mmu.map(readDevice: fontROM, writeDevice: pcgRAM, memoryLocation: 0xF800)
                }
                if registers.A == 0
                {
                    mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)  // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                    mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)  // swap video ram and pcg ram back into memory at 0xf000 for read and wrtie
                }
            case 0x0C: break // writing to port 0x0C needs no further processing
            case 0x0D: crtc.writeRegister(RegNum:ports[0x0C], RegValue:ports[0x0D])
            default: break // other ports go here
            }
            logInstructionDetails(instructionDetails: "OUT ($n),A", opcode: [0xD3], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0xD3], dataBytes: [opcode2])
            registers.PC = registers.PC &+ 2
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xDA: // JP C,nn
            logInstructionDetails(instructionDetails: "JP C,$nn", opcode: [0xDA], values: [opcode2,opcode3], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0xDA], dataBytes: [opcode2,opcode3])
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry))
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xDB: // IN A,(n)
            registers.A = ports[Int(opcode2)]
            switch opcode2
            {
            case 0x08: break // registers.A contains value of colour control port
            case 0x0A: break // NET selection INPUT from port - whatever this means
            case 0x0B: break // registers.A contains value of font rom control port
            case 0x0C: registers.A = crtc.readStatusRegister()
            case 0x0D: registers.A = crtc.readRegister(RegNum:ports[0x0C])
            default: break // other ports go here
            }
            logInstructionDetails(instructionDetails: "IN A,($n)", opcode: [0xDB], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0xDB], dataBytes: [opcode2])
            registers.PC = registers.PC &+ 2
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xE2: // JP PO,nn
            logInstructionDetails(instructionDetails: "JP PO,$nn", opcode: [0xE2], values: [opcode2,opcode3], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0xE2], dataBytes:[opcode2,opcode3])
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xEA: // JP PE,nn
            logInstructionDetails(instructionDetails: "JP PE,$nn", opcode: [0xEA], values: [opcode2,opcode3], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0xEA], dataBytes: [opcode2,opcode3])
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow))
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xED: // ED instructions
            switch opcode2
            {
            case 0xB0:  // LDIR
                repeat
                {
                    mmu.writeByte(address: registers.DE, value : mmu.readByte(address: registers.HL))
                    registers.HL = registers.HL &+ 1
                    registers.DE = registers.DE &+ 1
                    registers.BC = registers.BC &- 1
                }
                while registers.BC != 0
                        registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:false)
                        registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                        registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:registers.BC == 0)
                        logInstructionDetails(instructionDetails: "LDIR", opcode: [0xED,0xB0], programCounter: registers.PC)
                        myz80Queue.addToQueue(address: registers.PC, opCodes: [0xED,0xB0])
                        registers.PC = registers.PC &+ 2
                        tStates = tStates + 21
                        incrementR(opcodeCount:2)
                        case 0x4F: //  LD R, A    ED 4F
                        registers.R = (registers.A & 0x7F) | (registers.R & 0x80)
                        logInstructionDetails(instructionDetails: "LD R,A", opcode: [0xED,0x4F], programCounter: registers.PC)
                        myz80Queue.addToQueue(address: registers.PC, opCodes: [0xED,0x4F])
                        registers.PC = registers.PC &+ 2
                        tStates = tStates + 9
                        case 0x5F:  // LD A, R
                        //             LD A,R
                        //            Loads the refresh register R into A
                        //            Flags affected:
                        //            S, Z, P/V set from result
                        //            P/V reflects IFF2
                        //            H and N reset
                        //            C unchanged
                        incrementR(opcodeCount:2)
                        registers.A = registers.R
                        registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign,SetFlag:(registers.A & 0x80) != 0)
                        registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:registers.A == 0)
                        registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:false)
                        registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                        registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:registers.IFF2)
                        logInstructionDetails(instructionDetails: "LD A,R", opcode: [0xED,0x5F], programCounter: registers.PC)
                        myz80Queue.addToQueue(address: registers.PC, opCodes: [0xED,0x5F])
                        registers.PC = registers.PC &+ 2
                        tStates = tStates + 9
                        default:
                            logInstructionDetails(opcode: [0xED,opcode2], programCounter: registers.PC)
                        myz80Queue.addToQueue(address: registers.PC, opCodes: [0xED,opcode2], dataBytes: [opcode2])
                        registers.PC = registers.PC &+ 2
                        tStates = tStates + 21  // confirm this behaviour
                        incrementR(opcodeCount:2) // confirm this behaviour for ED codes
            }
        case 0xF2: // JP P,nn
            logInstructionDetails(instructionDetails: "JP P,$nn", opcode: [0xF2], values: [opcode2,opcode3], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0xF2], dataBytes: [opcode2,opcode3])
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xFA: // JP M,nn
            logInstructionDetails(instructionDetails: "JP M,$nn", opcode: [0xFA], values: [opcode2,opcode3], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0xFA], dataBytes: [opcode2,opcode3])
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign))
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xFE: // CP n
            let temporaryResult = registers.A &- opcode2
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign,SetFlag:(temporaryResult & 0x80) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:temporaryResult == 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:((registers.A & 0x0F) < (opcode2 & 0x0F)))
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:((registers.A ^ opcode2) & (registers.A ^ temporaryResult) & 0x80 ) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:true)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry,SetFlag:registers.A < opcode2)
            logInstructionDetails(instructionDetails: "CP $n", opcode: [0xFE], values: [opcode2], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [0xFE], dataBytes: [opcode2])
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        default:
            logInstructionDetails(opcode: [opcode1], programCounter: registers.PC)
            myz80Queue.addToQueue(address: registers.PC, opCodes: [opcode1])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 0 // check this behaviour
            incrementR(opcodeCount:1)
        } // end single opcodes
    }
    
    func returnSnapshot() async -> microbeeSnapshot
    {
        return microbeeSnapshot(
            id: UUID(),
            timestamp: Date(),
            z80Snapshot: z80Snapshot(
                PC: registers.PC,
                SP: registers.SP,
                
                BC: registers.BC,
                DE: registers.DE,
                HL: registers.HL,
                
                altAF: registers.altAF,
                altBC: registers.altBC,
                altDE: registers.altDE,
                altHL: registers.altHL,
                IX: registers.IX,
                IY: registers.IY,
                I: registers.I,
                R: registers.R,
                IM: registers.IM,
                IFF1: registers.IFF1,
                IFF2: registers.IFF2,
                A: registers.A,
                F: registers.F,
                B: registers.B,
                C: registers.C,
                D: registers.D,
                E: registers.E,
                H: registers.H,
                L: registers.L,
                altA: registers.altA,
                altF: registers.altF,
                altB: registers.altB,
                altC: registers.altC,
                altD: registers.altD,
                altE: registers.altE,
                altH: registers.altH,
                altL: registers.altL
            ),
            crtcSnapshot: crtcSnapshot(
                R0: crtc.registers.R0,
                R1: crtc.registers.R1,
                R2: crtc.registers.R2,
                R3: crtc.registers.R3,
                R4: crtc.registers.R4,
                R5: crtc.registers.R5,
                R6: crtc.registers.R6,
                R7: crtc.registers.R7,
                R8: crtc.registers.R8,
                R9: crtc.registers.R9,
                R10: crtc.registers.R10,
                R11: crtc.registers.R11,
                R12: crtc.registers.R12,
                R13: crtc.registers.R13,
                R14: crtc.registers.R14,
                R15: crtc.registers.R15,
                R16: crtc.registers.R16,
                R17: crtc.registers.R17,
                R18: crtc.registers.R18,
                R19: crtc.registers.R19,
                statusRegister: crtc.registers.statusRegister,
                redBackgroundIntensity: crtc.registers.redBackgroundIntensity,
                greenBackgroundIntensity: crtc.registers.greenBackgroundIntensity,
                blueBackgroundIntensity: crtc.registers.blueBackgroundIntensity
            ),
            executionSnapshot: executionSnapshot(
                tStates: tStates,
                emulatorState: emulatorState,
                executionMode: executionMode,
                ports: ports,
                z80Queue : myz80Queue,
                lastPC : registers.lastPC),
            memorySnapshot: memorySnapshot(
                VDU: videoRAM.bufferTransform(),
                CharRom: fontROM.bufferTransform(),
                PcgRam: pcgRAM.bufferTransform(),
                ColourRam: colourRAM.bufferTransform(),
                memoryDump: mmu.memorySlice(address: registers.PC & 0xFF00, size: 0x100)
            )
        )
    }
}

