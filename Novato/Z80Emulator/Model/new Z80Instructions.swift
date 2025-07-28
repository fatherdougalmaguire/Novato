////import Foundation
//
//extension Z80CPU {
//    func execute(_ opcode: UInt8) {
//        switch opcode {
//        case 0x00: // NOP
//            registers["PC"]! += 1
//
//        case 0x3E: // LD A, n
//            let value = memory[Int(registers["PC"]! + 1)]
//            registers["AF"] = (UInt16(value) << 8) | (registers["AF"]! & 0x00FF)
//            registers["PC"]! += 2
//
//        case 0x80: // ADD A, B
//            let af = registers["AF"]!
//            let a = UInt8((af & 0xFF00) >> 8)
//            let b = UInt8((registers["BC"]! & 0xFF00) >> 8)
//            let result = a &+ b
//            let carry = UInt16(a) + UInt16(b) > 0xFF
//            let halfCarry = ((a & 0x0F) + (b & 0x0F)) > 0x0F
//            let overflow = (~(a ^ b) & (a ^ result) & 0x80) != 0
//            Z80Flags.updateFlags(cpu: self, result: result, carry: carry, halfCarry: halfCarry, subtract: false, overflow: overflow)
//            registers["AF"] = (UInt16(result) << 8) | (registers["AF"]! & 0x00FF)
//            registers["PC"]! += 1
//
//        default:
//            print("Unknown opcode: \(String(format: "%02X", opcode))")
//            registers["PC"]! += 1
//        }
//    }
//}
