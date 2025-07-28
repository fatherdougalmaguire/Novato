import Foundation

class Z80CPU: ObservableObject {
    @Published var memory = [UInt8](repeating: 0, count: 65536)
    @Published var registers = Registers()
    @Published var isRunning = false

    init()
    {
        memory[1] = 0x3c
    }
    
    func step() {
        let pc = Int(registers.PC)
        let opcode = memory[pc]
        registers.PC &+= 1

        switch opcode {
        case 0x00: // NOP
            break
        case 0x3C: // INC A
            let a = UInt8(registers.AF >> 8)
            let result = a &+ 1
            registers.AF = UInt16(result) << 8 | UInt16(registers.AF & 0x00FF)
        case 0x78: // LD A, B
            let b = UInt8(registers.BC >> 8)
            let f = UInt8(registers.AF & 0x00FF)
            registers.AF = UInt16(b) << 8 | UInt16(f)
        default:
            print("Unknown opcode: \(String(format: "%02X", opcode))")
        }
    }

    func run(cycles: Int) {
        for _ in 0..<cycles {
            guard isRunning else { break }
            step()
        }
    }

    func reset() {
        registers = Registers()
        memory = [UInt8](repeating: 0, count: 65536)
    }
}
