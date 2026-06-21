import Foundation

actor microbee
{
    enum z80Flags : UInt8
    {
        case Carry = 0x01               // 00000001
        case Negative = 0x02            // 00000010
        case ParityOverflow = 0x04      // 00000100
        case X = 0x08                   // 00001000
        case HalfCarry = 0x10           // 00010000
        case Y = 0x20                   // 00100000
        case Zero = 0x40                // 01000000
        case Sign = 0x80                // 10000000
    }

    struct z80FastFlags
    {
        static let lookupSZP: [UInt8] =
        {
            (0...255).map
            { counter in
                
                var tempFlags: UInt8 = 0
                
                tempFlags = tempFlags | UInt8(counter & Int(z80Flags.X.rawValue))   // Preserve bit 3 (X) flags from result
                tempFlags = tempFlags | UInt8(counter & Int(z80Flags.Y.rawValue))   // Preserve bit 5 (Y) flags from result
                
                if (counter & Int(z80Flags.Sign.rawValue)) != 0
                {
                    tempFlags = tempFlags | z80Flags.Sign.rawValue             // Set sign flag is bit 7 is set
                }
                
                if counter == 0
                {
                    tempFlags = tempFlags | z80Flags.Zero.rawValue             // set zero flag is result is 0
                }
                
                let bitsSet = counter.nonzeroBitCount
                
                if bitsSet % 2 == 0
                {
                    tempFlags = tempFlags | z80Flags.ParityOverflow.rawValue   // set parity flag if even number of bits set
                }

                return tempFlags
            }
        }()
        
        @inline(__always)
        static func basicHelper(tempResult: UInt8) -> UInt8
        {
            return lookupSZP[Int(tempResult)]                                                     // Lookup Sign,Zero,Parity/Overflow
        }
        
        static let lookupDAA: [UInt8] =
        {
            (0...1023).map
            { counter in
                
                var tempValue : UInt8 = 0
                let UpperNibbleMask = (counter & 0xFF) >> 4
                let LowerNibbleMask = (counter & 0x0F)
                
                switch counter
                {
                case 0...255 :
                    if ((0...9).contains(UpperNibbleMask)) && ((0...9).contains(LowerNibbleMask))
                    {
                        tempValue = 0x00
                    }
                    if ((10...15).contains(UpperNibbleMask)) && ((0...9).contains(LowerNibbleMask))
                    {
                        tempValue = 0x60
                    }
                    if ((0...9).contains(UpperNibbleMask)) && ((10...15).contains(LowerNibbleMask))
                    {
                        tempValue = 0x06
                    }
                    if ((9...15).contains(UpperNibbleMask)) && ((10...15).contains(LowerNibbleMask))
                    {
                        tempValue = 0x66
                    }
                case 256...511 :
                    if ((0...9).contains(UpperNibbleMask)) && ((0...9).contains(LowerNibbleMask))
                    {
                        tempValue = 0x06
                    }
                    if ((10...15).contains(UpperNibbleMask)) && ((0...9).contains(LowerNibbleMask))
                    {
                        tempValue = 0x66
                    }
                    if ((0...9).contains(UpperNibbleMask)) && ((10...15).contains(LowerNibbleMask))
                    {
                        tempValue = 0x06
                    }
                    if ((9...15).contains(UpperNibbleMask)) && ((10...15).contains(LowerNibbleMask))
                    {
                        tempValue = 0x66
                    }
                case 512...767 :
                    if (0...9).contains(counter & 0x0F)
                    {
                        tempValue = 0x60
                    }
                    else
                    {
                        tempValue = 0x66
                    }
                case 768...1023 :
                    tempValue = 0x66
                default : break
                }

                return tempValue
            }
        }()
        
        @inline(__always)
        static func daaHelper(tempResult: Int) -> UInt8
        {
            return lookupDAA[Int(tempResult)]                                                     // Lookup Sign,Zero,Parity/Overflow
        }
        
        @inline(__always)
        static func logicHelper(tempResult: UInt8, halfCarryMask : UInt8 = 0) -> (returnResult: UInt8, returnFlags: UInt8)
        {
            var tempFlags = lookupSZP[Int(tempResult)]                                                     // Lookup Sign,Zero,Parity/Overflow
            
            tempFlags = tempFlags & ~z80Flags.Negative.rawValue                                            // Reset Negative
            tempFlags = tempFlags & ~z80Flags.Carry.rawValue                                               // Reset Carry
            tempFlags = tempFlags | halfCarryMask                                                          // Set Negative for AND, reset for OR/XOR
            
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
        static func addHelper(operand1: UInt8, operand2: UInt8, addCarry: Bool = false) -> (returnResult: UInt8, returnFlags: UInt8)
        {
            let carry: UInt8 = addCarry ? 1 : 0
            
            let intOperand1 = Int(operand1)
            let intOperand2 = Int(operand2)
            let tempResultOverflow = intOperand1 + intOperand2 + Int(carry)
            let tempResult = UInt8(tempResultOverflow & 0xFF)
            
            var tempFlags = lookupSZP[Int(tempResult)] & ~z80Flags.ParityOverflow.rawValue  // Lookup Sign,Zero,Parity/Overflow and set Parity/Overflow to 0
        
            if tempResultOverflow > 0xFF
            {
                tempFlags = tempFlags | z80Flags.Carry.rawValue                                        // Set Carry
            }

            tempFlags = tempFlags & ~z80Flags.Negative.rawValue                                        // Reset Negative for addition
            
            if ((intOperand1 ^ tempResultOverflow) & (intOperand2 ^ tempResultOverflow) & Int(z80Flags.Sign.rawValue)) != 0
            {
                tempFlags = tempFlags | z80Flags.ParityOverflow.rawValue                              // set Overflow if operand1 and operand2 have same sign but tempresult has a different sign
            }
            
            if (intOperand1 & 0x0F) + (intOperand2 & 0x0F) + Int(carry) > 0x0F                                // set Half Carry if carry from bit 3 to bit 4
            {
                tempFlags = tempFlags | z80Flags.HalfCarry.rawValue
            }
            
            return (tempResult, tempFlags)
        }
        
        @inline(__always)
        static func addHelper16(operand1: UInt16, operand2: UInt16, currentFlags: UInt8, addCarry: Bool = false) -> (returnResult: UInt16, returnFlags: UInt8)
        {
            let carry: UInt32 = addCarry ? 1 : 0
            let tempResultOverflow = UInt32(operand1) + UInt32(operand2) + carry
            let tempResult = UInt16(tempResultOverflow & 0xFFFF)
            
            let tempResultHigh = UInt8(tempResult >> 8)
            let tempX = tempResultHigh & 0x08
            let tempY = tempResultHigh & 0x20

            var tempFlags =  tempX | tempY
            
            if tempResultOverflow > 0xFFFF
            {
                tempFlags = tempFlags | z80Flags.Carry.rawValue
            }
        
            if ((UInt32(operand1) & 0x0FFF) + (UInt32(operand2) & 0x0FFF) + carry) > 0x0FFF
            {
                tempFlags = tempFlags | z80Flags.HalfCarry.rawValue
            }
        
            if ((UInt32(operand1) ^ tempResultOverflow) & (UInt32(operand2) ^ tempResultOverflow) & 0x8000) != 0
            {
                tempFlags = tempFlags | z80Flags.ParityOverflow.rawValue
            }

            if (tempResult & 0x8000) != 0
            {
                tempFlags = tempFlags | z80Flags.Sign.rawValue
            }

            if tempResult == 0
            {
                tempFlags = tempFlags |  z80Flags.Zero.rawValue
            }
            
            return (tempResult, tempFlags)
        }
        
        @inline(__always)
        static func subHelper(operand1: UInt8, operand2: UInt8, addCarry: Bool = false) -> (returnResult: UInt8, returnFlags: UInt8)
        {
            let carry: UInt8 = addCarry ? 1 : 0
            
            let tempResultOverflow = Int16(operand1) - Int16(operand2) - Int16(carry)
            let tempResult = UInt8(tempResultOverflow & 0xFF)
            
            var tempFlags = lookupSZP[Int(tempResult)] & ~z80Flags.ParityOverflow.rawValue
            
            tempFlags = tempFlags | z80Flags.Negative.rawValue
            
            if tempResultOverflow < 0
            {
                tempFlags = tempFlags | z80Flags.Carry.rawValue
            }
            
            if Int16(operand1 & 0x0F) - Int16(operand2 & 0x0F) - Int16(carry) < 0
            {
                tempFlags |= z80Flags.HalfCarry.rawValue
            }
            
            if ((operand1 ^ operand2) & 0x80 != 0) && ((operand1 ^ tempResult) & 0x80 != 0)
            {
                tempFlags = tempFlags | z80Flags.ParityOverflow.rawValue
            }
            
            return (tempResult, tempFlags)
        }
        
        @inline(__always)
        static func subHelper16(operand1: UInt16, operand2: UInt16, currentFlags: UInt8, addCarry: Bool = false) -> (returnResult: UInt16, returnFlags: UInt8)
        {
            let carry: Int32 = addCarry ? 1 : 0
            
            let tempResultOverflow = Int32(operand1) - Int32(operand2) - carry
            let tempResult = UInt16(tempResultOverflow & 0xFFFF)
            
            let tempResultHigh = UInt8(tempResult >> 8)
            let tempX = tempResultHigh & 0x08
            let tempY = tempResultHigh & 0x20

            var tempFlags = z80Flags.Negative.rawValue | tempX | tempY

            if tempResultOverflow  < 0
            {
                tempFlags = tempFlags | z80Flags.Carry.rawValue
            }

            if (Int32(operand1 & 0x0FFF) - Int32(operand2 & 0x0FFF) - carry) < 0
            {
                tempFlags = tempFlags | z80Flags.HalfCarry.rawValue
            }

            if ((operand1 ^ operand2) & 0x8000 != 0) && ((operand1 ^ tempResult) & 0x8000 != 0)
            {
                tempFlags = tempFlags | z80Flags.ParityOverflow.rawValue
            }

            if (tempResult & 0x8000) != 0
            {
                tempFlags = tempFlags | z80Flags.Sign.rawValue
            }

            if tempResult == 0
            {
                tempFlags = tempFlags | z80Flags.Zero.rawValue
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
        
        var SPH : UInt8 = 0x7F      // Index Register SP - high byte - 8 bit
        var SPL : UInt8 = 0x00      // Index Register SP - low byte - 8 bit
        var PCH : UInt8 = 0x80      // Index Register PC - high byte - 8 bit
        var PCL : UInt8 = 0x00      // Index Register PC - low byte - 8 bit
        
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
                altE = UInt8(newValue & 0xFF)
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
        
        var WZ : UInt16 = 0         // the mysterious WZ/MEMPTR register - 16 bit
        
        var Q : UInt8 = 0           // preservation of output of last flag modifying instruction -  8 bit
        
        var P : UInt8 = 0           // JSON psuedo-register - track whether previous instruction was LD A,I or LD A,R - 8 bit
        
        var EI : UInt8 = 0          // JSON psuedo-register - track whether previous instruction was EI - 8 bit
    }
    
    private var preserveEI : UInt8 = 0
    
    private var pausedBreakpoint : Bool = false
    
    private let z80Disassembler = Z80Disassembler()
    
    private var z80Queue = ContiguousArray<UInt16>(repeating: 0, count: 16)
    private var z80QueueFilled = ContiguousArray<Bool>(repeating: false, count: 16)
    private var z80QueueHead = 0
    
    private var breakpoints = SIMD16<UInt16>(repeating: 0x0000)
    private var breakpointMask = SIMD16<UInt16>(repeating: 0x0000)
    
    var registers = Registers()
    
    var tStates : UInt64 = 0
    
    private(set) var emulatorState : emulatorState = .stopped
    private(set) var executionMode : executionMode = .continuous
    
    private var interruptPending = false

    let bus = BUS()
    
    init()
    {
    }
    
    private var runTask: Task<Void, Never>?
    
    func loadCPUState(cpuState: CPUState) async
    {
        registers.A = cpuState.A
        registers.F = cpuState.F
        registers.B = cpuState.B
        registers.C = cpuState.C
        registers.D = cpuState.D
        registers.E = cpuState.E
        registers.H = cpuState.H
        registers.L = cpuState.L
        
        registers.altAF = cpuState.altAF
        registers.altBC = cpuState.altBC
        registers.altDE = cpuState.altDE
        registers.altHL = cpuState.altHL
        
        registers.I = cpuState.I
        registers.R = cpuState.R
        
        registers.IM = cpuState.IM
        
        registers.IFF1 = (cpuState.IFF1 != 0)
        registers.IFF2 = (cpuState.IFF2 != 0)
        
        registers.IX = cpuState.IX
        registers.IY = cpuState.IY
        
        registers.PC = cpuState.PC
        registers.SP  = cpuState.SP
        
        registers.WZ = cpuState.WZ
        
        registers.Q  = cpuState.Q
        
        registers.P = cpuState.P
        
        registers.EI = cpuState.EI
        
        bus.mmu.map(readDevice: bus.testRAM, writeDevice: bus.testRAM, memoryLocation: 0x0000)
        
        for location in cpuState.ram
        {
            let address = UInt16(location[0])
            let value = UInt8(location[1])
            bus.writeByte(address: address, value: value)
        }
    }
    
    func returnTStates() async -> Int
    {
        return Int(tStates)
    }
    
    func returnCPUState(cpuState: CPUState) async -> CPUState
    {
        var tempRam : [[Int]] = []
        for location in cpuState.ram
        {
            let address = UInt16(location[0])
            let value = bus.readByte(address: address)
            tempRam.append([Int(address),Int(value)])
        }
        
        let afterTest = CPUState(
            A: registers.A, F: registers.F,B: registers.B,C: registers.C,D: registers.D,E: registers.E,H: registers.H,L: registers.L,
            altAF: registers.altAF, altBC: registers.altBC, altDE: registers.altDE, altHL: registers.altHL,
            I: registers.I, R: registers.R,
            IM: registers.IM,
            IFF1: registers.IFF1 ? 1:0 , IFF2: registers.IFF2 ? 1:0,
            IX: registers.IX, IY: registers.IY,
            PC: registers.PC, SP: registers.SP,
            WZ: registers.WZ,
            Q: registers.Q,
            P: registers.P,
            EI: registers.EI,
            ram : tempRam
            )
        return afterTest
    }
    
    func loadPorts(portNum: UInt16, portValue: UInt8)
    {
        bus.writePort(portNum: portNum, portValue: portValue)
    }
    
    func returnPortValue(portNum: UInt16) -> UInt8
    {
        return bus.readPort(portNum: portNum)
    }
    
    func updateBreakpoints(index: Int, value: UInt16, mask: Bool) async
    {
        breakpoints[index] = value
        breakpointMask[index] = (mask ? 1 : 0)
    }
    
    func ClearVideoMemory()
    {
        bus.videoRAM.fillMemory(memValue : 0x20)
    }
    
    func splashScreen()
    {
        bus.videoRAM.fillMemory(memValue: 0x20)
        bus.colourRAM.fillMemory(memValue: 0x02)
        bus.videoRAM.fillMemoryFromArray(memValues: [87,101,108,99,111,109,101,32,116,111,32,78,111,118,97,116,111], memOffset: 88) // Welome to Novato
        bus.videoRAM.fillMemoryFromArray(memValues:  [128,129,130,131,132,133,134,135,
                                                   136,137,138,139,140,141,142,143], memOffset : 280)
        bus.videoRAM.fillMemoryFromArray(memValues:  [144,145,146,147,148,149,150,151,
                                                   152,153,154,155,156,157,158,159], memOffset : 344)
        bus.videoRAM.fillMemoryFromArray(memValues:  [160,161,162,163,164,165,166,167,
                                                   168,169,170,171,172,173,174,175], memOffset : 408)
        bus.videoRAM.fillMemoryFromArray(memValues:  [176,177,178,179,180,181,182,183,
                                                   184,185,186,187,188,189,190,191], memOffset : 472)
        bus.videoRAM.fillMemoryFromArray(memValues:  [192,193,194,195,196,197,198,199,
                                                   200,201,202,203,204,205,206,207], memOffset : 536)
        bus.videoRAM.fillMemoryFromArray(memValues:  [208,209,210,211,212,213,214,215,
                                                   216,217,218,219,220,221,222,223], memOffset : 600)
        bus.videoRAM.fillMemoryFromArray(memValues:  [224,225,226,227,228,229,230,231,
                                                   232,233,234,235,236,237,238,239], memOffset : 664)
        bus.videoRAM.fillMemoryFromArray(memValues:  [240,241,242,243,244,245,246,247,
                                                   248,249,250,251,252,253,254,255], memOffset : 728)
        bus.videoRAM.fillMemoryFromArray(memValues: [80,114,101,115,115,32,83,116,97,114,116], memOffset: 923) // Press Start
        bus.pcgRAM.fillMemoryFromArray(memValues :
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
        pausedBreakpoint = true
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
        
        registers.WZ = 0
        
        registers.Q = 0
        
        registers.P = 0
        
        registers.EI = 0
        
        preserveEI = 0
        
        tStates = 0
        
        emulatorState = .stopped
        executionMode = .continuous
        
        pausedBreakpoint = false
        
        interruptPending = false
        
        bus.ports.resetPorts()
        
        z80Queue = ContiguousArray<UInt16>(repeating: 0, count: 16)
        z80QueueFilled = ContiguousArray<Bool>(repeating: false, count: 16)
        z80QueueHead = 0
        
        breakpoints = SIMD16<UInt16>(repeating: 0x0000)
        breakpointMask = SIMD16<UInt16>(repeating: 0x0000)
        
        bus.crtc.registers.R0 = 0x00
        bus.crtc.registers.R1 = 0x40
        bus.crtc.registers.R2 = 0x00
        bus.crtc.registers.R3 = 0x00
        bus.crtc.registers.R4 = 0x12
        bus.crtc.registers.R5 = 0x00
        bus.crtc.registers.R6 = 0x10
        bus.crtc.registers.R7 = 0x00
        bus.crtc.registers.R8 = 0x00
        bus.crtc.registers.R9 = 0x0F
        bus.crtc.registers.R10 = 0x20
        bus.crtc.registers.R11 = 0x00
        bus.crtc.registers.R12 = 0x00
        bus.crtc.registers.R13 = 0x00
        bus.crtc.registers.R14 = 0x00
        bus.crtc.registers.R15 = 0x00
        bus.crtc.registers.R16 = 0x00
        bus.crtc.registers.R17 = 0x00
        bus.crtc.registers.R18 = 0x00
        bus.crtc.registers.R19 = 0x00
        
        bus.crtc.registers.statusRegister = 0b10000000
        
        bus.crtc.registers.redBackgroundIntensity = 0x00
        bus.crtc.registers.greenBackgroundIntensity = 0x00
        bus.crtc.registers.blueBackgroundIntensity = 0x00
        
        bus.mmu.map(readDevice: bus.mainRAM, writeDevice: bus.mainRAM, memoryLocation: 0x0000)       // 32K System RAM
        bus.mmu.map(readDevice: bus.basicROM, writeDevice: bus.basicROM, memoryLocation: 0x8000)     // 16K BASIC ROM
        bus.mmu.map(readDevice: bus.pakROM, writeDevice: bus.pakROM , memoryLocation: 0xC000)        // 8K Optional ROM
        bus.mmu.map(readDevice: bus.netROM, writeDevice: bus.netROM, memoryLocation: 0xE000)         // 4K Net ROM
        bus.mmu.map(readDevice: bus.videoRAM, writeDevice: bus.videoRAM, memoryLocation: 0xF000)     // 2K Video RAM
        bus.mmu.map(readDevice: bus.pcgRAM, writeDevice: bus.pcgRAM, memoryLocation: 0xF800)         // 2K PCG RAM
        
        bus.basicROM.fillMemoryFromFile(fileName: "basic_5.22e", fileExtension: "rom")
//        bus.pakROM.fillMemoryFromFile(fileName: "wordbee_1.2", fileExtension: "rom")
//        bus.netROM.fillMemoryFromFile(fileName: "telcom_1.0", fileExtension: "rom")
        bus.fontROM.fillMemoryFromFile(fileName: "charrom", fileExtension: "bin")
        
        // bus.mainRAM.fillMemoryFromFile(fileName: "demo", fileExtension: "bin", memOffset: 0x900)
        //bus.mainRAM.fillMemoryFromFile(fileName: "emu-j", fileExtension: "bee", memOffset: 0x900)
        //bus.mainRAM.fillMemoryFromFile(fileName: "kilopede", fileExtension: "bee", memOffset: 0x900)
         bus.mainRAM.fillMemoryFromFile(fileName: "sp-inv", fileExtension: "bee", memOffset: 0x900)
        
        bus.mainRAM.fillMemoryFromArray(memValues: [0xff], memOffset: 0x99)   // 0xff means this is a colour microbee.  Required here to force basic to clear colour ram
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
        bus.writeByte(address: registers.SP, value: registers.PCH)
        bus.writeByte(address: registers.SP + 1, value: registers.PCL)
        registers.PC = 0x0038
    }
    
    func writeToMemory(address: UInt16, value: UInt8)
    {
        bus.writeByte(address: address, value: value)
    }
    
    func updatePC(address: UInt16)
    {
        registers.PC = address    
    }
    
    func TestFlags ( FlagRegister : UInt8, Flag : z80Flags ) -> Bool
    
    {
        return FlagRegister & Flag.rawValue != 0
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
        let logString = z80Disassembler.decodeInstructions(address: programCounter, bytes: opcode+values)
        
//        var instructionString : String = instructionDetails
//        
//        switch values.count
//        {
//        case 1 :
//            instructionString = instructionString.replacingOccurrences(of: "$n", with: "0x"+String(format:"%02X",values[0]))
//            instructionString = instructionString.replacingOccurrences(of: "$d", with: "0x"+String(format:"%02X",values[0]))
//        case 2 :
//            instructionString = instructionString.replacingOccurrences(of: "$nn", with: "0x"+String(format:"%04X",UInt16(values[1]) << 8 | UInt16(values[0])))
//            instructionString = instructionString.replacingOccurrences(of: "$d", with: "0x"+String(format:"%02X",values[0]))
//            instructionString = instructionString.replacingOccurrences(of: "$n", with: "0x"+String(format:"%02X",values[1]))
//        default: break
//        }
//        let noValues = values.count == 0
//        let opcodeString = opcode.map { String(format:"%02X",$0) }.joined(separator: " ") + (noValues ? "" : " ") + values.map { String(format:"%02X",$0) }.joined(separator: " ")
//        let logString = String(format:"0x%04X",registers.PC) + "   " + opcodeString + "    " + instructionString
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
        
        if any(addressMatch .& (breakpointMask .!= 0)) && !pausedBreakpoint
        {
            pause()
            return
            // need to allow a smoother continuation of execution
        }

        pausedBreakpoint = false
        executeInstructions()
        appLog.cpu.debug("Cumulative T-states: \(String(self.tStates))")
        pollInterrupt()
    }

    @inline(__always)
    private func incrementR(opcodeCount: UInt8)
    {
        let msb = registers.R & 0x80
        let lsb = ( registers.R & 0x7F) &+ opcodeCount
        registers.R  = msb | (lsb & 0x7F)
    }
    
    private func executeCBInstructions(opcode2: UInt8)
    {
        switch opcode2
        {
        case 0x00: // RLC B - CB 00 - The contents of B are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0
            logInstructionDetails(instructionDetails: "RLC B", opcode: [0xCB,0x00], programCounter: registers.PC)
            let carry = registers.B >> 7
            let tempResult = (registers.B << 1) | carry
            (registers.B,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x01: // RLC C - CB 01 - The contents of C are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0
            logInstructionDetails(instructionDetails: "RLC C", opcode: [0xCB,0x01], programCounter: registers.PC)
            let carry = registers.C >> 7
            let tempResult = (registers.C << 1) | carry
            (registers.C,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x02: // RLC D - CB 02 - The contents of D are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0
            logInstructionDetails(instructionDetails: "RLC D", opcode: [0xCB,0x02], programCounter: registers.PC)
            let carry = registers.D >> 7
            let tempResult = (registers.D << 1) | carry
            (registers.D,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x03: // RLC E - CB 03 - The contents of E are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0
            logInstructionDetails(instructionDetails: "RLC E", opcode: [0xCB,0x03], programCounter: registers.PC)
            let carry = registers.E >> 7
            let tempResult = (registers.E << 1) | carry
            (registers.E,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x04: // RLC H - CB 04 - The contents of H are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0
            logInstructionDetails(instructionDetails: "RLC H", opcode: [0xCB,0x04], programCounter: registers.PC)
            let carry = registers.H >> 7
            let tempResult = (registers.H << 1) | carry
            (registers.H,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x05: // RLC L - CB 05 - The contents of L are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0
            logInstructionDetails(instructionDetails: "RLC L", opcode: [0xCB,0x05], programCounter: registers.PC)
            let carry = registers.L >> 7
            let tempResult = (registers.L << 1) | carry
            (registers.L,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x06: // RLC (HL)) - CB 06 - The contents of B are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0
            logInstructionDetails(instructionDetails: "RLC (HL)", opcode: [0xCB,0x06], programCounter: registers.PC)
            let tempOldValue =  bus.readByte(address: registers.HL)
            let carry = tempOldValue >> 7
            let tempResult = (tempOldValue << 1) | carry
            var tempNewValue : UInt8
            (tempNewValue,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: registers.HL, value: tempNewValue)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x07: // RLC A - CB 07 - The contents of A are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0
            logInstructionDetails(instructionDetails: "RLC A", opcode: [0xCB,0x07], programCounter: registers.PC)
            let carry = registers.A >> 7
            let tempResult = (registers.A << 1) | carry
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x08: // RRC B - CB 08 - The contents of B are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7.
            logInstructionDetails(instructionDetails: "RRC B", opcode: [0xCB,0x08], programCounter: registers.PC)
            let carry = registers.B & z80Flags.Carry.rawValue
            let tempResult = (registers.B >> 1) | (registers.B << 7)
            (registers.B,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x09: // RRC C - CB 09 - The contents of C are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7
            logInstructionDetails(instructionDetails: "RRC C", opcode: [0xCB,0x09], programCounter: registers.PC)
            let carry = registers.C & z80Flags.Carry.rawValue
            let tempResult = (registers.C >> 1) | (registers.C << 7)
            (registers.C,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x0A: // RRC D - CB 0A - The contents of D are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7
            logInstructionDetails(instructionDetails: "RRC D", opcode: [0xCB,0x0A], programCounter: registers.PC)
            let carry = registers.D & z80Flags.Carry.rawValue
            let tempResult = (registers.D >> 1) | (registers.D << 7)
            (registers.D,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x0B: // RRC E - CB 0B - The contents of E are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7
            logInstructionDetails(instructionDetails: "RRC E", opcode: [0xCB,0x0B], programCounter: registers.PC)
            let carry = registers.E & z80Flags.Carry.rawValue
            let tempResult = (registers.E >> 1) | (registers.E << 7)
            (registers.E,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x0C: // RRC H - CB 0C - The contents of H are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7
            logInstructionDetails(instructionDetails: "RRC H", opcode: [0xCB,0x0C], programCounter: registers.PC)
            let carry = registers.H & z80Flags.Carry.rawValue
            let tempResult = (registers.H >> 1) | (registers.H << 7)
            (registers.H,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x0D: // RRC L - CB 0D - The contents of D are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7
            logInstructionDetails(instructionDetails: "RRC L", opcode: [0xCB,0x0D], programCounter: registers.PC)
            let carry = registers.L & z80Flags.Carry.rawValue
            let tempResult = (registers.L >> 1) | (registers.L << 7)
            (registers.L,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x0E: // RRC (HL) - CB 0E - The contents of (HL) are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7
            logInstructionDetails(instructionDetails: "RRC (HL)", opcode: [0xCB,0x0E], programCounter: registers.PC)
            let tempOldValue =  bus.readByte(address: registers.HL)
            let carry = tempOldValue & z80Flags.Carry.rawValue
            let tempResult = (tempOldValue >> 1) | (tempOldValue << 7)
            var tempNewValue : UInt8
            (tempNewValue,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: registers.HL, value: tempNewValue)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x0F: // RRC A - CB 0F - The contents of A are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7
            logInstructionDetails(instructionDetails: "RRC A", opcode: [0xCB,0x0F], programCounter: registers.PC)
            let carry = registers.A & z80Flags.Carry.rawValue
            let tempResult = (registers.A >> 1) | (registers.A << 7)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x10: // RL B - CB 10 - The contents of B are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.
            logInstructionDetails(instructionDetails: "RL B", opcode: [0xCB,0x10], programCounter: registers.PC)
            let newcarry = registers.B >> 7
            let oldcarry = registers.F & z80Flags.Carry.rawValue
            let tempResult = (registers.B << 1) | oldcarry
            (registers.B,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x11: // RL C - CB 11 - The contents of C are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.
            logInstructionDetails(instructionDetails: "RL C", opcode: [0xCB,0x11], programCounter: registers.PC)
            let newcarry = registers.C >> 7
            let oldcarry = registers.F & z80Flags.Carry.rawValue
            let tempResult = (registers.C << 1) | oldcarry
            (registers.C,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x12: // RL D - CB 12 - The contents of D are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.
            logInstructionDetails(instructionDetails: "RL D", opcode: [0xCB,0x12], programCounter: registers.PC)
            let newcarry = registers.D >> 7
            let oldcarry = registers.F & z80Flags.Carry.rawValue
            let tempResult = (registers.D << 1) | oldcarry
            (registers.D,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x13: // RL E - CB 13 - The contents of E are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.
            logInstructionDetails(instructionDetails: "RL E", opcode: [0xCB,0x13], programCounter: registers.PC)
            let newcarry = registers.E >> 7
            let oldcarry = registers.F & z80Flags.Carry.rawValue
            let tempResult = (registers.E << 1) | oldcarry
            (registers.E,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x14: // RL H - CB 14 - The contents of H are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.
            logInstructionDetails(instructionDetails: "RL H", opcode: [0xCB,0x14], programCounter: registers.PC)
            let newcarry = registers.H >> 7
            let oldcarry = registers.F & z80Flags.Carry.rawValue
            let tempResult = (registers.H << 1) | oldcarry
            (registers.H,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x15: // RL L - CB 15 - The contents of L are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.
            logInstructionDetails(instructionDetails: "RL L", opcode: [0xCB,0x15], programCounter: registers.PC)
            let newcarry = registers.L >> 7
            let oldcarry = registers.F & z80Flags.Carry.rawValue
            let tempResult = (registers.L << 1) | oldcarry
            (registers.L,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x16: // RL (HL)) - CB 16 - The contents of (HL) are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.
            logInstructionDetails(instructionDetails: "RL (HL)", opcode: [0xCB,0x16], programCounter: registers.PC)
            var oldValue =  bus.readByte(address: registers.HL)
            let newcarry = oldValue >> 7
            let oldcarry = registers.F & z80Flags.Carry.rawValue
            let tempResult = (oldValue << 1) | oldcarry
            (oldValue,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: registers.HL, value: oldValue)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x17: // RL A - CB 17 - The contents of A are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.
            logInstructionDetails(instructionDetails: "RL A", opcode: [0xCB,0x17], programCounter: registers.PC)
            let newcarry = registers.A >> 7
            let oldcarry = registers.F & z80Flags.Carry.rawValue
            let tempResult = (registers.A << 1) | oldcarry
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x18: // RR B - CB 18 - The contents of B are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7
            logInstructionDetails(instructionDetails: "RR B", opcode: [0xCB,0x18], programCounter: registers.PC)
            let newcarry = registers.B & 0b00000001
            let oldcarry = (registers.F & z80Flags.Carry.rawValue) << 7
            let tempResult = (registers.B >> 1) | oldcarry
            (registers.B,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x19: // RR C - CB 19 - The contents of C are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7
            logInstructionDetails(instructionDetails: "RR C", opcode: [0xCB,0x19], programCounter: registers.PC)
            let newcarry = registers.C & 0b00000001
            let oldcarry = (registers.F & z80Flags.Carry.rawValue) << 7
            let tempResult = (registers.C >> 1) | oldcarry
            (registers.C,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x1A: // RR D - CB 1A - The contents of D are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7
            logInstructionDetails(instructionDetails: "RR D", opcode: [0xCB,0x1A], programCounter: registers.PC)
            let newcarry = registers.D & 0b00000001
            let oldcarry = (registers.F & z80Flags.Carry.rawValue) << 7
            let tempResult = (registers.D >> 1) | oldcarry
            (registers.D,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x1B: // RR E - CB 1B - The contents of E are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7
            logInstructionDetails(instructionDetails: "RR E", opcode: [0xCB,0x1B], programCounter: registers.PC)
            let newcarry = registers.E & 0b00000001
            let oldcarry = (registers.F & z80Flags.Carry.rawValue) << 7
            let tempResult = (registers.E >> 1) | oldcarry
            (registers.E,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x1C: // RR H - CB 1C - The contents of H are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7
            logInstructionDetails(instructionDetails: "RR H", opcode: [0xCB,0x1C], programCounter: registers.PC)
            let newcarry = registers.H & 0b00000001
            let oldcarry = (registers.F & z80Flags.Carry.rawValue) << 7
            let tempResult = (registers.H >> 1) | oldcarry
            (registers.H,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x1D: // RR L - CB 1D - The contents of L are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7
            logInstructionDetails(instructionDetails: "RR L", opcode: [0xCB,0x1D], programCounter: registers.PC)
            let newcarry = registers.L & 0b00000001
            let oldcarry = (registers.F & z80Flags.Carry.rawValue) << 7
            let tempResult = (registers.L >> 1) | oldcarry
            (registers.L,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x1E: // RR (HL) - CB 1E - The contents of (HL) are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7
            logInstructionDetails(instructionDetails: "RR (HL)", opcode: [0xCB,0x1E], programCounter: registers.PC)
            var tempHL =  bus.readByte(address: registers.HL)
            let newcarry = tempHL  & 0b00000001
            let oldcarry = (registers.F & z80Flags.Carry.rawValue) << 7
            let tempResult = (tempHL  >> 1) | oldcarry
            (tempHL,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: registers.HL, value: tempHL)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x1F: // RR A - CB 1F - The contents of A are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7
            logInstructionDetails(instructionDetails: "RR A", opcode: [0xCB,0x1F], programCounter: registers.PC)
            let newcarry = registers.A & 0b00000001
            let oldcarry = (registers.F & z80Flags.Carry.rawValue) << 7
            let tempResult = (registers.A >> 1) | oldcarry
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | newcarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x20: // SLA B - CB 20 - The contents of B are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0
            logInstructionDetails(instructionDetails: "SLA B", opcode: [0xCB,0x20], programCounter: registers.PC)
            let carry = registers.B >> 7
            let tempResult = registers.B << 1
            (registers.B,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x21: // SLA C - CB 21 - The contents of C are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0
            logInstructionDetails(instructionDetails: "SLA C", opcode: [0xCB,0x21], programCounter: registers.PC)
            let carry = registers.C >> 7
            let tempResult = registers.C << 1
            (registers.C,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x22: // SLA D - CB 22 - The contents of D are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0
            logInstructionDetails(instructionDetails: "SLA D", opcode: [0xCB,0x22], programCounter: registers.PC)
            let carry = registers.D >> 7
            let tempResult = registers.D << 1
            (registers.D,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x23: // SLA E - CB 23 - The contents of E are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0
            logInstructionDetails(instructionDetails: "SLA E", opcode: [0xCB,0x23], programCounter: registers.PC)
            let carry = registers.E >> 7
            let tempResult = registers.E << 1
            (registers.E,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x24: // SLA H - CB 24 - The contents of H are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0
            logInstructionDetails(instructionDetails: "SLA H", opcode: [0xCB,0x24], programCounter: registers.PC)
            let carry = registers.H >> 7
            let tempResult = registers.H << 1
            (registers.H,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x25: // SLA L - CB 25 - The contents of L are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0
            logInstructionDetails(instructionDetails: "SLA L", opcode: [0xCB,0x25], programCounter: registers.PC)
            let carry = registers.L >> 7
            let tempResult = registers.L << 1
            (registers.L,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x26: // SLA (HL) - CB 26 - The contents of (HL) are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0
            logInstructionDetails(instructionDetails: "SLA (HL)", opcode: [0xCB,0x26], programCounter: registers.PC)
            var oldValue =  bus.readByte(address: registers.HL)
            let carry = oldValue >> 7
            let tempResult = oldValue << 1
            (oldValue,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: registers.HL, value: oldValue)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x27: // SLA A - CB 27 - The contents of A are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0
            logInstructionDetails(instructionDetails: "SLA A", opcode: [0xCB,0x27], programCounter: registers.PC)
            let carry = registers.A >> 7
            let tempResult = registers.A << 1
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x28: // SRA B - CB 28 - The contents of C are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged
            logInstructionDetails(instructionDetails: "SRA B", opcode: [0xCB,0x28], programCounter: registers.PC)
            let carry = registers.B & 0b00000001
            let bit7 = registers.B & 0b10000000
            let tempResult = (registers.B >> 1) | bit7
            (registers.B,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x29: // SRA C - CB 29 - The contents of C are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged
            logInstructionDetails(instructionDetails: "SRA C", opcode: [0xCB,0x29], programCounter: registers.PC)
            let carry = registers.C & 0b00000001
            let bit7 = registers.C & 0b10000000
            let tempResult = (registers.C >> 1) | bit7
            (registers.C,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x2A: // SRA D - CB 2A - The contents of D are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged
            logInstructionDetails(instructionDetails: "SRA D", opcode: [0xCB,0x2A], programCounter: registers.PC)
            let carry = registers.D & 0b00000001
            let bit7 = registers.D & 0b10000000
            let tempResult = (registers.D >> 1) | bit7
            (registers.D,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x2B: // SRA E - CB 2B - The contents of E are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged
            logInstructionDetails(instructionDetails: "SRA E", opcode: [0xCB,0x2B], programCounter: registers.PC)
            let carry = registers.E & 0b00000001
            let bit7 = registers.E & 0b10000000
            let tempResult = (registers.E >> 1) | bit7
            (registers.E,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x2C: // SRA H - CB 2C - The contents of H are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged
            logInstructionDetails(instructionDetails: "SRA H", opcode: [0xCB,0x2C], programCounter: registers.PC)
            let carry = registers.H & 0b00000001
            let bit7 = registers.H & 0b10000000
            let tempResult = (registers.H >> 1) | bit7
            (registers.H,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x2D: // SRA L - CB 2D - The contents of L are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged
            logInstructionDetails(instructionDetails: "SRA L", opcode: [0xCB,0x2D], programCounter: registers.PC)
            let carry = registers.L & 0b00000001
            let bit7 = registers.L & 0b10000000
            let tempResult = (registers.L >> 1) | bit7
            (registers.L,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x2E: // SRA (HL) - CB 2E - The contents of (HL) are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged
            logInstructionDetails(instructionDetails: "SRA (HL)", opcode: [0xCB,0x2E], programCounter: registers.PC)
            var oldValue =  bus.readByte(address: registers.HL)
            let carry = oldValue & 0b00000001
            let bit7 = oldValue & 0b10000000
            let tempResult = (oldValue >> 1) | bit7
            (oldValue,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: registers.HL, value: oldValue)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x2F: // SRA A - CB 2F - The contents of A are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged
            logInstructionDetails(instructionDetails: "SRA A", opcode: [0xCB,0x2F], programCounter: registers.PC)
            let carry = registers.A & 0b00000001
            let bit7 = registers.A & 0b10000000
            let tempResult = (registers.A >> 1) | bit7
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x30: // Undocumented - SLL B - CB 30 - The contents of B are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0
            // Stub
            logInstructionDetails(instructionDetails: "SLL B", opcode: [0xCB,0x30], programCounter: registers.PC)
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x31: // Undocumented - SLL C - CB 31 - The contents of C are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0
            // Stub
            logInstructionDetails(instructionDetails: "SLL C", opcode: [0xCB,0x31], programCounter: registers.PC)
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x32: // Undocumented - SLL D - CB 32 - The contents of D are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0
            // Stub
            logInstructionDetails(instructionDetails: "SLL D", opcode: [0xCB,0x32], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x33: // Undocumented - SLL E - CB 33 - The contents of E are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0
            // Stub
            logInstructionDetails(instructionDetails: "SLL E", opcode: [0xCB,0x33], programCounter: registers.PC)
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x34: // Undocumented - SLL H - CB 34 - The contents of H are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0
            // Stub
            logInstructionDetails(instructionDetails: "SLL H", opcode: [0xCB,0x34], programCounter: registers.PC)
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x35: // Undocumented - SLL L - CB 35 - The contents of L are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0
            // Stub
            logInstructionDetails(instructionDetails: "SLL L", opcode: [0xCB,0x35], programCounter: registers.PC)
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x36: // Undocumented - SLL (HL) - CB 36 - The contents of (HL) are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0
            // Stub
            logInstructionDetails(instructionDetails: "SLL (HL)", opcode: [0xCB,0x36], programCounter: registers.PC)
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x37: // Undocumented - SLL A - CB 37 - The contents of A are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0
            // Stub
            logInstructionDetails(instructionDetails: "SLL A", opcode: [0xCB,0x37], programCounter: registers.PC)
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x38: // SRL B - CB 38 - The contents of B are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7
            logInstructionDetails(instructionDetails: "SRL B", opcode: [0xCB,0x38], programCounter: registers.PC)
            let carry = registers.B & z80Flags.Carry.rawValue
            let tempResult = registers.B >> 1
            (registers.B,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x39: // SRL C - CB 39 - The contents of C are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7
            logInstructionDetails(instructionDetails: "SRL C", opcode: [0xCB,0x39], programCounter: registers.PC)
            let carry = registers.C & z80Flags.Carry.rawValue
            let tempResult = registers.C >> 1
            (registers.C,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x3A: // SRL D - CB 3A - The contents of D are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7
            logInstructionDetails(instructionDetails: "SRL D", opcode: [0xCB,0x3A], programCounter: registers.PC)
            let carry = registers.D & z80Flags.Carry.rawValue
            let tempResult = registers.D >> 1
            (registers.D,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x3B: // SRL E - CB 3B - The contents of E are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7
            logInstructionDetails(instructionDetails: "SRL E", opcode: [0xCB,0x3B], programCounter: registers.PC)
            let carry = registers.E & z80Flags.Carry.rawValue
            let tempResult = registers.E >> 1
            (registers.E,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x3C: // SRL H - CB 3C - The contents of H are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7
            logInstructionDetails(instructionDetails: "SRL H", opcode: [0xCB,0x3C], programCounter: registers.PC)
            let carry = registers.H & z80Flags.Carry.rawValue
            let tempResult = registers.H >> 1
            (registers.H,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x3D: // SRL L - CB 3D - The contents of L are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7
            logInstructionDetails(instructionDetails: "SRL L", opcode: [0xCB,0x3D], programCounter: registers.PC)
            let carry = registers.L & z80Flags.Carry.rawValue
            let tempResult = registers.L >> 1
            (registers.L,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x3E: // SRL (HL) - CB 3E - The contents of (HL)) are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7
            logInstructionDetails(instructionDetails: "SRL (HL)", opcode: [0xCB,0x3E], programCounter: registers.PC)
            var oldValue =  bus.readByte(address: registers.HL)
            let carry = oldValue & z80Flags.Carry.rawValue
            let tempResult = oldValue >> 1
            (oldValue,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: registers.HL, value: oldValue)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x3F: // SRL A - CB 3F - The contents of A are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7
            logInstructionDetails(instructionDetails: "SRL A", opcode: [0xCB,0x3F], programCounter: registers.PC)
            let carry = registers.A & z80Flags.Carry.rawValue
            let tempResult = registers.A >> 1
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = registers.F | carry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x40: // BIT 0,B - CB 40 - Tests bit 0 of B
            logInstructionDetails(instructionDetails: "BIT 0,B", opcode: [0xCB,0x40], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.B & z80Flags.X.rawValue
            let tempY : UInt8 = registers.B & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.B & 0x01) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.B & 0x01) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x41: // BIT 0,C - CB 41 - Tests bit 0 of C
            logInstructionDetails(instructionDetails: "BIT 0,C", opcode: [0xCB,0x41], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.C & z80Flags.X.rawValue
            let tempY : UInt8 = registers.C & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.C & 0x01) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.C & 0x01) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x42: // BIT 0,D - CB 42 - Tests bit 0 of D
            logInstructionDetails(instructionDetails: "BIT 0,D", opcode: [0xCB,0x42], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.D & z80Flags.X.rawValue
            let tempY : UInt8 = registers.D & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.D & 0x01) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.D & 0x01) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x43: // BIT 0,E - CB 43 - Tests bit 0 of E
            logInstructionDetails(instructionDetails: "BIT 0,E", opcode: [0xCB,0x43], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.E & z80Flags.X.rawValue
            let tempY : UInt8 = registers.E & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.E & 0x01) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.E & 0x01) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x44: // BIT 0,H - CB 44 - Tests bit 0 of H
            logInstructionDetails(instructionDetails: "BIT 0,H", opcode: [0xCB,0x44], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.H & z80Flags.X.rawValue
            let tempY : UInt8 = registers.H & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.H & 0x01) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.H & 0x01) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x45: // BIT 0,L - CB 45 - Tests bit 0 of L
            logInstructionDetails(instructionDetails: "BIT 0,L", opcode: [0xCB,0x45], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.L & z80Flags.X.rawValue
            let tempY : UInt8 = registers.L & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.L & 0x01) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.L & 0x01) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x46: // BIT 0,(HL) - CB 46 - Tests bit 0 of (HL)
            logInstructionDetails(instructionDetails: "BIT 0,(HL)", opcode: [0xCB,0x46], programCounter: registers.PC)
            let tempResult =  bus.readByte(address: registers.HL)
            let WZH = UInt8((registers.WZ >> 8) & 0xFF)
            let tempX : UInt8 = WZH & 0x08
            let tempY : UInt8 = WZH & 0x20
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (tempResult & 0x01) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (tempResult & 0x01) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 12
            incrementR(opcodeCount:2)
        case 0x47: // BIT 0,A - CB 47 - Tests bit 0 of A
            logInstructionDetails(instructionDetails: "BIT 0,A", opcode: [0xCB,0x47], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.A & z80Flags.X.rawValue
            let tempY : UInt8 = registers.A & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.A & 0x01) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.A & 0x01) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x48: // BIT 1,B - CB 48 - Tests bit 1 of B
            logInstructionDetails(instructionDetails: "BIT 1,B", opcode: [0xCB,0x48], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.B & z80Flags.X.rawValue
            let tempY : UInt8 = registers.B & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.B & 0x02) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.B & 0x02) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x49: // BIT 1,C - CB 49 - Tests bit 1 of C
            logInstructionDetails(instructionDetails: "BIT 1,C", opcode: [0xCB,0x49], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.C & z80Flags.X.rawValue
            let tempY : UInt8 = registers.C & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.C & 0x02) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.C & 0x02) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4A: // BIT 1,D - CB 4A - Tests bit 1 of D
            logInstructionDetails(instructionDetails: "BIT 1,D", opcode: [0xCB,0x4A], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.D & z80Flags.X.rawValue
            let tempY : UInt8 = registers.D & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.D & 0x02) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.D & 0x02) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4B: // BIT 1,E - CB 4B - Tests bit 1 of E
            logInstructionDetails(instructionDetails: "BIT 1,E", opcode: [0xCB,0x4B], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.E & z80Flags.X.rawValue
            let tempY : UInt8 = registers.E & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.E & 0x02) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.E & 0x02) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4C: // BIT 1,H - CB 4C - Tests bit 1 of H
            logInstructionDetails(instructionDetails: "BIT 1,H", opcode: [0xCB,0x4C], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.H & z80Flags.X.rawValue
            let tempY : UInt8 = registers.H & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.H & 0x02) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.H & 0x02) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4D: // BIT 1,L - CB 4D - Tests bit 1 of L
            logInstructionDetails(instructionDetails: "BIT 1,L", opcode: [0xCB,0x4D], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.L & z80Flags.X.rawValue
            let tempY : UInt8 = registers.L & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.L & 0x02) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.L & 0x02) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4E: // BIT 1,(HL) - CB 4E - Tests bit 1 of (HL)
            logInstructionDetails(instructionDetails: "BIT 1,(HL)", opcode: [0xCB,0x4E], programCounter: registers.PC)
            let tempResult =  bus.readByte(address: registers.HL)
            let WZH = UInt8((registers.WZ >> 8) & 0xFF)
            let tempX : UInt8 = WZH & 0x08
            let tempY : UInt8 = WZH & 0x20
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (tempResult & 0x02) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (tempResult & 0x02) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 12
            incrementR(opcodeCount:2)
        case 0x4F: // BIT 1,A - CB 4F - Tests bit 1 of A
            logInstructionDetails(instructionDetails: "BIT 1,A", opcode: [0xCB,0x4F], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.A & z80Flags.X.rawValue
            let tempY : UInt8 = registers.A & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.A & 0x02) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.A & 0x02) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x50: // BIT 2,B - CB 50 - Tests bit 2 of B
            logInstructionDetails(instructionDetails: "BIT 2,B", opcode: [0xCB,0x50], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.B & z80Flags.X.rawValue
            let tempY : UInt8 = registers.B & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.B & 0x04) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.B & 0x04) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x51: // BIT 2,C - CB 51 - Tests bit 2 of C
            logInstructionDetails(instructionDetails: "BIT 2,C", opcode: [0xCB,0x51], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.C & z80Flags.X.rawValue
            let tempY : UInt8 = registers.C & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.C & 0x04) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.C & 0x04) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x52: // BIT 2,D - CB 52 - Tests bit 2 of D
            logInstructionDetails(instructionDetails: "BIT 2,D", opcode: [0xCB,0x52], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.D & z80Flags.X.rawValue
            let tempY : UInt8 = registers.D & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.D & 0x04) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.D & 0x04) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x53: // BIT 2,E - CB 53 - Tests bit 2 of E
            logInstructionDetails(instructionDetails: "BIT 2,E", opcode: [0xCB,0x53], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.E & z80Flags.X.rawValue
            let tempY : UInt8 = registers.E & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.E & 0x04) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.E & 0x04) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x54: // BIT 2,H - CB 54 - Tests bit 2 of H
            logInstructionDetails(instructionDetails: "BIT 2,H", opcode: [0xCB,0x54], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.H & z80Flags.X.rawValue
            let tempY : UInt8 = registers.H & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.H & 0x04) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.H & 0x04) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x55: // BIT 2,L - CB 55 - Tests bit 2 of L
            logInstructionDetails(instructionDetails: "BIT 2,L", opcode: [0xCB,0x55], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.L & z80Flags.X.rawValue
            let tempY : UInt8 = registers.L & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.L & 0x04) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.L & 0x04) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x56: // BIT 2,(HL) - CB 56 - Tests bit 2 of (HL)
            logInstructionDetails(instructionDetails: "BIT 2,(HL)", opcode: [0xCB,0x56], programCounter: registers.PC)
            let tempResult =  bus.readByte(address: registers.HL)
            let WZH = UInt8((registers.WZ >> 8) & 0xFF)
            let tempX : UInt8 = WZH & 0x08
            let tempY : UInt8 = WZH & 0x20
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (tempResult & 0x04) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (tempResult & 0x04) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 12
            incrementR(opcodeCount:2)
        case 0x57: // BIT 2,A - CB 57 - Tests bit 2 of A
            logInstructionDetails(instructionDetails: "BIT 2,A", opcode: [0xCB,0x57], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.A & z80Flags.X.rawValue
            let tempY : UInt8 = registers.A & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.A & 0x04) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.A & 0x04) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x58: // BIT 3,B - CB 58 - Tests bit 3 of B
            logInstructionDetails(instructionDetails: "BIT 3,B", opcode: [0xCB,0x58], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.B & z80Flags.X.rawValue
            let tempY : UInt8 = registers.B & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.B & 0x08) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.B & 0x08) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x59: // BIT 3,C - CB 59 - Tests bit 3 of C
            logInstructionDetails(instructionDetails: "BIT 3,C", opcode: [0xCB,0x59], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.C & z80Flags.X.rawValue
            let tempY : UInt8 = registers.C & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.C & 0x08) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.C & 0x08) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5A: // BIT 3,D - CB 5A - Tests bit 3 of D
            logInstructionDetails(instructionDetails: "BIT 3,D", opcode: [0xCB,0x5A], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.D & z80Flags.X.rawValue
            let tempY : UInt8 = registers.D & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.D & 0x08) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.D & 0x08) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5B: // BIT 3,E - CB 5B - Tests bit 3 of E
            logInstructionDetails(instructionDetails: "BIT 3,E", opcode: [0xCB,0x5B], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.E & z80Flags.X.rawValue
            let tempY : UInt8 = registers.E & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.E & 0x08) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.E & 0x08) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5C: // BIT 3,H - CB 5C - Tests bit 3 of H
            logInstructionDetails(instructionDetails: "BIT 3,H", opcode: [0xCB,0x5C], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.H & z80Flags.X.rawValue
            let tempY : UInt8 = registers.H & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.H & 0x08) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.H & 0x08) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5D: // BIT 3,L - CB 5D - Tests bit 3 of L
            logInstructionDetails(instructionDetails: "BIT 3,L", opcode: [0xCB,0x5D], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.L & z80Flags.X.rawValue
            let tempY : UInt8 = registers.L & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.L & 0x08) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.L & 0x08) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5E: // BIT 3,(HL) - CB 5E - Tests bit 3 of (HL)
            logInstructionDetails(instructionDetails: "BIT 3,(HL)", opcode: [0xCB,0x5E], programCounter: registers.PC)
            let tempResult =  bus.readByte(address: registers.HL)
            let WZH = UInt8((registers.WZ >> 8) & 0xFF)
            let tempX : UInt8 = WZH & 0x08
            let tempY : UInt8 = WZH & 0x20
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (tempResult & 0x08) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (tempResult & 0x08) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 12
            incrementR(opcodeCount:2)
        case 0x5F: // BIT 3,A - CB 5F - Tests bit 3 of A
            logInstructionDetails(instructionDetails: "BIT 3,A", opcode: [0xCB,0x5F], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.A & z80Flags.X.rawValue
            let tempY : UInt8 = registers.A & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.A & 0x08) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.A & 0x08) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x60: // BIT 4,B - CB 60 - Tests bit 4 of B
            logInstructionDetails(instructionDetails: "BIT 4,B", opcode: [0xCB,0x60], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.B & z80Flags.X.rawValue
            let tempY : UInt8 = registers.B & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.B & 0x10) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.B & 0x10) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x61: // BIT 4,C - CB 61 - Tests bit 4 of C
            logInstructionDetails(instructionDetails: "BIT 4,C", opcode: [0xCB,0x61], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.C & z80Flags.X.rawValue
            let tempY : UInt8 = registers.C & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.C & 0x10) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.C & 0x10) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x62: // BIT 4,D - CB 62 - Tests bit 4 of D
            logInstructionDetails(instructionDetails: "BIT 4,D", opcode: [0xCB,0x62], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.D & z80Flags.X.rawValue
            let tempY : UInt8 = registers.D & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.D & 0x10) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.D & 0x10) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x63: // BIT 4,E - CB 63 - Tests bit 4 of E
            logInstructionDetails(instructionDetails: "BIT 4,E", opcode: [0xCB,0x63], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.E & z80Flags.X.rawValue
            let tempY : UInt8 = registers.E & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.E & 0x10) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.E & 0x10) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x64: // BIT 4,H - CB 64 - Tests bit 4 of H
            logInstructionDetails(instructionDetails: "BIT 4,H", opcode: [0xCB,0x64], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.H & z80Flags.X.rawValue
            let tempY : UInt8 = registers.H & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.H & 0x10) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.H & 0x10) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x65: // BIT 4,L - CB 65 - Tests bit 4 of L
            logInstructionDetails(instructionDetails: "BIT 4,L", opcode: [0xCB,0x65], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.L & z80Flags.X.rawValue
            let tempY : UInt8 = registers.L & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.L & 0x10) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.L & 0x10) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x66: // BIT 4,(HL) - CB 66 - Tests bit 4 of (HL)
            logInstructionDetails(instructionDetails: "BIT 4,(HL)", opcode: [0xCB,0x66], programCounter: registers.PC)
            let tempResult =  bus.readByte(address: registers.HL)
            let WZH = UInt8((registers.WZ >> 8) & 0xFF)
            let tempX : UInt8 = WZH & 0x08
            let tempY : UInt8 = WZH & 0x20
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (tempResult & 0x10) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (tempResult & 0x10) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 12
            incrementR(opcodeCount:2)
        case 0x67: // BIT 4,A - CB 67 - Tests bit 4 of A
            logInstructionDetails(instructionDetails: "BIT 4,A", opcode: [0xCB,0x67], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.A & z80Flags.X.rawValue
            let tempY : UInt8 = registers.A & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.A & 0x10) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.A & 0x10) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x68: // BIT 5,B - CB 68 - Tests bit 5 of B
            logInstructionDetails(instructionDetails: "BIT 5,B", opcode: [0xCB,0x68], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.B & z80Flags.X.rawValue
            let tempY : UInt8 = registers.B & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.B & 0x20) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.B & 0x20) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x69: // BIT 5,C - CB 69 - Tests bit 5 of C
            logInstructionDetails(instructionDetails: "BIT 5,C", opcode: [0xCB,0x69], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.C & z80Flags.X.rawValue
            let tempY : UInt8 = registers.C & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.C & 0x20) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.C & 0x20) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6A: // BIT 5,D - CB 6A - Tests bit 5 of D
            logInstructionDetails(instructionDetails: "BIT 5,D", opcode: [0xCB,0x6A], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.D & z80Flags.X.rawValue
            let tempY : UInt8 = registers.D & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.D & 0x020) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.D & 0x20) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6B: // BIT 5,E - CB 6B - Tests bit 5 of E
            logInstructionDetails(instructionDetails: "BIT 5,E", opcode: [0xCB,0x6B], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.E & z80Flags.X.rawValue
            let tempY : UInt8 = registers.E & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.E & 0x20) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.E & 0x20) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6C: // BIT 5,H - CB 6C - Tests bit 5 of H
            logInstructionDetails(instructionDetails: "BIT 5,H", opcode: [0xCB,0x6C], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.H & z80Flags.X.rawValue
            let tempY : UInt8 = registers.H & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.H & 0x20) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.H & 0x20) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6D: // BIT 5,L - CB 6D - Tests bit 5 of L
            logInstructionDetails(instructionDetails: "BIT 5,L", opcode: [0xCB,0x6D], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.L & z80Flags.X.rawValue
            let tempY : UInt8 = registers.L & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.L & 0x20) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.L & 0x20) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6E: // BIT 5,(HL) - CB 6E - Tests bit 5 of (HL)
            logInstructionDetails(instructionDetails: "BIT 5,(HL)", opcode: [0xCB,0x6E], programCounter: registers.PC)
            let tempResult =  bus.readByte(address: registers.HL)
            let WZH = UInt8((registers.WZ >> 8) & 0xFF)
            let tempX : UInt8 = WZH & 0x08
            let tempY : UInt8 = WZH & 0x20
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (tempResult & 0x20) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (tempResult & 0x20) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 12
            incrementR(opcodeCount:2)
        case 0x6F: // BIT 5,A - CB 6F - Tests bit 5 of A
            logInstructionDetails(instructionDetails: "BIT 5,A", opcode: [0xCB,0x6F], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.A & z80Flags.X.rawValue
            let tempY : UInt8 = registers.A & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.A & 0x20) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.A & 0x20) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x70: // BIT 6,B - CB 70 - Tests bit 6 of B
            logInstructionDetails(instructionDetails: "BIT 6,B", opcode: [0xCB,0x70], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.B & z80Flags.X.rawValue
            let tempY : UInt8 = registers.B & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.B & 0x40) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.B & 0x40) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x71: // BIT 6,C - CB 71 - Tests bit 6 of C
            logInstructionDetails(instructionDetails: "BIT 6,C", opcode: [0xCB,0x71], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.C & z80Flags.X.rawValue
            let tempY : UInt8 = registers.C & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.C & 0x40) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.C & 0x40) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x72: // BIT 6,D - CB 72 - Tests bit 6 of D
            logInstructionDetails(instructionDetails: "BIT 6,D", opcode: [0xCB,0x72], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.D & z80Flags.X.rawValue
            let tempY : UInt8 = registers.D & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.D & 0x40) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.D & 0x40) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x73: // BIT 6,E - CB 73 - Tests bit 6 of E
            logInstructionDetails(instructionDetails: "BIT 6,E", opcode: [0xCB,0x73], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.E & z80Flags.X.rawValue
            let tempY : UInt8 = registers.E & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.E & 0x40) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.E & 0x40) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x74: // BIT 6,H - CB 74 - Tests bit 6 of H
            logInstructionDetails(instructionDetails: "BIT 6,H", opcode: [0xCB,0x74], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.H & z80Flags.X.rawValue
            let tempY : UInt8 = registers.H & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.H & 0x40) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.H & 0x40) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x75: // BIT 6,L - CB 75 - Tests bit 6 of L
            logInstructionDetails(instructionDetails: "BIT 6,L", opcode: [0xCB,0x75], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.L & z80Flags.X.rawValue
            let tempY : UInt8 = registers.L & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.L & 0x40) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.L & 0x40) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x76: // BIT 6,(HL) - CB 76 - Tests bit 6 of (HL)
            logInstructionDetails(instructionDetails: "BIT 6,(HL)", opcode: [0xCB,0x76], programCounter: registers.PC)
            let tempResult =  bus.readByte(address: registers.HL)
            let WZH = UInt8((registers.WZ >> 8) & 0xFF)
            let tempX : UInt8 = WZH & 0x08
            let tempY : UInt8 = WZH & 0x20
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (tempResult & 0x40) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (tempResult & 0x40) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 12
            incrementR(opcodeCount:2)
        case 0x77: // BIT 6,A - CB 77 - Tests bit 6 of A
            logInstructionDetails(instructionDetails: "BIT 6,A", opcode: [0xCB,0x77], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.A & z80Flags.X.rawValue
            let tempY : UInt8 = registers.A & z80Flags.Y.rawValue
            let tempSign : UInt8 = 0x00 // 0x80 for Bit 7, 0x00 otherwise
            let tempZero : UInt8 = (registers.A & 0x40) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.A & 0x40) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x78: // BIT 7,B - CB 78 - Tests bit 7 of B
            logInstructionDetails(instructionDetails: "BIT 7,B", opcode: [0xCB,0x78], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.B & z80Flags.X.rawValue
            let tempY : UInt8 = registers.B & z80Flags.Y.rawValue
            let tempSign : UInt8 = (registers.B & 0x80) == 0 ? 0x00 : 0x80
            let tempZero : UInt8 = (registers.B & 0x80) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.B & 0x80) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x79: // BIT 7,C - CB 79 - Tests bit 7 of C
            logInstructionDetails(instructionDetails: "BIT 7,C", opcode: [0xCB,0x79], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.C & z80Flags.X.rawValue
            let tempY : UInt8 = registers.C & z80Flags.Y.rawValue
            let tempSign : UInt8 = (registers.C & 0x80) == 0 ? 0x00 : 0x80
            let tempZero : UInt8 = (registers.C & 0x80) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.C & 0x80) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7A: // BIT 7,D - CB 7A - Tests bit 7 of D
            logInstructionDetails(instructionDetails: "BIT 7,D", opcode: [0xCB,0x7A], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.D & z80Flags.X.rawValue
            let tempY : UInt8 = registers.D & z80Flags.Y.rawValue
            let tempSign : UInt8 = (registers.D & 0x80) == 0 ? 0x00 : 0x80
            let tempZero : UInt8 = (registers.D & 0x80) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.D & 0x80) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7B: // BIT 7,E - CB 7B - Tests bit 7 of E
            logInstructionDetails(instructionDetails: "BIT 7,E", opcode: [0xCB,0x7B], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.E & z80Flags.X.rawValue
            let tempY : UInt8 = registers.E & z80Flags.Y.rawValue
            let tempSign : UInt8 = (registers.E & 0x80) == 0 ? 0x00 : 0x80
            let tempZero : UInt8 = (registers.E & 0x80) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.E & 0x80) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7C: // BIT 7,H - CB 7C - Tests bit 7 of H
            logInstructionDetails(instructionDetails: "BIT 7,H", opcode: [0xCB,0x7C], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.H & z80Flags.X.rawValue
            let tempY : UInt8 = registers.H & z80Flags.Y.rawValue
            let tempSign : UInt8 = (registers.H & 0x80) == 0 ? 0x00 : 0x80
            let tempZero : UInt8 = (registers.H & 0x80) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.H & 0x80) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7D: // BIT 7,L - CB 7D - Tests bit 7 of L
            logInstructionDetails(instructionDetails: "BIT 7,L", opcode: [0xCB,0x7D], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.L & z80Flags.X.rawValue
            let tempY : UInt8 = registers.L & z80Flags.Y.rawValue
            let tempSign : UInt8 = (registers.L & 0x80) == 0 ? 0x00 : 0x80
            let tempZero : UInt8 = (registers.L & 0x80) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.L & 0x80) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7E: // BIT 7,(HL) - CB 7E - Tests bit 7 of (HL)
            logInstructionDetails(instructionDetails: "BIT 7,(HL)", opcode: [0xCB,0x7E], programCounter: registers.PC)
            let tempResult =  bus.readByte(address: registers.HL)
            let WZH = UInt8((registers.WZ >> 8) & 0xFF)
            let tempX : UInt8 = WZH & 0x08
            let tempY : UInt8 = WZH & 0x20
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempSign : UInt8 = (tempResult & 0x80) == 0 ? 0x00 : 0x80
            let tempZero : UInt8 = (tempResult & 0x80) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (tempResult & 0x80) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 12
            incrementR(opcodeCount:2)
        case 0x7F: // BIT 7,A - CB 7F - Tests bit 7 of A
            logInstructionDetails(instructionDetails: "BIT 7,A", opcode: [0xCB,0x7F], programCounter: registers.PC)
            let tempCarry : UInt8 = registers.F & z80Flags.Carry.rawValue
            let tempX : UInt8 = registers.A & z80Flags.X.rawValue
            let tempY : UInt8 = registers.A & z80Flags.Y.rawValue
            let tempSign : UInt8 = (registers.A & 0x80) == 0 ? 0x00 : 0x80
            let tempZero : UInt8 = (registers.A & 0x80) == 0 ? 0x40 : 0x00
            let tempParityOverflow : UInt8 = (registers.A & 0x80) == 0 ? 0x04 : 0x00
            let tempNegative : UInt8 = 0x00
            let tempHalfCarry : UInt8 = z80Flags.HalfCarry.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.Q = registers.F
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x80: // RES 0,B - CB 80 - Resets bit 0 of B
            logInstructionDetails(instructionDetails: "RES 0,B", opcode: [0xCB,0x80], programCounter: registers.PC)
            registers.B = registers.B & 0b11111110
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x81: // RES 0,C - CB 81 - Resets bit 0 of C
            logInstructionDetails(instructionDetails: "RES 0,C", opcode: [0xCB,0x81], programCounter: registers.PC)
            registers.C = registers.C & 0b11111110
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x82: // RES 0,D - CB 82 - Resets bit 0 of D
            logInstructionDetails(instructionDetails: "RES 0,D", opcode: [0xCB,0x82], programCounter: registers.PC)
            registers.D = registers.D & 0b11111110
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x83: // RES 0,E - CB 83 - Resets bit 0 of E
            logInstructionDetails(instructionDetails: "RES 0,E", opcode: [0xCB,0x83], programCounter: registers.PC)
            registers.E = registers.E & 0b11111110
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x84: // RES 0,H - CB 84 - Resets bit 0 of H
            logInstructionDetails(instructionDetails: "RES 0,H", opcode: [0xCB,0x84], programCounter: registers.PC)
            registers.H = registers.H & 0b11111110
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x85: // RES 0,L - CB 85 - Resets bit 0 of L
            logInstructionDetails(instructionDetails: "RES 0,L", opcode: [0xCB,0x85], programCounter: registers.PC)
            registers.L = registers.L & 0b11111110
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x86: // RES 0,(HL) - CB 86 - Resets bit 0 of (HL)
            logInstructionDetails(instructionDetails: "RES 0,(HL)", opcode: [0xCB,0x86], programCounter: registers.PC)
            let tempResult =  bus.readByte(address: registers.HL) & 0b11111110
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x87: // RES 0,A - CB 87 - Resets bit 0 of A
            logInstructionDetails(instructionDetails: "RES 0,A", opcode: [0xCB,0x87], programCounter: registers.PC)
            registers.A = registers.A & 0b11111110
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x88: // RES 1,B - CB 88 - Resets bit 1 of B
            logInstructionDetails(instructionDetails: "RES 1,B", opcode: [0xCB,0x88], programCounter: registers.PC)
            registers.B = registers.B & 0b11111101
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x89: // RES 1,C - CB 89 - Resets bit 1 of C
            logInstructionDetails(instructionDetails: "RES 1,C", opcode: [0xCB,0x89], programCounter: registers.PC)
            registers.C = registers.C & 0b11111101
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x8A: // RES 1,D - CB 8A - Resets bit 1 of D
            logInstructionDetails(instructionDetails: "RES 1,D", opcode: [0xCB,0x8A], programCounter: registers.PC)
            registers.D = registers.D & 0b11111101
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x8B: // RES 1,E - CB 8B - Resets bit 1 of E
            logInstructionDetails(instructionDetails: "RES 1,E", opcode: [0xCB,0x8B], programCounter: registers.PC)
            registers.E = registers.E & 0b11111101
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x8C: // RES 1,H - CB 8C - Resets bit 1 of H
            logInstructionDetails(instructionDetails: "RES 1,H", opcode: [0xCB,0x8C], programCounter: registers.PC)
            registers.H = registers.H & 0b11111101
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x8D: // RES 1,L - CB 8D - Resets bit 1 of L
            logInstructionDetails(instructionDetails: "RES 1,L", opcode: [0xCB,0x8D], programCounter: registers.PC)
            registers.L = registers.L & 0b11111101
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x8E: // RES 1,(HL) - CB 8E - Resets bit 1 of (HL)
            logInstructionDetails(instructionDetails: "RES 1,(HL)", opcode: [0xCB,0x8E], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) & 0b11111101
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x8F: // RES 1,A - CB 8F - Resets bit 1 of A
            logInstructionDetails(instructionDetails: "RES 1,A", opcode: [0xCB,0x8F], programCounter: registers.PC)
            registers.A = registers.A & 0b11111101
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x90: // RES 2,B - CB 90 - Resets bit 2 of B
            logInstructionDetails(instructionDetails: "RES 2,B", opcode: [0xCB,0x90], programCounter: registers.PC)
            registers.B = registers.B & 0b11111011
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x91: // RES 2,C - CB 91 - Resets bit 2 of C
            logInstructionDetails(instructionDetails: "RES 2,C", opcode: [0xCB,0x91], programCounter: registers.PC)
            registers.C = registers.C & 0b11111011
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x92: // RES 2,D - CB 92 - Resets bit 2 of D
            logInstructionDetails(instructionDetails: "RES 2,D", opcode: [0xCB,0x92], programCounter: registers.PC)
            registers.D = registers.D & 0b11111011
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x93: // RES 2,E - CB 93 - Resets bit 2 of E
            logInstructionDetails(instructionDetails: "RES 2,E", opcode: [0xCB,0x93], programCounter: registers.PC)
            registers.E = registers.E & 0b11111011
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x94: // RES 2,H - CB 94 - Resets bit 2 of H
            logInstructionDetails(instructionDetails: "RES 2,H", opcode: [0xCB,0x94], programCounter: registers.PC)
            registers.H = registers.H & 0b11111011
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x95: // RES 2,L - CB 95 - Resets bit 2 of L
            logInstructionDetails(instructionDetails: "RES 2,L", opcode: [0xCB,0x95], programCounter: registers.PC)
            registers.L = registers.L & 0b11111011
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x96: // RES 2,(HL) - CB 96 - Resets bit 2 of (HL)
            logInstructionDetails(instructionDetails: "RES 2,(HL)", opcode: [0xCB,0x96], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) & 0b11111011
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x97: // RES 2,A - CB 97 - Resets bit 2 of A
            logInstructionDetails(instructionDetails: "RES 2,A", opcode: [0xCB,0x97], programCounter: registers.PC)
            registers.A = registers.A & 0b11111011
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x98: // RES 3,B - CB 98 - Resets bit 3 of B
            logInstructionDetails(instructionDetails: "RES 3,B", opcode: [0xCB,0x98], programCounter: registers.PC)
            registers.B = registers.B & 0b11110111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x99: // RES 3,C - CB 99 - Resets bit 3 of C
            logInstructionDetails(instructionDetails: "RES 3,C", opcode: [0xCB,0x99], programCounter: registers.PC)
            registers.C = registers.C & 0b11110111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9A: // RES 3,D - CB 9A - Resets bit 3 of D
            logInstructionDetails(instructionDetails: "RES 3,D", opcode: [0xCB,0x9A], programCounter: registers.PC)
            registers.D = registers.D & 0b11110111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9B: // RES 3,E - CB 9B - Resets bit 3 of E
            logInstructionDetails(instructionDetails: "RES 3,E", opcode: [0xCB,0x9B], programCounter: registers.PC)
            registers.E = registers.E & 0b11110111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9C: // RES 3,H - CB 9C - Resets bit 3 of H
            logInstructionDetails(instructionDetails: "RES 3,H", opcode: [0xCB,0x9C], programCounter: registers.PC)
            registers.H = registers.H & 0b11110111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9D: // RES 3,L - CB 9D - Resets bit 3 of L
            logInstructionDetails(instructionDetails: "RES 3,L", opcode: [0xCB,0x9D], programCounter: registers.PC)
            registers.L = registers.L & 0b11110111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9E: // RES 3,(HL) - CB 9E - Resets bit 3 of (HL)
            logInstructionDetails(instructionDetails: "RES 3,(HL)", opcode: [0xCB,0x9E], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) & 0b11110111
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x9F: // RES 3,A - CB 9F - Resets bit 3 of A
            logInstructionDetails(instructionDetails: "RES 3,A", opcode: [0xCB,0x9F], programCounter: registers.PC)
            registers.A = registers.A & 0b11110111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xA0: // RES 4,B - CB A0 - Resets bit 4 of B
            logInstructionDetails(instructionDetails: "RES 4,B", opcode: [0xCB,0xA0], programCounter: registers.PC)
            registers.B = registers.B & 0b11101111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xA1: // RES 4,C - CB A1 - Resets bit 4 of C
            logInstructionDetails(instructionDetails: "RES 4,C", opcode: [0xCB,0xA1], programCounter: registers.PC)
            registers.C = registers.C & 0b11101111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xA2: // RES 4,D - CB A2 - Resets bit 4 of D
            logInstructionDetails(instructionDetails: "RES 4,D", opcode: [0xCB,0xA2], programCounter: registers.PC)
            registers.D = registers.D & 0b11101111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xA3: // RES 4,E - CB A3 - Resets bit 4 of E
            logInstructionDetails(instructionDetails: "RES 4,E", opcode: [0xCB,0xA3], programCounter: registers.PC)
            registers.E = registers.E & 0b11101111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xA4: // RES 4,H - CB A4 - Resets bit 4 of H
            logInstructionDetails(instructionDetails: "RES 4,H", opcode: [0xCB,0xA4], programCounter: registers.PC)
            registers.H = registers.H & 0b11101111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xA5: // RES 4,L - CB A5 - Resets bit 4 of L
            logInstructionDetails(instructionDetails: "RES 4,L", opcode: [0xCB,0xA5], programCounter: registers.PC)
            registers.L = registers.L & 0b11101111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xA6: // RES 4,(HL) - CB A6 - Resets bit 4 of (HL)
            logInstructionDetails(instructionDetails: "RES 4,(HL)", opcode: [0xCB,0xA6], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) & 0b11101111
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xA7: // RES 4,A - CB A7 - Resets bit 4 of A
            logInstructionDetails(instructionDetails: "RES 4,A", opcode: [0xCB,0xA7], programCounter: registers.PC)
            registers.A = registers.A & 0b11101111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xA8: // RES 5,B - CB A8 - Resets bit 5 of B
            logInstructionDetails(instructionDetails: "RES 5,B", opcode: [0xCB,0xA8], programCounter: registers.PC)
            registers.B = registers.B & 0b11011111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xA9: // RES 5,C - CB A9 - Resets bit 5 of C
            logInstructionDetails(instructionDetails: "RES 5,C", opcode: [0xCB,0xA9], programCounter: registers.PC)
            registers.C = registers.C & 0b11011111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xAA: // RES 5,D - CB AA - Resets bit 5 of D
            logInstructionDetails(instructionDetails: "RES 5,D", opcode: [0xCB,0xAA], programCounter: registers.PC)
            registers.D = registers.D & 0b11011111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xAB: // RES 5,E - CB AB - Resets bit 5 of E
            logInstructionDetails(instructionDetails: "RES 5,E", opcode: [0xCB,0xAB], programCounter: registers.PC)
            registers.E = registers.E & 0b11011111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xAC: // RES 5,H - CB AC - Resets bit 5 of H
            logInstructionDetails(instructionDetails: "RES 5,H", opcode: [0xCB,0xAC], programCounter: registers.PC)
            registers.H = registers.H & 0b11011111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xAD: // RES 5,L - CB AD - Resets bit 5 of L
            logInstructionDetails(instructionDetails: "RES 5,L", opcode: [0xCB,0xAD], programCounter: registers.PC)
            registers.L = registers.L & 0b11011111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xAE: // RES 5,(HL) - CB AE - Resets bit 5 of (HL)
            logInstructionDetails(instructionDetails: "RES 5,(HL)", opcode: [0xCB,0xAE], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) & 0b11011111
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xAF: // RES 5,A - CB AF - Resets bit 5 of A
            logInstructionDetails(instructionDetails: "RES 5,A", opcode: [0xCB,0xAF], programCounter: registers.PC)
            registers.A = registers.A & 0b11011111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB0: // RES 6,B - CB B0 - Resets bit 6 of B
            logInstructionDetails(instructionDetails: "RES 6,B", opcode: [0xCB,0xB0], programCounter: registers.PC)
            registers.B = registers.B & 0b10111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB1: // RES 6,C - CB B1 - Resets bit 6 of C
            logInstructionDetails(instructionDetails: "RES 6,C", opcode: [0xCB,0xB1], programCounter: registers.PC)
            registers.C = registers.C & 0b10111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB2: // RES 6,D - CB B2 - Resets bit 6 of D
            logInstructionDetails(instructionDetails: "RES 6,D", opcode: [0xCB,0xB2], programCounter: registers.PC)
            registers.D = registers.D & 0b10111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB3: // RES 6,E - CB B3 - Resets bit 6 of E
            logInstructionDetails(instructionDetails: "RES 6,E", opcode: [0xCB,0xB3], programCounter: registers.PC)
            registers.E = registers.E & 0b10111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB4: // RES 6,H - CB B4 - Resets bit 6 of H
            logInstructionDetails(instructionDetails: "RES 6,H", opcode: [0xCB,0xB4], programCounter: registers.PC)
            registers.H = registers.H & 0b10111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB5: // RES 6,L - CB B5 - Resets bit 6 of L
            logInstructionDetails(instructionDetails: "RES 6,L", opcode: [0xCB,0xB5], programCounter: registers.PC)
            registers.L = registers.L & 0b10111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB6: // RES 6,(HL) - CB B6 - Resets bit 6 of (HL)
            logInstructionDetails(instructionDetails: "RES 6,(HL)", opcode: [0xCB,0xB6], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) & 0b10111111
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xB7: // RES 6,A - CB B7 - Resets bit 6 of A
            logInstructionDetails(instructionDetails: "RES 6,A", opcode: [0xCB,0xB7], programCounter: registers.PC)
            registers.A = registers.A & 0b10111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB8: // RES 7,B - CB B8 - Resets bit 7 of B
            logInstructionDetails(instructionDetails: "RES 7,B", opcode: [0xCB,0xB8], programCounter: registers.PC)
            registers.B = registers.B & 0b01111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB9: // RES 7,C - CB B9 - Resets bit 7 of C
            logInstructionDetails(instructionDetails: "RES 7,C", opcode: [0xCB,0xB9], programCounter: registers.PC)
            registers.C = registers.C & 0b01111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xBA: // RES 7,D - CB BA - Resets bit 7 of D
            logInstructionDetails(instructionDetails: "RES 7,D", opcode: [0xCB,0xBA], programCounter: registers.PC)
            registers.D = registers.D & 0b01111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xBB: // RES 7,E - CB BB - Resets bit 7 of E
            logInstructionDetails(instructionDetails: "RES 7,E", opcode: [0xCB,0xBB], programCounter: registers.PC)
            registers.E = registers.E & 0b01111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xBC: // RES 7,H - CB BC - Resets bit 7 of H
            logInstructionDetails(instructionDetails: "RES 7,H", opcode: [0xCB,0xBC], programCounter: registers.PC)
            registers.H = registers.H & 0b01111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xBD: // RES 7,L - CB BD - Resets bit 7 of L
            logInstructionDetails(instructionDetails: "RES 7,L", opcode: [0xCB,0xBD], programCounter: registers.PC)
            registers.L = registers.L & 0b01111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xBE: // RES 7,(HL) - CB BE - Resets bit 7 of (HL)
            logInstructionDetails(instructionDetails: "RES 7,(HL)", opcode: [0xCB,0xBE], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) & 0b01111111
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xBF: // RES 7,A - CB BF - Resets bit 7 of A
            logInstructionDetails(instructionDetails: "RES 7,A", opcode: [0xCB,0xBF], programCounter: registers.PC)
            registers.A = registers.A & 0b01111111
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xC0: // SET 0,B - CB C0 - Sets bit 0 of B
            logInstructionDetails(instructionDetails: "SET 0,B", opcode: [0xCB,0xC0], programCounter: registers.PC)
            registers.B = registers.B | 0b00000001
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xC1: // SET 0,C - CB C1 - Sets bit 0 of C
            logInstructionDetails(instructionDetails: "SET 0,C", opcode: [0xCB,0xC1], programCounter: registers.PC)
            registers.C = registers.C | 0b00000001
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xC2: // SET 0,D - CB C2 - Sets bit 0 of D
            logInstructionDetails(instructionDetails: "SET 0,D", opcode: [0xCB,0xC2], programCounter: registers.PC)
            registers.D = registers.D | 0b00000001
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xC3: // SET 0,E - CB C3 - Sets bit 0 of E
            logInstructionDetails(instructionDetails: "SET 0,E", opcode: [0xCB,0xC3], programCounter: registers.PC)
            registers.E = registers.E | 0b00000001
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xC4: // SET 0,H - CB C4 - Sets bit 0 of H
            logInstructionDetails(instructionDetails: "SET 0,H", opcode: [0xCB,0xC4], programCounter: registers.PC)
            registers.H = registers.H | 0b00000001
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xC5: // SET 0,L - CB C5 - Sets bit 0 of L
            logInstructionDetails(instructionDetails: "SET 0,L", opcode: [0xCB,0xC5], programCounter: registers.PC)
            registers.L = registers.L | 0b00000001
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xC6: // SET 0,(HL) - CB C6 - Sets bit 0 of (HL)
            logInstructionDetails(instructionDetails: "SET 0,(HL)", opcode: [0xCB,0xC6], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) | 0b00000001
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xC7: // SET 0,A - CB C7 - Sets bit 0 of A
            logInstructionDetails(instructionDetails: "SET 0,A", opcode: [0xCB,0xC7], programCounter: registers.PC)
            registers.A = registers.A | 0b00000001
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xC8: // SET 1,B - CB C8 - Sets bit 1 of B
            logInstructionDetails(instructionDetails: "SET 1,B", opcode: [0xCB,0xC8], programCounter: registers.PC)
            registers.B = registers.B | 0b00000010
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xC9: // SET 1,C - CB C9 - Sets bit 1 of C
            logInstructionDetails(instructionDetails: "SET 1,C", opcode: [0xCB,0xC9], programCounter: registers.PC)
            registers.C = registers.C | 0b00000010
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xCA: // SET 1,D - CB CA - Sets bit 1 of D
            logInstructionDetails(instructionDetails: "SET 1,D", opcode: [0xCB,0xCA], programCounter: registers.PC)
            registers.D = registers.D | 0b00000010
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xCB: // SET 1,E - CB CB - Sets bit 1 of E
            logInstructionDetails(instructionDetails: "SET 1,E", opcode: [0xCB,0xCB], programCounter: registers.PC)
            registers.E = registers.E | 0b00000010
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xCC: // SET 1,H - CB CC - Sets bit 1 of H
            logInstructionDetails(instructionDetails: "SET 1,H", opcode: [0xCB,0xCC], programCounter: registers.PC)
            registers.H = registers.H | 0b00000010
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xCD: // SET 1,L - CB CD - Sets bit 1 of L
            logInstructionDetails(instructionDetails: "SET 1,L", opcode: [0xCB,0xCD], programCounter: registers.PC)
            registers.L = registers.L | 0b00000010
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xCE: // SET 1,(HL) - CB CE - Sets bit 1 of (HL)
            logInstructionDetails(instructionDetails: "SET 1,(HL)", opcode: [0xCB,0xCE], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) | 0b00000010
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xCF: // SET 1,A - CB CF - Sets bit 1 of A
            logInstructionDetails(instructionDetails: "SET 1,A", opcode: [0xCB,0xCF], programCounter: registers.PC)
            registers.A = registers.A | 0b00000010
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xD0: // SET 2,B - CB D0 - Sets bit 2 of B
            logInstructionDetails(instructionDetails: "SET 2,B", opcode: [0xCB,0xD0], programCounter: registers.PC)
            registers.B = registers.B | 0b00000100
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xD1: // SET 2,C - CB D1 - Sets bit 2 of C
            logInstructionDetails(instructionDetails: "SET 2,C", opcode: [0xCB,0xD1], programCounter: registers.PC)
            registers.C = registers.C | 0b00000100
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xD2: // SET 2,D - CB D2 - Sets bit 2 of D
            logInstructionDetails(instructionDetails: "SET 2,D", opcode: [0xCB,0xD2], programCounter: registers.PC)
            registers.D = registers.D | 0b00000100
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xD3: // SET 2,E - CB D3 - Sets bit 2 of E
            logInstructionDetails(instructionDetails: "SET 2,E", opcode: [0xCB,0xD3], programCounter: registers.PC)
            registers.E = registers.E | 0b00000100
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xD4: // SET 2,H - CB D4 - Sets bit 2 of H
            logInstructionDetails(instructionDetails: "SET 2,H", opcode: [0xCB,0xD4], programCounter: registers.PC)
            registers.H = registers.H | 0b00000100
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xD5: // SET 2,L - CB D5 - Sets bit 2 of L
            logInstructionDetails(instructionDetails: "SET 2,L", opcode: [0xCB,0xD5], programCounter: registers.PC)
            registers.L = registers.L | 0b00000100
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xD6: // SET 2,(HL) - CB D6 - Sets bit 2 of (HL)
            logInstructionDetails(instructionDetails: "SET 2,(HL)", opcode: [0xCB,0xD6], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) | 0b00000100
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xD7: // SET 2,A - CB D7 - Sets bit 2 of A
            logInstructionDetails(instructionDetails: "SET 2,A", opcode: [0xCB,0xD7], programCounter: registers.PC)
            registers.A = registers.A | 0b00000100
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xD8: // SET 3,B - CB D8 - Sets bit 3 of B
            logInstructionDetails(instructionDetails: "SET 3,B", opcode: [0xCB,0xD8], programCounter: registers.PC)
            registers.B = registers.B | 0b00001000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xD9: // SET 3,C - CB D9 - Sets bit 3 of C
            logInstructionDetails(instructionDetails: "SET 3,C", opcode: [0xCB,0xD9], programCounter: registers.PC)
            registers.C = registers.C | 0b00001000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xDA: // SET 3,D - CB DA - Sets bit 3 of D
            logInstructionDetails(instructionDetails: "SET 3,D", opcode: [0xCB,0xDA], programCounter: registers.PC)
            registers.D = registers.D | 0b00001000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xDB: // SET 3,E - CB DB - Sets bit 3 of E
            logInstructionDetails(instructionDetails: "SET 3,E", opcode: [0xCB,0xDB], programCounter: registers.PC)
            registers.E = registers.E | 0b00001000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xDC: // SET 43,H - CB DC - Sets bit 3 of H
            logInstructionDetails(instructionDetails: "SET 3,H", opcode: [0xCB,0xDC], programCounter: registers.PC)
            registers.H = registers.H | 0b00001000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xDD: // SET 3,L - CB DD - Sets bit 3 of L
            logInstructionDetails(instructionDetails: "SET 3,L", opcode: [0xCB,0xDD], programCounter: registers.PC)
            registers.L = registers.L | 0b00001000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xDE: // SET 3,(HL) - CB DE - Sets bit 3 of (HL)
            logInstructionDetails(instructionDetails: "SET 3,(HL)", opcode: [0xCB,0xDE], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) | 0b00001000
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xDF: // SET 3,A - CB DF - Sets bit 3 of A
            logInstructionDetails(instructionDetails: "SET 3,A", opcode: [0xCB,0xDF], programCounter: registers.PC)
            registers.A = registers.A | 0b00001000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xE0: // SET 4,B - CB E0 - Sets bit 4 of B
            logInstructionDetails(instructionDetails: "SET 4,B", opcode: [0xCB,0xE0], programCounter: registers.PC)
            registers.B = registers.B | 0b00010000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xE1: // SET 4,C - CB E1 - Sets bit 4 of C
            logInstructionDetails(instructionDetails: "SET 4,C", opcode: [0xCB,0xE1], programCounter: registers.PC)
            registers.C = registers.C | 0b00010000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xE2: // SET 4,D - CB E2 - Sets bit 4 of D
            logInstructionDetails(instructionDetails: "SET 4,D", opcode: [0xCB,0xE2], programCounter: registers.PC)
            registers.D = registers.D | 0b00010000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xE3: // SET 4,E - CB E3 - Sets bit 4 of E
            logInstructionDetails(instructionDetails: "SET 4,E", opcode: [0xCB,0xE3], programCounter: registers.PC)
            registers.E = registers.E | 0b00010000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xE4: // SET 4,H - CB E4 - Sets bit 4 of H
            logInstructionDetails(instructionDetails: "SET 4,H", opcode: [0xCB,0xE4], programCounter: registers.PC)
            registers.H = registers.H | 0b00010000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xE5: // SET 4,L - CB E5 - Sets bit 4 of L
            logInstructionDetails(instructionDetails: "SET 4,L", opcode: [0xCB,0xE5], programCounter: registers.PC)
            registers.L = registers.L | 0b00010000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xE6: // SET 4,(HL) - CB E6 - Sets bit 4 of (HL)
            logInstructionDetails(instructionDetails: "SET 4,(HL)", opcode: [0xCB,0xE6], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) | 0b00010000
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xE7: // SET 4,A - CB E7 - Sets bit 4 of A
            logInstructionDetails(instructionDetails: "SET 4,A", opcode: [0xCB,0xE7], programCounter: registers.PC)
            registers.A = registers.A | 0b00010000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xE8: // SET 5,B - CB E8 - Sets bit 5 of B
            logInstructionDetails(instructionDetails: "SET 5,B", opcode: [0xCB,0xE8], programCounter: registers.PC)
            registers.B = registers.B | 0b00100000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xE9: // SET 5,C - CB E9 - Sets bit 5 of C
            logInstructionDetails(instructionDetails: "SET 5,C", opcode: [0xCB,0xE9], programCounter: registers.PC)
            registers.C = registers.C | 0b00100000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xEA: // SET 5,D - CB EA - Sets bit 5 of D
            logInstructionDetails(instructionDetails: "SET 5,D", opcode: [0xCB,0xEA], programCounter: registers.PC)
            registers.D = registers.D | 0b00100000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xEB: // SET 5,E - CB EB - Sets bit 5 of E
            logInstructionDetails(instructionDetails: "SET 5,E", opcode: [0xCB,0xEB], programCounter: registers.PC)
            registers.E = registers.E | 0b00100000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xEC: // SET 5,H - CB EC - Sets bit 5 of H
            logInstructionDetails(instructionDetails: "SET 5,H", opcode: [0xCB,0xEC], programCounter: registers.PC)
            registers.H = registers.H | 0b00100000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xED: // SET 5,L - CB ED - Sets bit 5 of L
            logInstructionDetails(instructionDetails: "SET 5,L", opcode: [0xCB,0xED], programCounter: registers.PC)
            registers.L = registers.L | 0b00100000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xEE: // SET 5,(HL) - CB EE - Sets bit 5 of (HL)
            logInstructionDetails(instructionDetails: "SET 5,(HL)", opcode: [0xCB,0xEE], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) | 0b00100000
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xEF: // SET 5,A - CB EF - Sets bit 5 of A
            logInstructionDetails(instructionDetails: "SET 5,A", opcode: [0xCB,0xEF], programCounter: registers.PC)
            registers.A = registers.A | 0b00100000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xF0: // SET 6,B - CB F0 - Sets bit 6 of B
            logInstructionDetails(instructionDetails: "SET 6,B", opcode: [0xCB,0xF0], programCounter: registers.PC)
            registers.B = registers.B | 0b01000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xF1: // SET 6,C - CB F1 - Sets bit 6 of C
            logInstructionDetails(instructionDetails: "SET 6,C", opcode: [0xCB,0xF1], programCounter: registers.PC)
            registers.C = registers.C | 0b01000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xF2: // SET 6,D - CB F2 - Sets bit 6 of D
            logInstructionDetails(instructionDetails: "SET 6,D", opcode: [0xCB,0xF2], programCounter: registers.PC)
            registers.D = registers.D | 0b01000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xF3: // SET 6,E - CB F3 - Sets bit 6 of E
            logInstructionDetails(instructionDetails: "SET 6,E", opcode: [0xCB,0xF3], programCounter: registers.PC)
            registers.E = registers.E | 0b01000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xF4: // SET 6,H - CB F4 - Sets bit 6 of H
            logInstructionDetails(instructionDetails: "SET 6,H", opcode: [0xCB,0xF4], programCounter: registers.PC)
            registers.H = registers.H | 0b01000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xF5: // SET 6,L - CB F5 - Sets bit 6 of L
            logInstructionDetails(instructionDetails: "SET 6,L", opcode: [0xCB,0xF5], programCounter: registers.PC)
            registers.L = registers.L | 0b01000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xF6: // SET 6,(HL) - CB F6 - Sets bit 6 of (HL)
            logInstructionDetails(instructionDetails: "SET 6,(HL)", opcode: [0xCB,0xF6], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) | 0b01000000
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xF7: // SET 6,A - CB F7 - Sets bit 6 of A
            logInstructionDetails(instructionDetails: "SET 6,A", opcode: [0xCB,0xF7], programCounter: registers.PC)
            registers.A = registers.A | 0b01000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xF8: // SET 7,B - CB F8 - Sets bit 7 of B
            logInstructionDetails(instructionDetails: "SET 7,B", opcode: [0xCB,0xF8], programCounter: registers.PC)
            registers.B = registers.B | 0b10000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xF9: // SET 7,C - CB F9 - Sets bit 7 of C
            logInstructionDetails(instructionDetails: "SET 7,C", opcode: [0xCB,0xF9], programCounter: registers.PC)
            registers.C = registers.C | 0b10000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xFA: // SET 7,D - CB FA - Sets bit 7 of D
            logInstructionDetails(instructionDetails: "SET 7,D", opcode: [0xCB,0xFA], programCounter: registers.PC)
            registers.D = registers.D | 0b10000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xFB: // SET 7,E - CB FB - Sets bit 7 of E
            logInstructionDetails(instructionDetails: "SET 7,E", opcode: [0xCB,0xFB], programCounter: registers.PC)
            registers.E = registers.E | 0b10000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xFC: // SET 7,H - CB FC - Sets bit 7 of H
            logInstructionDetails(instructionDetails: "SET 7,H", opcode: [0xCB,0xFC], programCounter: registers.PC)
            registers.H = registers.H | 0b10000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xFD: // SET 7,L - CB FD - Sets bit 7 of L
            logInstructionDetails(instructionDetails: "SET 7,L", opcode: [0xCB,0xFD], programCounter: registers.PC)
            registers.L = registers.L | 0b10000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xFE: // SET 7,(HL) - CB FE - Sets bit 7 of (HL)
            logInstructionDetails(instructionDetails: "SET 7,(HL)", opcode: [0xCB,0xFE], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL) | 0b10000000
            bus.writeByte(address: registers.HL, value: tempResult)
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xFF: // SET 7,A - CB FF - Sets bit 7 of A
            logInstructionDetails(instructionDetails: "SET 7,A", opcode: [0xCB,0xFF], programCounter: registers.PC)
            registers.A = registers.A | 0b10000000
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        default:
            logInstructionDetails(opcode: [0xCB,opcode2], programCounter: registers.PC)
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
            // Assuming this is correct behaviour - missing gap between 0x30-0x37 is undocumented SLL instructions
        }
        registers.PC = registers.PC &+ 2
    }
    
    private func executeDDInstructions(opcode2: UInt8, opcode3: UInt8, opcode4: UInt8)
    {
        switch opcode2
        {
        case 0x04: // Undocumented - INC B - DD 04 - Adds one to B
            // Stub
            logInstructionDetails(instructionDetails: "INC B", opcode: [0xDD,0x04], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x05: // Undocumented - DEC B - DD 05 - Subtracts one from B - DD 05
            // Stub
            logInstructionDetails(instructionDetails: "DEC B", opcode: [0xDD,0x05], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x06: // Undocumented - LD B,$n - DD 06 n - Loads $n into B - DD 6 $n
            // Stub
            logInstructionDetails(instructionDetails: "LD B,$n", opcode: [0xDD,0x06], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x09: // ADD IX,BC - DD 09 - The value of BC is added to IX
            logInstructionDetails(instructionDetails: "ADD IX,BC", opcode: [0xDD,0x09], programCounter: registers.PC)
            registers.WZ = registers.IX &+ 1
            let tempResult = registers.IX &+ registers.BC
            let halfCarry = ((registers.IX ^ registers.BC ^ tempResult) & 0x1000) != 0 ? z80Flags.HalfCarry.rawValue : 0
            let carrytempResult = UInt32(registers.IX) + UInt32(registers.BC)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.IX = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = (registers.F & ~z80Flags.HalfCarry.rawValue) | halfCarry
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.IXH & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.IXH & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.PC = registers.PC &+ 2
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x0C: // Undocumented - INC C - DD 0C - Adds one to C
            // Stub
            logInstructionDetails(instructionDetails: "INC C", opcode: [0xDD,0x0C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x0D: // Undocumented - DEC C - DD 0D - Subtracts one from C
            // Stub
            logInstructionDetails(instructionDetails: "DEC C", opcode: [0xDD,0x0D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x0E: // Undocumented - LD C,$n - DD 0E n - Loads n into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,$n", opcode: [0xDD,0x0E], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x14: // Undocumented - INC D - DD 14 - Adds one to D
            // Stub
            logInstructionDetails(instructionDetails: "INC D", opcode: [0xDD,0x14], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x15: // Undocumented - DEC D - DD 15 - Subtracts one from D
            // Stub
            logInstructionDetails(instructionDetails: "DEC D", opcode: [0xDD,0x15], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x16: // Undocumented - LD D,$n - DD 16 n - Loads $n into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,$n", opcode: [0xDD,0x16], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x19: // ADD IX,DE - DD 19 - The value of DE is added to IX
            logInstructionDetails(instructionDetails: "ADD IX,DE", opcode: [0xDD,0x19], programCounter: registers.PC)
            registers.WZ = registers.IX &+ 1
            let tempResult = registers.IX &+ registers.DE
            let halfCarry = ((registers.IX ^ registers.DE ^ tempResult) & 0x1000) != 0 ? z80Flags.HalfCarry.rawValue : 0
            let carrytempResult = UInt32(registers.IX) + UInt32(registers.DE)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.IX = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = (registers.F & ~z80Flags.HalfCarry.rawValue) | halfCarry
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.IXH & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.IXH & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.PC = registers.PC &+ 2
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x1C: // Undocumented - INC E - DD 1C - Adds one to E
            // Stub
            logInstructionDetails(instructionDetails: "INC E", opcode: [0xDD,0x1C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x1D: // Undocumented - DEC E - DD 1D - Subtracts one from E
            // Stub
            logInstructionDetails(instructionDetails: "DEC E", opcode: [0xDD,0x1D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x1E: // Undocumented - LD E,$n - DD 1E n - Loads n into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,$n", opcode: [0xDD,0x1E], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x21: // LD IX,$nn - DD 21 n n - Loads $nn into register IX
           logInstructionDetails(instructionDetails: "LD IX,$nn", opcode: [0xDD,0x21], values: [opcode3,opcode4], programCounter: registers.PC)
           registers.IX = UInt16(opcode4) << 8 | UInt16(opcode3)
           registers.PC = registers.PC &+ 4
           registers.Q = 0
           tStates = tStates + 14
           incrementR(opcodeCount:2)
        case 0x22: // LD ($nn),IX - DD 22 n n - Loads $nn into register IX
            logInstructionDetails(instructionDetails: "LD ($nn),IX", opcode: [0xDD,0x22], values: [opcode3,opcode4], programCounter: registers.PC)
            let tempResult =  UInt16(opcode4) << 8 | UInt16(opcode3)
            registers.WZ = tempResult &+ 1
            bus.writeByte(address: tempResult, value: registers.IXL)
            bus.writeByte(address: tempResult &+ 1, value: registers.IXH)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x23: // INC IX - DD 23 - Adds one to IX
           logInstructionDetails(instructionDetails: "INC IX", opcode: [0xDD,0x23], programCounter: registers.PC)
           registers.IX = registers.IX &+ 1
           registers.PC = registers.PC &+ 2
           registers.Q = 0
           tStates = tStates + 10
           incrementR(opcodeCount:2)
        case 0x24: // Undocumented - INC IXH - DD 24 - Adds one to IXH
            // Stub
            logInstructionDetails(instructionDetails: "INC IXH", opcode: [0xDD,0x24], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x25: // Undocumented - DEC IXH - DD 25 - Subtracts one from IXH
            // Stub
            logInstructionDetails(instructionDetails: "DEC IXH", opcode: [0xDD,0x25], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x26: // Undocumented - LD IHX,$n - DD 26 n - Loads $n into IXH
            // Stub
            logInstructionDetails(instructionDetails: "LD IHX,$n", opcode: [0xDD,0x26], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x29: // ADD IX,IX - DD 29 - The value of IX is added to IX
            logInstructionDetails(instructionDetails: "ADD IX,IX", opcode: [0xDD,0x29], programCounter: registers.PC)
            registers.WZ = registers.IX &+ 1
            let tempResult = registers.IX &+ registers.IX
            let halfCarry = ((registers.IX ^ registers.IX ^ tempResult) & 0x1000) != 0 ? z80Flags.HalfCarry.rawValue : 0
            let carrytempResult = UInt32(registers.IX) + UInt32(registers.IX)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.IX = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = (registers.F & ~z80Flags.HalfCarry.rawValue) | halfCarry
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.IXH & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.IXH & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.PC = registers.PC &+ 2
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x2A: // LD IX,($nn) - DD 2A n n - Loads the value pointed to by $nn into IX
            logInstructionDetails(instructionDetails: "LD IX,($nn)", opcode: [0xDD,0x2A], values: [opcode3,opcode4], programCounter: registers.PC)
            let tempResult = UInt16(opcode4) << 8 | UInt16(opcode3)
            registers.IXL = bus.readByte(address: tempResult)
            registers.IXH = bus.readByte(address: tempResult &+ 1)
            registers.WZ = tempResult &+ 1
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x2B: // DEC IX - DD 2B - Subtracts one from IX
           logInstructionDetails(instructionDetails: "DEC IX", opcode: [0xDD,0x2B], programCounter: registers.PC)
           registers.IX = registers.IX &- 1
           registers.PC = registers.PC &+ 2
           registers.Q = 0
           tStates = tStates + 10
           incrementR(opcodeCount:2)
        case 0x2C: // Undocumented - INC IXL - DD 2C - Adds one to IXL
            // Stub
            logInstructionDetails(instructionDetails: "INC IXL", opcode: [0xDD,0x2C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x2D: // Undocumented - DEC IXL - DD 2D - Subtracts one from IXL
            // Stub
            logInstructionDetails(instructionDetails: "DEC IXL", opcode: [0xDD,0x2D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x2E: // Undocumented - LD IXL,$n - DD 2E n - Loads n into IXL
            // Stub
            logInstructionDetails(instructionDetails: "LD IXL,$n", opcode: [0xDD,0x2E], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x34: // INC (IX+$d) - DD 34 d - Adds one to the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "INC (IX+$d)", opcode: [0xDD,0x34], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResult
            var previous = bus.readByte(address: tempResult)
            (previous,registers.F) = z80FastFlags.incHelper(operand: previous, currentFlags: registers.F)
            bus.writeByte(address: tempResult,value: previous)
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x35: // DEC (IX+$d) - DD 35 d - Subtracts one from the memory location pointed to by IX plus $d.
            logInstructionDetails(instructionDetails: "DEC (IX+$d)", opcode: [0xDD,0x35], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResult
            var previous = bus.readByte(address: tempResult)
            (previous,registers.F) = z80FastFlags.decHelper(operand: previous, currentFlags: registers.F)
            bus.writeByte(address: tempResult,value: previous)
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x36: // LD (IX+$d),$n - DD 36 d n - Stores $n to the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "LD (IX+$d),$n", opcode: [0xDD,0x36], values: [opcode3,opcode4], programCounter: registers.PC)
            let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResult
            bus.writeByte(address: tempResult, value: opcode4)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
       case 0x39: // ADD IX,SP - DD 39 - The value of SP is added to IX
            logInstructionDetails(instructionDetails: "ADD IX,SP", opcode: [0xDD,0x39], programCounter: registers.PC)
            registers.WZ = registers.IX &+ 1
            let tempResult = registers.IX &+ registers.SP
            let halfCarry = ((registers.IX ^ registers.SP ^ tempResult) & 0x1000) != 0 ? z80Flags.HalfCarry.rawValue : 0
            let carrytempResult = UInt32(registers.IX) + UInt32(registers.SP)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.IX = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = (registers.F & ~z80Flags.HalfCarry.rawValue) | halfCarry
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.IXH & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.IXH & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.PC = registers.PC &+ 2
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x3C: // Undocumented - INC A - DD 3C - Adds one to A
            // Stub
            logInstructionDetails(instructionDetails: "INC A", opcode: [0xDD,0x3C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x3D: // Undocumented - DEC A - DD 3D - Subtracts one from A
            // Stub
            logInstructionDetails(instructionDetails: "DEC A", opcode: [0xDD,0x3D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x3E: // Undocumented - LD A,$n - DD 3E n - Loads n into A.
            // Stub
            logInstructionDetails(instructionDetails: "LD A,$n", opcode: [0xDD,0x3E], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x40: // Undocumented - LD B,B - DD 40 - The contents of B are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,B", opcode: [0xDD,0x40], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x41: // Undocumented - LD B,C - DD 41 - The contents of C are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,C", opcode: [0xDD,0x41], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x42: // Undocumented - LD B,D - DD 42 - The contents of D are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,D", opcode: [0xDD,0x42], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x43: // Undocumented - LD B,E - DD 43 - The contents of E are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,E", opcode: [0xDD,0x43], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x44: // Undocumented - LD B,IXH - DD 44 - The contents of IXH are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,IXH", opcode: [0xDD,0x44], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x45: // Undocumented - LD B,IXL - DD 45 - The contents of IXL are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,IXL", opcode: [0xDD,0x45], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x46: // LD B,(IX+$d) - DD 46 d - Loads the value pointed to by IX plus $d into B
           logInstructionDetails(instructionDetails: "LD B,(IX+$d)", opcode: [0xDD,0x46], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
           registers.B = bus.readByte(address: tempResult)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
        case 0x47: // Undocumented - LD B,A - DD 47 - The contents of A are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,A", opcode: [0xDD,0x47], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x48: // Undocumented - LD C,B - DD 48 - The contents of B are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,B", opcode: [0xDD,0x48], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x49: // Undocumented - LD C,C - DD 49 - The contents of C are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,C", opcode: [0xDD,0x49], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4A: // Undocumented - LD C,D - DD 4A - The contents of D are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,D", opcode: [0xDD,0x4A], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4B: // Undocumented - LD C,E - DD 4B - The contents of E are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,E", opcode: [0xDD,0x4B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4C: // Undocumented - LD C,IXH - DD 4C - The contents of IXH are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,IXH", opcode: [0xDD,0x4C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4D: // Undocumented - LD C,IXL - DD 4D - The contents of IXL are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,IXL", opcode: [0xDD,0x4D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4E: // LD C,(IX+$d) - DD 4E d - Loads the value pointed to by IX plus $d into C
           logInstructionDetails(instructionDetails: "LD C,(IX+$d)", opcode: [0xDD,0x4E], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
            registers.C = bus.readByte(address: tempResult)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
        case 0x4F: // Undocumented - LD C,A - DD 4F - The contents of A are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,A", opcode: [0xDD,0x4F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x50: // Undocumented - LD D,B - DD 50 - The contents of B are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,B", opcode: [0xDD,0x50], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x51: // Undocumented - LD D,C - DD 51 - The contents of C are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,C", opcode: [0xDD,0x51], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x52: // Undocumented - LD D,D - DD 52 - The contents of D are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,D", opcode: [0xDD,0x52], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x53: // Undocumented - LD D,E - DD 53 - The contents of E are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,E", opcode: [0xDD,0x53], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x54: // Undocumented - LD D,IXH - DD 54 - The contents of IXH are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,IXH", opcode: [0xDD,0x54], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x55: // Undocumented - LD D,IXL - DD 55 - The contents of IXL are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,IXL", opcode: [0xDD,0x55], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x56: // LD D,(IX+$d) - DD 56 d - Loads the value pointed to by IX plus $d into D
           logInstructionDetails(instructionDetails: "LD D,(IX+$d)", opcode: [0xDD,0x46], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
            registers.D = bus.readByte(address: tempResult)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
        case 0x57: // Undocumented - LD D,A - DD 57 - The contents of A are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,A", opcode: [0xDD,0x57], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x58: // Undocumented - LD E,B - DD 58 - The contents of B are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,B", opcode: [0xDD,0x58], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x59: // Undocumented - LD E,C - DD 59 - The contents of C are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,C", opcode: [0xDD,0x59], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5A: // Undocumented - LD E,D - DD 5A - The contents of D are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,D", opcode: [0xDD,0x5A], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5B: // Undocumented - LD E,E - DD 5B - The contents of E are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,E", opcode: [0xDD,0x5B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5C: // Undocumented - LD E,IXH - DD 5C - The contents of IXH are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,IXH", opcode: [0xDD,0x5C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5D: // Undocumented - LD E,IXL - DD 5D - The contents of IXL are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,IXL", opcode: [0xDD,0x5D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
       case 0x5E: // LD E,(IX+$d) - DD 5E d - Loads the value pointed to by IX plus $d into E
           logInstructionDetails(instructionDetails: "LD E,(IX+$d)", opcode: [0xDD,0x5E], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
            registers.E = bus.readByte(address: tempResult)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
        case 0x5F: // Undocumented - LD E,A - DD 5F - The contents of A are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,A", opcode: [0xDD,0x5F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x60: // Undocumented - LD IXH,B - DD 60 - The contents of B are loaded into IXH
            // Stub
            logInstructionDetails(instructionDetails: "LD IXH,B", opcode: [0xDD,0x60], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x61: // Undocumented - LD IXH,C - DD 61 - The contents of C are loaded into IXH
            // Stub
            logInstructionDetails(instructionDetails: "LD IXH,C", opcode: [0xDD,0x61], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x62: // Undocumented - LD IXH,D - DD 62 - The contents of D are loaded into IXH
            // Stub
            logInstructionDetails(instructionDetails: "LD IXH,D", opcode: [0xDD,0x62], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x63: // Undocumented - LD IXH,E - DD 63 - The contents of E are loaded into IXH
            // Stub
            logInstructionDetails(instructionDetails: "LD IXH,E", opcode: [0xDD,0x63], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x64: // Undocumented - LD IXH,IXH - DD 64 - The contents of IXH are loaded into IXH
            // Stub
            logInstructionDetails(instructionDetails: "LD IXH,IXH", opcode: [0xDD,0x64], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x65: // Undocumented - LD IXH,IXL - DD 65 - The contents of IXH are loaded into IXH
            // Stub
            logInstructionDetails(instructionDetails: "LD IXH,IXL", opcode: [0xDD,0x65], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
       case 0x66: // LD H,(IX+$d) - DD 66 d - Loads the value pointed to by IX plus $d into H
           logInstructionDetails(instructionDetails: "LD H,(IX+$d)", opcode: [0xDD,0x66], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
            registers.H = bus.readByte(address: tempResult)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
        case 0x67: // Undocumented - LD IXH,A - DD 67 - The contents of A are loaded into IX
            // Stub
            logInstructionDetails(instructionDetails: "LD IXH,A", opcode: [0xDD,0x67], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x68: // Undocumented - LD IXL,B - DD 68 - The contents of B are loaded into IXL
            // Stub
            logInstructionDetails(instructionDetails: "LD IXL,B", opcode: [0xDD,0x68], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x69: // Undocumented - LD IXL,C - DD 69 - The contents of C are loaded into IXL
            // Stub
            logInstructionDetails(instructionDetails: "LD IXL,C", opcode: [0xDD,0x69], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6A: // Undocumented - LD IXL,D - DD 6A - The contents of D are loaded into IXL
            // Stub
            logInstructionDetails(instructionDetails: "LD IXL,D", opcode: [0xDD,0x6A], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6B: // Undocumented - LD IXL,E - DD 6B - The contents of E are loaded into IXL
            // Stub
            logInstructionDetails(instructionDetails: "LD IXL,E", opcode: [0xDD,0x6B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6C: // Undocumented - LD IXL,IXH - DD 6C - The contents of IXH are loaded into IXL
            // Stub
            logInstructionDetails(instructionDetails: "LD IXL,IXH", opcode: [0xDD,0x6C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6D: // Undocumented - LD IXL,IXL - DD 6D - The contents of IXL are loaded into IXL
            // Stub
            logInstructionDetails(instructionDetails: "LD IXL,IXL", opcode: [0xDD,0x6D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
       case 0x6E: // LD L,(IX+$d) - DD 6E d - Loads the value pointed to by IX plus $d into L
           logInstructionDetails(instructionDetails: "LD L,(IX+$d)", opcode: [0xDD,0x6E], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
            registers.L = bus.readByte(address: tempResult)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
        case 0x6F: // Undocumented - LD IXL,A - DD 6F - The contents of A are loaded into IXL
            // Stub
            logInstructionDetails(instructionDetails: "LD IXL,A", opcode: [0xDD,0x6F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
       case 0x70: // LD (IX+$d),B - DD 70 d - Stores B to the memory location pointed to by IX plus $d
           logInstructionDetails(instructionDetails: "LD (IX+$d),B", opcode: [0xDD,0x70], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
            bus.writeByte(address: tempResult, value: registers.B)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
       case 0x71: // LD (IX+$d),C - DD 71 d - Stores C to the memory location pointed to by IX plus $d
           logInstructionDetails(instructionDetails: "LD (IX+$d),C", opcode: [0xDD,0x71], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
            bus.writeByte(address: tempResult, value: registers.C)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
       case 0x72: // LD (IX+$d),D - DD 72 d - Stores D to the memory location pointed to by IX plus $d
           logInstructionDetails(instructionDetails: "LD (IX+$d),D", opcode: [0xDD,0x72], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
            bus.writeByte(address: tempResult, value: registers.D)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
       case 0x73: // LD (IX+$d),E - DD 73 d - Stores E to the memory location pointed to by IX plus $d
           logInstructionDetails(instructionDetails: "LD (IX+$d),E", opcode: [0xDD,0x73], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
            bus.writeByte(address: tempResult, value: registers.E)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
       case 0x74: // LD (IX+$d),H - DD 74 d - Stores H to the memory location pointed to by IX plus $d
           logInstructionDetails(instructionDetails: "LD (IX+$d),H", opcode: [0xDD,0x74], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
            bus.writeByte(address: tempResult, value: registers.H)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
       case 0x75: // LD (IX+$d),L - DD 75 d - Stores L to the memory location pointed to by IX plus $d
           logInstructionDetails(instructionDetails: "LD (IX+$d),L", opcode: [0xDD,0x36], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
            bus.writeByte(address: tempResult, value: registers.L)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
       case 0x77: // LD (IX+$d),A - DD 77 d - Stores A to the memory location pointed to by IX plus $d
           logInstructionDetails(instructionDetails: "LD (IX+$d),A", opcode: [0xDD,0x77], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
        bus.writeByte(address: tempResult, value: registers.A)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
        case 0x78: // Undocumented - LD A,B - DD 78 - The contents of B are loaded into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,B", opcode: [0xDD,0x78], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x79: // Undocumented - LD A,C - DD 79 - The contents of C are loaded into A. - DD 79
            // Stub
            logInstructionDetails(instructionDetails: "LD A,C", opcode: [0xDD,0x79], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7A: // Undocumented - LD A,D - DD 7A - The contents of D are loaded into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,D", opcode: [0xDD,0x7A], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7B: // Undocumented - LD A,E - DD 7B - The contents of E are loaded into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,E", opcode: [0xDD,0x7B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7C: // Undocumented - LD A,IXH - DD 7C - The contents of IXH are loaded into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,IXH", opcode: [0xDD,0x7C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7D: // Undocumented - LD A,IXL - DD 7D - The contents of IXL are loaded into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,IXL", opcode: [0xDD,0x7D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
       case 0x7E: // LD A,(IX+$d) - DD 7E d - Loads the value pointed to by IX plus $d into A
           logInstructionDetails(instructionDetails: "LD A,(IX+$d)", opcode: [0xDD,0x7E], values: [opcode3], programCounter: registers.PC)
           let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
           registers.WZ = tempResult
            registers.A = bus.readByte(address: tempResult)
           registers.PC = registers.PC &+ 3
           registers.Q = 0
           tStates = tStates + 19
           incrementR(opcodeCount:2)
        case 0x7F: // Undocumented - LD A,A - DD 7F - The contents of A are loaded into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,A", opcode: [0xDD,0x7F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x80: // Undocumented - ADD A,B - DD 80 - Adds B to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,B", opcode: [0xDD,0x80], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x81: // Undocumented - ADD A,C - DD 81 - Adds C to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,C", opcode: [0xDD,0x81], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x82: // Undocumented - ADD A,D - DD 82 - Adds D to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,D", opcode: [0xDD,0x82], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x83: // Undocumented - ADD A,E - DD 83 - Adds E to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,E", opcode: [0xDD,0x83], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x84: // Undocumented - ADD A,IXH - DD 84 - Adds IXH to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,IXH", opcode: [0xDD,0x84], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x85: // Undocumented - ADD A,IXL - DD 85 - Adds IXL to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,IXL", opcode: [0xDD,0x85], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
       case 0x86: // ADD A,(IX+$d) - DD 86 d - Adds the value pointed to by IX plus $d to A
            logInstructionDetails(instructionDetails: "ADD A,(IX+$d)", opcode: [0xDD,0x86], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResult
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: bus.readByte(address: tempResult))
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x87: // Undocumented - ADD A,A - DD 87 - Adds A to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,A", opcode: [0xDD,0x87], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x88: // Undocumented - ADC A,B - DD 88 - Adds B and the carry flag to A
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,B", opcode: [0xDD,0x88], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x89: // Undocumented - ADC A,C - DD 89 - Adds C and the carry flag to A
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,C", opcode: [0xDD,0x89], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x8A: // Undocumented - ADC A,D - DD 8A - Adds D and the carry flag to
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,D", opcode: [0xDD,0x8A], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x8B: // Undocumented - ADC A,E - DD 8B - Adds E and the carry flag to A
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,E", opcode: [0xDD,0x8B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x8C: // Undocumented - ADC A,IXH - DD 8C - Adds IXH and the carry flag to A
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,IXH", opcode: [0xDD,0x8C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x8D: // Undocumented - ADC A,IXL - DD 8D - Adds IXL and the carry flag to A
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,IXL", opcode: [0xDD,0x8D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
       case 0x8E: // ADC A,(IX+$d) - DD 8E d - Adds the value pointed to by IX plus $d and the carry flag to A
            logInstructionDetails(instructionDetails: "ADC A,(IX+$d)", opcode: [0xDD,0x8E], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResult
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: bus.readByte(address: tempResult), addCarry: addCarry)
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x8F: // Undocumented - ADC A,A - DD 8F - Adds A and the carry flag to A
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,A", opcode: [0xDD,0x8F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x90: // Undocumented - SUB B - DD 90 - Subtracts B from A
            // Stub
            logInstructionDetails(instructionDetails: "SUB B", opcode: [0xDD,0x90], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x91: // Undocumented - SUB C - DD 91 - Subtracts C from A
            // Stub
            logInstructionDetails(instructionDetails: "SUB C", opcode: [0xDD,0x90], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x92: // Undocumented - SUB D - DD 92 - Subtracts D from A
            // Stub
            logInstructionDetails(instructionDetails: "SUB D", opcode: [0xDD,0x92], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x93: // Undocumented - SUB E - DD 93 - Subtracts E from A
            // Stub
            logInstructionDetails(instructionDetails: "SUB E", opcode: [0xDD,0x93], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x94: // Undocumented - SUB IXH - DD 94 - Subtracts IXH from A
            // Stub
            logInstructionDetails(instructionDetails: "SUB IXH", opcode: [0xDD,0x94], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x95: // Undocumented - SUB IXL - DD 95 - Subtracts IXL from A
            // Stub
            logInstructionDetails(instructionDetails: "SUB IXL", opcode: [0xDD,0x95], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
       case 0x96: // SUB (IX+$d) - DD 96 d - Subtracts the value pointed to by IX plus $d from A
            logInstructionDetails(instructionDetails: "SUB (IX+$d)", opcode: [0xDD,0x96], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: bus.readByte(address: tempResultAddress))
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x97: // Undocumented - SUB A - DD 97 - Subtracts A from A
            // Stub
            logInstructionDetails(instructionDetails: "SUB A", opcode: [0xDD,0x97], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x98: // Undocumented - SBC A,B - DD 98 - Subtracts B and the carry flag from A
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,B", opcode: [0xDD,0x98], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x99: // Undocumented - SBC A,C - DD 99 - Subtracts C and the carry flag from A
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,C", opcode: [0xDD,0x99], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9A: // Undocumented - SBC A,D - DD 9A - Subtracts D and the carry flag from A
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,D", opcode: [0xDD,0x9A], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9B: // Undocumented - SBC A,E - DD 9B - Subtracts E and the carry flag from A
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,E", opcode: [0xDD,0x9B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9C: // Undocumented - SBC A,IXH - DD 9C - Subtracts IXH and the carry flag from A
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,IXH", opcode: [0xDD,0x9C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9D: // Undocumented - SBC A,IXL - DD 9D - Subtracts IXL and the carry flag from A
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,IXL", opcode: [0xDD,0x9D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
       case 0x9E: // SBC A,(IX+$d)- DD 9E d - Subtracts the value pointed to by IX plus $d and the carry flag from A
            logInstructionDetails(instructionDetails: "SBC A,(IX+$d)", opcode: [0xDD,0x9E], values: [opcode3], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempResult = bus.readByte(address: tempResultAddress)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: tempResult, addCarry: addCarry)
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x9F: // Undocumented - SBC A,A - DD 9F - Subtracts A and the carry flag from A
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,A", opcode: [0xDD,0x9F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xA0: // Undocumented - AND B - DD A0 - Bitwise AND on A with B
            // Stub
            logInstructionDetails(instructionDetails: "AND B", opcode: [0xDD,0xA0], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA1: // Undocumented - AND C - DD A1 - Bitwise AND on A with C
            // Stub
            logInstructionDetails(instructionDetails: "AND C", opcode: [0xDD,0xA1], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA2: // Undocumented - AND D - DD A2 - Bitwise AND on A with D
            // Stub
            logInstructionDetails(instructionDetails: "AND D", opcode: [0xDD,0xA2], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA3: // Undocumented - AND E - DD A3 - Bitwise AND on A with E
            // Stub
            logInstructionDetails(instructionDetails: "AND E", opcode: [0xDD,0xA3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA4: // Undocumented - AND IXH - DD A4 - Bitwise AND on A with IXH
            // Stub
            logInstructionDetails(instructionDetails: "AND IXH", opcode: [0xDD,0xA4], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA5: // Undocumented - AND IXL - DD A5 - Bitwise AND on A with IXL
            // Stub
            logInstructionDetails(instructionDetails: "AND IXL", opcode: [0xDD,0xA5], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
       case 0xA6: // AND (IX+$d) - DD A6 d - Bitwise AND on A with the value pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "AND (IX+$d)", opcode: [0xDD,0xA6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & bus.readByte(address: tempResultAddress), halfCarryMask: z80Flags.HalfCarry.rawValue)
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0xA7: // Undocumented - AND A - DD A7 - Bitwise AND on A with A
            // Stub
            logInstructionDetails(instructionDetails: "AND A", opcode: [0xDD,0xA7], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA8: // Undocumented - XOR B - DD A8 - Bitwise XOR on A with B - DD A8
            // Stub
            logInstructionDetails(instructionDetails: "XOR B", opcode: [0xDD,0xA8], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA9: // Undocumented - XOR C - DD A9 - Bitwise XOR on A with C
            // Stub
            logInstructionDetails(instructionDetails: "XOR C", opcode: [0xDD,0xA9], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xAA: // Undocumented - XOR D - DD AA - Bitwise XOR on A with D
            // Stub
            logInstructionDetails(instructionDetails: "XOR D", opcode: [0xDD,0xAA], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xAB: // Undocumented - XOR E - DD AB - Bitwise XOR on A with E
            // Stub
            logInstructionDetails(instructionDetails: "XOR E", opcode: [0xDD,0xAB], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xAC: // Undocumented - XOR IXH - DD AC - Bitwise XOR on A with IXH
            // Stub
            logInstructionDetails(instructionDetails: "XOR IXH", opcode: [0xDD,0xAC], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xAD: // Undocumented - XOR IXL - DD AD - Bitwise XOR on A with IXL
            // Stub
            logInstructionDetails(instructionDetails: "XOR IXL", opcode: [0xDD,0xAD], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
       case 0xAE: // XOR (IX+$d) - DD AE d - Bitwise XOR on A with the value pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "XOR (IX+$d)", opcode: [0xDD,0xAE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ bus.readByte(address: tempResultAddress))
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0xAF: // Undocumented - XOR A - DD AF - Bitwise XOR on A with A.
            // Stub
            logInstructionDetails(instructionDetails: "XOR A", opcode: [0xDD,0xAF], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xB0: // Undocumented - OR B - DD B0 - Bitwise OR on A with B
            // Stub
            logInstructionDetails(instructionDetails: "OR B", opcode: [0xDD,0xB0], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB1: // Undocumented - OR C - DD B1 - Bitwise OR on A with C
            // Stub
            logInstructionDetails(instructionDetails: "OR C", opcode: [0xDD,0xB1], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB2: // Undocumented - OR D - DD B2 - Bitwise OR on A with D
            // Stub
            logInstructionDetails(instructionDetails: "OR D", opcode: [0xDD,0xB2], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB3: // Undocumented - OR E - DD B3 - Bitwise OR on A with E
            // Stub
            logInstructionDetails(instructionDetails: "OR E", opcode: [0xDD,0xB3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB4: // Undocumented - OR IXH - DD B4 - Bitwise OR on A with IXH
            // Stub
            logInstructionDetails(instructionDetails: "OR IXH", opcode: [0xDD,0xB4], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB5: // Undocumented - OR IXL - DD B5 - Bitwise OR on A with IXL
            // Stub
            logInstructionDetails(instructionDetails: "OR IXL", opcode: [0xDD,0xB5], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
       case 0xB6: // OR (IX+$d) - DD B6 d - Bitwise OR on A with the value pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "OR (IX+$d)", opcode: [0xDD,0xB6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | bus.readByte(address: tempResultAddress))
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0xB7: // Undocumented - OR A - DD B7 - Bitwise OR on A with A
            // Stub
            logInstructionDetails(instructionDetails: "OR A", opcode: [0xDD,0xB7], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB8: // Undocumented - CP B - DD B8 - Subtracts B from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP B", opcode: [0xDD,0xB8], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xB9: // Undocumented - CP C - DD B9 - Subtracts C from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP C", opcode: [0xDD,0xB9], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xBA: // Undocumented - CP D - DD BA - Subtracts D from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP D", opcode: [0xDD,0xBA], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xBB: // Undocumented - CP E - DD BB - Subtracts E from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP E", opcode: [0xDD,0xBB], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xBC: // Undocumented - CP IXH - DD BC - Subtracts IXH from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP IXH", opcode: [0xDD,0xBC], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xBD: // Undocumented - CP IXL - DD BD - Subtracts IXL from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP IXL", opcode: [0xDD,0xBD], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
       case 0xBE: // CP (IX+$d) - DD BE d - Subtracts the value pointed to by IX plus $d from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP (IX+$d)", opcode: [0xDD,0xBE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempResult = bus.readByte(address: tempResultAddress)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: tempResult)
            registers.F = tempFlags
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from (IX+$d)
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from (IX+$d)
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0xBF: // Undocumented - CP A - DD BF - Subtracts A from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP A", opcode: [0xDD,0xBF], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xCB: executeDDCBInstructions(opcode3: opcode3, opcode4: opcode4)
        case 0xE1: // POP IX - DD E1 - The memory location pointed to by SP is stored into IXL and SP is incremented. The memory location pointed to by SP is stored into IXH and SP is incremented again
            logInstructionDetails(instructionDetails: "POP IX", opcode: [0xDD,0xE1], programCounter: registers.PC)
            registers.IXL = bus.readByte(address: registers.SP)
            registers.IXH = bus.readByte(address: registers.SP &+ 1)
            registers.SP = registers.SP &+ 2
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 14
            incrementR(opcodeCount:2)
        case 0xE3: // EX (SP),IX - DD E3 - Exchanges (SP) with IXL, and (SP+1) with IXH
            logInstructionDetails(instructionDetails: "EX (SP),IX", opcode: [0xDD,0xE3], programCounter: registers.PC)
            let tempSPCL = bus.readByte(address: registers.SP)
            let tempSPCH = bus.readByte(address: registers.SP &+ 1)
            bus.writeByte(address: registers.SP, value: registers.IXL)
            bus.writeByte(address: registers.SP &+ 1, value: registers.IXH)
            registers.IX = UInt16(tempSPCH) << 8 | UInt16(tempSPCL)
            registers.WZ = registers.IX
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE5: // PUSH IX - DD E5 - SP is decremented and IXH is stored into the memory location pointed to by SP. SP is decremented again and IXL is stored into the memory location pointed to by SP
            logInstructionDetails(instructionDetails: "PUSH IX", opcode: [0xDD,0xE5], programCounter: registers.PC)
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.IXH)
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.IXL)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xE9: // JP (IX) - DD E9 - Loads the value of IX into PC
            logInstructionDetails(instructionDetails: "JP (IX)", opcode: [0xDD,0xE9], programCounter: registers.PC)
            registers.PC = registers.IX
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xF9: // LD SP,IX - DD F9 - Loads the value of IX into SP
            logInstructionDetails(instructionDetails: "SP,IX", opcode: [0xDD,0xF9], programCounter: registers.PC)
            registers.SP = registers.IX
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:2)
        default:
            logInstructionDetails(opcode: [0xDD,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
            // Assuming this is correct behaviour - confirm what decodes in missing ranges in real z80
        }
    }
    
    private func executeDDCBInstructions(opcode3 : UInt8, opcode4: UInt8)
    {
        switch opcode4
        {
        case 0x00: // Undocumented - RLC (IX+$d),B - DD CB d 00 - The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IX+$d),B", opcode: [0xDD,0xCB,opcode3,0x00], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x01: // Undocumented - RLC (IX+$d),C - DD CB d 01 - The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IX+$d),C", opcode: [0xDD,0xCB,opcode3,0x01], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x02: // Undocumented - RLC (IX+$d),D - DD CB d 02 -The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IX+$d),D", opcode: [0xDD,0xCB,opcode3,0x02], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x03: // Undocumented - RLC (IX+$d),E - DD CB d 03 - The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IX+$d),E", opcode: [0xDD,0xCB,opcode3,0x03], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x04: // Undocumented - RLC (IX+$d),H - DD CB d 04 - The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IX+$d),H", opcode: [0xDD,0xCB,opcode3,0x04], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x05: // Undocumented - RLC (IX+$d),L - DD CB d 05 - The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IX+$d),L", opcode: [0xDD,0xCB,opcode3,0x05], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x06: // RLC (IX+$d) - DD CB d 06 - The contents of (IX+$d) are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0
            logInstructionDetails(instructionDetails: "RLC (IX+$d)", opcode: [0xDD,0xCB,opcode3,0x06], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let tempResult = (tempOldValue << 1) | (tempOldValue >> 7)
            let carry = (tempOldValue  & 0x80) >> 7
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | carry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x07: // Undocumented - RLC (IX+$d),A - DD CB d 07 - The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IX+$d),A", opcode: [0xDD,0xCB,opcode3,0x07], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x08: // Undocumented - RRC (IX+$d),B - DD CB d 08 - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IX+$d),B", opcode: [0xDD,0xCB,opcode3,0x08], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x09: // Undocumented - RRC (IX+$d),C - DD CB d 09 - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IX+$d),C", opcode: [0xDD,0xCB,opcode3,0x09], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x0A: // Undocumented - RRC (IX+$d),D - DD CB d 0A - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IX+$d),D", opcode: [0xDD,0xCB,opcode3,0x0A], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x0B: // Undocumented - RRC (IX+$d),E - DD CB d 0B - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IX+$d),E", opcode: [0xDD,0xCB,opcode3,0x0B], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x0C: // Undocumented - RRC (IX+$d),H - DD CB d 0C - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IX+$d),H", opcode: [0xDD,0xCB,opcode3,0x0C], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x0D: // Undocumented - RRC (IX+$d),L - DD CB d 0D - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IX+$d),L", opcode: [0xDD,0xCB,opcode3,0x0D], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x0E: // RRC (IX+$d) - DD CB d 0E - The contents of (IX+$d) are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7
            logInstructionDetails(instructionDetails: "RRC (IX+$d)", opcode: [0xDD,0xCB,opcode3,0x0E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let carry = tempOldValue & 0x01
            let tempResult = (tempOldValue << 7) | (tempOldValue >> 1)
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | carry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x0F: // Undocumented - RRC (IX+$d),A - DD CB d 0F - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IX+$d),A", opcode: [0xDD,0xCB,opcode3,0x0F], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x10: // Undocumented - RL (IX+$d),B - DD CB d 10 - The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RL (IX+$d),B", opcode: [0xDD,0xCB,opcode3,0x10], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x11: // Undocumented - RL (IX+$d),C - DD CB d 11 - The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RL (IX+$d),C", opcode: [0xDD,0xCB,opcode3,0x11], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x12: // Undocumented - RL (IX+$d),D - DD CB d 12 - The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RL (IX+$d),D", opcode: [0xDD,0xCB,opcode3,0x12], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x13: // Undocumented - RL (IX+$d),E - DD CB d 13 - The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RL (IX+$d),E", opcode: [0xDD,0xCB,opcode3,0x13], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x14: // Undocumented - RL (IX+$d),H - DD CB d 14 - The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RL (IX+$d),H", opcode: [0xDD,0xCB,opcode3,0x14], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x15: // Undocumented - RL (IX+$d),L - DD CB d 15 - The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RL (IX+$d),L", opcode: [0xDD,0xCB,opcode3,0x15], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x16: // RL (IX+$d) - DD CB d 16 - The contents of (IX+$d) are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.
            logInstructionDetails(instructionDetails: "RL (IX+$d)", opcode: [0xDD,0xCB,opcode3,0x16], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let newCarry = (tempOldValue & 0x80) >> 7
            let oldCarry = registers.F & 0x01
            let tempResult = ((tempOldValue << 1) & 0xFE) | oldCarry
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | newCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x17: // Undocumented - RL (IX+$d),A - DD CB d 17 - The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RL (IX+$d),A",opcode: [0xDD,0xCB,opcode3,0x17], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x18: // Undocumented - RR (IX+$d),B - DD CB d 18 - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RR (IX+$d),B", opcode: [0xDD,0xCB,opcode3,0x18], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x19: // Undocumented - RR (IX+$d),C - DD CB d 19 - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RR (IX+$d),C", opcode: [0xDD,0xCB,opcode3,0x19], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x1A: // Undocumented - RR (IX+$d),D - DD CB d 1A - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RR (IX+$d),D", opcode: [0xDD,0xCB,opcode3,0x1A], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x1B: // Undocumented - RR (IX+$d),E - DD CB d 1B - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RR (IX+$d),E", opcode: [0xDD,0xCB,opcode3,0x1B], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x1C: // Undocumented - RR (IX+$d),H - DD CB d 1C - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RR (IX+$d),H", opcode: [0xDD,0xCB,opcode3,0x1C], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x1D: // Undocumented - RR (IX+$d),L - DD CB d 1D - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RR (IX+$d),L", opcode: [0xDD,0xCB,opcode3,0x1D], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x1E: // RR (IX+$d) - DD CB d 1E - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7
            logInstructionDetails(instructionDetails: "RR (IX+$d)", opcode: [0xDD,0xCB,opcode3,0x1E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let newCarry = tempOldValue & 0x01
            let oldCarry = registers.F & 0x01
            let tempResult = (tempOldValue >> 1) | ( oldCarry << 7 )
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | newCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x1F: // Undocumented - RR (IX+$d),A - DD CB d 1F - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RR (IX+$d),A", opcode: [0xDD,0xCB,opcode3,0x1F], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x20: // Undocumented - SLA (IX+$d),B - DD CB d 20 - The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IX+$d),B", opcode: [0xDD,0xCB,opcode3,0x20], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x21: // Undocumented - SLA (IX+$d),C - DD CB d 21 - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IX+$d),C", opcode: [0xDD,0xCB,opcode3,0x21], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x22: // Undocumented - SLA (IX+$d),D  - DD CB d 22 - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IX+$d),D", opcode: [0xDD,0xCB,opcode3,0x22], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x23: // Undocumented - SLA (IX+$d),E - DD CB d 23 - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IX+$d),E", opcode: [0xDD,0xCB,opcode3,0x23], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x24: // Undocumented - SLA (IX+$d),H - DD CB d 24 - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IX+$d),H", opcode: [0xDD,0xCB,opcode3,0x24], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x25: // Undocumented - SLA (IX+$d),L - DD CB d 25 - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IX+$d),L", opcode: [0xDD,0xCB,opcode3,0x25], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x26: // SLA (IX+$d) - DD CB d 26 - The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0
            logInstructionDetails(instructionDetails: "SLA (IX+$d)", opcode: [0xDD,0xCB,opcode3,0x26], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let newCarry = (tempOldValue & 0x80) >> 7
            let tempResult = tempOldValue << 1
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | newCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x27: // Undocumented - SLA (IX+$d),A - DD CB d 27 - The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IX+$d),A", opcode: [0xDD,0xCB,opcode3,0x27], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x28: // Undocumented - SRA (IX+$d),B - DD CB d 28 - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IX+$d),B", opcode: [0xDD,0xCB,opcode3,0x28], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x29: // Undocumented - SRA (IX+$d),C - DD CB d 29 - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IX+$d),C", opcode: [0xDD,0xCB,opcode3,0x29], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x2A: // Undocumented - SRA (IX+$d),D - DD CB d 2A - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IX+$d),D", opcode: [0xDD,0xCB,opcode3,0x2A], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x2B: // Undocumented - SRA (IX+$d),E - DD CB d 2B - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IX+$d),E", opcode: [0xDD,0xCB,opcode3,0x2B], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x2C: // Undocumented - SRA (IX+$d),H - DD CB d 2C - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IX+$d),H", opcode: [0xDD,0xCB,opcode3,0x2C], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x2D: // Undocumented - SRA (IX+$d),L - DD CB d 2D - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IX+$d),L", opcode: [0xDD,0xCB,opcode3,0x2D], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x2E: // SRA (IX+$d) - DD CB d 2E - The contents of (IX+$d) are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged
            logInstructionDetails(instructionDetails: "SRA (IX+$d)", opcode: [0xDD,0xCB,opcode3,0x2E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let newCarry = tempOldValue & 0x01
            let oldBitSeven = tempOldValue & 0x80
            let tempResult = (tempOldValue >> 1) | oldBitSeven
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | newCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x2F: // Undocumented - SRA (IX+$d),A - DD CB d 2F - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IX+$d),A", opcode: [0xDD,0xCB,opcode3,0x2F], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x30: // Undocumented - SLL (IX+$d),B - DD CB d 30 - The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IX+$d),B", opcode: [0xDD,0xCB,opcode3,0x30], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x31: // Undocumented - SLL (IX+$d),C - DD CB d 31 - The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IX+$d),C", opcode: [0xDD,0xCB,opcode3,0x31], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x32: // Undocumented - SLL (IX+$d),D - DD CB d 32 - The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IX+$d),D", opcode: [0xDD,0xCB,opcode3,0x32], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x33: // Undocumented - SLL (IX+$d),E - DD CB d 33 - The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IX+$d),E", opcode: [0xDD,0xCB,opcode3,0x33], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x34: // Undocumented - SLL (IX+$d),H - DD CB d 34 - The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IX+$d),H", opcode: [0xDD,0xCB,opcode3,0x34], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x35: // Undocumented - SLL (IX+$d),L - DD CB d 35 - The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IX+$d),L", opcode: [0xDD,0xCB,opcode3,0x35], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x36: // Undocumented - SLL (IX+$d) - DD CB d 36 - The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IX+$d)", opcode: [0xDD,0xCB,opcode3,0x36], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x37: // Undocumented - SLL (IX+$d),A - DD CB d 37 - The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IX+$d),A", opcode: [0xDD,0xCB,opcode3,0x37], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x38: // Undocumented - SRL (IX+$d),B - DD CB d 38 - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IX+$d),B", opcode: [0xDD,0xCB,opcode3,0x38], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x39: // Undocumented - SRL (IX+$d),C - DD CB d 39 - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IX+$d),C", opcode: [0xDD,0xCB,opcode3,0x39], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x3A: // Undocumented - SRL (IX+$d),D - DD CB d 3A - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IX+$d),D", opcode: [0xDD,0xCB,opcode3,0x3A], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x3B: // Undocumented - SRL (IX+$d),E - DD CB d 3B - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IX+$d),E", opcode: [0xDD,0xCB,opcode3,0x3B], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x3C: // Undocumented - SRL (IX+$d),H - DD CB d 3C - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IX+$d),H", opcode: [0xDD,0xCB,opcode3,0x3C], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x3D: // Undocumented - SRL (IX+$d),L - DD CB d 3D - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IX+$d),L", opcode: [0xDD,0xCB,opcode3,0x3D], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x3E: // SRL SRL (IX+$d) - DD CB d 3E - The contents of SRL (IX+$d) are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7
            logInstructionDetails(instructionDetails: "SRL (IX+$d)", opcode: [0xDD,0xCB,opcode3,0x3E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let newCarry = tempOldValue & 0x01
            let tempResult = tempOldValue >> 1
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | newCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x3F: // Undocumented - SRL (IX+$d),A - DD CB d 3F - The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IX+$d),A", opcode: [0xDD,0xCB,opcode3,0x3F], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x40: // Undocumented - BIT 0,(IX+$d) - DD CB d 40 - Tests bit 0 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x40], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x41: // Undocumented - BIT 0,(IX+$d) - DD CB d 41 - Tests bit 0 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x41], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x42: // Undocumented - BIT 0,(IX+$d) - DD CB d 42 - Tests bit 0 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x42], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x43: // Undocumented - BIT 0,(IX+$d) - DD CB d 43 - Tests bit 0 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x43], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x44: // Undocumented - BIT 0,(IX+$d) - DD CB d 44 - Tests bit 0 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x44], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x45: // Undocumented - BIT 0,(IX+$d) - DD CB d 45 - Tests bit 0 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x45], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x46: // BIT 0,(IX+$d) - DD CB d 46 - Tests bit 0 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x46], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x01) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x01) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x47: // Undocumented - BIT 0,(IX+$d) - DD CB d 47 - Tests bit 0 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x47], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x48: // Undocumented - BIT 1,(IX+$d) - DD CB d 48 - Tests bit 1 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x48], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x49: // Undocumented - BIT 1,(IX+$d) - DD CB d 49 - Tests bit 1 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x49], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x4A: // Undocumented - BIT 1,(IX+$d) - DD CB d 4A - Tests bit 1 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x4A], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x4B: // Undocumented - BIT 1,(IX+$d) - DD CB d 4B - Tests bit 1 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x4B], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x4C: // Undocumented - BIT 1,(IX+$d) - DD CB d 4C - Tests bit 1 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x4C], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x4D: // Undocumented - BIT 1,(IX+$d) - DD CB d 4D - Tests bit 1 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x4D], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x4E: // BIT 1,(IX+$d) - DD CB d 4E - Tests bit 1 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x4E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x02) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x02) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x4F: // Undocumented - BIT 1,(IX+$d) - DD CB d 4F - Tests bit 1 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x4F], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x50: // Undocumented - BIT 2,(IX+$d) - DD CB d 50 - Tests bit 2 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x50], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x51: // Undocumented - BIT 2,(IX+$d) - DD CB d 51 - Tests bit 2 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x51], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x52: // Undocumented - BIT 2,(IX+$d) - DD CB d 52 - Tests bit 2 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x52], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x53: // Undocumented - BIT 2,(IX+$d) - DD CB d 53 - Tests bit 2 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x53], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x54: // Undocumented - BIT 2,(IX+$d) - DD CB d 54 - Tests bit 2 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x54], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x55: // Undocumented - BIT 2,(IX+$d) - DD CB d 55 - Tests bit 2 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x55], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x56: // BIT 2,(IX+$d) - DD CB d 56 - Tests bit 2 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x56], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x04) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x04) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x57: // Undocumented - BIT 2,(IX+$d) - DD CB d 57 - Tests bit 2 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x57], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x58: // Undocumented - BIT 3,(IX+$d) - DD CB d 58 - Tests bit 3 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x58], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x59: // Undocumented - BIT 3,(IX+$d) - DD CB d 59 - Tests bit 3 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x59], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x5A: // Undocumented - BIT 3,(IX+$d) - DD CB d 5A - Tests bit 3 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x5A], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x5B: // Undocumented - BIT 3,(IX+$d) - DD CB d 5B - Tests bit 3 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x5B], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x5C: // Undocumented - BIT 3,(IX+$d) - DD CB d 5C - Tests bit 3 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x5C], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x5D: // Undocumented - BIT 3,(IX+$d) - DD CB d 5D - Tests bit 3 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x5D], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x5E: // BIT 3,(IX+$d) - DD CB d 5E - Tests bit 3 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x5E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x08) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x08) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x5F: // Undocumented - BIT 3,(IX+$d) - DD CB d 5F - Tests bit 3 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x5F], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x60: // Undocumented - BIT 4,(IX+$d) - DD CB d 60 - Tests bit 4 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x60], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x61: // Undocumented - BIT 4,(IX+$d) - DD CB d 61 - Tests bit 4 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x61], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x62: // Undocumented - BIT 4,(IX+$d) - DD CB d 62 - Tests bit 4 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x62], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x63: // Undocumented - BIT 4,(IX+$d) - DD CB d 63 - Tests bit 4 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x63], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x64: // Undocumented - BIT 4,(IX+$d) - DD CB d 64 - Tests bit 4 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x64], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x65: // Undocumented - BIT 4,(IX+$d) - DD CB d 65 - Tests bit 4 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x65], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x66: // BIT 4,(IX+$d) - DD CB d 66 - Tests bit 4 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x66], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x10) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x10) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x67: // Undocumented - BIT 4,(IX+$d) - DD CB d 67 - Tests bit 4 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x67], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x68: // Undocumented - BIT 5,(IX+$d) - DD CB d 68 - Tests bit 5 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x68], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x69: // Undocumented - BIT 5,(IX+$d) - DD CB d 69 - Tests bit 5 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x69], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x6A: // Undocumented - BIT 5,(IX+$d) - DD CB d 6A - Tests bit 5 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x6A], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x6B: // Undocumented - BIT 5,(IX+$d) - DD CB d 6B - Tests bit 5 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x6B], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x6C: // Undocumented - BIT 5,(IX+$d) - DD CB d 6C - Tests bit 5 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x6C], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x6D: // Undocumented - BIT 5,(IX+$d) - DD CB d 6D - Tests bit 5 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x6D], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x6E: // BIT 5,(IX+$d) - DD CB d 6E - Tests bit 5 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x6E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x20) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x20) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x6F: // Undocumented - BIT 5,(IX+$d) - DD CB d 6F - Tests bit 5 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x6F], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x70: // Undocumented - BIT 6,(IX+$d) - DD CB d 70 - Tests bit 6 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x70], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x71: // Undocumented - BIT 6,(IX+$d) - DD CB d 71 - Tests bit 6 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x71], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x72: // Undocumented - BIT 6,(IX+$d) - DD CB d 72 - Tests bit 6 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x72], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x73: // Undocumented - BIT 6,(IX+$d) - DD CB d 73 - Tests bit 6 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x73], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x74: // Undocumented - BIT 6,(IX+$d) - DD CB d 74 - Tests bit 6 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x74], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x75: // Undocumented - BIT 6,(IX+$d) - DD CB d 75 - Tests bit 6 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x75], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x76: // BIT 6,(IX+$d) - DD CB d 76 - Tests bit 6 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x76], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x40) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x40) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x77: // Undocumented - BIT 6,(IX+$d) - DD CB d 77 - Tests bit 6 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x77], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:3)
        case 0x78: // Undocumented - BIT 7,(IX+$d) - DD CB d 78 - Tests bit 7 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x78], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x79: // Undocumented - BIT 7,(IX+$d) - DD CB d 79 - Tests bit 7 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x79], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x7A: // Undocumented - BIT 7,(IX+$d) - DD CB d 7A - Tests bit 7 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x7A], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x7B: // Undocumented - BIT 7,(IX+$d) - DD CB d 7B - Tests bit 7 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x7B], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x7C: // Undocumented - BIT 7,(IX+$d) - DD CB d 7C - Tests bit 7 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x7C], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x7D: // Undocumented - BIT 7,(IX+$d) - DD CB d 7D - Tests bit 7 of the memory location pointed to by IX plus $d L
            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x7D], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x7E: // BIT 7,(IX+$d) - DD CB d 7E - Tests bit 7 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x7E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let bitSet = (tempResult & 0x80) != 0
            let newZero: UInt8 = bitSet ? 0x00 : 0x40
            let newParityOverflow: UInt8 = bitSet ? 0x00 : 0x04
            let newHalfCarry: UInt8 = 0x10
            let newNegative: UInt8 = 0x00
            let newSign: UInt8 = bitSet ? 0x80 : 0x00
            let oldCarry = registers.F & 0x01
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newX = WZH & 0x08
            let newY = WZH & 0x20
            registers.F = newSign | newZero | newY | newHalfCarry | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x7F: // Undocumented - BIT 7,(IX+$d) - DD CB d 7F - Tests bit 7 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x7F], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x80: // Undocumented - RES 0,(IX+$d),B - DD CB d 80 - Resets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0x80], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x81: // Undocumented - RES 0,(IX+$d),C - DD CB d 81 - Resets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0x81], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x82: // Undocumented - RES 0,(IX+$d),D - DD CB d 82 - Resets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0x82], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x83: // Undocumented - RES 0,(IX+$d),E - DD CB d 83 - Resets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0x83], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x84: // Undocumented - RES 0,(IX+$d),H - DD CB d 84 - Resets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0x84], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x85: // Undocumented - RES 0,(IX+$d),L - DD CB d 85 - Resets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0x85], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x86: // RES 0,(IX+$d) - DD CB d 86 - Resets bit 0 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "RES 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x86], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b11111110
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x87: // Undocumented - RES 0,(IX+$d),A - DD CB d 87 - Resets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0x87], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x88: // Undocumented - RES 1,(IX+$d),B - DD CB d 88 - Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0x88], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x89: // Undocumented - RES 1,(IX+$d),C - DD CB d 89 - Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0x89], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x8A: // Undocumented - RES 1,(IX+$d),D - DD CB d 8A - Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0x8A], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x8B: // Undocumented - RES 1,(IX+$d),E - DD CB d 8B - Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0x8B], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x8C: // Undocumented - RES 1,(IX+$d),H - DD CB d 8C - Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0x8C], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x8D: // Undocumented - RES 1,(IX+$d),L - DD CB d 8D - Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0x8D], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x8E: // RES 1,(IX+$d) - DD CB d 8E - Resets bit 1 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "RES 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x8E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b11111101
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x8F: // Undocumented - RES 1,(IX+$d),A - DD CB d 8F - Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0x8F], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x90: // Undocumented - RES 2,(IX+$d),B - DD CB d 90 - Resets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0x90], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x91: // Undocumented - RES 2,(IX+$d),C - DD CB d 91 - Resets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0x91], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x92: // Undocumented - RES 2,(IX+$d),D - DD CB d 92 - Resets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0x92], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x93: // Undocumented - RES 2,(IX+$d),E - DD CB d 93 - Resets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0x93], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x94: // Undocumented - RES 2,(IX+$d),H - DD CB d 94 - Resets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0x94], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x95: // Undocumented - RES 2,(IX+$d),L - DD CB d 95 - Resets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0x95], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x96: // RES 2,(IX+$d) - DD CB d 96 - Resets bit 2 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "RES 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x96], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b11111011
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x97: // Undocumented - RES 2,(IX+$d),A - DD CB d 97 - Resets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0x97], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x98: // Undocumented - RES 3,(IX+$d),B - DD CB d 98 - Resets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0x98], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x99: // Undocumented - RES 3,(IX+$d),C - DD CB d 99 - Resets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0x99], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x9A: // Undocumented - RES 3,(IX+$d),D - DD CB d 9A - Resets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0x9A], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x9B: // Undocumented - RES 3,(IX+$d),E - DD CB d 9B - Resets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0x9B], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x9C: // Undocumented - RES 3,(IX+$d),H - DD CB d 9C - Resets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0x9C], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x9D: // Undocumented - RES 3,(IX+$d),L - DD CB d 9D - Resets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0x9D], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x9E: // RES 3,(IX+$d) - DD CB d 9E - Resets bit 3 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "RES 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0x9E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b11110111
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x9F: // Undocumented - RES 3,(IX+$d),A - DD CB d 9F - Resets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0x9F], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA0: // Undocumented - RES 4,(IX+$d),B - DD CB d A0 - Resets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0xA0], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA1: // Undocumented - RES 4,(IX+$d),C - DD CB d A1 - Resets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0xA1], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA2: // Undocumented - RES 4,(IX+$d),D - DD CB d A2 - Resets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0xA2], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA3: // Undocumented - RES 4,(IX+$d),E - DD CB d A3 - Resets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0xA3], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA4: // Undocumented - RES 4,(IX+$d),H - DD CB d A4 - Resets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0xA4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA5: // Undocumented - RES 4,(IX+$d),L - DD CB d A5 - Resets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0xA5], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA6: // RES 4,(IX+$d) - DD CB d A6 - Resets bit 4 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "RES 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xA6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b11101111
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA7: // Undocumented - RES 4,(IX+$d),A - DD CB d A7 - Resets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0xA7], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA8: // Undocumented - RES 5,(IX+$d),B - DD CB d A8 - Resets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0xA8], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA9: // Undocumented - RES 5,(IX+$d),C - DD CB d A9 - Resets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0xA9], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xAA: // Undocumented - RES 5,(IX+$d),D - DD CB d AA - Resets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0xAA], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xAB: // Undocumented - RES 5,(IX+$d),E - DD CB d AB - Resets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0xAB], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xAC: // Undocumented - RES 5,(IX+$d),H - DD CB d AC - Resets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0xAC], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xAD: // Undocumented - RES 5,(IX+$d),L - DD CB d AD - Resets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0xAD], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xAE: // RES 5,(IX+$d) - DD CB d AE - Resets bit 5 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "RES 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xAE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b11011111
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xAF: // Undocumented - RES 5,(IX+$d),A - DD CB d AF - Resets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0xAF], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB0: // Undocumented - RES 6,(IX+$d),B - DD CB d B0 - Resets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0xB0], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB1: // Undocumented - RES 6,(IX+$d),C - DD CB d B1 - Resets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0xB1], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB2: // Undocumented - RES 6,(IX+$d),D - DD CB d B2 - Resets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0xB2], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB3: // Undocumented - RES 6,(IX+$d),E - DD CB d B3 - Resets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0xB3], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB4: // Undocumented - RES 6,(IX+$d),H - DD CB d B4 - Resets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0xB4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB5: // Undocumented - RES 6,(IX+$d),L - DD CB d B5 - Resets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0xB5], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB6: // RES 6,(IX+$d) - DD CB d B6 - Resets bit 6 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "RES 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xB6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b10111111
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB7: // Undocumented - RES 6,(IX+$d),A - DD CB d B7 - Resets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0xB7], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB8: // Undocumented - RES 7,(IX+$d),B - DD CB d B8 - Resets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0xB8], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB9: // Undocumented - RES 7,(IX+$d),C - DD CB d B9 - Resets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0xB9], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xBA: // Undocumented - RES 7,(IX+$d),D - DD CB d BA - Resets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0xBA], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xBB: // Undocumented - RES 7,(IX+$d),E - DD CB d BB - Resets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0xBB], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xBC: // Undocumented - RES 7,(IX+$d),H - DD CB d BC - Resets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0xBC], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xBD: // Undocumented - RES 7,(IX+$d),L - DD CB d BD - Resets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0xBD], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xBE: // RES 7,(IX+$d) - DD CB d BE - Resets bit 7 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "RES 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xBE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b01111111
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xBF: // Undocumented - RES 7,(IX+$d),A - DD CB d BF - Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0xBF], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC0: // Undocumented - SET 0,(IX+$d),B - DD CB d C0 - Sets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0xC0], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC1: // Undocumented - SET 0,(IX+$d),C - DD CB d C1 - Sets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0xC1], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC2: // Undocumented - SET 0,(IX+$d),D - DD CB d C2 - Sets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0xC2], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC3: // Undocumented - SET 0,(IX+$d),E - DD CB d C3 - Sets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0xC3], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC4: // Undocumented - SET 0,(IX+$d),H - DD CB d C4 - Sets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0xC4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC5: // Undocumented - SET 0,(IX+$d),L - DD CB d C5 - Sets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0xC5], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC6: // SET 0,(IX+$d) - DD CB d C6 - Sets bit 0 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "SET 0,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xC6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b00000001
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC7: // Undocumented - SET 0,(IX+$d),A - DD CB d C7 - Sets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0xC7], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC8: // Undocumented - SET 1,(IX+$d),B - DD CB d C8 - Sets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0xC8], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC9: // Undocumented - SET 1,(IX+$d),C - DD CB d C9 - Sets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0xC9], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xCA: // Undocumented - SET 1,(IX+$d),D - DD CB d CA - Sets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0xCA], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xCB: // Undocumented - SET 1,(IX+$d),E - DD CB d CB - Sets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0xCB], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xCC: // Undocumented - SET 1,(IX+$d),H - DD CB d CC - Sets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0xCC], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xCD: // Undocumented - SET 1,(IX+$d),L - DD CB d CD - Sets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0xCD], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xCE: // SET 1,(IX+$d) - DD CB d CE - Sets bit 1 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "SET 1,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xCE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b00000010
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xCF: // Undocumented - SET 1,(IX+$d),A - DD CB d CF - Sets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0xCF], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD0: // Undocumented - SET 2,(IX+$d),B - DD CB d D0 - Sets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 2,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0xD0], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD1: // Undocumented - SET 2,(IX+$d),C - DD CB d D1 - Sets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 2,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0xD1], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD2: // Undocumented - SET 2,(IX+$d),D - DD CB d D2 - Sets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 2,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0xD2], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD3: // Undocumented - SET 2,(IX+$d),E - DD CB d D3 - Sets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 2,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0xD3], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD4: // Undocumented - SET 2,(IX+$d),H - DD CB d D4 - Sets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 2,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0xD4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD5: // Undocumented - SET 2,(IX+$d),L - DD CB d D5 - Sets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 2,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0xD5], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD6: // SET 2,(IX+$d) - DD CB d D6 - Sets bit 2 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "SET 2,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xD6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b00000100
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD7: // Undocumented - SET 2,(IX+$d),A - DD CB d D7 - Sets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 2,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0xD7], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD8: // Undocumented - SET 3,(IX+$d),B - DD CB d D8 - Sets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0xD8], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD9: // Undocumented - SET 3,(IX+$d),C - DD CB d D9 - Sets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0xD9], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xDA: // Undocumented - SET 3,(IX+$d),D - DD CB d DA - Sets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0xDA], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xDB: // Undocumented - SET 3,(IX+$d),E - DD CB d DB - Sets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0xDB], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xDC: // Undocumented - SET 3,(IX+$d),H - DD CB d DC - Sets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0xDC], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xDD: // Undocumented - SET 3,(IX+$d),L - DD CB d DD - Sets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0xDD], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xDE: // SET 3,(IX+$d) - DD CB d DE - Sets bit 3 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "SET 3,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xDE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b00001000
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xDF: // Undocumented - SET 3,(IX+$d),A - DD CB d DF - Sets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0xDF], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE0: // Undocumented - SET 4,(IX+$d),B - DD CB d E0 - Sets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0xE0], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE1: // Undocumented - SET 4,(IX+$d),C - DD CB d E1 - Sets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0xE1], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE2: // Undocumented - SET 4,(IX+$d),D - DD CB d E2 - Sets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0xE2], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE3: // Undocumented - SET 4,(IX+$d),E - DD CB d E3 - Sets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0xE3], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE4: // Undocumented - SET 4,(IX+$d),H - DD CB d E4 - Sets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0xE4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE5: // Undocumented - SET 4,(IX+$d),L - DD CB d E5 - Sets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0xE5], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE6: // SET 4,(IX+$d) - DD CB d E6 - Sets bit 4 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "SET 4,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xE6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b00010000
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE7: // Undocumented - SET 4,(IX+$d),A - DD CB d E7 - Sets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0xE7], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE8: // Undocumented - SET 5,(IX+$d),B - DD CB d E8 - Sets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0xE8], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE9: // Undocumented - SET 5,(IX+$d),C - DD CB d E9 - Sets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0xE9], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xEA: // Undocumented - SET 5,(IX+$d),D - DD CB d EA - Sets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0xEA], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xEB: // Undocumented - SET 5,(IX+$d),E - DD CB d EB - Sets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0xEB], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xEC: // Undocumented - SET 5,(IX+$d),H - DD CB d EC - Sets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0xEC], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xED: // Undocumented - SET 5,(IX+$d),L - DD CB d ED - Sets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0xED], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xEE: // SET 5,(IX+$d) - DD CB d EE - Sets bit 5 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "SET 5,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xEE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b00100000
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xEF: // Undocumented - SET 5,(IX+$d),A - DD CB d EF - Sets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0xEF], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF0: // Undocumented - SET 6,(IX+$d),B - DD CB d F0 - Sets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0xF0], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF1: // Undocumented - SET 6,(IX+$d),C - DD CB d F1 - Sets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0xF1], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF2: // Undocumented - SET 6,(IX+$d),D - DD CB d F2 - Sets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0xF2], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF3: // Undocumented - SET 6,(IX+$d),E - DD CB d F3 - Sets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0xF3], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF4: // Undocumented - SET 6,(IX+$d),H - DD CB d F4 - Sets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0xF4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF5: // Undocumented - SET 6,(IX+$d),L - DD CB d F5 - Sets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0xF5], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF6: // SET 6,(IX+$d) - DD CB d F6 - Sets bit 6 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "SET 6,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xF6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b01000000
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF7: // Undocumented - SET 6,(IX+$d),A - DD CB d F7 - Sets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0xF7], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF8: // Undocumented - SET 7,(IX+$d),B - DD CB d F8 - Sets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IX+$d),B", opcode: [0xDD,0xCB,opcode3,0xF8], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF9: // Undocumented - SET 7,(IX+$d),C - DD CB d F9 - Sets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IX+$d),C", opcode: [0xDD,0xCB,opcode3,0xF9], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xFA: // Undocumented - SET 7,(IX+$d),D - DD CB d FA - Sets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IX+$d),D", opcode: [0xDD,0xCB,opcode3,0xFA], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xFB: // Undocumented - SET 7,(IX+$d),E - DD CB d FB - Sets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IX+$d),E", opcode: [0xDD,0xCB,opcode3,0xFB], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xFC: // Undocumented - SET 7,(IX+$d),H - DD CB d FC - Sets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IX+$d),H", opcode: [0xDD,0xCB,opcode3,0xFC], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xFD: // Undocumented - SET 7,(IX+$d),L - DD CB d FD - Sets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IX+$d),L", opcode: [0xDD,0xCB,opcode3,0xFD], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xFE: // SET 7,(IX+$d) - DD CB d FE - Sets bit 7 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "SET 7,(IX+$d)", opcode: [0xDD,0xCB,opcode3,0xFE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IX &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b10000000
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xFF: // Undocumented - SET 7,(IX+$d),A - DD CB d FF - Sets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IX+$d),A", opcode: [0xDD,0xCB,opcode3,0xFF], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        default:
            logInstructionDetails(opcode: [0xDD,0xCB,opcode3,opcode4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
            // Assuming this is correct behaviour - confirm what decodes in missing ranges in real z80
        }
    }
     
    private func executeEDInstructions(opcode2: UInt8, opcode3: UInt8, opcode4: UInt8)
    {
       switch opcode2
        {
       case 0x40: // IN B,(C) - ED 40 - A byte from port C is written to B
           logInstructionDetails(instructionDetails: "IN B,(C)", opcode: [0xED,0x40], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           registers.WZ = tempResult + 1
           registers.B = bus.readPort(portNum: tempResult)
           let carry = registers.F & z80Flags.Carry.rawValue
           registers.F = z80FastFlags.basicHelper(tempResult: registers.B) | carry
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x41: // OUT (C),B - ED 41 - The value of B is written to port C
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           logInstructionDetails(instructionDetails: "OUT (C),B", opcode: [0xED,0x41], programCounter: registers.PC)
           bus.writePort(portNum: tempResult, portValue: registers.B)
           registers.WZ = registers.BC &+ 1
           registers.Q = 0
           registers.PC = registers.PC &+ 2
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x42: // SBC HL,BC - ED 42 - Subtracts BC and the carry flag from HL
           logInstructionDetails(instructionDetails: "SBC HL,BC", opcode: [0xED,0x42], programCounter: registers.PC)
           registers.WZ = registers.HL &+ 1
           let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
           (registers.HL,registers.F) = z80FastFlags.subHelper16(operand1: registers.HL, operand2: registers.BC,currentFlags: registers.F, addCarry: addCarry)
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 15
           incrementR(opcodeCount:2)
       case 0x43: // LD ($nn),BC - ED 43 n n - Stores BC into the memory location pointed to by $nn
           logInstructionDetails(instructionDetails: "LD ($nn),BC", opcode: [0xED,0x43], values: [opcode3, opcode4], programCounter: registers.PC)
           let tempResult = UInt16(opcode4) << 8 | UInt16(opcode3)
           bus.writeByte(address: tempResult, value: registers.C)
           bus.writeByte(address: tempResult &+ 1, value: registers.B)
           registers.WZ = tempResult &+ 1
           registers.Q = 0
           registers.PC = registers.PC &+ 4
           tStates = tStates + 20
           incrementR(opcodeCount:2)
       case 0x44: // NEG - ED 44 - The contents of A are negated (two's complement). Operation is the same as subtracting A from zero.
           logInstructionDetails(instructionDetails: "NEG", opcode: [0xED,0x44], programCounter: registers.PC)
           (registers.A,registers.F) = z80FastFlags.subHelper(operand1: 0, operand2: registers.A)
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 8
           incrementR(opcodeCount:2)
       case 0x45: // RETN - ED 45 - Used at the end of a non-maskable interrupt service routine (located at 0066h) to pop the top stack entry into PC. The value of IFF2 is copied to IFF1 so that maskable interrupts are allowed to continue as before. NMIs are not enabled on the TI
           logInstructionDetails(instructionDetails: "RETN", opcode: [0xED,0x45], programCounter: registers.PC)
           registers.IFF1 = registers.IFF2
           registers.PCL = bus.readByte(address: registers.SP)
           registers.SP = registers.SP &+ 1
           registers.PCH = bus.readByte(address: registers.SP)
           registers.SP = registers.SP &+ 1
           registers.WZ = registers.PC
           registers.Q = 0
           tStates = tStates + 14
           incrementR(opcodeCount:2)
       case 0x46: // IM 0 - ED 46 - Sets interrupt mode 0
           logInstructionDetails(instructionDetails: "IM 0", opcode: [0xED,0x46], programCounter: registers.PC)
           registers.IM = 0
           registers.Q = 0
           registers.PC = registers.PC &+ 2
           tStates = tStates + 8
           incrementR(opcodeCount:2)
       case 0x47: // LD I,A - ED 47 - Stores the value of A into register I
           logInstructionDetails(instructionDetails: "LD I,A", opcode: [0xED,0x47], programCounter: registers.PC)
           registers.I = registers.A
           registers.Q = 0
           registers.PC = registers.PC &+ 2
           tStates = tStates + 9
           incrementR(opcodeCount:2)
       case 0x48: // IN C,(C) - ED 48 - A byte from port C is written to B
           logInstructionDetails(instructionDetails: "IN C,(C)", opcode: [0xED,0x48], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           registers.WZ = tempResult + 1
           registers.C = bus.readPort(portNum: tempResult)
           let carry = registers.F & z80Flags.Carry.rawValue
           registers.F = z80FastFlags.basicHelper(tempResult: registers.C) | carry
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x49: // OUT (C),C - ED 49 - The value of C is written to port C
           logInstructionDetails(instructionDetails: "OUT (C),C", opcode: [0xED,0x49], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           bus.writePort(portNum: tempResult, portValue: registers.C)
           registers.WZ = registers.BC &+ 1
           registers.Q = 0
           registers.PC = registers.PC &+ 2
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x4A: // ADC HL,BC - ED 4A - Adds BC and the carry flag to HL
           logInstructionDetails(instructionDetails: "ADC HL,BC", opcode: [0xED,0x4A], programCounter: registers.PC)
           registers.WZ = registers.HL &+ 1
           let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
           (registers.HL,registers.F) = z80FastFlags.addHelper16(operand1: registers.HL, operand2: registers.BC,currentFlags: registers.F, addCarry: addCarry)
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 15
           incrementR(opcodeCount:2)
       case 0x4B: // LD BC,($nn) - ED 4B n n - Loads the value pointed to by $nn into BC
           logInstructionDetails(instructionDetails: "LD BC,($nn)", opcode: [0xED,0x4B], values: [opcode3,opcode4], programCounter: registers.PC)
           let tempResult = UInt16(opcode4) << 8 | UInt16(opcode3)
           registers.C =  bus.readByte(address: tempResult)
           registers.B =  bus.readByte(address: tempResult &+ 1)
           registers.PC = registers.PC &+ 4
           registers.WZ = tempResult &+ 1
           registers.Q = 0
           tStates = tStates + 20
           incrementR(opcodeCount:2)
       case 0x4D: // RETI - ED 4D - Used at the end of a maskable interrupt service routine. The top stack entry is popped into PC, and signals an I/O device that the interrupt has finished, allowing nested interrupts (not a consideration on the TI)
           logInstructionDetails(instructionDetails: "RETI", opcode: [0xED,0x4D], programCounter: registers.PC)
           registers.PCL = bus.readByte(address: registers.SP)
           registers.SP = registers.SP &+ 1
           registers.PCH = bus.readByte(address: registers.SP)
           registers.SP = registers.SP &+ 1
           registers.IFF1 = registers.IFF2
           registers.WZ = registers.PC
           registers.Q = 0
           tStates = tStates + 14
           incrementR(opcodeCount:2)
       case 0x4F: // LD R,A - ED 4F - Stores the value of A into register R
           logInstructionDetails(instructionDetails: "LD R,A", opcode: [0xED,0x4F], programCounter: registers.PC)
           registers.R = registers.A
           registers.Q = 0
           registers.PC = registers.PC &+ 2
           tStates = tStates + 9
       case 0x50: // IN D,(C) - ED 50 - A byte from port C is written to D
           logInstructionDetails(instructionDetails: "IN D,(C)", opcode: [0xED,0x50], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           registers.WZ = tempResult &+ 1
           registers.D = bus.readPort(portNum: tempResult)
           let carry = registers.F & z80Flags.Carry.rawValue
           registers.F = z80FastFlags.basicHelper(tempResult: registers.D) | carry
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x51: // OUT (C),D - ED 51 - The value of D is written to port C
           logInstructionDetails(instructionDetails: "OUT (C),D", opcode: [0xED,0x51], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           registers.D = bus.readPort(portNum: tempResult)
           registers.WZ = registers.BC &+ 1
           registers.Q = 0
           registers.PC = registers.PC &+ 2
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x52: // SBC HL,DE - ED 52 - Subtracts DE and the carry flag from HL
           logInstructionDetails(instructionDetails: "SBC HL,DE", opcode: [0xED,0x52], programCounter: registers.PC)
           registers.WZ = registers.HL &+ 1
           let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
           (registers.HL,registers.F) = z80FastFlags.subHelper16(operand1: registers.HL, operand2: registers.DE, currentFlags: registers.F, addCarry: addCarry)
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 15
           incrementR(opcodeCount:2)
       case 0x53: // LD ($nn),DE - ED 53 n n - Stores DE into the memory location pointed to by $nn
           logInstructionDetails(instructionDetails: "LD ($nn),DE", opcode: [0xED,0x53], values: [opcode3,opcode4], programCounter: registers.PC)
           let tempResult = UInt16(opcode4) << 8 | UInt16(opcode3)
           bus.writeByte(address: tempResult, value: registers.E)
           bus.writeByte(address: tempResult &+ 1, value: registers.D)
           registers.WZ = tempResult &+ 1
           registers.Q = 0
           registers.PC = registers.PC &+ 4
           tStates = tStates + 20
           incrementR(opcodeCount:2)
       case 0x56: // IM 1 - ED 56 - Sets interrupt mode 1
           logInstructionDetails(instructionDetails: "IM 1", opcode: [0xED,0x56], programCounter: registers.PC)
           registers.IM = 1
           registers.Q = 0
           registers.PC = registers.PC &+ 2
           tStates = tStates + 8
           incrementR(opcodeCount:2)
       case 0x57: // LD A,I - ED 57 - Stores the value of register I into A
           // If an interrupt occurs during execution of this instruction, the parity flag contains a 0
           logInstructionDetails(instructionDetails: "LD A,I", opcode: [0xED,0x57], programCounter: registers.PC)
           registers.A = registers.I
           let carry = registers.F & z80Flags.Carry.rawValue
           registers.F = z80FastFlags.basicHelper(tempResult: registers.I) | carry
           registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
           registers.F = registers.F & ~z80Flags.Negative.rawValue
           registers.F = registers.F & ~z80Flags.Negative.rawValue
           if registers.IFF2
           {
               registers.F = registers.F | z80Flags.ParityOverflow.rawValue
           }
           else
           {
               registers.F = registers.F & ~z80Flags.ParityOverflow.rawValue
           }
           registers.P = 1
           registers.EI = preserveEI == 1 ? 0 : registers.EI
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 9
           incrementR(opcodeCount:2)
       case 0x58: // IN E,(C) - ED 50 - A byte from port C is written to E
           logInstructionDetails(instructionDetails: "IN E,(C)", opcode: [0xED,0x58], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           registers.WZ = tempResult &+ 1
           registers.E = bus.readPort(portNum: tempResult)
           let carry = registers.F & z80Flags.Carry.rawValue
           registers.F = z80FastFlags.basicHelper(tempResult: registers.E) | carry
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x59: // OUT (C),E - ED 59 - The value of E is written to port C
           logInstructionDetails(instructionDetails: "OUT (C),E", opcode: [0xED,0x59], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           bus.writePort(portNum: tempResult, portValue: registers.E)
           registers.WZ = registers.BC &+ 1
           registers.Q = 0
           registers.PC = registers.PC &+ 2
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x5A: // ADC HL,DE - ED 5A - Adds DE and the carry flag to HL
           logInstructionDetails(instructionDetails: "ADC HL,DE", opcode: [0xED,0x5A], programCounter: registers.PC)
           registers.WZ = registers.HL &+ 1
           let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
           (registers.HL,registers.F) = z80FastFlags.addHelper16(operand1: registers.HL, operand2: registers.DE,currentFlags: registers.F, addCarry: addCarry)
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 15
           incrementR(opcodeCount:2)
       case 0x5B: // LD DE,($nn) - ED 5B n n - Loads the value pointed to by $nn into DE
           logInstructionDetails(instructionDetails: "LD DE,($nn)", opcode: [0xED,0x5B], values: [opcode3,opcode4], programCounter: registers.PC)
           let tempResult = UInt16(opcode4) << 8 | UInt16(opcode3)
           registers.E = bus.readByte(address: tempResult)
           registers.D = bus.readByte(address: tempResult &+ 1)
           registers.Q = 0
           registers.PC = registers.PC &+ 4
           registers.WZ = tempResult &+ 1
           tStates = tStates + 20
           incrementR(opcodeCount:2)
       case 0x5E: // IM 2 - ED 5E - Sets interrupt mode 2
           logInstructionDetails(instructionDetails: "IM 2", opcode: [0xED,0x5E], programCounter: registers.PC)
           registers.IM = 2
           registers.Q = 0
           registers.PC = registers.PC &+ 2
           tStates = tStates + 8
           incrementR(opcodeCount:2)
       case 0x5F: // LD A,R - ED 5F - Stores the value of register R into A
           // If an interrupt occurs during execution of this instruction, the parity flag contains a 0
           logInstructionDetails(instructionDetails: "LD A,R", opcode: [0xED,0x5F], programCounter: registers.PC)
           incrementR(opcodeCount:2)
           registers.A = registers.R
           let carry = registers.F & z80Flags.Carry.rawValue
           registers.F = z80FastFlags.basicHelper(tempResult: registers.R) | carry
           registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
           registers.F = registers.F & ~z80Flags.Negative.rawValue
           registers.F = registers.F & ~z80Flags.Negative.rawValue
           if registers.IFF2
           {
               registers.F = registers.F | z80Flags.ParityOverflow.rawValue
           }
           else
           {
               registers.F = registers.F & ~z80Flags.ParityOverflow.rawValue
           }
           registers.P = 1
           registers.EI = preserveEI == 1 ? 0 : registers.EI
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 9
       case 0x60: // IN H,(C) - ED 60 - A byte from port C is written to H
           logInstructionDetails(instructionDetails: "IN H,(C)", opcode: [0xED,0x60], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           registers.WZ = tempResult + 1
           registers.H = bus.readPort(portNum: tempResult)
           let carry = registers.F & z80Flags.Carry.rawValue
           registers.F = z80FastFlags.basicHelper(tempResult: registers.H) | carry
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x61: // OUT (C),H - ED 61 - The value of H is written to port C
           logInstructionDetails(instructionDetails: "OUT (C),H", opcode: [0xED,0x61], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           bus.writePort(portNum: tempResult, portValue: registers.H)
           registers.WZ = registers.BC &+ 1
           registers.Q = 0
           registers.PC = registers.PC &+ 2
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x62: // SBC HL,HL - ED 62 - Subtracts HL and the carry flag from HL
           logInstructionDetails(instructionDetails: "SBC HL,HL", opcode: [0xED,0x62], programCounter: registers.PC)
           registers.WZ = registers.HL &+ 1
           let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
           (registers.HL,registers.F) = z80FastFlags.subHelper16(operand1: registers.HL, operand2: registers.HL, currentFlags: registers.F, addCarry: addCarry)
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 15
           incrementR(opcodeCount:2)
       case 0x63: // Undocumented - LD ($nn),HL - ED 63 n n - Stores HL into the memory location pointed to by $nn
           // Stub
           logInstructionDetails(instructionDetails: "LD ($nn),HL", opcode: [0xED,0x63], values: [opcode3,opcode4], programCounter: registers.PC)
           registers.PC = registers.PC &+ 4
           registers.Q = 0
           tStates = tStates + 20
           incrementR(opcodeCount:2)
       case 0x67: // RRD - ED 67 - The contents of the low-order nibble of (HL) are copied to the low-order nibble of A. The previous contents are copied to the high-order nibble of (HL). The previous contents are copied to the low-order nibble of (HL)
           logInstructionDetails(instructionDetails: "RRD", opcode: [0xED,0x67], programCounter: registers.PC)
           let carry = registers.F & z80Flags.Carry.rawValue
           let contentsHL = bus.readByte(address: registers.HL)
           registers.WZ = registers.HL &+ 1
           let upperHL = contentsHL >> 4
           let lowerHL = contentsHL & 0b00001111
           let lowerA = registers.A & 0b00001111
           let newContentsHL = (lowerA << 4) | upperHL
           let tempResultA = ( registers.A & 0b11110000 ) | lowerHL
           (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: tempResultA)
           bus.writeByte(address: registers.HL, value: newContentsHL)
           registers.F = registers.F & ~z80Flags.Negative.rawValue
           registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
           registers.F = registers.F | carry
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 18
           incrementR(opcodeCount:2)
       case 0x68: // IN L,(C) - ED 68 - A byte from port C is written to L
           logInstructionDetails(instructionDetails: "IN L,(C)", opcode: [0xED,0x68], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           registers.WZ = tempResult &+ 1
           registers.L = bus.readPort(portNum: tempResult)
           let carry = registers.F & z80Flags.Carry.rawValue
           registers.F = z80FastFlags.basicHelper(tempResult: registers.L) | carry
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x69: // OUT (C),L - ED 69 - The value of L is written to port C
           logInstructionDetails(instructionDetails: "OUT (C),L", opcode: [0xED,0x69], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           bus.writePort(portNum: tempResult, portValue: registers.L)
           registers.WZ = registers.BC &+ 1
           registers.Q = 0
           registers.PC = registers.PC &+ 2
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x6A: // ADC HL,HL - ED 6A - Adds HL and the carry flag to HL
           logInstructionDetails(instructionDetails: "ADC HL,HL", opcode: [0xED,0x6A], programCounter: registers.PC)
           registers.WZ = registers.HL &+ 1
           let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
           (registers.HL,registers.F) = z80FastFlags.addHelper16(operand1: registers.HL, operand2: registers.HL,currentFlags: registers.F, addCarry: addCarry)
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 15
           incrementR(opcodeCount:2)
       case 0x6B: // Undocumented - LD HL,($nn) - ED 6B n n - Loads the value pointed to by $nn into HL
           // Stub
           logInstructionDetails(instructionDetails: "LD HL,($nn)", opcode: [0xED,0x6B], values: [opcode3,opcode4], programCounter: registers.PC)
           registers.PC = registers.PC &+ 4
           registers.Q = 0
           tStates = tStates + 20
           incrementR(opcodeCount:2)
       case 0x6F: // RLD - ED 6F - The contents of the low-order nibble of (HL) are copied to the high-order nibble of (HL). The previous contents are copied to the low-order nibble of A. The previous contents are copied to the low-order nibble of (HL)
           logInstructionDetails(instructionDetails: "RLD", opcode: [0xED,0x6F], programCounter: registers.PC)
           let carry = registers.F & z80Flags.Carry.rawValue
           registers.WZ = registers.HL &+ 1
           let contentsHL = bus.readByte(address: registers.HL)
           let upperHL = contentsHL >> 4
           let lowerHL = contentsHL & 0b00001111
           let lowerA = registers.A & 0b00001111
           let newContentsHL = (lowerHL << 4) | lowerA
           let tempResultA = ( registers.A & 0b11110000 ) | upperHL
           (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: tempResultA)
           bus.writeByte(address: registers.HL, value: newContentsHL)
           registers.F = registers.F & ~z80Flags.Negative.rawValue
           registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
           registers.F = registers.F | carry
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 18
           incrementR(opcodeCount:2)
       case 0x70: // Undocumented - IN (C) - ED 70 - Inputs a byte from port C and affects flags only
           // Stub
           logInstructionDetails(instructionDetails: "IN (C)", opcode: [0xED,0x70], programCounter: registers.PC)
           registers.PC = registers.PC &+ 2
           registers.Q = 0 //  change for flag opcodes
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x71: // Undocumented - OUT (C),0 - ED 71 - Outputs a zero (on NMOS Z80s) or 255 (on CMOS Z80s) to port C
           // Stub
           logInstructionDetails(instructionDetails: "OUT (C),0", opcode: [0xED,0x71], programCounter: registers.PC)
           registers.PC = registers.PC &+ 2
           registers.Q = 0
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x72: // SBC HL,SP - ED 72 - Subtracts SP and the carry flag from HL
           logInstructionDetails(instructionDetails: "SBC HL,SP", opcode: [0xED,0x72], programCounter: registers.PC)
           registers.WZ = registers.HL &+ 1
           let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
           (registers.HL,registers.F) = z80FastFlags.subHelper16(operand1: registers.HL, operand2: registers.SP, currentFlags: registers.F, addCarry: addCarry)
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 15
           incrementR(opcodeCount:2)
       case 0x73: // LD ($nn),SP - ED 73 n n - Stores SP into the memory location pointed to by $nn
           logInstructionDetails(instructionDetails: "LD ($nn),SP", opcode: [0xED,0x73], values: [opcode3,opcode4], programCounter: registers.PC)
           let tempResult = UInt16(opcode4) << 8 | UInt16(opcode3)
           bus.writeByte(address: tempResult, value: registers.SPL)
           bus.writeByte(address: tempResult &+ 1, value: registers.SPH)
           registers.WZ = tempResult &+ 1
           registers.Q = 0
           registers.PC = registers.PC &+ 4
           tStates = tStates + 20
           incrementR(opcodeCount:2)
       case 0x78: // IN A,(C) - ED 78 - A byte from port C is written to A
           logInstructionDetails(instructionDetails: "IN A,(C)", opcode: [0xED,0x78], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           registers.WZ = tempResult &+ 1
           registers.A = bus.readPort(portNum: tempResult)
           let carry = registers.F & z80Flags.Carry.rawValue
           registers.F = z80FastFlags.basicHelper(tempResult: registers.A) | carry
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x79: // OUT (C),A - ED 79 - The value of A is written to port C
           logInstructionDetails(instructionDetails: "OUT (C),A", opcode: [0xED,0x79], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           bus.writePort(portNum: tempResult, portValue: registers.A)
           registers.WZ = registers.BC &+ 1
           registers.Q = 0
           registers.PC = registers.PC &+ 2
           tStates = tStates + 12
           incrementR(opcodeCount:2)
       case 0x7A: // ADC HL,SP - ED 7A - Adds SP and the carry flag to HL
           logInstructionDetails(instructionDetails: "ADC HL,SP", opcode: [0xED,0x7A], programCounter: registers.PC)
           registers.WZ = registers.HL &+ 1
           let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
           (registers.HL,registers.F) = z80FastFlags.addHelper16(operand1: registers.HL, operand2: registers.SP,currentFlags: registers.F, addCarry: addCarry)
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 15
           incrementR(opcodeCount:2)
       case 0x7B: // LD SP,($nn) - ED 7B n n - Loads the value pointed to by $nn into SP
           logInstructionDetails(instructionDetails: "LD SP,($nn)", opcode: [0xED,0x7B], values: [opcode3,opcode4], programCounter: registers.PC)
           let tempResult = UInt16(opcode4) << 8 | UInt16(opcode3)
           registers.SPL = bus.readByte(address: tempResult)
           registers.SPH = bus.readByte(address: tempResult &+ 1)
           registers.Q = 0
           registers.PC = registers.PC &+ 4
           registers.WZ = tempResult &+ 1
           tStates = tStates + 20
           incrementR(opcodeCount:2)
       case 0xA0: // LDI - ED A0 - Transfers a byte of data from the memory location pointed to by HL to the memory location pointed to by DE. Then HL and DE are incremented and BC is decremented. p/v is reset if BC becomes zero and set otherwise.
           logInstructionDetails(instructionDetails: "LDI", opcode: [0xED,0xA0], programCounter: registers.PC)
           let tempValue = bus.readByte(address: registers.HL)
           bus.writeByte(address: registers.DE, value: tempValue)
           registers.HL = registers.HL &+ 1
           registers.DE = registers.DE &+ 1
           registers.BC = registers.BC &- 1
           registers.F = registers.F &  ~z80Flags.Negative.rawValue
           registers.F = registers.F &  ~z80Flags.HalfCarry.rawValue
           let tempResult = tempValue &+ registers.A
           let tempX = tempResult & 0x08
           let tempY = (tempResult & 0x02) << 4
           registers.F = registers.F & ~z80Flags.X.rawValue & ~z80Flags.Y.rawValue & ~z80Flags.ParityOverflow.rawValue
           registers.F = registers.F | tempX | tempY
           if registers.BC != 0
           {
               registers.F = registers.F | z80Flags.ParityOverflow.rawValue
           }
           tStates = tStates + 16
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           incrementR(opcodeCount:2)
       case 0xA1: // CPI - ED A1 - Compares the value of the memory location pointed to by HL with A. Then HL is incremented and BC is decremented. p/v is reset if BC becomes zero and set otherwise
           logInstructionDetails(instructionDetails: "CPI", opcode: [0xED,0xA1], programCounter: registers.PC)
           registers.WZ = registers.WZ &+ 1
           let tempValue = bus.readByte(address: registers.HL)
           let oldCarry = registers.F & z80Flags.Carry.rawValue
           let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: tempValue)
           let tempResult = registers.A &- tempValue &- ((tempFlags & z80Flags.HalfCarry.rawValue) >> 4)
           let tempX = tempResult & 0x08
           let tempY = (tempResult & 0x02) << 4
           registers.F = tempFlags
           registers.F = registers.F & ~z80Flags.X.rawValue & ~z80Flags.Y.rawValue & ~z80Flags.ParityOverflow.rawValue & ~z80Flags.Carry.rawValue
           registers.F = registers.F | tempX | tempY | z80Flags.Negative.rawValue | oldCarry
           registers.HL = registers.HL &+ 1
           registers.BC = registers.BC &- 1
           if registers.BC != 0
           {
               registers.F = registers.F | z80Flags.ParityOverflow.rawValue
           }
           tStates = tStates + 16
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           incrementR(opcodeCount:2)
       case 0xA2: // INI - ED A2 - A byte from port C is written to the memory location pointed to by HL. Then HL is incremented and B is decremented
           logInstructionDetails(instructionDetails: "INI", opcode: [0xED,0xA2], programCounter: registers.PC)
           registers.WZ = registers.BC &+ 1
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           let tempValue = bus.readPort(portNum: tempResult)
           bus.writeByte(address: registers.HL, value: tempValue)
           registers.HL = registers.HL &+ 1
           registers.B = registers.B &- 1
           let tempNegative : UInt8 = (tempValue & 0x80) >> 6
           let tempResultFlags = UInt16(tempValue) + UInt16(registers.C &+ 1)
           let tempCarry : UInt8 = tempResultFlags > 0xFF ? 0x01 : 0x00
           let tempHalfCarry : UInt8 = tempResultFlags > 0xFF ? 0x10 : 0x00
           let tempParityCalc = UInt8(tempResultFlags & 0x07) ^ registers.B
           let tempParityOverflow: UInt8 = tempParityCalc.nonzeroBitCount % 2 == 0 ? 0x04 : 0x00
           let tempSign = registers.B & z80Flags.Sign.rawValue
           let tempZero: UInt8 = registers.B == 0 ? z80Flags.Zero.rawValue : 0
           let tempY = registers.B & z80Flags.Y.rawValue
           let tempX = registers.B & z80Flags.X.rawValue
           registers.F = tempSign | tempZero | tempY | tempHalfCarry | tempX | tempParityOverflow | tempNegative | tempCarry
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 16
           incrementR(opcodeCount:2)
       case 0xA3: // OUTI - ED AB - B is decremented. A byte from the memory location pointed to by HL is written to port C. Then HL is incremented
           logInstructionDetails(instructionDetails: "OUTI", opcode: [0xED,0xA3], programCounter: registers.PC)
           (registers.B,registers.F) = z80FastFlags.decHelper(operand: registers.B, currentFlags: registers.F)
           registers.WZ = registers.BC &+ 1
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           let tempValue = bus.readByte(address: registers.HL)
           bus.writePort(portNum: tempResult, portValue: tempValue)
           registers.HL = registers.HL &+ 1
           let tempFlags = registers.F & ~z80Flags.Negative.rawValue & ~z80Flags.Carry.rawValue & ~z80Flags.HalfCarry.rawValue & ~z80Flags.ParityOverflow.rawValue
           let tempNegative : UInt8 = (tempValue & 0x80) >> 6
           let tempResultFlags = UInt16(tempValue) + UInt16(registers.L)
           let tempCarry : UInt8 = tempResultFlags > 0xFF ? 0x01 : 0x00
           let tempHalfCarry : UInt8 = tempResultFlags > 0xFF ? 0x10 : 0x00
           let tempParityCalc = UInt8(tempResultFlags & 0x07) ^ registers.B
           let tempParityOverflow: UInt8 = tempParityCalc.nonzeroBitCount % 2 == 0 ? 0x04 : 0x00
           registers.F = tempFlags | tempHalfCarry | tempParityOverflow | tempNegative | tempCarry
           registers.Q = registers.F
           tStates = tStates + 16
           registers.PC = registers.PC &+ 2
           incrementR(opcodeCount:2)
       case 0xA8: // LDD - ED A8 - Transfers a byte of data from the memory location pointed to by HL to the memory location pointed to by DE. Then HL, DE, and BC are decremented. p/v is reset if BC becomes zero and set otherwise
           logInstructionDetails(instructionDetails: "LDD", opcode: [0xED,0xA8], programCounter: registers.PC)
           let tempValue = bus.readByte(address: registers.HL)
           bus.writeByte(address: registers.DE, value: tempValue)
           registers.HL = registers.HL &- 1
           registers.DE = registers.DE &- 1
           registers.BC = registers.BC &- 1
           registers.F = registers.F &  ~z80Flags.Negative.rawValue
           registers.F = registers.F &  ~z80Flags.HalfCarry.rawValue
           let tempResult = tempValue &+ registers.A
           let tempX = tempResult & 0x08
           let tempY = (tempResult & 0x02) << 4
           registers.F = registers.F & ~z80Flags.X.rawValue & ~z80Flags.Y.rawValue & ~z80Flags.ParityOverflow.rawValue
           registers.F = registers.F | tempX | tempY
           if registers.BC != 0
           {
               registers.F = registers.F | z80Flags.ParityOverflow.rawValue
           }
           tStates = tStates + 16
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           incrementR(opcodeCount:2)
       case 0xA9: // CPD - ED A9 - Compares the value of the memory location pointed to by HL with A. Then HL and BC are decremented. p/v is reset if BC becomes zero and set otherwise
           logInstructionDetails(instructionDetails: "CPD", opcode: [0xED,0xA9], programCounter: registers.PC)
           registers.WZ = registers.WZ &- 1
           let tempValue = bus.readByte(address: registers.HL)
           let oldCarry = registers.F & z80Flags.Carry.rawValue
           let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: tempValue)
           let tempResult = registers.A &- tempValue &- ((tempFlags & z80Flags.HalfCarry.rawValue) >> 4)
           let tempX = tempResult & 0x08
           let tempY = (tempResult & 0x02) << 4
           registers.F = tempFlags
           registers.F = registers.F & ~z80Flags.X.rawValue & ~z80Flags.Y.rawValue & ~z80Flags.ParityOverflow.rawValue & ~z80Flags.Carry.rawValue
           registers.F = registers.F | tempX | tempY | z80Flags.Negative.rawValue | oldCarry
           registers.HL = registers.HL &- 1
           registers.BC = registers.BC &- 1
           if registers.BC != 0
           {
               registers.F = registers.F | z80Flags.ParityOverflow.rawValue
           }
           tStates = tStates + 16
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           incrementR(opcodeCount:2)
       case 0xAA: // IND - ED AA - A byte from port C is written to the memory location pointed to by HL. Then HL and B are decremented
           logInstructionDetails(instructionDetails: "IND", opcode: [0xED,0xAA], programCounter: registers.PC)
           registers.WZ = registers.BC &- 1
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           let tempValue = bus.readPort(portNum: tempResult)
           bus.writeByte(address: registers.HL, value: tempValue)
           registers.HL = registers.HL &- 1
           registers.B = registers.B &- 1
           let tempNegative : UInt8 = (tempValue & 0x80) >> 6
           let tempResultFlags = UInt16(tempValue) + UInt16(registers.C &- 1)
           let tempCarry : UInt8 = tempResultFlags > 0xFF ? 0x01 : 0x00
           let tempHalfCarry : UInt8 = tempResultFlags > 0xFF ? 0x10 : 0x00
           let tempParityCalc = UInt8(tempResultFlags & 0x07) ^ registers.B
           let tempParityOverflow: UInt8 = tempParityCalc.nonzeroBitCount % 2 == 0 ? 0x04 : 0x00
           let tempSign = registers.B & z80Flags.Sign.rawValue
           let tempZero: UInt8 = registers.B == 0 ? z80Flags.Zero.rawValue : 0
           let tempY = registers.B & z80Flags.Y.rawValue
           let tempX = registers.B & z80Flags.X.rawValue
           registers.F = tempSign | tempZero | tempY | tempHalfCarry | tempX | tempParityOverflow | tempNegative | tempCarry
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 16
           incrementR(opcodeCount:2)
       case 0xAB: // OUTD - ED AB - B is decremented. A byte from the memory location pointed to by HL is written to port C. Then HL is decremented
           logInstructionDetails(instructionDetails: "OUTD", opcode: [0xED,0xAB], programCounter: registers.PC)
           (registers.B,registers.F) = z80FastFlags.decHelper(operand: registers.B, currentFlags: registers.F)
           registers.WZ = registers.BC &- 1
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           let tempValue = bus.readByte(address: registers.HL)
           bus.writePort(portNum: tempResult, portValue: tempValue)
           registers.HL = registers.HL &- 1
           let tempFlags = registers.F & ~z80Flags.Negative.rawValue & ~z80Flags.Carry.rawValue & ~z80Flags.HalfCarry.rawValue & ~z80Flags.ParityOverflow.rawValue
           let tempNegative : UInt8 = (tempValue & 0x80) >> 6
           let tempResultFlags = UInt16(tempValue) + UInt16(registers.L)
           let tempCarry : UInt8 = tempResultFlags > 0xFF ? 0x01 : 0x00
           let tempHalfCarry : UInt8 = tempResultFlags > 0xFF ? 0x10 : 0x00
           let tempParityCalc = UInt8(tempResultFlags & 0x07) ^ registers.B
           let tempParityOverflow: UInt8 = tempParityCalc.nonzeroBitCount % 2 == 0 ? 0x04 : 0x00
           registers.F = tempFlags | tempHalfCarry | tempParityOverflow | tempNegative | tempCarry
           registers.Q = registers.F
           tStates = tStates + 16
           registers.PC = registers.PC &+ 2
           incrementR(opcodeCount:2)
       case 0xB0: // LDIR - ED B0 - Transfers a byte of data from the memory location pointed to by HL to the memory location pointed to by DE. Then HL and DE are incremented and BC is decremented. If BC is not zero, this operation is repeated. Interrupts can trigger while this instruction is processing
           logInstructionDetails(instructionDetails: "LDIR", opcode: [0xED,0xB0], programCounter: registers.PC)
           let tempValue = bus.readByte(address: registers.HL)
           bus.writeByte(address: registers.DE, value : tempValue)
           registers.HL = registers.HL &+ 1
           registers.DE = registers.DE &+ 1
           registers.BC = registers.BC &- 1
           let tempResult = UInt8((UInt16(registers.A) + UInt16(tempValue)) & 0xFF)
           let tempX = UInt8(tempResult) & 0x08
           let tempY = UInt8(tempResult) & 0x02 << 4
           let tempParityOverflow = registers.BC != 0 ? z80Flags.ParityOverflow.rawValue : 0x00
           let tempSign = registers.F & z80Flags.Sign.rawValue
           let tempZero = registers.F & z80Flags.Zero.rawValue
           let tempCarry = registers.F & z80Flags.Carry.rawValue
           let tempHalfCarry = registers.F & z80Flags.HalfCarry.rawValue << 4
           let tempNegative : UInt8 = 0x00
           registers.F = tempSign | tempZero | tempY | tempHalfCarry
           registers.F = registers.F | tempX | tempNegative | tempParityOverflow | tempCarry
           let repeating = registers.BC != 0
           tStates = tStates + (repeating ? 21 : 16)
           registers.PC = registers.PC &+ (repeating ? 0 : 2)
           registers.WZ = registers.BC == 1 ? registers.WZ : registers.PC &+ 1
           registers.Q = registers.F
           incrementR(opcodeCount:2)
       case 0xB1: // CPIR - ED B1 - Compares the value of the memory location pointed to by HL with A. Then HL is incremented and BC is decremented. If BC is not zero and z is not set, this operation is repeated. p/v is reset if BC becomes zero and set otherwise, acting as an indicator that HL reached a memory location whose value equalled A before the counter went to zero. Interrupts can trigger while this instruction is processing
           logInstructionDetails(instructionDetails: "CPIR", opcode: [0xED,0xB1], programCounter: registers.PC)
           let tempValue = bus.readByte(address: registers.HL)
           let oldCarry = registers.F & z80Flags.Carry.rawValue
           let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: tempValue)
           let tempResult = registers.A &- tempValue &- ((tempFlags & z80Flags.HalfCarry.rawValue) >> 4)
           let tempX = tempResult & 0x08
           let tempY = (tempResult & 0x02) << 4
           registers.F = tempFlags
           registers.F = registers.F & ~z80Flags.X.rawValue & ~z80Flags.Y.rawValue & ~z80Flags.ParityOverflow.rawValue & ~z80Flags.Carry.rawValue
           registers.F = registers.F | tempX | tempY | z80Flags.Negative.rawValue | oldCarry
           registers.HL = registers.HL &+ 1
           registers.BC = registers.BC &- 1
           if registers.BC != 0
           {
               registers.F = registers.F | z80Flags.ParityOverflow.rawValue
           }
           let repeating = registers.BC != 0
           tStates = tStates + (repeating ? 21 : 16)
           registers.PC = registers.PC &+ (repeating ? 0 : 2)
           registers.WZ = registers.BC == 1 ? registers.WZ : registers.PC &+ 1
           incrementR(opcodeCount:2)
       case 0xB2: // INIR - ED B2 - A byte from port C is written to the memory location pointed to by HL. Then HL is incremented and B is decremented. If B is not zero, this operation is repeated. Interrupts can trigger while this instruction is processing
           logInstructionDetails(instructionDetails: "INIR", opcode: [0xED,0xB2], programCounter: registers.PC)
           let port = UInt16(registers.B) << 8 | UInt16(registers.C)

           let value = bus.readPort(portNum: port)

           bus.writeByte(address: registers.HL, value: value)

           registers.HL &+= 1
           registers.B &-= 1

           let sum = UInt16(value) + UInt16(registers.C) + 1

           // H and C
           let hcCarry = sum > 0xFF

           let carry: UInt8 =
               hcCarry ? z80Flags.Carry.rawValue : 0

           let halfCarry: UInt8 =
               hcCarry ? z80Flags.HalfCarry.rawValue : 0

           // N
           let negative: UInt8 =
               (value & 0x80) != 0
               ? z80Flags.Negative.rawValue
               : 0

           // PV
           let k = UInt8(sum & 0x07)

           let pvInput = k ^ registers.B

           let parityOverflow: UInt8 =
               pvInput.nonzeroBitCount % 2 == 0
               ? z80Flags.ParityOverflow.rawValue
               : 0

           // S,Z
           let sign = registers.B & z80Flags.Sign.rawValue

           let zero: UInt8 =
               registers.B == 0
               ? z80Flags.Zero.rawValue
               : 0

           // undocumented
           let wrappedSum = UInt8(truncatingIfNeeded: sum)

           let x = wrappedSum & z80Flags.X.rawValue
           let y = (wrappedSum & 0x02) << 4

           registers.F =
               sign |
               zero |
               y |
               halfCarry |
               x |
               parityOverflow |
               negative |
               carry

           registers.Q = registers.F

           let repeating = registers.B != 0

           if repeating
           {
               registers.WZ = registers.PC &+ 1
               tStates += 21
           }
           else
           {
               registers.PC &+= 2
               tStates += 16
           }

           incrementR(opcodeCount: 2)
       case 0xB3: // OTIR - ED B3 - B is decremented. A byte from the memory location pointed to by HL is written to port C. Then HL is incremented. If B is not zero, this operation is repeated. Interrupts can trigger while this instruction is processing
           logInstructionDetails(instructionDetails: "OTIR", opcode: [0xED,0xB3], programCounter: registers.PC)
           (registers.B,registers.F) = z80FastFlags.decHelper(operand: registers.B, currentFlags: registers.F)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           let tempValue = bus.readByte(address: registers.HL)
           bus.writePort(portNum: tempResult, portValue: tempValue)
           registers.HL = registers.HL &+ 1
           let tempFlags = registers.F & ~z80Flags.Negative.rawValue & ~z80Flags.Carry.rawValue & ~z80Flags.HalfCarry.rawValue & ~z80Flags.ParityOverflow.rawValue
           let tempNegative : UInt8 = (tempValue & 0x80) >> 6
           let tempResultFlags = UInt16(tempValue) + UInt16(registers.L)
           let tempCarry : UInt8 = tempResultFlags > 0xFF ? 0x01 : 0x00
           let tempHalfCarry : UInt8 = tempResultFlags > 0xFF ? 0x10 : 0x00
           let tempParityCalc = UInt8(tempResultFlags & 0x07) ^ registers.B
           let tempParityOverflow: UInt8 = tempParityCalc.nonzeroBitCount % 2 == 0 ? 0x04 : 0x00
           registers.F = tempFlags | tempHalfCarry | tempParityOverflow | tempNegative | tempCarry
           let repeating = registers.B != 0
           tStates = tStates + (repeating ? 21 : 16)
           registers.PC = registers.PC &+ (repeating ? 0 : 2)
           registers.WZ = registers.BC &- 1
           registers.Q = registers.F
           incrementR(opcodeCount:2)
       case 0xB8: // LDDR - ED B8 - Transfers a byte of data from the memory location pointed to by HL to the memory location pointed to by DE. Then HL, DE, and BC are decremented. If BC is not zero, this operation is repeated. Interrupts can trigger while this instruction is processing
           logInstructionDetails(instructionDetails: "LDDR", opcode: [0xED,0xB8], programCounter: registers.PC)
           let tempValue = bus.readByte(address: registers.HL)
           bus.writeByte(address: registers.DE, value : tempValue)
           registers.HL = registers.HL &- 1
           registers.DE = registers.DE &- 1
           registers.BC = registers.BC &- 1
           let tempResult = registers.A &+ tempValue
           let tempX = tempResult & 0x08
           let tempY = (tempResult & 0x02) << 4
           let tempParityOverflow = registers.BC != 0 ? z80Flags.ParityOverflow.rawValue : 0x00
           let tempFlags = registers.F & (z80Flags.Sign.rawValue | z80Flags.Zero.rawValue | z80Flags.Carry.rawValue)
           registers.F = tempFlags | tempY | tempX | tempParityOverflow // why is tempX calculating wrong
           //registers.F = tempFlags | tempY | tempParityOverflow // why is tempX calculating wrong
           let repeating = registers.BC != 0
           tStates = tStates + (repeating ? 21 : 16)
           registers.PC = registers.PC &+ (repeating ? 0 : 2)
           registers.WZ = registers.BC == 1 ? registers.WZ : registers.PC &+ 1
           registers.Q = registers.F
           incrementR(opcodeCount:2)
       case 0xB9: // CPDR - ED B9 - Compares the value of the memory location pointed to by HL with A. Then HL and BC are decremented. If BC is not zero and z is not set, this operation is repeated. p/v is reset if BC becomes zero and set otherwise, acting as an indicator that HL reached a memory location whose value equalled A before the counter went to zero. Interrupts can trigger while this instruction is processing
           logInstructionDetails(instructionDetails: "CPDR", opcode: [0xED,0xB9], programCounter: registers.PC)
           let tempValue = bus.readByte(address: registers.HL)
           let oldCarry = registers.F & z80Flags.Carry.rawValue
           let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: tempValue)
           let tempResult = registers.A &- tempValue &- ((tempFlags & z80Flags.HalfCarry.rawValue) >> 4)
           let tempX = tempResult & 0x08
           let tempY = (tempResult & 0x02) << 4
           registers.F = tempFlags
           registers.F = registers.F & ~z80Flags.X.rawValue & ~z80Flags.Y.rawValue & ~z80Flags.ParityOverflow.rawValue & ~z80Flags.Carry.rawValue
           registers.F = registers.F | tempX | tempY | z80Flags.Negative.rawValue | oldCarry
           registers.HL = registers.HL &- 1
           registers.BC = registers.BC &- 1
           if registers.BC != 0
           {
               registers.F = registers.F | z80Flags.ParityOverflow.rawValue
           }
           let repeating = registers.BC != 0
           tStates = tStates + (repeating ? 21 : 16)
           registers.PC = registers.PC &+ (repeating ? 0 : 2)
           registers.WZ = registers.BC == 1 ? registers.WZ : registers.PC &+ 1
           incrementR(opcodeCount:2)
       case 0xBA: // INDR - ED BA - A byte from port C is written to the memory location pointed to by HL. Then HL and B are decremented. If B is not zero, this operation is repeated. Interrupts can trigger while this instruction is processing.
           logInstructionDetails(instructionDetails: "INDR", opcode: [0xED,0xBA], programCounter: registers.PC)
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           let tempValue = bus.readPort(portNum: tempResult)
           bus.writeByte(address: registers.HL, value: tempValue)
           registers.HL = registers.HL &- 1
           (registers.B,registers.F) = z80FastFlags.decHelper(operand: registers.B, currentFlags: registers.F)
           let tempFlags = registers.F & ~z80Flags.Negative.rawValue & ~z80Flags.Carry.rawValue & ~z80Flags.HalfCarry.rawValue & ~z80Flags.ParityOverflow.rawValue
           let tempNegative : UInt8 = (tempValue & 0x80) >> 6
           let tempResultFlags = UInt16(tempValue) + UInt16(registers.C) - 1
           let tempCarry : UInt8 = tempResultFlags > 0xFF ? 0x01 : 0x00
           let tempHalfCarry : UInt8 = tempResultFlags > 0xFF ? 0x10 : 0x00
           let tempParityCalc = UInt8(tempResultFlags & 0x07) ^ registers.B
           let tempParityOverflow: UInt8 = tempParityCalc.nonzeroBitCount % 2 == 0 ? 0x04 : 0x00
           registers.F = tempFlags | tempHalfCarry | tempParityOverflow | tempNegative | tempCarry
           let repeating = registers.BC != 0
           tStates = tStates + (repeating ? 21 : 16)
           registers.PC = registers.PC &+ (repeating ? 0 : 2)
           registers.WZ = registers.BC == 1 ? registers.WZ : registers.PC &+ 1
           incrementR(opcodeCount:2)
       case 0xBB: // OTDR - ED BB - B is decremented. A byte from the memory location pointed to by HL is written to port C. Then HL is decremented. If B is not zero, this operation is repeated. Interrupts can trigger while this instruction is processing
           logInstructionDetails(instructionDetails: "OTDR", opcode: [0xED,0xBB], programCounter: registers.PC)
           (registers.B,registers.F) = z80FastFlags.decHelper(operand: registers.B, currentFlags: registers.F)
           registers.WZ = registers.BC &- 1
           let tempResult = UInt16(registers.B) << 8 | UInt16(registers.C)
           let tempValue = bus.readByte(address: registers.HL)
           bus.writePort(portNum: tempResult, portValue: tempValue)
           registers.HL = registers.HL &- 1
           let tempFlags = registers.F & ~z80Flags.Negative.rawValue & ~z80Flags.Carry.rawValue & ~z80Flags.HalfCarry.rawValue & ~z80Flags.ParityOverflow.rawValue
           let tempNegative : UInt8 = (tempValue & 0x80) >> 6
           let tempResultFlags = UInt16(tempValue) + UInt16(registers.L)
           let tempCarry : UInt8 = tempResultFlags > 0xFF ? 0x01 : 0x00
           let tempHalfCarry : UInt8 = tempResultFlags > 0xFF ? 0x10 : 0x00
           let tempParityCalc = UInt8(tempResultFlags & 0x07) ^ registers.B
           let tempParityOverflow: UInt8 = tempParityCalc.nonzeroBitCount % 2 == 0 ? 0x04 : 0x00
           registers.F = tempFlags | tempHalfCarry | tempParityOverflow | tempNegative | tempCarry
           let repeating = registers.BC != 0
           tStates = tStates + (repeating ? 21 : 16)
           registers.PC = registers.PC &+ (repeating ? 0 : 2)
           registers.WZ = registers.BC == 1 ? registers.WZ : registers.PC &+ 1
           registers.Q = registers.F
           incrementR(opcodeCount:2)
       default:
           logInstructionDetails(opcode: [0xED,opcode2], programCounter: registers.PC)
           registers.PC = registers.PC &+ 2
           registers.Q = 0
           tStates = tStates + 8
           incrementR(opcodeCount:2)
           // Assuming this is correct behaviour - confirm what decodes in missing ranges in real z80
       }
    }
    
    private func executeFDCBInstructions(opcode3: UInt8, opcode4: UInt8)
    {
        switch opcode4 // FD CB opcodes
        {
        case 0x00: // Undocumented - RLC (IY+$d),B - FD CB d 00 - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IY+$d),B", opcode: [0xFD,0xCB,opcode3,0x00], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x01: // Undocumented - RLC (IY+$d),C - FD CB d 01 - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IY+$d),C", opcode: [0xFD,0xCB,opcode3,0x01], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x02: // Undocumented - RLC (IY+$d),D - FD CB d 02 - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IY+$d),D", opcode: [0xFD,0xCB,opcode3,0x02], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x03: // Undocumented - RLC (IY+$d),E - FD CB d 03 - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IY+$d),E", opcode: [0xFD,0xCB,opcode3,0x03], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x04: // Undocumented - RLC (IY+$d),H - FD CB d 04 - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IY+$d),H", opcode: [0xFD,0xCB,opcode3,0x04], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x05: // Undocumented - RLC (IY+$d),L - FD CB d 05 - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IY+$d),L", opcode: [0xFD,0xCB,opcode3,0x05], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x06: // RLC (IY+$d) - FD CB d 06 - The contents of (IY+$d) are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0
            logInstructionDetails(instructionDetails: "RLC (IY+$d)", opcode: [0xFD,0xCB,opcode3,0x06], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let tempResult = (tempOldValue << 1) | (tempOldValue >> 7)
            let carry = (tempOldValue  & 0x80) >> 7
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | carry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x07: // Undocumented - RLC (IY+$d),A - FD CB d 07 - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RLC (IY+$d),A", opcode: [0xFD,0xCB,opcode3,0x07], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x08: // Undocumented - RRC (IY+$d),B - FD CB d 08 - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IY+$d),B", opcode: [0xFD,0xCB,opcode3,0x08], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x09: // Undocumented - RRC (IY+$d),C - FD CB d 09 - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IY+$d),C", opcode: [0xFD,0xCB,opcode3,0x09], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x0A: // Undocumented - RRC (IY+$d),D - FD CB d 0A - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IY+$d),D", opcode: [0xFD,0xCB,opcode3,0x0A], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x0B: // Undocumented - RRC (IY+$d),E - FD CB d 0B - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IY+$d),E", opcode: [0xFD,0xCB,opcode3,0x0B], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x0C: // Undocumented - RRC (IY+$d),H - FD CB d 0C - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IY+$d),H", opcode: [0xFD,0xCB,opcode3,0x0C], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x0D: // Undocumented - RRC (IY+$d),L - FD CB d 0D - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IY+$d),L", opcode: [0xFD,0xCB,opcode3,0x0D], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x0E: // RRC (IY+$d) - FD CB d 0E - The contents of (IY+$d) are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7
            logInstructionDetails(instructionDetails: "RRC (IY+$d)", opcode: [0xFD,0xCB,opcode3,0x0E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let carry = tempOldValue & 0x01
            let tempResult = (tempOldValue << 7) | (tempOldValue >> 1)
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | carry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x0F: // Undocumented - RRC (IY+$d),A - FD CB d 0F - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RRC (IY+$d),A", opcode: [0xFD,0xCB,opcode3,0x0F], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x10: // Undocumented - RL (IY+$d),B  - FD CB d 10 - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RL (IY+$d),B", opcode: [0xFD,0xCB,opcode3,0x10], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x11: // Undocumented - RL (IY+$d),C  - FD CB d 11  - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RL (IY+$d),C", opcode: [0xFD,0xCB,opcode3,0x11], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x12: // Undocumented - RL (IY+$d),D - FD CB d 12 - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RL (IY+$d),D", opcode: [0xFD,0xCB,opcode3,0x12], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x13: // Undocumented - RL (IY+$d),E - FD CB d 13 - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RL (IY+$d),E", opcode: [0xFD,0xCB,opcode3,0x13], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x14: // Undocumented - RL (IY+$d),H - FD CB d 14 - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RL (IY+$d),H", opcode: [0xFD,0xCB,opcode3,0x14], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x15: // Undocumented - RL (IY+$d),L - FD CB d 15 - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RL (IY+$d),L", opcode: [0xFD,0xCB,opcode3,0x15], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x16: // RL (IY+$d) - FD CB d 16 - The contents of (IY+$d) are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.
            logInstructionDetails(instructionDetails: "RL (IY+$d)", opcode: [0xFD,0xCB,opcode3,0x16], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let newCarry = (tempOldValue & 0x80) >> 7
            let oldCarry = registers.F & 0x01
            let tempResult = ((tempOldValue << 1) & 0xFE) | oldCarry
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | newCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x17: // Undocumented - RL (IY+$d),A - FD CB d 17  - The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RL (IY+$d),A", opcode: [0xFD,0xCB,opcode3,0x17], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x18: // Undocumented - RR (IY+$d),B - FD CB d 18 - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RR (IY+$d),B", opcode: [0xFD,0xCB,opcode3,0x18], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x19: // Undocumented - RR (IY+$d),C - FD CB d 19  - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RR (IY+$d),C", opcode: [0xFD,0xCB,opcode3,0x19], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x1A: // Undocumented - RR (IY+$d),D - FD CB d 1A - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RR (IY+$d),D", opcode: [0xFD,0xCB,opcode3,0x1A], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x1B: // Undocumented - RR (IY+$d),E - FD CB d 1B - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RR (IY+$d),E", opcode: [0xFD,0xCB,opcode3,0x1B], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x1C: // Undocumented - RR (IY+$d),H - FD CB d 1C - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RR (IY+$d),H", opcode: [0xFD,0xCB,opcode3,0x1C], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x1D: // Undocumented - RR (IY+$d),L - FD CB d 1D - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RR (IY+$d),L", opcode: [0xFD,0xCB,opcode3,0x1D], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x1E: // RR (IY+$d) - FD CB d 1E - The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7
            logInstructionDetails(instructionDetails: "RR (IY+$d)", opcode: [0xFD,0xCB,opcode3,0x1E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let newCarry = tempOldValue & 0x01
            let oldCarry = registers.F & 0x01
            let tempResult = (tempOldValue >> 1) | ( oldCarry << 7 )
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | newCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x1F: // Undocumented - RR (IY+$d),A - FD CB d 1F - The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RR (IY+$d),A", opcode: [0xFD,0xCB,opcode3,0x1F], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x20: // Undocumented - SLA (IY+$d),B - FD CB d 20 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IY+$d),B", opcode: [0xFD,0xCB,opcode3,0x20], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x21: // Undocumented - SLA (IY+$d),C - FD CB d 21 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IY+$d),C", opcode: [0xFD,0xCB,opcode3,0x21], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x22: // Undocumented - SLA (IY+$d),D - FD CB d 22 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IY+$d),D", opcode: [0xFD,0xCB,opcode3,0x22], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x23: // Undocumented - SLA (IY+$d),E - FD CB d 23 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IY+$d),E", opcode: [0xFD,0xCB,opcode3,0x23], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x24: // Undocumented - SLA (IY+$d),H - FD CB d 24 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IY+$d),H", opcode: [0xFD,0xCB,opcode3,0x24], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x25: // Undocumented - SLA (IY+$d),L - FD CB d 25 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IY+$d),L", opcode: [0xFD,0xCB,opcode3,0x25], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x26: // SLA (IY+$d) - FD CB d 26 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0
            logInstructionDetails(instructionDetails: "SLA (IY+$d)", opcode: [0xFD,0xCB,opcode3,0x26], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let newCarry = (tempOldValue & 0x80) >> 7
            let tempResult = tempOldValue << 1
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | newCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x27: // Undocumented - SLA (IY+$d),A - FD CB d 27 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SLA (IY+$d),A", opcode: [0xFD,0xCB,opcode3,0x27], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x28: // Undocumented - SRA (IY+$d),B - FD CB d 28 - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IY+$d),B", opcode: [0xFD,0xCB,opcode3,0x28], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x29: // Undocumented - SRA (IY+$d),C - FD CB d 29 - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IY+$d),C", opcode: [0xFD,0xCB,opcode3,0x29], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x2A: // Undocumented - SRA (IY+$d),D - FD CB d 2A - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IY+$d),D", opcode: [0xFD,0xCB,opcode3,0x2A], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x2B: // Undocumented - SRA (IY+$d),E - FD CB d 2B - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IY+$d),E", opcode: [0xFD,0xCB,opcode3,0x2B], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x2C: // Undocumented - SRA (IY+$d),H - FD CB d 2C - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IY+$d),H", opcode: [0xFD,0xCB,opcode3,0x2C], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x2D: // Undocumented - SRA (IY+$d),L - FD CB d 2D - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IY+$d),L", opcode: [0xFD,0xCB,opcode3,0x2D], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
                incrementR(opcodeCount:2)
        case 0x2E: // SRA (IY+$d) - FD CB d 2E - The contents of (IY+$d) are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged
            logInstructionDetails(instructionDetails: "SRA (IY+$d)", opcode: [0xFD,0xCB,opcode3,0x2E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let newCarry = tempOldValue & 0x01
            let oldBitSeven = tempOldValue & 0x80
            let tempResult = (tempOldValue >> 1) | oldBitSeven
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | newCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x2F: // Undocumented - SRA (IY+$d),A - FD CB d 2F - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SRA (IY+$d),A", opcode: [0xFD,0xCB,opcode3,0x2F], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x30: // Undocumented - SLL (IY+$d),B - FD CB d 30 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IY+$d),B", opcode: [0xFD,0xCB,opcode3,0x30], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x31: // Undocumented - SLL (IY+$d),C - FD CB d 31 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IY+$d),C", opcode: [0xFD,0xCB,opcode3,0x31], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x32: // Undocumented - SLL (IY+$d),D - FD CB d 32 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IY+$d),D", opcode: [0xFD,0xCB,opcode3,0x32], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x33: // Undocumented - SLL (IY+$d),E - FD CB d 33 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IY+$d),E", opcode: [0xFD,0xCB,opcode3,0x33], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x34: // Undocumented - SLL (IY+$d),H - FD CB d 34 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IY+$d),H", opcode: [0xFD,0xCB,opcode3,0x34], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x35: // Undocumented - SLL (IY+$d),L - FD CB d 35 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IY+$d),L", opcode: [0xFD,0xCB,opcode3,0x35], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x36: // Undocumented - SLL (IY+$d) - FD CB d 36 - The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IY+$d)", opcode: [0xFD,0xCB,opcode3,0x36], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x37: // Undocumented - SLL (IY+$d),A - FD CB d 37- The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SLL (IY+$d),A", opcode: [0xFD,0xCB,opcode3,0x37], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x38: // Undocumented - SRL (IY+$d),B - FD CB d 38 - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IY+$d),B", opcode: [0xFD,0xCB,opcode3,0x38], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x39: // Undocumented - SRL (IY+$d),C - FD CB d 39 - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IY+$d),C", opcode: [0xFD,0xCB,opcode3,0x39], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x3A: // Undocumented - SRL (IY+$d),D - FD CB d 3A - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IY+$d),D", opcode: [0xFD,0xCB,opcode3,0x3A], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x3B: // Undocumented - SRL (IY+$d),E - FD CB d 3B - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IY+$d),E", opcode: [0xFD,0xCB,opcode3,0x3B], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x3C: // Undocumented - SRL (IY+$d),H - FD CB d 3C - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IY+$d),H", opcode: [0xFD,0xCB,opcode3,0x3C], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x3D: // Undocumented - SRL (IY+$d),L - FD CB d 3D - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IY+$d),L", opcode: [0xFD,0xCB,opcode3,0x3D], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x3E: // SRL (IY+$d) - FD CB d 3E - The contents of SRL (IY+$d) are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7
            logInstructionDetails(instructionDetails: "SRL (IY+$d)", opcode: [0xFD,0xCB,opcode3,0x3E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempOldValue = bus.readByte(address: tempResultAddress)
            let newCarry = tempOldValue & 0x01
            let tempResult = tempOldValue >> 1
            (_,registers.F) = z80FastFlags.logicHelper(tempResult: tempResult)
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | newCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x3F: // Undocumented - SRL (IY+$d),A - FD CB d 3F - The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SRL (IY+$d),A", opcode: [0xFD,0xCB,opcode3,0x3F], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x40: // Undocumented - BIT 0,(IY+$d) - FD CB d 40 - Tests bit 0 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x40], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x41: // Undocumented - BIT 0,(IY+$d) - FD CB d 41 - Tests bit 0 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x41], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x42: // Undocumented - BIT 0,(IY+$d) - FD CB d 42 - Tests bit 0 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x42], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x43: // Undocumented - BIT 0,(IY+$d) - FD CB d 43 - Tests bit 0 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x43], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x44: // Undocumented - BIT 0,(IY+$d) - FD CB d 44 - Tests bit 0 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x44], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x45: // Undocumented - BIT 0,(IY+$d) - FD CB d 45 - Tests bit 0 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x45], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x46: // BIT 0,(IY+$d) - FD CB d 46 - Tests bit 0 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x46], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x01) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x01) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x47: // Undocumented - BIT 0,(IY+$d) - FD CB d 47 - Tests bit 0 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x47], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 1
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x48: // Undocumented - BIT 1,(IY+$d) - FD CB d 48 - Tests bit 1 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x48], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x49: // Undocumented - BIT 1,(IY+$d) - FD CB d 49 - Tests bit 1 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x49], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x4A: // Undocumented - BIT 1,(IY+$d) - FD CB d 4A - Tests bit 1 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x4A], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x4B: // Undocumented - BIT 1,(IY+$d) - FD CB d 4B - Tests bit 1 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x4B], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x4C: // Undocumented - BIT 1,(IY+$d) - FD CB d 4C - Tests bit 1 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x4C], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x4D: // Undocumented - BIT 1,(IY+$d) - FD CB d 4D - Tests bit 1 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x4D], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x4E: // BIT 1,(IY+$d) - FD CB d 4E - Tests bit 1 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x4E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x02) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x02) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x4F: // Undocumented - BIT 1,(IY+$d) - FD CB d 4F - Tests bit 1 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x4F], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 2
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x50: // Undocumented - BIT 2,(IY+$d) - FD CB d 50 - Tests bit 2 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x50], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x51: // Undocumented - BIT 2,(IY+$d) - FD CB d 51 - Tests bit 2 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x51], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x52: // Undocumented - BIT 2,(IY+$d) - FD CB d 52 - Tests bit 2 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x52], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x53: // Undocumented - BIT 2,(IY+$d) - FD CB d 53 - Tests bit 2 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x53], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x54: // Undocumented - BIT 2,(IY+$d) - FD CB d 54 - Tests bit 2 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x54], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x55: // Undocumented - BIT 2,(IY+$d) - FD CB d 55 - Tests bit 2 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x55], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x56: // BIT 2,(IY+$d) - FD CB d 56 - Tests bit 2 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x56], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x04) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x04) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x57: // Undocumented - BIT 2,(IY+$d) - FD CB d 57 - Tests bit 2 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x57], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 4
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x58: // Undocumented - BIT 3,(IY+$d) - FD CB d 58 - Tests bit 3 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x58], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x59: // Undocumented - BIT 3,(IY+$d) - FD CB d 59 - Tests bit 3 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x59], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x5A: // Undocumented - BIT 3,(IY+$d) - FD CB d 5A - Tests bit 3 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x5A], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x5B: // Undocumented - BIT 3,(IY+$d) - FD CB d 5B - Tests bit 3 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x5B], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x5C: // Undocumented - BIT 3,(IY+$d) - FD CB d 5C - Tests bit 3 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x5C], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x5D: // Undocumented - BIT 3,(IY+$d) - FD CB d 5D - Tests bit 3 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x5D], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x5E: // BIT 3,(IY+$d) - FD CB d 5E - Tests bit 3 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x5E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x08) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x08) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x5F: // Undocumented - BIT 3,(IY+$d) - FD CB d 5F - Tests bit 3 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x5F], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 8
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x60: // Undocumented - BIT 4,(IY+$d) - FD CB d 60 - Tests bit 4 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x60], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x61: // Undocumented - BIT 4,(IY+$d) - FD CB d 61 - Tests bit 4 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x61], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x62: // Undocumented - BIT 4,(IY+$d) - FD CB d 62 - Tests bit 4 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x62], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x63: // Undocumented - BIT 4,(IY+$d) - FD CB d 63 - Tests bit 4 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x63], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x64: // Undocumented - BIT 4,(IY+$d) - FD CB d 64 - Tests bit 4 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x64], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x65: // Undocumented - BIT 4,(IY+$d) - FD CB d 65 - Tests bit 4 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x65], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x66: // BIT 4,(IY+$d) - FD CB d 66 - Tests bit 4 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x66], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x10) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x10) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x67: // Undocumented - BIT 4,(IY+$d) - FD CB d 67 - Tests bit 4 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x67], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 16
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x68: // Undocumented - BIT 5,(IY+$d) - FD CB d 68 - Tests bit 5 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x68], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x69: // Undocumented - BIT 5,(IY+$d) - FD CB d 69 - Tests bit 5 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x69], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x6A: // Undocumented - BIT 5,(IY+$d) - FD CB d 6A - Tests bit 5 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x6A], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x6B: // Undocumented - BIT 5,(IY+$d) - FD CB d 6B - Tests bit 5 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x6B], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x6C: // Undocumented - BIT 5,(IY+$d) - FD CB d 6C - Tests bit 5 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x6C], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x6D: // Undocumented - BIT 5,(IY+$d) - FD CB d 6D - Tests bit 5 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x6D], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x6E: // BIT 5,(IY+$d) - FD CB d 6E - Tests bit 5 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x6E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x20) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x20) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x6F: // Undocumented - BIT 5,(IY+$d) - FD CB d 6F - Tests bit 5 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x6F], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 32
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x70: // Undocumented - BIT 6,(IY+$d) - FD CB d 70 - Tests bit 6 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x70], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x71: // Undocumented - BIT 6,(IY+$d) - FD CB d 71 - Tests bit 6 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x71], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x72: // Undocumented - BIT 6,(IY+$d) - FD CB d 72 - Tests bit 6 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x72], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x73: // Undocumented - BIT 6,(IY+$d) - FD CB d 73 - Tests bit 6 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x73], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x74: // Undocumented - BIT 6,(IY+$d) - FD CB d 74 - Tests bit 6 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x74], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x75: // Undocumented - BIT 6,(IY+$d) - FD CB d 75 - Tests bit 6 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x75], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x76: // BIT 6,(IY+$d) - FD CB d 76 - Tests bit 6 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x76], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let newZero : UInt8 = (tempResult & 0x40) == 0 ? 0x40 : 0x00  // change mask for bit position
            let newParityOverflow : UInt8 = (tempResult & 0x40) == 0 ? 0x04 : 0x00 // ParityOverflow  matches Zero for BIT instructions
            let newHalfCarry : UInt8 = 0x10 // Always 1
            let newNegative : UInt8 = 0x00 // Always 0
            let newSign : UInt8 = 0x00  // set if bit 7, reset otherwise
            let oldCarry = registers.F & 0x01 // Preserve old carry
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newY = WZH & 0x20
            let newX = WZH & 0x08
            registers.F = newSign | newZero | newY | newHalfCarry
            registers.F = registers.F | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x77: // Undocumented - BIT 6,(IY+$d) - FD CB d 77 - Tests bit 6 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x77], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 64
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x78: // Undocumented - BIT 7,(IY+$d) - FD CB d 78 - Tests bit 7 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x78], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x79: // Undocumented - BIT 7,(IY+$d) - FD CB d 79 - Tests bit 7 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x79], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x7A: // Undocumented - BIT 7,(IY+$d) - FD CB d 7A - Tests bit 7 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x7A], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x7B: // Undocumented - BIT 7,(IY+$d) - FD CB d 7B - Tests bit 7 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x7B], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x7C: // Undocumented - BIT 7,(IY+$d) - FD CB d 7C - Tests bit 7 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x7C], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x7D: // Undocumented - BIT 7,(IY+$d) - FD CB d 7D - Tests bit 7 of the memory location pointed to by IY plus $d L
            logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x7D], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x7E: // BIT 7,(IY+$d) - FD CB d 7E - Tests bit 7 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x7E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress)
            registers.WZ = tempResultAddress
            let bitSet = (tempResult & 0x80) != 0
            let newZero: UInt8 = bitSet ? 0x00 : 0x40
            let newParityOverflow: UInt8 = bitSet ? 0x00 : 0x04
            let newHalfCarry: UInt8 = 0x10
            let newNegative: UInt8 = 0x00
            let newSign: UInt8 = bitSet ? 0x80 : 0x00
            let oldCarry = registers.F & 0x01
            let WZH = UInt8((tempResultAddress >> 8) & 0xFF)
            let newX = WZH & 0x08
            let newY = WZH & 0x20
            registers.F = newSign | newZero | newY | newHalfCarry | newX | newParityOverflow | newNegative | oldCarry
            registers.PC = registers.PC &+ 4
            registers.Q = registers.F
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x7F: // Undocumented - BIT 7,(IY+$d) - FD CB d 7F - Tests bit 7 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "BIT 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x7F], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 128
            registers.F = (registers.F & ~z80Flags.Zero.rawValue) | ((tempResult ^ 1) << 6)
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.PC = registers.PC &+ 4
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x80: // Undocumented - RES 0,(IY+$d),B - FD CB d 80 - Resets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0x80], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x81: // Undocumented - RES 0,(IY+$d),C - FD CB d 81 - Resets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0x81], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x82: // Undocumented - RES 0,(IY+$d),D - FD CB d 82 - Resets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0x82], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x83: // Undocumented - RES 0,(IY+$d),E - FD CB d 83 - Resets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0x83], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x84: // Undocumented - RES 0,(IY+$d),H - FD CB d 84 - Resets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0x84], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x85: // Undocumented - RES 0,(IY+$d),L - FD CB d 85 - Resets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0x85], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x86: // RES 0,(IY+$d) - FD CB d 86 - Resets bit 0 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "RES 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x86], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b11111110
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x87: // Undocumented - RES 0,(IY+$d),A - FD CB d 87 - Resets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 0,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0x87], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x88: // Undocumented - RES 1,(IY+$d),B - FD CB d 88 - Resets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0x88], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x89: // Undocumented - RES 1,(IY+$d),C - FD CB d 89 - Resets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0x89], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x8A: // Undocumented - RES 1,(IY+$d),D - FD CB d 8A - Resets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0x8A], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x8B: // Undocumented - RES 1,(IY+$d),E - FD CB d 8B - Resets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0x8B], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x8C: // Undocumented - RES 1,(IY+$d),H - FD CB d 8C - Resets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0x8C], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x8D: // Undocumented - RES 1,(IY+$d),L - FD CB d 8D - Resets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0x8D], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x8E: // RES 1,(IY+$d) - FD CB d 8E - Resets bit 1 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "RES 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x8E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b11111101
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x8F: // Undocumented - RES 1,(IY+$d),A - FD CB d 8F - Resets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 1,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0x8F], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x90: // Undocumented - RES 2,(IY+$d),B - FD CB d 90 - Resets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0x90], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x91: // Undocumented - RES 2,(IY+$d),C - FD CB d 91 - Resets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0x91], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
        incrementR(opcodeCount:2)
        case 0x92: // Undocumented - RES 2,(IY+$d),D - FD CB d 92 - Resets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0x92], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x93: // Undocumented - RES 2,(IY+$d),E - FD CB d 93 - Resets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0x93], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x94: // Undocumented - RES 2,(IY+$d),H - FD CB d 94 - Resets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0x94], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x95: // Undocumented - RES 2,(IY+$d),L - FD CB d 95 - Resets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0x95], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x96: // RES 2,(IX+$d) - FD CB d 96 - Resets bit 2 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "RES 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x96], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b11111011
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x97: // Undocumented - RES 2,(IY+$d),A - FD CB d 97 - Resets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 2,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0x97], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x98: // Undocumented - RES 3,(IY+$d),B - FD CB d 98 - Resets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0x98], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x99: // Undocumented - RES 3,(IY+$d),C - FD CB d 99 - Resets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0x99], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x9A: // Undocumented - RES 3,(IY+$d),D - FD CB d 9A - Resets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0x9A], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x9B: // Undocumented - RES 3,(IY+$d),E - FD CB d 9B - Resets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0x9B], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x9C: // Undocumented - RES 3,(IY+$d),H - FD CB d 9C - Resets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0x9C], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x9D: // Undocumented - RES 3,(IY+$d),L - FD CB d 9D - Resets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0x9D], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x9E: // RES 3,(IX+$d) - FD CB d 9E - Resets bit 3 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "RES 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0x9E], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b11110111
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x9F: // Undocumented - RES 3,(IY+$d),A - FD CB d 9F - Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 3,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0x9F], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA0: // Undocumented - RES 4,(IY+$d),B - FD CB d A0 - Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0xA0], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA1: // Undocumented - RES 4,(IY+$d),C - FD CB d A1 - Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0xA1], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA2: // Undocumented - RES 4,(IY+$d),D - FD CB d A2 - Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0xA2], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA3: // Undocumented - RES 4,(IY+$d),E - FD CB d A3 - Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0xA3], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA4: // Undocumented - RES 4,(IY+$d),H - FD CB d A4 - Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0xA4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA5: // Undocumented - RES 4,(IY+$d),L - FD CB d 24 - Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0xA5], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA6: // RES 4,(IY+$d) - FD CB d A6 - Resets bit 4 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "RES 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xA6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b11101111
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA7: // Undocumented - RES 4,(IY+$d),A - FD CB d A7 - Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 4,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0xA7], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA8: // Undocumented - RES 5,(IY+$d),B - FD CB d A8 - Resets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0xA8], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xA9: // Undocumented - RES 5,(IY+$d),C - FD CB d A9 - Resets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0xA9], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xAA: // Undocumented - RES 5,(IY+$d),D - FD CB d AA - Resets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0xAA], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xAB: // Undocumented - RES 5,(IY+$d),E - FD CB d AB - Resets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0xAB], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xAC: // Undocumented - RES 5,(IY+$d),H - FD CB d AC - Resets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0xAC], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xAD: // Undocumented - RES 5,(IY+$d),L - FD CB d AD - Resets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0xAD], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xAE: // RES 5,(IY+$d) - FD CB d AE - Resets bit 5 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "RES 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xAE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b11011111
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xAF: // Undocumented - RES 5,(IY+$d),A - FD CB d AF - Resets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 5,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0xAF], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB0: // Undocumented - RES 6,(IY+$d),B - FD CB d B0 - Resets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0xB0], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB1: // Undocumented - RES 6,(IY+$d),C - FD CB d B1 - Resets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0xB1], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB2: // Undocumented - RES 6,(IY+$d),D - FD CB d B2 - Resets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0xB2], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB3: // Undocumented - RES 6,(IY+$d),E - FD CB d B3 - Resets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0xB3], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB4: // Undocumented - RES 6,(IY+$d),H - FD CB d B4 - Resets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0xB4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB5: // Undocumented - RES 6,(IY+$d),L - FD CB d B5 - Resets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0xB5], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
        case 0xB6: // RES 6,(IY+$d) - FD CB d B6 - Resets bit 6 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "RES 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xB6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b10111111
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB7: // Undocumented - RES 6,(IY+$d),A - FD CB d B7 - Resets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 6,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0xB7], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB8: // Undocumented - RES 7,(IY+$d),B - FD CB d B8 - Resets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0xB8], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xB9: // Undocumented - RES 7,(IY+$d),C - FD CB d B9 - Resets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0xB9], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xBA: // Undocumented - RES 7,(IY+$d),D - FD CB d BA - Resets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0xBA], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xBB: // Undocumented - RES 7,(IY+$d),E - FD CB d BB - Resets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0xBB], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xBC: // Undocumented - RES 7,(IY+$d),H - FD CB d BC - Resets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0xBC], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xBD: // Undocumented - RES 7,(IY+$d),L - FD CB d BD - Resets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0xBD], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xBE: // RES 7,(IY+$d) - FD CB d BE - Resets bit 7 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "RES 7,(IY+$d)", opcode: [0xFD,0xDB,opcode3,0xBE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) & 0b01111111
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xBF: // Undocumented - RES 7,(IY+$d),A - FD CB d BF - Resets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "RES 7,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0xBF], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC0: // Undocumented - SET 0,(IY+$d),B - FD CB d C0 - Sets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0xC0], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC1: // Undocumented - SET 0,(IY+$d),C - FD CB d C1 - Sets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0xC1], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC2: // Undocumented - SET 0,(IY+$d),D - FD CB d C2 - Sets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0xC2], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC3: // Undocumented - SET 0,(IY+$d),E - FD CB d C3 - Sets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0xC3], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC4: // Undocumented - SET 0,(IY+$d),H - FD CB d C4 - Sets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0xC4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC5: // Undocumented - SET 0,(IY+$d),L  - FD CB d C5 - Sets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0xC5], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC6: // SET 0,(IY+$d) - FD CB d C6 - Sets bit 0 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "SET 0,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xC6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b00000001
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC7: // Undocumented - SET 0,(IY+$d),A - FD CB d C7 - Sets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 0,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0xC7], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC8: // Undocumented - SET 1,(IY+$d),B - FD CB d C8 - Sets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0xC8], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xC9: // Undocumented - SET 1,(IY+$d),C - FD CB d C9 - Sets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0xC9], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xCA: // Undocumented - SET 1,(IY+$d),D - FD CB d CA - Sets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0xCA], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xCB: // Undocumented - SET 1,(IY+$d),E - FD CB d CB - Sets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0xCB], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xCC: // Undocumented - SET 1,(IY+$d),H - FD CB d CC - Sets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0xCC], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xCD: // Undocumented - SET 1,(IY+$d),L - FD CB d CD - Sets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0xCD], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xCE: // SET 1,(IY+$d) - FD CB d CE - Sets bit 1 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "SET 1,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xCE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b00000010
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xCF: // Undocumented - SET 1,(IY+$d),A - FD CB d CF - Sets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 1,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0xCF], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD0: // Undocumented - SET 2,(IY+$d),B - FD CB d D0 - Sets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 2,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0xD0], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD1: // Undocumented - SET 2,(IY+$d),C - FD CB d D1 - Sets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 2,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0xD1], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD2: // Undocumented - SET 2,(IY+$d),D - FD CB d D2 - Sets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 2,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0xD2], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD3: // Undocumented - SET 2,(IY+$d),E - FD CB d D3 - Sets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 2,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0xD3], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD4: // Undocumented - SET 2,(IY+$d),H - FD CB d D4 - Sets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 2,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0xD4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD5: // Undocumented - SET 2,(IY+$d),L - FD CB d D5 - Sets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 2,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0xD5], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD6: // SET 2,(IY+$d) - FD CB d D6 - Sets bit 2 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "SET 2,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xD6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b00000100
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD7: // Undocumented - SET 3,(IY+$d),B - FD CB d D8 - Sets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0xD8], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xD9: // Undocumented - SET 3,(IY+$d),C - FD CB d D9 - Sets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0xD9], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xDA: // Undocumented - SET 3,(IY+$d),D - FD CB d DA - Sets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0xDA], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xDB: // Undocumented - SET 3,(IY+$d),E - FD CB d DB - Sets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0xDB], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xDC: // Undocumented - SET 3,(IY+$d),H - FD CB d DC - Sets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0xDC], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xDD: // Undocumented - SET 3,(IY+$d),L - FD CB d DD - Sets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0xDD], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xDE: // SET 3,(IY+$d) - FD CB d DE - Sets bit 3 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "SET 3,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xDE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b00001000
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xDF: // Undocumented - SET 3,(IY+$d),A - FD CB d DF - Sets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 3,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0xDF], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE0: // Undocumented - SET 4,(IY+$d),B - FD CB d E0 - Sets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0xE0], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE1: // Undocumented - SET 4,(IY+$d),C - FD CB d E1 - Sets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0xE1], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE2: // Undocumented - SET 4,(IY+$d),D - FD CB d E2 - Sets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0xE2], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE3: // Undocumented - SET 4,(IY+$d),E - FD CB d E3 - Sets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0xE3], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE4: // Undocumented - SET 4,(IY+$d),H - FD CB d E4 - Sets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0xE4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE5: // Undocumented - SET 4,(IY+$d),L - FD CB d E5 - Sets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0xE5], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE6: // SET 4,(IY+$d) - FD CB d E6 - Sets bit 4 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "SET 4,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xE6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b00010000
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE7: // Undocumented - SET 4,(IY+$d),A - FD CB d E7 - Sets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 4,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0xE7], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE8: // Undocumented - SET 5,(IY+$d),B - FD CB d E8 - Sets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0xE8], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE9: // Undocumented - SET 5,(IY+$d),C - FD CB d E9 - Sets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0xE9], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xEA: // Undocumented - SET 5,(IY+$d),D - FD CB d EA - Sets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0xEA], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xEB: // Undocumented - SET 5,(IY+$d),E - FD CB d EB - Sets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0xEB], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xEC: // Undocumented - SET 5,(IY+$d),H - FD CB d EC - Sets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0xEC], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xED: // Undocumented - SET 5,(IY+$d),L - FD CB d ED - Sets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0xED], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xEE: // SET 5,(IY+$d) - FD CB d EE - Sets bit 5 of the memory location pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "SET 5,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xEE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b00100000
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xEF: // Undocumented - SET 5,(IY+$d),A - FD CB d EF - Sets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 5,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0xEF], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF0: // Undocumented - SET 6,(IY+$d),B - FD CB d F0 - Sets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0xF0], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF1: // Undocumented - SET 6,(IY+$d),C - FD CB d F1 - Sets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0xF1], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF2: // Undocumented - SET 6,(IY+$d),D - FD CB d F2 - Sets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0xF2], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF3: // Undocumented - SET 6,(IY+$d),E - FD CB d F3 - Sets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0xF3], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF4: // Undocumented - SET 6,(IY+$d),H - FD CB d F4 - Sets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0xF4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF5: // Undocumented - SET 6,(IY+$d),L - FD CB d F5 - Sets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0xF5], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF6: // SET 6,(IY+$d) - FD CB d F6 - Sets bit 6 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "SET 6,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xF6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b01000000
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF7: // Undocumented - SET 6,(IY+$d),A - FD CB d F7 - Sets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 6,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0xF7], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF8: // Undocumented - SET 7,(IY+$d),B - FD CB d F8 - Sets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in B
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IY+$d),B", opcode: [0xFD,0xCB,opcode3,0xF8], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xF9: // Undocumented - SET 7,(IY+$d),C - FD CB d F9 - Sets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in C
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IY+$d),C", opcode: [0xFD,0xCB,opcode3,0xF9], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xFA: // Undocumented - SET 7,(IY+$d),D - FD CB d FA - Sets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in D
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IY+$d),D", opcode: [0xFD,0xCB,opcode3,0xFA], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xFB: // Undocumented - SET 7,(IY+$d),E - FD CB d FB - Sets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in E
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IY+$d),E", opcode: [0xFD,0xCB,opcode3,0xFB], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xFC: // Undocumented - SET 7,(IY+$d),H - FD CB d FC - Sets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in H
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IY+$d),H", opcode: [0xFD,0xCB,opcode3,0xFC], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xFD: // Undocumented - SET 7,(IY+$d),L - FD CB d FD - Sets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in L
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IY+$d),L", opcode: [0xFD,0xCB,opcode3,0xFD], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xFE: // SET 7,(IY+$d) - FD CB d FE - Sets bit 7 of the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "SET 7,(IY+$d)", opcode: [0xFD,0xCB,opcode3,0xFE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            let tempResult = bus.readByte(address: tempResultAddress) | 0b10000000
            bus.writeByte(address: tempResultAddress, value: tempResult)
            registers.WZ = tempResultAddress
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xFF: // Undocumented - SET 7,(IY+$d),A - FD CB d FF - Sets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in A
            // Stub
            logInstructionDetails(instructionDetails: "SET 7,(IY+$d),A", opcode: [0xFD,0xCB,opcode3,0xFF], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        default:
            logInstructionDetails(opcode: [0xFD,0xCB,opcode3,opcode4], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        }
    }
        
    private func executeFDInstructions(opcode2: UInt8, opcode3: UInt8, opcode4: UInt8)
    {
        switch opcode2
        {
        case 0x04: // Undocumented - INC B - FD 04 - Adds one to B
            // Stub
            logInstructionDetails(instructionDetails: "INC B", opcode: [0xFD,0x04], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x05: // Undocumented - DEC B - FD 05 - Subtracts one from B
            // Stub
            logInstructionDetails(instructionDetails: "DEC B", opcode: [0xFD,0x05], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x06: // Undocumented - LD B,$n - FD 06 n - Loads $n into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,$n", opcode: [0xFD,0x06], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x09: // ADD IY,BC - FD 09 - The value of BC is added to IY
            logInstructionDetails(instructionDetails: "ADD IY,BC", opcode: [0xDD,0x09], programCounter: registers.PC)
            registers.WZ = registers.IY &+ 1
            let tempResult = registers.IY &+ registers.BC
            let halfCarry = ((registers.IY ^ registers.BC ^ tempResult) & 0x1000) != 0 ? z80Flags.HalfCarry.rawValue : 0
            let carrytempResult = UInt32(registers.IY) + UInt32(registers.BC)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.IY = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = (registers.F & ~z80Flags.HalfCarry.rawValue) | halfCarry
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.IYH & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.IYH & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.PC = registers.PC &+ 2
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x0C: // Undocumented - INC C - FD 0C - Adds one to C
            // Stub
            logInstructionDetails(instructionDetails: "INC C", opcode: [0xFD,0x0C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x0D: // Undocumented - DEC C - FD 0D - Subtracts one from C
            // Stub
            logInstructionDetails(instructionDetails: "DEC C", opcode: [0xFD,0x0D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x0E: // Undocumented - LD C,$n - FD 0E n - Loads n into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,$n", opcode: [0xFD,0x0E], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x14: // Undocumented - INC D - FD 14 - Adds one to D
            // Stub
            logInstructionDetails(instructionDetails: "INC D", opcode: [0xFD,0x14], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x15: // Undocumented - DEC D - FD 15 - Subtracts one from D
            // Stub
            logInstructionDetails(instructionDetails: "DEC D", opcode: [0xFD,0x15], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x16: // Undocumented - LD D,$n - FD 16 n - Loads $n into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,$n", opcode: [0xFD,0x16], values: [opcode3,opcode4], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x19: // ADD IY,DE - FD 19 - The value of DE is added to IY
            logInstructionDetails(instructionDetails: "ADD IY,DE", opcode: [0xDD,0x19], programCounter: registers.PC)
            registers.WZ = registers.IY &+ 1
            let tempResult = registers.IY &+ registers.DE
            let halfCarry = ((registers.IY ^ registers.DE ^ tempResult) & 0x1000) != 0 ? z80Flags.HalfCarry.rawValue : 0
            let carrytempResult = UInt32(registers.IY) + UInt32(registers.DE)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.IY = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = (registers.F & ~z80Flags.HalfCarry.rawValue) | halfCarry
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.IYH & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.IYH & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.PC = registers.PC &+ 2
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x1C: // Undocumented - INC E - FD 1C - Adds one to E
            // Stub
            logInstructionDetails(instructionDetails: "INC E", opcode: [0xFD,0x1C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x1D: // Undocumented - DEC E - FD 1D - Subtracts one from E
            // Stub
            logInstructionDetails(instructionDetails: "DEC E", opcode: [0xFD,0x1D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x1E: // Undocumented - LD E,$n - FD 1E n - Loads n into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,$n", opcode: [0xFD,0x1E], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x21: // LD IY,$nn - FD 21 n n - Loads $nn into register IY
            logInstructionDetails(instructionDetails: "LD IY,$nn", opcode: [0xFD,0x21], values: [opcode3,opcode4], programCounter: registers.PC)
            registers.IY = UInt16(opcode4) << 8 | UInt16(opcode3)
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 14
            incrementR(opcodeCount:2)
        case 0x22: // LD ($nn),IY - FD 22 n n - Stores IY into the memory location pointed to by $nn
            logInstructionDetails(instructionDetails: "LD ($nn),IY", opcode: [0xFD,0x22], values: [opcode3,opcode4], programCounter: registers.PC)
            let tempResult =  UInt16(opcode4) << 8 | UInt16(opcode3)
            bus.writeByte(address: tempResult, value: registers.IYL)
            bus.writeByte(address: tempResult &+ 1, value: registers.IYH)
            registers.WZ = tempResult &+ 1
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x23: // INC IY - FD 23 - Adds one to IY
            logInstructionDetails(instructionDetails: "INC IY", opcode: [0xFD,0x23], programCounter: registers.PC)
            registers.IY = registers.IY &+ 1
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:2)
        case 0x24: // Undocumented - INC IYH - FD 24 - Adds one to IYH
            // Stub
            logInstructionDetails(instructionDetails: "INC IYH", opcode: [0xFD,0x24], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x25: // Undocumented - DEC IYH - FD 25 - Subtracts one from IYH
            // Stub
            logInstructionDetails(instructionDetails: "DEC IYH", opcode: [0xFD,0x25], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x26: // Undocumented - LD IYH,$n - FD 26 n - Loads $n into IYH
            // Stub
            logInstructionDetails(instructionDetails: "LD IYH,$n", opcode: [0xFD,0x26], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x29: // ADD IY,IY - FD 29 - The value of IY is added to IY
            logInstructionDetails(instructionDetails: "ADD IY,IY", opcode: [0xDD,0x29], programCounter: registers.PC)
            registers.WZ = registers.IY &+ 1
            let tempResult = registers.IY &+ registers.IY
            let halfCarry = ((registers.IY ^ registers.IY ^ tempResult) & 0x1000) != 0 ? z80Flags.HalfCarry.rawValue : 0
            let carrytempResult = UInt32(registers.IY) + UInt32(registers.IY)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.IY = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = (registers.F & ~z80Flags.HalfCarry.rawValue) | halfCarry
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.IYH & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.IYH & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.PC = registers.PC &+ 2
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x2A: // LD IY,($nn) - FD 2A n n - Loads the value pointed to by $nn into IY
            logInstructionDetails(instructionDetails: "LD IY,($nn)", opcode: [0xFD,0x2A], values: [opcode3,opcode4], programCounter: registers.PC)
            let tempResult = UInt16(opcode4) << 8 | UInt16(opcode3)
            registers.IYL = bus.readByte(address: tempResult)
            registers.IYH = bus.readByte(address: tempResult &+ 1)
            registers.WZ = tempResult &+ 1
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 20
            incrementR(opcodeCount:2)
        case 0x2B: // DEC IY - FD 2B - Subtracts one from IY
            logInstructionDetails(instructionDetails: "DEC IY", opcode: [0xFD,0x2B], programCounter: registers.PC)
            registers.IY = registers.IY &- 1
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:2)
        case 0x2C: // Undocumented - INC IYL - FD 2C - Adds one to IYL
            // Stub
            logInstructionDetails(instructionDetails: "INC IYL", opcode: [0xFD,0x2C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x2D: // Undocumented - DEC IYL - FD 2D - Subtracts one from IYL
            // Stub
            logInstructionDetails(instructionDetails: "DEC IYL", opcode: [0xFD,0x2D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x2E: // Undocumented - LD IYL,$n - FD 2E n - Loads n into IYL
            // Stub
            logInstructionDetails(instructionDetails: "LD IYL,$n", opcode: [0xFD,0x2E], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x34: // INC (IY+$d) - FD 34 d - Adds one to the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "INC (IY+$d)", opcode: [0xFD,0x34], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResult
            var previous = bus.readByte(address: tempResult)
            (previous,registers.F) = z80FastFlags.incHelper(operand: previous, currentFlags: registers.F)
            bus.writeByte(address: tempResult,value: previous)
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x35: // DEC (IY+$d) - FD 35 d - Subtracts one from the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "DEC (IY+$d)", opcode: [0xFD,0x35], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResult
            var previous = bus.readByte(address: tempResult)
            (previous,registers.F) = z80FastFlags.decHelper(operand: previous, currentFlags: registers.F)
            bus.writeByte(address: tempResult,value: previous)
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0x36: // LD (IY+$d),$n - FD 36 d n - Stores $n to the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "LD (IY+$d),$n", opcode: [0xFD,0x36], values: [opcode3,opcode4], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            bus.writeByte(address: tempResult, value: opcode4)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 4
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x39: // ADD IY,SP - FD 39 - The value of SP is added to IY
            logInstructionDetails(instructionDetails: "ADD IY,SP", opcode: [0xDD,0x39], programCounter: registers.PC)
            registers.WZ = registers.IY &+ 1
            let tempResult = registers.IY &+ registers.SP
            let halfCarry = ((registers.IY ^ registers.SP ^ tempResult) & 0x1000) != 0 ? z80Flags.HalfCarry.rawValue : 0
            let carrytempResult = UInt32(registers.IY) + UInt32(registers.SP)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.IY = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = (registers.F & ~z80Flags.HalfCarry.rawValue) | halfCarry
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.IYH & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.IYH & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.PC = registers.PC &+ 2
            registers.Q = registers.F
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0x3C: // Undocumented - INC A - FD 3C - Adds one to A
            // Stub
            logInstructionDetails(instructionDetails: "INC A", opcode: [0xFD,0x3C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x3D: // Undocumented - DEC A - FD 3D - Subtracts one from A
            // Stub
            logInstructionDetails(instructionDetails: "DEC A", opcode: [0xFD,0x3D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x3E: // Undocumented - LD A,$n - FD 3E n - Loads n into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,$n", opcode: [0xFD,0x3E], values: [opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:2)
        case 0x40: // Undocumented - LD B,B - FD 40 - The contents of B are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,B", opcode: [0xFD,0x40], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x41: // Undocumented - LD B,C - FD 41 - The contents of C are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,C", opcode: [0xFD,0x41], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x42: // Undocumented - LD B,D - FD 42 - The contents of D are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,D", opcode: [0xFD,0x42], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x43: // Undocumented - LD B,E - FD 43 - The contents of E are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,E", opcode: [0xFD,0x43], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x44: // Undocumented - LD B,IYH - FD 44 - The contents of IYH are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,IYH", opcode: [0xFD,0x44], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x45: // Undocumented - LD B,IYL - FD 45 - The contents of IYL are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,IYL", opcode: [0xFD,0x45], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x46: // LD B,(IY+$d) - FD 46 d - Loads the value pointed to by IY plus $d into B
            logInstructionDetails(instructionDetails: "LD B,(IY+$d)", opcode: [0xFD,0x46], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.B = bus.readByte(address: tempResult)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x47: // Undocumented - LD B,A - FD 47 - The contents of A are loaded into B
            // Stub
            logInstructionDetails(instructionDetails: "LD B,A", opcode: [0xFD,0x47], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x48: // Undocumented - LD C,B - FD 48 - The contents of B are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,B", opcode: [0xFD,0x48], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x49: // Undocumented - LD C,C - FD 49 - The contents of C are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,C", opcode: [0xFD,0x49], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4A: // Undocumented - LD C,D - FD 4A - The contents of D are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,D", opcode: [0xFD,0x4A], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4B: // Undocumented - LD C,E - FD 4B - The contents of E are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,E", opcode: [0xFD,0x4B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4C: // Undocumented - LD C,IYH - FD 4C - The contents of IYH are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,IYH", opcode: [0xFD,0x4C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4D: // Undocumented - LD C,IYL - FD 4D - The contents of IYL are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,IYL", opcode: [0xFD,0x4D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x4E: // LD C,(IY+$d) - FD 4E d - Loads the value pointed to by IY plus $d into C
            logInstructionDetails(instructionDetails: "LD C,(IY+$d)", opcode: [0xFD,0x4E], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.C = bus.readByte(address: tempResult)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x4F: // Undocumented - LD C,A - FD 4F - The contents of A are loaded into C
            // Stub
            logInstructionDetails(instructionDetails: "LD C,A", opcode: [0xFD,0x4F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x50: // Undocumented - LD D,B - FD 50 - The contents of B are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,B", opcode: [0xFD,0x50], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x51: // Undocumented - LD D,C - FD 51 - The contents of C are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,C", opcode: [0xFD,0x51], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x52: // Undocumented - LD D,D - FD 52 - The contents of D are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,D", opcode: [0xFD,0x52], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x53: // Undocumented - LD D,E - FD 53 - The contents of E are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,E", opcode: [0xFD,0x53], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x54: // Undocumented - LD D,IYH - FD 54 - The contents of IYH are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,IYH", opcode: [0xFD,0x54], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x55: // Undocumented - LD D,IYL - FD 55 - The contents of IYL are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,IYL", opcode: [0xFD,0x55], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x56: // LD D,(IY+$d) - FD 56 d - Loads the value pointed to by IY plus $d into D
            logInstructionDetails(instructionDetails: "LD D,(IY+$d)", opcode: [0xFD,0x46], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.D = bus.readByte(address: tempResult)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
            
        case 0x57: // Undocumented - LD D,A - FD 57 - The contents of A are loaded into D
            // Stub
            logInstructionDetails(instructionDetails: "LD D,A", opcode: [0xFD,0x57], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x58: // Undocumented - LD E,B - FD 58 - The contents of B are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,B", opcode: [0xFD,0x58], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x59: // Undocumented - LD E,C - FD 59 - The contents of C are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,C", opcode: [0xFD,0x59], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5A: // Undocumented - LD E,D - FD 5A - The contents of D are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,D", opcode: [0xFD,0x5A], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5B: // Undocumented - LD E,E - FD 5B - The contents of E are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,E", opcode: [0xFD,0x5B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5C: // Undocumented - LD E,IYH - FD 5C - The contents of IYH are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,IYH", opcode: [0xFD,0x5C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5D: // Undocumented - LD E,IYL - FD 5D - The contents of IYL are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,IYL", opcode: [0xFD,0x5D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x5E: // LD E,(IY+$d)- FD 5E d - Loads the value pointed to by IY plus $d into E
            logInstructionDetails(instructionDetails: "LD E,(IY+$d)", opcode: [0xFD,0x5E], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.E = bus.readByte(address: tempResult)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x5F: // Undocumented - LD E,A - FD 5F - The contents of A are loaded into E
            // Stub
            logInstructionDetails(instructionDetails: "LD E,A", opcode: [0xFD,0x5F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x60: // Undocumented - LD IYH,B - FD 60 - The contents of B are loaded into IYH
            // Stub
            logInstructionDetails(instructionDetails: "LD IYH,B", opcode: [0xFD,0x60], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x61: // Undocumented - LD IYH,C - FD 61 - The contents of C are loaded into IYH
            // Stub
            logInstructionDetails(instructionDetails: "LD IYH,C", opcode: [0xFD,0x61], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x62: // Undocumented - LD IYH,D - FD 62 - The contents of D are loaded into IYH
            // Stub
            logInstructionDetails(instructionDetails: "LD IYH,D", opcode: [0xFD,0x62], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x63: // Undocumented - LD IYH,E - FD 63 - The contents of E are loaded into IYH
            // Stub
            logInstructionDetails(instructionDetails: "LD IYH,E", opcode: [0xFD,0x63], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x64: // Undocumented - LD IYH,IYH - FD 64 - The contents of IYH are loaded into IYH
            // Stub
            logInstructionDetails(instructionDetails: "LD IYH,IYH", opcode: [0xFD,0x64], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x65: // Undocumented - LD IYH,IYL - FD 65 - The contents of IYL are loaded into IYH
            // Stub
            logInstructionDetails(instructionDetails: "LD IYH,IYL", opcode: [0xFD,0x65], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x66: // LD H,(IY+$d) - FD 66 d - Loads the value pointed to by IY plus $d into H
            logInstructionDetails(instructionDetails: "LD H,(IY+$d)", opcode: [0xFD,0x66], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.H = bus.readByte(address: tempResult)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x67: // Undocumented - LD IYH,A - FD 67 - The contents of A are loaded into IYH
            // Stub
            logInstructionDetails(instructionDetails: "LD IYH,A", opcode: [0xFD,0x67], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x68: // Undocumented - LD IYL,B - FD 68 - The contents of B are loaded into IYL
            // Stub
            logInstructionDetails(instructionDetails: "LD IYL,B", opcode: [0xFD,0x68], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x69: // Undocumented - LD IYL,C - FD 69 - The contents of C are loaded into IYL
            // Stub
            logInstructionDetails(instructionDetails: "LD IYL,C", opcode: [0xFD,0x69], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6A: // Undocumented - LD IYL,D - FD 6A - The contents of D are loaded into IYL
            // Stub
            logInstructionDetails(instructionDetails: "LD IYL,D", opcode: [0xFD,0x6A], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6B: // Undocumented - LD IYL,E - FD 6B - The contents of E are loaded into IYL
            // Stub
            logInstructionDetails(instructionDetails: "LD IYL,E", opcode: [0xFD,0x6B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6C: // Undocumented - LD IYL,IYH - FD 6C - The contents of IYH are loaded into IYL
            // Stub
            logInstructionDetails(instructionDetails: "LD IYL,IYH", opcode: [0xFD,0x6C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6D: // Undocumented - LD IYL,IYL - FD 6D - The contents of IYL are loaded into IYL
            // Stub
            logInstructionDetails(instructionDetails: "LD IYL,IYL", opcode: [0xFD,0x6D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x6E: // LD L,(IY+$d) - FD 6E d - Loads the value pointed to by IY plus $d into L
            logInstructionDetails(instructionDetails: "LD L,(IY+$d)", opcode: [0xFD,0x6E], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.L = bus.readByte(address: tempResult)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x6F: // Undocumented - LD IYL,A - FD 6F - The contents of A are loaded into IYL
            // Stub
            logInstructionDetails(instructionDetails: "LD IYL,A", opcode: [0xFD,0x6F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x70: // LD (IY+$d),B - FD 70 d - Stores B to the memory location pointed to by IY plus $
            logInstructionDetails(instructionDetails: "LD (IY+$d),B", opcode: [0xFD,0x70], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            bus.writeByte(address: tempResult, value: registers.B)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x71: // LD (IY+$d),C - FD 71 d - Stores C to the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "LD (IY+$d),C", opcode: [0xFD,0x71], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            bus.writeByte(address: tempResult, value: registers.C)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x72: // LD (IY+$d),D - FD 72 d - Stores D to the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "LD (IY+$d),D", opcode: [0xFD,0x72], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            bus.writeByte(address: tempResult, value: registers.D)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x73: // LD (IY+$d),E - FD 73 d - Stores E to the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "LD (IY+$d),E", opcode: [0xFD,0x73], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            bus.writeByte(address: tempResult, value: registers.E)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x74: // LD (IY+$d),H - FD 74 d - Stores H to the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "LD (IY+$d),H", opcode: [0xFD,0x74], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            bus.writeByte(address: tempResult, value: registers.H)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x75: // LD (IY+$d),L - FD 75 d - Stores L to the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "LD (IY+$d),L", opcode: [0xFD,0x36], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            bus.writeByte(address: tempResult, value: registers.L)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x77: // LD (IY+$d),A - FD 77 d - Stores A to the memory location pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "LD (IY+$d),A", opcode: [0xFD,0x77], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            bus.writeByte(address: tempResult, value: registers.A)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x78: // Undocumented - LD A,B - FD 78 - The contents of B are loaded into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,B", opcode: [0xFD,0x78], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x79: // Undocumented - LD A,C - FD 79 - The contents of C are loaded into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,C", opcode: [0xFD,0x79], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7A: // Undocumented - LD A,D - FD 7A - The contents of D are loaded into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,D", opcode: [0xFD,0x7A], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7B: // Undocumented - LD A,E - FD 7B - The contents of E are loaded into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,E", opcode: [0xFD,0x7B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7C: // Undocumented - LD A,IYH - FD 7C - The contents of IYH are loaded into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,IYH", opcode: [0xFD,0x7C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7D: // Undocumented - LD A,IYL - FD 7D - The contents of IYL are loaded into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,IYL", opcode: [0xFD,0x7D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x7E: // LD A,(IY+$d) - FD 7E d - Loads the value pointed to by IY plus $d into A
            logInstructionDetails(instructionDetails: "LD A,(IY+$d)", opcode: [0xFD,0x7E], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.A = bus.readByte(address: tempResult)
            registers.WZ = tempResult
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x7F: // Undocumented - LD A,A - FD 7F - The contents of A are loaded into A
            // Stub
            logInstructionDetails(instructionDetails: "LD A,A", opcode: [0xFD,0x7F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x80: // Undocumented - ADD A,B - FD 80 - Adds B to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,B", opcode: [0xFD,0x80], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x81: // Undocumented - ADD A,C - FD 81 - Adds C to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,C", opcode: [0xFD,0x81], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x82: // Undocumented - ADD A,D - FD 82 - Adds D to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,D", opcode: [0xFD,0x82], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x83: // Undocumented - ADD A,E - FD 83 - Adds E to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,E", opcode: [0xFD,0x83], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x84: // Undocumented - ADD A,IYH - FD 84 - Adds IYH to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,IYH", opcode: [0xFD,0x84], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x85: // Undocumented - ADD A,IYL - FD 85 - Adds IYL to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,IYL", opcode: [0xFD,0x85], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x86: // ADD A,(IY+$d) - FD 86 d - Adds the value pointed to by IY plus $d to A.
            logInstructionDetails(instructionDetails: "ADD A,(IY+$d)", opcode: [0xFD,0x86], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResult
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: bus.readByte(address: tempResult))
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x87: // Undocumented - ADD A,A - FD 87 - Adds A to A
            // Stub
            logInstructionDetails(instructionDetails: "ADD A,A", opcode: [0xFD,0x87], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x88: // Undocumented - ADC A,B - FD 88 - Adds B and the carry flag to A
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,B", opcode: [0xFD,0x88], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x89: // Undocumented - ADC A,C - FD 89 - Adds C and the carry flag to A
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,C", opcode: [0xFD,0x89], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x8A: // Undocumented - ADC A,D - FD 8A - Adds D and the carry flag to A
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,D", opcode: [0xFD,0x8A], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x8B: // Undocumented - ADC A,E - FD 8B - Adds E and the carry flag to A
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,E", opcode: [0xFD,0x8B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x8C: // Undocumented - ADC A,IYH - FD 8C - Adds IYH and the carry flag to A
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,IYH", opcode: [0xFD,0x8C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x8D: // Undocumented - ADC A,IYL - FD 8D - Adds IYL and the carry flag to A
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,IYL", opcode: [0xFD,0x8D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x8E: // ADC A,(IY+$d) - FD 8E d - Adds the value pointed to by IY plus $d and the carry flag to A
            logInstructionDetails(instructionDetails: "ADC A,(IY+$d)", opcode: [0xDD,0x8E], values: [opcode3], programCounter: registers.PC)
            let tempResult = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResult
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: bus.readByte(address: tempResult), addCarry: addCarry)
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x8F: // Undocumented - ADC A,A - FD 8F - Adds A and the carry flag to A
            // Stub
            logInstructionDetails(instructionDetails: "ADC A,A", opcode: [0xFD,0x8F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x90: // Undocumented - SUB B - FD 90 - Subtracts B from A
            // Stub
            logInstructionDetails(instructionDetails: "SUB B", opcode: [0xFD,0x90], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x91: // Undocumented - SUB C - FD 91 - Subtracts B from A
            // Stub
            logInstructionDetails(instructionDetails: "SUB C", opcode: [0xFD,0x91], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x92: // Undocumented - SUB D - FD 92 - Subtracts D from A
            // Stub
            logInstructionDetails(instructionDetails: "SUB D", opcode: [0xFD,0x92], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x93: // Undocumented - SUB E - FD 93 - Subtracts E from A
            // Stub
            logInstructionDetails(instructionDetails: "SUB E", opcode: [0xFD,0x93], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x94: // Undocumented - SUB IYH - FD 94 - Subtracts IYH from A
            // Stub
            logInstructionDetails(instructionDetails: "SUB IYH", opcode: [0xFD,0x94], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x95: // Undocumented - SUB IYL - FD 95 - SubtractsIYLfrom A
            // Stub
            logInstructionDetails(instructionDetails: "SUB IYL", opcode: [0xFD,0x95], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x96: // SUB (IY+$d) - FD 96 d - Subtracts the value pointed to by IY plus $d from A
            logInstructionDetails(instructionDetails: "SUB (IY+$d)", opcode: [0xFD,0x96], values: [opcode2], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: bus.readByte(address: tempResultAddress))
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x97: // Undocumented - SUB A - FD 97 - Subtracts A from A
            // Stub
            logInstructionDetails(instructionDetails: "SUB A", opcode: [0xFD,0x97], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0x98: // Undocumented - SBC A,B - FD 98 - Subtracts B and the carry flag from A
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,B", opcode: [0xFD,0x98], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x99: // Undocumented - SBC A,C - FD 99 - Subtracts C and the carry flag from A. - FD 99
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,C", opcode: [0xFD,0x0C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9A: // Undocumented - SBC A,D - FD 9A - Subtracts D and the carry flag from A
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,D", opcode: [0xFD,0x9A], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9B: // Undocumented - SBC A,E - FD 9B - Subtracts E and the carry flag from A
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,E", opcode: [0xFD,0x9B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9C: // Undocumented - SBC A,IYH - FD 9C - Subtracts IYH and the carry flag from A
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,IYH", opcode: [0xFD,0x9C], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9D: // Undocumented - SBC A,IYL - FD 9D - Subtracts IYL and the carry flag from A
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,IYL", opcode: [0xFD,0x9D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0x9E: // SBC A,(IY+$d)- FD 9E d - Subtracts the value pointed to by IY plus $d and the carry flag from A
            logInstructionDetails(instructionDetails: "SBC A,(IY+$d)", opcode: [0xFD,0x9E], values: [opcode3], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempResult = bus.readByte(address: tempResultAddress)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: tempResult, addCarry: addCarry)
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0x9F: // Undocumented - SBC A,A - FD 9F - Subtracts A and the carry flag from A
            // Stub
            logInstructionDetails(instructionDetails: "SBC A,A", opcode: [0xFD,0x9F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xA0: // Undocumented - AND B - FD A0 - Bitwise AND on A with B
            // Stub
            logInstructionDetails(instructionDetails: "AND B", opcode: [0xFD,0xA0], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA1: // Undocumented - AND C - FD A1 - Bitwise AND on A with C
            // Stub
            logInstructionDetails(instructionDetails: "AND C", opcode: [0xFD,0xA1], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA2: // Undocumented - AND D - FD A2 - Bitwise AND on A with D
            // Stub
            logInstructionDetails(instructionDetails: "AND D", opcode: [0xFD,0xA2], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA3: // Undocumented - AND E - FD A3 - Bitwise AND on A with E
            // Stub
            logInstructionDetails(instructionDetails: "AND E", opcode: [0xFD,0xA3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA4: // Undocumented - AND IYH - FD A4 - Bitwise AND on A with IYH
            // Stub
            logInstructionDetails(instructionDetails: "AND IYH", opcode: [0xFD,0xA4], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA5: // Undocumented - AND IYL - FD A5 - Bitwise AND on A with IYL
            // Stub
            logInstructionDetails(instructionDetails: "AND IYL", opcode: [0xFD,0xA5], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA6: // AND (IY+$d) - FD A6 d - Bitwise AND on A with the value pointed to by IY plus $d
            logInstructionDetails(instructionDetails: "AND (IY+$d)", opcode: [0xFD,0xA6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & bus.readByte(address: tempResultAddress), halfCarryMask: z80Flags.HalfCarry.rawValue)
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0xA7: // Undocumented - AND A - FD A7 - Bitwise AND on A with A
            // Stub
            logInstructionDetails(instructionDetails: "AND A", opcode: [0xFD,0xA7], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA8: // Undocumented - XOR B - FD A8 - Bitwise XOR on A with B
            // Stub
            logInstructionDetails(instructionDetails: "XOR B", opcode: [0xFD,0xA8], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xA9: // Undocumented - XOR C - FD A9 - Bitwise XOR on A with C
            // Stub
            logInstructionDetails(instructionDetails: "XOR C", opcode: [0xFD,0xA9], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xAA: // Undocumented - XOR D - FD AA - Bitwise XOR on A with D
            // Stub
            logInstructionDetails(instructionDetails: "XOR D", opcode: [0xFD,0xAA], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xAB: // Undocumented - XOR E - FD AB - Bitwise XOR on A with E
            // Stub
            logInstructionDetails(instructionDetails: "XOR E", opcode: [0xFD,0xAB], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xAC: // Undocumented - XOR IYH - FD AC - Bitwise XOR on A with IYH
            // Stub
            logInstructionDetails(instructionDetails: "XOR IYH", opcode: [0xFD,0xAC], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xAD: // Undocumented - XOR IYL - FD AD - Bitwise XOR on A with IYL
            // Stub
            logInstructionDetails(instructionDetails: "XOR IYL", opcode: [0xFD,0xAD], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xAE: // XOR (IY+$d) - FD AE d - Bitwise XOR on A with the value pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "XOR (IY+$d)", opcode: [0xFD,0xAE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ bus.readByte(address: tempResultAddress))
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0xAF: // Undocumented - XOR A - FD AF - Bitwise XOR on A with A
            // Stub
            logInstructionDetails(instructionDetails: "XOR A", opcode: [0xFD,0xAF], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xB0: // Undocumented - OR B - FD B0 - Bitwise OR on A with B
            // Stub
            logInstructionDetails(instructionDetails: "OR B", opcode: [0xFD,0xB0], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB1: // Undocumented - OR C - FD B1 - Bitwise OR on A with C
            // Stub
            logInstructionDetails(instructionDetails: "OR C", opcode: [0xFD,0xB1], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB2: // Undocumented - OR D - FD B2 - Bitwise OR on A with D
            // Stub
            logInstructionDetails(instructionDetails: "OR D", opcode: [0xFD,0xB2], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB3: // Undocumented - OR E - FD B3 - Bitwise OR on A with E
            // Stub
            logInstructionDetails(instructionDetails: "OR E", opcode: [0xFD,0xB3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB4: // Undocumented - OR IYH - FD B4 - Bitwise OR on A with IYH
            // Stub
            logInstructionDetails(instructionDetails: "OR IYH", opcode: [0xFD,0xB4], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB5: // Undocumented - OR IYL - FD B5 - Bitwise OR on A with IYL
            // Stub
            logInstructionDetails(instructionDetails: "OR IYL", opcode: [0xFD,0xB5], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB6: // OR (IY+$d) - FD B6 d - Bitwise OR on A with the value pointed to by IX plus $d
            logInstructionDetails(instructionDetails: "OR (IY+$d)", opcode: [0xDD,0xB6], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | bus.readByte(address: tempResultAddress))
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0xB7: // Undocumented - OR A - FD B7 - Bitwise OR on A with A
            // Stub
            logInstructionDetails(instructionDetails: "OR A", opcode: [0xFD,0xB7], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xB8: // Undocumented - CP B - FD B8 - Subtracts B from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP B", opcode: [0xFD,0xB8], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xB9: // Undocumented - CP C - FD B9 - Subtracts C from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP C", opcode: [0xFD,0xB9], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xBA: // Undocumented - CP D - FD BA - Subtracts D from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP D", opcode: [0xFD,0xBA], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xBB: // Undocumented - CP E - FD BB - Subtracts E from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP E", opcode: [0xFD,0xBB], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xBC: // Undocumented - CP IYH - FD BC - Subtracts IYH from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP IYH", opcode: [0xFD,0xBC], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xBD: // Undocumented - CP IYL - FD BD - Subtracts IYL from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP IYL", opcode: [0xFD,0xBD], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xBE: // CP (IY+$d) - FD BE d - Subtracts the value pointed to by IY plus $d from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP (IY+$d)", opcode: [0xFD,0xBE], values: [opcode3], programCounter: registers.PC)
            let tempResultAddress = registers.IY &+ UInt16(bitPattern: Int16(Int8(bitPattern: opcode3)))
            registers.WZ = tempResultAddress
            let tempResult = bus.readByte(address: tempResultAddress)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: tempResult)
            registers.F = tempFlags
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (tempResult & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from (IX+$d)
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (tempResult & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from (IX+$d)
            registers.PC = registers.PC &+ 3
            registers.Q = registers.F
            tStates = tStates + 19
            incrementR(opcodeCount:2)
        case 0xBF: // Undocumented - CP A - FD BF - Subtracts A from A and affects flags according to the result. A is not modified
            // Stub
            logInstructionDetails(instructionDetails: "CP A", opcode: [0xFD,0xBF], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0 //  change for flag opcodes
            tStates = tStates + 4
            incrementR(opcodeCount:2)
        case 0xCB: executeFDCBInstructions(opcode3: opcode3, opcode4: opcode4)
        case 0xE1: // POP IY - FD E1 - The memory location pointed to by SP is stored into IYL and SP is incremented. The memory location pointed to by SP is stored into IYH and SP is incremented again
            logInstructionDetails(instructionDetails: "POP IY", opcode: [0xFD,0xE1], programCounter: registers.PC)
            registers.IYL = bus.readByte(address: registers.SP)
            registers.IYH = bus.readByte(address: registers.SP &+ 1)
            registers.SP = registers.SP &+ 2
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 14
            incrementR(opcodeCount:2)
        case 0xE3: // EX (SP),IY - FD E3 - Exchanges (SP) with IYL, and (SP+1) with IYH
            logInstructionDetails(instructionDetails: "EX (SP),IY", opcode: [0xFD,0xE3], programCounter: registers.PC)
            let tempSPCL = bus.readByte(address: registers.SP)
            let tempSPCH = bus.readByte(address: registers.SP &+ 1)
            bus.writeByte(address: registers.SP, value: registers.IYL)
            bus.writeByte(address: registers.SP &+ 1, value: registers.IYH)
            registers.IY = UInt16(tempSPCH) << 8 | UInt16(tempSPCL)
            registers.WZ = registers.IY
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 23
            incrementR(opcodeCount:2)
        case 0xE5: // PUSH IY - FD E5 - SP is decremented and IYH is stored into the memory location pointed to by SP. SP is decremented again and IYL is stored into the memory location pointed to by SP
            logInstructionDetails(instructionDetails: "PUSH IY", opcode: [0xFD,0xE5], programCounter: registers.PC)
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.IYH)
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.IYL)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 15
            incrementR(opcodeCount:2)
        case 0xE9: // JP (IY) - FD E9 - Loads the value of IY into PC
            logInstructionDetails(instructionDetails: "JP (IY)", opcode: [0xFD,0xE9], programCounter: registers.PC)
            registers.PC = registers.IY
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:2)
        case 0xF9: // LD SP,IY - FD F9 - Loads the value of IY into SP
            logInstructionDetails(instructionDetails: "LD SP,IY", opcode: [0xFD,0xF9], programCounter: registers.PC)
            registers.SP = registers.IY
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:2)
        default:
            logInstructionDetails(opcode: [0xFD,opcode2], programCounter: registers.PC)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:2)
        }
    }

    private func executeInstructions()
    {
        let opcode1 = bus.readByte(address: registers.PC)
        let opcode2 = bus.readByte(address: registers.PC &+ 1)
        let opcode3 = bus.readByte(address: registers.PC &+ 2)
        let opcode4 = bus.readByte(address: registers.PC &+ 3)
        z80Queue[z80QueueHead] = registers.PC
        z80QueueFilled[z80QueueHead] = true
        z80QueueHead = (z80QueueHead + 1) % 16
        registers.P = 0 // default value for all instructions except LD A,I and LD A,R
        preserveEI = registers.EI
        registers.EI = 0 // default value for all instructions except LD A,I and LD A,R
        switch opcode1
        {
        case 0x00: // NOP - 00 - No operation is performed
            logInstructionDetails(instructionDetails: "NOP", opcode: [0x00], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x01: // LD BC,nn - 01 n n - Loads $nn into BC
            logInstructionDetails(instructionDetails: "LD BC,$nn", opcode: [0x01], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.BC = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0x02: // LD (BC),A - 02 - Stores A into the memory location pointed to by BC
            logInstructionDetails(instructionDetails: "LD (BC),A", opcode: [0x02], programCounter: registers.PC)
            bus.writeByte(address: registers.BC, value: registers.A)
            registers.WZ = (UInt16(registers.A) << 8) | (UInt16(registers.C &+ 1))
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x03: // INC BC - 03 - Adds one to BC
            logInstructionDetails(instructionDetails: "INC BE", opcode: [0x03], programCounter: registers.PC)
            registers.BC = registers.BC &+ 1
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x04: // INC B - 04 - Adds one to B
            logInstructionDetails(instructionDetails: "INC B", opcode: [0x04], programCounter: registers.PC)
            (registers.B,registers.F) = z80FastFlags.incHelper(operand: registers.B, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x05: // DEC B - 05 - Subtracts one from B
            logInstructionDetails(instructionDetails: "DEC B", opcode: [0x05], programCounter: registers.PC)
            (registers.B,registers.F) = z80FastFlags.decHelper(operand: registers.B, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x06: // LD B,$n - 06 n - Loads $n into B
            logInstructionDetails(instructionDetails: "LD B,$n", opcode: [0x06], values: [opcode2], programCounter: registers.PC)
            registers.B = opcode2
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x07: // RLCA - 07 - The contents of A are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0
            logInstructionDetails(instructionDetails: "RLCA", opcode: [0x07], programCounter: registers.PC)
            let previousA = registers.A
            registers.A = (previousA << 1) | (previousA >> 7)
            let carry = registers.A & 0x01
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.A & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.A & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & 0xFE) | carry
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x08: // EX AF,AF' - 08 - Adds one to Exchanges the 16-bit contents of AF and AF'
            logInstructionDetails(instructionDetails: "EX AF,AF'", opcode: [0x08], programCounter: registers.PC)
            let tempResult = registers.AF
            registers.AF = registers.altAF
            registers.altAF = tempResult
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x09: // ADD HL,BC - 09 - The value of BC is added to HL
            logInstructionDetails(instructionDetails: "ADD HL,BC", opcode: [0x09], programCounter: registers.PC)
            registers.WZ = registers.HL &+ 1
            let tempResult = registers.HL &+ registers.BC
            let halfCarry = ((registers.HL ^ registers.BC ^ tempResult) & 0x1000) != 0 ? z80Flags.HalfCarry.rawValue : 0
            let carrytempResult = UInt32(registers.HL) + UInt32(registers.BC)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.HL = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = (registers.F & ~z80Flags.HalfCarry.rawValue) | halfCarry
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.H & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.H & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0x0A: // LD A,(BC) - 0A - Loads the value pointed to by BC into A
            logInstructionDetails(instructionDetails: "LD A,(BC)", opcode: [0x0A], programCounter: registers.PC)
            registers.A = bus.readByte(address: registers.BC)
            registers.WZ = registers.BC &+ 1
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            registers.P = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x0B: // DEC BC - 0B - Subtracts one from BC
            logInstructionDetails(instructionDetails: "DEC BC", opcode: [0x0B], programCounter: registers.PC)
            registers.BC = registers.BC &- 1
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x0C: // INC C - 0C - Adds one to C
            logInstructionDetails(instructionDetails: "INC C", opcode: [0x0C], programCounter: registers.PC)
            (registers.C,registers.F) = z80FastFlags.incHelper(operand: registers.C, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x0D: // DEC C - 0D - Subtracts one from C
            logInstructionDetails(instructionDetails: "DEC C", opcode: [0x0D], programCounter: registers.PC)
            (registers.C,registers.F) = z80FastFlags.decHelper(operand: registers.C, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x0E: // LD C,$n - 0E n - Loads n into C
            logInstructionDetails(instructionDetails: "LD C,$n", opcode: [0x0E], values: [opcode2], programCounter: registers.PC)
            registers.C = opcode2
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x0F: // RRCA - 0F - The contents of A are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7
            logInstructionDetails(instructionDetails: "RRCA", opcode: [0x0F], programCounter: registers.PC)
            let previousA = registers.A
            registers.A = (previousA >> 1) | (previousA << 7)
            let carry = registers.A >> 7
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.A & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.A & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & 0xFE) | carry
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
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
                registers.WZ = registers.PC
                tStates = tStates + 13
            }
            else
            {
                registers.PC = registers.PC &+ 2
                tStates = tStates + 8
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0x11: // LD DE,$nn - 11 n n - Loads $nn into DE
            logInstructionDetails(instructionDetails: "LD DE,$nn", opcode: [0x11], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.DE = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0x12: // LD (DE),A - 12 - Stores A into the memory location pointed to by DE
            logInstructionDetails(instructionDetails: "LD (DE),A", opcode: [0x12], programCounter: registers.PC)
            bus.writeByte(address: registers.DE, value: registers.A)
            registers.PC = registers.PC &+ 1
            registers.WZ = (UInt16(registers.A) << 8) | (UInt16(registers.E) &+ 1)
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x13: // INC DE - 13 - Adds one to DE
            logInstructionDetails(instructionDetails: "INC DE", opcode: [0x13], programCounter: registers.PC)
            registers.DE = registers.DE &+ 1
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x14: // INC D - 14 - Adds one to D
            logInstructionDetails(instructionDetails: "INC D", opcode: [0x14], programCounter: registers.PC)
            (registers.D,registers.F) = z80FastFlags.incHelper(operand: registers.D, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x15: // DEC D - 15 - Subtracts one from D
            logInstructionDetails(instructionDetails: "DEC D", opcode: [0x15], programCounter: registers.PC)
            (registers.D,registers.F) = z80FastFlags.decHelper(operand: registers.D, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x16: // LD D,$n - 16 n - Loads $n into D
            logInstructionDetails(instructionDetails: "LD D,$n", opcode: [0x16], values: [opcode2], programCounter: registers.PC)
            registers.D = opcode2
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x17: // RLA - 17 - The contents of A are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0
            logInstructionDetails(instructionDetails: "RLA", opcode: [0x17], programCounter: registers.PC)
            let previousA = registers.A
            let oldCarry = registers.F & 0x01
            registers.A = (previousA << 1) | oldCarry
            let newCarry = (previousA >> 7) & 0x01
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.A & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.A & z80Flags.Y.rawValue)   // Preserve bit 5 (y) flags from result
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & 0xFE) | newCarry
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x18: // JR d - 18 d - The signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR $d", opcode: [0x18], values: [opcode2], programCounter: registers.PC)
            let signedOffset = Int8(bitPattern: opcode2)
            let displacement = Int16(signedOffset)
            registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
            registers.WZ = registers.PC
            registers.Q = 0
            tStates = tStates + 12
            incrementR(opcodeCount:1)
        case 0x19: // ADD HL,DE - 19 - The value of DE is added to HL
            logInstructionDetails(instructionDetails: "ADD HL,DE", opcode: [0x19], programCounter: registers.PC)
            registers.WZ = registers.HL &+ 1
            let tempResult = registers.HL &+ registers.DE
            let halfCarry = ((registers.HL ^ registers.DE ^ tempResult) & 0x1000) != 0 ? z80Flags.HalfCarry.rawValue : 0
            let carrytempResult = UInt32(registers.HL) + UInt32(registers.DE)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.HL = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = (registers.F & ~z80Flags.HalfCarry.rawValue) | halfCarry
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.H & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.H & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0x1A: // LD A,(DE) - 1A - Loads the value pointed to by DE into A
            logInstructionDetails(instructionDetails: "LD A,(DE)", opcode: [0x1A], programCounter: registers.PC)
            registers.A = bus.readByte(address: registers.DE)
            registers.PC = registers.PC &+ 1
            registers.WZ = registers.DE &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x1B: // DEC DE - 1B - Subtracts one from DE
            logInstructionDetails(instructionDetails: "DEC DE", opcode: [0x1B], programCounter: registers.PC)
            registers.DE = registers.DE &- 1
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x1C: // INC E - 14 - Adds one to E
            logInstructionDetails(instructionDetails: "INC E", opcode: [0x1C], programCounter: registers.PC)
            (registers.E,registers.F) = z80FastFlags.incHelper(operand: registers.E, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x1D: // DEC E - 1D - Subtracts one from E
            logInstructionDetails(instructionDetails: "DEC E", opcode: [0x1D], programCounter: registers.PC)
            (registers.E,registers.F) = z80FastFlags.decHelper(operand: registers.E, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x1E: // LD E,$n - 1E n - Loads $n into E
            logInstructionDetails(instructionDetails: "LD E,$n", opcode: [0x1E], values: [opcode2], programCounter: registers.PC)
            registers.E = opcode2
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x1F: // RRA - 1F - The contents of A are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7
            logInstructionDetails(instructionDetails: "RRA", opcode: [0x1F], programCounter: registers.PC)
            let previousA = registers.A
            let oldCarry = registers.F & 0x01
            registers.A = (previousA >> 1) | (oldCarry << 7)
            let newCarry = previousA  & 0x01
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.A & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.A & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = registers.F & ~z80Flags.HalfCarry.rawValue
            registers.F = (registers.F & 0xFE) | newCarry
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x20: // JR NZ,$d - 20 d - If the zero flag is unset, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR NZ,$d", opcode: [0x20], values: [opcode2], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
            {
                registers.PC = registers.PC &+ 2
                tStates = tStates + 7
            }
            else
            {
                let signedOffset = Int8(bitPattern: opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
                registers.WZ = registers.PC
                tStates = tStates + 12
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0x21: // LD HL,$nn - 21 n n - Loads $nn into HL
            logInstructionDetails(instructionDetails: "LD HL,$nn", opcode: [0x21], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.HL = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0x22: // LD ($nn),HL - 22 n n - Stores HL into the memory location pointed to by $nn.
            logInstructionDetails(instructionDetails: "LD ($nn),HL", opcode: [0x22], values: [opcode2,opcode3], programCounter: registers.PC)
            let tempResult = UInt16(opcode3) << 8 | UInt16(opcode2)
            bus.writeByte(address: tempResult, value: registers.L)
            bus.writeByte(address: tempResult &+ 1, value: registers.H)
            registers.PC = registers.PC &+ 3
            registers.WZ = tempResult + 1
            registers.Q = 0
            tStates = tStates + 16
            incrementR(opcodeCount:1)
        case 0x23: // INC HL - 23 - Adds one to HL
            logInstructionDetails(instructionDetails: "INC HL", opcode: [0x23], programCounter: registers.PC)
            registers.HL = registers.HL &+ 1
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x24: // INC H - 24 - Adds one to H
            logInstructionDetails(instructionDetails: "INC H", opcode: [0x24], programCounter: registers.PC)
            (registers.H,registers.F) = z80FastFlags.incHelper(operand: registers.H, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x25: // DEC H - 25 - Subtracts one from H
            logInstructionDetails(instructionDetails: "DEC H", opcode: [0x25], programCounter: registers.PC)
            (registers.H,registers.F) = z80FastFlags.decHelper(operand: registers.H, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x26: // LD H,$n - 26 n - Loads $n into H
            logInstructionDetails(instructionDetails: "LD H,$n", opcode: [0x26], values: [opcode2], programCounter: registers.PC)
            registers.H = opcode2
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x27: // DAA - 27 - Adjusts A for BCD addition and subtraction operations
            logInstructionDetails(instructionDetails: "DAA", opcode: [0x27], programCounter: registers.PC)
            let previousA = registers.A
            let tempCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            let tempHalfCarry = (registers.F & z80Flags.HalfCarry.rawValue) != 0
            let tempNegative = (registers.F & z80Flags.Negative.rawValue) != 0

            let daaIndex = (tempCarry ? 0x200 : 0) | (tempHalfCarry ? 0x100 : 0) | Int(previousA)
            let difference = z80FastFlags.daaHelper(tempResult: daaIndex)

            if tempNegative
            {
                registers.A = previousA &- difference
            }
            else
            {
                registers.A = previousA &+ difference
            }

            let newHalfCarry: UInt8 = ((previousA ^ registers.A ^ difference) & 0x10) != 0 ? z80Flags.HalfCarry.rawValue : 0
            let newCarry: UInt8 = ((difference & 0x60) != 0 || tempCarry) ? z80Flags.Carry.rawValue : 0
            let newNegative: UInt8 = tempNegative ? z80Flags.Negative.rawValue : 0
            let tempFlags = z80FastFlags.lookupSZP[Int(registers.A)]
            registers.F = tempFlags | newCarry | newHalfCarry | newNegative
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x28: // JR Z,$d - 28 d - If the zero flag is set, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR Z,$d", opcode: [0x28], values: [opcode2], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
            {
                let signedOffset = Int8(bitPattern: opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
                registers.WZ = registers.PC
                tStates = tStates + 12
            }
            else
            {
                registers.PC = registers.PC &+ 2
                tStates = tStates + 7
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0x29: // ADD HL,HL - 29 - The value of HL is added to HL
            logInstructionDetails(instructionDetails: "ADD HL,HL", opcode: [0x29], programCounter: registers.PC)
            registers.WZ = registers.HL &+ 1
            let tempResult = registers.HL &+ registers.HL
            let halfCarry = ((registers.HL ^ registers.HL ^ tempResult) & 0x1000) != 0 ? z80Flags.HalfCarry.rawValue : 0
            let carrytempResult = UInt32(registers.HL) + UInt32(registers.HL)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.HL = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = (registers.F & ~z80Flags.HalfCarry.rawValue) | halfCarry
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.H & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.H & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0x2A: // LD HL,($nn) - 2A n n - Loads the value pointed to by $nn into HL
            logInstructionDetails(instructionDetails: "LD HL,($nn)", opcode: [0x2A], values: [opcode2,opcode3], programCounter: registers.PC)
            let tempResult = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.L = bus.readByte(address: tempResult)
            registers.H = bus.readByte(address: tempResult &+ 1)
            registers.PC = registers.PC &+ 3
            registers.WZ = tempResult+1
            registers.Q = 0
            tStates = tStates + 16
            incrementR(opcodeCount:1)
        case 0x2B: // DEC HL - 2B - Subtracts one from HL
            logInstructionDetails(instructionDetails: "DEC HL", opcode: [0x2B], programCounter: registers.PC)
            registers.HL = registers.HL &- 1
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x2C: // INC L - 2C - Adds one to L
            logInstructionDetails(instructionDetails: "INC L", opcode: [0x2C], programCounter: registers.PC)
            (registers.L,registers.F) = z80FastFlags.incHelper(operand: registers.L, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x2D: // DEC L - 2D - Subtracts one from L
            logInstructionDetails(instructionDetails: "DEC L", opcode: [0x2D], programCounter: registers.PC)
            (registers.L,registers.F) = z80FastFlags.decHelper(operand: registers.L, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x2E: // LD L,$n - 2E n - Loads n into L
            logInstructionDetails(instructionDetails: "LD H,$n", opcode: [0x2E], values: [opcode2], programCounter: registers.PC)
            registers.L = opcode2
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x2F: // CPL - 2F - The contents of A are inverted (one's complement)
            logInstructionDetails(instructionDetails: "CPL", opcode: [0x2F], programCounter: registers.PC)
            registers.A = ~registers.A
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.A & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.A & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.F = registers.F | z80Flags.Negative.rawValue
            registers.F = registers.F | z80Flags.HalfCarry.rawValue
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x30: // JR NC,d - 30 $d - If the carry flag is unset, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR NC,$d", opcode: [0x30], values: [opcode2], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
            {
                registers.PC = registers.PC &+ 2
                tStates = tStates + 7
            }
            else
            {
                let signedOffset = Int8(bitPattern: opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
                registers.WZ = registers.PC
                tStates = tStates + 12
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0x31: // LD SP,$nn - 31 n n - Loads $nn into SP
            logInstructionDetails(instructionDetails: "LD SP,$nn", opcode: [0x31], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.SP = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.PC = registers.PC &+ 3
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0x32: // LD ($nn),A - 32 n n - Stores A into the memory location pointed to by $nn
            logInstructionDetails(instructionDetails: "LD ($nn),A", opcode: [0x32], values: [opcode2,opcode3], programCounter: registers.PC)
            let tempResult = UInt16(opcode3) << 8 | UInt16(opcode2)
            bus.writeByte(address: tempResult, value: registers.A)
            registers.PC = registers.PC &+ 3
            registers.WZ = (UInt16(registers.A) << 8) | (UInt16((tempResult + 1)) & 0xFF)
            registers.Q = 0
            tStates = tStates + 13
            incrementR(opcodeCount:1)
        case 0x33: // INC SP - 33 - Adds one to SP
            logInstructionDetails(instructionDetails: "INC SP", opcode: [0x33], programCounter: registers.PC)
            registers.SP = registers.SP &+ 1
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x34: // INC (HL) - 34 - Adds one to (HL)
            logInstructionDetails(instructionDetails: "INC (HL)", opcode: [0x34], programCounter: registers.PC)
            var previous = bus.readByte(address: registers.HL)
            (previous,registers.F) = z80FastFlags.incHelper(operand: previous, currentFlags: registers.F)
            bus.writeByte(address: registers.HL,value: previous)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0x35: // DEC (HL) - 35 - Subtracts one from (HL)
            logInstructionDetails(instructionDetails: "DEC (HL)", opcode: [0x35], programCounter: registers.PC)
            var previous = bus.readByte(address: registers.HL)
            (previous,registers.F) = z80FastFlags.decHelper(operand: previous, currentFlags: registers.F)
            bus.writeByte(address: registers.HL,value: previous)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0x36: // LD (HL),$n - 36 n - Loads $n into address at HL
            logInstructionDetails(instructionDetails: "LD (HL),$n", opcode: [0x36], values: [opcode2], programCounter: registers.PC)
            bus.writeByte(address: registers.HL, value: opcode2)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0x37: // SCF - 37 - Sets the carry flag
            logInstructionDetails(instructionDetails: "SCF", opcode: [0x37], programCounter: registers.PC)
            let tempSign = registers.F & z80Flags.Sign.rawValue
            let tempZero = registers.F & z80Flags.Zero.rawValue
            let tempParityOverflow = registers.F & z80Flags.ParityOverflow.rawValue
            let tempNegative : UInt8 = 0x00   // N = 0
            let tempHalfCarry : UInt8 = 0x00  // H = 0
            let tempCarry : UInt8 = 0x01     // C = 1
            let tempX = ((registers.Q ^ registers.F) | registers.A)  & z80Flags.X.rawValue
            let tempY = ((registers.Q ^ registers.F) | registers.A)  & z80Flags.Y.rawValue
            registers.F = tempSign | tempZero | tempY | tempHalfCarry
            registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x38: // JR C,d - 38 $d - If the carry flag is set, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode
            logInstructionDetails(instructionDetails: "JR C,$d", opcode: [0x38], values: [opcode2], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
            {
                let signedOffset = Int8(bitPattern: opcode2)
                let displacement = Int16(signedOffset)
                registers.PC = registers.PC &+ UInt16(bitPattern: displacement) &+ 2
                registers.WZ = registers.PC
                tStates = tStates + 12
            }
            else
            {
                registers.PC = registers.PC &+ 2
                tStates = tStates + 7
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0x39: // ADD HL,SP - 39 - The value of SP is added to HL
            logInstructionDetails(instructionDetails: "ADD HL,SP", opcode: [0x39], programCounter: registers.PC)
            registers.WZ = registers.HL &+ 1
            let tempResult = registers.HL &+ registers.SP
            let halfCarry = ((registers.HL ^ registers.SP ^ tempResult) & 0x1000) != 0 ? z80Flags.HalfCarry.rawValue : 0
            let carrytempResult = UInt32(registers.HL) + UInt32(registers.SP)
            let carry = UInt8((carrytempResult & 0x10000) >> 16)
            registers.HL = tempResult
            registers.F = registers.F & ~z80Flags.Negative.rawValue
            registers.F = (registers.F & ~z80Flags.Carry.rawValue) | carry
            registers.F = (registers.F & ~z80Flags.HalfCarry.rawValue) | halfCarry
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.H & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from result
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.H & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from result
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0x3A: // LD A,($nn) - 3A n n - Loads the value pointed to by $nn into A
            logInstructionDetails(instructionDetails: "LD A,($nn)", opcode: [0x3A], values: [opcode2,opcode3], programCounter: registers.PC)
            let tempResult = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.A = bus.readByte(address: tempResult)
            registers.PC = registers.PC &+ 3
            registers.WZ = tempResult &+ 1
            registers.Q = 0
            tStates = tStates + 13
            incrementR(opcodeCount:1)
        case 0x3B: // DEC SP - 3B - Subtracts one from SP
            logInstructionDetails(instructionDetails: "DEC SP", opcode: [0x3B], programCounter: registers.PC)
            registers.SP = registers.SP &- 1
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0x3C: // INC A - 3C - Adds one to A
            logInstructionDetails(instructionDetails: "INC A", opcode: [0x3C], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.incHelper(operand: registers.A, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x3D: // DEC A - 3D - Subtracts one from A
            logInstructionDetails(instructionDetails: "DEC A", opcode: [0x3D], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.decHelper(operand: registers.A, currentFlags: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x3E: // LD A,n - 3E - Loads n into A
            logInstructionDetails(instructionDetails: "LD A,$n", opcode: [0x3E], values: [opcode2], programCounter: registers.PC)
            registers.A = opcode2
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x3F: // CCF - 3F - Inverts the carry flag
                logInstructionDetails(instructionDetails: "CCF", opcode: [0x3F], programCounter: registers.PC)
                let tempSign = registers.F & z80Flags.Sign.rawValue
                let tempZero = registers.F & z80Flags.Zero.rawValue
                let tempParityOverflow = registers.F & z80Flags.ParityOverflow.rawValue
                let tempNegative : UInt8 = 0x00   // N = 0
                let tempHalfCarry = (registers.F & z80Flags.Carry.rawValue) << 4
                let tempCarry = (registers.F & z80Flags.Carry.rawValue) == 0 ? z80Flags.Carry.rawValue : 0
                let tempX = ((registers.Q ^ registers.F) | registers.A)  & z80Flags.X.rawValue
                let tempY = ((registers.Q ^ registers.F) | registers.A)  & z80Flags.Y.rawValue
                registers.F = tempSign | tempZero | tempY | tempHalfCarry
                registers.F = registers.F | tempX | tempParityOverflow | tempNegative | tempCarry
                registers.PC = registers.PC &+ 1
                registers.Q = registers.F
                tStates = tStates + 4
                incrementR(opcodeCount:1)
        case 0x40: // LD B,B - 40 - The contents of B are loaded into B
            logInstructionDetails(instructionDetails: "LD B,B", opcode: [0x40], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x41: // LD B,C - 41 - The contents of C are loaded into B
            logInstructionDetails(instructionDetails: "LD B,C", opcode: [0x41], programCounter: registers.PC)
            registers.B = registers.C
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x42: // LD B,D - 42 - The contents of D are loaded into B
            logInstructionDetails(instructionDetails: "LD B,D", opcode: [0x42], programCounter: registers.PC)
            registers.B = registers.D
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x43: // LD B,E - 43 - The contents of E are loaded into B
            logInstructionDetails(instructionDetails: "LD B,E", opcode: [0x43], programCounter: registers.PC)
            registers.B = registers.E
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x44: // LD B,H - 44 - The contents of H are loaded into B
            logInstructionDetails(instructionDetails: "LD B,H", opcode: [0x44], programCounter: registers.PC)
            registers.B = registers.H
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x45: // LD B,L - 45 - The contents of L are loaded into B
            logInstructionDetails(instructionDetails: "LD B,L", opcode: [0x45], programCounter: registers.PC)
            registers.B = registers.L
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x46: // LD B,(HL) - 46 - The contents of (HL) are loaded into B
            logInstructionDetails(instructionDetails: "LD B,(HL)", opcode: [0x46], programCounter: registers.PC)
            registers.B = bus.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x47: // LD B,A - 47 - The contents of A are loaded into B
            logInstructionDetails(instructionDetails: "LD B,A", opcode: [0x47], programCounter: registers.PC)
            registers.B = registers.A
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x48: // LD C,B - 48 - The contents of B are loaded into C
            logInstructionDetails(instructionDetails: "LD C,B", opcode: [0x48], programCounter: registers.PC)
            registers.C = registers.B
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x49: // LD C,C - 41 - The contents of C are loaded into C
            logInstructionDetails(instructionDetails: "LD C,C", opcode: [0x49], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x4A: // LD C,D - 4A - The contents of D are loaded into C
            logInstructionDetails(instructionDetails: "LD C,D", opcode: [0x4A], programCounter: registers.PC)
            registers.C = registers.D
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x4B: // LD C,E - 43 - The contents of E are loaded into C
            logInstructionDetails(instructionDetails: "LD C,E", opcode: [0x4B], programCounter: registers.PC)
            registers.C = registers.E
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x4C: // LD C,H - 44 - The contents of H are loaded into C
            logInstructionDetails(instructionDetails: "LD C,H", opcode: [0x4C], programCounter: registers.PC)
            registers.C = registers.H
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x4D: // LD C,L - 45 - The contents of L are loaded into C
            logInstructionDetails(instructionDetails: "LD C,L", opcode: [0x4D], programCounter: registers.PC)
            registers.C = registers.L
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x4E: // LD C,(HL) - 46 - The contents of (HL) are loaded into C
            logInstructionDetails(instructionDetails: "LD C,(HL)", opcode: [0x4E], programCounter: registers.PC)
            registers.C = bus.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x4F: // LD C,A - 47 - The contents of A are loaded into C
            logInstructionDetails(instructionDetails: "LD C,A", opcode: [0x4F], programCounter: registers.PC)
            registers.C = registers.A
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x50: // LD D,B - 40 - The contents of B are loaded into D
            logInstructionDetails(instructionDetails: "LD D,B", opcode: [0x50], programCounter: registers.PC)
            registers.D = registers.B
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x51: // LD D,C - 41 - The contents of C are loaded into D
            logInstructionDetails(instructionDetails: "LD D,C", opcode: [0x51], programCounter: registers.PC)
            registers.D = registers.C
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x52: // LD D,D - 42 - The contents of D are loaded into D
            logInstructionDetails(instructionDetails: "LD D,D", opcode: [0x52], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x53: // LD D,E - 43 - The contents of E are loaded into D
            logInstructionDetails(instructionDetails: "LD D,E", opcode: [0x53], programCounter: registers.PC)
            registers.D = registers.E
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x54: // LD D,H - 44 - The contents of H are loaded into D
            logInstructionDetails(instructionDetails: "LD D,H", opcode: [0x54], programCounter: registers.PC)
            registers.D = registers.H
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x55: // LD D,L - 45 - The contents of L are loaded into D
            logInstructionDetails(instructionDetails: "LD D,L", opcode: [0x55], programCounter: registers.PC)
            registers.D = registers.L
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x56: // LD D,(HL) - 46 - The contents of (HL) are loaded into D
            logInstructionDetails(instructionDetails: "LD D,(HL)", opcode: [0x56], programCounter: registers.PC)
            registers.D = bus.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x57: // LD D,A - 47 - The contents of A are loaded into D
            logInstructionDetails(instructionDetails: "LD D,A", opcode: [0x57], programCounter: registers.PC)
            registers.D = registers.A
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x58: // LD E,B - 40 - The contents of B are loaded into E
            logInstructionDetails(instructionDetails: "LD E,B", opcode: [0x58], programCounter: registers.PC)
            registers.E = registers.B
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x59: // LD E,C - 41 - The contents of C are loaded into E
            logInstructionDetails(instructionDetails: "LD E,C", opcode: [0x59], programCounter: registers.PC)
            registers.E = registers.C
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x5A: // LD E,D - 42 - The contents of D are loaded into E
            logInstructionDetails(instructionDetails: "LD E,D", opcode: [0x5A], programCounter: registers.PC)
            registers.E = registers.D
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x5B: // LD E,E - 43 - The contents of E are loaded into E
            logInstructionDetails(instructionDetails: "LD E,E", opcode: [0x5B], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x5C: // LD E,H - 44 - The contents of H are loaded into E
            logInstructionDetails(instructionDetails: "LD E,H", opcode: [0x5C], programCounter: registers.PC)
            registers.E = registers.H
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x5D: // LD E,L - 45 - The contents of L are loaded into E
            logInstructionDetails(instructionDetails: "LD E,L", opcode: [0x5D], programCounter: registers.PC)
            registers.E = registers.L
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x5E: // LD E,(HL) - 46 - The contents of (HL) are loaded into E
            logInstructionDetails(instructionDetails: "LD E,(HL)", opcode: [0x5E], programCounter: registers.PC)
            registers.E = bus.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x5F: // LD E,A - 47 - The contents of A are loaded into E
            logInstructionDetails(instructionDetails: "LD E,A", opcode: [0x5F], programCounter: registers.PC)
            registers.E = registers.A
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x60: // LD H,B - 40 - The contents of B are loaded into H
            logInstructionDetails(instructionDetails: "LD H,B", opcode: [0x60], programCounter: registers.PC)
            registers.H = registers.B
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x61: // LD H,C - 41 - The contents of C are loaded into H
            logInstructionDetails(instructionDetails: "LD H,C", opcode: [0x61], programCounter: registers.PC)
            registers.H = registers.C
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x62: // LD H,D - 42 - The contents of D are loaded into H
            logInstructionDetails(instructionDetails: "LD H,D", opcode: [0x62], programCounter: registers.PC)
            registers.H = registers.D
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x63: // LD H,E - 43 - The contents of E are loaded into H
            logInstructionDetails(instructionDetails: "LD H,E", opcode: [0x63], programCounter: registers.PC)
            registers.H = registers.E
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x64: // LD H,H - 44 - The contents of H are loaded into H
            logInstructionDetails(instructionDetails: "LD H,H", opcode: [0x64], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x65: // LD H,L - 45 - The contents of L are loaded into H
            logInstructionDetails(instructionDetails: "LD H,L", opcode: [0x65], programCounter: registers.PC)
            registers.H = registers.L
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x66: // LD H,(HL) - 46 - The contents of (HL) are loaded into H
            logInstructionDetails(instructionDetails: "LD H,(HL)", opcode: [0x66], programCounter: registers.PC)
            registers.H = bus.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x67: // LD H,A - 47 - The contents of A are loaded into H
            logInstructionDetails(instructionDetails: "LD H,A", opcode: [0x67], programCounter: registers.PC)
            registers.H = registers.A
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x68: // LD L,B - 40 - The contents of B are loaded into L
            logInstructionDetails(instructionDetails: "LD L,B", opcode: [0x68], programCounter: registers.PC)
            registers.L = registers.B
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x69: // LD L,C - 41 - The contents of C are loaded into L
            logInstructionDetails(instructionDetails: "LD L,C", opcode: [0x69], programCounter: registers.PC)
            registers.L = registers.C
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x6A: // LD L,D - 42 - The contents of D are loaded into L
            logInstructionDetails(instructionDetails: "LD L,D", opcode: [0x6A], programCounter: registers.PC)
            registers.L = registers.D
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x6B: // LD L,E - 43 - The contents of E are loaded into L
            logInstructionDetails(instructionDetails: "LD L,E", opcode: [0x6B], programCounter: registers.PC)
            registers.L = registers.E
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x6C: // LD L,H - 44 - The contents of H are loaded into L
            logInstructionDetails(instructionDetails: "LD L,H", opcode: [0x6C], programCounter: registers.PC)
            registers.L = registers.H
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x6D: // LD L,L - 45 - The contents of L are loaded into L
            logInstructionDetails(instructionDetails: "LD L,L", opcode: [0x6D], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x6E: // LD L,(HL) - 6E - The contents of (HL) are loaded into L
            logInstructionDetails(instructionDetails: "LD L,(HL)", opcode: [0x6E], programCounter: registers.PC)
            registers.L = bus.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x6F: // LD L,A - 6F - The contents of A are loaded into L
            logInstructionDetails(instructionDetails: "LD L,A", opcode: [0x6F], programCounter: registers.PC)
            registers.L = registers.A
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x70: // LD (HL),B - 70 - The contents of B are loaded into (HL)
            logInstructionDetails(instructionDetails: "LD (HL),B", opcode: [0x70], programCounter: registers.PC)
            bus.writeByte(address: registers.HL, value: registers.B)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x71: // LD (HL),C - 71 - The contents of C are loaded into (HL)
            logInstructionDetails(instructionDetails: "LD (HL),C", opcode: [0x71], programCounter: registers.PC)
            bus.writeByte(address: registers.HL, value: registers.C)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x72: // LD (HL),D - 72 - The contents of D are loaded into (HL)
            logInstructionDetails(instructionDetails: "LD (HL),D", opcode: [0x72], programCounter: registers.PC)
            bus.writeByte(address: registers.HL, value: registers.D)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x73: // LD (HL),E - 73 - The contents of B are loaded into (HL)
            tStates = tStates + 7
            logInstructionDetails(instructionDetails: "LD (HL),E", opcode: [0x73], programCounter: registers.PC)
            bus.writeByte(address: registers.HL, value: registers.E)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0x74: // LD (HL),H - 74 - The contents of H are loaded into (HL)
            logInstructionDetails(instructionDetails: "LD (HL),H", opcode: [0x74], programCounter: registers.PC)
            bus.writeByte(address: registers.HL, value: registers.H)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x75: // LD (HL),L - 75 - The contents of L are loaded into (HL)
            logInstructionDetails(instructionDetails: "LD (HL),L", opcode: [0x75], programCounter: registers.PC)
            bus.writeByte(address: registers.HL, value: registers.L)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x76: // HALT - 76 - Suspends CPU operation until an interrupt or reset occurs
            emulatorState = .halted
            logInstructionDetails(instructionDetails: "HALT", opcode: [0x76], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x77: // LD (HL),A - 77 - The contents of A are loaded into (HL)
            logInstructionDetails(instructionDetails: "LD (HL),A", opcode: [0x77], programCounter: registers.PC)
            bus.writeByte(address: registers.HL, value: registers.A)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x78: // LD A,B - 78 - The contents of B are loaded into A
            logInstructionDetails(instructionDetails: "LD A, B", opcode: [0x78], programCounter: registers.PC)
            registers.A = registers.B
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x79: // LD A,C - 79 - The contents of C are loaded into A
            logInstructionDetails(instructionDetails: "LD A,C", opcode: [0x79], programCounter: registers.PC)
            registers.A = registers.C
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7A: // LD A,D - 7A - The contents of D are loaded into A
            logInstructionDetails(instructionDetails: "LD A,D", opcode: [0x7A], programCounter: registers.PC)
            registers.A = registers.D
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7B: // LD A,E - 7B - The contents of E are loaded into A
            logInstructionDetails(instructionDetails: "LD A,E", opcode: [0x7B], programCounter: registers.PC)
            registers.A = registers.E
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7C: // LD A,H - 7C - The contents of H are loaded into A
            logInstructionDetails(instructionDetails: "LD A,H", opcode: [0x7C], programCounter: registers.PC)
            registers.A = registers.H
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7D: // LD A,L - 7D - The contents of L are loaded into A
            logInstructionDetails(instructionDetails: "LD A,L", opcode: [0x7D], programCounter: registers.PC)
            registers.A = registers.L
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x7E: // LD A,(HL) - 7E - The contents of (HL) are loaded into A
            logInstructionDetails(instructionDetails: "LD A,(HL)", opcode: [0x7E], programCounter: registers.PC)
            registers.A = bus.readByte(address: registers.HL)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x7F: // LD A,A - 7F - The contents of A are loaded into A
            logInstructionDetails(instructionDetails: "LD A,A", opcode: [0x7F], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x80: // ADD A,B - 80 - Adds B to A
            logInstructionDetails(instructionDetails: "ADD A,B", opcode: [0x80], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.B)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x81: // ADD A,C - 81 - Adds C to A
            logInstructionDetails(instructionDetails: "ADD A,C", opcode: [0x81], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.C)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x82: // ADD A,D - 82 - Adds D to A
            logInstructionDetails(instructionDetails: "ADD A,D", opcode: [0x82], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.D)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x83: // ADD A,E - 83 - Adds E to A
            logInstructionDetails(instructionDetails: "ADD A,E", opcode: [0x83], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.E)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x84: // ADD A,H - 84 - Adds H to A
            logInstructionDetails(instructionDetails: "ADD A,H", opcode: [0x84], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.H)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x85: // ADD A,L - 85 - Adds L to A
            logInstructionDetails(instructionDetails: "ADD A,L", opcode: [0x85], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.L)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x86: // ADD A,(HL) - 86 - Adds (HL)) to A
            logInstructionDetails(instructionDetails: "ADD A,(HL)", opcode: [0x86], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: bus.readByte(address: registers.HL))
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x87: // ADD A,A - 87 - Adds A to A
            logInstructionDetails(instructionDetails: "ADD A,A", opcode: [0x87], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.A)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x88: // ADC A,B - 88 - Adds B and the carry flag to A
            logInstructionDetails(instructionDetails: "ADC A,B", opcode: [0x88], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.B, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x89: // ADC A,C - 89 - Adds C and the carry flag to A
            logInstructionDetails(instructionDetails: "ADC A,C", opcode: [0x89], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.C, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x8A: // ADD A,D - 8A - Adds D and the carry flag to A
            logInstructionDetails(instructionDetails: "ADD A,D", opcode: [0x8A], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.D, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x8B: // ADC A,E - 8B - Adds E and the carry flag to A
            logInstructionDetails(instructionDetails: "ADC A,E", opcode: [0x8B], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.E, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x8C: // ADC A,H - 8C - Adds H and the carry flag to A
            logInstructionDetails(instructionDetails: "ADC A,H", opcode: [0x8C], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.H, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x8D: // ADC A,L - 8D - Adds L and the carry flag to A
            logInstructionDetails(instructionDetails: "ADC A,L", opcode: [0x8D], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.L, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x8E: // ADC A,(HL) - 8E - Adds (HL) and the carry flag to A
            logInstructionDetails(instructionDetails: "ADC A,(HL)", opcode: [0x8E], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: bus.readByte(address: registers.HL), addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x8F: // ADC A,A - 8F - Adds A and the carry flag to A
            logInstructionDetails(instructionDetails: "ADC A,A", opcode: [0x8F], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: registers.A, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x90: // SUB B - 90 - Subtracts B from A
            logInstructionDetails(instructionDetails: "SUB B", opcode: [0x90], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.B)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x91: // SUB C - 91 - Subtracts C from A
            logInstructionDetails(instructionDetails: "SUB C", opcode: [0x91], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.C)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x92: // SUB D - 92 - Subtracts D from A
            logInstructionDetails(instructionDetails: "SUB D", opcode: [0x92], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.D)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x93: // SUB E - 93 - Subtracts E from A
            logInstructionDetails(instructionDetails: "SUB E", opcode: [0x93], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.E)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x94: // SUB H - 94 - Subtracts H from A
            logInstructionDetails(instructionDetails: "SUB H", opcode: [0x94], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.H)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x95: // SUB L - 95 - Subtracts L from A
            logInstructionDetails(instructionDetails: "SUB L", opcode: [0x95], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.L)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x96: // SUB (HL) - 96 - Subtracts (HL) from A
            logInstructionDetails(instructionDetails: "SUB (HL)", opcode: [0x96], programCounter: registers.PC)
            let tempResult = bus.readByte(address: registers.HL)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: tempResult)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x97: // SUB A - 97 - Subtracts A from A
            logInstructionDetails(instructionDetails: "SUB A", opcode: [0x97], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.A)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x98: // SBC A,B - 98 - Subtracts B and the carry flag from A
            logInstructionDetails(instructionDetails: "SBC A,B", opcode: [0x98], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.B, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x99: // SBC A,C - 99 - Subtracts C and the carry flag from A
            logInstructionDetails(instructionDetails: "SBC A,C", opcode: [0x99], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.C, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x9A: // SBC A,D - 9A - Subtracts D and the carry flag from A
            logInstructionDetails(instructionDetails: "SBC A,D", opcode: [0x9A], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.D, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x9B: // SBC A,E - 9B - Subtracts E and the carry flag from A
            logInstructionDetails(instructionDetails: "SBC A,E", opcode: [0x9B], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.E, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x9C: // SBC A,H - 9C - Subtracts H and the carry flag from A
            logInstructionDetails(instructionDetails: "SBC A,H", opcode: [0x9C], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.H, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x9D: // SBC A,L - 9D - Subtracts L and the carry flag from A
            logInstructionDetails(instructionDetails: "SBC A,L", opcode: [0x9D], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.L, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0x9E: // SBC A,(HL) - 9E - Subtracts (HL) and the carry flag from A
            logInstructionDetails(instructionDetails: "SBC A,(HL)", opcode: [0x9E], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            let tempResult = bus.readByte(address: registers.HL)
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: tempResult, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0x9F: // SBC A,A - 9F - Subtracts A and the carry flag from A
            logInstructionDetails(instructionDetails: "SBC A,A", opcode: [0x9F], programCounter: registers.PC)
            let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
            (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.A, addCarry: addCarry)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA0: // AND B - A0 - Bitwise AND on A with B
            logInstructionDetails(instructionDetails: "AND B", opcode: [0xA0], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.B, halfCarryMask: z80Flags.HalfCarry.rawValue)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA1: // AND C - A1 - Bitwise AND on A with C
            logInstructionDetails(instructionDetails: "AND C", opcode: [0xA1], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.C, halfCarryMask: z80Flags.HalfCarry.rawValue)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA2: // AND D - A2 - Bitwise AND on A with D
            logInstructionDetails(instructionDetails: "AND D", opcode: [0xA2], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.D, halfCarryMask: z80Flags.HalfCarry.rawValue)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA3: // AND E - A3 - Bitwise AND on A with E
            logInstructionDetails(instructionDetails: "AND E", opcode: [0xA3], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.E, halfCarryMask: z80Flags.HalfCarry.rawValue)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA4: // AND H - A4 - Bitwise AND on A with H
            logInstructionDetails(instructionDetails: "AND H", opcode: [0xA4], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.H, halfCarryMask: z80Flags.HalfCarry.rawValue)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA5: // AND L - A5 - Bitwise AND on A with L
            logInstructionDetails(instructionDetails: "AND L", opcode: [0xA5], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.L, halfCarryMask: z80Flags.HalfCarry.rawValue)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA6: // AND (HL) - A6 - Bitwise AND on A with (HL)
            logInstructionDetails(instructionDetails: "AND (HL)", opcode: [0xA6], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & bus.readByte(address: registers.HL), halfCarryMask: z80Flags.HalfCarry.rawValue)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xA7: // AND A - A7 - Bitwise AND on A with A
            logInstructionDetails(instructionDetails: "AND A", opcode: [0xA7], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & registers.A, halfCarryMask: z80Flags.HalfCarry.rawValue)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA8: // XOR B - A8 - Bitwise XOR on A with B
            logInstructionDetails(instructionDetails: "XOR B", opcode: [0xA8], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.B)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xA9: // XOR C - A9 - Bitwise XOR on A with C
            logInstructionDetails(instructionDetails: "XOR C", opcode: [0xA9], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.C)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xAA: // XOR D - AA - Bitwise XOR on A with D
            logInstructionDetails(instructionDetails: "XOR D", opcode: [0xAA], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.D)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xAB: // XOR E - AB - Bitwise XOR on A with E
            logInstructionDetails(instructionDetails: "XOR E", opcode: [0xAB], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.E)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xAC: // XOR H - AC - Bitwise XOR on A with H
            logInstructionDetails(instructionDetails: "XOR H", opcode: [0xAC], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.H)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xAD: // XOR L - AD - Bitwise XOR on A with L
            logInstructionDetails(instructionDetails: "XOR L", opcode: [0xAD], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.L)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xAE: // XOR (HL) - AE - Bitwise XOR on A with (HL)
            logInstructionDetails(instructionDetails: "XOR (HL)", opcode: [0xAE], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ bus.readByte(address: registers.HL))
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xAF: // XOR A - AF - Bitwise XOR on A with A
            logInstructionDetails(instructionDetails: "XOR A", opcode: [0xAF], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ registers.A)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB0: // OR B - B0 - Bitwise OR on A with B
            logInstructionDetails(instructionDetails: "OR B", opcode: [0xB0], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.B)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB1: // OR C - B1 - Bitwise OR on A with C
            logInstructionDetails(instructionDetails: "OR C", opcode: [0xB1], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.C)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB2: // OR D - B2 - Bitwise OR on A with D
            logInstructionDetails(instructionDetails: "OR D", opcode: [0xB2], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.D)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB3: // OR E - B3 - Bitwise OR on A with E
            logInstructionDetails(instructionDetails: "OR E", opcode: [0xB3], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.E)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB4: // OR H - B4 - Bitwise OR on A with H
            logInstructionDetails(instructionDetails: "OR H", opcode: [0xB4], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.H)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB5: // OR L - B5 - Bitwise OR on A with L
            logInstructionDetails(instructionDetails: "OR L", opcode: [0xB5], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.L)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB6: // OR (HL) - B6 - Bitwise OR on A with (HL)
            logInstructionDetails(instructionDetails: "OR (HL)", opcode: [0xB6], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | bus.readByte(address: registers.HL))
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xB7: // OR A - B7 - Bitwise OR on A with A
            logInstructionDetails(instructionDetails: "OR A", opcode: [0xB7], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | registers.A)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB8: // CP B - B8 - Subtracts B from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP B", opcode: [0xB8], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.B)
            registers.F = tempFlags
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.B & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from B
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.B & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from B
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xB9: // CP C - B9 - Subtracts C from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP C", opcode: [0xB9], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.C)
            registers.F = tempFlags
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.C & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from C
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.C & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from C
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xBA: // CP D - BA - Subtracts D from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP D", opcode: [0xBA], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.D)
            registers.F = tempFlags
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.D & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from D
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.D & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from D
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xBB: // CP E - BB - Subtracts E from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP E", opcode: [0xBB], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.E)
            registers.F = tempFlags
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.E & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from E
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.E & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from E
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xBC: // CP H - BC - Subtracts H from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP H", opcode: [0xBC], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.H)
            registers.F = tempFlags
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.H & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from H
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.H & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from H
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xBD: // CP L - BD - Subtracts L from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP L", opcode: [0xBD], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.L)
            registers.F = tempFlags
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.L & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from L
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.L & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from L
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xBE: // CP (HL) - BE - Subtracts (HL) from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP (HL)", opcode: [0xBE], programCounter: registers.PC)
            let previous = bus.readByte(address: registers.HL)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: previous)
            registers.F = tempFlags
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (previous & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from (HL)
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (previous & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from (HL)
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xBF: // CP A - BF - Subtracts A from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP A", opcode: [0xBF], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: registers.A)
            registers.F = tempFlags
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (registers.A & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from A
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (registers.A & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from A
            registers.PC = registers.PC &+ 1
            registers.Q = registers.F
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
                registers.PCL = bus.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = bus.readByte(address: registers.SP)
                registers.WZ = registers.PC
                registers.SP = registers.SP &+ 1
                tStates = tStates + 11
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0xC1: // POP BC - C1 - The memory location pointed to by SP is stored into C and SP is incremented. The memory location pointed to by SP is stored into B and SP is incremented again
            logInstructionDetails(instructionDetails: "POP BC", opcode: [0xC1], programCounter: registers.PC)
            registers.C = bus.readByte(address: registers.SP)
            registers.B = bus.readByte(address: registers.SP &+ 1)
            registers.SP = registers.SP &+ 2
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xC2: // JP NZ,$nn - C2 n n - If the zero flag is unset, $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP NZ,$nn", opcode: [0xC2], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xC3: // JP $nn - C3 n n - $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP $nn", opcode: [0xC3], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            registers.WZ = registers.PC
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xC4: // CALL NZ,$nn - C4 n n - JIf the zero flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn
            logInstructionDetails(instructionDetails: "CALL NZ,$nn",opcode: [0xC4], values:[opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
            {
                tStates = tStates + 10
            }
            else
            {
                registers.SP = registers.SP &- 1
                bus.writeByte(address: registers.SP, value: registers.PCH)
                registers.SP = registers.SP &- 1
                bus.writeByte(address: registers.SP, value: registers.PCL)
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
                tStates = tStates + 17
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0xC5: // PUSH BC - C5 - SP is decremented and B is stored into the memory location pointed to by SP. SP is decremented again and C is stored into the memory location pointed to by SP
            logInstructionDetails(instructionDetails: "PUSH BC", opcode: [0xC5], programCounter: registers.PC)
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.B)
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.C)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xC6: // ADD A,$n - C6 n - Adds $n to A
            logInstructionDetails(instructionDetails: "ADD A,E", opcode: [0xC6], values: [opcode2], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: opcode2)
            registers.PC = registers.PC &+ 2
            registers.Q = registers.F
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xC7: // RST 0x00 - C7 - The current PC value plus one is pushed onto the stack, then is loaded with 0x00
            logInstructionDetails(instructionDetails: "RST 0x00", opcode: [0xC7], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0000
            registers.Q = 0
            registers.WZ = registers.PC
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xC8: // RETZ - C8 - If the zero flag is set, the top stack entry is popped into PC
            logInstructionDetails(instructionDetails: "RETZ", opcode: [0xC8], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
            {
                registers.PCL = bus.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = bus.readByte(address: registers.SP)
                registers.WZ = registers.PC
                registers.SP = registers.SP &+ 1
                tStates = tStates + 11
            }
            else
            {
                registers.PC = registers.PC &+ 1
                tStates = tStates + 5
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0xC9: // RET - C9 - The top stack entry is popped into PC
            logInstructionDetails(instructionDetails: "RET", opcode: [0xC9], programCounter: registers.PC)
            registers.PCL = bus.readByte(address: registers.SP)
            registers.SP = registers.SP &+ 1
            registers.PCH = bus.readByte(address: registers.SP)
            registers.WZ = registers.PC
            registers.SP = registers.SP &+ 1
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xCA: // JP Z,nn - CA n n - If the zero flag is set, $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP Z,$nn", opcode: [0xCA], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xCB : executeCBInstructions(opcode2: opcode2)
        case 0xCC: // CALL Z,$nn - CC n n - If the zero flag is set, the current PC value plus three is pushed onto the stack, then is loaded with $nn
           logInstructionDetails(instructionDetails: "CALL Z,$nn",opcode: [0xCC], values: [opcode2,opcode3], programCounter: registers.PC)
           registers.PC = registers.PC &+ 3
           registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
           if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Zero))
           {
               registers.SP = registers.SP &- 1
               bus.writeByte(address: registers.SP, value: registers.PCH)
               registers.SP = registers.SP &- 1
               bus.writeByte(address: registers.SP, value: registers.PCL)
               registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
               tStates = tStates + 17
           }
           else
           {
               tStates = tStates + 10
           }
           registers.Q = 0
           incrementR(opcodeCount:1)
        case 0xCD: // CALL $nn - CD n n - The current PC value plus three is pushed onto the stack, then is loaded with $nn
           logInstructionDetails(instructionDetails: "CALL $nn",opcode: [0xCD], values: [opcode2,opcode3], programCounter: registers.PC)
           registers.PC = registers.PC &+ 3
           registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.PCH)
           registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.PCL)
           registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
           registers.WZ = registers.PC
            registers.Q = 0
           tStates = tStates + 17
           incrementR(opcodeCount:1)
        case 0xCE: // ADC A,$n - C3 n - Adds $n and the carry flag to A
           logInstructionDetails(instructionDetails: "ADC A,$n", opcode: [0xCE], values: [opcode2], programCounter: registers.PC)
           let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
           (registers.A,registers.F) = z80FastFlags.addHelper(operand1: registers.A, operand2: opcode2, addCarry: addCarry)
           registers.PC = registers.PC &+ 2
            registers.Q = registers.F
           tStates = tStates + 7
           incrementR(opcodeCount:1)
        case 0xCF: // RST 0x08 - The current PC value plus one is pushed onto the stack, then is loaded with 0x08
           logInstructionDetails(instructionDetails: "RST 0x08", opcode: [0xCF], programCounter: registers.PC)
           registers.PC = registers.PC &+ 1
           registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
           registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
           registers.PC = 0x0008
           registers.WZ = registers.PC
           registers.Q = 0
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
               registers.PCL = bus.readByte(address: registers.SP)
               registers.SP = registers.SP &+ 1
               registers.PCH = bus.readByte(address: registers.SP)
               registers.SP = registers.SP &+ 1
               registers.WZ = registers.PC
               tStates = tStates + 11
           }
           registers.Q = 0
           incrementR(opcodeCount:1)
       case 0xD1: // POP DE - D1 - The memory location pointed to by SP is stored into E and SP is incremented. The memory location pointed to by SP is stored into D and SP is incremented again.
            logInstructionDetails(instructionDetails: "POP DE", opcode: [0xD1], programCounter: registers.PC)
            registers.E = bus.readByte(address: registers.SP)
            registers.D = bus.readByte(address: registers.SP &+ 1)
            registers.SP = registers.SP &+ 2
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
       case 0xD2: // JP NC,$nn - D2 n n - If the carry flag is unset, $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP NC,$nn", opcode: [0xD2], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
            {
               registers.PC = registers.PC &+ 3
            }
            else
            {
               registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
       case 0xD3: // OUT ($n),A - D3 n - The value of A is written to port $n
            logInstructionDetails(instructionDetails: "OUT ($n),A", opcode: [0xD3], values: [opcode2], programCounter: registers.PC)
            let tempResult = UInt16(registers.A) << 8 | UInt16(opcode2)
            bus.writePort(portNum: tempResult, portValue: registers.A)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            registers.WZ = UInt16(registers.A) << 8 | (UInt16(opcode2) &+ 1) & 0xFF
            tStates = tStates + 11
            incrementR(opcodeCount:1)
       case 0xD4: // CALL NC,$nn - D4 n n - If the carry flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn
           logInstructionDetails(instructionDetails: "CALL NC,$nn",opcode: [0xD4], values: [opcode2,opcode3], programCounter: registers.PC)
           registers.PC = registers.PC &+ 3
           registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
           if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
           {
               tStates = tStates + 10
           }
           else
           {
               registers.SP = registers.SP &- 1
               bus.writeByte(address: registers.SP, value: registers.PCH)
               registers.SP = registers.SP &- 1
               bus.writeByte(address: registers.SP, value: registers.PCL)
               registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
               tStates = tStates + 17
           }
           registers.Q = 0
           incrementR(opcodeCount:1)
       case 0xD5: // PUSH DE - D5 - SP is decremented and D is stored into the memory location pointed to by SP. SP is decremented again and E is stored into the memory location pointed to by SP
           logInstructionDetails(instructionDetails: "PUSH DE", opcode: [0xD5], programCounter: registers.PC)
           registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.D)
           registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.E)
           registers.PC = registers.PC &+ 1
           registers.Q = 0
           tStates = tStates + 11
           incrementR(opcodeCount:1)
       case 0xD6: // SUB $n - D6 n - Subtracts $n from A
           logInstructionDetails(instructionDetails: "SUB $n", opcode: [0xD6], values: [opcode2], programCounter: registers.PC)
           (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: opcode2)
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 7
           incrementR(opcodeCount:1)
       case 0xD7: // RST 0x10 - The current PC value plus one is pushed onto the stack, then is loaded with 0x10
           logInstructionDetails(instructionDetails: "RST 0x10", opcode: [0xD7], programCounter: registers.PC)
           registers.PC = registers.PC &+ 1
           registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
           registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
           registers.PC = 0x0010
           registers.WZ = registers.PC
           registers.Q = 0
           tStates = tStates + 11
           incrementR(opcodeCount:1)
       case 0xD8: // RET C - D8 - If the carry flag is set, the top stack entry is popped into PC
           logInstructionDetails(instructionDetails: "RET NC", opcode: [0xD0], programCounter: registers.PC)
           if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
           {
               registers.PCL = bus.readByte(address: registers.SP)
               registers.SP = registers.SP &+ 1
               registers.PCH = bus.readByte(address: registers.SP)
               registers.WZ = registers.PC
               registers.SP = registers.SP &+ 1
               tStates = tStates + 11
           }
           else
           {
               registers.PC = registers.PC &+ 1
               tStates = tStates + 5
           }
           registers.Q = 0
           incrementR(opcodeCount:1)
       case 0xD9: // EXX - D9 - Exchanges the 16-bit contents of BC, DE, and HL with BC', DE', and HL'
           logInstructionDetails(instructionDetails: "EXX", opcode: [0xD9], programCounter: registers.PC)
           (registers.BC,registers.altBC) = (registers.altBC,registers.BC)
           (registers.DE,registers.altDE) = (registers.altDE,registers.DE)
           (registers.HL,registers.altHL) = (registers.altHL,registers.HL)
           registers.PC = registers.PC &+ 1
           registers.Q = 0
           tStates = tStates + 4
           incrementR(opcodeCount:1)
       case 0xDA: // JP C,$nn - DA n n - If the carry flag is set, $nn is copied to PC
           logInstructionDetails(instructionDetails: "JP C,$nn", opcode: [0xDA], values: [opcode2,opcode3], programCounter: registers.PC)
           registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
           if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
           {
               registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
           }
           else
           {
               registers.PC = registers.PC &+ 3
           }
           registers.Q = 0
           tStates = tStates + 10
           incrementR(opcodeCount:1)
       case 0xDB: // IN A,($n) - DB n - A byte from port $n is written to A
            logInstructionDetails(instructionDetails: "IN A,($n)", opcode: [0xDB], values: [opcode2], programCounter: registers.PC)
            registers.WZ = UInt16(registers.A) << 8 | UInt16(opcode2) &+ 1
            let tempResult = UInt16(registers.A) << 8 | UInt16(opcode2)
            registers.A = bus.readPort(portNum: tempResult)
            registers.PC = registers.PC &+ 2
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:1)
       case 0xDC: // CALL C,$nn - DC n n - If the carry flag is set, the current PC value plus three is pushed onto the stack, then is loaded with $nn.
           logInstructionDetails(instructionDetails: "CALL C,$nn",opcode: [0xDC], values: [opcode2,opcode3], programCounter: registers.PC)
           registers.PC = registers.PC &+ 3
           registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
           if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Carry))
           {
               registers.SP = registers.SP &- 1
               bus.writeByte(address: registers.SP, value: registers.PCH)
               registers.SP = registers.SP &- 1
               bus.writeByte(address: registers.SP, value: registers.PCL)
               registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
               tStates = tStates + 17
           }
           else
           {
               tStates = tStates + 10
           }
           registers.Q = 0
           incrementR(opcodeCount:1)
        case 0xDD : executeDDInstructions(opcode2: opcode2, opcode3: opcode3, opcode4: opcode4)
        case 0xDE: // SBC A,$n - DE n - Subtracts $n and the carry flag from A
           logInstructionDetails(instructionDetails: "SBC A,$n", opcode: [0xDE], values: [opcode2], programCounter: registers.PC)
           let addCarry = (registers.F & z80Flags.Carry.rawValue) != 0
           (registers.A,registers.F) = z80FastFlags.subHelper(operand1: registers.A, operand2: opcode2, addCarry: addCarry)
           registers.PC = registers.PC &+ 2
           registers.Q = registers.F
           tStates = tStates + 7
           incrementR(opcodeCount:1)
        case 0xDF: // RST 0x18 - DF - The current PC value plus one is pushed onto the stack, then is loaded with 0x18
            logInstructionDetails(instructionDetails: "RST 0x18", opcode: [0xC7], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0018
            registers.Q = 0
            registers.WZ = registers.PC
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
                registers.PCL = bus.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = bus.readByte(address: registers.SP)
                registers.WZ = registers.PC
                registers.SP = registers.SP &+ 1
                tStates = tStates + 11
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0xE1: // POP HL - E1 - The memory location pointed to by SP is stored into L and SP is incremented. The memory location pointed to by SP is stored into H and SP is incremented again
            logInstructionDetails(instructionDetails: "POP HL", opcode: [0xE1], programCounter: registers.PC)
            registers.L = bus.readByte(address: registers.SP)
            registers.H = bus.readByte(address: registers.SP &+ 1)
            registers.SP = registers.SP &+ 2
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xE2: // JP PO,nn - E1 n n - If the parity/overflow flag is unset, $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP PO,$nn", opcode: [0xE2], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.ParityOverflow))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xE3: // EX (SP),HL - E3 - Exchanges (SP) with L, and (SP+1) with H
            logInstructionDetails(instructionDetails: "EX (SP),HL", opcode: [0xE3], programCounter: registers.PC)
            let tempResultH = registers.H
            let tempResultL = registers.L
            registers.L = bus.readByte(address: registers.SP)
            registers.H = bus.readByte(address: registers.SP &+ 1)
            registers.WZ = UInt16(registers.H) << 8 | UInt16(registers.L)
            bus.writeByte(address: registers.SP, value: tempResultL)
            bus.writeByte(address: registers.SP &+ 1, value: tempResultH)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 19
            incrementR(opcodeCount:1)
        case 0xE4: // CALL PO,$nn - D4 n n - If the parity/overflow flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn
            logInstructionDetails(instructionDetails: "CALL PO,$nn",opcode: [0xE4], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.ParityOverflow))
            {
                tStates = tStates + 10
            }
            else
            {
                registers.SP = registers.SP &- 1
                bus.writeByte(address: registers.SP, value: registers.PCH)
                registers.SP = registers.SP &- 1
                bus.writeByte(address: registers.SP, value: registers.PCL)
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
                tStates = tStates + 17
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0xE5: // PUSH HL - D5 - SP is decremented and H is stored into the memory location pointed to by SP. SP is decremented again and L is stored into the memory location pointed to by SP
            logInstructionDetails(instructionDetails: "PUSH HL", opcode: [0xE5], programCounter: registers.PC)
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.H)
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.L)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xE6: // AND n - E6 n - Bitwise AND on A with $n
            logInstructionDetails(instructionDetails: "AND $n", opcode: [0xE6], values: [opcode2], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A & opcode2, halfCarryMask: z80Flags.HalfCarry.rawValue)
            registers.PC = registers.PC &+ 2
            registers.Q = registers.F
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xE7: // RST 0x20 - E7 - The current PC value plus one is pushed onto the stack, then is loaded with 0x20
            logInstructionDetails(instructionDetails: "RST 0x20", opcode: [0xE7], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0020
            registers.Q = 0
            registers.WZ = registers.PC
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xE8: // RET PO - E8 - If the parity/overflow flag is unset, the top stack entry is popped into PC
            logInstructionDetails(instructionDetails: "RET PE", opcode: [0xE8], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.ParityOverflow))
            {
                registers.PCL = bus.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = bus.readByte(address: registers.SP)
                registers.WZ = registers.PC
                registers.SP = registers.SP &+ 1
                tStates = tStates + 11
            }
            else
            {
                registers.PC = registers.PC &+ 1
                tStates = tStates + 5
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0xE9: // JP (HL) - E9 - Loads the value of HL into PC
            logInstructionDetails(instructionDetails: "JP (HL)", opcode: [0xE9], programCounter: registers.PC)
            registers.PC = registers.HL
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xEA: // JP PE,nn - EA n n - If the parity/overflow flag is set, $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP PE,$nn", opcode: [0xEA], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.ParityOverflow))
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xEB: // EX DE,HL - EB - Exchanges the 16-bit contents of DE and HL
            logInstructionDetails(instructionDetails: "EX DE,HL", opcode: [0xEB], programCounter: registers.PC)
            (registers.DE,registers.HL) = (registers.HL,registers.DE)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xEC: // CALL PE,$nn - EC n n - If the parity/overflow flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn
            logInstructionDetails(instructionDetails: "CALL PE,$nn",opcode: [0xEC], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.ParityOverflow))
            {
                registers.SP = registers.SP &- 1
                bus.writeByte(address: registers.SP, value: registers.PCH)
                registers.SP = registers.SP &- 1
                bus.writeByte(address: registers.SP, value: registers.PCL)
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
                tStates = tStates + 17
            }
            else
            {
                tStates = tStates + 10
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0xED : executeEDInstructions(opcode2: opcode2, opcode3: opcode3, opcode4: opcode4)
        case 0xEE: // XOR n - EE n - Bitwise XOR on A with $n
            logInstructionDetails(instructionDetails: "XOR $n", opcode: [0xEE], values: [opcode2], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A ^ opcode2)
            registers.PC = registers.PC &+ 2
            registers.Q = registers.F
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xEF: // RST 0x28 - EF - The current PC value plus one is pushed onto the stack, then is loaded with 0x28
            logInstructionDetails(instructionDetails: "RST 0x28", opcode: [0xEF], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0028
            registers.Q = 0
            registers.WZ = registers.PC
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
                registers.PCL = bus.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = bus.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.WZ = registers.PC
                tStates = tStates + 11
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0xF1: // POP AF - F1 - The memory location pointed to by SP is stored into F and SP is incremented. The memory location pointed to by SP is stored into A and SP is incremented again
            logInstructionDetails(instructionDetails: "POP AF", opcode: [0xF1], programCounter: registers.PC)
            registers.F = bus.readByte(address: registers.SP)
            registers.A = bus.readByte(address: registers.SP &+ 1)
            registers.SP = registers.SP &+ 2
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xF2: // JP P,nn - F2 n n - If the sign flag is unset, $nn is copied to PC
            logInstructionDetails(instructionDetails: "JP P,$nn", opcode: [0xF2], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Sign))
            {
                registers.PC = registers.PC &+ 3
            }
            else
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xF3: // DI - F3 - Resets both interrupt flip-flops, thus preventing maskable interrupts from triggering
            logInstructionDetails(instructionDetails: "DI", opcode: [0xF3], programCounter: registers.PC)
            registers.IFF1 = false
            registers.IFF2 = false
            registers.EI = 0
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xF4: // CALL P,$nn - F4 n n - If the sign flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn.
            logInstructionDetails(instructionDetails: "CALL P,$nn",opcode: [0xF4], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Sign))
            {
                tStates = tStates + 10
            }
            else
            {
                registers.SP = registers.SP &- 1
                bus.writeByte(address: registers.SP, value: registers.PCH)
                registers.SP = registers.SP &- 1
                bus.writeByte(address: registers.SP, value: registers.PCL)
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
                tStates = tStates + 17
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0xF5: // PUSH AF - F5 - SP is decremented and A is stored into the memory location pointed to by SP. SP is decremented again and F is stored into the memory location pointed to by SP
            logInstructionDetails(instructionDetails: "PUSH AF", opcode: [0xF5], programCounter: registers.PC)
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.A)
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: registers.F)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xF6: // OR n - F6 n - Bitwise OR on A with $n
            logInstructionDetails(instructionDetails: "OR $n", opcode: [0xF6], values: [opcode2], programCounter: registers.PC)
            (registers.A,registers.F) = z80FastFlags.logicHelper(tempResult: registers.A | opcode2)
            registers.PC = registers.PC &+ 2
            registers.Q = registers.F
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xF7: // RST 0x30 - F7 - The current PC value plus one is pushed onto the stack, then is loaded with 0x30
            logInstructionDetails(instructionDetails: "RST 0x30", opcode: [0xF7], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0030
            registers.Q = 0
            registers.WZ = registers.PC
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        case 0xF8: // RET M - F0 - If the sign flag is set, the top stack entry is popped into PC
            logInstructionDetails(instructionDetails: "RET M", opcode: [0xF8], programCounter: registers.PC)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Sign))
            {
                registers.PCL = bus.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.PCH = bus.readByte(address: registers.SP)
                registers.SP = registers.SP &+ 1
                registers.WZ = registers.PC
                tStates = tStates + 11
            }
            else
            {
                registers.PC = registers.PC &+ 1
                tStates = tStates + 5
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0xF9: // LD SP,HL - F9 - Loads the value of HL into SP
            logInstructionDetails(instructionDetails: "LD SP,HL", opcode: [0xF9], programCounter: registers.PC)
            registers.SP = registers.HL
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 6
            incrementR(opcodeCount:1)
        case 0xFA: // JP M,nn
            logInstructionDetails(instructionDetails: "JP M,$nn", opcode: [0xFA], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Sign))
            {
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
            }
            else
            {
                registers.PC = registers.PC &+ 3
            }
            registers.Q = 0
            tStates = tStates + 10
            incrementR(opcodeCount:1)
        case 0xFB: // EI - FB - Sets both interrupt flip-flops, thus allowing maskable interrupts to occur. An interrupt will not occur until after the immediately following instruction
            logInstructionDetails(instructionDetails: "EI", opcode: [0xFB], programCounter: registers.PC)
            registers.IFF1 = true
            registers.IFF2 = true
            registers.EI = 1
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 4
            incrementR(opcodeCount:1)
        case 0xFC: // CALL M,$nn - FC n n - If the sign flag is set, the current PC value plus three is pushed onto the stack, then is loaded with $nn
            logInstructionDetails(instructionDetails: "CALL M,$nn",opcode: [0xFC], values: [opcode2,opcode3], programCounter: registers.PC)
            registers.PC = registers.PC &+ 3
            registers.WZ = UInt16(opcode3) << 8 | UInt16(opcode2)
            if (TestFlags(FlagRegister:registers.F,Flag:z80Flags.Sign))
            {
                registers.SP = registers.SP &- 1
                bus.writeByte(address: registers.SP, value: registers.PCH)
                registers.SP = registers.SP &- 1
                bus.writeByte(address: registers.SP, value: registers.PCL)
                registers.PC = UInt16(opcode3) << 8 | UInt16(opcode2)
                tStates = tStates + 17
            }
            else
            {
                tStates = tStates + 10
            }
            registers.Q = 0
            incrementR(opcodeCount:1)
        case 0xFD: executeFDInstructions(opcode2: opcode2, opcode3: opcode3, opcode4: opcode4)
        case 0xFE: // CP n - FE n - Subtracts $n from A and affects flags according to the result. A is not modified
            logInstructionDetails(instructionDetails: "CP $n", opcode: [0xFE], values: [opcode2], programCounter: registers.PC)
            let (_,tempFlags) = z80FastFlags.subHelper(operand1: registers.A, operand2: opcode2)
            registers.F = tempFlags
            registers.F = (registers.F & ~z80Flags.X.rawValue) | (opcode2 & z80Flags.X.rawValue)   // Preserve bit 3 (X) flags from $n
            registers.F = (registers.F & ~z80Flags.Y.rawValue) | (opcode2 & z80Flags.Y.rawValue)   // Preserve bit 5 (Y) flags from $n
            registers.PC = registers.PC &+ 2
            registers.Q = registers.F
            tStates = tStates + 7
            incrementR(opcodeCount:1)
        case 0xFF: // RST 0x38 - FF - The current PC value plus one is pushed onto the stack, then is loaded with 0x38
            logInstructionDetails(instructionDetails: "RST 0x38", opcode: [0xFF], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC >> 8))
            registers.SP = registers.SP &- 1
            bus.writeByte(address: registers.SP, value: UInt8(registers.PC & 0x00FF))
            registers.PC = 0x0038
            registers.Q = 0
            registers.WZ = registers.PC
            tStates = tStates + 11
            incrementR(opcodeCount:1)
        default:
            logInstructionDetails(opcode: [opcode1], programCounter: registers.PC)
            registers.PC = registers.PC &+ 1
            registers.Q = 0
            tStates = tStates + 8
            incrementR(opcodeCount:1)
            // Assuming this is correct behaviour - confirm what decodes in missing ranges in real z80
        }
    }
    
    func sortZ80Queue() -> [String]
    {
        var tempZ80Queue: [String] = []
        
        for counter in 0..<16
        {
            let z80QueuePosition = (z80QueueHead + counter) % 16
            let tempPC = z80Queue[z80QueuePosition]
            let tempBytes = [bus.readByte(address: tempPC),bus.readByte(address: tempPC &+ 1),bus.readByte(address: tempPC &+ 2),bus.readByte(address: tempPC &+ 3)]
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
            tempBreakpointQueue.append(String(format: "%04X",breakpoints[counter]))
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
                R0: bus.crtc.registers.R0,
                R1: bus.crtc.registers.R1,
                R2: bus.crtc.registers.R2,
                R3: bus.crtc.registers.R3,
                R4: bus.crtc.registers.R4,
                R5: bus.crtc.registers.R5,
                R6: bus.crtc.registers.R6,
                R7: bus.crtc.registers.R7,
                R8: bus.crtc.registers.R8,
                R9: bus.crtc.registers.R9,
                R10: bus.crtc.registers.R10,
                R11: bus.crtc.registers.R11,
                R12: bus.crtc.registers.R12,
                R13: bus.crtc.registers.R13,
                R14: bus.crtc.registers.R14,
                R15: bus.crtc.registers.R15,
                R16: bus.crtc.registers.R16,
                R17: bus.crtc.registers.R17,
                R18: bus.crtc.registers.R18,
                R19: bus.crtc.registers.R19,
                statusRegister: bus.crtc.registers.statusRegister,
                redBackgroundIntensity: bus.crtc.registers.redBackgroundIntensity,
                greenBackgroundIntensity: bus.crtc.registers.greenBackgroundIntensity,
                blueBackgroundIntensity: bus.crtc.registers.blueBackgroundIntensity
            ),
            executionSnapshot: executionSnapshot(
                tStates: tStates,
                emulatorState: emulatorState,
                executionMode: executionMode,
                ports: bus.ports.returnPorts(),
                orderedZ80Queue: sortZ80Queue(),
                breakpointQueue: sortBreakpointQueue(),
                breakpointQueueMask : sortBreakpointQueueMask(),
                currentInstruction : z80Disassembler.decodeInstructions(address: registers.PC, bytes: [bus.readByte(address: registers.PC),bus.readByte(address: registers.PC &+ 1),bus.readByte(address: registers.PC &+ 2),bus.readByte(address: registers.PC &+ 3)])
            ),
            memorySnapshot: memorySnapshot(
                VDU: bus.videoRAM.bufferTransform(),
                CharRom: bus.fontROM.bufferTransform(),
                PcgRam: bus.pcgRAM.bufferTransform(),
                ColourRam: bus.colourRAM.bufferTransform(),
                memoryDump: bus.memorySlice(address: registers.PC & 0xFF00, size: 0x100)
            )
        )
    }
}
