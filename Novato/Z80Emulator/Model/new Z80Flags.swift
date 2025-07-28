//import Foundation
//
//struct Z80Flags {
//    static func updateFlags(cpu: Z80CPU, result: UInt8, carry: Bool = false, halfCarry: Bool = false, subtract: Bool = false, overflow: Bool = false) {
//        var flags: UInt8 = 0
//        if result == 0 { flags |= 0b01000000 } // Z
//        if result & 0x80 != 0 { flags |= 0b10000000 } // S
//        if carry { flags |= 0b00000001 } // C
//        if halfCarry { flags |= 0b00010000 } // H
//        if subtract { flags |= 0b00000010 } // N
//        if overflow { flags |= 0b00000100 } // P/V
//
//        let af = cpu.registers["AF"]!
//        cpu.registers["AF"] = (af & 0xFF00) | UInt16(flags)
//    }
//}
