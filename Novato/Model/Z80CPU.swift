import Foundation

actor Z80CPU {
    var registers = Registers()
    
    var runcycles : UInt64 = 0
    var CPUstarttime : Date = Date()
    var CPUendtime : Date = Date()

    var AddressSpace = MMU(MemorySize : 0x10000, MemoryValue : 0x00)
    var VDURAM = MMU(MemorySize : 0x800, MemoryValue : 0x20)
    var CharGenROM = MMU(MemorySize : 0x1000, MemoryValue : 0x00)
    
    init()
    {
        AddressSpace.memory[0xf000...0xf7ff] = VDURAM.memory[0...0x7ff]
        AddressSpace.LoadMemoryFromFile(FileName: "basic_5.22e", FileExtension: "rom",MemoryAddress : 0x8000)
        AddressSpace.LoadMemoryFromFile(FileName: "wordbee_1.2", FileExtension: "rom",MemoryAddress : 0xC000)
        AddressSpace.LoadMemoryFromFile(FileName: "telcom_1.0", FileExtension: "rom",MemoryAddress : 0xE000)
        CharGenROM.LoadMemoryFromFile(FileName: "charrom", FileExtension: "bin", MemoryAddress : 0x0000)
        AddressSpace.LoadMemoryFromArray(MemoryAddress : 0x0000,
                                   MemoryData :  [0x3E,0x01,
                                                  0xFE,0x01,
                                                  0x28,0x24,
                                                  0x21,0x4E,0x00,
                                                  0x11,0x00,0xF0,
                                                  0x01,0x33,0x00,
                                                  0xED,0xB0,
                                                  0x21,0x81,0x00,
                                                  0x11,0x80,0xF0,
                                                  0x01,0x2A,0x00,
                                                  0xED,0xB0,
                                                  0x21,0xAB,0x00,
                                                  0x11,0x00,0xF1,
                                                  0x01,0x01,0x00,
                                                  0xED,0xB0,
                                                  0xC3,0x00,0x10,
                                                  0x21,0xAC,0x00,
                                                  0x11,0x50,0xF0,
                                                  0x01,0x13,0x00,
                                                  0xED,0xB0,
                                                  0x21,0xBF,0x00,
                                                  0x11,0xA0,0xF0,
                                                  0x01,0x13,0x00,
                                                  0xED,0xB0,
                                                  0x21,0xD2,0x00,
                                                  0x11,0x40,0xF1,
                                                  0x01,0x02,0x00,
                                                  0xED,0xB0,
                                                  0xC3,0x00,0x10,
                                                  0x41,0x70,0x70,0x6C,0x69,0x65,0x64,0x20,0x54,0x65,0x63,0x68,0x6E,0x6F,0x6C,0x6F,0x67,0x79,0x20,0x4D,0x69,0x63,0x72,0x6F,0x62,0x65,0x65,0x20,0x43,0x6F,0x6C,0x6F,0x75,0x72,0x20,0x42,0x61,0x73,0x69,0x63,0x2E,0x20,0x56,0x65,0x72,0x20,0x35,0x2E,0x32,0x32,0x65,
                                                  0x43,0x6F,0x70,0x79,0x72,0x69,0x67,0x68,0x74,0x20,0x4D,0x53,0x20,0x31,0x39,0x38,0x33,0x20,0x66,0x6F,0x72,0x20,0x4D,0x69,0x63,0x72,0x6F,0x57,0x6F,0x72,0x6C,0x64,0x20,0x41,0x75,0x73,0x74,0x72,0x61,0x6C,0x69,0x61,
                                                  0x3E,
                                                  0x4D,0x69,0x63,0x72,0x6F,0x62,0x65,0x65,0x20,0x20,0x35,0x36,0x4B,0x20,0x20,0x43,0x50,0x2F,0x4D,
                                                  0x56,0x65,0x72,0x73,0x20,0x32,0x2E,0x32,0x30,0x20,0x5B,0x5A,0x43,0x50,0x52,0x20,0x49,0x49,0x5D,
                                                  0x41,0x3E])
//        0000   3E 01                  LD   A,1
//        0002   FE 01                  CP   1
//        0004   28 24                  JR   Z,EIGHTY
//        0006   21 4E 00               LD   HL,LINE1_64
//        0009   11 00 F0               LD   DE,$F000
//        000C   01 33 00               LD   BC,$33
//        000F   ED B0                  LDIR
//        0011   21 81 00               LD   HL,LINE2_64
//        0014   11 80 F0               LD   DE,$F080
//        0017   01 2A 00               LD   BC,$2A
//        001A   ED B0                  LDIR
//        001C   21 AB 00               LD   HL,LINE3_64
//        001F   11 00 F1               LD   DE,$F100
//        0022   01 01 00               LD   BC,$01
//        0025   ED B0                  LDIR
//        0027   C3 00 10               JP   $1000
//        002A                EIGHTY:
//        002A   21 AC 00               LD   HL,LINE1_80
//        002D   11 50 F0               LD   DE,$F050
//        0030   01 13 00               LD   BC,$13
//        0033   ED B0                  LDIR
//        0035   21 BF 00               LD   HL,LINE2_80
//        0038   11 A0 F0               LD   DE,$F0A0
//        003B   01 13 00               LD   BC,$13
//        003E   ED B0                  LDIR
//        0040   21 D2 00               LD   HL,LINE3_80
//        0043   11 40 F1               LD   DE,$F140
//        0046   01 02 00               LD   BC,$02
//        0049   ED B0                  LDIR
//        004B   C3 00 10               JP   $1000
//        004E                LINE1_64:
//        004E   41 70 70 6C 69 65 64 20 54 65 63 68 6E 6F 6C 6F 67 79 20 4D 69 63 72 6F 62 65 65 20 43 6F 6C 6F 75 72 20 42 61 73 69 63 2E 20 56 65 72 20 35 2E 32 32 65 DB   "Applied Technology Microbee Colour Basic. Ver 5.22e"
//        0081                LINE2_64:
//        0081   43 6F 70 79 72 69 67 68 74 20 4D 53 20 31 39 38 33 20 66 6F 72 20 4D 69 63 72 6F 57 6F 72 6C 64 20 41 75 73 74 72 61 6C 69 61 DB   "Copyright MS 1983 for MicroWorld Australia"
//        00AB                LINE3_64:
//        00AB   3E                     DB   ">"
//        00AC                LINE1_80:
//        00AC   4D 69 63 72 6F 62 65 65 20 20 35 36 4B 20 20 43 50 2F 4D DB   "Microbee  56K  CP/M"
//        00BF                LINE2_80:
//        00BF   56 65 72 73 20 32 2E 32 30 20 5B 5A 43 50 52 20 49 49 5D DB   "Vers 2.20 [ZCPR II]"
//        00D2                LINE3_80:
//        00D2   41 3E                  DB   "A>"
    }

    private(set) var running = false

    func start()
    {
        CPUstarttime = Date()
        guard !running else { return }
        running = true
        Task.detached(priority: .background) { await self.runLoop() }
    }

    func stop()
    {
        CPUendtime = Date()
        running = false
        let ken = CPUendtime.timeIntervalSince1970-CPUstarttime.timeIntervalSince1970
        print(ken,"seconds")
        print(runcycles," instructions")
        print("Each instruction takes ",ken / Double(runcycles)*1000*1000," microseconds to execute")
        runcycles = 0
    }

    private func runLoop() async
    {
        while running
        {
            let prefetch = fetch(ProgramCounter : registers.PC)
            await execute(opcodes : prefetch)
            try? await Task.sleep(nanoseconds: 100)
        }
    }

    private func fetch( ProgramCounter : UInt16) -> (UInt8,UInt8,UInt8,UInt8)
    {
        return ( opcode1 : AddressSpace.ReadMemory(MemoryAddress : ProgramCounter),
                 opcode2 : AddressSpace.ReadMemory(MemoryAddress : IncrementRegPair(BaseValue : ProgramCounter,Increment : 1)),
                 opcode3 : AddressSpace.ReadMemory(MemoryAddress : IncrementRegPair(BaseValue : ProgramCounter,Increment : 2)),
                 opcode4 : AddressSpace.ReadMemory(MemoryAddress : IncrementRegPair(BaseValue : ProgramCounter,Increment : 3))
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

    private func execute( opcodes: ( opcode1 : UInt8, opcode2 : UInt8, opcode3 : UInt8, opcode4 : UInt8)) async {
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
            print("Executed JR Z, n @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:opcodes.opcode2)
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
            print("Executed LD A, n @ "+String(format:"%04X",registers.PC))
            registers.A = opcodes.opcode2
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
        case 0x77: // LD (HL), A
            print("Executed LD (HL), A @ "+String(format:"%04X",registers.PC))
            if (0xF000...0xF7FF).contains(registers.HL)
            {
                VDURAM.WriteMemory(MemoryAddress : registers.HL-0xF000, MemoryValue : registers.A)
            }
            AddressSpace.WriteMemory(MemoryAddress : registers.HL, MemoryValue : registers.A)
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
        case 0xC3: // JP nn
            print("Executed JP nn @ "+String(format:"%04X",registers.PC))
            registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
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
                    AddressSpace.WriteMemory(MemoryAddress : registers.DE, MemoryValue : AddressSpace.ReadMemory(MemoryAddress : registers.HL))
                    VDURAM.WriteMemory(MemoryAddress : registers.DE-0xF000, MemoryValue : AddressSpace.ReadMemory(MemoryAddress : registers.HL))
                    registers.HL = IncrementRegPair(BaseValue:registers.HL,Increment:1)
                    registers.DE = IncrementRegPair(BaseValue:registers.DE,Increment:1)
                    registers.BC = DecrementRegPair(BaseValue:registers.BC,Decrement:1)
                }
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
            default:
                print("Unknown opcode "+String(format: "%02X", opcodes.opcode1)+String(format: "%02X", opcodes.opcode2) + " @ "+String(format:"%04X",registers.PC))
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
            }
        case 0xFE: // CP n
            print("Executed CP n @ "+String(format:"%04X",registers.PC))
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
        guard Int(registers.PC)+0x0ff < 0x10000
        else
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
                             memoryDump: Array(AddressSpace.memory[Int(registers.PC)..<0xffff]),
                             VDU : VDURAM.memory.map { Float($0) },
                             CharRom : CharGenROM.memory.map { Float($0) } )
        }
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
                         memoryDump: Array(AddressSpace.memory[Int(registers.PC)..<Int(registers.PC)+0x0ff]),
                         VDU : VDURAM.memory.map { Float($0) },
                         CharRom : CharGenROM.memory.map { Float($0) } )
    }
}

