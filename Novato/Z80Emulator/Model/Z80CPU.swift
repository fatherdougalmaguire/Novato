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
                                   MemoryData :  [0x21,0x00,0xF0,0x3E,0x48,0x77,0x23,0x3E,0x45,0x77,0x23,0x3E,0x4C,0x77,0x23,0x3E,0x4C,0x77,0x23,0x3E,0x4F,0x77,0x23])
        //        0000   21 00 F0               LD   HL,$F000
        //        0003   3E 48                  LD   A,"H"
        //        0005   77                     LD   (HL),A
        //        0006   23                     INC   HL
        //        0007   3E 45                  LD   A,"E"
        //        0009   77                     LD   (HL),A
        //        000A   23                     INC   HL
        //        000B   3E 4C                  LD   A,"L"
        //        000D   77                     LD   (HL),A
        //        000E   23                     INC   HL
        //        000F   3E 4C                  LD   A,"L"
        //        0011   77                     LD   (HL),A
        //        0012   23                     INC   HL
        //        0013   3E 4F                  LD   A,"O"
        //        0015   77                     LD   (HL),A
        //        0016   23                     INC   HL
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
    
    func DecrementRegPair ( BaseValue  : UInt16, Increment : UInt16 ) -> UInt16
    
    {
        return BaseValue &- Increment
    }
    
    func IncrementReg ( BaseValue  : UInt8, Increment : UInt8 ) -> UInt8
    
    {
        return BaseValue &+ Increment
        // flag code goes here
    }
    
    func DecrementReg ( BaseValue  : UInt8, Increment : UInt8 ) -> UInt8
    
    {
        return BaseValue &- Increment
        // flag code goes here
    }

    private func execute( opcodes: ( opcode1 : UInt8, opcode2 : UInt8, opcode3 : UInt8, opcode4 : UInt8)) async {
        switch opcodes.opcode1
        {
        case 0x00: // NOP
            print("Executed NOP @ "+String(format:"%04X",registers.PC))
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x21: // LD HL, nn
            print("Executed LD HL, nn @ "+String(format:"%04X",registers.PC))
            registers.HL = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:3)
        case 0x23: // INC HL
            print("Executed INC HL @ "+String(format:"%04X",registers.PC))
            registers.HL = IncrementRegPair(BaseValue:registers.HL,Increment:1)
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x3C: // INC A
            print("Executed INC A @ "+String(format:"%04X",registers.PC))
            registers.A = IncrementReg(BaseValue:registers.A,Increment:1)
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x3E: // LD A, n
            print("Executed LD A, n @ "+String(format:"%04X",registers.PC))
            registers.A = opcodes.opcode2
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:2)
        case 0x77: // LD (HL), A
            print("Executed LD (HL), A @ "+String(format:"%04X",registers.PC))
            if (0xF000...0xF7FF).contains(registers.HL)
            {
                VDURAM.WriteMemory(MemoryAddress : registers.HL-0xF000, MemoryValue : registers.A)
            }
            AddressSpace.WriteMemory(MemoryAddress : registers.HL, MemoryValue : registers.A)
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x78: // LD A, B
            print("Executed LD A, B @ "+String(format:"%04X",registers.PC))
            registers.A = registers.B
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x79: // LD A,C
            print("Executed LD A, C @ "+String(format:"%04X",registers.PC))
            registers.A = registers.C
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x7A: // LD A,D
            print("Executed LD A, D @ "+String(format:"%04X",registers.PC))
            registers.A = registers.D
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x7B: // LD A,E
            print("Executed LD A, E @ "+String(format:"%04X",registers.PC))
            registers.A = registers.E
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x7C: // LD A,H
            print("Executed LD A, H @ "+String(format:"%04X",registers.PC))
            registers.A = registers.H
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x7D: // LD A,L
            print("Executed LD A, L @ "+String(format:"%04X",registers.PC))
            registers.A = registers.L
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x04: // INC B
            print("Unimplemented opcode "+String(format: "%02X", opcodes.opcode1) + " @ "+String(format:"%04X",registers.PC))
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x05: // DEC B
            print("Unimplemented opcode "+String(format: "%02X", opcodes.opcode1) + " @ "+String(format:"%04X",registers.PC))
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        default:
            print("Unknown opcode "+String(format: "%02X", opcodes.opcode1) + " @ "+String(format:"%04X",registers.PC))
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
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
                             VDU : VDURAM.memory)
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
                         VDU : VDURAM.memory)
    }
}

