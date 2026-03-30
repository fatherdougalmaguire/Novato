import Foundation

actor microbee
{
    enum z80Flags : UInt8
    {
        case Carry = 0x01               // 00000001
        case Negative = 0x02            // 00000010
        case ParityOverflow = 0x04      // 00000100
        case Y = 0x08                   // 00001000
        case HalfCarry = 0x10           // 00010000
        case X = 0x20                   // 00100000
        case Zero = 0x40                // 01000000
        case Sign = 0x80                // 10000000
    }

    struct z80FastFlags
    {
        static let lookupSZP: [UInt8] =
        {
            (0...255).map
            { counter in
                var tempF: UInt8 = 0
                if (counter & Int(z80Flags.Sign.rawValue)) != 0
                {
                    tempF |= z80Flags.Sign.rawValue             // Set sign flag is bit 7 is set
                }
                if counter == 0
                {
                    tempF |= z80Flags.Zero.rawValue             // set zero flag is result is 0
                }
                let bitsSet = counter.nonzeroBitCount
                if bitsSet % 2 == 0
                {
                    tempF |= z80Flags.ParityOverflow.rawValue   // set parity flag if even number of bits set
                }
                
                return tempF
            }
        }()
        
        @inline(__always)
        static func logicHelper(tempResult: UInt8) -> (returnResult: UInt8, returnFlags: UInt8)
        {
            var tempFlags = lookupSZP[Int(tempResult)]                                                     // Lookup Sign,Zero,Parity/Overflow
            
            tempFlags = tempFlags & ~z80Flags.Negative.rawValue                                            // Reset Negative for AND
            tempFlags = tempFlags & ~z80Flags.Carry.rawValue                                               // Reset Carry for AND
            tempFlags = tempFlags | z80Flags.HalfCarry.rawValue                                            // Set Negative for AND
            
            return (tempResult, tempFlags)
        }
        
        @inline(__always)
        static func incHelper(operand: UInt8, currentFlags: UInt8) -> (returnResult: UInt8, returnFlags: UInt8)
        {
            let tempResult = operand &+ 1                                                                   // Wrapping addition
            
            var tempFlags = lookupSZP[Int(tempResult)] & ~0x04                                              // Lookup Sign,Zero,Parity/Overflow and set Parity/Overflow to 0
            
            tempFlags = tempFlags | (currentFlags & z80Flags.Carry.rawValue)                               // Preserve Carry
            
            tempFlags = tempFlags & ~z80Flags.Negative.rawValue                                            // Reset Negative for subtraction
            
            if operand == 0x7F
            {
                tempFlags |= z80Flags.ParityOverflow.rawValue                                              // set Overflow if operand is 127
            }
            
            if (operand & 0x0F) == 0x0F
            {
                tempFlags |= z80Flags.HalfCarry.rawValue                                                    // set Half Carry if carry from bit 3 to bit 4
            }

            return (tempResult, tempFlags)
        }
        
        @inline(__always)
        static func decHelper(operand: UInt8, currentFlags: UInt8) -> (returnResult: UInt8, returnFlags: UInt8)
        {
            let tempResult = operand &- 1
            
            var tempFlags = lookupSZP[Int(tempResult)] & ~z80Flags.ParityOverflow.rawValue          // Lookup Sign,Zero,Parity/Overflow and set Parity/Overflow to 0
            
            tempFlags = tempFlags | (currentFlags & z80Flags.Carry.rawValue)                                    // Preserve Carry
            
            tempFlags = tempFlags | z80Flags.Negative.rawValue                                                 // Set Negative for subtraction
            
            if operand == z80Flags.Sign.rawValue
            {
                tempFlags = tempFlags | z80Flags.ParityOverflow.rawValue                                       // set Overflow if operand is -128
            }
            
            if (operand & 0x0F) == 0x00
            {
                tempFlags = tempFlags | z80Flags.HalfCarry.rawValue                                           // set Half Carry if borrow from bit 4 to bit 3
            }
            
            return (tempResult, tempFlags)
        }
        
        @inline(__always)
        static func addHelper(operand1: UInt8, operand2: UInt8) -> (returnResult: UInt8, returnFlags: UInt8)
        {
            let (tempResult, carry) = operand1.addingReportingOverflow(operand2)
            
            var tempFlags = lookupSZP[Int(tempResult)] & ~z80Flags.ParityOverflow.rawValue  // Lookup Sign,Zero,Parity/Overflow and set Parity/Overflow to 0
            
            print(tempFlags)
            
            if carry
            {
                tempFlags = tempFlags | z80Flags.Carry.rawValue                                        // Set Carry
            }

            tempFlags = tempFlags | ~z80Flags.Negative.rawValue                                        // Reset Negative for addition
            
            if ((operand1 ^ tempResult) & (operand2 ^ tempResult) & z80Flags.Sign.rawValue) != 0
            {
                tempFlags = tempFlags | z80Flags.ParityOverflow.rawValue                              // set Overflow if operand1 and operand2 have same sign but tempresult has a different sign
            }
            
            if (operand1 & 0x0F) + (operand2 & 0x0F) > 0x0F                                // set Half Carry if carry from bit 3 to bit 4
            {
                tempFlags = tempFlags | z80Flags.HalfCarry.rawValue
            }
            
            return (tempResult, tempFlags)
        }
        
        @inline(__always)
        static func subHelper(operand1: UInt8, operand2: UInt8) -> (returnResult: UInt8, returnFlags: UInt8)
        {
            let (tempResult, carry) = operand1.subtractingReportingOverflow(operand2)
            
            var tempFlags = lookupSZP[Int(tempResult)] & ~z80Flags.ParityOverflow.rawValue              // Lookup Sign,Zero,Parity/Overflow and set Parity/Overflow to 0

            if carry
            {
                tempFlags = tempFlags | z80Flags.Carry.rawValue                                                   // Set Carry
            }

            tempFlags = tempFlags | z80Flags.Negative.rawValue                                                    // Set Negative for subtraction
            
            if ((operand1 ^ operand2) & z80Flags.Sign.rawValue != 0) && ((operand1 ^ tempResult) & z80Flags.Sign.rawValue != 0)     // set Overflow if operand1 and operand2 have different signs
            {
                tempFlags = tempFlags | z80Flags.ParityOverflow.rawValue
            }
            
            if (operand1 & 0x0F) < (operand2 & 0x0F)
            {
                tempFlags = tempFlags | z80Flags.HalfCarry.rawValue                                               // set Half Carry if borrow from bit 4 to bit 3
            }
            
            return (tempResult, tempFlags)
        }
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
        
        var IXH : UInt8 = 0         // Index Register IX - high byte - 8 bit
        var IXL : UInt8 = 0         // Index Register IX - low byte - 8 bit
        var IYH : UInt8 = 0         // Index Register IY - high byte - 8 bit
        var IYL : UInt8 = 0         // Index Register IY - low byte - 8 bit
        
        var SPH : UInt8 = 0x7F         // Index Register SP - high byte - 8 bit
        var SPL : UInt8 = 0x00      // Index Register SP - low byte - 8 bit
        var PCH : UInt8 = 0x80         // Index Register PC - high byte - 8 bit
        var PCL : UInt8 = 0x00         // Index Register PC - low byte - 8 bit
        
        var IX : UInt16             // Index Register IX - 16 bit
        {
            get
            {
                return UInt16(IXH) << 8 | UInt16(IXL)
            }
            set
            {
                IXH = UInt8(newValue >> 8)
                IXL = UInt8(newValue & 0xFF)
            }
        }
        
        var IY : UInt16             // Index Register IY - 16 bit
        {
            get
            {
                return UInt16(IYH) << 8 | UInt16(IYL)
            }
            set
            {
                IYH = UInt8(newValue >> 8)
                IYL = UInt8(newValue & 0xFF)
            }
        }
        
        var SP : UInt16           // Stack Pointer - 16 bit
        {
            get
            {
                return UInt16(SPH) << 8 | UInt16(SPL)
            }
            set
            {
                SPH = UInt8(newValue >> 8)
                SPL = UInt8(newValue & 0xFF)
            }
        }
        
        var PC : UInt16             // Program Counter - 16 bit
        {
            get
            {
                return UInt16(PCH) << 8 | UInt16(PCL)
            }
            set
            {
                PCH = UInt8(newValue >> 8)
                PCL = UInt8(newValue & 0xFF)
            }
        }
        
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
        var IFF1 : Bool = false     // Interrupt Flip-flop 1
        var IFF2 : Bool = false     // Interrupt Flip-flop 2
    }
    
    private let z80Disassembler = Z80Disassembler()
    
    private var z80Queue = ContiguousArray<UInt16>(repeating: 0, count: 16)
    private var z80QueueFilled = ContiguousArray<Bool>(repeating: false, count: 16)
    private var z80QueueHead = 0
    
    private var breakpoints = SIMD16<UInt16>(repeating: 0x0000)
    private var breakpointMask = SIMD16<UInt16>(repeating: 0x0000)
    
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
    //    bit 1 Cassette data out
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
    
    private(set) var emulatorState : emulatorState = .stopped
    private(set) var executionMode : executionMode = .continuous
    
    private var interruptPending = false
    
    var crtc = CRTC()
    
    var mmu = memoryMapper()
    
    let mainRAM = memoryBlock(size: 0x8000)
    let basicROM = memoryBlock(size: 0x4000, deviceType : .ROM)
    let pakROM = memoryBlock(size: 0x2000, deviceType : .ROM)
    let netROM = memoryBlock(size: 0x1000, deviceType : .ROM)
    let videoRAM = memoryBlock(size: 0x800)
    let pcgRAM = memoryBlock(size: 0x800)
    let colourRAM = memoryBlock(size: 0x800)
    let fontROM = memoryBlock(size: 0x1000, deviceType : .ROM)
    
    init()
    {
        mmu.map(readDevice: mainRAM, writeDevice: mainRAM, memoryLocation: 0x0000)       // 32K System RAM
        mmu.map(readDevice: basicROM, writeDevice: basicROM, memoryLocation: 0x8000)     // 16K BASIC ROM
        mmu.map(readDevice: pakROM, writeDevice: pakROM , memoryLocation: 0xC000)        // 8K Optional ROM
        mmu.map(readDevice: netROM, writeDevice: netROM, memoryLocation: 0xE000)         // 4K Net ROM
        mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)     // 2K Video RAM
        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)         // 2K PCG RAM
        
        basicROM.fillMemoryFromFile(fileName: "basic_5.22e", fileExtension: "rom")
        pakROM.fillMemoryFromFile(fileName: "wordbee_1.2", fileExtension: "rom")
        netROM.fillMemoryFromFile(fileName: "telcom_1.0", fileExtension: "rom")
        fontROM.fillMemoryFromFile(fileName: "charrom", fileExtension: "bin")
        
        mainRAM.fillMemoryFromFile(fileName: "demo", fileExtension: "bin", memOffset: 0x900)
    }
    private var runTask: Task<Void, Never>?
    
    func updateBreakpoints(index: Int, value: UInt16, mask: Bool) async
    {
        breakpoints[index] = value
        breakpointMask[index] = (mask ? 1 : 0)
    }
    
    func ClearVideoMemory()
    {
        videoRAM.fillMemory(memValue : 0x20)
    }
    
    func splashScreen()
    {
        videoRAM.fillMemory(memValue: 0x20)
        colourRAM.fillMemory(memValue: 0x02)
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
    }
    
    func reset()
    {
        //confirm Z80 and 6545 reset behaviour
        registers.A =  0
        registers.F =  0
        registers.B =  0
        registers.C =  0
        registers.D =  0
        registers.E =  0
        registers.H =  0
        registers.L =  0
        
        registers.altA =  0
        registers.altF =  0
        registers.altB =  0
        registers.altC =  0
        registers.altD =  0
        registers.altE =  0
        registers.altH =  0
        registers.altL =  0
        
        registers.AF =  0
        registers.BC =  0
        registers.DE =  0
        registers.HL =  0
        
        registers.altAF = 0
        registers.altBC = 0
        registers.altDE =  0
        registers.altHL =  0

        registers.I =  0
        registers.R =  0
        
        registers.IM =  0
        registers.IFF1 = false
        registers.IFF2 = false
        
        registers.IX =  0
        registers.IY =  0
        
        registers.PC =  0x8000
        registers.SP =  0x7FFF
        
        tStates = 0
        
        emulatorState = .stopped
        executionMode = .continuous
        
        interruptPending = false
        
        ports.indices.forEach { ports[$0] = 0 }
        
        z80Queue = ContiguousArray<UInt16>(repeating: 0, count: 16)
        z80QueueFilled = ContiguousArray<Bool>(repeating: false, count: 16)
        z80QueueHead = 0
        
        breakpoints = SIMD16<UInt16>(repeating: 0x0000)
        breakpointMask = SIMD16<UInt16>(repeating: 0x0000)
        
        crtc.registers.R0 = 0x00
        crtc.registers.R1 = 0x40
        crtc.registers.R2 = 0x00
        crtc.registers.R3 = 0x00
        crtc.registers.R4 = 0x12
        crtc.registers.R5 = 0x00
        crtc.registers.R6 = 0x10
        crtc.registers.R7 = 0x00
        crtc.registers.R8 = 0x00
        crtc.registers.R9 = 0x0F
        crtc.registers.R10 = 0x20
        crtc.registers.R11 = 0x00
        crtc.registers.R12 = 0x00
        crtc.registers.R13 = 0x00
        crtc.registers.R14 = 0x00
        crtc.registers.R15 = 0x00
        crtc.registers.R16 = 0x00
        crtc.registers.R17 = 0x00
        crtc.registers.R18 = 0x00
        crtc.registers.R19 = 0x00
        
        crtc.registers.statusRegister = 0b10000000
        
        crtc.registers.redBackgroundIntensity = 0x00
        crtc.registers.greenBackgroundIntensity = 0x00
        crtc.registers.blueBackgroundIntensity = 0x00
        
        mmu.map(readDevice: mainRAM, writeDevice: mainRAM, memoryLocation: 0x0000)       // 32K System RAM
        mmu.map(readDevice: basicROM, writeDevice: basicROM, memoryLocation: 0x8000)     // 16K BASIC ROM
        mmu.map(readDevice: pakROM, writeDevice: pakROM , memoryLocation: 0xC000)        // 8K Optional ROM
        mmu.map(readDevice: netROM, writeDevice: netROM, memoryLocation: 0xE000)         // 4K Net ROM
        mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)     // 2K Video RAM
        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)         // 2K PCG RAM
        
        basicROM.fillMemoryFromFile(fileName: "basic_5.22e", fileExtension: "rom")
        pakROM.fillMemoryFromFile(fileName: "wordbee_1.2", fileExtension: "rom")
        netROM.fillMemoryFromFile(fileName: "telcom_1.0", fileExtension: "rom")
        fontROM.fillMemoryFromFile(fileName: "charrom", fileExtension: "bin")
        
        mainRAM.fillMemoryFromFile(fileName: "demo", fileExtension: "bin", memOffset: 0x900)
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
        emulatorState = .running
        
        registers.IFF1 = false
        registers.IFF2 = false
        
        // check this
        registers.SP &-= 2
        mmu.writeByte(address: registers.SP, value: registers.PCH)
        mmu.writeByte(address: registers.SP + 1, value: registers.PCL)
        registers.PC = 0x0038
    }
    
    func writeToMemory(address: UInt16, value: UInt8)
    {
        mmu.writeByte(address: address, value: value)
    }
    
    func updatePC(address: UInt16)
    {
        registers.PC = address

        z80Queue[z80QueueHead] = registers.PC
        z80QueueFilled[z80QueueHead] = true
        z80QueueHead = (z80QueueHead + 1) % 16
    
    }
    
    func TestFlags ( FlagRegister : UInt8, Flag : z80Flags ) -> Bool
    
    {
        return FlagRegister & Flag.rawValue != 0
    }
    
    func UpdateFlags ( FlagRegister : UInt8, Flag : z80Flags, SetFlag : Bool ) -> UInt8
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
        
        let currentPCVector = SIMD16<UInt16>(repeating: UInt16(registers.PC))
        let addressMatch = (currentPCVector .== breakpoints)
        
        if any(addressMatch .& (breakpointMask .!= 0))
        {
        pause()
            // wrong state
            // wrong PC
        }
        executeInstruction()
        appLog.cpu.debug("Cumulative T-states: \(String(self.tStates))")
        pollInterrupt()
    }

    @inline(__always)
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
        switch opcode1
        {
        case 0x00: // NOP - 00 - No operation is performed
            logInstructionDetails(instructionDetails: "NOP", opcode: [0x00], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x01: // LD BC,nn - 01 n n - Loads $nn into BC
            logInstructionDetails(instructionDetails: "LD BC,$nn", opcode: [0x01], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.BC = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.PC = registers.PC &+ 3
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0x02: // LD (BC),A - 02 - Stores A into the memory location pointed to by BC
            logInstructionDetails(instructionDetails: "LD (BC),A", opcode: [0x02], programCounter: registers.PC)
            mmu.writeByte(address: registers.BC, value: registers.A)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x03: // INC BC - 03 - Adds one to BC
            logInstructionDetails(instructionDetails: "INC BE", opcode: [0x03], programCounter: registers.PC)
            registers.DE = registers.BC &+ 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x04: // INC B - 04 - Adds one to B
            logInstructionDetails(instructionDetails: "INC B", opcode: [0x04], programCounter: registers.PC)
            (registers.B,registers.F) = z80FastFlags.incHelper(operand: registers.B, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x05: // DEC B - 05 - Subtracts one from B
            logInstructionDetails(instructionDetails: "DEC B", opcode: [0x05], programCounter: registers.PC)
            (registers.B,registers.F) = z80FastFlags.decHelper(operand: registers.B, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x06: // LD B,$n - 06 n - Loads $n into B
            logInstructionDetails(instructionDetails: "LD B,$n", opcode: [0x06], values: [opcode2], programCounter: registers.PC)
            registers.B = opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x07: // RLCA - 07 - The contents of A are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0
            logInstructionDetails(instructionDetails: "RLCA", opcode: [0x07], programCounter: registers.PC)
            let previousA = registers.A
            registers.A = (previousA << 1) | (previousA >> 7)
            let carry = registers.A & 0x01
            registers.F = (registers.F & 0xEC) | carry
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x08: // EX AF,AF' - 08 - Adds one to Exchanges the 16-bit contents of AF and AF'
            logInstructionDetails(instructionDetails: "EX AF,AF'", opcode: [0x08], programCounter: registers.PC)
            let tempResult = registers.AF
            registers.AF = registers.altAF
            registers.altAF = tempResult
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x09: // ADD HL,BC - 09 - The value of BC is added to HL
            logInstructionDetails(instructionDetails: "ADD HL,BC", opcode: [0x09], programCounter: registers.PC)
            let tempResult = registers.HL &+ registers.BC
            let halfCarry = UInt8((registers.HL ^ registers.BC ^ tempResult) & 0x1000)
            let carrytempResult = UInt32(registers.HL) + UInt32(registers.BC)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.HL = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = registers.F | halfCarry
            registers.PC = registers.PC &+ 1
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0x0A: // LD A,(BC) - 0A - Loads the value pointed to by BC into A
            logInstructionDetails(instructionDetails: "LD A,(BC)", opcode: [0x0A], programCounter: registers.PC)
            registers.A = mmu.readByte(address: registers.BC)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x0B: // DEC BC - 0B - Subtracts one from BC
            logInstructionDetails(instructionDetails: "DEC BC", opcode: [0x0B], programCounter: registers.PC)
            registers.BC = registers.BC &- 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x0C: // INC C - 0C - Adds one to C
            logInstructionDetails(instructionDetails: "INC C", opcode: [0x0C], programCounter: registers.PC)
            (registers.C,registers.F) = z80FastFlags.incHelper(operand: registers.C, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x0D: // DEC C - 0D - Subtracts one from C
            logInstructionDetails(instructionDetails: "DEC C", opcode: [0x0D], programCounter: registers.PC)
            (registers.C,registers.F) = z80FastFlags.decHelper(operand: registers.C, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x0E: // LD C,$n - 0E n - Loads n into C
            logInstructionDetails(instructionDetails: "LD C,$n", opcode: [0x0E], values: [opcode2], programCounter: registers.PC)
            registers.C = opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x0F: // RRCA - 0F - The contents of A are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7
            logInstructionDetails(instructionDetails: "RRCA", opcode: [0x0F], programCounter: registers.PC)
            let previousA = registers.A
            registers.A = (previousA >> 1) | (previousA << 7)
            let carry = registers.A >> 7
            registers.F = (registers.F & 0xEC) | carry
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x10: // DJNZ $d - 10 d - The B register is decremented, and if not zero, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode.
            logInstructionDetails(instructionDetails: "DJNZ $d", opcode: [0x10], values: [opcode2], programCounter: registers.PC)
            registers.B = registers.B &- 1
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
            logInstructionDetails(instructionDetails: "LD DE,$nn", opcode: [0x11], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.DE = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.PC = registers.PC &+ 3
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0x12: // LD (DE),A - 12 - Stores A into the memory location pointed to by DE
            logInstructionDetails(instructionDetails: "LD (DE),A", opcode: [0x12], programCounter: registers.PC)
            mmu.writeByte(address: registers.DE, value: registers.A)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x13: // INC DE - 13 - Adds one to DE
            logInstructionDetails(instructionDetails: "INC DE", opcode: [0x13], programCounter: registers.PC)
            registers.DE = registers.DE &+ 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x14: // INC D - 14 - Adds one to D
            logInstructionDetails(instructionDetails: "INC D", opcode: [0x14], programCounter: registers.PC)
            (registers.D,registers.F) = z80FastFlags.incHelper(operand: registers.D, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x15: // DEC D - 15 - Subtracts one from D
            logInstructionDetails(instructionDetails: "DEC D", opcode: [0x15], programCounter: registers.PC)
            (registers.D,registers.F) = z80FastFlags.decHelper(operand: registers.D, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x16: // LD D,$n - 16 n - Loads $n into D
            logInstructionDetails(instructionDetails: "LD D,$n", opcode: [0x16], values: [opcode2], programCounter: registers.PC)
            registers.D = opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x17: // RLA - 17 - The contents of A are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0
            logInstructionDetails(instructionDetails: "RLA", opcode: [0x17], programCounter: registers.PC)
            let previousA = registers.A
            let oldCarry = registers.F & 0x01
            registers.A = (previousA << 1) | oldCarry
            let newCarry = (previousA >> 7) & 0x01
            registers.F = (registers.F & 0xEC) | newCarry
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x18: // JR d - 18 d - The signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR $d", opcode: [0x18], values: [opcode2], programCounter: registers.PC)
            let signedOffset = Int8(bitPattern: opcode2)
            let displacement = Int16(signedOffset)
            registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            tStates = tStates + 12
        case 0x19: // ADD HL,DE - 19 - The value of DE is added to HL
            logInstructionDetails(instructionDetails: "ADD HL,DE", opcode: [0x19], programCounter: registers.PC)
            let tempResult = registers.HL &+ registers.DE
            let halfCarry = UInt8((registers.HL ^ registers.DE ^ tempResult) & 0x1000)
            let carrytempResult = UInt32(registers.HL) + UInt32(registers.DE)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.HL = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = registers.F | halfCarry
            registers.PC = registers.PC &+ 1
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0x1A: // LD A,(DE) - 1A - Loads the value pointed to by DE into A
            logInstructionDetails(instructionDetails: "LD A,(DE)", opcode: [0x1A], programCounter: registers.PC)
            registers.A = mmu.readByte(address: registers.DE)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x1B: // DEC DE - 1B - Subtracts one from DE
            logInstructionDetails(instructionDetails: "DEC DE", opcode: [0x1B], programCounter: registers.PC)
            registers.DE = registers.DE &- 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x1C: // INC E - 14 - Adds one to E
            logInstructionDetails(instructionDetails: "INC E", opcode: [0x1C], programCounter: registers.PC)
            (registers.E,registers.F) = z80FastFlags.incHelper(operand: registers.E, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x1D: // DEC E - 1D - Subtracts one from E
            logInstructionDetails(instructionDetails: "DEC E", opcode: [0x1D], programCounter: registers.PC)
            (registers.E,registers.F) = z80FastFlags.decHelper(operand: registers.E, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x1E: // LD E,$n - 1E n - Loads $n into E
            logInstructionDetails(instructionDetails: "LD E,$n", opcode: [0x1E], values: [opcode2], programCounter: registers.PC)
            registers.E = opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x1F: // RRA - 1F - The contents of A are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7
            logInstructionDetails(instructionDetails: "RRA", opcode: [0x1F], programCounter: registers.PC)
            let previousA = registers.A
            let oldCarry = registers.F & 0x01
            registers.A = (previousA >> 1) | (oldCarry << 7)
            let newCarry = previousA  & 0x01
            registers.F = (registers.F & 0xEC) | newCarry
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x20: // JR NZ,$d - 20 d - If the zero flag is unset, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR NZ,$d", opcode: [0x20], values: [opcode2], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
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
            registers.HL = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.PC = registers.PC &+ 3
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0x22: // LD ($nn),HL - 22 n n - Stores HL into the memory location pointed to by $nn.
            logInstructionDetails(instructionDetails: "LD ($nn),HL", opcode: [0x22], values: [opcode2,opcode3], programCounter: registers.PC)
            let tempResult = UInt16(opcode3) << 8 | UInt16(opcode2)
            mmu.writeByte(address: tempResult, value: registers.L)
            mmu.writeByte(address: tempResult &+ 1, value: registers.H)
            registers.PC = registers.PC &+ 3
            tStates = tStates + 16
            incrementR(opcodeCount:1)
        case 0x23: // INC HL - 23 - Adds one to HL
            logInstructionDetails(instructionDetails: "INC HL", opcode: [0x23], programCounter: registers.PC)
            registers.HL = registers.HL &+ 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x24: // INC H - 24 - Adds one to H
            logInstructionDetails(instructionDetails: "INC H", opcode: [0x24], programCounter: registers.PC)
            (registers.H,registers.F) = z80FastFlags.incHelper(operand: registers.H, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x25: // DEC H - 25 - Subtracts one from H
            logInstructionDetails(instructionDetails: "DEC H", opcode: [0x25], programCounter: registers.PC)
            (registers.H,registers.F) = z80FastFlags.decHelper(operand: registers.H, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x26: // LD H,$n - 26 n - Loads $n into H
            logInstructionDetails(instructionDetails: "LD H,$n", opcode: [0x26], values: [opcode2], programCounter: registers.PC)
            registers.H = opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x28: // JR Z,$d - 28 d - If the zero flag is set, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR Z,$d", opcode: [0x28], values: [opcode2], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
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
        case 0x29: // ADD HL,HL - 29 - The value of HL is added to HL
            logInstructionDetails(instructionDetails: "ADD HL,HL", opcode: [0x29], programCounter: registers.PC)
            let tempResult = registers.HL &+ registers.HL
            let halfCarry = UInt8((registers.HL ^ registers.HL ^ tempResult) & 0x1000)
            let carrytempResult = UInt32(registers.HL) + UInt32(registers.HL)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.HL = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = registers.F | halfCarry
            registers.PC = registers.PC &+ 1
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0x2A: // LD HL,($nn) - 2A n n - Loads the value pointed to by $nn into HL
            logInstructionDetails(instructionDetails: "LD HL,($nn)", opcode: [0x2A], values: [opcode2,opcode3], programCounter: registers.PC)
            let tempResult = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.HL = UInt16(mmu.readByte(address: tempResult))
            registers.PC = registers.PC &+ 3
            tStates = tStates + 16
            incrementR(opcodeCount:1)
        case 0x2B: // DEC HL - 2B - Subtracts one from HL
            logInstructionDetails(instructionDetails: "DEC HL", opcode: [0x2B], programCounter: registers.PC)
            registers.HL = registers.HL &- 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x2C: // INC L - 2C - Adds one to L
            logInstructionDetails(instructionDetails: "INC L", opcode: [0x2C], programCounter: registers.PC)
            (registers.L,registers.F) = z80FastFlags.incHelper(operand: registers.L, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x2D: // DEC L - 2D - Subtracts one from L
            logInstructionDetails(instructionDetails: "DEC L", opcode: [0x2D], programCounter: registers.PC)
            (registers.L,registers.F) = z80FastFlags.decHelper(operand: registers.L, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x2E: // LD L,$n - 2E n - Loads n into L
            logInstructionDetails(instructionDetails: "LD H,$n", opcode: [0x2E], values: [opcode2], programCounter: registers.PC)
            registers.L = opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x2F: // CPL - 2F - The contents of A are inverted (one's complement)
            logInstructionDetails(instructionDetails: "CPL", opcode: [0x2F], programCounter: registers.PC)
            registers.A = ~registers.A
            registers.F = registers.F | z80Flags.Negative.rawValue
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x30: // JR NC,d - 30 $d - If the carry flag is unset, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR NC,$d", opcode: [0x30], values: [opcode2], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
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
        case 0x31: // LD SP,$nn - 31 n n - Loads $nn into SP
            logInstructionDetails(instructionDetails: "LD SP,$nn", opcode: [0x31], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.SP = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.PC = registers.PC &+ 3
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0x32: // LD ($nn),A - 32 n n - Stores A into the memory location pointed to by $nn
            logInstructionDetails(instructionDetails: "LD ($nn),A", opcode: [0x32], values: [opcode2,opcode3], programCounter: registers.PC)
            let tempResult = UInt16(opcode3) << 8 | UInt16(opcode2)
            mmu.writeByte(address: tempResult, value: registers.A)
            registers.PC = registers.PC &+ 3
            tStates = tStates + 13
            incrementR(opcodeCount:1)
        case 0x33: // INC SP - 33 - Adds one to SP
            logInstructionDetails(instructionDetails: "INC SP", opcode: [0x33], programCounter: registers.PC)
            registers.SP = registers.PC &+ 1
            registers.PC = registers.PC &+ 3
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x34: // INC (HL) - 34 - Adds one to (HL)
            logInstructionDetails(instructionDetails: "INC (HL)", opcode: [0x34], programCounter: registers.PC)
            var previous = mmu.readByte(address: registers.HL)
            (previous,registers.F) = z80FastFlags.incHelper(operand: previous, currentFlags: registers.F)
            mmu.writeByte(address: registers.HL,value: previous)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 11
            incrementR(opcodeCount:1)
            incrementR(opcodeCount:1)
        case 0x35: // DEC (HL) - 35 - Subtracts one from (HL)
            logInstructionDetails(instructionDetails: "DEC (HL)", opcode: [0x35], programCounter: registers.PC)
            var previous = mmu.readByte(address: registers.HL)
            (previous,registers.F) = z80FastFlags.decHelper(operand: previous, currentFlags: registers.F)
            mmu.writeByte(address: registers.HL,value: previous)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0x36: // LD (HL),$n - 36 n - Loads $n into address at HL
            logInstructionDetails(instructionDetails: "LD (HL),$n", opcode: [0x36], values: [opcode2], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: opcode2)
            registers.PC = registers.PC &+ 2
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0x37: // SCF - 37 - Sets the carry flag
            logInstructionDetails(instructionDetails: "SCF", opcode: [0x37], programCounter: registers.PC)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | z80Flags.Carry.rawValue
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x38: // JR C,d - 38 $d - If the carry flag is set, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR C,$d", opcode: [0x38], values: [opcode2], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
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
        case 0x39: // ADD HL,SP - 39 - The value of SP is added to HL
            logInstructionDetails(instructionDetails: "ADD HL,SP", opcode: [0x39], programCounter: registers.PC)
            let tempResult = registers.HL &+ registers.SP
            let halfCarry = UInt8((registers.HL ^ registers.SP ^ tempResult) & 0x1000)
            let carrytempResult = UInt32(registers.HL) + UInt32(registers.SP)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.HL = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = registers.F | halfCarry
            registers.PC = registers.PC &+ 1
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0x3A: // LD A,($nn) - 3A n n - Loads the value pointed to by $nn into A
            logInstructionDetails(instructionDetails: "LD A,($nn)", opcode: [0x3A], values: [opcode2,opcode3], programCounter: registers.PC)
            let tempResult = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.A = mmu.readByte(address: tempResult)
            registers.PC = registers.PC &+ 3
            tStates = tStates + 13
            incrementR(opcodeCount:1)
        case 0x3B: // DEC SP - 3B - Subtracts one from SP
            logInstructionDetails(instructionDetails: "DEC SP", opcode: [0x3B], programCounter: registers.PC)
            registers.SP = registers.SP &- 1
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x3C: // INC A - 3C - Adds one to A
            logInstructionDetails(instructionDetails: "INC A", opcode: [0x3C], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.incHelper(operand: registers.A, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x3D: // DEC A - 3D - Subtracts one from A
            logInstructionDetails(instructionDetails: "DEC A", opcode: [0x3D], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.decHelper(operand: registers.A, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x3E: // LD A,n - 3E - Loads n into A
            logInstructionDetails(instructionDetails: "LD A,$n", opcode: [0x3E], values: [opcode2], programCounter: registers.PC)
            registers.A = opcode2
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x3F: // CCF - 3F - Inverts the carry flag
            logInstructionDetails(instructionDetails: "CCF", opcode: [0x3F], programCounter: registers.PC)
            let previousCarry = registers.F & z80Flags.Carry.rawValue
            let newHalfCarry = previousCarry << 4
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F | newHalfCarry
            registers.F = registers.F ^ previousCarry
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x40: // LD B,B - 40 - The contents of B are loaded into B
            logInstructionDetails(instructionDetails: "LD B,B", opcode: [0x40], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x41: // LD B,C - 41 - The contents of C are loaded into B
            logInstructionDetails(instructionDetails: "LD B,C", opcode: [0x41], programCounter: registers.PC)
            registers.B = registers.C
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x42: // LD B,D - 42 - The contents of D are loaded into B
            logInstructionDetails(instructionDetails: "LD B,D", opcode: [0x42], programCounter: registers.PC)
            registers.B = registers.D
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x43: // LD B,E - 43 - The contents of E are loaded into B
            logInstructionDetails(instructionDetails: "LD B,E", opcode: [0x43], programCounter: registers.PC)
            registers.B = registers.E
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x44: // LD B,H - 44 - The contents of H are loaded into B
            logInstructionDetails(instructionDetails: "LD B,H", opcode: [0x44], programCounter: registers.PC)
            registers.B = registers.H
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x45: // LD B,L - 45 - The contents of L are loaded into B
            logInstructionDetails(instructionDetails: "LD B,L", opcode: [0x45], programCounter: registers.PC)
            registers.B = registers.L
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x46: // LD B,(HL) - 46 - The contents of (HL) are loaded into B
            logInstructionDetails(instructionDetails: "LD B,(HL)", opcode: [0x46], programCounter: registers.PC)
            registers.B = mmu.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x47: // LD B,A - 47 - The contents of A are loaded into B
            logInstructionDetails(instructionDetails: "LD B,A", opcode: [0x47], programCounter: registers.PC)
            registers.B = registers.A
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x48: // LD C,B - 48 - The contents of B are loaded into C
            logInstructionDetails(instructionDetails: "LD C,B", opcode: [0x48], programCounter: registers.PC)
            registers.C = registers.B
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x49: // LD C,C - 41 - The contents of C are loaded into C
            logInstructionDetails(instructionDetails: "LD C,C", opcode: [0x49], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x4A: // LD C,D - 4A - The contents of D are loaded into C
            logInstructionDetails(instructionDetails: "LD C,D", opcode: [0x4A], programCounter: registers.PC)
            registers.C = registers.D
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x4B: // LD C,E - 43 - The contents of E are loaded into C
            logInstructionDetails(instructionDetails: "LD C,E", opcode: [0x4B], programCounter: registers.PC)
            registers.C = registers.E
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x4C: // LD C,H - 44 - The contents of H are loaded into C
            logInstructionDetails(instructionDetails: "LD C,H", opcode: [0x4C], programCounter: registers.PC)
            registers.C = registers.H
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x4D: // LD C,L - 45 - The contents of L are loaded into C
            logInstructionDetails(instructionDetails: "LD C,L", opcode: [0x4D], programCounter: registers.PC)
            registers.C = registers.L
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x4E: // LD C,(HL) - 46 - The contents of (HL) are loaded into C
            logInstructionDetails(instructionDetails: "LD C,(HL)", opcode: [0x4E], programCounter: registers.PC)
            registers.C = mmu.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x4F: // LD C,A - 47 - The contents of A are loaded into C
            logInstructionDetails(instructionDetails: "LD C,A", opcode: [0x4F], programCounter: registers.PC)
            registers.C = registers.A
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x50: // LD D,B - 40 - The contents of B are loaded into D
            logInstructionDetails(instructionDetails: "LD D,B", opcode: [0x50], programCounter: registers.PC)
            registers.D = registers.B
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x51: // LD D,C - 41 - The contents of C are loaded into D
            logInstructionDetails(instructionDetails: "LD D,C", opcode: [0x51], programCounter: registers.PC)
            registers.D = registers.C
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x52: // LD D,D - 42 - The contents of D are loaded into D
            logInstructionDetails(instructionDetails: "LD D,D", opcode: [0x52], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x53: // LD D,E - 43 - The contents of E are loaded into D
            logInstructionDetails(instructionDetails: "LD D,E", opcode: [0x53], programCounter: registers.PC)
            registers.D = registers.E
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x54: // LD D,H - 44 - The contents of H are loaded into D
            logInstructionDetails(instructionDetails: "LD D,H", opcode: [0x54], programCounter: registers.PC)
            registers.D = registers.H
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x55: // LD D,L - 45 - The contents of L are loaded into D
            logInstructionDetails(instructionDetails: "LD D,L", opcode: [0x55], programCounter: registers.PC)
            registers.D = registers.L
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x56: // LD D,(HL) - 46 - The contents of (HL) are loaded into D
            logInstructionDetails(instructionDetails: "LD D,(HL)", opcode: [0x56], programCounter: registers.PC)
            registers.D = mmu.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x57: // LD D,A - 47 - The contents of A are loaded into D
            logInstructionDetails(instructionDetails: "LD D,A", opcode: [0x57], programCounter: registers.PC)
            registers.D = registers.A
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x58: // LD E,B - 40 - The contents of B are loaded into E
            logInstructionDetails(instructionDetails: "LD E,B", opcode: [0x58], programCounter: registers.PC)
            registers.E = registers.B
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x59: // LD E,C - 41 - The contents of C are loaded into E
            logInstructionDetails(instructionDetails: "LD E,C", opcode: [0x59], programCounter: registers.PC)
            registers.E = registers.C
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x5A: // LD E,D - 42 - The contents of D are loaded into E
            logInstructionDetails(instructionDetails: "LD E,D", opcode: [0x5A], programCounter: registers.PC)
            registers.E = registers.D
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x5B: // LD E,E - 43 - The contents of E are loaded into E
            logInstructionDetails(instructionDetails: "LD E,E", opcode: [0x5B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x5C: // LD E,H - 44 - The contents of H are loaded into E
            logInstructionDetails(instructionDetails: "LD E,H", opcode: [0x5C], programCounter: registers.PC)
            registers.E = registers.H
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x5D: // LD E,L - 45 - The contents of L are loaded into E
            logInstructionDetails(instructionDetails: "LD E,L", opcode: [0x5D], programCounter: registers.PC)
            registers.E = registers.L
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x5E: // LD E,(HL) - 46 - The contents of (HL) are loaded into E
            logInstructionDetails(instructionDetails: "LD E,(HL)", opcode: [0x5E], programCounter: registers.PC)
            registers.E = mmu.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x5F: // LD E,A - 47 - The contents of A are loaded into E
            logInstructionDetails(instructionDetails: "LD E,A", opcode: [0x5F], programCounter: registers.PC)
            registers.E = registers.A
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x60: // LD H,B - 40 - The contents of B are loaded into H
            logInstructionDetails(instructionDetails: "LD H,B", opcode: [0x60], programCounter: registers.PC)
            registers.H = registers.B
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x61: // LD H,C - 41 - The contents of C are loaded into H
            logInstructionDetails(instructionDetails: "LD H,C", opcode: [0x61], programCounter: registers.PC)
            registers.H = registers.C
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x62: // LD H,D - 42 - The contents of D are loaded into H
            logInstructionDetails(instructionDetails: "LD H,D", opcode: [0x62], programCounter: registers.PC)
            registers.H = registers.D
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x63: // LD H,E - 43 - The contents of E are loaded into H
            logInstructionDetails(instructionDetails: "LD H,E", opcode: [0x63], programCounter: registers.PC)
            registers.H = registers.E
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x64: // LD H,H - 44 - The contents of H are loaded into H
            logInstructionDetails(instructionDetails: "LD H,H", opcode: [0x64], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x65: // LD H,L - 45 - The contents of L are loaded into H
            logInstructionDetails(instructionDetails: "LD H,L", opcode: [0x65], programCounter: registers.PC)
            registers.H = registers.L
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x66: // LD H,(HL) - 46 - The contents of (HL) are loaded into H
            logInstructionDetails(instructionDetails: "LD H,(HL)", opcode: [0x66], programCounter: registers.PC)
            registers.H = mmu.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x67: // LD H,A - 47 - The contents of A are loaded into H
            logInstructionDetails(instructionDetails: "LD H,A", opcode: [0x67], programCounter: registers.PC)
            registers.H = registers.A
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x68: // LD L,B - 40 - The contents of B are loaded into L
            logInstructionDetails(instructionDetails: "LD L,B", opcode: [0x68], programCounter: registers.PC)
            registers.L = registers.B
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x69: // LD L,C - 41 - The contents of C are loaded into L
            logInstructionDetails(instructionDetails: "LD L,C", opcode: [0x69], programCounter: registers.PC)
            registers.L = registers.C
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x6A: // LD L,D - 42 - The contents of D are loaded into L
            logInstructionDetails(instructionDetails: "LD L,D", opcode: [0x6A], programCounter: registers.PC)
            registers.L = registers.D
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x6B: // LD L,E - 43 - The contents of E are loaded into L
            logInstructionDetails(instructionDetails: "LD L,E", opcode: [0x6B], programCounter: registers.PC)
            registers.L = registers.E
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x6C: // LD L,H - 44 - The contents of H are loaded into L
            logInstructionDetails(instructionDetails: "LD L,H", opcode: [0x6C], programCounter: registers.PC)
            registers.L = registers.H
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x6D: // LD L,L - 45 - The contents of L are loaded into L
            logInstructionDetails(instructionDetails: "LD L,L", opcode: [0x6D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x6E: // LD L,(HL) - 6E - The contents of (HL) are loaded into L
            logInstructionDetails(instructionDetails: "LD L,(HL)", opcode: [0x6E], programCounter: registers.PC)
            registers.L = mmu.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x6F: // LD L,A - 6F - The contents of A are loaded into L
            logInstructionDetails(instructionDetails: "LD L,A", opcode: [0x6F], programCounter: registers.PC)
            registers.L = registers.A
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x70: // LD (HL),B - 70 - The contents of B are loaded into (HL)
            logInstructionDetails(instructionDetails: "LD (HL),B", opcode: [0x70], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.B)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x71: // LD (HL),C - 70 - The contents of C are loaded into (HL)
            logInstructionDetails(instructionDetails: "LD (HL),C", opcode: [0x71], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.C)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x72: // LD (HL),D - 70 - The contents of D are loaded into (HL)
            logInstructionDetails(instructionDetails: "LD (HL),D", opcode: [0x72], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.D)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x73: // LD (HL),E - 70 - The contents of B are loaded into (HL)
            tStates = tStates + 7
            logInstructionDetails(instructionDetails: "LD (HL),E", opcode: [0x73], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.E)
            registers.PC = registers.PC &+ 1
            incrementR(opcodeCount:1)
        case 0x74: // LD (HL),H - 70 - The contents of H are loaded into (HL)
            logInstructionDetails(instructionDetails: "LD (HL),H", opcode: [0x74], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.H)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x75: // LD (HL),L - 70 - The contents of L are loaded into (HL)
            logInstructionDetails(instructionDetails: "LD (HL),L", opcode: [0x75], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.L)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x76: // HALT - 76 - Suspends CPU operation until an interrupt or reset occurs
            emulatorState = .halted
            logInstructionDetails(instructionDetails: "HALT", opcode: [0x76], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x77: // LD (HL),A - 70 - The contents of A are loaded into (HL)
            logInstructionDetails(instructionDetails: "LD (HL),A", opcode: [0x77], programCounter: registers.PC)
            mmu.writeByte(address: registers.HL, value: registers.A)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x78: // LD A,B - 78 - The contents of B are loaded into A
            logInstructionDetails(instructionDetails: "LD A, B", opcode: [0x78], programCounter: registers.PC)
            registers.A = registers.B
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x79: // LD A,C - 79 - The contents of C are loaded into A
            logInstructionDetails(instructionDetails: "LD A,C", opcode: [0x79], programCounter: registers.PC)
            registers.A = registers.C
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7A: // LD A,D - 7A - The contents of D are loaded into A
            logInstructionDetails(instructionDetails: "LD A,D", opcode: [0x7A], programCounter: registers.PC)
            registers.A = registers.D
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7B: // LD A,E - 7B - The contents of E are loaded into A
            logInstructionDetails(instructionDetails: "LD A,E", opcode: [0x7B], programCounter: registers.PC)
            registers.A = registers.E
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7C: // LD A,H - 7C - The contents of H are loaded into A
            logInstructionDetails(instructionDetails: "LD A,H", opcode: [0x7C], programCounter: registers.PC)
            registers.A = registers.H
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7D: // LD A,L - 7D - The contents of L are loaded into A
            logInstructionDetails(instructionDetails: "LD A,L", opcode: [0x7D], programCounter: registers.PC)
            registers.A = registers.L
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7E: // LD A,(HL) - 7E - The contents of (HL) are loaded into A
            logInstructionDetails(instructionDetails: "LD A,(HL)", opcode: [0x7E], programCounter: registers.PC)
            registers.A = mmu.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x7F: // LD A,A - 7F - The contents of A are loaded into A
            logInstructionDetails(instructionDetails: "LD A,A", opcode: [0x7F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x90: // SUB B - 90 - Subtracts B from A
            logInstructionDetails(instructionDetails: "SUB B", opcode: [0x90], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.B)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x91: // SUB C - 91 - Subtracts C from A
            logInstructionDetails(instructionDetails: "SUB C", opcode: [0x91], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.C)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x92: // SUB D - 92 - Subtracts D from A
            logInstructionDetails(instructionDetails: "SUB D", opcode: [0x92], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.D)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x93: // SUB E - 93 - Subtracts E from A
            logInstructionDetails(instructionDetails: "SUB E", opcode: [0x93], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.E)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x94: // SUB H - 94 - Subtracts H from A
            logInstructionDetails(instructionDetails: "SUB H", opcode: [0x94], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.H)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x95: // SUB L - 95 - Subtracts L from A
            logInstructionDetails(instructionDetails: "SUB L", opcode: [0x95], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.L)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x96: // SUB (HL) - 96 - Subtracts (HL) from A
            logInstructionDetails(instructionDetails: "SUB (HL)", opcode: [0x96], programCounter: registers.PC)
            let tempResult = mmu.readByte(address: registers.HL)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: tempResult)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x97: // SUB A - 97 - Subtracts A from A
            logInstructionDetails(instructionDetails: "SUB A", opcode: [0x97], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.A)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA0: // AND B - A0 - Bitwise AND on A with B
            logInstructionDetails(instructionDetails: "AND B", opcode: [0xA0], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.B)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA1: // AND C - A1 - Bitwise AND on A with C
            logInstructionDetails(instructionDetails: "AND C", opcode: [0xA1], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.C)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA2: // AND D - A2 - Bitwise AND on A with D
            logInstructionDetails(instructionDetails: "AND D", opcode: [0xA2], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.D)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA3: // AND E - A3 - Bitwise AND on A with E
            logInstructionDetails(instructionDetails: "AND E", opcode: [0xA3], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.E)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA4: // AND H - A4 - Bitwise AND on A with H
            logInstructionDetails(instructionDetails: "AND H", opcode: [0xA4], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.H)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA5: // AND L - A5 - Bitwise AND on A with L
            logInstructionDetails(instructionDetails: "AND L", opcode: [0xA5], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.L)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA6: // AND (HL) - A6 - Bitwise AND on A with (HL)
            logInstructionDetails(instructionDetails: "AND (HL)", opcode: [0xA6], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & mmu.readByte(address: registers.HL))
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xA7: // AND A - A7 - Bitwise AND on A with A
            logInstructionDetails(instructionDetails: "AND A", opcode: [0xA7], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.A)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA8: // XOR B - A8 - Bitwise XOR on A with B
            logInstructionDetails(instructionDetails: "XOR B", opcode: [0xA8], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.B)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA9: // XOR C - A9 - Bitwise XOR on A with C
            logInstructionDetails(instructionDetails: "XOR C", opcode: [0xA9], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.C)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xAA: // XOR D - AA - Bitwise XOR on A with D
            logInstructionDetails(instructionDetails: "XOR D", opcode: [0xAA], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.D)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xAB: // XOR E - AB - Bitwise XOR on A with E
            logInstructionDetails(instructionDetails: "XOR E", opcode: [0xAB], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.E)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xAC: // XOR H - AC - Bitwise XOR on A with H
            logInstructionDetails(instructionDetails: "XOR H", opcode: [0xAC], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.H)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xAD: // XOR L - AD - Bitwise XOR on A with L
            logInstructionDetails(instructionDetails: "XOR L", opcode: [0xAD], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.L)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xAE: // XOR (HL) - AE - Bitwise XOR on A with (HL)
            logInstructionDetails(instructionDetails: "XOR (HL)", opcode: [0xAE], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ mmu.readByte(address: registers.HL))
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xAF: // XOR A - AF - Bitwise XOR on A with A
            logInstructionDetails(instructionDetails: "XOR A", opcode: [0xAF], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.A)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB0: // OR B - B0 - Bitwise OR on A with B
            logInstructionDetails(instructionDetails: "OR B", opcode: [0xB0], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.B)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB1: // OR C - B1 - Bitwise OR on A with C
            logInstructionDetails(instructionDetails: "OR C", opcode: [0xB1], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.C)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB2: // OR D - B2 - Bitwise OR on A with D
            logInstructionDetails(instructionDetails: "OR D", opcode: [0xB2], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.D)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB3: // OR E - B3 - Bitwise OR on A with E
            logInstructionDetails(instructionDetails: "OR E", opcode: [0xB3], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.E)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB4: // OR H - B4 - Bitwise OR on A with H
            logInstructionDetails(instructionDetails: "OR H", opcode: [0xB4], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.H)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB5: // OR L - B5 - Bitwise OR on A with L
            logInstructionDetails(instructionDetails: "OR L", opcode: [0xB5], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.L)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB6: // OR (HL) - B6 - Bitwise OR on A with (HL)
            logInstructionDetails(instructionDetails: "OR (HL)", opcode: [0xB6], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | mmu.readByte(address: registers.HL))
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xB7: // OR A - B7 - Bitwise OR on A with A
            logInstructionDetails(instructionDetails: "OR A", opcode: [0xB7], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.A)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB8: // CP B - B8 - Subtracts B from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP B", opcode: [0xB8], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.B)
            registers.F = tempFlags
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB9: // CP C - B9 - Subtracts C from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP C", opcode: [0xB9], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.C)
            registers.F = tempFlags
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xBA: // CP D - BA - Subtracts D from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP D", opcode: [0xBA], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.D)
            registers.F = tempFlags
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xBB: // CP E - BB - Subtracts E from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP E", opcode: [0xBB], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.E)
            registers.F = tempFlags
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xBC: // CP H - BC - Subtracts H from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP H", opcode: [0xBC], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.H)
            registers.F = tempFlags
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xBD: // CP L - BD - Subtracts L from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP L", opcode: [0xBD], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.L)
            registers.F = tempFlags
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xBE: // CP (HL) - BE - Subtracts (HL) from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP (HL)", opcode: [0xBE], programCounter: registers.PC)
            let previous = mmu.readByte(address: registers.HL)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: previous)
            registers.F = tempFlags
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xBF: // CP A - BF - Subtracts A from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP A", opcode: [0xBF], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.A)
            registers.F = tempFlags
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xC0: // RET NZ - C0 - If the zero flag is unset, the top stack entry is popped into PC
            logInstructionDetails(instructionDetails: "RET NZ", opcode: [0xC0], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
            {
                registers.PC = registers.PC &+ 1
                tStates = tStates + 5
            }
            else
            {
                registers.PCL = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                tStates = tStates + 11
            }
            incrementR(opcodeCount:1)
        case 0xC1: // POP BC - C1 - The memory location pointed to by SP is stored into C and SP is incremented. The memory location pointed to by SP is stored into B and SP is incremented again
            logInstructionDetails(instructionDetails: "POP BC", opcode: [0xC1], programCounter: registers.PC)
            registers.C = mmu.readByte(address: registers.SP)
            registers.B = mmu.readByte(address: registers.SP &+ 1)
            registers.SP = registers.SP &+ 2
            registers.PC = registers.PC &+ 1
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xC2: // JP NZ,$nn - C2 n n - If the zero flag is unset, $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP NZ,$nn", opcode: [0xC2], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xC3: // JP $nn - C3 n n - $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP $nn", opcode: [0xC3], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xC4: // CALL NZ,$nn - C4 n n - JIf the zero flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn
            logInstructionDetails(instructionDetails: "CALL NZ,$nn",opcode: [0xC4], values:[opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
            {
                tStates = tStates + 10
            }
            else
            {
                registers.PC = registers.PC &+ 3
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCH)
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCL)
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
                tStates = tStates + 17
            }
            incrementR(opcodeCount:1)
        case 0xC5: // PUSH BC - C5 - SP is decremented and B is stored into the memory location pointed to by SP. SP is decremented again and C is stored into the memory location pointed to by SP
            logInstructionDetails(instructionDetails: "PUSH BC", opcode: [0xC5], programCounter: registers.PC)
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: registers.B)
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: registers.C)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xC7: // RST 0x00 - C7 - The current PC value plus one is pushed onto the stack, then is loaded with 0x00
            logInstructionDetails(instructionDetails: "RST 0x00", opcode: [0xC7], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0000
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xC8: // RETZ - C8 - If the zero flag is set, the top stack entry is popped into PC
            logInstructionDetails(instructionDetails: "RET", opcode: [0xC8], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
            {
                registers.PCL = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                tStates = tStates + 11
            }
            else
            {
                registers.PC = registers.PC &+ 1
                tStates = tStates + 5
            }
            incrementR(opcodeCount:1)
        case 0xC9: // RET - C9 - The top stack entry is popped into PC
            logInstructionDetails(instructionDetails: "RET", opcode: [0xC9], programCounter: registers.PC)
            registers.PCL = mmu.readByte(address: registers.SP)
            registers.SP = registers.SP &+ 1
            registers.PCH = mmu.readByte(address: registers.SP)
            registers.SP = registers.SP &+ 1
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xCA: // JP Z,nn - CA n n - If the zero flag is set, $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP Z,$nn", opcode: [0xCA], values: [opcode2,opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
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
            case 0x40: // BIT 0,B - CB 40 - Tests bit 0 of B
                logInstructionDetails(instructionDetails: "BIT 0,B", opcode: [0xCB,0x40], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.B & 1) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x41: // BIT 0,C - CB 41 - Tests bit 0 of C
                logInstructionDetails(instructionDetails: "BIT 0,C", opcode: [0xCB,0x41], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.C & 1) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x42: // BIT 0,D - CB 42 - Tests bit 0 of D
                logInstructionDetails(instructionDetails: "BIT 0,D", opcode: [0xCB,0x42], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.D & 1) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x43: // BIT 0,E - CB 43 - Tests bit 0 of E
                logInstructionDetails(instructionDetails: "BIT 0,E", opcode: [0xCB,0x43], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.E & 1) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x44: // BIT 0,H - CB 44 - Tests bit 0 of H
                logInstructionDetails(instructionDetails: "BIT 0,H", opcode: [0xCB,0x44], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.H & 1) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x45: // BIT 0,L - CB 45 - Tests bit 0 of L
                logInstructionDetails(instructionDetails: "BIT 0,L", opcode: [0xCB,0x45], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.L & 1) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x46: // BIT 0,(HL) - CB 46 - Tests bit 0 of (HL)
                logInstructionDetails(instructionDetails: "BIT 0,(HL)", opcode: [0xCB,0x46], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((tempResult & 1) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x47: // BIT 0,A - CB 47 - Tests bit 0 of A
                logInstructionDetails(instructionDetails: "BIT 0,A", opcode: [0xCB,0x47], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.A & 1) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x48: // BIT 1,B - CB 48 - Tests bit 1 of B
                logInstructionDetails(instructionDetails: "BIT 1,B", opcode: [0xCB,0x48], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.B & 2) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x49: // BIT 1,C - CB 49 - Tests bit 1 of C
                logInstructionDetails(instructionDetails: "BIT 1,C", opcode: [0xCB,0x49], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.C & 2) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x4A: // BIT 1,D - CB 4A - Tests bit 1 of D
                logInstructionDetails(instructionDetails: "BIT 1,D", opcode: [0xCB,0x4A], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.D & 2) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x4B: // BIT 1,E - CB 4B - Tests bit 1 of E
                logInstructionDetails(instructionDetails: "BIT 1,E", opcode: [0xCB,0x4B], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.E & 2) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x4C: // BIT 1,H - CB 4C - Tests bit 1 of H
                logInstructionDetails(instructionDetails: "BIT 1,H", opcode: [0xCB,0x4C], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.H & 2) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x4D: // BIT 1,L - CB 4D - Tests bit 1 of L
                logInstructionDetails(instructionDetails: "BIT 1,L", opcode: [0xCB,0x4D], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.L & 2) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x4E: // BIT 1,(HL) - CB 4E - Tests bit 1 of (HL)
                logInstructionDetails(instructionDetails: "BIT 1,(HL)", opcode: [0xCB,0x4E], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((tempResult & 2) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x4F: // BIT 1,A - CB 4F - Tests bit 1 of A
                logInstructionDetails(instructionDetails: "BIT 1,A", opcode: [0xCB,0x4F], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.A & 2) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x50: // BIT 2,B - CB 50 - Tests bit 2 of B
                logInstructionDetails(instructionDetails: "BIT 2,B", opcode: [0xCB,0x50], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.B & 4) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x51: // BIT 2,C - CB 51 - Tests bit 2 of C
                logInstructionDetails(instructionDetails: "BIT 2,C", opcode: [0xCB,0x51], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.C & 4) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x52: // BIT 2,D - CB 52 - Tests bit 2 of D
                logInstructionDetails(instructionDetails: "BIT 2,D", opcode: [0xCB,0x52], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.D & 4) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x53: // BIT 2,E - CB 53 - Tests bit 2 of E
                logInstructionDetails(instructionDetails: "BIT 2,E", opcode: [0xCB,0x53], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.E & 4) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x54: // BIT 2,H - CB 54 - Tests bit 2 of H
                logInstructionDetails(instructionDetails: "BIT 2,H", opcode: [0xCB,0x54], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.H & 4) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x55: // BIT 2,L - CB 55 - Tests bit 2 of L
                logInstructionDetails(instructionDetails: "BIT 2,L", opcode: [0xCB,0x55], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.L & 4) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x56: // BIT 2,(HL) - CB 56 - Tests bit 2 of (HL)
                logInstructionDetails(instructionDetails: "BIT 2,(HL)", opcode: [0xCB,0x56], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((tempResult & 1) ^ 4) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x57: // BIT 2,A - CB 57 - Tests bit 2 of A
                logInstructionDetails(instructionDetails: "BIT 2,A", opcode: [0xCB,0x57], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.A & 4) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x58: // BIT 3,B - CB 58 - Tests bit 3 of B
                logInstructionDetails(instructionDetails: "BIT 3,B", opcode: [0xCB,0x58], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.B & 8) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x59: // BIT 3,C - CB 59 - Tests bit 3 of C
                logInstructionDetails(instructionDetails: "BIT 3,C", opcode: [0xCB,0x59], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.C & 8) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x5A: // BIT 3,D - CB 5A - Tests bit 3 of D
                logInstructionDetails(instructionDetails: "BIT 3,D", opcode: [0xCB,0x5A], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.D & 8) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x5B: // BIT 3,E - CB 5B - Tests bit 3 of E
                logInstructionDetails(instructionDetails: "BIT 3,E", opcode: [0xCB,0x5B], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.E & 8) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x5C: // BIT 3,H - CB 5C - Tests bit 3 of H
                logInstructionDetails(instructionDetails: "BIT 3,H", opcode: [0xCB,0x5C], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.H & 8) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x5D: // BIT 3,L - CB 5D - Tests bit 3 of L
                logInstructionDetails(instructionDetails: "BIT 3,L", opcode: [0xCB,0x5D], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.L & 8) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x5E: // BIT 3,(HL) - CB 5E - Tests bit 3 of (HL)
                logInstructionDetails(instructionDetails: "BIT 3,(HL)", opcode: [0xCB,0x5E], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((tempResult & 8) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x5F: // BIT 3,A - CB 5F - Tests bit 3 of A
                logInstructionDetails(instructionDetails: "BIT 3,A", opcode: [0xCB,0x5F], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.A & 8) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x60: // BIT 4,B - CB 60 - Tests bit 4 of B
                logInstructionDetails(instructionDetails: "BIT 4,B", opcode: [0xCB,0x60], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.B & 16) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x61: // BIT 4,C - CB 61 - Tests bit 4 of C
                logInstructionDetails(instructionDetails: "BIT 4,C", opcode: [0xCB,0x61], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.C & 16) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x62: // BIT 4,D - CB 62 - Tests bit 4 of D
                logInstructionDetails(instructionDetails: "BIT 4,D", opcode: [0xCB,0x62], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.D & 16) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x63: // BIT 4,E - CB 63 - Tests bit 4 of E
                logInstructionDetails(instructionDetails: "BIT 4,E", opcode: [0xCB,0x63], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.E & 16) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x64: // BIT 4,H - CB 64 - Tests bit 4 of H
                logInstructionDetails(instructionDetails: "BIT 4,H", opcode: [0xCB,0x64], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.H & 16) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x65: // BIT 4,L - CB 65 - Tests bit 4 of L
                logInstructionDetails(instructionDetails: "BIT 4,L", opcode: [0xCB,0x65], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.L & 16) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x66: // BIT 4,(HL) - CB 66 - Tests bit 4 of (HL)
                logInstructionDetails(instructionDetails: "BIT 4,(HL)", opcode: [0xCB,0x66], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((tempResult & 16) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x67: // BIT 4,A - CB 67 - Tests bit 4 of A
                logInstructionDetails(instructionDetails: "BIT 4,A", opcode: [0xCB,0x67], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.A & 16) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x68: // BIT 5,B - CB 68 - Tests bit 5 of B
                logInstructionDetails(instructionDetails: "BIT 5,B", opcode: [0xCB,0x68], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.B & 32) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x69: // BIT 5,C - CB 69 - Tests bit 5 of C
                logInstructionDetails(instructionDetails: "BIT 5,C", opcode: [0xCB,0x69], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.C & 32) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x6A: // BIT 5,D - CB 6A - Tests bit 5 of D
                logInstructionDetails(instructionDetails: "BIT 5,D", opcode: [0xCB,0x6A], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.D & 32) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x6B: // BIT 5,E - CB 6B - Tests bit 5 of E
                logInstructionDetails(instructionDetails: "BIT 5,E", opcode: [0xCB,0x6B], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.E & 32) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x6C: // BIT 5,H - CB 6C - Tests bit 5 of H
                logInstructionDetails(instructionDetails: "BIT 5,H", opcode: [0xCB,0x6C], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.H & 32) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x6D: // BIT 5,L - CB 6D - Tests bit 5 of L
                logInstructionDetails(instructionDetails: "BIT 5,L", opcode: [0xCB,0x6D], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.L & 32) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x6E: // BIT 5,(HL) - CB 6E - Tests bit 5 of (HL)
                logInstructionDetails(instructionDetails: "BIT 5,(HL)", opcode: [0xCB,0x6E], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((tempResult & 32) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x6F: // BIT 5,A - CB 6F - Tests bit 5 of A
                logInstructionDetails(instructionDetails: "BIT 5,A", opcode: [0xCB,0x6F], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.A & 32) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x70: // BIT 6,B - CB 70 - Tests bit 6 of B
                logInstructionDetails(instructionDetails: "BIT 6,B", opcode: [0xCB,0x70], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.B & 64) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x71: // BIT 6,C - CB 71 - Tests bit 6 of C
                logInstructionDetails(instructionDetails: "BIT 6,C", opcode: [0xCB,0x71], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.C & 64) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x72: // BIT 6,D - CB 72 - Tests bit 6 of D
                logInstructionDetails(instructionDetails: "BIT 6,D", opcode: [0xCB,0x72], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.D & 64) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x73: // BIT 6,E - CB 73 - Tests bit 6 of E
                logInstructionDetails(instructionDetails: "BIT 6,E", opcode: [0xCB,0x73], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.E & 64) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x74: // BIT 6,H - CB 74 - Tests bit 6 of H
                logInstructionDetails(instructionDetails: "BIT 6,H", opcode: [0xCB,0x74], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.H & 64) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x75: // BIT 6,L - CB 75 - Tests bit 6 of L
                logInstructionDetails(instructionDetails: "BIT 6,L", opcode: [0xCB,0x75], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.L & 64) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x76: // BIT 6,(HL) - CB 76 - Tests bit 6 of (HL)
                logInstructionDetails(instructionDetails: "BIT 6,(HL)", opcode: [0xCB,0x76], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((tempResult & 64) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x77: // BIT 6,A - CB 77 - Tests bit 6 of A
                logInstructionDetails(instructionDetails: "BIT 6,A", opcode: [0xCB,0x77], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.A & 64) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x78: // BIT 7,B - CB 78 - Tests bit 7 of B
                logInstructionDetails(instructionDetails: "BIT 7,B", opcode: [0xCB,0x78], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.B & 128) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x79: // BIT 7,C - CB 79 - Tests bit 7 of C
                logInstructionDetails(instructionDetails: "BIT 7,C", opcode: [0xCB,0x79], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.C & 128) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x7A: // BIT 7,D - CB 7A - Tests bit 7 of D
                logInstructionDetails(instructionDetails: "BIT 7,D", opcode: [0xCB,0x7A], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.D & 128) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x7B: // BIT 7,E - CB 7B - Tests bit 7 of E
                logInstructionDetails(instructionDetails: "BIT 7,E", opcode: [0xCB,0x7B], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.E & 128) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x7C: // BIT 7,H - CB 7C - Tests bit 7 of H
                logInstructionDetails(instructionDetails: "BIT 7,H", opcode: [0xCB,0x7C], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.H & 128) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x7D: // BIT 7,L - CB 7D - Tests bit 7 of L
                logInstructionDetails(instructionDetails: "BIT 7,L", opcode: [0xCB,0x7D], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.L & 128) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x7E: // BIT 7,(HL) - CB 7E - Tests bit 7 of (HL)
                logInstructionDetails(instructionDetails: "BIT 7,(HL)", opcode: [0xCB,0x7E], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((tempResult & 128) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x7F: // BIT 7,A - CB 7F - Tests bit 7 of A
                logInstructionDetails(instructionDetails: "BIT 7,A", opcode: [0xCB,0x7F], programCounter: registers.PC)
                registers.F = (registers.F & ~z80Flags.Zero.rawValue) | (((registers.A & 128) ^ 1) << 6)
                registers.F = registers.F | z80Flags.HalfCarry.rawValue
                registers.F = registers.F & ~z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x80: // RES 0,B - CB 80 - Resets bit 0 of B
                logInstructionDetails(instructionDetails: "RES 0,B", opcode: [0xCB,0x80], programCounter: registers.PC)
                registers.B = registers.B & 0b11111110
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x81: // RES 0,C - CB 81 - Resets bit 0 of C
                logInstructionDetails(instructionDetails: "RES 0,C", opcode: [0xCB,0x81], programCounter: registers.PC)
                registers.C = registers.C & 0b11111110
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x82: // RES 0,D - CB 82 - Resets bit 0 of D
                logInstructionDetails(instructionDetails: "RES 0,D", opcode: [0xCB,0x82], programCounter: registers.PC)
                registers.D = registers.D & 0b11111110
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x83: // RES 0,E - CB 83 - Resets bit 0 of E
                logInstructionDetails(instructionDetails: "RES 0,E", opcode: [0xCB,0x83], programCounter: registers.PC)
                registers.E = registers.E & 0b11111110
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x84: // RES 0,H - CB 84 - Resets bit 0 of H
                logInstructionDetails(instructionDetails: "RES 0,H", opcode: [0xCB,0x84], programCounter: registers.PC)
                registers.H = registers.H & 0b11111110
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x85: // RES 0,L - CB 85 - Resets bit 0 of L
                logInstructionDetails(instructionDetails: "RES 0,L", opcode: [0xCB,0x85], programCounter: registers.PC)
                registers.L = registers.L & 0b11111110
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x86: // RES 0,(HL) - CB 86 - Resets bit 0 of (HL)
                logInstructionDetails(instructionDetails: "RES 0,(HL)", opcode: [0xCB,0x86], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) & 0b11111110
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0x87: // RES 0,A - CB 87 - Resets bit 0 of A
                logInstructionDetails(instructionDetails: "RES 0,A", opcode: [0xCB,0x87], programCounter: registers.PC)
                registers.A = registers.A & 0b11111101
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x88: // RES 1,B - CB 88 - Resets bit 1 of B
                logInstructionDetails(instructionDetails: "RES 1,B", opcode: [0xCB,0x88], programCounter: registers.PC)
                registers.B = registers.B & 0b11111101
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x89: // RES 1,C - CB 89 - Resets bit 1 of C
                logInstructionDetails(instructionDetails: "RES 1,C", opcode: [0xCB,0x89], programCounter: registers.PC)
                registers.C = registers.C & 0b11111101
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x8A: // RES 1,D - CB 8A - Resets bit 1 of D
                logInstructionDetails(instructionDetails: "RES 1,D", opcode: [0xCB,0x8A], programCounter: registers.PC)
                registers.D = registers.D & 0b11111101
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x8B: // RES 1,E - CB 8B - Resets bit 1 of E
                logInstructionDetails(instructionDetails: "RES 1,E", opcode: [0xCB,0x8B], programCounter: registers.PC)
                registers.E = registers.E & 0b11111101
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x8C: // RES 1,H - CB 8C - Resets bit 1 of H
                logInstructionDetails(instructionDetails: "RES 1,H", opcode: [0xCB,0x8C], programCounter: registers.PC)
                registers.H = registers.H & 0b11111101
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x8D: // RES 1,L - CB 8D - Resets bit 1 of L
                logInstructionDetails(instructionDetails: "RES 1,L", opcode: [0xCB,0x8D], programCounter: registers.PC)
                registers.L = registers.L & 0b11111101
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x8E: // RES 1,(HL) - CB 8E - Resets bit 1 of (HL)
                logInstructionDetails(instructionDetails: "RES 1,(HL)", opcode: [0xCB,0x8E], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) & 0b11111101
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0x8F: // RES 1,A - CB 8F - Resets bit 1 of A
                logInstructionDetails(instructionDetails: "RES 1,A", opcode: [0xCB,0x8F], programCounter: registers.PC)
                registers.A = registers.A & 0b11111101
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x90: // RES 2,B - CB 90 - Resets bit 2 of B
                logInstructionDetails(instructionDetails: "RES 2,B", opcode: [0xCB,0x90], programCounter: registers.PC)
                registers.B = registers.B & 0b11111011
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x91: // RES 2,C - CB 91 - Resets bit 2 of C
                logInstructionDetails(instructionDetails: "RES 2,C", opcode: [0xCB,0x91], programCounter: registers.PC)
                registers.C = registers.C & 0b11111011
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x92: // RES 2,D - CB 92 - Resets bit 2 of D
                logInstructionDetails(instructionDetails: "RES 2,D", opcode: [0xCB,0x92], programCounter: registers.PC)
                registers.D = registers.D & 0b11111011
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x93: // RES 2,E - CB 93 - Resets bit 2 of E
                logInstructionDetails(instructionDetails: "RES 2,E", opcode: [0xCB,0x93], programCounter: registers.PC)
                registers.E = registers.E & 0b11111011
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x94: // RES 2,H - CB 94 - Resets bit 2 of H
                logInstructionDetails(instructionDetails: "RES 2,H", opcode: [0xCB,0x94], programCounter: registers.PC)
                registers.H = registers.H & 0b11111011
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x95: // RES 2,L - CB 95 - Resets bit 2 of L
                logInstructionDetails(instructionDetails: "RES 2,L", opcode: [0xCB,0x95], programCounter: registers.PC)
                registers.L = registers.L & 0b11111011
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x96: // RES 2,(HL) - CB 96 - Resets bit 2 of (HL)
                logInstructionDetails(instructionDetails: "RES 2,(HL)", opcode: [0xCB,0x96], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) & 0b11111011
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0x97: // RES 2,A - CB 97 - Resets bit 2 of A
                logInstructionDetails(instructionDetails: "RES 2,A", opcode: [0xCB,0x97], programCounter: registers.PC)
                registers.A = registers.A & 0b11111011
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x98: // RES 3,B - CB 98 - Resets bit 3 of B
                logInstructionDetails(instructionDetails: "RES 3,B", opcode: [0xCB,0x98], programCounter: registers.PC)
                registers.B = registers.B & 0b11110111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x99: // RES 3,C - CB 99 - Resets bit 3 of C
                logInstructionDetails(instructionDetails: "RES 3,C", opcode: [0xCB,0x99], programCounter: registers.PC)
                registers.C = registers.C & 0b11110111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x9A: // RES 3,D - CB 9A - Resets bit 3 of D
                logInstructionDetails(instructionDetails: "RES 3,D", opcode: [0xCB,0x9A], programCounter: registers.PC)
                registers.D = registers.D & 0b11110111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x9B: // RES 3,E - CB 9B - Resets bit 3 of E
                logInstructionDetails(instructionDetails: "RES 3,E", opcode: [0xCB,0x9B], programCounter: registers.PC)
                registers.E = registers.E & 0b11110111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x9C: // RES 3,H - CB 9C - Resets bit 3 of H
                logInstructionDetails(instructionDetails: "RES 3,H", opcode: [0xCB,0x9C], programCounter: registers.PC)
                registers.H = registers.H & 0b11110111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x9D: // RES 3,L - CB 9D - Resets bit 3 of L
                logInstructionDetails(instructionDetails: "RES 3,L", opcode: [0xCB,0x9D], programCounter: registers.PC)
                registers.L = registers.L & 0b11110111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x9E: // RES 3,(HL) - CB 9E - Resets bit 3 of (HL)
                logInstructionDetails(instructionDetails: "RES 3,(HL)", opcode: [0xCB,0x9E], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) & 0b11110111
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0x9F: // RES 3,A - CB 9F - Resets bit 3 of A
                logInstructionDetails(instructionDetails: "RES 3,A", opcode: [0xCB,0x9F], programCounter: registers.PC)
                registers.A = registers.A & 0b11110111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xA0: // RES 4,B - CB A0 - Resets bit 4 of B
                logInstructionDetails(instructionDetails: "RES 4,B", opcode: [0xCB,0xA0], programCounter: registers.PC)
                registers.B = registers.B & 0b11101111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xA1: // RES 4,C - CB A1 - Resets bit 4 of C
                logInstructionDetails(instructionDetails: "RES 4,C", opcode: [0xCB,0xA1], programCounter: registers.PC)
                registers.C = registers.C & 0b11101111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xA2: // RES 4,D - CB A2 - Resets bit 4 of D
                logInstructionDetails(instructionDetails: "RES 4,D", opcode: [0xCB,0xA2], programCounter: registers.PC)
                registers.D = registers.D & 0b11101111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xA3: // RES 4,E - CB A3 - Resets bit 4 of E
                logInstructionDetails(instructionDetails: "RES 4,E", opcode: [0xCB,0xA3], programCounter: registers.PC)
                registers.E = registers.E & 0b11101111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xA4: // RES 4,H - CB A4 - Resets bit 4 of H
                logInstructionDetails(instructionDetails: "RES 4,H", opcode: [0xCB,0xA4], programCounter: registers.PC)
                registers.H = registers.H & 0b11101111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xA5: // RES 4,L - CB A5 - Resets bit 4 of L
                logInstructionDetails(instructionDetails: "RES 4,L", opcode: [0xCB,0xA5], programCounter: registers.PC)
                registers.L = registers.L & 0b11101111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xA6: // RES 4,(HL) - CB A6 - Resets bit 4 of (HL)
                logInstructionDetails(instructionDetails: "RES 4,(HL)", opcode: [0xCB,0xA6], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) & 0b11101111
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0xA7: // RES 4,A - CB A7 - Resets bit 4 of A
                logInstructionDetails(instructionDetails: "RES 4,A", opcode: [0xCB,0xA7], programCounter: registers.PC)
                registers.A = registers.A & 0b11101111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xA8: // RES 5,B - CB A8 - Resets bit 5 of B
                logInstructionDetails(instructionDetails: "RES 5,B", opcode: [0xCB,0xA8], programCounter: registers.PC)
                registers.B = registers.B & 0b11011111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xA9: // RES 5,C - CB A9 - Resets bit 5 of C
                logInstructionDetails(instructionDetails: "RES 5,C", opcode: [0xCB,0xA9], programCounter: registers.PC)
                registers.C = registers.C & 0b11011111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xAA: // RES 5,D - CB AA - Resets bit 5 of D
                logInstructionDetails(instructionDetails: "RES 5,D", opcode: [0xCB,0xAA], programCounter: registers.PC)
                registers.D = registers.D & 0b11011111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xAB: // RES 5,E - CB AB - Resets bit 5 of E
                logInstructionDetails(instructionDetails: "RES 5,E", opcode: [0xCB,0xAB], programCounter: registers.PC)
                registers.E = registers.E & 0b11011111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xAC: // RES 5,H - CB AC - Resets bit 5 of H
                logInstructionDetails(instructionDetails: "RES 5,H", opcode: [0xCB,0xAC], programCounter: registers.PC)
                registers.H = registers.H & 0b11011111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xAD: // RES 5,L - CB AD - Resets bit 5 of L
                logInstructionDetails(instructionDetails: "RES 5,L", opcode: [0xCB,0xAD], programCounter: registers.PC)
                registers.L = registers.L & 0b11011111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xAE: // RES 5,(HL) - CB AE - Resets bit 5 of (HL)
                logInstructionDetails(instructionDetails: "RES 5,(HL)", opcode: [0xCB,0xAE], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) & 0b11011111
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0xAF: // RES 5,A - CB AF - Resets bit 5 of A
                logInstructionDetails(instructionDetails: "RES 5,A", opcode: [0xCB,0xAF], programCounter: registers.PC)
                registers.A = registers.A & 0b11011111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xB0: // RES 6,B - CB B0 - Resets bit 6 of B
                logInstructionDetails(instructionDetails: "RES 6,B", opcode: [0xCB,0xB0], programCounter: registers.PC)
                registers.B = registers.B & 0b10111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xB1: // RES 6,C - CB B1 - Resets bit 6 of C
                logInstructionDetails(instructionDetails: "RES 6,C", opcode: [0xCB,0xB1], programCounter: registers.PC)
                registers.C = registers.C & 0b10111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xB2: // RES 6,D - CB B2 - Resets bit 6 of D
                logInstructionDetails(instructionDetails: "RES 6,D", opcode: [0xCB,0xB2], programCounter: registers.PC)
                registers.D = registers.D & 0b10111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xB3: // RES 6,E - CB B3 - Resets bit 6 of E
                logInstructionDetails(instructionDetails: "RES 6,E", opcode: [0xCB,0xB3], programCounter: registers.PC)
                registers.E = registers.E & 0b10111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xB4: // RES 6,H - CB B4 - Resets bit 6 of H
                logInstructionDetails(instructionDetails: "RES 6,H", opcode: [0xCB,0xB4], programCounter: registers.PC)
                registers.H = registers.H & 0b10111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xB5: // RES 6,L - CB B5 - Resets bit 6 of L
                logInstructionDetails(instructionDetails: "RES 6,L", opcode: [0xCB,0xB5], programCounter: registers.PC)
                registers.L = registers.L & 0b10111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xB6: // RES 6,(HL) - CB B6 - Resets bit 6 of (HL)
                logInstructionDetails(instructionDetails: "RES 6,(HL)", opcode: [0xCB,0xB6], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) & 0b10111111
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0xB7: // RES 6,A - CB B7 - Resets bit 6 of A
                logInstructionDetails(instructionDetails: "RES 6,A", opcode: [0xCB,0xB7], programCounter: registers.PC)
                registers.A = registers.A & 0b10111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xB8: // RES 7,B - CB B8 - Resets bit 7 of B
                logInstructionDetails(instructionDetails: "RES 7,B", opcode: [0xCB,0xB8], programCounter: registers.PC)
                registers.B = registers.B & 0b01111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xB9: // RES 7,C - CB B9 - Resets bit 7 of C
                logInstructionDetails(instructionDetails: "RES 7,C", opcode: [0xCB,0xB9], programCounter: registers.PC)
                registers.C = registers.C & 0b01111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xBA: // RES 7,D - CB BA - Resets bit 7 of D
                logInstructionDetails(instructionDetails: "RES 7,D", opcode: [0xCB,0xBA], programCounter: registers.PC)
                registers.D = registers.D & 0b01111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xBB: // RES 7,E - CB BB - Resets bit 7 of E
                logInstructionDetails(instructionDetails: "RES 7,E", opcode: [0xCB,0xBB], programCounter: registers.PC)
                registers.E = registers.E & 0b01111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xBC: // RES 7,H - CB BC - Resets bit 7 of H
                logInstructionDetails(instructionDetails: "RES 7,H", opcode: [0xCB,0xBC], programCounter: registers.PC)
                registers.H = registers.H & 0b01111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xBD: // RES 7,L - CB BD - Resets bit 7 of L
                logInstructionDetails(instructionDetails: "RES 7,L", opcode: [0xCB,0xBD], programCounter: registers.PC)
                registers.L = registers.L & 0b01111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xBE: // RES 7,(HL) - CB BE - Resets bit 7 of (HL)
                logInstructionDetails(instructionDetails: "RES 7,(HL)", opcode: [0xCB,0xBE], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) & 0b01111111
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0xBF: // RES 7,A - CB BF - Resets bit 7 of A
                logInstructionDetails(instructionDetails: "RES 7,A", opcode: [0xCB,0xBF], programCounter: registers.PC)
                registers.A = registers.A & 0b01111111
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xC0: // SET 0,B - CB C0 - Sets bit 0 of B
                logInstructionDetails(instructionDetails: "SET 0,B", opcode: [0xCB,0xC0], programCounter: registers.PC)
                registers.B = registers.B | 0b00000001
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xC1: // SET 0,C - CB C1 - Sets bit 0 of C
                logInstructionDetails(instructionDetails: "SET 0,C", opcode: [0xCB,0xC1], programCounter: registers.PC)
                registers.C = registers.C | 0b00000001
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xC2: // SET 0,D - CB C2 - Sets bit 0 of D
                logInstructionDetails(instructionDetails: "SET 0,D", opcode: [0xCB,0xC2], programCounter: registers.PC)
                registers.D = registers.D | 0b00000001
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xC3: // SET 0,E - CB C3 - Sets bit 0 of E
                logInstructionDetails(instructionDetails: "SET 0,E", opcode: [0xCB,0xC3], programCounter: registers.PC)
                registers.E = registers.E | 0b00000001
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xC4: // SET 0,H - CB C4 - Sets bit 0 of H
                logInstructionDetails(instructionDetails: "SET 0,H", opcode: [0xCB,0xC4], programCounter: registers.PC)
                registers.H = registers.H | 0b00000001
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xC5: // SET 0,L - CB C5 - Sets bit 0 of L
                logInstructionDetails(instructionDetails: "SET 0,L", opcode: [0xCB,0xC5], programCounter: registers.PC)
                registers.L = registers.L | 0b00000001
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xC6: // SET 0,(HL) - CB C6 - Sets bit 0 of (HL)
                logInstructionDetails(instructionDetails: "SET 0,(HL)", opcode: [0xCB,0xC6], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) | 0b00000001
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0xC7: // SET 0,A - CB C7 - Sets bit 0 of A
                logInstructionDetails(instructionDetails: "SET 0,A", opcode: [0xCB,0xC7], programCounter: registers.PC)
                registers.A = registers.A | 0b00000001
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xC8: // SET 1,B - CB C8 - Sets bit 1 of B
                logInstructionDetails(instructionDetails: "SET 1,B", opcode: [0xCB,0xC8], programCounter: registers.PC)
                registers.B = registers.B | 0b00000010
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xC9: // SET 1,C - CB C9 - Sets bit 1 of C
                logInstructionDetails(instructionDetails: "SET 1,C", opcode: [0xCB,0xC9], programCounter: registers.PC)
                registers.C = registers.C | 0b00000010
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xCA: // SET 1,D - CB CA - Sets bit 1 of D
                logInstructionDetails(instructionDetails: "SET 1,D", opcode: [0xCB,0xCA], programCounter: registers.PC)
                registers.D = registers.D | 0b00000010
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xCB: // SET 1,E - CB CB - Sets bit 1 of E
                logInstructionDetails(instructionDetails: "SET 1,E", opcode: [0xCB,0xCB], programCounter: registers.PC)
                registers.E = registers.E | 0b00000010
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xCC: // SET 1,H - CB CC - Sets bit 1 of H
                logInstructionDetails(instructionDetails: "SET 1,H", opcode: [0xCB,0xCC], programCounter: registers.PC)
                registers.H = registers.H | 0b00000010
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xCD: // SET 1,L - CB CD - Sets bit 1 of L
                logInstructionDetails(instructionDetails: "SET 1,L", opcode: [0xCB,0xCD], programCounter: registers.PC)
                registers.L = registers.L | 0b00000010
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xCE: // SET 1,(HL) - CB CE - Sets bit 1 of (HL)
                logInstructionDetails(instructionDetails: "SET 1,(HL)", opcode: [0xCB,0xCE], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) | 0b00000010
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0xCF: // SET 1,A - CB CF - Sets bit 1 of A
                logInstructionDetails(instructionDetails: "SET 1,A", opcode: [0xCB,0xCF], programCounter: registers.PC)
                registers.A = registers.A | 0b00000010
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xD0: // SET 2,B - CB D0 - Sets bit 2 of B
                logInstructionDetails(instructionDetails: "SET 2,B", opcode: [0xCB,0xD0], programCounter: registers.PC)
                registers.B = registers.B | 0b00000100
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xD1: // SET 2,C - CB D1 - Sets bit 2 of C
                logInstructionDetails(instructionDetails: "SET 2,C", opcode: [0xCB,0xD1], programCounter: registers.PC)
                registers.C = registers.C | 0b00000100
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xD2: // SET 2,D - CB D2 - Sets bit 2 of D
                logInstructionDetails(instructionDetails: "SET 2,D", opcode: [0xCB,0xD2], programCounter: registers.PC)
                registers.D = registers.D | 0b00000100
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xD3: // SET 2,E - CB D3 - Sets bit 2 of E
                logInstructionDetails(instructionDetails: "SET 2,E", opcode: [0xCB,0xD3], programCounter: registers.PC)
                registers.E = registers.E | 0b00000100
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xD4: // SET 2,H - CB D4 - Sets bit 2 of H
                logInstructionDetails(instructionDetails: "SET 2,H", opcode: [0xCB,0xD4], programCounter: registers.PC)
                registers.H = registers.H | 0b00000100
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xD5: // SET 2,L - CB D5 - Sets bit 2 of L
                logInstructionDetails(instructionDetails: "SET 2,L", opcode: [0xCB,0xD5], programCounter: registers.PC)
                registers.L = registers.L | 0b00000100
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xD6: // SET 2,(HL) - CB D6 - Sets bit 2 of (HL)
                logInstructionDetails(instructionDetails: "SET 2,(HL)", opcode: [0xCB,0xD6], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) | 0b00000001
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0xD7: // SET 2,A - CB D7 - Sets bit 2 of A
                logInstructionDetails(instructionDetails: "SET 2,A", opcode: [0xCB,0xD7], programCounter: registers.PC)
                registers.A = registers.A | 0b00000100
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xD8: // SET 3,B - CB D8 - Sets bit 3 of B
                logInstructionDetails(instructionDetails: "SET 3,B", opcode: [0xCB,0xD8], programCounter: registers.PC)
                registers.B = registers.B | 0b00001000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xD9: // SET 3,C - CB D9 - Sets bit 3 of C
                logInstructionDetails(instructionDetails: "SET 3,C", opcode: [0xCB,0xD9], programCounter: registers.PC)
                registers.C = registers.C | 0b00001000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xDA: // SET 3,D - CB DA - Sets bit 3 of D
                logInstructionDetails(instructionDetails: "SET 3,D", opcode: [0xCB,0xDA], programCounter: registers.PC)
                registers.D = registers.D | 0b00001000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xDB: // SET 3,E - CB DB - Sets bit 3 of E
                logInstructionDetails(instructionDetails: "SET 3,E", opcode: [0xCB,0xDB], programCounter: registers.PC)
                registers.E = registers.E | 0b00001000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xDC: // SET 43,H - CB DC - Sets bit 3 of H
                logInstructionDetails(instructionDetails: "SET 3,H", opcode: [0xCB,0xDC], programCounter: registers.PC)
                registers.H = registers.H | 0b00001000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xDD: // SET 3,L - CB DD - Sets bit 3 of L
                logInstructionDetails(instructionDetails: "SET 3,L", opcode: [0xCB,0xDD], programCounter: registers.PC)
                registers.L = registers.L | 0b00001000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xDE: // SET 3,(HL) - CB DE - Sets bit 3 of (HL)
                logInstructionDetails(instructionDetails: "SET 3,(HL)", opcode: [0xCB,0xDE], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) | 0b00001000
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0xDF: // SET 3,A - CB DF - Sets bit 3 of A
                logInstructionDetails(instructionDetails: "SET 3,A", opcode: [0xCB,0xDF], programCounter: registers.PC)
                registers.A = registers.A | 0b00001000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xE0: // SET 4,B - CB E0 - Sets bit 4 of B
                logInstructionDetails(instructionDetails: "SET 4,B", opcode: [0xCB,0xE0], programCounter: registers.PC)
                registers.B = registers.B | 0b00010000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xE1: // SET 4,C - CB E1 - Sets bit 4 of C
                logInstructionDetails(instructionDetails: "SET 4,C", opcode: [0xCB,0xE1], programCounter: registers.PC)
                registers.C = registers.C | 0b00010000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xE2: // SET 4,D - CB E2 - Sets bit 4 of D
                logInstructionDetails(instructionDetails: "SET 4,D", opcode: [0xCB,0xE2], programCounter: registers.PC)
                registers.D = registers.D | 0b00010000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xE3: // SET 4,E - CB E3 - Sets bit 4 of E
                logInstructionDetails(instructionDetails: "SET 4,E", opcode: [0xCB,0xE3], programCounter: registers.PC)
                registers.E = registers.E | 0b00010000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xE4: // SET 4,H - CB E4 - Sets bit 4 of H
                logInstructionDetails(instructionDetails: "SET 4,H", opcode: [0xCB,0xE4], programCounter: registers.PC)
                registers.H = registers.H | 0b00010000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xE5: // SET 4,L - CB E5 - Sets bit 4 of L
                logInstructionDetails(instructionDetails: "SET 4,L", opcode: [0xCB,0xE5], programCounter: registers.PC)
                registers.L = registers.L | 0b00010000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xE6: // SET 4,(HL) - CB E6 - Sets bit 4 of (HL)
                logInstructionDetails(instructionDetails: "SET 4,(HL)", opcode: [0xCB,0xE6], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) | 0b00010000
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0xE7: // SET 4,A - CB E7 - Sets bit 4 of A
                logInstructionDetails(instructionDetails: "SET 4,A", opcode: [0xCB,0xE7], programCounter: registers.PC)
                registers.A = registers.A | 0b00010000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xE8: // SET 5,B - CB E8 - Sets bit 5 of B
                logInstructionDetails(instructionDetails: "SET 5,B", opcode: [0xCB,0xE8], programCounter: registers.PC)
                registers.B = registers.B | 0b00100000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xE9: // SET 5,C - CB E9 - Sets bit 5 of C
                logInstructionDetails(instructionDetails: "SET 5,C", opcode: [0xCB,0xE9], programCounter: registers.PC)
                registers.C = registers.C | 0b00100000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xEA: // SET 5,D - CB EA - Sets bit 5 of D
                logInstructionDetails(instructionDetails: "SET 5,D", opcode: [0xCB,0xEA], programCounter: registers.PC)
                registers.D = registers.D | 0b00100000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xEB: // SET 5,E - CB EB - Sets bit 5 of E
                logInstructionDetails(instructionDetails: "SET 5,E", opcode: [0xCB,0xEB], programCounter: registers.PC)
                registers.E = registers.E | 0b00100000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xEC: // SET 5,H - CB EC - Sets bit 5 of H
                logInstructionDetails(instructionDetails: "SET 5,H", opcode: [0xCB,0xEC], programCounter: registers.PC)
                registers.H = registers.H | 0b00100000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xED: // SET 5,L - CB ED - Sets bit 5 of L
                logInstructionDetails(instructionDetails: "SET 5,L", opcode: [0xCB,0xED], programCounter: registers.PC)
                registers.L = registers.L | 0b00100000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xEE: // SET 5,(HL) - CB EE - Sets bit 5 of (HL)
                logInstructionDetails(instructionDetails: "SET 5,(HL)", opcode: [0xCB,0xEE], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) | 0b00100000
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0xEF: // SET 5,A - CB EF - Sets bit 5 of A
                logInstructionDetails(instructionDetails: "SET 5,A", opcode: [0xCB,0xEF], programCounter: registers.PC)
                registers.A = registers.A | 0b00100000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xF0: // SET 6,B - CB F0 - Sets bit 6 of B
                logInstructionDetails(instructionDetails: "SET 6,B", opcode: [0xCB,0xF0], programCounter: registers.PC)
                registers.B = registers.B | 0b01000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xF1: // SET 6,C - CB F1 - Sets bit 6 of C
                logInstructionDetails(instructionDetails: "SET 6,C", opcode: [0xCB,0xF1], programCounter: registers.PC)
                registers.C = registers.C | 0b01000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xF2: // SET 6,D - CB F2 - Sets bit 6 of D
                logInstructionDetails(instructionDetails: "SET 6,D", opcode: [0xCB,0xF2], programCounter: registers.PC)
                registers.D = registers.D | 0b01000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xF3: // SET 6,E - CB F3 - Sets bit 6 of E
                logInstructionDetails(instructionDetails: "SET 6,E", opcode: [0xCB,0xF3], programCounter: registers.PC)
                registers.E = registers.E | 0b01000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xF4: // SET 6,H - CB F4 - Sets bit 6 of H
                logInstructionDetails(instructionDetails: "SET 6,H", opcode: [0xCB,0xF4], programCounter: registers.PC)
                registers.H = registers.H | 0b01000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xF5: // SET 6,L - CB F5 - Sets bit 6 of L
                logInstructionDetails(instructionDetails: "SET 6,L", opcode: [0xCB,0xF5], programCounter: registers.PC)
                registers.L = registers.L | 0b01000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xF6: // SET 6,(HL) - CB F6 - Sets bit 6 of (HL)
                logInstructionDetails(instructionDetails: "SET 6,(HL)", opcode: [0xCB,0xF6], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) | 0b01000000
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0xF7: // SET 6,A - CB F7 - Sets bit 6 of A
                logInstructionDetails(instructionDetails: "SET 6,A", opcode: [0xCB,0xF7], programCounter: registers.PC)
                registers.A = registers.A | 0b01000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xF8: // SET 7,B - CB F8 - Sets bit 7 of B
                logInstructionDetails(instructionDetails: "SET 7,B", opcode: [0xCB,0xF8], programCounter: registers.PC)
                registers.B = registers.B | 0b10000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xF9: // SET 7,C - CB F9 - Sets bit 7 of C
                logInstructionDetails(instructionDetails: "SET 7,C", opcode: [0xCB,0xF9], programCounter: registers.PC)
                registers.C = registers.C | 0b10000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xFA: // SET 7,D - CB FA - Sets bit 7 of D
                logInstructionDetails(instructionDetails: "SET 7,D", opcode: [0xCB,0xFA], programCounter: registers.PC)
                registers.D = registers.D | 0b10000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xFB: // SET 7,E - CB FB - Sets bit 7 of E
                logInstructionDetails(instructionDetails: "SET 7,E", opcode: [0xCB,0xFB], programCounter: registers.PC)
                registers.E = registers.E | 0b10000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xFC: // SET 7,H - CB FC - Sets bit 7 of H
                logInstructionDetails(instructionDetails: "SET 7,H", opcode: [0xCB,0xFC], programCounter: registers.PC)
                registers.H = registers.H | 0b10000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xFD: // SET 7,L - CB FD - Sets bit 7 of L
                logInstructionDetails(instructionDetails: "SET 7,L", opcode: [0xCB,0xFD], programCounter: registers.PC)
                registers.L = registers.L | 0b10000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0xFE: // SET 7,(HL) - CB FE - Sets bit 7 of (HL)
                logInstructionDetails(instructionDetails: "SET 7,(HL)", opcode: [0xCB,0xFE], programCounter: registers.PC)
                let tempResult = mmu.readByte(address: registers.HL) | 0b10000000
                mmu.writeByte(address: registers.HL, value: tempResult)
                tStates = tStates + 15
                incrementR(opcodeCount:2)
            case 0xFF: // SET 7,A - CB FF - Sets bit 7 of A
                logInstructionDetails(instructionDetails: "SET 7,A", opcode: [0xCB,0xFF], programCounter: registers.PC)
                registers.A = registers.A | 0b10000000
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            default:
                tStates = tStates + 0 // check if this is correct
                logInstructionDetails(opcode: [0xCB,opcode2], programCounter: registers.PC)
                // myz80Queue.addToQueue(address: registers.PC, opCodes: [0xCB,opcode2])
                incrementR(opcodeCount:2)
            } // end CB opcodes
            registers.PC = registers.PC &+ 2
        case 0xCC: // CALL Z,$nn - CC n n - If the zero flag is set, the current PC value plus three is pushed onto the stack, then is loaded with $nn
            logInstructionDetails(instructionDetails: "CALL Z,$nn",opcode: [0xCC], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
            {
                registers.PC = registers.PC &+ 3
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCH)
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCL)
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
                tStates = tStates + 17
            }
            else
            {
                tStates = tStates + 10
            }
            incrementR(opcodeCount:1)
        case 0xCD: // CALL $nn - CD n n - The current PC value plus three is pushed onto the stack, then is loaded with $nn
            logInstructionDetails(instructionDetails: "CALL $nn",opcode: [0xCD], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: registers.PCH)
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: registers.PCL)
            registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            tStates = tStates + 17
            incrementR(opcodeCount:1)
        case 0xCF: // RST 0x08 - The current PC value plus one is pushed onto the stack, then is loaded with 0x08
            logInstructionDetails(instructionDetails: "RST 0x08", opcode: [0xCF], programCounter: registers.PC)
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0008
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xD0: // RET NC - D0 - If the carry flag is unset, the top stack entry is popped into PC
            logInstructionDetails(instructionDetails: "RET NC", opcode: [0xD0], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
            {
                registers.PC = registers.PC &+ 1
                tStates = tStates + 5
            }
            else
            {
                registers.PCL = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                tStates = tStates + 11
            }
            incrementR(opcodeCount:1)
        case 0xD1: // POP DE - D1 - The memory location pointed to by SP is stored into E and SP is incremented. The memory location pointed to by SP is stored into D and SP is incremented again.
            logInstructionDetails(instructionDetails: "POP DE", opcode: [0xD1], programCounter: registers.PC)
            registers.E = mmu.readByte(address: registers.SP)
            registers.D = mmu.readByte(address: registers.SP &+ 1)
            registers.SP = registers.SP &+ 2
            registers.PC = registers.PC &+ 1
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xD2: // JP NC,$nn - D2 n n - If the carry flag is unset, $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP NC,$nn", opcode: [0xD2], values: [opcode2,opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
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
                    mmu.map(readDevice: fontROM, writeDevice: nil, memoryLocation: 0xF000)     // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
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
            registers.PC = registers.PC &+ 2
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xD4: // CALL NC,$nn - D4 n n - If the carry flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn
            logInstructionDetails(instructionDetails: "CALL NC,$nn",opcode: [0xD4], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
            {
                tStates = tStates + 10
            }
            else
            {
                registers.PC = registers.PC &+ 3
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCH)
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCL)
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
                tStates = tStates + 17
            }
            incrementR(opcodeCount:1)
        case 0xD5: // PUSH DE - D5 - SP is decremented and D is stored into the memory location pointed to by SP. SP is decremented again and E is stored into the memory location pointed to by SP
            logInstructionDetails(instructionDetails: "PUSH DE", opcode: [0xD5], programCounter: registers.PC)
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: registers.D)
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: registers.E)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xD6: // SUB $n - D6 n - Subtracts $n from A
            logInstructionDetails(instructionDetails: "SUB $n", opcode: [0xD6], values: [opcode2], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: opcode2)
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xD7: // RST 0x10 - The current PC value plus one is pushed onto the stack, then is loaded with 0x10
            logInstructionDetails(instructionDetails: "RST 0x10", opcode: [0xD7], programCounter: registers.PC)
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0010
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xD8: // RET C - D8 - If the carry flag is set, the top stack entry is popped into PC
            logInstructionDetails(instructionDetails: "RET NC", opcode: [0xD0], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
            {
                registers.PCL = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                tStates = tStates + 11
            }
            else
            {
                registers.PC = registers.PC &+ 1
                tStates = tStates + 5
            }
            incrementR(opcodeCount:1)
        case 0xD9: // EXX - D9 - Exchanges the 16-bit contents of BC, DE, and HL with BC', DE', and HL'
            logInstructionDetails(instructionDetails: "EXX", opcode: [0xD9], programCounter: registers.PC)
            (registers.BC,registers.DE,registers.HL) = (registers.altBC,registers.altDE,registers.altHL)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xDA: // JP C,$nn - DA n n - If the carry flag is set, $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP C,$nn", opcode: [0xDA], values: [opcode2,opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xDB: // IN A,($n) - DB n - A byte from port $n is written to A
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
            registers.PC = registers.PC &+ 2
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xDC: // CALL C,$nn - DC n n - If the carry flag is set, the current PC value plus three is pushed onto the stack, then is loaded with $nn.
            logInstructionDetails(instructionDetails: "CALL C,$nn",opcode: [0xDC], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
            {
                registers.PC = registers.PC &+ 3
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCH)
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCL)
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
                tStates = tStates + 17
            }
            else
            {
                tStates = tStates + 10
            }
            incrementR(opcodeCount:1)
        case 0xDD: // DD instructions
            switch opcode2
            {
                case 0x09: // ADD IX,BC - DD 09 - The value of BC is added to IX
                    logInstructionDetails(instructionDetails: "ADD IX,BC", opcode: [0xDD,0x09], programCounter: registers.PC)
                    let tempResult = registers.IX &+ registers.BC
                    let halfCarry = UInt8((registers.IX ^ registers.BC ^ tempResult) & 0x1000)
                    let carrytempResult = UInt32(registers.IX) + UInt32(registers.BC)
                    let carry = UInt8((carrytempResult & 0x10000) >> 16)
                    registers.IX = tempResult
                    registers.F = registers.F & ~z80Flags.Negative.rawValue
                    registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
                    registers.F = registers.F | halfCarry
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 15
                    incrementR(opcodeCount:2)
                case 0x19: // ADD IX,DE - DD 19 - The value of DE is added to IX
                    logInstructionDetails(instructionDetails: "ADD IX,DE", opcode: [0xDD,0x19], programCounter: registers.PC)
                    let tempResult = registers.IX &+ registers.DE
                    let halfCarry = UInt8((registers.IX ^ registers.DE ^ tempResult) & 0x1000)
                    let carrytempResult = UInt32(registers.IX) + UInt32(registers.DE)
                    let carry = UInt8((carrytempResult & 0x10000) >> 16)
                    registers.IX = tempResult
                    registers.F = registers.F & ~z80Flags.Negative.rawValue
                    registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
                    registers.F = registers.F | halfCarry
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 15
                    incrementR(opcodeCount:2)
                case 0x21: // LD IX,$nn - DD 21 n n - Loads $nn into register IX
                    logInstructionDetails(instructionDetails: "LD IX,$nn", opcode: [0xDD,0x21], values: [opcode3,opcode4], programCounter: registers.PC)
                    registers.IX = UInt16(opcode4) << 8 | UInt16(opcode3)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 14
                    incrementR(opcodeCount:2)
                case 0x22: // LD ($nn),IX - DD 22 n n - Loads $nn into register IX
                    logInstructionDetails(instructionDetails: "LD ($nn),IX", opcode: [0xDD,0x22], values: [opcode3,opcode4], programCounter: registers.PC)
                    let tempResult =  UInt16(opcode4) << 8 | UInt16(opcode3)
                    mmu.writeByte(address: tempResult, value: UInt8(registers.IX & 0x00FF))
                    mmu.writeByte(address: tempResult &+ 1, value: UInt8(registers.IX >> 8))
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 20
                    incrementR(opcodeCount:2)
                case 0x23: // INC IX - DD 23 - Adds one to IX
                    logInstructionDetails(instructionDetails: "INC IX", opcode: [0xDD,0x23], programCounter: registers.PC)
                    registers.PC = registers.IX &+ 1
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 10
                    incrementR(opcodeCount:2)
                case 0x2A: // LD IX,($nn) - DD 2A n n - Loads the value pointed to by $nn into IX
                    logInstructionDetails(instructionDetails: "LD IX,($nn)", opcode: [0xDD,0x2A], values: [opcode3,opcode4], programCounter: registers.PC)
                    let tempResult = UInt16(opcode4) << 8 | UInt16(opcode3)
                    let tempResultIXH = mmu.readByte(address: tempResult)
                    let tempResultIXL = mmu.readByte(address: tempResult &+ 1)
                    registers.IX = UInt16(tempResultIXH << 8) | UInt16(tempResultIXL)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 20
                    incrementR(opcodeCount:2)
                case 0x2B: // DEC IX - DD 2B - Subtracts one from IX
                    logInstructionDetails(instructionDetails: "DEC IX", opcode: [0xDD,0x2B], programCounter: registers.PC)
                    registers.IX = registers.IX &- 1
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 10
                    incrementR(opcodeCount:2)
                case 0x29: // ADD IX,IX - DD 29 - The value of IX is added to IX
                    logInstructionDetails(instructionDetails: "ADD IX,IX", opcode: [0xDD,0x29], programCounter: registers.PC)
                    let tempResult = registers.IX &+ registers.IX
                    let halfCarry = UInt8((registers.IX ^ registers.IX ^ tempResult) & 0x1000)
                    let carrytempResult = UInt32(registers.IX) + UInt32(registers.IX)
                    let carry = UInt8((carrytempResult & 0x10000) >> 16)
                    registers.IX = tempResult
                    registers.F = registers.F & ~z80Flags.Negative.rawValue
                    registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
                    registers.F = registers.F | halfCarry
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 15
                    incrementR(opcodeCount:2)
                case 0x34: // INC (IX+$d) - DD 34 d - Adds one to the memory location pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "INC (IX+$d)", opcode: [0xDD,0x34], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    var previous = mmu.readByte(address: tempResult)
                    (previous,registers.F) = z80FastFlags.incHelper(operand: previous, currentFlags: registers.F)
                    mmu.writeByte(address: tempResult,value: previous)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 23
                    incrementR(opcodeCount:2)
                case 0x35: // DEC (IX+$d) - DD 35 d - Subtracts one from the memory location pointed to by IX plus $d.
                    logInstructionDetails(instructionDetails: "DEC (IX+$d)", opcode: [0xDD,0x35], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    var previous = mmu.readByte(address: tempResult)
                    (previous,registers.F) = z80FastFlags.decHelper(operand: previous, currentFlags: registers.F)
                    mmu.writeByte(address: tempResult,value: previous)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 23
                    incrementR(opcodeCount:2)
                case 0x36: // LD (IX+$d),$n - DD 36 d n - Stores $n to the memory location pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "LD (IX+$d),$n", opcode: [0xDD,0x36], values: [opcode3,opcode4], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: opcode4)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x39: // ADD IX,SP - DD 39 - The value of SP is added to IX
                    logInstructionDetails(instructionDetails: "ADD IX,SP", opcode: [0xDD,0x39], programCounter: registers.PC)
                    let tempResult = registers.IX &+ registers.SP
                    let halfCarry = UInt8((registers.IX ^ registers.SP ^ tempResult) & 0x1000)
                    let carrytempResult = UInt32(registers.IX) + UInt32(registers.SP)
                    let carry = UInt8((carrytempResult & 0x10000) >> 16)
                    registers.IX = tempResult
                    registers.F = registers.F & ~z80Flags.Negative.rawValue
                    registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
                    registers.F = registers.F | halfCarry
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 15
                    incrementR(opcodeCount:2)
                case 0x46: // LD B,(IX+$d) - DD 46 d - Loads the value pointed to by IX plus $d into B
                    logInstructionDetails(instructionDetails: "LD B,(IX+$d)", opcode: [0xDD,0x46], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.B = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x4E: // LD C,(IX+$d) - DD 4E d - Loads the value pointed to by IX plus $d into B
                    logInstructionDetails(instructionDetails: "LD C,(IX+$d)", opcode: [0xDD,0x4E], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.C = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x56: // LD D,(IX+$d) - DD 56 d - Loads the value pointed to by IX plus $d into D
                    logInstructionDetails(instructionDetails: "LD D,(IX+$d)", opcode: [0xDD,0x46], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.D = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x5E: // LD E,(IX+$d) - DD 5E d - Loads the value pointed to by IX plus $d into E
                    logInstructionDetails(instructionDetails: "LD E,(IX+$d)", opcode: [0xDD,0x5E], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.E = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x66: // LD H,(IX+$d) - DD 66 d - Loads the value pointed to by IX plus $d into H
                    logInstructionDetails(instructionDetails: "LD H,(IX+$d)", opcode: [0xDD,0x66], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.H = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x6E: // LD L,(IX+$d) - DD 6E d - Loads the value pointed to by IX plus $d into L
                    logInstructionDetails(instructionDetails: "LD L,(IX+$d)", opcode: [0xDD,0x6E], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.L = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x70: // LD (IX+$d),B - DD 70 d - Stores B to the memory location pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "LD (IX+$d),B", opcode: [0xDD,0x70], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.B)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x71: // LD (IX+$d),C - DD 71 d - Stores C to the memory location pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "LD (IX+$d),C", opcode: [0xDD,0x71], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.C)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x72: // LD (IX+$d),D - DD 72 d - Stores D to the memory location pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "LD (IX+$d),D", opcode: [0xDD,0x72], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.D)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x73: // LD (IX+$d),E - DD 73 d - Stores E to the memory location pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "LD (IX+$d),E", opcode: [0xDD,0x73], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.E)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x74: // LD (IX+$d),H - DD 74 d - Stores H to the memory location pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "LD (IX+$d),H", opcode: [0xDD,0x74], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.H)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x75: // LD (IX+$d),L - DD 75 d - Stores L to the memory location pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "LD (IX+$d),L", opcode: [0xDD,0x36], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.L)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x77: // LD (IX+$d),A - DD 77 d - Stores A to the memory location pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "LD (IX+$d),A", opcode: [0xDD,0x77], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.A)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x7E: // LD A,(IX+$d) - DD 7E d - Loads the value pointed to by IX plus $d into A
                    logInstructionDetails(instructionDetails: "LD A,(IX+$d)", opcode: [0xDD,0x7E], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.A = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x96: // SUB (IX+$d) - DD 96 d - Subtracts the value pointed to by IX plus $d from A
                    logInstructionDetails(instructionDetails: "SUB (IX+$d)", opcode: [0xDD,0x96], values: [opcode2], programCounter: registers.PC)
                    let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: mmu.readByte(address: tempResultAddress))
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0xA6: // AND (IX+$d) - DD A6 d - Bitwise AND on A with the value pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "AND (IX+$d)", opcode: [0xDD,0xA6], values: [opcode3], programCounter: registers.PC)
                    let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & mmu.readByte(address: tempResultAddress))
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0xAE: // XOR (IX+$d) - DD AE d - Bitwise XOR on A with the value pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "XOR (IX+$d)", opcode: [0xDD,0xAE], values: [opcode3], programCounter: registers.PC)
                    let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ mmu.readByte(address: tempResultAddress))
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0xB6: // OR (IX+$d) - DD B6 d - Bitwise OR on A with the value pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "OR (IX+$d)", opcode: [0xDD,0xB6], values: [opcode3], programCounter: registers.PC)
                    let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | mmu.readByte(address: tempResultAddress))
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0xBE: // CP (IX+$d) - DD BE d - Subtracts the value pointed to by IX plus $d from A and affects flags according to the result. A is not modified
                    logInstructionDetails(instructionDetails: "CP (IX+$d)", opcode: [0xDD,0xBE], values: [opcode3], programCounter: registers.PC)
                    let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    let tempResult = mmu.readByte(address: tempResultAddress)
                    let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: tempResult)
                    registers.F = tempFlags
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0xCB: // DD CB opcodes
                    switch opcode4
                    {
                        case 0x40: // BIT 0,(IX+$d) - DD CB $d 40 - Tests bit 0 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x40], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 1
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x41: // BIT 0,(IX+$d) - DD CB $d 41 - Tests bit 0 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x41], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 1
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x42: // BIT 0,(IX+$d) - DD CB $d 42 - Tests bit 0 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x42], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 1
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x43: // BIT 0,(IX+$d) - DD CB $d 43 - Tests bit 0 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x43], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 1
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x44: // BIT 0,(IX+$d) - DD CB $d 44 - Tests bit 0 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x44], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 1
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x45: // BIT 0,(IX+$d) - DD CB $d 45 - Tests bit 0 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x45], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 1
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x46: // BIT 0,(IX+$d) - DD CB $d 46 - Tests bit 0 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x46], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 1
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x47: // BIT 0,(IX+$d) - DD CB $d 47 - Tests bit 0 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x47], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 1
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x48: // BIT 1,(IX+$d) - DD CB $d 48 - Tests bit 1 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x48], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 2
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x49: // BIT 1,(IX+$d) - DD CB $d 49 - Tests bit 1 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x49], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 2
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x4A: // BIT 1,(IX+$d) - DD CB $d 4A - Tests bit 1 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x4A], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 2
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x4B: // BIT 1,(IX+$d) - DD CB $d 4B - Tests bit 1 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x4B], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 2
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x4C: // BIT 1,(IX+$d) - DD CB $d 4C - Tests bit 1 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x4C], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 2
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x4D: // BIT 1,(IX+$d) - DD CB $d 4D - Tests bit 1 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x4D], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 2
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x4E: // BIT 1,(IX+$d) - DD CB $d 4E - Tests bit 1 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x4E], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 2
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x4F: // BIT 1,(IX+$d) - DD CB $d 4F - Tests bit 1 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x4F], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 2
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x50: // BIT 2,(IX+$d) - DD CB $d 50 - Tests bit 2 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x50], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 4
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x51: // BIT 2,(IX+$d) - DD CB $d 51 - Tests bit 2 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x51], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 4
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x52: // BIT 2,(IX+$d) - DD CB $d 52 - Tests bit 2 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x52], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 4
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x53: // BIT 2,(IX+$d) - DD CB $d 53 - Tests bit 2 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x53], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 4
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x54: // BIT 2,(IX+$d) - DD CB $d 54 - Tests bit 2 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x54], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 4
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x55: // BIT 2,(IX+$d) - DD CB $d 55 - Tests bit 2 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x55], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 4
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x56: // BIT 2,(IX+$d) - DD CB $d 56 - Tests bit 2 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x56], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 4
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x57: // BIT 2,(IX+$d) - DD CB $d 57 - Tests bit 2 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x57], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 4
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x58: // BIT 3,(IX+$d) - DD CB $d 58 - Tests bit 3 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x58], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 8
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x59: // BIT 3,(IX+$d) - DD CB $d 59 - Tests bit 3 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x59], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 8
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x5A: // BIT 3,(IX+$d) - DD CB $d 5A - Tests bit 3 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x5A], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 8
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x5B: // BIT 3,(IX+$d) - DD CB $d 5B - Tests bit 3 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x5B], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 8
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x5C: // BIT 3,(IX+$d) - DD CB $d 5C - Tests bit 3 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x5C], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 8
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x5D: // BIT 3,(IX+$d) - DD CB $d 5D - Tests bit 3 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x5D], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 8
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x5E: // BIT 3,(IX+$d) - DD CB $d 5E - Tests bit 3 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x5E], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 8
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x5F: // BIT 3,(IX+$d) - DD CB $d 5F - Tests bit 3 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x5F], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 8
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x60: // BIT 4,(IX+$d) - DD CB $d 60 - Tests bit 4 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x60], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 16
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x61: // BIT 4,(IX+$d) - DD CB $d 61 - Tests bit 4 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x61], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 16
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x62: // BIT 4,(IX+$d) - DD CB $d 62 - Tests bit 4 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x62], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 16
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x63: // BIT 4,(IX+$d) - DD CB $d 63 - Tests bit 4 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x63], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 16
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x64: // BIT 4,(IX+$d) - DD CB $d 64 - Tests bit 4 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x64], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 16
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x65: // BIT 4,(IX+$d) - DD CB $d 65 - Tests bit 4 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x65], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 16
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x66: // BIT 4,(IX+$d) - DD CB $d 66 - Tests bit 4 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x66], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 16
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x67: // BIT 4,(IX+$d) - DD CB $d 67 - Tests bit 4 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x67], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 16
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x68: // BIT 5,(IX+$d) - DD CB $d 68 - Tests bit 5 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x68], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 32
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x69: // BIT 5,(IX+$d) - DD CB $d 69 - Tests bit 5 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x69], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 32
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x6A: // BIT 5,(IX+$d) - DD CB $d 6A - Tests bit 5 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x6A], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 32
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x6B: // BIT 5,(IX+$d) - DD CB $d 6B - Tests bit 5 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x6B], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 32
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x6C: // BIT 5,(IX+$d) - DD CB $d 6C - Tests bit 5 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x6C], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 32
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x6D: // BIT 5,(IX+$d) - DD CB $d 6D - Tests bit 5 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x6D], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 32
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x6E: // BIT 5,(IX+$d) - DD CB $d 6E - Tests bit 5 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x6E], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 32
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x6F: // BIT 5,(IX+$d) - DD CB $d 6F - Tests bit 5 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x6F], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 32
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x70: // BIT 6,(IX+$d) - DD CB $d 70 - Tests bit 6 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x70], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 64
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x71: // BIT 6,(IX+$d) - DD CB $d 71 - Tests bit 6 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x71], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 64
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x72: // BIT 6,(IX+$d) - DD CB $d 72 - Tests bit 6 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x72], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 64
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x73: // BIT 6,(IX+$d) - DD CB $d 73 - Tests bit 6 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x73], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 64
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x74: // BIT 6,(IX+$d) - DD CB $d 74 - Tests bit 6 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x74], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 64
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x75: // BIT 6,(IX+$d) - DD CB $d 75 - Tests bit 6 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x75], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 64
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x76: // BIT 6,(IX+$d) - DD CB $d 76 - Tests bit 6 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x76], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 64
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x77: // BIT 6,(IX+$d) - DD CB $d 77 - Tests bit 6 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x77], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 64
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x78: // BIT 7,(IX+$d) - DD CB $d 78 - Tests bit 7 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x78], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 128
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x79: // BIT 7,(IX+$d) - DD CB $d 79 - Tests bit 7 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x79], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 128
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x7A: // BIT 7,(IX+$d) - DD CB $d 7A - Tests bit 7 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x7A], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 128
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x7B: // BIT 7,(IX+$d) - DD CB $d 7B - Tests bit 7 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x7B], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 128
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x7C: // BIT 7,(IX+$d) - DD CB $d 7C - Tests bit 7 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x7C], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 128
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x7D: // BIT 7,(IX+$d) - DD CB $d 7D - Tests bit 7 of the memory location pointed to by IX plus $d L
                            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x7D], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 128
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x7E: // BIT 7,(IX+$d) - DD CB $d 7E - Tests bit 7 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x7E], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 128
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x7F: // BIT 7,(IX+$d) - DD CB $d 7F - Tests bit 7 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x7F], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 128
                            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                            registers.F = registers.F | z80Flags.HalfCarry.rawValue
                            registers.F = registers.F & ~z80Flags.Negative.rawValue
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 20
                            incrementR(opcodeCount:3)
                        case 0x86: // RES 0,(IX+$d) - DD CB d 86 - Resets bit 0 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "RES 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x86], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 0b11111110
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0x8E: // RES 1,(IX+$d) - DD CB d 8E - Resets bit 1 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "RES 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x8E], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 0b11111101
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0x96: // RES 2,(IX+$d) - DD CB d 96 - Resets bit 2 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "RES 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x96], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 0b11111011
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0x9E: // RES 3,(IX+$d) - DD CB d 9E - Resets bit 3 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "RES 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x9E], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 0b11110111
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0xA6: // RES 4,(IX+$d) - DD CB d A6 - Resets bit 4 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "RES 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xA6], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 0b11101111
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0xAE: // RES 5,(IX+$d) - DD CB d AE - Resets bit 5 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "RES 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xAE], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 0b11011111
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0xB6: // RES 6,(IX+$d) - DD CB d B6 - Resets bit 6 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "RES 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xB6], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 0b10111111
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0xBE: // RES 7,(IX+$d) - DD CB d BE - Resets bit 7 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "RES 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xBE], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) & 0b01111111
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0xC6: // SET 0,(IX+$d) - DD CB d C6 - Sets bit 0 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "SET 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xC6], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) | 0b00000001
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0xCE: // SET 1,(IX+$d) - DD CB d CE - Sets bit 1 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "SET 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xCE], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) | 0b00000010
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0xD6: // SET 2,(IX+$d) - DD CB d D6 - Sets bit 2 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "SET 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xD6], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) | 0b00000100
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0xDE: // SET 3,(IX+$d) - DD CB d DE - Sets bit 3 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "SET 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xDE], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) | 0b00001000
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0xE6: // SET 4,(IX+$d) - DD CB d E6 - Sets bit 4 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "SET 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xE6], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) | 0b00010000
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0xEE: // SET 5,(IX+$d) - DD CB d EE - Sets bit 5 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "SET 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xEE], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) | 0b00100000
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0xF6: // SET 6,(IX+$d) - DD CB d F6 - Sets bit 6 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "SET 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xF6], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) | 0b01000000
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        case 0xFE: // SET 7,(IX+$d) - DD CB d FE - Sets bit 7 of the memory location pointed to by IX plus $d
                            logInstructionDetails(instructionDetails: "SET 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xFE], values: [opcode3], programCounter: registers.PC)
                            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                            let tempResult = mmu.readByte(address: tempResultAddress) | 0b10000000
                            mmu.writeByte(address: tempResultAddress, value: tempResult)
                            registers.PC = registers.PC &+ 4
                            tStates = tStates + 23
                            incrementR(opcodeCount:3)
                        default:break
                    } // DB CB opcodes
                case 0xE1: // POP IX - DD E1 - The memory location pointed to by SP is stored into IXL and SP is incremented. The memory location pointed to by SP is stored into IXH and SP is incremented again
                    logInstructionDetails(instructionDetails: "POP IX", opcode: [0xDD,0xE1], programCounter: registers.PC)
                    registers.IXL = mmu.readByte(address: registers.SP)
                    registers.IXH = mmu.readByte(address: registers.SP &+ 1)
                    registers.SP = registers.SP &+ 2
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 14
                    incrementR(opcodeCount:2)
                case 0xE3: // EX (SP),IX - DD E3 - Exchanges (SP) with IXL, and (SP+1) with IXH
                    logInstructionDetails(instructionDetails: "EX (SP),IX", opcode: [0xDD,0xE3], programCounter: registers.PC)
                    let tempSPCL = mmu.readByte(address: registers.SP)
                    let tempSPCH = mmu.readByte(address: registers.SP &+ 1)
                    mmu.writeByte(address: registers.SP, value: UInt8(registers.IX >> 8))
                    mmu.writeByte(address: registers.SP &+ 1, value: UInt8(registers.IX & 0xFF))
                    registers.IX = UInt16(tempSPCH) << 8 | UInt16(tempSPCL)
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 23
                    incrementR(opcodeCount:2)
                case 0xE5: // PUSH IX - DD E5 - SP is decremented and IXH is stored into the memory location pointed to by SP. SP is decremented again and IXL is stored into the memory location pointed to by SP
                    logInstructionDetails(instructionDetails: "PUSH IX", opcode: [0xDD,0xE5], programCounter: registers.PC)
                    registers.SP = registers.SP &- 1
                    mmu.writeByte(address: registers.SP, value: registers.IXH)
                    registers.SP = registers.SP &- 1
                    mmu.writeByte(address: registers.SP, value: registers.IXL)
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 15
                    incrementR(opcodeCount:2)
                case 0xE9: // JP (IX) - DD E9 - Loads the value of IX into PC
                    logInstructionDetails(instructionDetails: "JP (IX)", opcode: [0xDD,0xE9], programCounter: registers.PC)
                    registers.PC = registers.IX
                    tStates = tStates + 8
                    incrementR(opcodeCount:2)
                case 0xF9: // LD SP,IX - DD F9 - Loads the value of IX into SP
                    logInstructionDetails(instructionDetails: "SP,IX", opcode: [0xDD,0xF9], programCounter: registers.PC)
                    registers.SP = registers.IX
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 10
                    incrementR(opcodeCount:2)
                default: break
            }
        case 0xDF: // RST 0x18 - DF - The current PC value plus one is pushed onto the stack, then is loaded with 0x18
            logInstructionDetails(instructionDetails: "RST 0x18", opcode: [0xC7], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0018
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xE0: // RET PO - E0 - If the parity/overflow flag is unset, the top stack entry is popped into PC
            logInstructionDetails(instructionDetails: "RET PO", opcode: [0xE0], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.ParityOverflow))
            {
                registers.PC = registers.PC &+ 1
                tStates = tStates + 5
            }
            else
            {
                registers.PCL = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                tStates = tStates + 11
            }
            incrementR(opcodeCount:1)
        case 0xE1: // POP HL - E1 - The memory location pointed to by SP is stored into L and SP is incremented. The memory location pointed to by SP is stored into H and SP is incremented again
            logInstructionDetails(instructionDetails: "POP HL", opcode: [0xE1], programCounter: registers.PC)
            registers.L = mmu.readByte(address: registers.SP)
            registers.H = mmu.readByte(address: registers.SP &+ 1)
            registers.SP = registers.SP &+ 2
            registers.PC = registers.PC &+ 1
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xE2: // JP PO,nn - E1 n n - If the parity/overflow flag is unset, $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP PO,$nn", opcode: [0xE2], values: [opcode2,opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.ParityOverflow))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xE3: // EX (SP),HL - E3 - Exchanges (SP) with L, and (SP+1) with H
            logInstructionDetails(instructionDetails: "EX (SP),HL", opcode: [0xE3], programCounter: registers.PC)
            let tempResultH = registers.H
            let tempResultL = registers.L
            registers.L = mmu.readByte(address: registers.SP)
            registers.H = mmu.readByte(address: registers.SP &+ 1)
            mmu.writeByte(address: registers.SP, value: tempResultL)
            mmu.writeByte(address: registers.SP &+ 1, value: tempResultH)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 19
            incrementR(opcodeCount:1)
        case 0xE4: // CALL PO,$nn - D4 n n - If the parity/overflow flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn
            logInstructionDetails(instructionDetails: "CALL PO,$nn",opcode: [0xE4], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.ParityOverflow))
            {
                tStates = tStates + 10
            }
            else
            {
                registers.PC = registers.PC &+ 3
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCH)
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCL)
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
                tStates = tStates + 17
            }
            incrementR(opcodeCount:1)
        case 0xE5: // PUSH HL - D5 - SP is decremented and H is stored into the memory location pointed to by SP. SP is decremented again and L is stored into the memory location pointed to by SP
            logInstructionDetails(instructionDetails: "PUSH HL", opcode: [0xE5], programCounter: registers.PC)
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: registers.H)
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: registers.L)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xE6: // AND n - E6 n - Bitwise AND on A with $n
            logInstructionDetails(instructionDetails: "AND $n", opcode: [0xE6], values: [opcode2], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & opcode2)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xE7: // RST 0x20 - E7 - The current PC value plus one is pushed onto the stack, then is loaded with 0x20
            logInstructionDetails(instructionDetails: "RST 0x20", opcode: [0xE7], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0020
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xE8: // RET PO - E8 - If the parity/overflow flag is unset, the top stack entry is popped into PC
            logInstructionDetails(instructionDetails: "RET PE", opcode: [0xE8], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.ParityOverflow))
            {
                registers.PCL = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                tStates = tStates + 11
            }
            else
            {
                registers.PC = registers.PC &+ 1
                tStates = tStates + 5
            }
            incrementR(opcodeCount:1)
        case 0xE9: // JP (HL) - E9 - Loads the value of HL into PC
            logInstructionDetails(instructionDetails: "JP (HL)", opcode: [0xE9], programCounter: registers.PC)
            registers.PC = registers.HL
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xEA: // JP PE,nn - EA n n - If the parity/overflow flag is set, $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP PE,$nn", opcode: [0xEA], values: [opcode2,opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.ParityOverflow))
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xEB: // EX DE,HL - EB - Exchanges the 16-bit contents of DE and HL
            logInstructionDetails(instructionDetails: "EX DE,HL", opcode: [0xEB], programCounter: registers.PC)
            (registers.DE,registers.HL) = (registers.HL,registers.DE)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xEC: // CALL PE,$nn - EC n n - If the parity/overflow flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn
            logInstructionDetails(instructionDetails: "CALL PE,$nn",opcode: [0xEC], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.ParityOverflow))
            {
                registers.PC = registers.PC &+ 3
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCH)
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCL)
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
                tStates = tStates + 1
            }
            else
            {
                tStates = tStates + 10
            }
            incrementR(opcodeCount:1)
        case 0xED: // ED instructions
            switch opcode2
            {
            case 0x41: // OUT (C),B - ED 41 - The value of B is written to port C
                ports[Int(registers.C)] = registers.B
                switch registers.B
                {
                case 0x08:
                    if testBit(value: registers.B, bitPosition: 1)
                    {
                       crtc.registers.redBackgroundIntensity = 1  // set global background red intensity to 1 = full
                    }
                    if !testBit(value: registers.B, bitPosition: 1)
                    {
                        crtc.registers.redBackgroundIntensity = 0 // set global background red intensity to 0 = half
                    }
                    if testBit(value: registers.B, bitPosition: 2)
                    {
                        crtc.registers.greenBackgroundIntensity = 1 // set global background blue intensity to 1 = full
                    }
                    if !testBit(value: registers.B, bitPosition: 2)
                    {
                        crtc.registers.greenBackgroundIntensity = 0 // set global background blue intensity to 0 = half
                    }
                    if testBit(value: registers.B, bitPosition: 3)
                    {
                        crtc.registers.blueBackgroundIntensity = 1 // set global background green intensity to 1 = full
                    }
                    if !testBit(value: registers.B, bitPosition: 3)
                    {
                        crtc.registers.blueBackgroundIntensity = 0 // set global background green intensity to 0 = half
                    }
                    if testBit(value: registers.B, bitPosition: 6)
                    {
                        mmu.map(readDevice: colourRAM, writeDevice: colourRAM, memoryLocation: 0xF800)  // swap in colour ram
                    }
                    if !testBit(value: registers.B, bitPosition: 6)
                    {
                        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)        // swap in pcg ram
                    }
                case 0x0A: break //PAK N selection - need some mechanism to map PAK number to memory device
                case 0x0B:
                    if registers.B == 1
                    {
                        mmu.map(readDevice: fontROM, writeDevice: nil, memoryLocation: 0xF000)     // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                    }
                    if registers.B == 0
                    {
                        mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)  // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)  // swap video ram and pcg ram back into memory at 0xf000 for read and wrtie
                    }
                case 0x0C: break // writing to port 0x0C needs no further processing
                case 0x0D: crtc.writeRegister(RegNum:ports[0x0C], RegValue:ports[0x0D])
                default: break // other ports go here
                }
                logInstructionDetails(instructionDetails: "OUT (C),B", opcode: [0xED,0x41], programCounter: registers.PC)
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x43: // LD ($nn),BC - ED 43 n n - Stores BC into the memory location pointed to by $nn
                logInstructionDetails(instructionDetails: "LD ($nn),BC", opcode: [0xED,0x43], values: [opcode3, opcode4], programCounter: registers.PC)
                let tempResult = UInt16(opcode4) << 8 | UInt16(opcode3)
                mmu.writeByte(address: tempResult, value: UInt8(registers.BC & 0x00FF))
                mmu.writeByte(address: tempResult &+ 1, value: UInt8(registers.BC >> 8))
                registers.PC = registers.PC &+ 4
                tStates = tStates + 20
                incrementR(opcodeCount:2)
            case 0x45: // RETN - ED 45 - Used at the end of a non-maskable interrupt service routine (located at 0066h) to pop the top stack entry into PC. The value of IFF2 is copied to IFF1 so that maskable interrupts are allowed to continue as before. NMIs are not enabled on the TI
                logInstructionDetails(instructionDetails: "RETN", opcode: [0xED,0x45], programCounter: registers.PC)
                registers.IFF1 = registers.IFF2
                registers.PCL = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                tStates = tStates + 14
                incrementR(opcodeCount:2)
            case 0x46: // IM 0 - ED 46 - Sets interrupt mode 0
                logInstructionDetails(instructionDetails: "IM 0", opcode: [0xED,0x46], programCounter: registers.PC)
                registers.IM = 0
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x47: // LD I,A - ED 47 - Stores the value of A into register I
                logInstructionDetails(instructionDetails: "LD I,A", opcode: [0xED,0x47], programCounter: registers.PC)
                registers.I = registers.A
                registers.PC = registers.PC &+ 2
                tStates = tStates + 9
                incrementR(opcodeCount:2)
            case 0x49: // OUT (C),C - ED 49 - The value of C is written to port C
                ports[Int(registers.C)] = registers.C
                switch registers.C
                {
                case 0x08:
                    if testBit(value: registers.C, bitPosition: 1)
                    {
                       crtc.registers.redBackgroundIntensity = 1  // set global background red intensity to 1 = full
                    }
                    if !testBit(value: registers.C, bitPosition: 1)
                    {
                        crtc.registers.redBackgroundIntensity = 0 // set global background red intensity to 0 = half
                    }
                    if testBit(value: registers.C, bitPosition: 2)
                    {
                        crtc.registers.greenBackgroundIntensity = 1 // set global background blue intensity to 1 = full
                    }
                    if !testBit(value: registers.C, bitPosition: 2)
                    {
                        crtc.registers.greenBackgroundIntensity = 0 // set global background blue intensity to 0 = half
                    }
                    if testBit(value: registers.C, bitPosition: 3)
                    {
                        crtc.registers.blueBackgroundIntensity = 1 // set global background green intensity to 1 = full
                    }
                    if !testBit(value: registers.C, bitPosition: 3)
                    {
                        crtc.registers.blueBackgroundIntensity = 0 // set global background green intensity to 0 = half
                    }
                    if testBit(value: registers.C, bitPosition: 6)
                    {
                        mmu.map(readDevice: colourRAM, writeDevice: colourRAM, memoryLocation: 0xF800)  // swap in colour ram
                    }
                    if !testBit(value: registers.C, bitPosition: 6)
                    {
                        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)        // swap in pcg ram
                    }
                case 0x0A: break //PAK N selection - need some mechanism to map PAK number to memory device
                case 0x0B:
                    if registers.C == 1
                    {
                        mmu.map(readDevice: fontROM, writeDevice: nil, memoryLocation: 0xF000)     // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                    }
                    if registers.C == 0
                    {
                        mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)  // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)  // swap video ram and pcg ram back into memory at 0xf000 for read and wrtie
                    }
                case 0x0C: break // writing to port 0x0C needs no further processing
                case 0x0D: crtc.writeRegister(RegNum:ports[0x0C], RegValue:ports[0x0D])
                default: break // other ports go here
                }
                logInstructionDetails(instructionDetails: "OUT (C),C", opcode: [0xED,0x49], programCounter: registers.PC)
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x4B: // LD BC,($nn) - ED 4B n n - Loads the value pointed to by $nn into BC
                logInstructionDetails(instructionDetails: "LD BC,($nn)", opcode: [0xED,0x4B], values: [opcode3,opcode4], programCounter: registers.PC)
                let tempResult = UInt16(opcode4) << 8 | UInt16(opcode3)
                registers.C = mmu.readByte(address: tempResult)
                registers.B = mmu.readByte(address: tempResult &+ 1)
                registers.PC = registers.PC &+ 4
                tStates = tStates + 20
                incrementR(opcodeCount:2)
            case 0x4D: // RETI - ED 4D - Used at the end of a maskable interrupt service routine. The top stack entry is popped into PC, and signals an I/O device that the interrupt has finished, allowing nested interrupts (not a consideration on the TI)
                logInstructionDetails(instructionDetails: "RETI", opcode: [0xED,0x4D], programCounter: registers.PC)
                registers.PCL = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                tStates = tStates + 14
                incrementR(opcodeCount:2)
            case 0x4F: // LD R,A - ED 4F - Stores the value of A into register R
                logInstructionDetails(instructionDetails: "LD R,A", opcode: [0xED,0x4F], programCounter: registers.PC)
                registers.R = registers.A
                registers.PC = registers.PC &+ 2
                tStates = tStates + 9
                incrementR(opcodeCount:2)
            case 0x51: // OUT (C),D - ED 51 - The value of D is written to port C
                ports[Int(registers.C)] = registers.D
                switch registers.D
                {
                case 0x08:
                    if testBit(value: registers.D, bitPosition: 1)
                    {
                       crtc.registers.redBackgroundIntensity = 1  // set global background red intensity to 1 = full
                    }
                    if !testBit(value: registers.D, bitPosition: 1)
                    {
                        crtc.registers.redBackgroundIntensity = 0 // set global background red intensity to 0 = half
                    }
                    if testBit(value: registers.D, bitPosition: 2)
                    {
                        crtc.registers.greenBackgroundIntensity = 1 // set global background blue intensity to 1 = full
                    }
                    if !testBit(value: registers.D, bitPosition: 2)
                    {
                        crtc.registers.greenBackgroundIntensity = 0 // set global background blue intensity to 0 = half
                    }
                    if testBit(value: registers.D, bitPosition: 3)
                    {
                        crtc.registers.blueBackgroundIntensity = 1 // set global background green intensity to 1 = full
                    }
                    if !testBit(value: registers.D, bitPosition: 3)
                    {
                        crtc.registers.blueBackgroundIntensity = 0 // set global background green intensity to 0 = half
                    }
                    if testBit(value: registers.D, bitPosition: 6)
                    {
                        mmu.map(readDevice: colourRAM, writeDevice: colourRAM, memoryLocation: 0xF800)  // swap in colour ram
                    }
                    if !testBit(value: registers.D, bitPosition: 6)
                    {
                        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)        // swap in pcg ram
                    }
                case 0x0A: break //PAK N selection - need some mechanism to map PAK number to memory device
                case 0x0B:
                    if registers.D == 1
                    {
                        mmu.map(readDevice: fontROM, writeDevice: nil, memoryLocation: 0xF000)     // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                    }
                    if registers.D == 0
                    {
                        mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)  // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)  // swap video ram and pcg ram back into memory at 0xf000 for read and wrtie
                    }
                case 0x0C: break // writing to port 0x0C needs no further processing
                case 0x0D: crtc.writeRegister(RegNum:ports[0x0C], RegValue:ports[0x0D])
                default: break // other ports go here
                }
                logInstructionDetails(instructionDetails: "OUT (C),D", opcode: [0xED,0x51], programCounter: registers.PC)
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x53: // LD ($nn),DE - ED 53 n n - Stores DE into the memory location pointed to by $nn
                logInstructionDetails(instructionDetails: "LD ($nn),DE", opcode: [0xED,0x53], values: [opcode3,opcode4], programCounter: registers.PC)
                let tempResult = UInt16(opcode4 << 8) | UInt16(opcode3)
                mmu.writeByte(address: tempResult, value: registers.E)
                mmu.writeByte(address: tempResult &+ 1, value: registers.D)
                registers.PC = registers.PC &+ 4
                tStates = tStates + 20
                incrementR(opcodeCount:2)
            case 0x56: // IM 1 - ED 56 - Sets interrupt mode 1
                logInstructionDetails(instructionDetails: "IM 1", opcode: [0xED,0x56], programCounter: registers.PC)
                registers.I = 1
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x59: // OUT (C),E - ED 59 - The value of E is written to port C
                ports[Int(registers.C)] = registers.E
                switch registers.E
                {
                case 0x08:
                    if testBit(value: registers.E, bitPosition: 1)
                    {
                       crtc.registers.redBackgroundIntensity = 1  // set global background red intensity to 1 = full
                    }
                    if !testBit(value: registers.E, bitPosition: 1)
                    {
                        crtc.registers.redBackgroundIntensity = 0 // set global background red intensity to 0 = half
                    }
                    if testBit(value: registers.E, bitPosition: 2)
                    {
                        crtc.registers.greenBackgroundIntensity = 1 // set global background blue intensity to 1 = full
                    }
                    if !testBit(value: registers.E, bitPosition: 2)
                    {
                        crtc.registers.greenBackgroundIntensity = 0 // set global background blue intensity to 0 = half
                    }
                    if testBit(value: registers.E, bitPosition: 3)
                    {
                        crtc.registers.blueBackgroundIntensity = 1 // set global background green intensity to 1 = full
                    }
                    if !testBit(value: registers.E, bitPosition: 3)
                    {
                        crtc.registers.blueBackgroundIntensity = 0 // set global background green intensity to 0 = half
                    }
                    if testBit(value: registers.E, bitPosition: 6)
                    {
                        mmu.map(readDevice: colourRAM, writeDevice: colourRAM, memoryLocation: 0xF800)  // swap in colour ram
                    }
                    if !testBit(value: registers.E, bitPosition: 6)
                    {
                        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)        // swap in pcg ram
                    }
                case 0x0A: break //PAK N selection - need some mechanism to map PAK number to memory device
                case 0x0B:
                    if registers.E == 1
                    {
                        mmu.map(readDevice: fontROM, writeDevice: nil, memoryLocation: 0xF000)     // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                    }
                    if registers.E == 0
                    {
                        mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)  // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)  // swap video ram and pcg ram back into memory at 0xf000 for read and wrtie
                    }
                case 0x0C: break // writing to port 0x0C needs no further processing
                case 0x0D: crtc.writeRegister(RegNum:ports[0x0C], RegValue:ports[0x0D])
                default: break // other ports go here
                }
                logInstructionDetails(instructionDetails: "OUT (C),E", opcode: [0xED,0x59], programCounter: registers.PC)
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x5B: // LD DE,($nn) - ED 5B n n - Loads the value pointed to by $nn into DE
                logInstructionDetails(instructionDetails: "LD DE,($nn)", opcode: [0xED,0x5B], values: [opcode3,opcode4], programCounter: registers.PC)
                let tempResult = UInt16(opcode4) << 8 | UInt16(opcode3)
                registers.E = mmu.readByte(address: tempResult)
                registers.D = mmu.readByte(address: tempResult &+ 1)
                registers.PC = registers.PC &+ 4
                tStates = tStates + 20
                incrementR(opcodeCount:2)
            case 0x5E: // IM 2 - ED 5E - Sets interrupt mode 2
                logInstructionDetails(instructionDetails: "IM 2", opcode: [0xED,0x5E], programCounter: registers.PC)
                registers.I = 2
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
                incrementR(opcodeCount:2)
            case 0x61: // OUT (C),H - ED 61 - The value of H is written to port C
                ports[Int(registers.C)] = registers.H
                switch registers.H
                {
                case 0x08:
                    if testBit(value: registers.H, bitPosition: 1)
                    {
                       crtc.registers.redBackgroundIntensity = 1  // set global background red intensity to 1 = full
                    }
                    if !testBit(value: registers.H, bitPosition: 1)
                    {
                        crtc.registers.redBackgroundIntensity = 0 // set global background red intensity to 0 = half
                    }
                    if testBit(value: registers.H, bitPosition: 2)
                    {
                        crtc.registers.greenBackgroundIntensity = 1 // set global background blue intensity to 1 = full
                    }
                    if !testBit(value: registers.H, bitPosition: 2)
                    {
                        crtc.registers.greenBackgroundIntensity = 0 // set global background blue intensity to 0 = half
                    }
                    if testBit(value: registers.H, bitPosition: 3)
                    {
                        crtc.registers.blueBackgroundIntensity = 1 // set global background green intensity to 1 = full
                    }
                    if !testBit(value: registers.H, bitPosition: 3)
                    {
                        crtc.registers.blueBackgroundIntensity = 0 // set global background green intensity to 0 = half
                    }
                    if testBit(value: registers.H, bitPosition: 6)
                    {
                        mmu.map(readDevice: colourRAM, writeDevice: colourRAM, memoryLocation: 0xF800)  // swap in colour ram
                    }
                    if !testBit(value: registers.H, bitPosition: 6)
                    {
                        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)        // swap in pcg ram
                    }
                case 0x0A: break //PAK N selection - need some mechanism to map PAK number to memory device
                case 0x0B:
                    if registers.H == 1
                    {
                        mmu.map(readDevice: fontROM, writeDevice: nil, memoryLocation: 0xF000)     // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                    }
                    if registers.H == 0
                    {
                        mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)  // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)  // swap video ram and pcg ram back into memory at 0xf000 for read and wrtie
                    }
                case 0x0C: break // writing to port 0x0C needs no further processing
                case 0x0D: crtc.writeRegister(RegNum:ports[0x0C], RegValue:ports[0x0D])
                default: break // other ports go here
                }
                logInstructionDetails(instructionDetails: "OUT (C),H", opcode: [0xED,0x61], programCounter: registers.PC)
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x69: // OUT (C),L - ED 69 - The value of L is written to port C
                ports[Int(registers.C)] = registers.L
                switch registers.L
                {
                case 0x08:
                    if testBit(value: registers.L, bitPosition: 1)
                    {
                       crtc.registers.redBackgroundIntensity = 1  // set global background red intensity to 1 = full
                    }
                    if !testBit(value: registers.L, bitPosition: 1)
                    {
                        crtc.registers.redBackgroundIntensity = 0 // set global background red intensity to 0 = half
                    }
                    if testBit(value: registers.L, bitPosition: 2)
                    {
                        crtc.registers.greenBackgroundIntensity = 1 // set global background blue intensity to 1 = full
                    }
                    if !testBit(value: registers.L, bitPosition: 2)
                    {
                        crtc.registers.greenBackgroundIntensity = 0 // set global background blue intensity to 0 = half
                    }
                    if testBit(value: registers.L, bitPosition: 3)
                    {
                        crtc.registers.blueBackgroundIntensity = 1 // set global background green intensity to 1 = full
                    }
                    if !testBit(value: registers.L, bitPosition: 3)
                    {
                        crtc.registers.blueBackgroundIntensity = 0 // set global background green intensity to 0 = half
                    }
                    if testBit(value: registers.L, bitPosition: 6)
                    {
                        mmu.map(readDevice: colourRAM, writeDevice: colourRAM, memoryLocation: 0xF800)  // swap in colour ram
                    }
                    if !testBit(value: registers.L, bitPosition: 6)
                    {
                        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)        // swap in pcg ram
                    }
                case 0x0A: break //PAK N selection - need some mechanism to map PAK number to memory device
                case 0x0B:
                    if registers.L == 1
                    {
                        mmu.map(readDevice: fontROM, writeDevice: nil, memoryLocation: 0xF000)     // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                    }
                    if registers.L == 0
                    {
                        mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)  // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)  // swap video ram and pcg ram back into memory at 0xf000 for read and wrtie
                    }
                case 0x0C: break // writing to port 0x0C needs no further processing
                case 0x0D: crtc.writeRegister(RegNum:ports[0x0C], RegValue:ports[0x0D])
                default: break // other ports go here
                }
                logInstructionDetails(instructionDetails: "OUT (C),L", opcode: [0xED,0x69], programCounter: registers.PC)
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x73: // LD ($nn),SP - ED 73 n n - Stores SP into the memory location pointed to by $nn
                logInstructionDetails(instructionDetails: "LD ($nn),SP", opcode: [0xED,0x73], values: [opcode3,opcode4], programCounter: registers.PC)
                let tempResultAddress = UInt16(opcode4) << 8 | UInt16(opcode3)
                mmu.writeByte(address: tempResultAddress, value: registers.SPL)
                mmu.writeByte(address: tempResultAddress &+ 1, value: registers.SPH)
                registers.PC = registers.PC &+ 4
                tStates = tStates + 20
                incrementR(opcodeCount:2)
            case 0x79: // OUT (C),A - ED 79 - The value of A is written to port C
                ports[Int(registers.C)] = registers.A
                switch registers.A
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
                        mmu.map(readDevice: fontROM, writeDevice: nil, memoryLocation: 0xF000)     // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
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
                logInstructionDetails(instructionDetails: "OUT (C),A", opcode: [0xED,0x79], programCounter: registers.PC)
                registers.PC = registers.PC &+ 2
                tStates = tStates + 12
                incrementR(opcodeCount:2)
            case 0x7B: // LD SP,($nn) - ED 7B n n - Loads the value pointed to by $nn into SP
                logInstructionDetails(instructionDetails: "LD SP,($nn)", opcode: [0xED,0x7B], values: [opcode3,opcode4], programCounter: registers.PC)
                let tempResultAddress = UInt16(opcode4) << 8 | UInt16(opcode3)
                registers.SP = UInt16(mmu.readByte(address: tempResultAddress &+ 1)) << 8 | UInt16(mmu.readByte(address: tempResultAddress))
                registers.PC = registers.PC &+ 4
                tStates = tStates + 20
                incrementR(opcodeCount:2)
            case 0xB0: // LDIR
                repeat
                {
                    mmu.writeByte(address: registers.DE, value : mmu.readByte(address: registers.HL))
                    registers.HL = registers.HL &+ 1
                    registers.DE = registers.DE &+ 1
                    registers.BC = registers.BC &- 1
                }
                while registers.BC != 0
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:z80Flags.HalfCarry,SetFlag:false)
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:z80Flags.Negative,SetFlag:false)
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:z80Flags.ParityOverflow,SetFlag:registers.BC == 0)
                logInstructionDetails(instructionDetails: "LDIR", opcode: [0xED,0xB0], programCounter: registers.PC)
                // myz80Queue.addToQueue(address: registers.PC, opCodes: [0xED,0xB0])
                registers.PC = registers.PC &+ 2
                tStates = tStates + 21
                incrementR(opcodeCount:2)
            case 0xB3: // OTIR - ED B3 - B is decremented. A byte from the memory location pointed to by HL is written to port C. Then HL is incremented. If B is not zero, this operation is repeated. Interrupts can trigger while this instruction is processing
                logInstructionDetails(instructionDetails: "OTIR", opcode: [0xED,0xB3], programCounter: registers.PC)
                let preserveB = registers.B
                repeat
                {
                    ports[Int(registers.C)] = mmu.readByte(address: registers.HL)
                    registers.HL = registers.HL &+ 1
                    registers.B = registers.B &- 1
                }
                while registers.B != 0
                registers.F = registers.F | z80Flags.Zero.rawValue
                registers.F = registers.F | z80Flags.Negative.rawValue
                registers.PC = registers.PC &+ 2
                if preserveB == 0
                {
                    tStates = tStates + 16
                }
                else
                {
                    tStates = tStates + 21
                }
                incrementR(opcodeCount:2)
            default:
                logInstructionDetails(opcode: [0xED,opcode2], programCounter: registers.PC)
                registers.PC = registers.PC &+ 2
                tStates = tStates + 21  // confirm this behaviour
                incrementR(opcodeCount:2) // confirm this behaviour for ED codes
            } // ED
        case 0xEE: // XOR n - EE n - Bitwise XOR on A with $n
            logInstructionDetails(instructionDetails: "XOR $n", opcode: [0xEE], values: [opcode2], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ opcode2)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xEF: // RST 0x28 - EF - The current PC value plus one is pushed onto the stack, then is loaded with 0x28
            logInstructionDetails(instructionDetails: "RST 0x28", opcode: [0xEF], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0028
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xF0: // RET P - F0 - If the sign flag is unset, the top stack entry is popped into PC
            logInstructionDetails(instructionDetails: "RET P", opcode: [0xF0], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Sign))
            {
                registers.PC = registers.PC &+ 1
                tStates = tStates + 5
            }
            else
            {
                registers.PCL = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                tStates = tStates + 11
            }
            incrementR(opcodeCount:1)
        case 0xF1: // POP AF - F1 - The memory location pointed to by SP is stored into F and SP is incremented. The memory location pointed to by SP is stored into A and SP is incremented again
            logInstructionDetails(instructionDetails: "POP AF", opcode: [0xF1], programCounter: registers.PC)
            registers.F = mmu.readByte(address: registers.SP)
            registers.A = mmu.readByte(address: registers.SP &+ 1)
            registers.SP = registers.SP &+ 2
            registers.PC = registers.PC &+ 1
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xF2: // JP P,nn - F2 n n - If the sign flag is unset, $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP P,$nn", opcode: [0xF2], values: [opcode2,opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Sign))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xF3: // DI - F3 - Resets both interrupt flip-flops, thus preventing maskable interrupts from triggering
            logInstructionDetails(instructionDetails: "DI", opcode: [0xF3], programCounter: registers.PC)
            registers.IFF1 = false
            registers.IFF2 = false
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xF4: // CALL P,$nn - F4 n n - If the sign flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn.
            logInstructionDetails(instructionDetails: "CALL P,$nn",opcode: [0xF4], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Sign))
            {
                tStates = tStates + 10
            }
            else
            {
                registers.PC = registers.PC &+ 3
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCH)
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCL)
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
                tStates = tStates + 17
            }
            incrementR(opcodeCount:1)
        case 0xF5: // PUSH AF - F5 - SP is decremented and A is stored into the memory location pointed to by SP. SP is decremented again and F is stored into the memory location pointed to by SP
            logInstructionDetails(instructionDetails: "PUSH AF", opcode: [0xF5], programCounter: registers.PC)
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: registers.A)
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: registers.F)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xF6: // OR n - F6 n - Bitwise OR on A with $n
            logInstructionDetails(instructionDetails: "OR $n", opcode: [0xF6], values: [opcode2], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | opcode2)
            registers.PC = registers.PC &+ 1
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xF7: // RST 0x30 - F7 - The current PC value plus one is pushed onto the stack, then is loaded with 0x30
            logInstructionDetails(instructionDetails: "RST 0x30", opcode: [0xF7], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0030
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xF8: // RET M - F0 - If the sign flag is set, the top stack entry is popped into PC
            logInstructionDetails(instructionDetails: "RET M", opcode: [0xF8], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Sign))
            {
                registers.PCL = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = mmu.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                tStates = tStates + 11
            }
            else
            {
                registers.PC = registers.PC &+ 1
                tStates = tStates + 5
            }
            incrementR(opcodeCount:1)
        case 0xF9: // LD SP,HL - F9 - Loads the value of HL into SP
            logInstructionDetails(instructionDetails: "LD SP,HL", opcode: [0xF9], programCounter: registers.PC)
            registers.SP = registers.HL
            registers.PC = registers.PC &+ 1
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0xFA: // JP M,nn
            logInstructionDetails(instructionDetails: "JP M,$nn", opcode: [0xFA], values: [opcode2,opcode3], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Sign))
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xFB: // EI- FB - Sets both interrupt flip-flops, thus allowing maskable interrupts to occur. An interrupt will not occur until after the immediately following instruction
            logInstructionDetails(instructionDetails: "EI", opcode: [0xFB], programCounter: registers.PC)
            registers.IFF1 = true
            registers.IFF2 = true
            registers.PC = registers.PC &+ 1
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xFC: // CALL M,$nn - FC n n - If the sign flag is set, the current PC value plus three is pushed onto the stack, then is loaded with $nn
            logInstructionDetails(instructionDetails: "CALL M,$nn",opcode: [0xFC], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Sign))
            {
                registers.PC = registers.PC &+ 3
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCH)
                registers.SP = registers.SP &- 1
                mmu.writeByte(address: registers.SP, value: registers.PCL)
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
                tStates = tStates + 17
            }
            else
            {
                tStates = tStates + 10
            }
            incrementR(opcodeCount:1)
        case 0xFD: // FD and FDCB opcodes
            switch opcode2
            {
                case 0x09: // ADD IY,BC - FD 09 - The value of BC is added to IY
                    logInstructionDetails(instructionDetails: "ADD IY,BC", opcode: [0xDD,0x09], programCounter: registers.PC)
                    let tempResult = registers.IY &+ registers.BC
                    let halfCarry = UInt8((registers.IY ^ registers.BC ^ tempResult) & 0x1000)
                    let carrytempResult = UInt32(registers.IY) + UInt32(registers.BC)
                    let carry = UInt8((carrytempResult & 0x10000) >> 16)
                    registers.IY = tempResult
                    registers.F = registers.F & ~z80Flags.Negative.rawValue
                    registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
                    registers.F = registers.F | halfCarry
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 15
                    incrementR(opcodeCount:2)
                case 0x19: // ADD IY,DE - FD 19 - The value of DE is added to IY
                    logInstructionDetails(instructionDetails: "ADD IY,DE", opcode: [0xDD,0x19], programCounter: registers.PC)
                    let tempResult = registers.IY &+ registers.DE
                    let halfCarry = UInt8((registers.IY ^ registers.DE ^ tempResult) & 0x1000)
                    let carrytempResult = UInt32(registers.IY) + UInt32(registers.DE)
                    let carry = UInt8((carrytempResult & 0x10000) >> 16)
                    registers.IY = tempResult
                    registers.F = registers.F & ~z80Flags.Negative.rawValue
                    registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
                    registers.F = registers.F | halfCarry
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 15
                    incrementR(opcodeCount:2)
                case 0x21: // LD IY,$nn - FD 21 n n - Loads $nn into register IY
                    logInstructionDetails(instructionDetails: "LD IY,$nn", opcode: [0xFD,0x21], values: [opcode3,opcode4], programCounter: registers.PC)
                    registers.IY = UInt16(opcode4) << 8 | UInt16(opcode3)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 14
                    incrementR(opcodeCount:2)
                case 0x22: // LD ($nn),IY - FD 22 n n - Stores IY into the memory location pointed to by $nn
                    logInstructionDetails(instructionDetails: "LD ($nn),IY", opcode: [0xFD,0x22], values: [opcode3,opcode4], programCounter: registers.PC)
                    let tempResult =  UInt16(opcode4) << 8 | UInt16(opcode3)
                    mmu.writeByte(address: tempResult, value: UInt8(registers.IY & 0x00FF))
                    mmu.writeByte(address: tempResult &+ 1, value: UInt8(registers.IY >> 8))
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 20
                    incrementR(opcodeCount:2)
                case 0x23: // INC IY - FD 23 - Adds one to IY
                    logInstructionDetails(instructionDetails: "INC IY", opcode: [0xFD,0x23], programCounter: registers.PC)
                    registers.PC = registers.IY &+ 1
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 10
                    incrementR(opcodeCount:2)
                case 0x29: // ADD IY,IY - FD 29 - The value of IY is added to IY
                    logInstructionDetails(instructionDetails: "ADD IY,IY", opcode: [0xDD,0x29], programCounter: registers.PC)
                    let tempResult = registers.IY &+ registers.IY
                    let halfCarry = UInt8((registers.IY ^ registers.IY ^ tempResult) & 0x1000)
                    let carrytempResult = UInt32(registers.IY) + UInt32(registers.IY)
                    let carry = UInt8((carrytempResult & 0x10000) >> 16)
                    registers.IY = tempResult
                    registers.F = registers.F & ~z80Flags.Negative.rawValue
                    registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
                    registers.F = registers.F | halfCarry
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 15
                    incrementR(opcodeCount:2)
                case 0x2A: // LD IY,($nn) - FD 2A n n - Loads the value pointed to by $nn into IY
                    logInstructionDetails(instructionDetails: "LD IY,($nn)", opcode: [0xFD,0x2A], values: [opcode3,opcode4], programCounter: registers.PC)
                    let tempResult = UInt16(opcode4) << 8 | UInt16(opcode3)
                    let tempResultIYH = mmu.readByte(address: tempResult)
                    let tempResultIYL = mmu.readByte(address: tempResult &+ 1)
                    registers.IY = UInt16(tempResultIYH << 8) | UInt16(tempResultIYL)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 20
                    incrementR(opcodeCount:2)
                case 0x2B: // DEC IY - FD 2B - Subtracts one from IY
                    logInstructionDetails(instructionDetails: "DEC IY", opcode: [0xFD,0x2B], programCounter: registers.PC)
                    registers.IY = registers.IY &- 1
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 10
                    incrementR(opcodeCount:2)
                case 0x34: // INC (IY+$d) - FD 34 d - Adds one to the memory location pointed to by IY plus $d
                    logInstructionDetails(instructionDetails: "INC (IY+$d)", opcode: [0xFD,0x34], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    var previous = mmu.readByte(address: tempResult)
                    (previous,registers.F) = z80FastFlags.incHelper(operand: previous, currentFlags: registers.F)
                    mmu.writeByte(address: tempResult,value: previous)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 23
                    incrementR(opcodeCount:2)
                case 0x35: // DEC (IY+$d) - FD 35 d - Subtracts one from the memory location pointed to by IY plus $d
                    logInstructionDetails(instructionDetails: "DEC (IY+$d)", opcode: [0xFD,0x35], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    var previous = mmu.readByte(address: tempResult)
                    (previous,registers.F) = z80FastFlags.decHelper(operand: previous, currentFlags: registers.F)
                    mmu.writeByte(address: tempResult,value: previous)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 23
                    incrementR(opcodeCount:2)
                case 0x36: // LD (IY+$d),$n - FD 36 n n - Stores $n to the memory location pointed to by IY plus $d
                    logInstructionDetails(instructionDetails: "LD (IY+$d),$n", opcode: [0xFD,0x36], values: [opcode3,opcode4], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: opcode4)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x39: // ADD IY,SP - FD 39 - The value of SP is added to IY
                    logInstructionDetails(instructionDetails: "ADD IY,SP", opcode: [0xDD,0x39], programCounter: registers.PC)
                    let tempResult = registers.IY &+ registers.SP
                    let halfCarry = UInt8((registers.IY ^ registers.SP ^ tempResult) & 0x1000)
                    let carrytempResult = UInt32(registers.IY) + UInt32(registers.SP)
                    let carry = UInt8((carrytempResult & 0x10000) >> 16)
                    registers.IY = tempResult
                    registers.F = registers.F & ~z80Flags.Negative.rawValue
                    registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
                    registers.F = registers.F | halfCarry
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 15
                    incrementR(opcodeCount:2)
                case 0x46: // LD B,(IY+$d) - FD 46 n n - Loads the value pointed to by IY plus $d into B
                    logInstructionDetails(instructionDetails: "LD B,(IY+$d)", opcode: [0xFD,0x46], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.B = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x4E: // LD C,(IY+$d) - FD 4E n n - Loads the value pointed to by IY plus $d into C
                    logInstructionDetails(instructionDetails: "LD C,(IY+$d)", opcode: [0xFD,0x4E], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.C = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x56: // LD D,(IY+$d) - FD 56 n n - Loads the value pointed to by IY plus $d into D
                    logInstructionDetails(instructionDetails: "LD D,(IY+$d)", opcode: [0xFD,0x46], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.D = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x5E: // LD E,(IY+$d)- FD 5E n n - Loads the value pointed to by IY plus $d into E
                    logInstructionDetails(instructionDetails: "LD E,(IY+$d)", opcode: [0xFD,0x5E], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.E = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x66: // LD H,(IY+$d) - FD 66 n n - Loads the value pointed to by IY plus $d into H
                    logInstructionDetails(instructionDetails: "LD H,(IY+$d)", opcode: [0xFD,0x66], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.H = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x6E: // LD L,(IY+$d) - FD 6E n n - Loads the value pointed to by IY plus $d into L
                    logInstructionDetails(instructionDetails: "LD L,(IY+$d)", opcode: [0xFD,0x6E], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.L = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x70: // LD (IY+$d),B - FD 70 n n - Stores B to the memory location pointed to by IY plus $
                    logInstructionDetails(instructionDetails: "LD (IY+$d),B", opcode: [0xFD,0x70], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.B)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x71: // LD (IY+$d),C - FD 71 n n - Stores C to the memory location pointed to by IY plus $d
                    logInstructionDetails(instructionDetails: "LD (IY+$d),C", opcode: [0xFD,0x71], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.C)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x72: // LD (IY+$d),D - FD 72 n n - Stores D to the memory location pointed to by IY plus $d
                    logInstructionDetails(instructionDetails: "LD (IY+$d),D", opcode: [0xFD,0x72], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.D)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x73: // LD (IY+$d),E - FD 73 n n - Stores E to the memory location pointed to by IY plus $d
                    logInstructionDetails(instructionDetails: "LD (IY+$d),E", opcode: [0xFD,0x73], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.E)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x74: // LD (IY+$d),H - FD 74 n n - Stores H to the memory location pointed to by IY plus $d
                    logInstructionDetails(instructionDetails: "LD (IY+$d),H", opcode: [0xFD,0x74], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.H)
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x75: // LD (IY+$d),L - FD 75 n n - Stores L to the memory location pointed to by IY plus $d
                    logInstructionDetails(instructionDetails: "LD (IY+$d),L", opcode: [0xFD,0x36], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.L)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x77: // LD (IY+$d),A - FD 77 n n - Stores A to the memory location pointed to by IY plus $d
                    logInstructionDetails(instructionDetails: "LD (IY+$d),A", opcode: [0xFD,0x77], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    mmu.writeByte(address: tempResult, value: registers.A)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x7E: // LD A,(IY+$d) - FD 7E n n - Loads the value pointed to by IY plus $d into A
                    logInstructionDetails(instructionDetails: "LD A,(IY+$d)", opcode: [0xFD,0x7E], values: [opcode3], programCounter: registers.PC)
                    let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    registers.A = mmu.readByte(address: tempResult)
                    registers.PC = registers.PC &+ 4
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0x96: // SUB (IY+$d) - FD 96 d - Subtracts the value pointed to by IY plus $d from A
                    logInstructionDetails(instructionDetails: "SUB (IY+$d)", opcode: [0xFD,0x96], values: [opcode2], programCounter: registers.PC)
                    let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: mmu.readByte(address: tempResultAddress))
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0xA6: // AND (IY+$d) - FD A6 d - Bitwise AND on A with the value pointed to by IY plus $d
                    logInstructionDetails(instructionDetails: "AND (IY+$d)", opcode: [0xFD,0xA6], values: [opcode3], programCounter: registers.PC)
                    let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & mmu.readByte(address: tempResultAddress))
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                switch opcode4 // FD CB opcodes
                {
                    case 0x40: // BIT 0,(IY+$d) - FD CB $d 40 - Tests bit 0 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x40], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 1
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x41: // BIT 0,(IY+$d) - FD CB $d 41 - Tests bit 0 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x41], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 1
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x42: // BIT 0,(IY+$d) - FD CB $d 42 - Tests bit 0 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x42], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 1
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x43: // BIT 0,(IY+$d) - FD CB $d 43 - Tests bit 0 of the memory location pointed to by IX plus $d
                        logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x43], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 1
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x44: // BIT 0,(IY+$d) - FD CB $d 44 - Tests bit 0 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x44], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 1
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x45: // BIT 0,(IY+$d) - FD CB $d 45 - Tests bit 0 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x45], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 1
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x46: // BIT 0,(IY+$d) - FD CB $d 46 - Tests bit 0 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x46], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 1
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x47: // BIT 0,(IY+$d) - FD CB $d 47 - Tests bit 0 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x47], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 1
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x48: // BIT 1,(IY+$d) - FD CB $d 48 - Tests bit 1 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x48], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 2
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x49: // BIT 1,(IY+$d) - FD CB $d 49 - Tests bit 1 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x49], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 2
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x4A: // BIT 1,(IY+$d) - FD CB $d 4A - Tests bit 1 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x4A], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 2
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x4B: // BIT 1,(IY+$d) - FD CB $d 4B - Tests bit 1 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x4B], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 2
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x4C: // BIT 1,(IY+$d) - FD CB $d 4C - Tests bit 1 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x4C], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 2
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x4D: // BIT 1,(IY+$d) - FD CB $d 4D - Tests bit 1 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x4D], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 2
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x4E: // BIT 1,(IY+$d) - FD CB $d 4E - Tests bit 1 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x4E], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 2
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x4F: // BIT 1,(IY+$d) - FD CB $d 4F - Tests bit 1 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x4F], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 2
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x50: // BIT 2,(IY+$d) - FD CB $d 50 - Tests bit 2 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x50], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 4
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x51: // BIT 2,(IY+$d) - FD CB $d 51 - Tests bit 2 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x51], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 4
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x52: // BIT 2,(IY+$d) - FD CB $d 52 - Tests bit 2 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x52], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 4
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x53: // BIT 2,(IY+$d) - FD CB $d 53 - Tests bit 2 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x53], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 4
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x54: // BIT 2,(IY+$d) - FD CB $d 54 - Tests bit 2 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x54], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 4
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x55: // BIT 2,(IY+$d) - FD CB $d 55 - Tests bit 2 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x55], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 4
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x56: // BIT 2,(IY+$d) - FD CB $d 56 - Tests bit 2 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x56], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 4
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x57: // BIT 2,(IY+$d) - FD CB $d 57 - Tests bit 2 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x57], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 4
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x58: // BIT 3,(IY+$d) - FD CB $d 58 - Tests bit 3 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x58], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 8
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x59: // BIT 3,(IY+$d) - FD CB $d 59 - Tests bit 3 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x59], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 8
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x5A: // BIT 3,(IY+$d) - FD CB $d 5A - Tests bit 3 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x5A], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 8
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x5B: // BIT 3,(IY+$d) - FD CB $d 5B - Tests bit 3 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x5B], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 8
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x5C: // BIT 3,(IY+$d) - FD CB $d 5C - Tests bit 3 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x5C], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 8
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x5D: // BIT 3,(IY+$d) - FD CB $d 5D - Tests bit 3 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x5D], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 8
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x5E: // BIT 3,(IY+$d) - FD CB $d 5E - Tests bit 3 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x5E], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 8
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x5F: // BIT 3,(IY+$d) - FD CB $d 5F - Tests bit 3 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x5F], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 8
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x60: // BIT 4,(IY+$d) - FD CB $d 60 - Tests bit 4 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x60], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 16
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x61: // BIT 4,(IY+$d) - FD CB $d 61 - Tests bit 4 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x61], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 16
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x62: // BIT 4,(IY+$d) - FD CB $d 62 - Tests bit 4 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x62], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 16
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x63: // BIT 4,(IY+$d) - FD CB $d 63 - Tests bit 4 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x63], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 16
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x64: // BIT 4,(IY+$d) - FD CB $d 64 - Tests bit 4 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x64], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 16
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x65: // BIT 4,(IY+$d) - FD CB $d 65 - Tests bit 4 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x65], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 16
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x66: // BIT 4,(IY+$d) - FD CB $d 66 - Tests bit 4 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x66], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 16
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x67: // BIT 4,(IY+$d) - FD CB $d 67 - Tests bit 4 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x67], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 16
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x68: // BIT 5,(IY+$d) - FD CB $d 68 - Tests bit 5 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x68], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 32
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x69: // BIT 5,(IY+$d) - FD CB $d 69 - Tests bit 5 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x69], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 32
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x6A: // BIT 5,(IY+$d) - FD CB $d 6A - Tests bit 5 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x6A], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 32
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x6B: // BIT 5,(IY+$d) - FD CB $d 6B - Tests bit 5 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x6B], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 32
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x6C: // BIT 5,(IY+$d) - FD CB $d 6C - Tests bit 5 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x6C], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 32
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x6D: // BIT 5,(IY+$d) - FD CB $d 6D - Tests bit 5 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x6D], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 32
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x6E: // BIT 5,(IY+$d) - FD CB $d 6E - Tests bit 5 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x6E], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 32
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x6F: // BIT 5,(IY+$d) - FD CB $d 6F - Tests bit 5 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x6F], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 32
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x70: // BIT 6,(IY+$d) - FD CB $d 70 - Tests bit 6 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x70], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 64
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x71: // BIT 6,(IY+$d) - FD CB $d 71 - Tests bit 6 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x71], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 64
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x72: // BIT 6,(IY+$d) - FD CB $d 72 - Tests bit 6 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x72], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 64
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x73: // BIT 6,(IY+$d) - FD CB $d 73 - Tests bit 6 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x73], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 64
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x74: // BIT 6,(IY+$d) - FD CB $d 74 - Tests bit 6 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x74], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 64
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x75: // BIT 6,(IY+$d) - FD CB $d 75 - Tests bit 6 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x75], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 64
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x76: // BIT 6,(IY+$d) - FD CB $d 76 - Tests bit 6 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x76], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 64
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x77: // BIT 6,(IY+$d) - FD CB $d 77 - Tests bit 6 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x77], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 64
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x78: // BIT 7,(IY+$d) - FD CB $d 78 - Tests bit 7 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x78], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 128
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x79: // BIT 7,(IY+$d) - FD CB $d 79 - Tests bit 7 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x79], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 128
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x7A: // BIT 7,(IY+$d) - FD CB $d 7A - Tests bit 7 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x7A], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 128
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x7B: // BIT 7,(IY+$d) - FD CB $d 7B - Tests bit 7 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x7B], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 128
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x7C: // BIT 7,(IY+$d) - FD CB $d 7C - Tests bit 7 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x7C], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 128
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x7D: // BIT 7,(IY+$d) - FD CB $d 7D - Tests bit 7 of the memory location pointed to by IY plus $d L
                        logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x7D], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 128
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x7E: // BIT 7,(IY+$d) - FD CB $d 7E - Tests bit 7 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x7E], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 128
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x7F: // BIT 7,(IY+$d) - FD CB $d 7F - Tests bit 7 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x7F], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 128
                        registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
                        registers.F = registers.F | z80Flags.HalfCarry.rawValue
                        registers.F = registers.F & ~z80Flags.Negative.rawValue
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 20
                        incrementR(opcodeCount:3)
                    case 0x86: // RES 0,(IY+$d) - FD CB d 86 - Resets bit 0 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "RES 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x86], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 0b11111110
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0x8E: // RES 1,(IY+$d) - FD CB d 8E - Resets bit 1 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "RES 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x8E], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 0b11111101
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0x96: // RES 2,(IX+$d) - FD CB d 96 - Resets bit 2 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "RES 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x96], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 0b11111011
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0x9E: // RES 3,(IX+$d) - FD CB d 9E - Resets bit 3 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "RES 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x9E], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 0b11110111
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0xA6: // RES 4,(IY+$d) - FD CB d A6 - Resets bit 4 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "RES 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xA6], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 0b11101111
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0xAE: // RES 5,(IY+$d) - FD CB d AE - Resets bit 5 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "RES 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xAE], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 0b11011111
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0xB6: // RES 6,(IY+$d) - FD CB d B6 - Resets bit 6 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "RES 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xB6], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 0b10111111
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0xBE: // RES 7,(IY+$d) - FD CB d BE - Resets bit 7 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "RES 7,(IY+$d)", opcode: [0xFD,0xDB,opcode3,0xBE], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) & 0b01111111
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0xC6: // SET 0,(IY+$d) - FD CB d C6 - Sets bit 0 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "SET 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xC6], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) | 0b00000001
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0xCE: // SET 1,(IY+$d) - FD CB d CE - Sets bit 1 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "SET 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xCE], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) | 0b00000010
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0xD6: // SET 2,(IY+$d) - FD CB d D6 - Sets bit 2 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "SET 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xD6], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) | 0b00000100
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0xDE: // SET 3,(IY+$d) - FD CB d DE - Sets bit 3 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "SET 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xDE], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) | 0b00001000
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0xE6: // SET 4,(IY+$d) - FD CB d E6 - Sets bit 4 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "SET 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xE6], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) | 0b00010000
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0xEE: // SET 5,(IY+$d) - FD CB d EE - Sets bit 5 of the memory location pointed to by IX plus $d
                        logInstructionDetails(instructionDetails: "SET 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xEE], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) | 0b00100000
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0xF6: // SET 6,(IY+$d) - FD CB d F6 - Sets bit 6 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "SET 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xF6], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) | 0b01000000
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    case 0xFE: // SET 7,(IY+$d) - FD CB d FE - Sets bit 7 of the memory location pointed to by IY plus $d
                        logInstructionDetails(instructionDetails: "SET 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xFE], values: [opcode3], programCounter: registers.PC)
                        let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                        let tempResult = mmu.readByte(address: tempResultAddress) | 0b10000000
                        mmu.writeByte(address: tempResultAddress, value: tempResult)
                        registers.PC = registers.PC &+ 4
                        tStates = tStates + 23
                        incrementR(opcodeCount:3)
                    default: break
                } // FD CB opcodes
                case 0xAE: // XOR (IY+$d) - FD AE d - Bitwise XOR on A with the value pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "XOR (IY+$d)", opcode: [0xFD,0xAE], values: [opcode3], programCounter: registers.PC)
                    let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ mmu.readByte(address: tempResultAddress))
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0xB6: // OR (IY+$d) - FD B6 d - Bitwise OR on A with the value pointed to by IX plus $d
                    logInstructionDetails(instructionDetails: "OR (IY+$d)", opcode: [0xDD,0xB6], values: [opcode3], programCounter: registers.PC)
                    let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | mmu.readByte(address: tempResultAddress))
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0xBE: // CP (IY+$d) - FD BE d - Subtracts the value pointed to by IY plus $d from A and affects flags according to the result. A is not modified
                    logInstructionDetails(instructionDetails: "CP (IY+$d)", opcode: [0xFD,0xBE], values: [opcode3], programCounter: registers.PC)
                    let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
                    let tempResult = mmu.readByte(address: tempResultAddress)
                    let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: tempResult)
                    registers.F = tempFlags
                    registers.PC = registers.PC &+ 3
                    tStates = tStates + 19
                    incrementR(opcodeCount:2)
                case 0xE1: // POP IY - FD E1 - The memory location pointed to by SP is stored into IYL and SP is incremented. The memory location pointed to by SP is stored into IYH and SP is incremented again
                    logInstructionDetails(instructionDetails: "POP IY", opcode: [0xFD,0xE1], programCounter: registers.PC)
                    registers.IYL = mmu.readByte(address: registers.SP)
                    registers.IYH = mmu.readByte(address: registers.SP &+ 1)
                    registers.SP = registers.SP &+ 2
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 14
                    incrementR(opcodeCount:2)
                case 0xE3: // EX (SP),IY - FD E3 - Exchanges (SP) with IYL, and (SP+1) with IYH
                    logInstructionDetails(instructionDetails: "EX (SP),IY", opcode: [0xFD,0xE3], programCounter: registers.PC)
                    let tempSPCL = mmu.readByte(address: registers.SP)
                    let tempSPCH = mmu.readByte(address: registers.SP &+ 1)
                    mmu.writeByte(address: registers.SP, value: UInt8(registers.IY >> 8))
                    mmu.writeByte(address: registers.SP &+ 1, value: UInt8(registers.IY & 0xFF))
                    registers.IX = UInt16(tempSPCH) << 8 | UInt16(tempSPCL)
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 23
                    incrementR(opcodeCount:2)
                case 0xE5: // PUSH IY - FD E5 - SP is decremented and IYH is stored into the memory location pointed to by SP. SP is decremented again and IYL is stored into the memory location pointed to by SP
                    logInstructionDetails(instructionDetails: "PUSH IY", opcode: [0xFD,0xE5], programCounter: registers.PC)
                    registers.SP = registers.SP &- 1
                    mmu.writeByte(address: registers.SP, value: registers.IYH)
                    registers.SP = registers.SP &- 1
                    mmu.writeByte(address: registers.SP, value: registers.IYL)
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 15
                    incrementR(opcodeCount:2)
                case 0xE9: // JP (IY) - FD E9 - Loads the value of IY into PC
                    logInstructionDetails(instructionDetails: "JP (IY)", opcode: [0xFD,0xE9], programCounter: registers.PC)
                    registers.PC = registers.IY
                    tStates = tStates + 8
                    incrementR(opcodeCount:2)
                case 0xF9: // LD SP,IY - FD F9 - Loads the value of IY into SP
                    logInstructionDetails(instructionDetails: "LD SP,IY", opcode: [0xFD,0xF9], programCounter: registers.PC)
                    registers.SP = registers.IY
                    registers.PC = registers.PC &+ 2
                    tStates = tStates + 10
                    incrementR(opcodeCount:2)
                default: break
            } // FD and FC CB opcodes
        case 0xFE: // CP n - FE n - Subtracts $n from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP $n", opcode: [0xFE], values: [opcode2], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: opcode2)
            registers.F = tempFlags
            registers.PC = registers.PC &+ 2
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xFF: // RST 0x38 - FF - The current PC value plus one is pushed onto the stack, then is loaded with 0x38
            logInstructionDetails(instructionDetails: "RST 0x38", opcode: [0xFF], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            mmu.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0038
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        default:
            logInstructionDetails(opcode: [opcode1], programCounter: registers.PC)
            // myz80Queue.addToQueue(address: registers.PC, opCodes: [opcode1])
            registers.PC = registers.PC &+ 1
            tStates = tStates + 0 // check this behaviour
            incrementR(opcodeCount:1)
        } // end single opcodes
        z80Queue[z80QueueHead] = registers.PC
        z80QueueFilled[z80QueueHead] = true
        z80QueueHead = (z80QueueHead + 1) % 16
    }
    
    func sortZ80Queue() -> [String]
    {
        var tempZ80Queue: [String] = []
        
        for counter in 0..<16
        {
            let z80QueuePosition = (z80QueueHead + counter) % 16
            let tempPC = z80Queue[z80QueuePosition]
            let tempBytes = [mmu.readByte(address: tempPC),mmu.readByte(address: tempPC &+ 1),mmu.readByte(address: tempPC &+ 2),mmu.readByte(address: tempPC &+ 3)]
            let tempInstruction = z80Disassembler.decodeInstructions(address: tempPC, bytes: tempBytes)
            if z80QueueFilled[z80QueuePosition]
            {
                tempZ80Queue.append(tempInstruction)
            }
        }
        return tempZ80Queue
    }
    
    func sortBreakpointQueue() -> [String]
    {
        var tempBreakpointQueue: [String] = []
        for counter in 0...15
        {
            if breakpointMask[counter] == 0
            {
                tempBreakpointQueue.append("")
            }
            else
            {
                tempBreakpointQueue.append(String(breakpoints[counter]))
            }
        }

        return tempBreakpointQueue
    }
    
    func sortBreakpointQueueMask() -> [Bool]
    {
        var tempBreakpointQueueMask: [Bool] = []
        for counter in 0...15
        {
            if breakpointMask[counter] == 0
            {
                tempBreakpointQueueMask.append(false)
            }
            else
            {
                tempBreakpointQueueMask.append(true)
            }
        }

        return tempBreakpointQueueMask
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
                orderedZ80Queue: sortZ80Queue(),
                breakpointQueue: sortBreakpointQueue(),
                breakpointQueueMask : sortBreakpointQueueMask()
            ),
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
