import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "com.emulator.novato"

    static let cpu = Logger(subsystem: subsystem, category: "CPU")
    
    static let pio = Logger(subsystem: subsystem, category: "PIO")
    
    static let video = Logger(subsystem: subsystem, category: "Video")
}

actor Z80CPU
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
        
        var IM : UInt8 = 0          // Interrupt Mode
        var IFF1 : UInt8 = 0        // Interrupt Flip-flop 1
        var IFF2 : UInt8 = 0        // Interrupt Flip-flop 2
        
        var IX : UInt16 = 0         // Index Register IX - 16 bit
        var IY : UInt16 = 0         // Index Register IY - 16 bit
        
        var SP : UInt16 = 0xFFFF    // Stack Pointer - 16 bit
        var PC : UInt16 = 0x0000  // Program Counter - 16 bit
    }
    
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
    
    var emulatorHalted : Bool = false
    
    var mnemonicQueue = instructionQueue(instructionLimit: 10)

    var MOS6545 = CRTC()
    
    var mmu = memoryMapper()

    var mainRAM = memoryBlock(size: 0x8000, label: "mainRAM")
    var basicROM = memoryBlock(size: 0x4000, deviceType : .ROM, label: "basicROM")
    var wordbeeROM = memoryBlock(size: 0x2000, deviceType : .ROM, label: "wordbeeROM")
    var netROM = memoryBlock(size: 0x1000, deviceType : .ROM, label: "netROM")
    var videoRAM = memoryBlock(size: 0x800, label: "videoRAM", fillValue: 0x20)
    var pcgRAM = memoryBlock(size: 0x800, label: "pcgRAM")
    var colourRAM = memoryBlock(size: 0x800,  label: "colourRAM")
    var fontROM = memoryBlock(size: 0x1000, deviceType : .ROM,  label: "fontROM")
    
    init()
    {
        mmu.map(readDevice: [mainRAM], writeDevice: [mainRAM], memoryLocation: 0x0000)       // 32K System RAM
        mmu.map(readDevice: [basicROM], writeDevice: [basicROM], memoryLocation: 0x8000)      // 16K BASIC ROM
        mmu.map(readDevice: [wordbeeROM], writeDevice: [wordbeeROM] , memoryLocation: 0xC000)    // 8K Optional ROM
        mmu.map(readDevice: [netROM], writeDevice: [netROM], memoryLocation: 0xE000)        // 4K Net ROM
        mmu.map(readDevice: [videoRAM], writeDevice: [videoRAM], memoryLocation: 0xF000)      // 2K Video RAM
        mmu.map(readDevice: [pcgRAM], writeDevice: [pcgRAM], memoryLocation: 0xF800)        // 2K PCG RAM
        
        videoRAM.fillMemoryFromArray(memValues: [Character("W").asciiValue!,Character("e").asciiValue!,Character("l").asciiValue!,Character("c").asciiValue!,Character("o").asciiValue!,Character("m").asciiValue!,Character("e").asciiValue!,Character(" ").asciiValue!,Character("t").asciiValue!,Character("o").asciiValue!,Character(" ").asciiValue!,Character("N").asciiValue!,Character("o").asciiValue!,Character("v").asciiValue!,Character("a").asciiValue!,Character("t").asciiValue!,Character("o").asciiValue!], memOffset : 88)
        videoRAM.fillMemoryFromArray(memValues :  [128,129,130,131,132,133,134,135,
                                                  136,137,138,139,140,141,142,143], memOffset : 280)
        videoRAM.fillMemoryFromArray(memValues :  [144,145,146,147,148,149,150,151,
                                                  152,153,154,155,156,157,158,159], memOffset : 344)
        videoRAM.fillMemoryFromArray(memValues :  [160,161,162,163,164,165,166,167,
                                                  168,169,170,171,172,173,174,175], memOffset : 408)
        videoRAM.fillMemoryFromArray(memValues :  [176,177,178,179,180,181,182,183,
                                                  184,185,186,187,188,189,190,191], memOffset : 472)
        videoRAM.fillMemoryFromArray(memValues :  [192,193,194,195,196,197,198,199,
                                                  200,201,202,203,204,205,206,207], memOffset : 536)
        videoRAM.fillMemoryFromArray(memValues :  [208,209,210,211,212,213,214,215,
                                                  216,217,218,219,220,221,222,223], memOffset : 600)
        videoRAM.fillMemoryFromArray(memValues :  [224,225,226,227,228,229,230,231,
                                                  232,233,234,235,236,237,238,239], memOffset : 664)
        videoRAM.fillMemoryFromArray(memValues :  [240,241,242,243,244,245,246,247,
                                                  248,249,250,251,252,253,254,255], memOffset : 728)
        videoRAM.fillMemoryFromArray(memValues :  [Character("P").asciiValue!,Character("r").asciiValue!,Character("e").asciiValue!,Character("s").asciiValue!,Character("s").asciiValue!,Character(" ").asciiValue!,Character("S").asciiValue!,Character("t").asciiValue!,Character("a").asciiValue!,Character("r").asciiValue!,Character("t").asciiValue!], memOffset : 923)
        basicROM.fillMemoryFromFile(FileName: "basic_5.22e", FileExtension: "rom")
        wordbeeROM.fillMemoryFromFile(FileName: "wordbee_1.2", FileExtension: "rom")
        netROM.fillMemoryFromFile(FileName: "telcom_1.0", FileExtension: "rom")
        fontROM.fillMemoryFromFile(FileName: "charrom", FileExtension: "bin")
        mainRAM.fillMemoryFromFile(FileName: "demo", FileExtension: "bin")
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
            colourRAM.fillMemory(memValue: 2)
    }

    private(set) var isRunning = false
    private var stepTask: Task<Void, Never>?

    func ClearVideoMemory()
    {
        videoRAM.fillMemory(memValue : 0x20)
    }
    
    func start()
    {
        guard !isRunning else { return }
        isRunning = true
        stepTask = Task
        {
            while isRunning
            {
                step()
                try? await Task.sleep(nanoseconds: 1000) // 1 microsecond
            }
        }
    }
    
    func step()
    {
        let prefetch = fetch(ProgramCounter : registers.PC)
        if !emulatorHalted
        {
            execute(opcodes : prefetch)
        }
        Logger.cpu.debug("Cumulative T states: \(String(self.tStates))")
    }

    func stop()
    {
        isRunning = false
        stepTask?.cancel()
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
            
            let opcodeString = opcode.map { String(format:"%02X",$0) }.joined(separator: ",")
            let logString = instructionString+" ["+opcodeString+"] @ 0x"+String(format:"%04X",registers.PC)
            Logger.cpu.debug("Instruction \(logString)")
        #endif
        mnemonicQueue.addInstruction(newInstruction: instructionString, newAddress: registers.PC)
    }
    
    func execute( opcodes: ( opcode1 : UInt8, opcode2 : UInt8, opcode3 : UInt8, opcode4 : UInt8))
    {
        switch opcodes.opcode1
        {
        case 0x00: // NOP - 00 - No operation is performed
            logInstructionDetails(instructionDetails: "NOP", opcode: [0x00], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
        case 0x01: // LD BC,nn - 01 n n - Loads $nn into BC
            logInstructionDetails(instructionDetails: "LD BC,$nn", opcode: [0x01,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            registers.BC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            registers.PC = registers.PC &+ 3
            tStates = tStates + 10
        case 0x02: // LD (BC),A - 02 - Stores A into the memory location pointed to by BC
            logInstructionDetails(instructionDetails: "LD (BC),A", opcode: [0x02], programCounter: registers.PC)
            mmu.writeByte(address: registers.BC, value: registers.A)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
        case 0x03: // INC BC - 03 - Adds one to BC
            logInstructionDetails(instructionDetails: "INC BE", opcode: [0x03], programCounter: registers.PC)
            registers.DE = registers.BC &+ 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
        case 0x04: // INC B
            logInstructionDetails(instructionDetails: "INC B", opcode: [opcodes.opcode1], programCounter: registers.PC)
            registers.B = registers.B &+ 1
//            H    Half-Carry    Set if there was a carry from bit 3 to bit 4 (useful for BCD math).
//            P/V    Overflow    Set if B was 127 (7F) and became -128 (80) indicating a signed overflow.
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign,SetFlag:(registers.B & 0x80) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:registers.B == 0)
            //registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:((registers.A & 0x0F) < (opcodes.opcode2 & 0x0F)))
            //registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:((registers.A ^ opcodes.opcode2) & (registers.A ^ temporaryResult) & 0x80 ) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
        case 0x05: // DEC B
            logInstructionDetails(instructionDetails: "DEC B", opcode: [opcodes.opcode1], programCounter: registers.PC)
            registers.B = registers.B &- 1
//            H    Half-Carry    Set if there was a borrow from bit 4 to bit 3.
//            P/V    Overflow    Set if B was 127 (7F) and became -128 (80) indicating a signed overflow.
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign,SetFlag:(registers.B & 0x80) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:registers.B == 0)
            //registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:((registers.A & 0x0F) < (opcodes.opcode2 & 0x0F)))
            //registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:((registers.A ^ opcodes.opcode2) & (registers.A ^ temporaryResult) & 0x80 ) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:true)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
        case 0x06: // LD B,$n - 06 n - Loads $n into B
            logInstructionDetails(instructionDetails: "LD B,$n", opcode: [0x06,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            registers.B = opcodes.opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
        case 0x08: // EX AF,AF' - 08 - Adds one to Exchanges the 16-bit contents of AF and AF'
            logInstructionDetails(instructionDetails: "EX AF,AF'", opcode: [0x08], programCounter: registers.PC)
            let tempResult = registers.AF
            registers.AF = registers.AltAF
            registers.AltAF = tempResult
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
        case 0x0A: // LD A,(BC) - 0A - Loads the value pointed to by BC into A
            logInstructionDetails(instructionDetails: "LD A,(BC)", opcode: [0x0A], programCounter: registers.PC)
            registers.A = mmu.readByte(address: registers.BC)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
        case 0x0B: // DEC BC - 0B - Subtracts one from BC
            logInstructionDetails(instructionDetails: "DEC BC", opcode: [0x0B], programCounter: registers.PC)
            registers.BC = registers.BC &- 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
        case 0x0E: // LD C,$n - 0E n - Loads n into C
            logInstructionDetails(instructionDetails: "LD C,$n", opcode: [0x0E,opcodes.opcode2], programCounter: registers.PC)
            registers.C = opcodes.opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
        case 0x10: // DJNZ $d - 10 d - The B register is decremented, and if not zero, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode.
            logInstructionDetails(instructionDetails: "DJNZ $d", opcode: [0x10,opcodes.opcode2], programCounter: registers.PC)
            registers.B = registers.B &- 1
            if registers.B != 0
            {
                let signedOffset = Int8(bitPattern: opcodes.opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            }
            else
            {
                registers.PC = registers.PC &+ 2
            }
            tStates = tStates + 13
        case 0x11: // LD DE,$nn - 11 n n - Loads $nn into DE
            logInstructionDetails(instructionDetails: "LD DE,$nn", opcode: [0x11,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            registers.DE = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            registers.PC = registers.PC &+ 3
            tStates = tStates + 10
        case 0x12: // LD (DE),A - 12 - Stores A into the memory location pointed to by DE
            logInstructionDetails(instructionDetails: "LD (DE),A", opcode: [0x12], programCounter: registers.PC)
            mmu.writeByte(address: registers.DE, value: registers.A)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
        case 0x13: // INC DE - 13 - Adds one to DE
            logInstructionDetails(instructionDetails: "INC DE", opcode: [0x13], programCounter: registers.PC)
            registers.DE = registers.DE &+ 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
        case 0x16: // LD D,$n - 16 n - Loads $n into D
            logInstructionDetails(instructionDetails: "LD D,$n", opcode: [0x16,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            registers.D = opcodes.opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
        case 0x18: // JR d - 18 d - The signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR $d", opcode: [0x18,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            let signedOffset = Int8(bitPattern: opcodes.opcode2)
            let displacement = Int16(signedOffset)
            registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            tStates = tStates + 12
        case 0x1A: // LD A,(DE) - 1A - Loads the value pointed to by DE into A
            logInstructionDetails(instructionDetails: "LD A,(DE)", opcode: [0x1A], programCounter: registers.PC)
            registers.A = mmu.readByte(address: registers.DE)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
        case 0x1B: // DEC DE - 1B - Subtracts one from DE
            logInstructionDetails(instructionDetails: "DEC DE", opcode: [0x1B], programCounter: registers.PC)
            registers.DE = registers.DE &- 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
        case 0x1E: // LD E,$n - 1E n - Loads $n into E
            logInstructionDetails(instructionDetails: "LD E,$n", opcode: [0x1E,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            registers.E = opcodes.opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
        case 0x20: // JR NZ,$d - 20 d - If the zero flag is unset, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR NZ,$d", opcode: [0x20,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                registers.PC = registers.PC &+ 2
            }
            else
            {
                let signedOffset = Int8(bitPattern: opcodes.opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            }
            tStates = tStates + 12
        case 0x21: // LD HL,$nn - 21 n n - Loads $nn into HL
            logInstructionDetails(instructionDetails: "LD HL,$nn", opcode: [0x21,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            registers.HL = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            registers.PC = registers.PC &+ 3
            tStates = tStates + 10
        case 0x22: // LD ($nn),HL - 22 n n - Stores HL into the memory location pointed to by $nn.
            logInstructionDetails(instructionDetails: "LD ($nn),HL", opcode: [0x22,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            let tempResult = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            mmu.writeByte(address: tempResult, value: registers.L)
            mmu.writeByte(address: tempResult &+ 1, value: registers.H)
            registers.PC = registers.PC &+ 3
            tStates = tStates + 16
        case 0x23: // INC HL - 23 - Adds one to HL
            logInstructionDetails(instructionDetails: "INC HL", opcode: [0x23], programCounter: registers.PC)
            registers.HL = registers.HL &+ 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
        case 0x26: // LD H,$n - 26 n - Loads $n into H
            logInstructionDetails(instructionDetails: "LD H,$n", opcode: [0x26,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            registers.H = opcodes.opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
        case 0x28: // JR Z,$d - 28 d - If the zero flag is set, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR Z,$d", opcode: [0x28,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                let signedOffset = Int8(bitPattern: opcodes.opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            }
            else
            {
                registers.PC = registers.PC &+ 2
            }
            tStates = tStates + 12
        case 0x2A: // LD HL,($nn) - 2A n n - Loads the value pointed to by $nn into HL.
            logInstructionDetails(instructionDetails: "LD HL,($nn)", opcode: [0x2A,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            let tempResult = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            registers.HL = UInt16(mmu.readByte(address: tempResult))
            registers.PC = registers.PC &+ 3
            tStates = tStates + 16
        case 0x2B: // DEC HL - 2B - Subtracts one from HL
            logInstructionDetails(instructionDetails: "DEC HL", opcode: [0x2B], programCounter: registers.PC)
            registers.HL = registers.HL &- 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
        case 0x2E: // LD L,$n - 2E n - Loads n into L.
            logInstructionDetails(instructionDetails: "LD H,$n", opcode: [0x2E,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            registers.L = opcodes.opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
        case 0x2F: // CPL
            logInstructionDetails(instructionDetails: "CPL", opcode: [opcodes.opcode1], programCounter: registers.PC)
            registers.A = ~registers.A
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:true)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
        case 0x30: // JR NC,d
            logInstructionDetails(instructionDetails: "JR NC,$d", opcode: [opcodes.opcode1,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry))
            {
                registers.PC = registers.PC &+ 2
            }
            else
            {
                let signedOffset = Int8(bitPattern: opcodes.opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            }
            tStates = tStates + 12
        case 0x38: // JR C,d
            logInstructionDetails(instructionDetails: "JR C,$d", opcode: [opcodes.opcode1,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry))
            {
                let signedOffset = Int8(bitPattern: opcodes.opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            }
            else
            {
                registers.PC = registers.PC &+ 2
            }
            tStates = tStates + 12
        case 0x3C: // INC A
            logInstructionDetails(instructionDetails: "INC A", opcode: [opcodes.opcode1], programCounter: registers.PC)
            // flags
            registers.A = registers.A &+ 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
        case 0x3E: // LD A,n
            logInstructionDetails(instructionDetails: "LD A,$n", opcode: [opcodes.opcode1,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            registers.A = opcodes.opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
        case 0x70: // LD (HL),B
            logInstructionDetails(instructionDetails: "LD (HL),B", opcode: [opcodes.opcode1], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.B)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
        case 0x71: // LD (HL),C
            logInstructionDetails(instructionDetails: "LD (HL),C", opcode: [opcodes.opcode1], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.C)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
        case 0x72: // LD (HL),D
            logInstructionDetails(instructionDetails: "LD (HL),D", opcode: [opcodes.opcode1], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.D)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
        case 0x73: // LD (HL),E
            logInstructionDetails(instructionDetails: "LD (HL),E", opcode: [opcodes.opcode1], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.E)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
        case 0x74: // LD (HL),H
            logInstructionDetails(instructionDetails: "LD (HL),H", opcode: [opcodes.opcode1], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.H)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
        case 0x75: // LD (HL),L
            logInstructionDetails(instructionDetails: "LD (HL),L", opcode: [opcodes.opcode1], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.L)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
        case 0x76: // HALT
            logInstructionDetails(instructionDetails: "HALT", opcode: [opcodes.opcode1], programCounter: registers.PC)
            emulatorHalted = true
            tStates = tStates + 4
        case 0x77: // LD (HL),A
            logInstructionDetails(instructionDetails: "LD (HL),A", opcode: [opcodes.opcode1], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.A)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
        case 0x78: // LD A,B
            logInstructionDetails(instructionDetails: "LD A, B", opcode: [opcodes.opcode1], programCounter: registers.PC)
            registers.A = registers.B
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
        case 0x79: // LD A,C
            logInstructionDetails(instructionDetails: "LD A,C", opcode: [opcodes.opcode1], programCounter: registers.PC)
            registers.A = registers.C
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
        case 0x7A: // LD A,D
            logInstructionDetails(instructionDetails: "LD A,D", opcode: [opcodes.opcode1], programCounter: registers.PC)
            registers.A = registers.D
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
        case 0x7B: // LD A,E
            logInstructionDetails(instructionDetails: "LD A,E", opcode: [opcodes.opcode1], programCounter: registers.PC)
            registers.A = registers.E
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
        case 0x7C: // LD A,H
            logInstructionDetails(instructionDetails: "LD A,H", opcode: [opcodes.opcode1], programCounter: registers.PC)
            registers.A = registers.H
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
        case 0x7D: // LD A,L
            logInstructionDetails(instructionDetails: "LD A,L", opcode: [opcodes.opcode1], programCounter: registers.PC)
            registers.A = registers.L
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
        case 0x7E: // LD A,(HL)
            logInstructionDetails(instructionDetails: "LD A,(HL)", opcode: [opcodes.opcode1], programCounter: registers.PC)
            registers.A = mmu.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
        case 0xB1: // OR C
            logInstructionDetails(instructionDetails: "OR C", opcode: [opcodes.opcode1], programCounter: registers.PC)
            registers.A = registers.C | registers.A
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign,SetFlag:(registers.A & 0x80) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:registers.A == 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:false)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:returnParity(value: registers.A))
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry,SetFlag:false)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
        case 0xC2: // JP NZ,nn
            logInstructionDetails(instructionDetails: "JP NZ,$nn", opcode: [opcodes.opcode1,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            tStates = tStates + 10
        case 0xC3: // JP nn
            logInstructionDetails(instructionDetails: "JP $nn", opcode: [opcodes.opcode1,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            tStates = tStates + 10
        case 0xCA: // JP Z,nn
            logInstructionDetails(instructionDetails: "JP Z,$nn", opcode: [opcodes.opcode1,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            tStates = tStates + 10
        case 0xCB: //start CB opcodes
            switch opcodes.opcode2
            {
                case 0x47: // BIT 0, A
                    logInstructionDetails(instructionDetails: "BIT 0, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b00000001) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b00000001) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                    tStates = tStates + 8
                case 0x4F: // BIT 1, A
                    logInstructionDetails(instructionDetails: "BIT 1, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b00000010) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b00000010) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                    tStates = tStates + 8
                case 0x57: // BIT 2, A
                    logInstructionDetails(instructionDetails: "BIT 2, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b00000100) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b00000100) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                    tStates = tStates + 8
                case 0x5F: // BIT 3, A
                    logInstructionDetails(instructionDetails: "BIT 3, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b00001000) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b00001000) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                    tStates = tStates + 8
                case 0x67: // BIT 4, A
                    logInstructionDetails(instructionDetails: "BIT 4, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b00010000) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b00010000) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                    tStates = tStates + 8
                case 0x6F: // BIT 5, A
                    logInstructionDetails(instructionDetails: "BIT 5, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b0010000) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b0010000) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                    tStates = tStates + 8
                case 0x77: // BIT 6, A
                    logInstructionDetails(instructionDetails: "BIT 6, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b01000000) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b01000000) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                    tStates = tStates + 8
                case 0x7F: // BIT 7, A
                    logInstructionDetails(instructionDetails: "BIT 7, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign,SetFlag:(registers.A & 0b10000000) == 1)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:!((registers.A & 0b10000000) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:true)
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:!((registers.A & 0b10000000) == 1))
                    registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                    tStates = tStates + 8
                case 0xC7: // SET 0, A
                    logInstructionDetails(instructionDetails: "SET 0, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.A = registers.A | 0b00000001
                    tStates = tStates + 8
                case 0xCF: // SET 1, A
                    logInstructionDetails(instructionDetails: "SET 1, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.A = registers.A | 0b00000010
                    tStates = tStates + 8
                case 0xD7: // SET 2, A
                    logInstructionDetails(instructionDetails: "SET 2, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.A = registers.A | 0b00000100
                    tStates = tStates + 8
                case 0xDF: // SET 3, A
                    logInstructionDetails(instructionDetails: "SET 3, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.A = registers.A | 0b00001000
                    tStates = tStates + 8
                case 0xE7: // SET 4, A
                    logInstructionDetails(instructionDetails: "SET 4, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.A = registers.A | 0b00010000
                    tStates = tStates + 8
                case 0xEF: // SET 5, A
                    logInstructionDetails(instructionDetails: "SET 5, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.A = registers.A | 0b00100000
                    tStates = tStates + 8
                case 0xF7: // SET 6, A
                    logInstructionDetails(instructionDetails: "SET 6, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.A = registers.A | 0b01000000
                    tStates = tStates + 8
                case 0xFF: // SET 7, A
                    logInstructionDetails(instructionDetails: "SET 7, A", opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    registers.A = registers.A | 0b10000000
                    tStates = tStates + 8
                default:
                    logInstructionDetails(opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                    tStates = tStates + 0 // check if this is correct
            } // end CB opcodes
            registers.PC = registers.PC &+ 2
        case 0xD2: // JP NC,nn
            logInstructionDetails(instructionDetails: "JP NC,$nn", opcode: [opcodes.opcode1,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            tStates = tStates + 10
        case 0xD3: // OUT (n),A
            logInstructionDetails(instructionDetails: "OUT ($n),A", opcode: [opcodes.opcode1,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            ports[Int(opcodes.opcode2)] = registers.A
            switch opcodes.opcode2
            {
            case 0x08:
                if testBit(value: registers.A, bitPosition: 1)
                {
                    MOS6545.crtcRegisters.redBackgroundIntensity = 1  // set global background red intensity to 1 = full
                }
                if !testBit(value: registers.A, bitPosition: 1)
                {
                    MOS6545.crtcRegisters.redBackgroundIntensity = 0 // set global background red intensity to 0 = half
                }
                if testBit(value: registers.A, bitPosition: 2)
                {
                    MOS6545.crtcRegisters.greenBackgroundIntensity = 1 // set global background blue intensity to 1 = full
                }
                if !testBit(value: registers.A, bitPosition: 2)
                {
                    MOS6545.crtcRegisters.greenBackgroundIntensity = 0 // set global background blue intensity to 0 = half
                }
                if testBit(value: registers.A, bitPosition: 3)
                {
                    MOS6545.crtcRegisters.blueBackgroundIntensity = 1 // set global background green intensity to 1 = full
                }
                if !testBit(value: registers.A, bitPosition: 3)
                {
                    MOS6545.crtcRegisters.blueBackgroundIntensity = 0 // set global background green intensity to 0 = half
                }
                if testBit(value: registers.A, bitPosition: 6)
                {
                    mmu.map(readDevice: [colourRAM], writeDevice: [colourRAM], memoryLocation: 0xF800)  // swap in colour ram
                }
                if !testBit(value: registers.A, bitPosition: 6)
                {
                    mmu.map(readDevice: [pcgRAM], writeDevice: [pcgRAM], memoryLocation: 0xF800)        // swap in pcg ram
                }
            case 0x0A: break //PAK N selection - need some mechanism to map PAK number to memory device
            case 0x0B:
                if registers.A == 1
                {
                    mmu.map(readDevice: [fontROM], writeDevice: [videoRAM,pcgRAM], memoryLocation: 0xF000)  // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                }
                if registers.A == 0
                {
                    mmu.map(readDevice: [videoRAM], writeDevice: [videoRAM], memoryLocation: 0xF000)  // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                    mmu.map(readDevice: [pcgRAM], writeDevice: [pcgRAM], memoryLocation: 0xF800)  // swap video ram and pcg ram back into memory at 0xf000 for read and wrtie
                }
            case 0x0C: break // writing to port 0x0C needs no further processing
            case 0x0D: MOS6545.WriteRegister(RegNum:ports[0x0C], RegValue:ports[0x0D])
            default: logInstructionDetails(opcode: [opcodes.opcode1], programCounter: registers.PC)
            }
            registers.PC = registers.PC &+ 2
            tStates = tStates + 11
        case 0xDA: // JP C,nn
            logInstructionDetails(instructionDetails: "JP C,$nn", opcode: [opcodes.opcode1,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry))
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            tStates = tStates + 10
        case 0xDB: // IN A,(n)
            logInstructionDetails(instructionDetails: "IN A,($n)", opcode: [opcodes.opcode1,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            registers.A = ports[Int(opcodes.opcode2)]
            switch opcodes.opcode2
            {
                case 0x08: break // registers.A contains value of colour control port
                case 0x0A: break // NET selection INPUT from port - whatever this means
                case 0x0B: break // registers.A contains value of font rom control port
                case 0x0C: registers.A = MOS6545.ReadStatusRegister()
                case 0x0D: registers.A = MOS6545.ReadRegister(RegNum:ports[0x0C])
                default: logInstructionDetails(opcode: [opcodes.opcode1], programCounter: registers.PC)
            }
            registers.PC = registers.PC &+ 2
            tStates = tStates + 11
        case 0xE2: // JP PO,nn
            logInstructionDetails(instructionDetails: "JP PO,$nn", opcode: [opcodes.opcode1,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            tStates = tStates + 10
        case 0xEA: // JP PE,nn
            logInstructionDetails(instructionDetails: "JP PE,$nn", opcode: [opcodes.opcode1,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow))
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            tStates = tStates + 10
        case 0xED: // ED instructions
            switch opcodes.opcode2
            {
            case 0xB0:  // LDIR
                logInstructionDetails(instructionDetails: "LDIR", opcode: [opcodes.opcode1], programCounter: registers.PC)
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
                registers.PC = registers.PC &+ 2
                tStates = tStates + 21
            default:
                logInstructionDetails(opcode: [opcodes.opcode1,opcodes.opcode2], programCounter: registers.PC)
                registers.PC = registers.PC &+ 2
                tStates = tStates + 21  // confirm this behaviour
            }
        case 0xF2: // JP P,nn
            logInstructionDetails(instructionDetails: "JP P,$nn", opcode: [opcodes.opcode1,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            tStates = tStates + 10
        case 0xFA: // JP M,nn
            logInstructionDetails(instructionDetails: "JP M,$nn", opcode: [opcodes.opcode1,opcodes.opcode2,opcodes.opcode3], values: [opcodes.opcode2,opcodes.opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign))
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            tStates = tStates + 10
        case 0xFE: // CP n
            logInstructionDetails(instructionDetails: "CP $n", opcode: [opcodes.opcode1,opcodes.opcode2], values: [opcodes.opcode2], programCounter: registers.PC)
            let temporaryResult = registers.A &- opcodes.opcode2
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign,SetFlag:(temporaryResult & 0x80) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:temporaryResult == 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:((registers.A & 0x0F) < (opcodes.opcode2 & 0x0F)))
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:((registers.A ^ opcodes.opcode2) & (registers.A ^ temporaryResult) & 0x80 ) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:true)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry,SetFlag:registers.A < opcodes.opcode2)
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
        default:
            logInstructionDetails(opcode: [opcodes.opcode1], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 0 // check this behaviour
        } // end single opcodes
    }

    func getState() async -> CPUState
    {
        return CPUState( PC: registers.PC,
                         SP: registers.SP,
                         BC : registers.BC,
                         DE : registers.DE,
                         HL : registers.HL,
                         AltBC : registers.AltBC,
                         AltDE : registers.AltDE,
                         AltHL : registers.AltHL,
                         IX : registers.IX,
                         IY : registers.IY,
                         I: registers.I,
                         R: registers.R,
                         IM  : registers.IM,
                         IFF1 : registers.IFF1,
                         IFF2 : registers.IFF2,
                         A: registers.A,
                         F: registers.F,
                         B: registers.B,
                         C: registers.C,
                         D: registers.D,
                         E: registers.E,
                         H: registers.H,
                         L: registers.L,
                         AltA: registers.AltA,
                         AltF: registers.AltF,
                         AltB: registers.AltB,
                         AltC: registers.AltC,
                         AltD: registers.AltD,
                         AltE: registers.AltE,
                         AltH: registers.AltH,
                         AltL: registers.AltL,
                         
                         memoryDump: mmu.memorySlice(address: registers.PC & 0xFF00, size: 0x100),
                         ports: ports,
                         VDU : videoRAM.bufferTransform(),
                         CharRom : fontROM.bufferTransform(),
                         PcgRam : pcgRAM.bufferTransform(),
                         ColourRam : colourRAM.bufferTransform(),
                             
                         vmR1_HorizDisplayed : MOS6545.ReadRegister(RegNum: 1),
                         vmR6_VertDisplayed : MOS6545.ReadRegister(RegNum: 6),
                         vmR9_ScanLinesMinus1 : MOS6545.ReadRegister(RegNum: 9),
                         vmR10_CursorStartAndBlinkMode : MOS6545.ReadRegister(RegNum: 10),
                         vmR11_CursorEnd : MOS6545.ReadRegister(RegNum: 11),
                         vmR12_DisplayStartAddrH : MOS6545.ReadRegister(RegNum: 12),
                         vmR13_DisplayStartAddrL : MOS6545.ReadRegister(RegNum: 13),
                         vmR14_CursorPositionH : MOS6545.ReadRegister(RegNum: 14),
                         vmR15_CursorPositionL : MOS6545.ReadRegister(RegNum: 15),
                         
                         vmRedBackgroundIntensity: MOS6545.crtcRegisters.redBackgroundIntensity,
                         vmGreenBackgroundIntensity: MOS6545.crtcRegisters.greenBackgroundIntensity,
                         vmBlueBackgroundIntensity: MOS6545.crtcRegisters.blueBackgroundIntensity
                         
            )
    }
}

