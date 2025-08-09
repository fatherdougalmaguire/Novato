import Foundation

@MainActor
class Z80CPU: ObservableObject {
    @Published var memory = [UInt8](repeating: 0x23, count: 65536)
    @Published var registers = Registers()
    @Published var isRunning = false
    var runcycles : UInt64 = 0
    var ElapsedStartTime : Date = Date()
    var ElapsedEndTime : Date = Date()
    
    private var task : Task<Void,Never>? = nil

    init()
    {
        memory[0] = 0x3c
        memory[1] = 0x23
        memory[2] = 0x23
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
    
    func step()
    {
        let prefetch = ( opcode1 : memory[Int(registers.PC)], opcode2 : memory[Int(IncrementRegPair(BaseValue:registers.PC,Increment:1))], opcode3 : memory[Int(IncrementRegPair(BaseValue:registers.PC,Increment:2))], opcode4 : memory[Int(IncrementRegPair(BaseValue:registers.PC,Increment:3))] )
        
        switch prefetch.opcode1
        {
            case 0x00: // NOP
                registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
            case 0x21: // LD HL, nn
            registers.HL = UInt16(prefetch.opcode2 << 8 | prefetch.opcode3)
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
            default:
            print("Unknown opcode: \(String(format: "%02X", prefetch.opcode1))")
            
        }
        runcycles = runcycles + 1
    }

    func run(cycles: Int) {
        for _ in 0..<cycles {
            guard isRunning else { break }
            step()
        }
    }
    
    func start()
    {
        ElapsedStartTime = Date()
        task = Task
        {
            while !Task.isCancelled
            {
                step()
                try? await Task.sleep(nanoseconds: 10)
            }
        }
    }

    func stop()
    {
        task?.cancel()
        task = nil
        ElapsedEndTime = Date()
        let ken = ElapsedEndTime.timeIntervalSince1970-ElapsedStartTime.timeIntervalSince1970
        print(ken,"seconds")
        print(runcycles," instructions")
        print("Each instruction takes ",ken / Double(runcycles)*1000," millseconds to execute")
    }
    
    func reset() {
        registers = Registers()
        memory = [UInt8](repeating: 0, count: 65536)
    }
}
