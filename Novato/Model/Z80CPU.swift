import Foundation

actor Z80CPU
{
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
    
    var runcycles : UInt64 = 0
    var CPUstarttime : Date = Date()
    var CPUendtime : Date = Date()
    
    var emulatorHalted : Bool = false

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
        
        MOS6545.SetCursorDutyCycle()
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
        mainRAM.fillMemoryFromFile(FileName: "hello", FileExtension: "bin")
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
        CPUstarttime = Date()
        let prefetch = fetch(ProgramCounter : registers.PC)
        MOS6545.ResetCursorDutyCycle()
        if !emulatorHalted
        {
            execute(opcodes : prefetch)
        }
        CPUendtime = Date()
        let ken = CPUendtime.timeIntervalSince1970-CPUstarttime.timeIntervalSince1970
        print("Instruction took ",ken / Double(runcycles)*1000*1000," microseconds to execute")
        runcycles = 0
    }

    func stop()
    {
        isRunning = false
        stepTask?.cancel()
    }

    private func fetch( ProgramCounter : UInt16) -> (UInt8,UInt8,UInt8,UInt8)
    {
        return ( opcode1 : mmu.readByte(address: ProgramCounter),
                 opcode2 : mmu.readByte(address: IncrementRegPair(BaseValue : ProgramCounter,Increment : 1)),
                 opcode3 : mmu.readByte(address: IncrementRegPair(BaseValue : ProgramCounter,Increment : 2)),
                 opcode4 : mmu.readByte(address: IncrementRegPair(BaseValue : ProgramCounter,Increment : 3))
                )
    }

    func IncrementRegPair ( BaseValue  : UInt16, Increment : UInt16 ) -> UInt16
    
    {
        return BaseValue &+ Increment
    }
    
    func DecrementRegPair ( BaseValue  : UInt16, Decrement : UInt16 ) -> UInt16
    
    {
        return BaseValue &- Decrement
    }
    
    func IncrementReg ( BaseValue  : UInt8, Increment : UInt8 ) -> UInt8
    
    {
        return BaseValue &+ Increment
        // flag code goes here
    }
    
    func DecrementReg ( BaseValue  : UInt8, Decrement : UInt8 ) -> UInt8
    
    {
        return BaseValue &- Decrement
        // flag code goes here
    }
    
    func UpdateProgramCounter ( CurrentPC : UInt16, Offset : UInt8 ) -> UInt16
    
    {
     return CurrentPC &+ UInt16(Int8(bitPattern: Offset))
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
    
    func SetFlags ( FlagRegister : UInt8, Flag : Z80Flags ) -> UInt8
    {
        let result = FlagRegister | Flag.rawValue
        return result
    }
    
    func ResetFlags ( FlagRegister : UInt8, Flag : Z80Flags ) -> UInt8
    {
        let result = FlagRegister & Flag.rawValue
        return result
    }

    private func execute( opcodes: ( opcode1 : UInt8, opcode2 : UInt8, opcode3 : UInt8, opcode4 : UInt8))
    {
        switch opcodes.opcode1
        {
        case 0x00: // NOP
            print("Executed NOP @ "+String(format:"%04X",registers.PC))
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x01: // LD BC, nn
            print("Executed LD BC, nn @ "+String(format:"%04X",registers.PC))
            registers.BC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
        case 0x04: // INC B
            print("Unimplemented opcode "+String(format: "%02X", opcodes.opcode1) + " @ "+String(format:"%04X",registers.PC))
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x05: // DEC B
            print("Unimplemented opcode "+String(format: "%02X", opcodes.opcode1) + " @ "+String(format:"%04X",registers.PC))
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x11: // LD DE, nn
            print("Executed LD DE, nn @ "+String(format:"%04X",registers.PC))
            registers.DE = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
        case 0x21: // LD HL, nn
            print("Executed LD HL, nn @ "+String(format:"%04X",registers.PC))
            registers.HL = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
        case 0x28: // JR Z,n
            print("Executed JR Z, n @ "+String(format:"%04X",registers.PC) + " ["+String(format:"%02X",opcodes.opcode1)+","+String(format:"%02X",opcodes.opcode2)+"]")
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:opcodes.opcode2+2)
            }
            else
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
            }
        case 0x23: // INC HL
            print("Executed INC HL @ "+String(format:"%04X",registers.PC))
            registers.HL = IncrementRegPair(BaseValue:registers.HL,Increment:1)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x3C: // INC A
            print("Executed INC A @ "+String(format:"%04X",registers.PC))
            registers.A = IncrementReg(BaseValue:registers.A,Increment:1)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x3E: // LD A, n
            print("Executed LD A, n @ "+String(format:"%04X",registers.PC) + " ["+String(format:"%02X",opcodes.opcode1)+","+String(format:"%02X",opcodes.opcode2)+"]")
            registers.A = opcodes.opcode2
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
        case 0x76: // HALT
            print("Executed HALT @ "+String(format:"%04X",registers.PC))
            emulatorHalted = true
        case 0x77: // LD (HL), A
            print("Executed LD (HL), A @ "+String(format:"%04X",registers.PC))
            mmu.writeByte(address: registers.HL, value: registers.A)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x78: // LD A, B
            print("Executed LD A, B @ "+String(format:"%04X",registers.PC))
            registers.A = registers.B
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x79: // LD A,C
            print("Executed LD A, C @ "+String(format:"%04X",registers.PC))
            registers.A = registers.C
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x7A: // LD A,D
            print("Executed LD A, D @ "+String(format:"%04X",registers.PC))
            registers.A = registers.D
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x7B: // LD A,E
            print("Executed LD A, E @ "+String(format:"%04X",registers.PC))
            registers.A = registers.E
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x7C: // LD A,H
            print("Executed LD A, H @ "+String(format:"%04X",registers.PC))
            registers.A = registers.H
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x7D: // LD A,L
            print("Executed LD A, L @ "+String(format:"%04X",registers.PC))
            registers.A = registers.L
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0xC2: // JP NZ,nn
            print("Executed JP NZ,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
            else
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
        case 0xC3: // JP nn
            print("Executed JP nn @ "+String(format:"%04X",registers.PC))
            registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
        case 0xCA: // JP Z,nn
            print("Executed JP Z,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            else
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
        case 0xD2: // JP NC,nn
            print("Executed JP NC,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry))
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
            else
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
        case 0xD3: // OUT (n),A
            print("Executed OUT (n),A @ "+String(format:"%04X",registers.PC) + " ["+String(format:"%02X",opcodes.opcode1)+","+String(format:"%02X",opcodes.opcode2)+"]")
            ports[Int(opcodes.opcode2)] = registers.A
            switch opcodes.opcode2
            {
                case 0x0C: break // writing to port 0x0C needs no further processing
                case 0x0D: MOS6545.WriteRegister(RegNum:ports[0x0C], RegValue:ports[0x0D])
                default: print("Whicha port ? Disaport !"+String(opcodes.opcode2))
            }
        
            //Writing to port 0x0C writes a register number
            //Writing port 0x0D writes the register selected on port 0x0C
            
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
        case 0xDA: // JP C,nn
            print("Executed JP C,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry))
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            else
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
        case 0xDB: // IN A,(n)
            print("Executed IN A,(n) @ "+String(format:"%04X",registers.PC) + " ["+String(format:"%02X",opcodes.opcode1)+","+String(format:"%02X",opcodes.opcode2)+"]")
            registers.A = ports[Int(opcodes.opcode2)]
            switch opcodes.opcode2
            {
                case 0x0C: registers.A = MOS6545.ReadStatusRegister()
                case 0x0D: registers.A = MOS6545.ReadRegister(RegNum:ports[0x0C])
                default: print("Whicha port ? Disaport !"+String(opcodes.opcode2))
            }
            
            //Reading port 0x0D reads the register selected on port 0x0C
            //Reading from port 0x0C reads the status register
            
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
        case 0xE2: // JP PO,nn
            print("Executed JP PO,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow))
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
            else
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
        case 0xEA: // JP PE,nn
            print("Executed JP PE,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow))
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            else
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
        case 0xED: // ED instructions
            switch opcodes.opcode2
            {
            case 0xB0:  // LDIR
                // doesn't cater for transfers to non VDU RAM
                // needs flags to be updated
                // S is not affected.
                // Z is not affected.
                // H is reset.
                // P/V is set if BC-1 != 0; otherwise, it is reset.
                // N is reset.
                // C is not affected.
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:false)
             //   registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:((registers.A ^ opcodes.opcode2) & (registers.A ^ temporaryResult) & 0x80 ) != 0)
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                if registers.BC == 0
                {
                    registers.BC = 0xFFFF
                }
                while registers.BC > 0
                {
                    mmu.writeByte(address: registers.DE, value : mmu.readByte(address: registers.HL))
                    registers.HL = IncrementRegPair(BaseValue:registers.HL,Increment:1)
                    registers.DE = IncrementRegPair(BaseValue:registers.DE,Increment:1)
                    registers.BC = DecrementRegPair(BaseValue:registers.BC,Decrement:1)
                }
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
            default:
                print("Unknown opcode "+String(format: "%02X", opcodes.opcode1)+String(format: "%02X", opcodes.opcode2) + " @ "+String(format:"%04X",registers.PC))
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
            }
        case 0xF2: // JP P,nn
            print("Executed JP P,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign))
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
            else
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
        case 0xFA: // JP M,nn
            print("Executed JP M,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign))
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            else
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
        case 0xFE: // CP n
            print("Executed CP n @ "+String(format:"%04X",registers.PC) + " ["+String(format:"%02X",opcodes.opcode1)+","+String(format:"%02X",opcodes.opcode2)+"]")
//            sign: (res8 & 0x80) != 0,
//            zero: a == n,
//            halfCarry: ((a & 0x0F) < (n & 0x0F)),
//            parityOverflow: ((a ^ n) & (a ^ res8) & 0x80) != 0,
//            subtract: true,
//            carry: a < n
            let temporaryResult = registers.A &- opcodes.opcode2
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign,SetFlag:(temporaryResult & 0x80) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:temporaryResult == 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:((registers.A & 0x0F) < (opcodes.opcode2 & 0x0F)))
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:((registers.A ^ opcodes.opcode2) & (registers.A ^ temporaryResult) & 0x80 ) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:true)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry,SetFlag:registers.A < opcodes.opcode2)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
        default:
            print("Unknown opcode "+String(format: "%02X", opcodes.opcode1) + " @ "+String(format:"%04X",registers.PC))
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        }
        runcycles = runcycles+1
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
                         
                         memoryDump: mmu.memorySlice(address: registers.PC, size: 0x100),
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
                         vmCursorBlinkCounter: MOS6545.crtcRegisters.CursorBlinkCounter,
                         vmCursorFlashLimit: MOS6545.crtcRegisters.CursorFlashLimit
            )
    }
}

