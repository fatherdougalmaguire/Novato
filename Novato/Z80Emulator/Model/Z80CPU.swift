import Foundation

actor Z80CPU {
    var registers = Registers()
    
    var runcycles : UInt64 = 0
    var CPUstarttime : Date = Date()
    var CPUendtime : Date = Date()

    var memory: [UInt8] = Array(repeating: 0, count: 0x10000)
    
    init()
    {
        for mycount in 0...0xFFFF
        {
            memory[mycount] = UInt8.random(in: 0...255)
        }
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
            let prefetch = fetch(pc:Int(registers.PC))
            await execute( opcodes : prefetch)
            // Roughly emulate 1 Mhz (≈1 µs per instruction) – tweak as needed.
            try? await Task.sleep(nanoseconds: 1000)
        }
    }

    private func fetch( pc : Int) -> (UInt8,UInt8,UInt8,UInt8)
    {
        return ( opcode1 : memory[Int(registers.PC)], opcode2 : memory[Int(IncrementRegPair(BaseValue:registers.PC,Increment:1))], opcode3 : memory[Int(IncrementRegPair(BaseValue:registers.PC,Increment:2))], opcode4 : memory[Int(IncrementRegPair(BaseValue:registers.PC,Increment:3))] )
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
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x21: // LD HL, nn
        registers.HL = UInt16(opcodes.opcode2 << 8 | opcodes.opcode3)
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:3)
        case 0x23: // INC HL
            registers.HL = registers.HL + 1
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x3C: // INC A
            registers.A = registers.A + 1
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x78: // LD A, B
            registers.A = registers.B
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x79: // LD A,C
            registers.A = registers.C
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x7A: // LD A,D
            registers.A = registers.D
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x7B: // LD A,E
            registers.A = registers.E
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x7C: // LD A,H
            registers.A = registers.H
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x7D: // LD A,L
            registers.A = registers.L
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x04: // INC B
            print("Unimplemented opcode: \(String(format: "%02X", opcodes.opcode1))")
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x05: // DEC B
            print("Unimplemented opcode: \(String(format: "%02X", opcodes.opcode1))")
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        default:
            print("Unknown opcode: \(String(format: "%02X", opcodes.opcode1))")
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        }
        runcycles = runcycles+1
    }

    func getState() async -> CPUState
    {
        return CPUState( PC: registers.PC, SP: registers.SP, A: registers.A, F: registers.F, B: registers.B, C: registers.C, D: registers.D, E: registers.E, H: registers.H, L: registers.L, memoryDump: Array(memory[0..<0x0ff]))
    }
}

