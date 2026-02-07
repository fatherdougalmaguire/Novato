import Foundation

struct z80Queue: Sendable, Equatable
{
    struct singleInstruction: Sendable, Equatable
    {
        var address : UInt16
        var opCodes : [UInt8]
        var dataBytes : [UInt8]
    }
    
    private var queueHead : Int
    private var queueCount : Int
    
    private var instructionQueue = ContiguousArray<singleInstruction>(repeating: singleInstruction(address: 0xFFFF, opCodes: [], dataBytes: []), count: 16)
    
    init()
    {
        queueHead = 0
        queueCount = 0
    }
    
    @inline(__always)
    mutating func addToQueue(address: UInt16, opCodes: [UInt8], dataBytes: [UInt8]=[])
    {
        instructionQueue[queueHead] = singleInstruction(address: address, opCodes: opCodes, dataBytes: dataBytes)
        queueHead = (queueHead + 1) & 15
    }
    
    func decodeAddress(index: Int) -> String
    {
        return String(format:"0x%04X",instructionQueue[index].address)
    }
    
    func returnAddress(index: Int) -> UInt16
    {
        return instructionQueue[index].address
    }
    
    func returnOpcodes(index: Int) -> [UInt8]
    {
        return instructionQueue[index].opCodes
    }
    
    func returnDataBytes(index: Int) -> [UInt8]
    {
        return instructionQueue[index].dataBytes
    }
    
    func checkEmptyQueue(index: Int) -> Bool
   {
//        if queueCount < index
//        {
//          return true
//        }
//        else
//        {
//          return false
//        }
    return false
    }
    
    func decodeBytes(index: Int) -> String
    {
        let combinedDataBytes = instructionQueue[index].opCodes + instructionQueue[index].dataBytes
        var TempResult = combinedDataBytes.map { String(format: "%02X", $0) }.joined(separator: " ")
        
        let paddingCount = 4-combinedDataBytes.count
        
        for _ in 0..<paddingCount
        {
            TempResult =  TempResult + "   "
        }
        return TempResult
    }
}

struct Z80Opcodes
{
    struct opCode
    {
        var mnemonic : String
        var size     : Int
    }
    
        let singleOpcode: [opCode] =
        [
            opCode(mnemonic: "NOP", size: 1) ,          // 0x00
            opCode(mnemonic: "LD BC,$nn", size: 3) ,    // 0x01
            opCode(mnemonic: "LD (BC),A", size: 1) ,    // 0x02
            opCode(mnemonic: "INC BC", size: 1) ,       // 0x03
            opCode(mnemonic: "INC B", size: 1) ,        // 0x04
            opCode(mnemonic: "DEC B", size: 1) ,        // 0x05
            opCode(mnemonic: "LD B,$n", size: 2) ,      // 0x06
            opCode(mnemonic: "RLCA", size: 1) ,         // 0x07
            opCode(mnemonic: "EX AF,AF'", size: 1) ,    // 0x08
            opCode(mnemonic: "ADD HL,BC", size: 1) ,    // 0x09
            opCode(mnemonic: "LD A,(BC)", size: 1) ,    // 0x0A
            opCode(mnemonic: "DEC BC", size: 1) ,       // 0x0B
            opCode(mnemonic: "INC C", size: 1) ,        // 0x0C
            opCode(mnemonic: "DEC C", size: 1) ,        // 0x0D
            opCode(mnemonic: "LD C,$n", size: 2) ,      // 0x0E
            opCode(mnemonic: "RRCA", size: 1) ,         // 0x0F
            opCode(mnemonic: "DJNZ $d", size: 2) ,      // 0x10
            opCode(mnemonic: "LD DE,$nn", size: 3) ,    // 0x11
            opCode(mnemonic: "LD (DE),A", size: 1) ,    // 0x12
            opCode(mnemonic: "INC DE", size: 1) ,       // 0x13
            opCode(mnemonic: "INC D", size: 1) ,        // 0x14
            opCode(mnemonic: "DEC D", size: 1) ,        // 0x15
            opCode(mnemonic: "LD D,$n", size: 2) ,      // 0x16
            opCode(mnemonic: "RLA", size: 1) ,          // 0x17
            opCode(mnemonic: "JR $d", size: 2) ,        // 0x18
            opCode(mnemonic: "ADD HL,DE", size: 1) ,    // 0x19
            opCode(mnemonic: "LD A,(DE)", size: 1) ,    // 0x1A
            opCode(mnemonic: "DEC DE", size: 1) ,       // 0x1B
            opCode(mnemonic: "INC E", size: 1) ,        // 0x1C
            opCode(mnemonic: "DEC E", size: 1) ,        // 0x1D
            opCode(mnemonic: "LD E,$n", size: 2) ,      // 0x1E
            opCode(mnemonic: "RRA", size: 1) ,          // 0x1F
            opCode(mnemonic: "JR NZ,$d", size: 2) ,     // 0x20
            opCode(mnemonic: "LD HL,$nn", size: 3) ,    // 0x21
            opCode(mnemonic: "LD ($nn),HL", size: 3) ,  // 0x22
            opCode(mnemonic: "INC HL", size: 1) ,       // 0x23
            opCode(mnemonic: "INC H", size: 1) ,        // 0x24
            opCode(mnemonic: "DEC H", size: 1) ,        // 0x25
            opCode(mnemonic: "LD H,$n", size: 2) ,      // 0x26
            opCode(mnemonic: "DAA", size: 1) ,          // 0x27
            opCode(mnemonic: "JR Z,$d", size: 2) ,      // 0x28
            opCode(mnemonic: "ADD HL,HL", size: 1) ,    // 0x29
            opCode(mnemonic: "LD HL,($nn)", size: 3) ,  // 0x2A
            opCode(mnemonic: "DEC HL", size: 1) ,       // 0x2B
            opCode(mnemonic: "INC L", size: 1) ,        // 0x2C
            opCode(mnemonic: "DEC L", size: 1) ,        // 0x2D
            opCode(mnemonic: "LD L,$n", size: 2) ,      // 0x2E
            opCode(mnemonic: "CPL", size: 1) ,          // 0x2F
            opCode(mnemonic: "JR NC,$d", size: 2) ,     // 0x30
            opCode(mnemonic: "LD SP,$nn", size: 3) ,    // 0x31
            opCode(mnemonic: "LD ($nn),A", size: 3) ,   // 0x32
            opCode(mnemonic: "INC SP", size: 1) ,       // 0x33
            opCode(mnemonic: "INC (HL)", size: 1) ,     // 0x34
            opCode(mnemonic: "DEC (HL)", size: 1) ,     // 0x35
            opCode(mnemonic: "LD (HL),$n", size: 2) ,   // 0x36
            opCode(mnemonic: "SCF", size: 1) ,          // 0x37
            opCode(mnemonic: "JR C,$d", size: 2) ,      // 0x38
            opCode(mnemonic: "ADD HL,SP", size: 1) ,    // 0x39
            opCode(mnemonic: "LD A,($nn)", size: 3) ,   // 0x3A
            opCode(mnemonic: "DEC SP", size: 1) ,       // 0x3B
            opCode(mnemonic: "INC A", size: 1) ,        // 0x3C
            opCode(mnemonic: "DEC A", size: 1) ,    // 0x3D
            opCode(mnemonic: "LD A,$n", size: 2) ,    // 0x3E
            opCode(mnemonic: "CCF", size: 1) ,    // 0x3F
            opCode(mnemonic: "LD B,B", size: 1) ,    // 0x40
            opCode(mnemonic: "LD B,C", size: 1) ,    // 0x41
            opCode(mnemonic: "LD B,D", size: 1) ,    // 0x42
            opCode(mnemonic: "LD B,E", size: 1) ,    // 0x43
            opCode(mnemonic: "LD B,H", size: 1) ,    // 0x44
            opCode(mnemonic: "LD B,L", size: 1) ,    // 0x45
            opCode(mnemonic: "LD B,(HL)", size: 1) ,    // 0x46
            opCode(mnemonic: "LD B,A", size: 1) ,    // 0x47
            opCode(mnemonic: "LD C,B", size: 1) ,    // 0x48
            opCode(mnemonic: "LD C,C", size: 1) ,    // 0x49
            opCode(mnemonic: "LD C,D", size: 1) ,    // 0x4A
            opCode(mnemonic: "LD C,E", size: 1) ,    // 0x4B
            opCode(mnemonic: "LD C,H", size: 1) ,    // 0x4C
            opCode(mnemonic: "LD C,L", size: 1) ,    // 0x4D
            opCode(mnemonic: "LD C,(HL)", size: 1) ,    // 0x4E
            opCode(mnemonic: "LD C,A", size: 1) ,    // 0x4F
            opCode(mnemonic: "LD D,B", size: 1) ,    // 0x50
            opCode(mnemonic: "LD D,C", size: 1) ,    // 0x51
            opCode(mnemonic: "LD D,D", size: 1) ,    // 0x52
            opCode(mnemonic: "LD D,E", size: 1) ,    // 0x53
            opCode(mnemonic: "LD D,H", size: 1) ,    // 0x54
            opCode(mnemonic: "LD D,L", size: 1) ,    // 0x55
            opCode(mnemonic: "LD D,(HL)", size: 1) ,    // 0x56
            opCode(mnemonic: "LD D,A", size: 1) ,    // 0x57
            opCode(mnemonic: "LD E,B", size: 1) ,    // 0x58
            opCode(mnemonic: "LD E,C", size: 1) ,    // 0x59
            opCode(mnemonic: "LD E,D", size: 1) ,    // 0x5A
            opCode(mnemonic: "LD E,E", size: 1) ,    // 0x5B
            opCode(mnemonic: "LD E,H", size: 1) ,    // 0x5C
            opCode(mnemonic: "LD E,L", size: 1) ,    // 0x5D
            opCode(mnemonic: "LD E,(HL)", size: 1) ,    // 0x5E
            opCode(mnemonic: "LD E,A", size: 1) ,    // 0x5F
            opCode(mnemonic: "LD H,B", size: 1) ,    // 0x60
            opCode(mnemonic: "LD H,C", size: 1) ,    // 0x61
            opCode(mnemonic: "LD H,D", size: 1) ,    // 0x62
            opCode(mnemonic: "LD H,E", size: 1) ,    // 0x63
            opCode(mnemonic: "LD H,H", size: 1) ,    // 0x64
            opCode(mnemonic: "LD H,L", size: 1) ,    // 0x65
            opCode(mnemonic: "LD H,(HL)", size: 1) ,    // 0x66
            opCode(mnemonic: "LD H,A", size: 1) ,    // 0x67
            opCode(mnemonic: "LD L,B", size: 1) ,    // 0x68
            opCode(mnemonic: "LD L,C", size: 1) ,    // 0x69
            opCode(mnemonic: "LD L,D", size: 1) ,    // 0x6A
            opCode(mnemonic: "LD L,E", size: 1) ,    // 0x6B
            opCode(mnemonic: "LD L,H", size: 1) ,    // 0x6C
            opCode(mnemonic: "LD L,L", size: 1) ,    // 0x6D
            opCode(mnemonic: "LD L,(HL)", size: 1) ,    // 0x6E
            opCode(mnemonic: "LD L,A", size: 1) ,    // 0x6F
            opCode(mnemonic: "LD (HL),B", size: 1) ,    // 0x70
            opCode(mnemonic: "LD (HL),C", size: 1) ,    // 0x71
            opCode(mnemonic: "LD (HL),D", size: 1) ,    // 0x72
            opCode(mnemonic: "LD (HL),E", size: 1) ,    // 0x73
            opCode(mnemonic: "LD (HL),H", size: 1) ,    // 0x74
            opCode(mnemonic: "LD (HL),L", size: 1) ,    // 0x75
            opCode(mnemonic: "HALT", size: 1) ,    // 0x76
            opCode(mnemonic: "LD (HL),A", size: 1) ,    // 0x77
            opCode(mnemonic: "LD A,B", size: 1) ,    // 0x78
            opCode(mnemonic: "LD A,C", size: 1) ,    // 0x79
            opCode(mnemonic: "LD A,D", size: 1) ,    // 0x7A
            opCode(mnemonic: "LD A,E", size: 1) ,    // 0x7B
            opCode(mnemonic: "LD A,H", size: 1) ,    // 0x7C
            opCode(mnemonic: "LD A,L", size: 1) ,    // 0x7D
            opCode(mnemonic: "LD A,(HL)", size: 1) ,    // 0x7E
            opCode(mnemonic: "LD A,A", size: 1) ,    // 0x7F
            opCode(mnemonic: "ADD A,B", size: 1) ,    // 0x80
            opCode(mnemonic: "ADD A,C", size: 1) ,    // 0x81
            opCode(mnemonic: "ADD A,D", size: 1) ,    // 0x82
            opCode(mnemonic: "ADD A,E", size: 1) ,    // 0x83
            opCode(mnemonic: "ADD A,H", size: 1) ,    // 0x84
            opCode(mnemonic: "ADD A,L", size: 1) ,    // 0x85
            opCode(mnemonic: "ADD A,(HL)", size: 1) ,    // 0x86
            opCode(mnemonic: "ADD A,A", size: 1) ,    // 0x87
            opCode(mnemonic: "ADC A,B", size: 1) ,    // 0x88
            opCode(mnemonic: "ADC A,C", size: 1) ,    // 0x89
            opCode(mnemonic: "ADC A,D", size: 1) ,    // 0x8A
            opCode(mnemonic: "ADC A,E", size: 1) ,    // 0x8B
            opCode(mnemonic: "ADC A,H", size: 1) ,    // 0x8C
            opCode(mnemonic: "ADC A,L", size: 1) ,    // 0x8D
            opCode(mnemonic: "ADC A,(HL)", size: 1) ,    // 0x8E
            opCode(mnemonic: "ADC A,A", size: 1) ,    // 0x8F
            opCode(mnemonic: "SUB B", size: 1) ,    // 0x90
            opCode(mnemonic: "SUB C", size: 1) ,    // 0x91
            opCode(mnemonic: "SUB D", size: 1) ,    // 0x92
            opCode(mnemonic: "SUB E", size: 1) ,    // 0x93
            opCode(mnemonic: "SUB H", size: 1) ,        // 0x94
            opCode(mnemonic: "SUB L", size: 1) ,        // 0x95
            opCode(mnemonic: "SUB (HL)", size: 1) ,     // 0x96
            opCode(mnemonic: "SUB A", size: 1) ,        // 0x97
            opCode(mnemonic: "SBC A,B", size: 1) ,    // 0x98
            opCode(mnemonic: "SBC A,C", size: 1) ,    // 0x99
            opCode(mnemonic: "SBC A,D", size: 1) ,    // 0x9A
            opCode(mnemonic: "SBC A,E", size: 1) ,    // 0x9B
            opCode(mnemonic: "SBC A,H", size: 1) ,    // 0x9C
            opCode(mnemonic: "SBC A,L", size: 1) ,    // 0x9D
            opCode(mnemonic: "SBC A,(HL)", size: 1) ,    // 0x9E
            opCode(mnemonic: "SBC A,A", size: 1) ,    // 0x9F
            opCode(mnemonic: "AND B", size: 1) ,    // 0xA0
            opCode(mnemonic: "AND C", size: 1) ,    // 0xA1
            opCode(mnemonic: "AND D", size: 1) ,    // 0xA2
            opCode(mnemonic: "AND E", size: 1) ,    // 0xA3
            opCode(mnemonic: "AND H", size: 1) ,    // 0xA4
            opCode(mnemonic: "AND L", size: 1) ,    // 0xA5
            opCode(mnemonic: "AND (HL)", size: 1) ,    // 0xA6
            opCode(mnemonic: "AND A", size: 1) ,    // 0xA7
            opCode(mnemonic: "XOR B", size: 1) ,    // 0xA8
            opCode(mnemonic: "XOR C", size: 1) ,    // 0xA9
            opCode(mnemonic: "XOR D", size: 1) ,    // 0xAA
            opCode(mnemonic: "XOR E", size: 1) ,    // 0xAB
            opCode(mnemonic: "XOR H", size: 1) ,    // 0xAC
            opCode(mnemonic: "XOR L", size: 1) ,    // 0xAD
            opCode(mnemonic: "XOR (HL)", size: 1) ,    // 0xAE
            opCode(mnemonic: "XOR A", size: 1) ,    // 0xAF
            opCode(mnemonic: "OR B", size: 1) ,    // 0xB0
            opCode(mnemonic: "OR C", size: 1) ,    // 0xB1
            opCode(mnemonic: "OR D", size: 1) ,    // 0xB2
            opCode(mnemonic: "OR E", size: 1) ,    // 0xB3
            opCode(mnemonic: "OR H", size: 1) ,    // 0xB4
            opCode(mnemonic: "OR L", size: 1) ,    // 0xB5
            opCode(mnemonic: "OR (HL)", size: 1) ,    // 0xB6
            opCode(mnemonic: "OR A", size: 1) ,    // 0xB7
            opCode(mnemonic: "CP B", size: 1) ,    // 0xB8
            opCode(mnemonic: "CP C", size: 1) ,    // 0xB9
            opCode(mnemonic: "CP D", size: 1) ,    // 0xBA
            opCode(mnemonic: "CP E", size: 1) ,    // 0xBB
            opCode(mnemonic: "CP H", size: 1) ,    // 0xBC
            opCode(mnemonic: "CP L", size: 1) ,    // 0xBD
            opCode(mnemonic: "CP (HL)", size: 1) ,    // 0xBE
            opCode(mnemonic: "CP A", size: 1) ,    // 0xBF
            opCode(mnemonic: "RET NZ", size: 1) ,    // 0xC0
            opCode(mnemonic: "POP BC", size: 1) ,    // 0xC1
            opCode(mnemonic: "JP NZ,$nn", size: 3) ,    // 0xC2
            opCode(mnemonic: "JP $nn", size: 3) ,    // 0xC3
            opCode(mnemonic: "CALL NZ,$nn", size: 3) ,    // 0xC4
            opCode(mnemonic: "PUSH BC", size: 1) ,    // 0xC5
            opCode(mnemonic: "ADD A,$n", size: 2) ,    // 0xC6
            opCode(mnemonic: "RST 0x00", size: 1) ,    // 0xC7
            opCode(mnemonic: "RET Z", size: 1) ,    // 0xC8
            opCode(mnemonic: "RET", size: 1) ,    // 0xC9
            opCode(mnemonic: "JP Z,$nn", size: 3) ,    // 0xCA
            opCode(mnemonic: "CB prefixes", size: 0),    // 0xCB
            opCode(mnemonic: "CALL Z,$nn", size: 3) ,    // 0xCC
            opCode(mnemonic: "CALL $nn", size: 3) ,    // 0xCD
            opCode(mnemonic: "ADC A,$n", size: 2) ,    // 0xCE
            opCode(mnemonic: "RST 0x08", size: 1) ,    // 0xCF
            opCode(mnemonic: "RET NC", size: 1) ,    // 0xD0
            opCode(mnemonic: "POP DE", size: 1) ,    // 0xD1
            opCode(mnemonic: "JP NC,$nn", size: 3) ,    // 0xD2
            opCode(mnemonic: "OUT ($n),A", size: 2) ,    // 0xD3
            opCode(mnemonic: "CALL NC,$nn", size: 3) ,    // 0xD4
            opCode(mnemonic: "PUSH DE", size: 1) ,    // 0xD5
            opCode(mnemonic: "SUB $n", size: 2) ,    // 0xD6
            opCode(mnemonic: "RST 0x10", size: 1) ,    // 0xD7
            opCode(mnemonic: "RET C", size: 1) ,    // 0xD8
            opCode(mnemonic: "EXX", size: 1) ,    // 0xD9
            opCode(mnemonic: "JP C,$nn", size: 3) ,    // 0xDA
            opCode(mnemonic: "IN A,(N)", size: 2) ,    // 0xDB
            opCode(mnemonic: "CALL C,$nn", size: 3) ,    // 0xDC
            opCode(mnemonic: "DDCB prefixes", size: 3) ,    // 0xDD
            opCode(mnemonic: "SBC A,$n", size: 2) ,    // 0xDE
            opCode(mnemonic: "RST 0x18", size: 1) ,    // 0xDF
            opCode(mnemonic: "RET PO", size: 1) ,    // 0xE0
            opCode(mnemonic: "POP HL", size: 1) ,    // 0xE1
            opCode(mnemonic: "JP PO,$nn", size: 3) ,    // 0xE2
            opCode(mnemonic: "EX (SP),HL", size: 1) ,    // 0xE3
            opCode(mnemonic: "CALL PO,$nn", size: 3) ,    // 0xE4
            opCode(mnemonic: "PUSH HL", size: 1) ,    // 0xE5
            opCode(mnemonic: "AND $n", size: 2) ,    // 0xE6
            opCode(mnemonic: "RST 0x20", size: 1) ,    // 0xE7
            opCode(mnemonic: "RET PE", size: 1) ,    // 0xE8
            opCode(mnemonic: "JP (HL)", size: 1) ,    // 0xE9
            opCode(mnemonic: "JP PE,$nn", size: 3) ,    // 0xEA
            opCode(mnemonic: "EX DE,HL", size: 1) ,    // 0xEB
            opCode(mnemonic: "CALL PE,$nn", size: 3) ,    // 0xEC
            opCode(mnemonic: "ED prefixes", size: 3) ,    // 0xED
            opCode(mnemonic: "XOR $n", size: 2) ,    // 0xEE
            opCode(mnemonic: "RST 0x28", size: 1) ,    // 0xEF
            opCode(mnemonic: "RET P", size: 1) ,    // 0xF0
            opCode(mnemonic: "POP AF", size: 1) ,    // 0xF1
            opCode(mnemonic: "JP P,$nn", size: 3) ,    // 0xF2
            opCode(mnemonic: "DI", size: 1) ,    // 0xF3
            opCode(mnemonic: "CALL P,$nn", size: 3) ,    // 0xF4
            opCode(mnemonic: "PUSH AF", size: 1) ,    // 0xF5
            opCode(mnemonic: "OR N", size: 2) ,    // 0xF6
            opCode(mnemonic: "RST 0x30", size: 1) ,    // 0xF7
            opCode(mnemonic: "RET M", size: 1) ,    // 0xF8
            opCode(mnemonic: "LD SP,HL", size: 1) ,    // 0xF9
            opCode(mnemonic: "JP M,$nn", size: 3) ,    // 0xFA
            opCode(mnemonic: "EI", size: 1) ,    // 0xFB
            opCode(mnemonic: "CALL M,$nn", size: 3) ,    // 0xFC
            opCode(mnemonic: "FD anD FDCB prefixes", size: 0),    // 0xFD
            opCode(mnemonic: "CP $n", size: 2) ,    // 0xFE
            opCode(mnemonic: "RST 0x38", size: 1)     // 0xFF
        ]
        
        let CBPrefixOpcode: [opCode] =
        [
            opCode(mnemonic: "RLC B", size: 2),     // 0x00
            opCode(mnemonic: "RLC C", size: 2),     // 0x01
            opCode(mnemonic: "RLC D", size: 2),     // 0x02
            opCode(mnemonic: "RLC E", size: 2),     // 0x03
            opCode(mnemonic: "RLC H", size: 2),     // 0x04
            opCode(mnemonic: "RLC L", size: 2),     // 0x05
            opCode(mnemonic: "RLC (HL)", size: 2),  // 0x06
            opCode(mnemonic: "RLC A", size: 2),     //    0x07
            opCode(mnemonic: "RRC B", size: 2),     //    0x08
            opCode(mnemonic: "RRC C", size: 2),     //    0x09
            opCode(mnemonic: "RRC D", size: 2),     //    0x0A
            opCode(mnemonic: "RRC E", size: 2),     //    0x0B
            opCode(mnemonic: "RRC H", size: 2),     //    0x0C
            opCode(mnemonic: "RRC L", size: 2),     //    0x0D
            opCode(mnemonic: "RRC (HL)", size: 2),  //    0x0E
            opCode(mnemonic: "RRC A", size: 2),     //    0x0F
            opCode(mnemonic: "RL B", size: 2),      //    0x10
            opCode(mnemonic: "RL C", size: 2),      //    0x11
            opCode(mnemonic: "RL D", size: 2),      //    0x12
            opCode(mnemonic: "RL E", size: 2), //    0x13
            opCode(mnemonic: "RL H", size: 2), //    0x14
            opCode(mnemonic: "RL L", size: 2), //    0x15
            opCode(mnemonic: "RL (HL)", size: 2), //    0x16
            opCode(mnemonic: "RL A", size: 2), //    0x17
            opCode(mnemonic: "RR B", size: 2), //    0x18
            opCode(mnemonic: "RR C", size: 2), //    0x19
            opCode(mnemonic: "RR D", size: 2), //    0x1A
            opCode(mnemonic: "RR E", size: 2), //    0x1B
            opCode(mnemonic: "RR H", size: 2), //    0x1C
            opCode(mnemonic: "RR L", size: 2), //    0x1D
            opCode(mnemonic: "RR (HL)", size: 2), //    0x1E
            opCode(mnemonic: "RR A", size: 2), //    0x1F
            opCode(mnemonic: "SLA B", size: 2), //    0x20
            opCode(mnemonic: "SLA C", size: 2), //    0x21
            opCode(mnemonic: "SLA D", size: 2), //    0x22
            opCode(mnemonic: "SLA E", size: 2), //    0x23
            opCode(mnemonic: "SLA H", size: 2), //    0x24
            opCode(mnemonic: "SLA L", size: 2), //    0x25
            opCode(mnemonic: "SLA (HL)", size: 2), //    0x26
            opCode(mnemonic: "SLA A", size: 2), //    0x27
            opCode(mnemonic: "SRA B", size: 2), //    0x28
            opCode(mnemonic: "SRA C", size: 2), //    0x29
            opCode(mnemonic: "SRA D", size: 2), //    0x2A
            opCode(mnemonic: "SRA E", size: 2), //    0x2B
            opCode(mnemonic: "SRA H", size: 2), //    0x2C
            opCode(mnemonic: "SRA L", size: 2), //    0x2D
            opCode(mnemonic: "SRA (HL)", size: 2), //    0x2E
            opCode(mnemonic: "SRA A", size: 2), //    0x2F
            opCode(mnemonic: "SLL B", size: 2), //    0x30
            opCode(mnemonic: "SLL C", size: 2), //    0x31
            opCode(mnemonic: "SLL D", size: 2), //    0x32
            opCode(mnemonic: "SLL E", size: 2), //    0x33
            opCode(mnemonic: "SLL H", size: 2), //    0x34
            opCode(mnemonic: "SLL L", size: 2), //    0x35
            opCode(mnemonic: "SLL (HL)", size: 2), //    0x36
            opCode(mnemonic: "SLL A", size: 2), //    0x37
            opCode(mnemonic: "SRL B", size: 2), //    0x38
            opCode(mnemonic: "SRL C", size: 2), //    0x39
            opCode(mnemonic: "SRL D", size: 2), //    0x3A
            opCode(mnemonic: "SRL E", size: 2), //    0x3B
            opCode(mnemonic: "SRL H", size: 2), //    0x3C
            opCode(mnemonic: "SRL L", size: 2), //    0x3D
            opCode(mnemonic: "SRL (HL)", size: 2), //    0x3E
            opCode(mnemonic: "SRL A", size: 2), //    0x3F
            opCode(mnemonic: "BIT 0,B", size: 2), //    0x40
            opCode(mnemonic: "BIT 0,C", size: 2), //    0x41
            opCode(mnemonic: "BIT 0,D", size: 2), //    0x42
            opCode(mnemonic: "BIT 0,E", size: 2), //    0x43
            opCode(mnemonic: "BIT 0,H", size: 2), //    0x44
            opCode(mnemonic: "BIT 0,L", size: 2), //    0x45
            opCode(mnemonic: "BIT 0,(HL)", size: 2), //    0x46
            opCode(mnemonic: "BIT 0,A", size: 2), //    0x47
            opCode(mnemonic: "BIT 1,B", size: 2), //    0x48
            opCode(mnemonic: "BIT 1,C", size: 2), //    0x49
            opCode(mnemonic: "BIT 1,D", size: 2), //    0x4A
            opCode(mnemonic: "BIT 1,E", size: 2), //    0x4B
            opCode(mnemonic: "BIT 1,H", size: 2), //    0x4C
            opCode(mnemonic: "BIT 1,L", size: 2), //    0x4D
            opCode(mnemonic: "BIT 1,(HL)", size: 2), //    0x4E
            opCode(mnemonic: "BIT 1,A", size: 2), //    0x4F
            opCode(mnemonic: "BIT 2,B", size: 2), //    0x50
            opCode(mnemonic: "BIT 2,C", size: 2), //    0x51
            opCode(mnemonic: "BIT 2,D", size: 2), //    0x52
            opCode(mnemonic: "BIT 2,E", size: 2), //    0x53
            opCode(mnemonic: "BIT 2,H", size: 2), //    0x54
            opCode(mnemonic: "BIT 2,L", size: 2), //    0x55
            opCode(mnemonic: "BIT 2,(HL)", size: 2), //    0x56
            opCode(mnemonic: "BIT 2,A", size: 2), //    0x57
            opCode(mnemonic: "BIT 3,B", size: 2), //    0x58
            opCode(mnemonic: "BIT 3,C", size: 2), //    0x59
            opCode(mnemonic: "BIT 3,D", size: 2), //    0x5A
            opCode(mnemonic: "BIT 3,E", size: 2), //    0x5B
            opCode(mnemonic: "BIT 3,H", size: 2), //    0x5C
            opCode(mnemonic: "BIT 3,L", size: 2), //    0x5D
            opCode(mnemonic: "BIT 3,(HL)", size: 2), //    0x5E
            opCode(mnemonic: "BIT 3,A", size: 2), //    0x5F
            opCode(mnemonic: "BIT 4,B", size: 2), //    0x60
            opCode(mnemonic: "BIT 4,C", size: 2), //    0x61
            opCode(mnemonic: "BIT 4,D", size: 2), //    0x62
            opCode(mnemonic: "BIT 4,E", size: 2), //    0x63
            opCode(mnemonic: "BIT 4,H", size: 2), //    0x64
            opCode(mnemonic: "BIT 4,L", size: 2), //    0x65
            opCode(mnemonic: "BIT 4,(HL)", size: 2), //    0x66
            opCode(mnemonic: "BIT 4,A", size: 2), //    0x67
            opCode(mnemonic: "BIT 5,B", size: 2), //    0x68
            opCode(mnemonic: "BIT 5,C", size: 2), //    0x69
            opCode(mnemonic: "BIT 5,D", size: 2), //    0x6A
            opCode(mnemonic: "BIT 5,E", size: 2), //    0x6B
            opCode(mnemonic: "BIT 5,H", size: 2), //    0x6C
            opCode(mnemonic: "BIT 5,L", size: 2), //    0x6D
            opCode(mnemonic: "BIT 5,(HL)", size: 2), //    0x6E
            opCode(mnemonic: "BIT 5,A", size: 2), //    0x6F
            opCode(mnemonic: "BIT 6,B", size: 2), //    0x70
            opCode(mnemonic: "BIT 6,C", size: 2), //    0x71
            opCode(mnemonic: "BIT 6,D", size: 2), //    0x72
            opCode(mnemonic: "BIT 6,E", size: 2), //    0x73
            opCode(mnemonic: "BIT 6,H", size: 2), //    0x74
            opCode(mnemonic: "BIT 6,L", size: 2), //    0x75
            opCode(mnemonic: "BIT 6,(HL)", size: 2), //    0x76
            opCode(mnemonic: "BIT 6,A", size: 2), //    0x77
            opCode(mnemonic: "BIT 7,B", size: 2), //    0x78
            opCode(mnemonic: "BIT 7,C", size: 2), //    0x79
            opCode(mnemonic: "BIT 7,D", size: 2), //    0x7A
            opCode(mnemonic: "BIT 7,E", size: 2), //    0x7B
            opCode(mnemonic: "BIT 7,H", size: 2), //    0x7C
            opCode(mnemonic: "BIT 7,L", size: 2), //    0x7D
            opCode(mnemonic: "BIT 7,(HL)", size: 2), //    0x7E
            opCode(mnemonic: "BIT 7,A", size: 2), //    0x7F
            opCode(mnemonic: "RES 0,B", size: 2), //    0x80
            opCode(mnemonic: "RES 0,C", size: 2), //    0x81
            opCode(mnemonic: "RES 0,D", size: 2), //    0x82
            opCode(mnemonic: "RES 0,E", size: 2), //    0x83
            opCode(mnemonic: "RES 0,H", size: 2), //    0x84
            opCode(mnemonic: "RES 0,L", size: 2), //    0x85
            opCode(mnemonic: "RES 0,(HL)", size: 2), //    0x86
            opCode(mnemonic: "RES 0,A", size: 2), //    0x87
            opCode(mnemonic: "RES 1,B", size: 2), //    0x88
            opCode(mnemonic: "RES 1,C", size: 2), //    0x89
            opCode(mnemonic: "RES 1,D", size: 2), //    0x8A
            opCode(mnemonic: "RES 1,E", size: 2), //    0x8B
            opCode(mnemonic: "RES 1,H", size: 2), //    0x8C
            opCode(mnemonic: "RES 1,L", size: 2), //    0x8D
            opCode(mnemonic: "RES 1,(HL)", size: 2), //    0x8E
            opCode(mnemonic: "RES 1,A", size: 2), //    0x8F
            opCode(mnemonic: "RES 2,B", size: 2), //    0x90
            opCode(mnemonic: "RES 2,C", size: 2), //    0x91
            opCode(mnemonic: "RES 2,D", size: 2), //    0x92
            opCode(mnemonic: "RES 2,E", size: 2), //    0x93
            opCode(mnemonic: "RES 2,H", size: 2), //    0x94
            opCode(mnemonic: "RES 2,L", size: 2), //    0x95
            opCode(mnemonic: "RES 2,(HL)", size: 2), //    0x96
            opCode(mnemonic: "RES 2,A", size: 2), //    0x97
            opCode(mnemonic: "RES 3,B", size: 2), //    0x98
            opCode(mnemonic: "RES 3,C", size: 2), //    0x99
            opCode(mnemonic: "RES 3,D", size: 2), //    0x9A
            opCode(mnemonic: "RES 3,E", size: 2), //    0x9B
            opCode(mnemonic: "RES 3,H", size: 2), //    0x9C
            opCode(mnemonic: "RES 3,L", size: 2), //    0x9D
            opCode(mnemonic: "RES 3,(HL)", size: 2), //    0x9E
            opCode(mnemonic: "RES 3,A", size: 2), //    0x9F
            opCode(mnemonic: "RES 4,B", size: 2), //    0xA0
            opCode(mnemonic: "RES 4,C", size: 2), //    0xA1
            opCode(mnemonic: "RES 4,D", size: 2), //    0xA2
            opCode(mnemonic: "RES 4,E", size: 2), //    0xA3
            opCode(mnemonic: "RES 4,H", size: 2), //    0xA4
            opCode(mnemonic: "RES 4,L", size: 2), //    0xA5
            opCode(mnemonic: "RES 4,(HL)", size: 2), //    0xA6
            opCode(mnemonic: "RES 4,A", size: 2), //    0xA7
            opCode(mnemonic: "RES 5,B", size: 2), //    0xA8
            opCode(mnemonic: "RES 5,C", size: 2), //    0xA9
            opCode(mnemonic: "RES 5,D", size: 2), //    0xAA
            opCode(mnemonic: "RES 5,E", size: 2), //    0xAB
            opCode(mnemonic: "RES 5,H", size: 2), //    0xAC
            opCode(mnemonic: "RES 5,L", size: 2), //    0xAD
            opCode(mnemonic: "RES 5,(HL)", size: 2), //    0xAE
            opCode(mnemonic: "RES 5,A", size: 2), //    0xAF
            opCode(mnemonic: "RES 6,B", size: 2), //    0xB0
            opCode(mnemonic: "RES 6,C", size: 2), //    0xB1
            opCode(mnemonic: "RES 6,D", size: 2), //    0xB2
            opCode(mnemonic: "RES 6,E", size: 2), //    0xB3
            opCode(mnemonic: "RES 6,H", size: 2), //    0xB4
            opCode(mnemonic: "RES 6,L", size: 2), //    0xB5
            opCode(mnemonic: "RES 6,(HL)", size: 2), //    0xB6
            opCode(mnemonic: "RES 6,A", size: 2), //    0xB7
            opCode(mnemonic: "RES 7,B", size: 2), //    0xB8
            opCode(mnemonic: "RES 7,C", size: 2), //    0xB9
            opCode(mnemonic: "RES 7,D", size: 2), //    0xBA
            opCode(mnemonic: "RES 7,E", size: 2), //    0xBB
            opCode(mnemonic: "RES 7,H", size: 2), //    0xBC
            opCode(mnemonic: "RES 7,L", size: 2), //    0xBD
            opCode(mnemonic: "RES 7,(HL)", size: 2), //    0xBE
            opCode(mnemonic: "RES 7,A", size: 2), //    0xBF
            opCode(mnemonic: "SET 0,B", size: 2), //    0xC0
            opCode(mnemonic: "SET 0,C", size: 2), //    0xC1
            opCode(mnemonic: "SET 0,D", size: 2), //    0xC2
            opCode(mnemonic: "SET 0,E", size: 2), //    0xC3
            opCode(mnemonic: "SET 0,H", size: 2), //    0xC4
            opCode(mnemonic: "SET 0,L", size: 2), //    0xC5
            opCode(mnemonic: "SET 0,(HL)", size: 2), //    0xC6
            opCode(mnemonic: "SET 0,A", size: 2), //    0xC7
            opCode(mnemonic: "SET 1,B", size: 2), //    0xC8
            opCode(mnemonic: "SET 1,C", size: 2), //    0xC9
            opCode(mnemonic: "SET 1,D", size: 2), //    0xCA
            opCode(mnemonic: "SET 1,E", size: 2), //    0xCB
            opCode(mnemonic: "SET 1,H", size: 2), //    0xCC
            opCode(mnemonic: "SET 1,L", size: 2), //    0xCD
            opCode(mnemonic: "SET 1,(HL)", size: 2), //    0xCE
            opCode(mnemonic: "SET 1,A", size: 2), //    0xCF
            opCode(mnemonic: "SET 2,B", size: 2), //    0xD0
            opCode(mnemonic: "SET 2,C", size: 2), //    0xD1
            opCode(mnemonic: "SET 2,D", size: 2), //    0xD2
            opCode(mnemonic: "SET 2,E", size: 2), //    0xD3
            opCode(mnemonic: "SET 2,H", size: 2), //    0xD4
            opCode(mnemonic: "SET 2,L", size: 2), //    0xD5
            opCode(mnemonic: "SET 2,(HL)", size: 2), //    0xD6
            opCode(mnemonic: "SET 2,A", size: 2), //    0xD7
            opCode(mnemonic: "SET 3,B", size: 2), //    0xD8
            opCode(mnemonic: "SET 3,C", size: 2), //    0xD9
            opCode(mnemonic: "SET 3,D", size: 2), //    0xDA
            opCode(mnemonic: "SET 3,E", size: 2), //    0xDB
            opCode(mnemonic: "SET 3,H", size: 2), //    0xDC
            opCode(mnemonic: "SET 3,L", size: 2), //    0xDD
            opCode(mnemonic: "SET 3,(HL)", size: 2), //    0xDE
            opCode(mnemonic: "SET 3,A", size: 2), //    0xDF
            opCode(mnemonic: "SET 4,B", size: 2), //    0xE0
            opCode(mnemonic: "SET 4,C", size: 2), //    0xE1
            opCode(mnemonic: "SET 4,D", size: 2), //    0xE2
            opCode(mnemonic: "SET 4,E", size: 2), //    0xE3
            opCode(mnemonic: "SET 4,H", size: 2), //    0xE4
            opCode(mnemonic: "SET 4,L", size: 2), //    0xE5
            opCode(mnemonic: "SET 4,(HL)", size: 2), //    0xE6
            opCode(mnemonic: "SET 4,A", size: 2), //    0xE7
            opCode(mnemonic: "SET 5,B", size: 2), //    0xE8
            opCode(mnemonic: "SET 5,C", size: 2), //    0xE9
            opCode(mnemonic: "SET 5,D", size: 2), //    0xEA
            opCode(mnemonic: "SET 5,E", size: 2), //    0xEB
            opCode(mnemonic: "SET 5,H", size: 2), //    0xEC
            opCode(mnemonic: "SET 5,L", size: 2), //    0xED
            opCode(mnemonic: "SET 5,(HL)", size: 2), //    0xEE
            opCode(mnemonic: "SET 5,A", size: 2), //    0xEF
            opCode(mnemonic: "SET 6,B", size: 2), //    0xF0
            opCode(mnemonic: "SET 6,C", size: 2), //    0xF1
            opCode(mnemonic: "SET 6,D", size: 2), //    0xF2
            opCode(mnemonic: "SET 6,E", size: 2), //    0xF3
            opCode(mnemonic: "SET 6,H", size: 2), //    0xF4
            opCode(mnemonic: "SET 6,L", size: 2), //    0xF5
            opCode(mnemonic: "SET 6,(HL)", size: 2), //    0xF6
            opCode(mnemonic: "SET 6,A", size: 2), //    0xF7
            opCode(mnemonic: "SET 7,B", size: 2), //    0xF8
            opCode(mnemonic: "SET 7,C", size: 2), //    0xF9
            opCode(mnemonic: "SET 7,D", size: 2), //    0xFA
            opCode(mnemonic: "SET 7,E", size: 2), //    0xFB
            opCode(mnemonic: "SET 7,H", size: 2), //    0xFC
            opCode(mnemonic: "SET 7,L", size: 2), //    0xFD
            opCode(mnemonic: "SET 7,(HL)", size: 2), //    0xFE
            opCode(mnemonic: "SET 7,A", size: 2) //    0xFF
        ]
        
        let DDPrefixOpcode: [opCode] =
        [
            opCode(mnemonic: "NOP", size: 2),    //  0x00
            opCode(mnemonic: "LD BC,$nn", size: 2),    //  0x01
            opCode(mnemonic: "LD (BC),A", size: 2),    //  0x02
            opCode(mnemonic: "INC BC", size: 2),    //  0x03
            opCode(mnemonic: "INC B", size: 2),    //  0x04
            opCode(mnemonic: "DEC B", size: 2),    //  0x05
            opCode(mnemonic: "LD B,$n", size: 2),    //  0x06
            opCode(mnemonic: "RLCA", size: 2),    //  0x07
            opCode(mnemonic: "EX AF,AF'", size: 2),    //  0x08
            opCode(mnemonic: "ADD IX,BC", size: 2),    //  0x09
            opCode(mnemonic: "LD A,(BC)", size: 2),    //  0x0A
            opCode(mnemonic: "DEC BC", size: 2),    //  0x0B
            opCode(mnemonic: "INC C", size: 2),    //  0x0C
            opCode(mnemonic: "DEC C", size: 2),    //  0x0D
            opCode(mnemonic: "LD C,$n", size: 2),    //  0x0E
            opCode(mnemonic: "RRCA", size: 2),    //  0x0F
            opCode(mnemonic: "DJNZ $d", size: 2),    //  0x10
            opCode(mnemonic: "LD DE,$nn", size: 2),    //  0x11
            opCode(mnemonic: "LD (DE),A", size: 2),    //  0x12
            opCode(mnemonic: "INC DE", size: 2),    //  0x13
            opCode(mnemonic: "INC D", size: 2),    //  0x14
            opCode(mnemonic: "DEC D", size: 2),    //  0x15
            opCode(mnemonic: "LD D,$n", size: 2),    //  0x16
            opCode(mnemonic: "RLA", size: 2),    //  0x17
            opCode(mnemonic: "JR $d", size: 2),    //  0x18
            opCode(mnemonic: "ADD IX,DE", size: 2),    //  0x19
            opCode(mnemonic: "LD A,(DE)", size: 2),    //  0x1A
            opCode(mnemonic: "DEC DE", size: 2),    //  0x1B
            opCode(mnemonic: "INC E", size: 2),    //  0x1C
            opCode(mnemonic: "DEC E", size: 2),    //  0x1D
            opCode(mnemonic: "LD E,$n", size: 2),    //  0x1E
            opCode(mnemonic: "RRA", size: 2),    //  0x1F
            opCode(mnemonic: "JR NZ,$d", size: 2),    //  0x20
            opCode(mnemonic: "LD IX,$nn", size: 2),    //  0x21
            opCode(mnemonic: "LD ($nn),IX", size: 2),    //  0x22
            opCode(mnemonic: "INC IX", size: 2),    //  0x23
            opCode(mnemonic: "INC IXH", size: 2),    //  0x24
            opCode(mnemonic: "DEC IXH", size: 2),    //  0x25
            opCode(mnemonic: "LD IHX,$n", size: 2),    //  0x26
            opCode(mnemonic: "DAA", size: 2),    //  0x27
            opCode(mnemonic: "JR Z,$d", size: 2),    //  0x28
            opCode(mnemonic: "ADD IX,IX", size: 2),    //  0x29
            opCode(mnemonic: "LD IX,($nn)", size: 2),    //  0x2A
            opCode(mnemonic: "DEC IX", size: 2),    //  0x2B
            opCode(mnemonic: "INC IXL", size: 2),    //  0x2C
            opCode(mnemonic: "DEC IXL", size: 2),    //  0x2D
            opCode(mnemonic: "LD IXL,$n", size: 2),    //  0x2E
            opCode(mnemonic: "CPL", size: 2),    //  0x2F
            opCode(mnemonic: "JR NC,$d", size: 2),    //  0x30
            opCode(mnemonic: "LD SP,$nn", size: 2),    //  0x31
            opCode(mnemonic: "LD ($nn),A", size: 2),    //  0x32
            opCode(mnemonic: "INC SP", size: 2),    //  0x33
            opCode(mnemonic: "INC (IX+$d)", size: 2),    //  0x34
            opCode(mnemonic: "DEC (IX+$d)", size: 2),    //  0x35
            opCode(mnemonic: "LD (IX+$d),$n", size: 2),    //  0x36
            opCode(mnemonic: "SCF", size: 2),    //  0x37
            opCode(mnemonic: "JR C,$d", size: 2),    //  0x38
            opCode(mnemonic: "ADD IX,SP", size: 2),    //  0x39
            opCode(mnemonic: "LD A,($nn)", size: 2),    //  0x3A
            opCode(mnemonic: "DEC SP", size: 2),    //  0x3B
            opCode(mnemonic: "INC A", size: 2),    //  0x3C
            opCode(mnemonic: "DEC A", size: 2),    //  0x3D
            opCode(mnemonic: "LD A,$n", size: 2),    //  0x3E
            opCode(mnemonic: "CCF", size: 2),    //  0x3F
            opCode(mnemonic: "LD B,B", size: 2),    //  0x40
            opCode(mnemonic: "LD B,C", size: 2),    //  0x41
            opCode(mnemonic: "LD B,D", size: 2),    //  0x42
            opCode(mnemonic: "LD B,E", size: 2),    //  0x43
            opCode(mnemonic: "LD B,IXH", size: 2),    //  0x44
            opCode(mnemonic: "LD B,IXL", size: 2),    //  0x45
            opCode(mnemonic: "LD B,(IX+$d)", size: 2),    //  0x46
            opCode(mnemonic: "LD B,A", size: 2),    //  0x47
            opCode(mnemonic: "LD C,B", size: 2),    //  0x48
            opCode(mnemonic: "LD C,C", size: 2),    //  0x49
            opCode(mnemonic: "LD C,D", size: 2),    //  0x4A
            opCode(mnemonic: "LD C,E", size: 2),    //  0x4B
            opCode(mnemonic: "LD C,IXH", size: 2),    //  0x4C
            opCode(mnemonic: "LD C,IXL", size: 2),    //  0x4D
            opCode(mnemonic: "LD C,(IX+$d)", size: 2),    //  0x4E
            opCode(mnemonic: "LD C,A", size: 2),    //  0x4F
            opCode(mnemonic: "LD D,B", size: 2),    //  0x50
            opCode(mnemonic: "LD D,C", size: 2),    //  0x51
            opCode(mnemonic: "LD D,D", size: 2),    //  0x52
            opCode(mnemonic: "LD D,E", size: 2),    //  0x53
            opCode(mnemonic: "LD D,IXH", size: 2),    //  0x54
            opCode(mnemonic: "LD D,IXL", size: 2),    //  0x55
            opCode(mnemonic: "LD D,(IX+$d)", size: 2),    //  0x56
            opCode(mnemonic: "LD D,A", size: 2),    //  0x57
            opCode(mnemonic: "LD E,B", size: 2),    //  0x58
            opCode(mnemonic: "LD E,C", size: 2),    //  0x59
            opCode(mnemonic: "LD E,D", size: 2),    //  0x5A
            opCode(mnemonic: "LD E,E", size: 2),    //  0x5B
            opCode(mnemonic: "LD E,IXH", size: 2),    //  0x5C
            opCode(mnemonic: "LD E,IXL", size: 2),    //  0x5D
            opCode(mnemonic: "LD E,(IX+$d)", size: 2),    //  0x5E
            opCode(mnemonic: "LD E,A", size: 2),    //  0x5F
            opCode(mnemonic: "LD IXH,B", size: 2),    //  0x60
            opCode(mnemonic: "LD IXH,C", size: 2),    //  0x61
            opCode(mnemonic: "LD IXH,D", size: 2),    //  0x62
            opCode(mnemonic: "LD IXH,E", size: 2),    //  0x63
            opCode(mnemonic: "LD IXH,IXH", size: 2),    //  0x64
            opCode(mnemonic: "LD IXH,IXL", size: 2),    //  0x65
            opCode(mnemonic: "LD H,(IX+$d)", size: 2),    //  0x66
            opCode(mnemonic: "LD IXH,A", size: 2),    //  0x67
            opCode(mnemonic: "LD IXL,B", size: 2),    //  0x68
            opCode(mnemonic: "LD IXL,C", size: 2),    //  0x69
            opCode(mnemonic: "LD IXL,D", size: 2),    //  0x6A
            opCode(mnemonic: "LD IXL,E", size: 2),    //  0x6B
            opCode(mnemonic: "LD IXL,IXH", size: 2),    //  0x6C
            opCode(mnemonic: "LD IXL,IXL", size: 2),    //  0x6D
            opCode(mnemonic: "LD L,(IX+$d)", size: 2),    //  0x6E
            opCode(mnemonic: "LD IXL,A", size: 2),    //  0x6F
            opCode(mnemonic: "LD (IX+$d),B", size: 2),    //  0x70
            opCode(mnemonic: "LD (IX+$d),C", size: 2),    //  0x71
            opCode(mnemonic: "LD (IX+$d),D", size: 2),    //  0x72
            opCode(mnemonic: "LD (IX+$d),E", size: 2),    //  0x73
            opCode(mnemonic: "LD (IX+$d),H", size: 2),    //  0x74
            opCode(mnemonic: "LD (IX+$d),L", size: 2),    //  0x75
            opCode(mnemonic: "HALT", size: 2),    //  0x76
            opCode(mnemonic: "LD (IX+$d),A", size: 2),    //  0x77
            opCode(mnemonic: "LD A,B", size: 2),    //  0x78
            opCode(mnemonic: "LD A,C", size: 2),    //  0x79
            opCode(mnemonic: "LD A,D", size: 2),    //  0x7A
            opCode(mnemonic: "LD A,E", size: 2),    //  0x7B
            opCode(mnemonic: "LD A,IXH", size: 2),    //  0x7C
            opCode(mnemonic: "LD A,IXL", size: 2),    //  0x7D
            opCode(mnemonic: "LD A,(IX+$d)", size: 2),    //  0x7E
            opCode(mnemonic: "LD A,A", size: 2),    //  0x7F
            opCode(mnemonic: "ADD A,B", size: 2),    //  0x80
            opCode(mnemonic: "ADD A,C", size: 2),    //  0x81
            opCode(mnemonic: "ADD A,D", size: 2),    //  0x82
            opCode(mnemonic: "ADD A,E", size: 2),    //  0x83
            opCode(mnemonic: "ADD A,IXH", size: 2),    //  0x84
            opCode(mnemonic: "ADD A,IXL", size: 2),    //  0x85
            opCode(mnemonic: "ADD A,(IX+$d)", size: 2),    //  0x86
            opCode(mnemonic: "ADD A,A", size: 2),    //  0x87
            opCode(mnemonic: "ADC A,B", size: 2),    //  0x88
            opCode(mnemonic: "ADC A,C", size: 2),    //  0x89
            opCode(mnemonic: "ADC A,D", size: 2),    //  0x8A
            opCode(mnemonic: "ADC A,E", size: 2),    //  0x8B
            opCode(mnemonic: "ADC A,IXH", size: 2),    //  0x8C
            opCode(mnemonic: "ADC A,IXL", size: 2),    //  0x8D
            opCode(mnemonic: "ADC A,(IX+$d)", size: 2),    //  0x8E
            opCode(mnemonic: "ADC A,A", size: 2),    //  0x8F
            opCode(mnemonic: "SUB B", size: 2),    //  0x90
            opCode(mnemonic: "SUB C", size: 2),    //  0x91
            opCode(mnemonic: "SUB D", size: 2),    //  0x92
            opCode(mnemonic: "SUB E", size: 2),    //  0x93
            opCode(mnemonic: "SUB IXH", size: 2),    //  0x94
            opCode(mnemonic: "SUB IXL", size: 2),    //  0x95
            opCode(mnemonic: "SUB (IX+$d)", size: 2),    //  0x96
            opCode(mnemonic: "SUB A", size: 2),    //  0x97
            opCode(mnemonic: "SBC A,B", size: 2),    //  0x98
            opCode(mnemonic: "SBC A,C", size: 2),    //  0x99
            opCode(mnemonic: "SBC A,D", size: 2),    //  0x9A
            opCode(mnemonic: "SBC A,E", size: 2),    //  0x9B
            opCode(mnemonic: "SBC A,IXH", size: 2),    //  0x9C
            opCode(mnemonic: "SBC A,IXL", size: 2),    //  0x9D
            opCode(mnemonic: "SBC A,(IX+$d)", size: 2),    //  0x9E
            opCode(mnemonic: "SBC A,A", size: 2),    //  0x9F
            opCode(mnemonic: "AND B", size: 2),    //  0xA0
            opCode(mnemonic: "AND C", size: 2),    //  0xA1
            opCode(mnemonic: "AND D", size: 2),    //  0xA2
            opCode(mnemonic: "AND E", size: 2),    //  0xA3
            opCode(mnemonic: "AND IXH", size: 2),    //  0xA4
            opCode(mnemonic: "AND IXL", size: 2),    //  0xA5
            opCode(mnemonic: "AND (IX+$d)", size: 2),    //  0xA6
            opCode(mnemonic: "AND A", size: 2),    //  0xA7
            opCode(mnemonic: "XOR B", size: 2),    //  0xA8
            opCode(mnemonic: "XOR C", size: 2),    //  0xA9
            opCode(mnemonic: "XOR D", size: 2),    //  0xAA
            opCode(mnemonic: "XOR E", size: 2),    //  0xAB
            opCode(mnemonic: "XOR IXH", size: 2),    //  0xAC
            opCode(mnemonic: "XOR IXL", size: 2),    //  0xAD
            opCode(mnemonic: "XOR (IX+$d)", size: 2),    //  0xAE
            opCode(mnemonic: "XOR A", size: 2),    //  0xAF
            opCode(mnemonic: "OR B", size: 2),    //  0xB0
            opCode(mnemonic: "OR C", size: 2),    //  0xB1
            opCode(mnemonic: "OR D", size: 2),    //  0xB2
            opCode(mnemonic: "OR E", size: 2),    //  0xB3
            opCode(mnemonic: "OR IXH", size: 2),    //  0xB4
            opCode(mnemonic: "OR IXL", size: 2),    //  0xB5
            opCode(mnemonic: "OR (IX+$d)", size: 2),    //  0xB6
            opCode(mnemonic: "OR A", size: 2),    //  0xB7
            opCode(mnemonic: "CP B", size: 2),    //  0xB8
            opCode(mnemonic: "CP C", size: 2),    //  0xB9
            opCode(mnemonic: "CP D", size: 2),    //  0xBA
            opCode(mnemonic: "CP E", size: 2),    //  0xBB
            opCode(mnemonic: "CP IXH", size: 2),    //  0xBC
            opCode(mnemonic: "CP IXL", size: 2),    //  0xBD
            opCode(mnemonic: "CP (IX+$d)", size: 2),    //  0xBE
            opCode(mnemonic: "CP A", size: 2),    //  0xBF
            opCode(mnemonic: "RET NZ", size: 2),    //  0xC0
            opCode(mnemonic: "POP BC", size: 2),    //  0xC1
            opCode(mnemonic: "JP NZ,$nn", size: 2),    //  0xC2
            opCode(mnemonic: "JP $nn", size: 2),    //  0xC3
            opCode(mnemonic: "CALL NZ,$nn", size: 2),    //  0xC4
            opCode(mnemonic: "PUSH BC", size: 2),    //  0xC5
            opCode(mnemonic: "ADD A,$n", size: 2),    //  0xC6
            opCode(mnemonic: "RST 0x00", size: 2),    //  0xC7
            opCode(mnemonic: "RET Z", size: 2),    //  0xC8
            opCode(mnemonic: "RET", size: 2),    //  0xC9
            opCode(mnemonic: "JP Z,$nn", size: 2),    //  0xCA
            opCode(mnemonic: "CB prefixes", size: 2),    //  0xCB
            opCode(mnemonic: "CALL Z,$nn", size: 2),    //  0xCC
            opCode(mnemonic: "CALL $nn", size: 2),    //  0xCD
            opCode(mnemonic: "ADC A,$n", size: 2),    //  0xCE
            opCode(mnemonic: "RST 0x08", size: 2),    //  0xCF
            opCode(mnemonic: "RET NC", size: 2),    //  0xD0
            opCode(mnemonic: "POP DE", size: 2),    //  0xD1
            opCode(mnemonic: "JP NC,$nn", size: 2),    //  0xD2
            opCode(mnemonic: "OUT ($n),A", size: 2),    //  0xD3
            opCode(mnemonic: "CALL NC,$nn", size: 2),    //  0xD4
            opCode(mnemonic: "PUSH DE", size: 2),    //  0xD5
            opCode(mnemonic: "SUB $n", size: 2),    //  0xD6
            opCode(mnemonic: "RST 0x10", size: 2),    //  0xD7
            opCode(mnemonic: "RET C", size: 2),    //  0xD8
            opCode(mnemonic: "EXX", size: 2),    //  0xD9
            opCode(mnemonic: "JP C,$nn", size: 2),    //  0xDA
            opCode(mnemonic: "IN A,(N)", size: 2),    //  0xDB
            opCode(mnemonic: "CALL C,$nn", size: 2),    //  0xDC
            opCode(mnemonic: "DD/DDCB prefixes", size: 2),    //  0xDD
            opCode(mnemonic: "SBC A,$n", size: 2),    //  0xDE
            opCode(mnemonic: "RST 0x18", size: 2),    //  0xDF
            opCode(mnemonic: "RET PO", size: 2),    //  0xE0
            opCode(mnemonic: "POP IX", size: 2),    //  0xE1
            opCode(mnemonic: "JP PO,$nn", size: 2),    //  0xE2
            opCode(mnemonic: "EX (SP),IX", size: 2),    //  0xE3
            opCode(mnemonic: "CALL PO,$nn", size: 2),    //  0xE4
            opCode(mnemonic: "PUSH IX", size: 2),    //  0xE5
            opCode(mnemonic: "AND $n", size: 2),    //  0xE6
            opCode(mnemonic: "RST 0x20", size: 2),    //  0xE7
            opCode(mnemonic: "RET PE", size: 2),    //  0xE8
            opCode(mnemonic: "JP (IX)", size: 2),    //  0xE9
            opCode(mnemonic: "JP PE,$nn", size: 2),    //  0xEA
            opCode(mnemonic: "EX DE,HL", size: 2),    //  0xEB
            opCode(mnemonic: "CALL PE,$nn", size: 2),    //  0xEC
            opCode(mnemonic: "ED prefixes", size: 2),    //  0xED
            opCode(mnemonic: "XOR $n", size: 2),    //  0xEE
            opCode(mnemonic: "RST 0x28", size: 2),    //  0xEF
            opCode(mnemonic: "RET P", size: 2),    //  0xF0
            opCode(mnemonic: "POP AF", size: 2),    //  0xF1
            opCode(mnemonic: "JP P,$nn", size: 2),    //  0xF2
            opCode(mnemonic: "DI", size: 2),    //  0xF3
            opCode(mnemonic: "CALL P,$nn", size: 2),    //  0xF4
            opCode(mnemonic: "PUSH AF", size: 2),    //  0xF5
            opCode(mnemonic: "OR N", size: 2),    //  0xF6
            opCode(mnemonic: "RST 0x30", size: 2),    //  0xF7
            opCode(mnemonic: "RET M", size: 2),    //  0xF8
            opCode(mnemonic: "LD SP,IX", size: 2),    //  0xF9
            opCode(mnemonic: "JP M,$nn", size: 2),    //  0xFA
            opCode(mnemonic: "EI", size: 2),    //  0xFB
            opCode(mnemonic: "CALL M,$nn", size: 2),    //  0xFC
            opCode(mnemonic: "FD/FDCB prefixes", size: 2),    //  0xFD
            opCode(mnemonic: "CP $n", size: 2),    //  0xFE
            opCode(mnemonic: "RST 0x38", size: 2)    //  0xFF
        ]
        
        let EDPrefixOpcode: [opCode] =
        [
            opCode(mnemonic: "DB ED,00", size: 2),    //  0x00
            opCode(mnemonic: "DB ED,01", size: 2),    //  0x01
            opCode(mnemonic: "DB ED,02", size: 2),    //  0x02
            opCode(mnemonic: "DB ED,03", size: 2),    //  0x03
            opCode(mnemonic: "DB ED,04", size: 2),    //  0x04
            opCode(mnemonic: "DB ED,05", size: 2),    //  0x05
            opCode(mnemonic: "DB ED,06", size: 2),    //  0x06
            opCode(mnemonic: "DB ED,07", size: 2),    //  0x07
            opCode(mnemonic: "DB ED,08", size: 2),    //  0x08
            opCode(mnemonic: "DB ED,09", size: 2),    //  0x09
            opCode(mnemonic: "DB ED,0A", size: 2),    //  0x0A
            opCode(mnemonic: "DB ED,0B", size: 2),    //  0x0B
            opCode(mnemonic: "DB ED,0C", size: 2),    //  0x0C
            opCode(mnemonic: "DB ED,0D", size: 2),    //  0x0D
            opCode(mnemonic: "DB ED,0E", size: 2),    //  0x0E
            opCode(mnemonic: "DB ED,0F", size: 2),    //  0x0F
            opCode(mnemonic: "DB ED,10", size: 2),    //  0x10
            opCode(mnemonic: "DB ED,11", size: 2),    //  0x11
            opCode(mnemonic: "DB ED,12", size: 2),    //  0x12
            opCode(mnemonic: "DB ED,13", size: 2),    //  0x13
            opCode(mnemonic: "DB ED,14", size: 2),    //  0x14
            opCode(mnemonic: "DB ED,15", size: 2),    //  0x15
            opCode(mnemonic: "DB ED,16", size: 2),    //  0x16
            opCode(mnemonic: "DB ED,17", size: 2),    //  0x17
            opCode(mnemonic: "DB ED,18", size: 2),    //  0x18
            opCode(mnemonic: "DB ED,19", size: 2),    //  0x19
            opCode(mnemonic: "DB ED,1A", size: 2),    //  0x1A
            opCode(mnemonic: "DB ED,1B", size: 2),    //  0x1B
            opCode(mnemonic: "DB ED,1C", size: 2),    //  0x1C
            opCode(mnemonic: "DB ED,1D", size: 2),    //  0x1D
            opCode(mnemonic: "DB ED,1E", size: 2),    //  0x1E
            opCode(mnemonic: "DB ED,1F", size: 2),    //  0x1F
            opCode(mnemonic: "DB ED,20", size: 2),    //  0x20
            opCode(mnemonic: "DB ED,21", size: 2),    //  0x21
            opCode(mnemonic: "DB ED,22", size: 2),    //  0x22
            opCode(mnemonic: "DB ED,23", size: 2),    //  0x23
            opCode(mnemonic: "DB ED,24", size: 2),    //  0x24
            opCode(mnemonic: "DB ED,25", size: 2),    //  0x25
            opCode(mnemonic: "DB ED,26", size: 2),    //  0x26
            opCode(mnemonic: "DB ED,27", size: 2),    //  0x27
            opCode(mnemonic: "DB ED,28", size: 2),    //  0x28
            opCode(mnemonic: "DB ED,29", size: 2),    //  0x29
            opCode(mnemonic: "DB ED,2A", size: 2),    //  0x2A
            opCode(mnemonic: "DB ED,2B", size: 2),    //  0x2B
            opCode(mnemonic: "DB ED,2C", size: 2),    //  0x2C
            opCode(mnemonic: "DB ED,2D", size: 2),    //  0x2D
            opCode(mnemonic: "DB ED,2E", size: 2),    //  0x2E
            opCode(mnemonic: "DB ED,2F", size: 2),    //  0x2F
            opCode(mnemonic: "DB ED,30", size: 2),    //  0x30
            opCode(mnemonic: "DB ED,31", size: 2),    //  0x31
            opCode(mnemonic: "DB ED,32", size: 2),    //  0x32
            opCode(mnemonic: "DB ED,33", size: 2),    //  0x33
            opCode(mnemonic: "DB ED,34", size: 2),    //  0x34
            opCode(mnemonic: "DB ED,35", size: 2),    //  0x35
            opCode(mnemonic: "DB ED,36", size: 2),    //  0x36
            opCode(mnemonic: "DB ED,37", size: 2),    //  0x37
            opCode(mnemonic: "DB ED,38", size: 2),    //  0x38
            opCode(mnemonic: "DB ED,39", size: 2),    //  0x39
            opCode(mnemonic: "DB ED,3A", size: 2),    //  0x3A
            opCode(mnemonic: "DB ED,3B", size: 2),    //  0x3B
            opCode(mnemonic: "DB ED,3C", size: 2),    //  0x3C
            opCode(mnemonic: "DB ED,3D", size: 2),    //  0x3D
            opCode(mnemonic: "DB ED,3E", size: 2),    //  0x3E
            opCode(mnemonic: "DB ED,3F", size: 2),    //  0x3F
            opCode(mnemonic: "IN B,(C)", size: 2),    //  0x40
            opCode(mnemonic: "OUT (C),B", size: 2),    //  0x41
            opCode(mnemonic: "SBC HL,BC", size: 2),    //  0x42
            opCode(mnemonic: "LD ($nn),BC", size: 2),    //  0x43
            opCode(mnemonic: "NEG", size: 2),    //  0x44
            opCode(mnemonic: "RETN", size: 2),    //  0x45
            opCode(mnemonic: "IM 0", size: 2),    //  0x46
            opCode(mnemonic: "LD I,A", size: 2),    //  0x47
            opCode(mnemonic: "IN C,(C)", size: 2),    //  0x48
            opCode(mnemonic: "OUT (C),C", size: 2),    //  0x49
            opCode(mnemonic: "ADC HL,BC", size: 2),    //  0x4A
            opCode(mnemonic: "LD BC,($nn)", size: 2),    //  0x4B
            opCode(mnemonic: "DB ED,4C", size: 2),    //  0x4C
            opCode(mnemonic: "RETI", size: 2),    //  0x4D
            opCode(mnemonic: "DB ED,4E", size: 2),    //  0x4E
            opCode(mnemonic: "LD R,A", size: 2),    //  0x4F
            opCode(mnemonic: "IN D,(C)", size: 2),    //  0x50
            opCode(mnemonic: "OUT (C),D", size: 2),    //  0x51
            opCode(mnemonic: "SBC HL,DE", size: 2),    //  0x52
            opCode(mnemonic: "LD ($nn),DE", size: 2),    //  0x53
            opCode(mnemonic: "DB ED,54", size: 2),    //  0x54
            opCode(mnemonic: "DB ED,55", size: 2),    //  0x55
            opCode(mnemonic: "IM 1", size: 2),    //  0x56
            opCode(mnemonic: "LD A,I", size: 2),    //  0x57
            opCode(mnemonic: "IN E,(C)", size: 2),    //  0x58
            opCode(mnemonic: "OUT (C),E", size: 2),    //  0x59
            opCode(mnemonic: "ADC HL,DE", size: 2),    //  0x5A
            opCode(mnemonic: "LD DE,($nn)", size: 2),    //  0x5B
            opCode(mnemonic: "DB ED,5C", size: 2),    //  0x5C
            opCode(mnemonic: "DB ED,5D", size: 2),    //  0x5D
            opCode(mnemonic: "IM 2", size: 2),    //  0x5E
            opCode(mnemonic: "LD A,R", size: 2),    //  0x5F
            opCode(mnemonic: "IN H,(C)", size: 2),    //  0x60
            opCode(mnemonic: "OUT (C),H", size: 2),    //  0x61
            opCode(mnemonic: "SBC HL,HL", size: 2),    //  0x62
            opCode(mnemonic: "LD ($nn),HL", size: 2),    //  0x63
            opCode(mnemonic: "DB ED,64", size: 2),    //  0x64
            opCode(mnemonic: "DB ED,65", size: 2),    //  0x65
            opCode(mnemonic: "DB ED,66", size: 2),    //  0x66
            opCode(mnemonic: "RRD", size: 2),    //  0x67
            opCode(mnemonic: "IN L,(C)", size: 2),    //  0x68
            opCode(mnemonic: "OUT (C),L", size: 2),    //  0x69
            opCode(mnemonic: "ADC HL,HL", size: 2),    //  0x6A
            opCode(mnemonic: "LD HL,($nn)", size: 2),    //  0x6B
            opCode(mnemonic: "DB ED,6C", size: 2),    //  0x6C
            opCode(mnemonic: "DB ED,6D", size: 2),    //  0x6D
            opCode(mnemonic: "DB ED,6E", size: 2),    //  0x6E
            opCode(mnemonic: "RLD", size: 2),    //  0x6F
            opCode(mnemonic: "IN (C)", size: 2),    //  0x70
            opCode(mnemonic: "OUT (C),0", size: 2),    //  0x71
            opCode(mnemonic: "SBC HL,SP", size: 2),    //  0x72
            opCode(mnemonic: "LD ($nn),SP", size: 2),    //  0x73
            opCode(mnemonic: "DB ED,74", size: 2),    //  0x74
            opCode(mnemonic: "DB ED,75", size: 2),    //  0x75
            opCode(mnemonic: "DB ED,76", size: 2),    //  0x76
            opCode(mnemonic: "DB ED,77", size: 2),    //  0x77
            opCode(mnemonic: "IN A,(C)", size: 2),    //  0x78
            opCode(mnemonic: "OUT (C),A", size: 2),    //  0x79
            opCode(mnemonic: "ADC HL,SP", size: 2),    //  0x7A
            opCode(mnemonic: "LD SP,($nn)", size: 2),    //  0x7B
            opCode(mnemonic: "DB ED,7C", size: 2),    //  0x7C
            opCode(mnemonic: "DB ED,7D", size: 2),    //  0x7D
            opCode(mnemonic: "DB ED,7E", size: 2),    //  0x7E
            opCode(mnemonic: "DB ED,7F", size: 2),    //  0x7F
            opCode(mnemonic: "DB ED,80", size: 2),    //  0x80
            opCode(mnemonic: "DB ED,81", size: 2),    //  0x81
            opCode(mnemonic: "DB ED,82", size: 2),    //  0x82
            opCode(mnemonic: "DB ED,83", size: 2),    //  0x83
            opCode(mnemonic: "DB ED,84", size: 2),    //  0x84
            opCode(mnemonic: "DB ED,85", size: 2),    //  0x85
            opCode(mnemonic: "DB ED,86", size: 2),    //  0x86
            opCode(mnemonic: "DB ED,87", size: 2),    //  0x87
            opCode(mnemonic: "DB ED,88", size: 2),    //  0x88
            opCode(mnemonic: "DB ED,89", size: 2),    //  0x89
            opCode(mnemonic: "DB ED,8A", size: 2),    //  0x8A
            opCode(mnemonic: "DB ED,8B", size: 2),    //  0x8B
            opCode(mnemonic: "DB ED,8C", size: 2),    //  0x8C
            opCode(mnemonic: "DB ED,8D", size: 2),    //  0x8D
            opCode(mnemonic: "DB ED,8E", size: 2),    //  0x8E
            opCode(mnemonic: "DB ED,8F", size: 2),    //  0x8F
            opCode(mnemonic: "DB ED,90", size: 2),    //  0x90
            opCode(mnemonic: "DB ED,91", size: 2),    //  0x91
            opCode(mnemonic: "DB ED,92", size: 2),    //  0x92
            opCode(mnemonic: "DB ED,93", size: 2),    //  0x93
            opCode(mnemonic: "DB ED,94", size: 2),    //  0x94
            opCode(mnemonic: "DB ED,95", size: 2),    //  0x95
            opCode(mnemonic: "DB ED,96", size: 2),    //  0x96
            opCode(mnemonic: "DB ED,97", size: 2),    //  0x97
            opCode(mnemonic: "DB ED,98", size: 2),    //  0x98
            opCode(mnemonic: "DB ED,99", size: 2),    //  0x99
            opCode(mnemonic: "DB ED,9A", size: 2),    //  0x9A
            opCode(mnemonic: "DB ED,9B", size: 2),    //  0x9B
            opCode(mnemonic: "DB ED,9C", size: 2),    //  0x9C
            opCode(mnemonic: "DB ED,9D", size: 2),    //  0x9D
            opCode(mnemonic: "DB ED,9E", size: 2),    //  0x9E
            opCode(mnemonic: "DB ED,9F", size: 2),    //  0x9F
            opCode(mnemonic: "LDI", size: 2),    //  0xA0
            opCode(mnemonic: "CPI", size: 2),    //  0xA1
            opCode(mnemonic: "INI", size: 2),    //  0xA2
            opCode(mnemonic: "OUTI", size: 2),    //  0xA3
            opCode(mnemonic: "DB ED,A4", size: 2),    //  0xA4
            opCode(mnemonic: "DB ED,A5", size: 2),    //  0xA5
            opCode(mnemonic: "DB ED,A6", size: 2),    //  0xA6
            opCode(mnemonic: "DB ED,A7", size: 2),    //  0xA7
            opCode(mnemonic: "LDD", size: 2),    //  0xA8
            opCode(mnemonic: "CPD", size: 2),    //  0xA9
            opCode(mnemonic: "IND", size: 2),    //  0xAA
            opCode(mnemonic: "OUTD", size: 2),    //  0xAB
            opCode(mnemonic: "DB ED,AC", size: 2),    //  0xAC
            opCode(mnemonic: "DB ED,AD", size: 2),    //  0xAD
            opCode(mnemonic: "DB ED,AE", size: 2),    //  0xAE
            opCode(mnemonic: "DB ED,AF", size: 2),    //  0xAF
            opCode(mnemonic: "LDIR", size: 2),    //  0xB0
            opCode(mnemonic: "CPIR", size: 2),    //  0xB1
            opCode(mnemonic: "INIR", size: 2),    //  0xB2
            opCode(mnemonic: "OTIR", size: 2),    //  0xB3
            opCode(mnemonic: "DB ED,B4", size: 2),    //  0xB4
            opCode(mnemonic: "DB ED,B5", size: 2),    //  0xB5
            opCode(mnemonic: "DB ED,B6", size: 2),    //  0xB6
            opCode(mnemonic: "DB ED,B7", size: 2),    //  0xB7
            opCode(mnemonic: "LDDR", size: 2),    //  0xB8
            opCode(mnemonic: "CPDR", size: 2),    //  0xB9
            opCode(mnemonic: "INDR", size: 2),    //  0xBA
            opCode(mnemonic: "OTDR", size: 2),    //  0xBB
            opCode(mnemonic: "DB ED,BC", size: 2),    //  0xBC
            opCode(mnemonic: "DB ED,BD", size: 2),    //  0xBD
            opCode(mnemonic: "DB ED,BE", size: 2),    //  0xBE
            opCode(mnemonic: "DB ED,BF", size: 2),    //  0xBF
            opCode(mnemonic: "DB ED,C0", size: 2),    //  0xC0
            opCode(mnemonic: "DB ED,C1", size: 2),    //  0xC1
            opCode(mnemonic: "DB ED,C2", size: 2),    //  0xC2
            opCode(mnemonic: "DB ED,C3", size: 2),    //  0xC3
            opCode(mnemonic: "DB ED,C4", size: 2),    //  0xC4
            opCode(mnemonic: "DB ED,C5", size: 2),    //  0xC5
            opCode(mnemonic: "DB ED,C6", size: 2),    //  0xC6
            opCode(mnemonic: "DB ED,C7", size: 2),    //  0xC7
            opCode(mnemonic: "DB ED,C8", size: 2),    //  0xC8
            opCode(mnemonic: "DB ED,C9", size: 2),    //  0xC9
            opCode(mnemonic: "DB ED,CA", size: 2),    //  0xCA
            opCode(mnemonic: "DB ED,CB", size: 2),    //  0xCB
            opCode(mnemonic: "DB ED,CC", size: 2),    //  0xCC
            opCode(mnemonic: "DB ED,CD", size: 2),    //  0xCD
            opCode(mnemonic: "DB ED,CE", size: 2),    //  0xCE
            opCode(mnemonic: "DB ED,CF", size: 2),    //  0xCF
            opCode(mnemonic: "DB ED,D0", size: 2),    //  0xD0
            opCode(mnemonic: "DB ED,D1", size: 2),    //  0xD1
            opCode(mnemonic: "DB ED,D2", size: 2),    //  0xD2
            opCode(mnemonic: "DB ED,D3", size: 2),    //  0xD3
            opCode(mnemonic: "DB ED,D4", size: 2),    //  0xD4
            opCode(mnemonic: "DB ED,D5", size: 2),    //  0xD5
            opCode(mnemonic: "DB ED,D6", size: 2),    //  0xD6
            opCode(mnemonic: "DB ED,D7", size: 2),    //  0xD7
            opCode(mnemonic: "DB ED,D8", size: 2),    //  0xD8
            opCode(mnemonic: "DB ED,D9", size: 2),    //  0xD9
            opCode(mnemonic: "DB ED,DA", size: 2),    //  0xDA
            opCode(mnemonic: "DB ED,DB", size: 2),    //  0xDB
            opCode(mnemonic: "DB ED,DC", size: 2),    //  0xDC
            opCode(mnemonic: "DB ED,DD", size: 2),    //  0xDD
            opCode(mnemonic: "DB ED,DE", size: 2),    //  0xDE
            opCode(mnemonic: "DB ED,DF", size: 2),    //  0xDF
            opCode(mnemonic: "DB ED,E0", size: 2),    //  0xE0
            opCode(mnemonic: "DB ED,E1", size: 2),    //  0xE1
            opCode(mnemonic: "DB ED,E2", size: 2),    //  0xE2
            opCode(mnemonic: "DB ED,E3", size: 2),    //  0xE3
            opCode(mnemonic: "DB ED,E4", size: 2),    //  0xE4
            opCode(mnemonic: "DB ED,E5", size: 2),    //  0xE5
            opCode(mnemonic: "DB ED,E6", size: 2),    //  0xE6
            opCode(mnemonic: "DB ED,E7", size: 2),    //  0xE7
            opCode(mnemonic: "DB ED,E8", size: 2),    //  0xE8
            opCode(mnemonic: "DB ED,E9", size: 2),    //  0xE9
            opCode(mnemonic: "DB ED,EA", size: 2),    //  0xEA
            opCode(mnemonic: "DB ED,EB", size: 2),    //  0xEB
            opCode(mnemonic: "DB ED,EC", size: 2),    //  0xEC
            opCode(mnemonic: "DB ED,ED", size: 2),    //  0xED
            opCode(mnemonic: "DB ED,EE", size: 2),    //  0xEE
            opCode(mnemonic: "DB ED,EF", size: 2),    //  0xEF
            opCode(mnemonic: "DB ED,F0", size: 2),    //  0xF0
            opCode(mnemonic: "DB ED,F1", size: 2),    //  0xF1
            opCode(mnemonic: "DB ED,F2", size: 2),    //  0xF2
            opCode(mnemonic: "DB ED,F3", size: 2),    //  0xF3
            opCode(mnemonic: "DB ED,F4", size: 2),    //  0xF4
            opCode(mnemonic: "DB ED,F5", size: 2),    //  0xF5
            opCode(mnemonic: "DB ED,F6", size: 2),    //  0xF6
            opCode(mnemonic: "DB ED,F7", size: 2),    //  0xF7
            opCode(mnemonic: "DB ED,F8", size: 2),    //  0xF8
            opCode(mnemonic: "DB ED,F9", size: 2),    //  0xF9
            opCode(mnemonic: "DB ED,FA", size: 2),    //  0xFA
            opCode(mnemonic: "DB ED,FB", size: 2),    //  0xFB
            opCode(mnemonic: "DB ED,FC", size: 2),    //  0xFC
            opCode(mnemonic: "DB ED,FD", size: 2),    //  0xFD
            opCode(mnemonic: "DB ED,FE", size: 2),    //  0xFE
            opCode(mnemonic: "DB ED,FF", size: 2)    //  0xFF
        ]
        
        let FDPrefixOpcode: [opCode] =
        [
            opCode(mnemonic: "NOP", size: 2),    //  0x00
            opCode(mnemonic: "LD BC,$nn", size: 2),    //  0x01
            opCode(mnemonic: "LD (BC),A", size: 2),    //  0x02
            opCode(mnemonic: "INC BC", size: 2),    //  0x03
            opCode(mnemonic: "INC B", size: 2),    //  0x04
            opCode(mnemonic: "DEC B", size: 2),    //  0x05
            opCode(mnemonic: "LD B,$n", size: 2),    //  0x06
            opCode(mnemonic: "RLCA", size: 2),    //  0x07
            opCode(mnemonic: "EX AF,AF'", size: 2),    //  0x08
            opCode(mnemonic: "ADD IY,BC", size: 2),    //  0x09
            opCode(mnemonic: "LD A,(BC)", size: 2),    //  0x0A
            opCode(mnemonic: "DEC BC", size: 2),    //  0x0B
            opCode(mnemonic: "INC C", size: 2),    //  0x0C
            opCode(mnemonic: "DEC C", size: 2),    //  0x0D
            opCode(mnemonic: "LD C,$n", size: 2),    //  0x0E
            opCode(mnemonic: "RRCA", size: 2),    //  0x0F
            opCode(mnemonic: "DJNZ $d", size: 2),    //  0x10
            opCode(mnemonic: "LD DE,$nn", size: 2),    //  0x11
            opCode(mnemonic: "LD (DE),A", size: 2),    //  0x12
            opCode(mnemonic: "INC DE", size: 2),    //  0x13
            opCode(mnemonic: "INC D", size: 2),    //  0x14
            opCode(mnemonic: "DEC D", size: 2),    //  0x15
            opCode(mnemonic: "LD D,$n", size: 2),    //  0x16
            opCode(mnemonic: "RLA", size: 2),    //  0x17
            opCode(mnemonic: "JR $d", size: 2),    //  0x18
            opCode(mnemonic: "ADD IY,DE", size: 2),    //  0x19
            opCode(mnemonic: "LD A,(DE)", size: 2),    //  0x1A
            opCode(mnemonic: "DEC DE", size: 2),    //  0x1B
            opCode(mnemonic: "INC E", size: 2),    //  0x1C
            opCode(mnemonic: "DEC E", size: 2),    //  0x1D
            opCode(mnemonic: "LD E,$n", size: 2),    //  0x1E
            opCode(mnemonic: "RRA", size: 2),    //  0x1F
            opCode(mnemonic: "JR NZ,$d", size: 2),    //  0x20
            opCode(mnemonic: "LD IY,$nn", size: 2),    //  0x21
            opCode(mnemonic: "LD ($nn),IY", size: 2),    //  0x22
            opCode(mnemonic: "INC IY", size: 2),    //  0x23
            opCode(mnemonic: "INC IYH", size: 2),    //  0x24
            opCode(mnemonic: "DEC IYH", size: 2),    //  0x25
            opCode(mnemonic: "LD IYH,$n", size: 2),    //  0x26
            opCode(mnemonic: "DAA", size: 2),    //  0x27
            opCode(mnemonic: "JR Z,$d", size: 2),    //  0x28
            opCode(mnemonic: "ADD IY,IY", size: 2),    //  0x29
            opCode(mnemonic: "LD IY,($nn)", size: 2),    //  0x2A
            opCode(mnemonic: "DEC IY", size: 2),    //  0x2B
            opCode(mnemonic: "INC IYL", size: 2),    //  0x2C
            opCode(mnemonic: "DEC IYL", size: 2),    //  0x2D
            opCode(mnemonic: "LD IYL,$n", size: 2),    //  0x2E
            opCode(mnemonic: "CPL", size: 2),    //  0x2F
            opCode(mnemonic: "JR NC,$d", size: 2),    //  0x30
            opCode(mnemonic: "LD SP,$nn", size: 2),    //  0x31
            opCode(mnemonic: "LD ($nn),A", size: 2),    //  0x32
            opCode(mnemonic: "INC SP", size: 2),    //  0x33
            opCode(mnemonic: "INC (IY+$d)", size: 2),    //  0x34
            opCode(mnemonic: "DEC (IY+$d)", size: 2),    //  0x35
            opCode(mnemonic: "LD (IY+$d),$n", size: 2),    //  0x36
            opCode(mnemonic: "SCF", size: 2),    //  0x37
            opCode(mnemonic: "JR C,$d", size: 2),    //  0x38
            opCode(mnemonic: "ADD IY,SP", size: 2),    //  0x39
            opCode(mnemonic: "LD A,($nn)", size: 2),    //  0x3A
            opCode(mnemonic: "DEC SP", size: 2),    //  0x3B
            opCode(mnemonic: "INC A", size: 2),    //  0x3C
            opCode(mnemonic: "DEC A", size: 2),    //  0x3D
            opCode(mnemonic: "LD A,$n", size: 2),    //  0x3E
            opCode(mnemonic: "CCF", size: 2),    //  0x3F
            opCode(mnemonic: "LD B,B", size: 2),    //  0x40
            opCode(mnemonic: "LD B,C", size: 2),    //  0x41
            opCode(mnemonic: "LD B,D", size: 2),    //  0x42
            opCode(mnemonic: "LD B,E", size: 2),    //  0x43
            opCode(mnemonic: "LD B,IYH", size: 2),    //  0x44
            opCode(mnemonic: "LD B,IYL", size: 2),    //  0x45
            opCode(mnemonic: "LD B,(IY+$d)", size: 2),    //  0x46
            opCode(mnemonic: "LD B,A", size: 2),    //  0x47
            opCode(mnemonic: "LD C,B", size: 2),    //  0x48
            opCode(mnemonic: "LD C,C", size: 2),    //  0x49
            opCode(mnemonic: "LD C,D", size: 2),    //  0x4A
            opCode(mnemonic: "LD C,E", size: 2),    //  0x4B
            opCode(mnemonic: "LD C,IYH", size: 2),    //  0x4C
            opCode(mnemonic: "LD C,IYL", size: 2),    //  0x4D
            opCode(mnemonic: "LD C,(IY+$d)", size: 2),    //  0x4E
            opCode(mnemonic: "LD C,A", size: 2),    //  0x4F
            opCode(mnemonic: "LD D,B", size: 2),    //  0x50
            opCode(mnemonic: "LD D,C", size: 2),    //  0x51
            opCode(mnemonic: "LD D,D", size: 2),    //  0x52
            opCode(mnemonic: "LD D,E", size: 2),    //  0x53
            opCode(mnemonic: "LD D,IYH", size: 2),    //  0x54
            opCode(mnemonic: "LD D,IYL", size: 2),    //  0x55
            opCode(mnemonic: "LD D,(IY+$d)", size: 2),    //  0x56
            opCode(mnemonic: "LD D,A", size: 2),    //  0x57
            opCode(mnemonic: "LD E,B", size: 2),    //  0x58
            opCode(mnemonic: "LD E,C", size: 2),    //  0x59
            opCode(mnemonic: "LD E,D", size: 2),    //  0x5A
            opCode(mnemonic: "LD E,E", size: 2),    //  0x5B
            opCode(mnemonic: "LD E,IYH", size: 2),    //  0x5C
            opCode(mnemonic: "LD E,IYL", size: 2),    //  0x5D
            opCode(mnemonic: "LD E,(IY+$d)", size: 2),    //  0x5E
            opCode(mnemonic: "LD E,A", size: 2),    //  0x5F
            opCode(mnemonic: "LD IYH,B", size: 2),    //  0x60
            opCode(mnemonic: "LD IYH,C", size: 2),    //  0x61
            opCode(mnemonic: "LD IYH,D", size: 2),    //  0x62
            opCode(mnemonic: "LD IYH,E", size: 2),    //  0x63
            opCode(mnemonic: "LD IYH,IYH", size: 2),    //  0x64
            opCode(mnemonic: "LD IYH,IYL", size: 2),    //  0x65
            opCode(mnemonic: "LD H,(IY+$d)", size: 2),    //  0x66
            opCode(mnemonic: "LD IYH,A", size: 2),    //  0x67
            opCode(mnemonic: "LD IYL,B", size: 2),    //  0x68
            opCode(mnemonic: "LD IYL,C", size: 2),    //  0x69
            opCode(mnemonic: "LD IYL,D", size: 2),    //  0x6A
            opCode(mnemonic: "LD IYL,E", size: 2),    //  0x6B
            opCode(mnemonic: "LD IYL,IYH", size: 2),    //  0x6C
            opCode(mnemonic: "LD IYL,IYL", size: 2),    //  0x6D
            opCode(mnemonic: "LD L,(IY+$d)", size: 2),    //  0x6E
            opCode(mnemonic: "LD IYL,A", size: 2),    //  0x6F
            opCode(mnemonic: "LD (IY+$d),B", size: 2),    //  0x70
            opCode(mnemonic: "LD (IY+$d),C", size: 2),    //  0x71
            opCode(mnemonic: "LD (IY+$d),D", size: 2),    //  0x72
            opCode(mnemonic: "LD (IY+$d),E", size: 2),    //  0x73
            opCode(mnemonic: "LD (IY+$d),H", size: 2),    //  0x74
            opCode(mnemonic: "LD (IY+$d),L", size: 2),    //  0x75
            opCode(mnemonic: "HALT", size: 2),    //  0x76
            opCode(mnemonic: "LD (IY+$d),A", size: 2),    //  0x77
            opCode(mnemonic: "LD A,B", size: 2),    //  0x78
            opCode(mnemonic: "LD A,C", size: 2),    //  0x79
            opCode(mnemonic: "LD A,D", size: 2),    //  0x7A
            opCode(mnemonic: "LD A,E", size: 2),    //  0x7B
            opCode(mnemonic: "LD A,IYH", size: 2),    //  0x7C
            opCode(mnemonic: "LD A,IYL", size: 2),    //  0x7D
            opCode(mnemonic: "LD A,(IY+$d)", size: 2),    //  0x7E
            opCode(mnemonic: "LD A,A", size: 2),    //  0x7F
            opCode(mnemonic: "ADD A,B", size: 2),    //  0x80
            opCode(mnemonic: "ADD A,C", size: 2),    //  0x81
            opCode(mnemonic: "ADD A,D", size: 2),    //  0x82
            opCode(mnemonic: "ADD A,E", size: 2),    //  0x83
            opCode(mnemonic: "ADD A,IYH", size: 2),    //  0x84
            opCode(mnemonic: "ADD A,IYL", size: 2),    //  0x85
            opCode(mnemonic: "ADD A,(IY+$d)", size: 2),    //  0x86
            opCode(mnemonic: "ADD A,A", size: 2),    //  0x87
            opCode(mnemonic: "ADC A,B", size: 2),    //  0x88
            opCode(mnemonic: "ADC A,C", size: 2),    //  0x89
            opCode(mnemonic: "ADC A,D", size: 2),    //  0x8A
            opCode(mnemonic: "ADC A,E", size: 2),    //  0x8B
            opCode(mnemonic: "ADC A,IYH", size: 2),    //  0x8C
            opCode(mnemonic: "ADC A,IYL", size: 2),    //  0x8D
            opCode(mnemonic: "ADC A,(IY+$d)", size: 2),    //  0x8E
            opCode(mnemonic: "ADC A,A", size: 2),    //  0x8F
            opCode(mnemonic: "SUB B", size: 2),    //  0x90
            opCode(mnemonic: "SUB C", size: 2),    //  0x91
            opCode(mnemonic: "SUB D", size: 2),    //  0x92
            opCode(mnemonic: "SUB E", size: 2),    //  0x93
            opCode(mnemonic: "SUB IYH", size: 2),    //  0x94
            opCode(mnemonic: "SUB IYL", size: 2),    //  0x95
            opCode(mnemonic: "SUB (IY+$d)", size: 2),    //  0x96
            opCode(mnemonic: "SUB A", size: 2),    //  0x97
            opCode(mnemonic: "SBC A,B", size: 2),    //  0x98
            opCode(mnemonic: "SBC A,C", size: 2),    //  0x99
            opCode(mnemonic: "SBC A,D", size: 2),    //  0x9A
            opCode(mnemonic: "SBC A,E", size: 2),    //  0x9B
            opCode(mnemonic: "SBC A,IYH", size: 2),    //  0x9C
            opCode(mnemonic: "SBC A,IYL", size: 2),    //  0x9D
            opCode(mnemonic: "SBC A,(IY+$d)", size: 2),    //  0x9E
            opCode(mnemonic: "SBC A,A", size: 2),    //  0x9F
            opCode(mnemonic: "AND B", size: 2),    //  0xA0
            opCode(mnemonic: "AND C", size: 2),    //  0xA1
            opCode(mnemonic: "AND D", size: 2),    //  0xA2
            opCode(mnemonic: "AND E", size: 2),    //  0xA3
            opCode(mnemonic: "AND IYH", size: 2),    //  0xA4
            opCode(mnemonic: "AND IYL", size: 2),    //  0xA5
            opCode(mnemonic: "AND (IY+$d)", size: 2),    //  0xA6
            opCode(mnemonic: "AND A", size: 2),    //  0xA7
            opCode(mnemonic: "XOR B", size: 2),    //  0xA8
            opCode(mnemonic: "XOR C", size: 2),    //  0xA9
            opCode(mnemonic: "XOR D", size: 2),    //  0xAA
            opCode(mnemonic: "XOR E", size: 2),    //  0xAB
            opCode(mnemonic: "XOR IYH", size: 2),    //  0xAC
            opCode(mnemonic: "XOR IYL", size: 2),    //  0xAD
            opCode(mnemonic: "XOR (IY+$d)", size: 2),    //  0xAE
            opCode(mnemonic: "XOR A", size: 2),    //  0xAF
            opCode(mnemonic: "OR B", size: 2),    //  0xB0
            opCode(mnemonic: "OR C", size: 2),    //  0xB1
            opCode(mnemonic: "OR D", size: 2),    //  0xB2
            opCode(mnemonic: "OR E", size: 2),    //  0xB3
            opCode(mnemonic: "OR IYH", size: 2),    //  0xB4
            opCode(mnemonic: "OR IYL", size: 2),    //  0xB5
            opCode(mnemonic: "OR (IY+$d)", size: 2),    //  0xB6
            opCode(mnemonic: "OR A", size: 2),    //  0xB7
            opCode(mnemonic: "CP B", size: 2),    //  0xB8
            opCode(mnemonic: "CP C", size: 2),    //  0xB9
            opCode(mnemonic: "CP D", size: 2),    //  0xBA
            opCode(mnemonic: "CP E", size: 2),    //  0xBB
            opCode(mnemonic: "CP IYH", size: 2),    //  0xBC
            opCode(mnemonic: "CP IYL", size: 2),    //  0xBD
            opCode(mnemonic: "CP (IY+$d)", size: 2),    //  0xBE
            opCode(mnemonic: "CP A", size: 2),    //  0xBF
            opCode(mnemonic: "RET NZ", size: 2),    //  0xC0
            opCode(mnemonic: "POP BC", size: 2),    //  0xC1
            opCode(mnemonic: "JP NZ,$nn", size: 2),    //  0xC2
            opCode(mnemonic: "JP $nn", size: 2),    //  0xC3
            opCode(mnemonic: "CALL NZ,$nn", size: 2),    //  0xC4
            opCode(mnemonic: "PUSH BC", size: 2),    //  0xC5
            opCode(mnemonic: "ADD A,$n", size: 2),    //  0xC6
            opCode(mnemonic: "RST 0x00", size: 2),    //  0xC7
            opCode(mnemonic: "RET Z", size: 2),    //  0xC8
            opCode(mnemonic: "RET", size: 2),    //  0xC9
            opCode(mnemonic: "JP Z,$nn", size: 2),    //  0xCA
            opCode(mnemonic: "CB prefixes", size: 2),    //  0xCB
            opCode(mnemonic: "CALL Z,$nn", size: 2),    //  0xCC
            opCode(mnemonic: "CALL $nn", size: 2),    //  0xCD
            opCode(mnemonic: "ADC A,$n", size: 2),    //  0xCE
            opCode(mnemonic: "RST 0x08", size: 2),    //  0xCF
            opCode(mnemonic: "RET NC", size: 2),    //  0xD0
            opCode(mnemonic: "POP DE", size: 2),    //  0xD1
            opCode(mnemonic: "JP NC,$nn", size: 2),    //  0xD2
            opCode(mnemonic: "OUT ($n),A", size: 2),    //  0xD3
            opCode(mnemonic: "CALL NC,$nn", size: 2),    //  0xD4
            opCode(mnemonic: "PUSH DE", size: 2),    //  0xD5
            opCode(mnemonic: "SUB $n", size: 2),    //  0xD6
            opCode(mnemonic: "RST 0x10", size: 2),    //  0xD7
            opCode(mnemonic: "RET C", size: 2),    //  0xD8
            opCode(mnemonic: "EXX", size: 2),    //  0xD9
            opCode(mnemonic: "JP C,$nn", size: 2),    //  0xDA
            opCode(mnemonic: "IN A,(N)", size: 2),    //  0xDB
            opCode(mnemonic: "CALL C,$nn", size: 2),    //  0xDC
            opCode(mnemonic: "DD/DDCB prefixes", size: 2),    //  0xDD
            opCode(mnemonic: "SBC A,$n", size: 2),    //  0xDE
            opCode(mnemonic: "RST 0x18", size: 2),    //  0xDF
            opCode(mnemonic: "RET PO", size: 2),    //  0xE0
            opCode(mnemonic: "POP IY", size: 2),    //  0xE1
            opCode(mnemonic: "JP PO,$nn", size: 2),    //  0xE2
            opCode(mnemonic: "EX (SP),IY", size: 2),    //  0xE3
            opCode(mnemonic: "CALL PO,$nn", size: 2),    //  0xE4
            opCode(mnemonic: "PUSH IY", size: 2),    //  0xE5
            opCode(mnemonic: "AND $n", size: 2),    //  0xE6
            opCode(mnemonic: "RST 0x20", size: 2),    //  0xE7
            opCode(mnemonic: "RET PE", size: 2),    //  0xE8
            opCode(mnemonic: "JP (IY)", size: 2),    //  0xE9
            opCode(mnemonic: "JP PE,$nn", size: 2),    //  0xEA
            opCode(mnemonic: "EX DE,HL", size: 2),    //  0xEB
            opCode(mnemonic: "CALL PE,$nn", size: 2),    //  0xEC
            opCode(mnemonic: "ED prefixes", size: 2),    //  0xED
            opCode(mnemonic: "XOR $n", size: 2),    //  0xEE
            opCode(mnemonic: "RST 0x28", size: 2),    //  0xEF
            opCode(mnemonic: "RET P", size: 2),    //  0xF0
            opCode(mnemonic: "POP AF", size: 2),    //  0xF1
            opCode(mnemonic: "JP P,$nn", size: 2),    //  0xF2
            opCode(mnemonic: "DI", size: 2),    //  0xF3
            opCode(mnemonic: "CALL P,$nn", size: 2),    //  0xF4
            opCode(mnemonic: "PUSH AF", size: 2),    //  0xF5
            opCode(mnemonic: "OR N", size: 2),    //  0xF6
            opCode(mnemonic: "RST 0x30", size: 2),    //  0xF7
            opCode(mnemonic: "RET M", size: 2),    //  0xF8
            opCode(mnemonic: "LD SP,IY", size: 2),    //  0xF9
            opCode(mnemonic: "JP M,$nn", size: 2),    //  0xFA
            opCode(mnemonic: "EI", size: 2),    //  0xFB
            opCode(mnemonic: "CALL M,$nn", size: 2),    //  0xFC
            opCode(mnemonic: "FD/FDCB prefixes", size: 2),    //  0xFD
            opCode(mnemonic: "CP $n", size: 2),    //  0xFE
            opCode(mnemonic: "RST 0x38", size: 2)    //  0xFF
        ]
        
        let DDCBPrefixOpcode: [opCode] =
        [
            opCode(mnemonic: "RLC (IX+$d),B", size: 4),    //  0x00
            opCode(mnemonic: "RLC (IX+$d),C", size: 4),    //  0x01
            opCode(mnemonic: "RLC (IX+$d),D", size: 4),    //  0x02
            opCode(mnemonic: "RLC (IX+$d),E", size: 4),    //  0x03
            opCode(mnemonic: "RLC (IX+$d),H", size: 4),    //  0x04
            opCode(mnemonic: "RLC (IX+$d),L", size: 4),    //  0x05
            opCode(mnemonic: "RLC (IX+$d)", size: 4),    //  0x06
            opCode(mnemonic: "RLC (IX+$d),A", size: 4),    //  0x07
            opCode(mnemonic: "RRC (IX+$d),B", size: 4),    //  0x08
            opCode(mnemonic: "RRC (IX+$d),C", size: 4),    //  0x09
            opCode(mnemonic: "RRC (IX+$d),D", size: 4),    //  0x0A
            opCode(mnemonic: "RRC (IX+$d),E", size: 4),    //  0x0B
            opCode(mnemonic: "RRC (IX+$d),H", size: 4),    //  0x0C
            opCode(mnemonic: "RRC (IX+$d),L", size: 4),    //  0x0D
            opCode(mnemonic: "RRC (IX+$d)", size: 4),    //  0x0E
            opCode(mnemonic: "RRC (IX+$d),A", size: 4),    //  0x0F
            opCode(mnemonic: "RL (IX+$d),B", size: 4),    //  0x10
            opCode(mnemonic: "RL (IX+$d),C", size: 4),    //  0x11
            opCode(mnemonic: "RL (IX+$d),D", size: 4),    //  0x12
            opCode(mnemonic: "RL (IX+$d),E", size: 4),    //  0x13
            opCode(mnemonic: "RL (IX+$d),H", size: 4),    //  0x14
            opCode(mnemonic: "RL (IX+$d),L", size: 4),    //  0x15
            opCode(mnemonic: "RL (IX+$d)", size: 4),    //  0x16
            opCode(mnemonic: "RL (IX+$d),A", size: 4),    //  0x17
            opCode(mnemonic: "RR (IX+$d),B", size: 4),    //  0x18
            opCode(mnemonic: "RR (IX+$d),C", size: 4),    //  0x19
            opCode(mnemonic: "RR (IX+$d),D", size: 4),    //  0x1A
            opCode(mnemonic: "RR (IX+$d),E", size: 4),    //  0x1B
            opCode(mnemonic: "RR (IX+$d),H", size: 4),    //  0x1C
            opCode(mnemonic: "RR (IX+$d),L", size: 4),    //  0x1D
            opCode(mnemonic: "RR (IX+$d)", size: 4),    //  0x1E
            opCode(mnemonic: "RR (IX+$d),A", size: 4),    //  0x1F
            opCode(mnemonic: "SLA (IX+$d),B", size: 4),    //  0x20
            opCode(mnemonic: "SLA (IX+$d),C", size: 4),    //  0x21
            opCode(mnemonic: "SLA (IX+$d),D", size: 4),    //  0x22
            opCode(mnemonic: "SLA (IX+$d),E", size: 4),    //  0x23
            opCode(mnemonic: "SLA (IX+$d),H", size: 4),    //  0x24
            opCode(mnemonic: "SLA (IX+$d),L", size: 4),    //  0x25
            opCode(mnemonic: "SLA (IX+$d)", size: 4),    //  0x26
            opCode(mnemonic: "SLA (IX+$d),A", size: 4),    //  0x27
            opCode(mnemonic: "SRA (IX+$d),B", size: 4),    //  0x28
            opCode(mnemonic: "SRA (IX+$d),C", size: 4),    //  0x29
            opCode(mnemonic: "SRA (IX+$d),D", size: 4),    //  0x2A
            opCode(mnemonic: "SRA (IX+$d),E", size: 4),    //  0x2B
            opCode(mnemonic: "SRA (IX+$d),H", size: 4),    //  0x2C
            opCode(mnemonic: "SRA (IX+$d),L", size: 4),    //  0x2D
            opCode(mnemonic: "SRA (IX+$d)", size: 4),    //  0x2E
            opCode(mnemonic: "SRA (IX+$d),A", size: 4),    //  0x2F
            opCode(mnemonic: "SLL (IX+$d),B", size: 4),    //  0x30
            opCode(mnemonic: "SLL (IX+$d),C", size: 4),    //  0x31
            opCode(mnemonic: "SLL (IX+$d),D", size: 4),    //  0x32
            opCode(mnemonic: "SLL (IX+$d),E", size: 4),    //  0x33
            opCode(mnemonic: "SLL (IX+$d),H", size: 4),    //  0x34
            opCode(mnemonic: "SLL (IX+$d),L", size: 4),    //  0x35
            opCode(mnemonic: "SLL (IX+$d)", size: 4),    //  0x36
            opCode(mnemonic: "SLL (IX+$d),A", size: 4),    //  0x37
            opCode(mnemonic: "SRL (IX+$d),B", size: 4),    //  0x38
            opCode(mnemonic: "SRL (IX+$d),C", size: 4),    //  0x39
            opCode(mnemonic: "SRL (IX+$d),D", size: 4),    //  0x3A
            opCode(mnemonic: "SRL (IX+$d),E", size: 4),    //  0x3B
            opCode(mnemonic: "SRL (IX+$d),H", size: 4),    //  0x3C
            opCode(mnemonic: "SRL (IX+$d),L", size: 4),    //  0x3D
            opCode(mnemonic: "SRL (IX+$d)", size: 4),    //  0x3E
            opCode(mnemonic: "SRL (IX+$d),A", size: 4),    //  0x3F
            opCode(mnemonic: "BIT 0,(IX+$d)", size: 4),    //  0x40
            opCode(mnemonic: "BIT 0,(IX+$d)", size: 4),    //  0x41
            opCode(mnemonic: "BIT 0,(IX+$d)", size: 4),    //  0x42
            opCode(mnemonic: "BIT 0,(IX+$d)", size: 4),    //  0x43
            opCode(mnemonic: "BIT 0,(IX+$d)", size: 4),    //  0x44
            opCode(mnemonic: "BIT 0,(IX+$d)", size: 4),    //  0x45
            opCode(mnemonic: "BIT 0,(IX+$d)", size: 4),    //  0x46
            opCode(mnemonic: "BIT 0,(IX+$d)", size: 4),    //  0x47
            opCode(mnemonic: "BIT 1,(IX+$d)", size: 4),    //  0x48
            opCode(mnemonic: "BIT 1,(IX+$d)", size: 4),    //  0x49
            opCode(mnemonic: "BIT 1,(IX+$d)", size: 4),    //  0x4A
            opCode(mnemonic: "BIT 1,(IX+$d)", size: 4),    //  0x4B
            opCode(mnemonic: "BIT 1,(IX+$d)", size: 4),    //  0x4C
            opCode(mnemonic: "BIT 1,(IX+$d)", size: 4),    //  0x4D
            opCode(mnemonic: "BIT 1,(IX+$d)", size: 4),    //  0x4E
            opCode(mnemonic: "BIT 1,(IX+$d)", size: 4),    //  0x4F
            opCode(mnemonic: "BIT 2,(IX+$d)", size: 4),    //  0x50
            opCode(mnemonic: "BIT 2,(IX+$d)", size: 4),    //  0x51
            opCode(mnemonic: "BIT 2,(IX+$d)", size: 4),    //  0x52
            opCode(mnemonic: "BIT 2,(IX+$d)", size: 4),    //  0x53
            opCode(mnemonic: "BIT 2,(IX+$d)", size: 4),    //  0x54
            opCode(mnemonic: "BIT 2,(IX+$d)", size: 4),    //  0x55
            opCode(mnemonic: "BIT 2,(IX+$d)", size: 4),    //  0x56
            opCode(mnemonic: "BIT 2,(IX+$d)", size: 4),    //  0x57
            opCode(mnemonic: "BIT 3,(IX+$d)", size: 4),    //  0x58
            opCode(mnemonic: "BIT 3,(IX+$d)", size: 4),    //  0x59
            opCode(mnemonic: "BIT 3,(IX+$d)", size: 4),    //  0x5A
            opCode(mnemonic: "BIT 3,(IX+$d)", size: 4),    //  0x5B
            opCode(mnemonic: "BIT 3,(IX+$d)", size: 4),    //  0x5C
            opCode(mnemonic: "BIT 3,(IX+$d)", size: 4),    //  0x5D
            opCode(mnemonic: "BIT 3,(IX+$d)", size: 4),    //  0x5E
            opCode(mnemonic: "BIT 3,(IX+$d)", size: 4),    //  0x5F
            opCode(mnemonic: "BIT 4,(IX+$d)", size: 4),    //  0x60
            opCode(mnemonic: "BIT 4,(IX+$d)", size: 4),    //  0x61
            opCode(mnemonic: "BIT 4,(IX+$d)", size: 4),    //  0x62
            opCode(mnemonic: "BIT 4,(IX+$d)", size: 4),    //  0x63
            opCode(mnemonic: "BIT 4,(IX+$d)", size: 4),    //  0x64
            opCode(mnemonic: "BIT 4,(IX+$d)", size: 4),    //  0x65
            opCode(mnemonic: "BIT 4,(IX+$d)", size: 4),    //  0x66
            opCode(mnemonic: "BIT 4,(IX+$d)", size: 4),    //  0x67
            opCode(mnemonic: "BIT 5,(IX+$d)", size: 4),    //  0x68
            opCode(mnemonic: "BIT 5,(IX+$d)", size: 4),    //  0x69
            opCode(mnemonic: "BIT 5,(IX+$d)", size: 4),    //  0x6A
            opCode(mnemonic: "BIT 5,(IX+$d)", size: 4),    //  0x6B
            opCode(mnemonic: "BIT 5,(IX+$d)", size: 4),    //  0x6C
            opCode(mnemonic: "BIT 5,(IX+$d)", size: 4),    //  0x6D
            opCode(mnemonic: "BIT 5,(IX+$d)", size: 4),    //  0x6E
            opCode(mnemonic: "BIT 5,(IX+$d)", size: 4),    //  0x6F
            opCode(mnemonic: "BIT 6,(IX+$d)", size: 4),    //  0x70
            opCode(mnemonic: "BIT 6,(IX+$d)", size: 4),    //  0x71
            opCode(mnemonic: "BIT 6,(IX+$d)", size: 4),    //  0x72
            opCode(mnemonic: "BIT 6,(IX+$d)", size: 4),    //  0x73
            opCode(mnemonic: "BIT 6,(IX+$d)", size: 4),    //  0x74
            opCode(mnemonic: "BIT 6,(IX+$d)", size: 4),    //  0x75
            opCode(mnemonic: "BIT 6,(IX+$d)", size: 4),    //  0x76
            opCode(mnemonic: "BIT 6,(IX+$d)", size: 4),    //  0x77
            opCode(mnemonic: "BIT 7,(IX+$d)", size: 4),    //  0x78
            opCode(mnemonic: "BIT 7,(IX+$d)", size: 4),    //  0x79
            opCode(mnemonic: "BIT 7,(IX+$d)", size: 4),    //  0x7A
            opCode(mnemonic: "BIT 7,(IX+$d)", size: 4),    //  0x7B
            opCode(mnemonic: "BIT 7,(IX+$d)", size: 4),    //  0x7C
            opCode(mnemonic: "BIT 7,(IX+$d)", size: 4),    //  0x7D
            opCode(mnemonic: "BIT 7,(IX+$d)", size: 4),    //  0x7E
            opCode(mnemonic: "BIT 7,(IX+$d)", size: 4),    //  0x7F
            opCode(mnemonic: "RES 0,(IX+$d),B", size: 4),    //  0x80
            opCode(mnemonic: "RES 0,(IX+$d),C", size: 4),    //  0x81
            opCode(mnemonic: "RES 0,(IX+$d),D", size: 4),    //  0x82
            opCode(mnemonic: "RES 0,(IX+$d),E", size: 4),    //  0x83
            opCode(mnemonic: "RES 0,(IX+$d),H", size: 4),    //  0x84
            opCode(mnemonic: "RES 0,(IX+$d),L", size: 4),    //  0x85
            opCode(mnemonic: "RES 0,(IX+$d)", size: 4),    //  0x86
            opCode(mnemonic: "RES 0,(IX+$d),A", size: 4),    //  0x87
            opCode(mnemonic: "RES 1,(IX+$d),B", size: 4),    //  0x88
            opCode(mnemonic: "RES 1,(IX+$d),C", size: 4),    //  0x89
            opCode(mnemonic: "RES 1,(IX+$d),D", size: 4),    //  0x8A
            opCode(mnemonic: "RES 1,(IX+$d),E", size: 4),    //  0x8B
            opCode(mnemonic: "RES 1,(IX+$d),H", size: 4),    //  0x8C
            opCode(mnemonic: "RES 1,(IX+$d),L", size: 4),    //  0x8D
            opCode(mnemonic: "RES 1,(IX+$d)", size: 4),    //  0x8E
            opCode(mnemonic: "RES 1,(IX+$d),A", size: 4),    //  0x8F
            opCode(mnemonic: "RES 2,(IX+$d),B", size: 4),    //  0x90
            opCode(mnemonic: "RES 2,(IX+$d),C", size: 4),    //  0x91
            opCode(mnemonic: "RES 2,(IX+$d),D", size: 4),    //  0x92
            opCode(mnemonic: "RES 2,(IX+$d),E", size: 4),    //  0x93
            opCode(mnemonic: "RES 2,(IX+$d),H", size: 4),    //  0x94
            opCode(mnemonic: "RES 2,(IX+$d),L", size: 4),    //  0x95
            opCode(mnemonic: "RES 2,(IX+$d)", size: 4),    //  0x96
            opCode(mnemonic: "RES 2,(IX+$d),A", size: 4),    //  0x97
            opCode(mnemonic: "RES 3,(IX+$d),B", size: 4),    //  0x98
            opCode(mnemonic: "RES 3,(IX+$d),C", size: 4),    //  0x99
            opCode(mnemonic: "RES 3,(IX+$d),D", size: 4),    //  0x9A
            opCode(mnemonic: "RES 3,(IX+$d),E", size: 4),    //  0x9B
            opCode(mnemonic: "RES 3,(IX+$d),H", size: 4),    //  0x9C
            opCode(mnemonic: "RES 3,(IX+$d),L", size: 4),    //  0x9D
            opCode(mnemonic: "RES 3,(IX+$d)", size: 4),    //  0x9E
            opCode(mnemonic: "RES 3,(IX+$d),A", size: 4),    //  0x9F
            opCode(mnemonic: "RES 4,(IX+$d),B", size: 4),    //  0xA0
            opCode(mnemonic: "RES 4,(IX+$d),C", size: 4),    //  0xA1
            opCode(mnemonic: "RES 4,(IX+$d),D", size: 4),    //  0xA2
            opCode(mnemonic: "RES 4,(IX+$d),E", size: 4),    //  0xA3
            opCode(mnemonic: "RES 4,(IX+$d),H", size: 4),    //  0xA4
            opCode(mnemonic: "RES 4,(IX+$d),L", size: 4),    //  0xA5
            opCode(mnemonic: "RES 4,(IX+$d)", size: 4),    //  0xA6
            opCode(mnemonic: "RES 4,(IX+$d),A", size: 4),    //  0xA7
            opCode(mnemonic: "RES 5,(IX+$d),B", size: 4),    //  0xA8
            opCode(mnemonic: "RES 5,(IX+$d),C", size: 4),    //  0xA9
            opCode(mnemonic: "RES 5,(IX+$d),D", size: 4),    //  0xAA
            opCode(mnemonic: "RES 5,(IX+$d),E", size: 4),    //  0xAB
            opCode(mnemonic: "RES 5,(IX+$d),H", size: 4),    //  0xAC
            opCode(mnemonic: "RES 5,(IX+$d),L", size: 4),    //  0xAD
            opCode(mnemonic: "RES 5,(IX+$d)", size: 4),    //  0xAE
            opCode(mnemonic: "RES 5,(IX+$d),A", size: 4),    //  0xAF
            opCode(mnemonic: "RES 6,(IX+$d),B", size: 4),    //  0xB0
            opCode(mnemonic: "RES 6,(IX+$d),C", size: 4),    //  0xB1
            opCode(mnemonic: "RES 6,(IX+$d),D", size: 4),    //  0xB2
            opCode(mnemonic: "RES 6,(IX+$d),E", size: 4),    //  0xB3
            opCode(mnemonic: "RES 6,(IX+$d),H", size: 4),    //  0xB4
            opCode(mnemonic: "RES 6,(IX+$d),L", size: 4),    //  0xB5
            opCode(mnemonic: "RES 6,(IX+$d)", size: 4),    //  0xB6
            opCode(mnemonic: "RES 6,(IX+$d),A", size: 4),    //  0xB7
            opCode(mnemonic: "RES 7,(IX+$d),B", size: 4),    //  0xB8
            opCode(mnemonic: "RES 7,(IX+$d),C", size: 4),    //  0xB9
            opCode(mnemonic: "RES 7,(IX+$d),D", size: 4),    //  0xBA
            opCode(mnemonic: "RES 7,(IX+$d),E", size: 4),    //  0xBB
            opCode(mnemonic: "RES 7,(IX+$d),H", size: 4),    //  0xBC
            opCode(mnemonic: "RES 7,(IX+$d),L", size: 4),    //  0xBD
            opCode(mnemonic: "RES 7,(IX+$d)", size: 4),    //  0xBE
            opCode(mnemonic: "RES 7,(IX+$d),A", size: 4),    //  0xBF
            opCode(mnemonic: "SET 0,(IX+$d),B", size: 4),    //  0xC0
            opCode(mnemonic: "SET 0,(IX+$d),C", size: 4),    //  0xC1
            opCode(mnemonic: "SET 0,(IX+$d),D", size: 4),    //  0xC2
            opCode(mnemonic: "SET 0,(IX+$d),E", size: 4),    //  0xC3
            opCode(mnemonic: "SET 0,(IX+$d),H", size: 4),    //  0xC4
            opCode(mnemonic: "SET 0,(IX+$d),L", size: 4),    //  0xC5
            opCode(mnemonic: "SET 0,(IX+$d)", size: 4),    //  0xC6
            opCode(mnemonic: "SET 0,(IX+$d),A", size: 4),    //  0xC7
            opCode(mnemonic: "SET 1,(IX+$d),B", size: 4),    //  0xC8
            opCode(mnemonic: "SET 1,(IX+$d),C", size: 4),    //  0xC9
            opCode(mnemonic: "SET 1,(IX+$d),D", size: 4),    //  0xCA
            opCode(mnemonic: "SET 1,(IX+$d),E", size: 4),    //  0xCB
            opCode(mnemonic: "SET 1,(IX+$d),H", size: 4),    //  0xCC
            opCode(mnemonic: "SET 1,(IX+$d),L", size: 4),    //  0xCD
            opCode(mnemonic: "SET 1,(IX+$d)", size: 4),    //  0xCE
            opCode(mnemonic: "SET 1,(IX+$d),A", size: 4),    //  0xCF
            opCode(mnemonic: "SET 2,(IX+$d),B", size: 4),    //  0xD0
            opCode(mnemonic: "SET 2,(IX+$d),C", size: 4),    //  0xD1
            opCode(mnemonic: "SET 2,(IX+$d),D", size: 4),    //  0xD2
            opCode(mnemonic: "SET 2,(IX+$d),E", size: 4),    //  0xD3
            opCode(mnemonic: "SET 2,(IX+$d),H", size: 4),    //  0xD4
            opCode(mnemonic: "SET 2,(IX+$d),L", size: 4),    //  0xD5
            opCode(mnemonic: "SET 2,(IX+$d)", size: 4),    //  0xD6
            opCode(mnemonic: "SET 2,(IX+$d),A", size: 4),    //  0xD7
            opCode(mnemonic: "SET 3,(IX+$d),B", size: 4),    //  0xD8
            opCode(mnemonic: "SET 3,(IX+$d),C", size: 4),    //  0xD9
            opCode(mnemonic: "SET 3,(IX+$d),D", size: 4),    //  0xDA
            opCode(mnemonic: "SET 3,(IX+$d),E", size: 4),    //  0xDB
            opCode(mnemonic: "SET 3,(IX+$d),H", size: 4),    //  0xDC
            opCode(mnemonic: "SET 3,(IX+$d),L", size: 4),    //  0xDD
            opCode(mnemonic: "SET 3,(IX+$d)", size: 4),    //  0xDE
            opCode(mnemonic: "SET 3,(IX+$d),A", size: 4),    //  0xDF
            opCode(mnemonic: "SET 4,(IX+$d),B", size: 4),    //  0xE0
            opCode(mnemonic: "SET 4,(IX+$d),C", size: 4),    //  0xE1
            opCode(mnemonic: "SET 4,(IX+$d),D", size: 4),    //  0xE2
            opCode(mnemonic: "SET 4,(IX+$d),E", size: 4),    //  0xE3
            opCode(mnemonic: "SET 4,(IX+$d),H", size: 4),    //  0xE4
            opCode(mnemonic: "SET 4,(IX+$d),L", size: 4),    //  0xE5
            opCode(mnemonic: "SET 4,(IX+$d)", size: 4),    //  0xE6
            opCode(mnemonic: "SET 4,(IX+$d),A", size: 4),    //  0xE7
            opCode(mnemonic: "SET 5,(IX+$d),B", size: 4),    //  0xE8
            opCode(mnemonic: "SET 5,(IX+$d),C", size: 4),    //  0xE9
            opCode(mnemonic: "SET 5,(IX+$d),D", size: 4),    //  0xEA
            opCode(mnemonic: "SET 5,(IX+$d),E", size: 4),    //  0xEB
            opCode(mnemonic: "SET 5,(IX+$d),H", size: 4),    //  0xEC
            opCode(mnemonic: "SET 5,(IX+$d),L", size: 4),    //  0xED
            opCode(mnemonic: "SET 5,(IX+$d)", size: 4),    //  0xEE
            opCode(mnemonic: "SET 5,(IX+$d),A", size: 4),    //  0xEF
            opCode(mnemonic: "SET 6,(IX+$d),B", size: 4),    //  0xF0
            opCode(mnemonic: "SET 6,(IX+$d),C", size: 4),    //  0xF1
            opCode(mnemonic: "SET 6,(IX+$d),D", size: 4),    //  0xF2
            opCode(mnemonic: "SET 6,(IX+$d),E", size: 4),    //  0xF3
            opCode(mnemonic: "SET 6,(IX+$d),H", size: 4),    //  0xF4
            opCode(mnemonic: "SET 6,(IX+$d),L", size: 4),    //  0xF5
            opCode(mnemonic: "SET 6,(IX+$d)", size: 4),    //  0xF6
            opCode(mnemonic: "SET 6,(IX+$d),A", size: 4),    //  0xF7
            opCode(mnemonic: "SET 7,(IX+$d),B", size: 4),    //  0xF8
            opCode(mnemonic: "SET 7,(IX+$d),C", size: 4),    //  0xF9
            opCode(mnemonic: "SET 7,(IX+$d),D", size: 4),    //  0xFA
            opCode(mnemonic: "SET 7,(IX+$d),E", size: 4),    //  0xFB
            opCode(mnemonic: "SET 7,(IX+$d),H", size: 4),    //  0xFC
            opCode(mnemonic: "SET 7,(IX+$d),L", size: 4),    //  0xFD
            opCode(mnemonic: "SET 7,(IX+$d)", size: 4),    //  0xFE
            opCode(mnemonic: "SET 7,(IX+$d),A", size: 4)    //  0xFF
        ]
        
        let FDCBPrefixOpcode: [opCode] =
        [
            opCode(mnemonic: "RLC (IY+$d),C", size: 4),    //  0x01
            opCode(mnemonic: "RLC (IY+$d),D", size: 4),    //  0x02
            opCode(mnemonic: "RLC (IY+$d),E", size: 4),    //  0x03
            opCode(mnemonic: "RLC (IY+$d),H", size: 4),    //  0x04
            opCode(mnemonic: "RLC (IY+$d),L", size: 4),    //  0x05
            opCode(mnemonic: "RLC (IY+$d)", size: 4),    //  0x06
            opCode(mnemonic: "RLC (IY+$d),A", size: 4),    //  0x07
            opCode(mnemonic: "RRC (IY+$d),B", size: 4),    //  0x08
            opCode(mnemonic: "RRC (IY+$d),C", size: 4),    //  0x09
            opCode(mnemonic: "RRC (IY+$d),D", size: 4),    //  0x0A
            opCode(mnemonic: "RRC (IY+$d),E", size: 4),    //  0x0B
            opCode(mnemonic: "RRC (IY+$d),H", size: 4),    //  0x0C
            opCode(mnemonic: "RRC (IY+$d),L", size: 4),    //  0x0D
            opCode(mnemonic: "RRC (IY+$d)", size: 4),    //  0x0E
            opCode(mnemonic: "RRC (IY+$d),A", size: 4),    //  0x0F
            opCode(mnemonic: "RL (IY+$d),B", size: 4),    //  0x10
            opCode(mnemonic: "RL (IY+$d),C", size: 4),    //  0x11
            opCode(mnemonic: "RL (IY+$d),D", size: 4),    //  0x12
            opCode(mnemonic: "RL (IY+$d),E", size: 4),    //  0x13
            opCode(mnemonic: "RL (IY+$d),H", size: 4),    //  0x14
            opCode(mnemonic: "RL (IY+$d),L", size: 4),    //  0x15
            opCode(mnemonic: "RL (IY+$d)", size: 4),    //  0x16
            opCode(mnemonic: "RL (IY+$d),A", size: 4),    //  0x17
            opCode(mnemonic: "RR (IY+$d),B", size: 4),    //  0x18
            opCode(mnemonic: "RR (IY+$d),C", size: 4),    //  0x19
            opCode(mnemonic: "RR (IY+$d),D", size: 4),    //  0x1A
            opCode(mnemonic: "RR (IY+$d),E", size: 4),    //  0x1B
            opCode(mnemonic: "RR (IY+$d),H", size: 4),    //  0x1C
            opCode(mnemonic: "RR (IY+$d),L", size: 4),    //  0x1D
            opCode(mnemonic: "RR (IY+$d)", size: 4),    //  0x1E
            opCode(mnemonic: "RR (IY+$d),A", size: 4),    //  0x1F
            opCode(mnemonic: "SLA (IY+$d),B", size: 4),    //  0x20
            opCode(mnemonic: "SLA (IY+$d),C", size: 4),    //  0x21
            opCode(mnemonic: "SLA (IY+$d),D", size: 4),    //  0x22
            opCode(mnemonic: "SLA (IY+$d),E", size: 4),    //  0x23
            opCode(mnemonic: "SLA (IY+$d),H", size: 4),    //  0x24
            opCode(mnemonic: "SLA (IY+$d),L", size: 4),    //  0x25
            opCode(mnemonic: "SLA (IY+$d)", size: 4),    //  0x26
            opCode(mnemonic: "SLA (IY+$d),A", size: 4),    //  0x27
            opCode(mnemonic: "SRA (IY+$d),B", size: 4),    //  0x28
            opCode(mnemonic: "SRA (IY+$d),C", size: 4),    //  0x29
            opCode(mnemonic: "SRA (IY+$d),D", size: 4),    //  0x2A
            opCode(mnemonic: "SRA (IY+$d),E", size: 4),    //  0x2B
            opCode(mnemonic: "SRA (IY+$d),H", size: 4),    //  0x2C
            opCode(mnemonic: "SRA (IY+$d),L", size: 4),    //  0x2D
            opCode(mnemonic: "SRA (IY+$d)", size: 4),    //  0x2E
            opCode(mnemonic: "SRA (IY+$d),A", size: 4),    //  0x2F
            opCode(mnemonic: "SLL (IY+$d),B", size: 4),    //  0x30
            opCode(mnemonic: "SLL (IY+$d),C", size: 4),    //  0x31
            opCode(mnemonic: "SLL (IY+$d),D", size: 4),    //  0x32
            opCode(mnemonic: "SLL (IY+$d),E", size: 4),    //  0x33
            opCode(mnemonic: "SLL (IY+$d),H", size: 4),    //  0x34
            opCode(mnemonic: "SLL (IY+$d),L", size: 4),    //  0x35
            opCode(mnemonic: "SLL (IY+$d)", size: 4),    //  0x36
            opCode(mnemonic: "SLL (IY+$d),A", size: 4),    //  0x37
            opCode(mnemonic: "SRL (IY+$d),B", size: 4),    //  0x38
            opCode(mnemonic: "SRL (IY+$d),C", size: 4),    //  0x39
            opCode(mnemonic: "SRL (IY+$d),D", size: 4),    //  0x3A
            opCode(mnemonic: "SRL (IY+$d),E", size: 4),    //  0x3B
            opCode(mnemonic: "SRL (IY+$d),H", size: 4),    //  0x3C
            opCode(mnemonic: "SRL (IY+$d),L", size: 4),    //  0x3D
            opCode(mnemonic: "SRL (IY+$d)", size: 4),    //  0x3E
            opCode(mnemonic: "SRL (IY+$d),A", size: 4),    //  0x3F
            opCode(mnemonic: "BIT 0,(IY+$d)", size: 4),    //  0x40
            opCode(mnemonic: "BIT 0,(IY+$d)", size: 4),    //  0x41
            opCode(mnemonic: "BIT 0,(IY+$d)", size: 4),    //  0x42
            opCode(mnemonic: "BIT 0,(IY+$d)", size: 4),    //  0x43
            opCode(mnemonic: "BIT 0,(IY+$d)", size: 4),    //  0x44
            opCode(mnemonic: "BIT 0,(IY+$d)", size: 4),    //  0x45
            opCode(mnemonic: "BIT 0,(IY+$d)", size: 4),    //  0x46
            opCode(mnemonic: "BIT 0,(IY+$d)", size: 4),    //  0x47
            opCode(mnemonic: "BIT 1,(IY+$d)", size: 4),    //  0x48
            opCode(mnemonic: "BIT 1,(IY+$d)", size: 4),    //  0x49
            opCode(mnemonic: "BIT 1,(IY+$d)", size: 4),    //  0x4A
            opCode(mnemonic: "BIT 1,(IY+$d)", size: 4),    //  0x4B
            opCode(mnemonic: "BIT 1,(IY+$d)", size: 4),    //  0x4C
            opCode(mnemonic: "BIT 1,(IY+$d)", size: 4),    //  0x4D
            opCode(mnemonic: "BIT 1,(IY+$d)", size: 4),    //  0x4E
            opCode(mnemonic: "BIT 1,(IY+$d)", size: 4),    //  0x4F
            opCode(mnemonic: "BIT 2,(IY+$d)", size: 4),    //  0x50
            opCode(mnemonic: "BIT 2,(IY+$d)", size: 4),    //  0x51
            opCode(mnemonic: "BIT 2,(IY+$d)", size: 4),    //  0x52
            opCode(mnemonic: "BIT 2,(IY+$d)", size: 4),    //  0x53
            opCode(mnemonic: "BIT 2,(IY+$d)", size: 4),    //  0x54
            opCode(mnemonic: "BIT 2,(IY+$d)", size: 4),    //  0x55
            opCode(mnemonic: "BIT 2,(IY+$d)", size: 4),    //  0x56
            opCode(mnemonic: "BIT 2,(IY+$d)", size: 4),    //  0x57
            opCode(mnemonic: "BIT 3,(IY+$d)", size: 4),    //  0x58
            opCode(mnemonic: "BIT 3,(IY+$d)", size: 4),    //  0x59
            opCode(mnemonic: "BIT 3,(IY+$d)", size: 4),    //  0x5A
            opCode(mnemonic: "BIT 3,(IY+$d)", size: 4),    //  0x5B
            opCode(mnemonic: "BIT 3,(IY+$d)", size: 4),    //  0x5C
            opCode(mnemonic: "BIT 3,(IY+$d)", size: 4),    //  0x5D
            opCode(mnemonic: "BIT 3,(IY+$d)", size: 4),    //  0x5E
            opCode(mnemonic: "BIT 3,(IY+$d)", size: 4),    //  0x5F
            opCode(mnemonic: "BIT 4,(IY+$d)", size: 4),    //  0x60
            opCode(mnemonic: "BIT 4,(IY+$d)", size: 4),    //  0x61
            opCode(mnemonic: "BIT 4,(IY+$d)", size: 4),    //  0x62
            opCode(mnemonic: "BIT 4,(IY+$d)", size: 4),    //  0x63
            opCode(mnemonic: "BIT 4,(IY+$d)", size: 4),    //  0x64
            opCode(mnemonic: "BIT 4,(IY+$d)", size: 4),    //  0x65
            opCode(mnemonic: "BIT 4,(IY+$d)", size: 4),    //  0x66
            opCode(mnemonic: "BIT 4,(IY+$d)", size: 4),    //  0x67
            opCode(mnemonic: "BIT 5,(IY+$d)", size: 4),    //  0x68
            opCode(mnemonic: "BIT 5,(IY+$d)", size: 4),    //  0x69
            opCode(mnemonic: "BIT 5,(IY+$d)", size: 4),    //  0x6A
            opCode(mnemonic: "BIT 5,(IY+$d)", size: 4),    //  0x6B
            opCode(mnemonic: "BIT 5,(IY+$d)", size: 4),    //  0x6C
            opCode(mnemonic: "BIT 5,(IY+$d)", size: 4),    //  0x6D
            opCode(mnemonic: "BIT 5,(IY+$d)", size: 4),    //  0x6E
            opCode(mnemonic: "BIT 5,(IY+$d)", size: 4),    //  0x6F
            opCode(mnemonic: "BIT 6,(IY+$d)", size: 4),    //  0x70
            opCode(mnemonic: "BIT 6,(IY+$d)", size: 4),    //  0x71
            opCode(mnemonic: "BIT 6,(IY+$d)", size: 4),    //  0x72
            opCode(mnemonic: "BIT 6,(IY+$d)", size: 4),    //  0x73
            opCode(mnemonic: "BIT 6,(IY+$d)", size: 4),    //  0x74
            opCode(mnemonic: "BIT 6,(IY+$d)", size: 4),    //  0x75
            opCode(mnemonic: "BIT 6,(IY+$d)", size: 4),    //  0x76
            opCode(mnemonic: "BIT 6,(IY+$d)", size: 4),    //  0x77
            opCode(mnemonic: "BIT 7,(IY+$d)", size: 4),    //  0x78
            opCode(mnemonic: "BIT 7,(IY+$d)", size: 4),    //  0x79
            opCode(mnemonic: "BIT 7,(IY+$d)", size: 4),    //  0x7A
            opCode(mnemonic: "BIT 7,(IY+$d)", size: 4),    //  0x7B
            opCode(mnemonic: "BIT 7,(IY+$d)", size: 4),    //  0x7C
            opCode(mnemonic: "BIT 7,(IY+$d)", size: 4),    //  0x7D
            opCode(mnemonic: "BIT 7,(IY+$d)", size: 4),    //  0x7E
            opCode(mnemonic: "BIT 7,(IY+$d)", size: 4),    //  0x7F
            opCode(mnemonic: "RES 0,(IY+$d),B", size: 4),    //  0x80
            opCode(mnemonic: "RES 0,(IY+$d),C", size: 4),    //  0x81
            opCode(mnemonic: "RES 0,(IY+$d),D", size: 4),    //  0x82
            opCode(mnemonic: "RES 0,(IY+$d),E", size: 4),    //  0x83
            opCode(mnemonic: "RES 0,(IY+$d),H", size: 4),    //  0x84
            opCode(mnemonic: "RES 0,(IY+$d),L", size: 4),    //  0x85
            opCode(mnemonic: "RES 0,(IY+$d)", size: 4),    //  0x86
            opCode(mnemonic: "RES 0,(IY+$d),A", size: 4),    //  0x87
            opCode(mnemonic: "RES 1,(IY+$d),B", size: 4),    //  0x88
            opCode(mnemonic: "RES 1,(IY+$d),C", size: 4),    //  0x89
            opCode(mnemonic: "RES 1,(IY+$d),D", size: 4),    //  0x8A
            opCode(mnemonic: "RES 1,(IY+$d),E", size: 4),    //  0x8B
            opCode(mnemonic: "RES 1,(IY+$d),H", size: 4),    //  0x8C
            opCode(mnemonic: "RES 1,(IY+$d),L", size: 4),    //  0x8D
            opCode(mnemonic: "RES 1,(IY+$d)", size: 4),    //  0x8E
            opCode(mnemonic: "RES 1,(IY+$d),A", size: 4),    //  0x8F
            opCode(mnemonic: "RES 2,(IY+$d),B", size: 4),    //  0x90
            opCode(mnemonic: "RES 2,(IY+$d),C", size: 4),    //  0x91
            opCode(mnemonic: "RES 2,(IY+$d),D", size: 4),    //  0x92
            opCode(mnemonic: "RES 2,(IY+$d),E", size: 4),    //  0x93
            opCode(mnemonic: "RES 2,(IY+$d),H", size: 4),    //  0x94
            opCode(mnemonic: "RES 2,(IY+$d),L", size: 4),    //  0x95
            opCode(mnemonic: "RES 2,(IY+$d)", size: 4),    //  0x96
            opCode(mnemonic: "RES 2,(IY+$d),A", size: 4),    //  0x97
            opCode(mnemonic: "RES 3,(IY+$d),B", size: 4),    //  0x98
            opCode(mnemonic: "RES 3,(IY+$d),C", size: 4),    //  0x99
            opCode(mnemonic: "RES 3,(IY+$d),D", size: 4),    //  0x9A
            opCode(mnemonic: "RES 3,(IY+$d),E", size: 4),    //  0x9B
            opCode(mnemonic: "RES 3,(IY+$d),H", size: 4),    //  0x9C
            opCode(mnemonic: "RES 3,(IY+$d),L", size: 4),    //  0x9D
            opCode(mnemonic: "RES 3,(IY+$d)", size: 4),    //  0x9E
            opCode(mnemonic: "RES 3,(IY+$d),A", size: 4),    //  0x9F
            opCode(mnemonic: "RES 4,(IY+$d),B", size: 4),    //  0xA0
            opCode(mnemonic: "RES 4,(IY+$d),C", size: 4),    //  0xA1
            opCode(mnemonic: "RES 4,(IY+$d),D", size: 4),    //  0xA2
            opCode(mnemonic: "RES 4,(IY+$d),E", size: 4),    //  0xA3
            opCode(mnemonic: "RES 4,(IY+$d),H", size: 4),    //  0xA4
            opCode(mnemonic: "RES 4,(IY+$d),L", size: 4),    //  0xA5
            opCode(mnemonic: "RES 4,(IY+$d)", size: 4),    //  0xA6
            opCode(mnemonic: "RES 4,(IY+$d),A", size: 4),    //  0xA7
            opCode(mnemonic: "RES 5,(IY+$d),B", size: 4),    //  0xA8
            opCode(mnemonic: "RES 5,(IY+$d),C", size: 4),    //  0xA9
            opCode(mnemonic: "RES 5,(IY+$d),D", size: 4),    //  0xAA
            opCode(mnemonic: "RES 5,(IY+$d),E", size: 4),    //  0xAB
            opCode(mnemonic: "RES 5,(IY+$d),H", size: 4),    //  0xAC
            opCode(mnemonic: "RES 5,(IY+$d),L", size: 4),    //  0xAD
            opCode(mnemonic: "RES 5,(IY+$d)", size: 4),    //  0xAE
            opCode(mnemonic: "RES 5,(IY+$d),A", size: 4),    //  0xAF
            opCode(mnemonic: "RES 6,(IY+$d),B", size: 4),    //  0xB0
            opCode(mnemonic: "RES 6,(IY+$d),C", size: 4),    //  0xB1
            opCode(mnemonic: "RES 6,(IY+$d),D", size: 4),    //  0xB2
            opCode(mnemonic: "RES 6,(IY+$d),E", size: 4),    //  0xB3
            opCode(mnemonic: "RES 6,(IY+$d),H", size: 4),    //  0xB4
            opCode(mnemonic: "RES 6,(IY+$d),L", size: 4),    //  0xB5
            opCode(mnemonic: "RES 6,(IY+$d)", size: 4),    //  0xB6
            opCode(mnemonic: "RES 6,(IY+$d),A", size: 4),    //  0xB7
            opCode(mnemonic: "RES 7,(IY+$d),B", size: 4),    //  0xB8
            opCode(mnemonic: "RES 7,(IY+$d),C", size: 4),    //  0xB9
            opCode(mnemonic: "RES 7,(IY+$d),D", size: 4),    //  0xBA
            opCode(mnemonic: "RES 7,(IY+$d),E", size: 4),    //  0xBB
            opCode(mnemonic: "RES 7,(IY+$d),H", size: 4),    //  0xBC
            opCode(mnemonic: "RES 7,(IY+$d),L", size: 4),    //  0xBD
            opCode(mnemonic: "RES 7,(IY+$d)", size: 4),    //  0xBE
            opCode(mnemonic: "RES 7,(IY+$d),A", size: 4),    //  0xBF
            opCode(mnemonic: "SET 0,(IY+$d),B", size: 4),    //  0xC0
            opCode(mnemonic: "SET 0,(IY+$d),C", size: 4),    //  0xC1
            opCode(mnemonic: "SET 0,(IY+$d),D", size: 4),    //  0xC2
            opCode(mnemonic: "SET 0,(IY+$d),E", size: 4),    //  0xC3
            opCode(mnemonic: "SET 0,(IY+$d),H", size: 4),    //  0xC4
            opCode(mnemonic: "SET 0,(IY+$d),L", size: 4),    //  0xC5
            opCode(mnemonic: "SET 0,(IY+$d)", size: 4),    //  0xC6
            opCode(mnemonic: "SET 0,(IY+$d),A", size: 4),    //  0xC7
            opCode(mnemonic: "SET 1,(IY+$d),B", size: 4),    //  0xC8
            opCode(mnemonic: "SET 1,(IY+$d),C", size: 4),    //  0xC9
            opCode(mnemonic: "SET 1,(IY+$d),D", size: 4),    //  0xCA
            opCode(mnemonic: "SET 1,(IY+$d),E", size: 4),    //  0xCB
            opCode(mnemonic: "SET 1,(IY+$d),H", size: 4),    //  0xCC
            opCode(mnemonic: "SET 1,(IY+$d),L", size: 4),    //  0xCD
            opCode(mnemonic: "SET 1,(IY+$d)", size: 4),    //  0xCE
            opCode(mnemonic: "SET 1,(IY+$d),A", size: 4),    //  0xCF
            opCode(mnemonic: "SET 2,(IY+$d),B", size: 4),    //  0xD0
            opCode(mnemonic: "SET 2,(IY+$d),C", size: 4),    //  0xD1
            opCode(mnemonic: "SET 2,(IY+$d),D", size: 4),    //  0xD2
            opCode(mnemonic: "SET 2,(IY+$d),E", size: 4),    //  0xD3
            opCode(mnemonic: "SET 2,(IY+$d),H", size: 4),    //  0xD4
            opCode(mnemonic: "SET 2,(IY+$d),L", size: 4),    //  0xD5
            opCode(mnemonic: "SET 2,(IY+$d)", size: 4),    //  0xD6
            opCode(mnemonic: "SET 2,(IY+$d),A", size: 4),    //  0xD7
            opCode(mnemonic: "SET 3,(IY+$d),B", size: 4),    //  0xD8
            opCode(mnemonic: "SET 3,(IY+$d),C", size: 4),    //  0xD9
            opCode(mnemonic: "SET 3,(IY+$d),D", size: 4),    //  0xDA
            opCode(mnemonic: "SET 3,(IY+$d),E", size: 4),    //  0xDB
            opCode(mnemonic: "SET 3,(IY+$d),H", size: 4),    //  0xDC
            opCode(mnemonic: "SET 3,(IY+$d),L", size: 4),    //  0xDD
            opCode(mnemonic: "SET 3,(IY+$d)", size: 4),    //  0xDE
            opCode(mnemonic: "SET 3,(IY+$d),A", size: 4),    //  0xDF
            opCode(mnemonic: "SET 4,(IY+$d),B", size: 4),    //  0xE0
            opCode(mnemonic: "SET 4,(IY+$d),C", size: 4),    //  0xE1
            opCode(mnemonic: "SET 4,(IY+$d),D", size: 4),    //  0xE2
            opCode(mnemonic: "SET 4,(IY+$d),E", size: 4),    //  0xE3
            opCode(mnemonic: "SET 4,(IY+$d),H", size: 4),    //  0xE4
            opCode(mnemonic: "SET 4,(IY+$d),L", size: 4),    //  0xE5
            opCode(mnemonic: "SET 4,(IY+$d)", size: 4),    //  0xE6
            opCode(mnemonic: "SET 4,(IY+$d),A", size: 4),    //  0xE7
            opCode(mnemonic: "SET 5,(IY+$d),B", size: 4),    //  0xE8
            opCode(mnemonic: "SET 5,(IY+$d),C", size: 4),    //  0xE9
            opCode(mnemonic: "SET 5,(IY+$d),D", size: 4),    //  0xEA
            opCode(mnemonic: "SET 5,(IY+$d),E", size: 4),    //  0xEB
            opCode(mnemonic: "SET 5,(IY+$d),H", size: 4),    //  0xEC
            opCode(mnemonic: "SET 5,(IY+$d),L", size: 4),    //  0xED
            opCode(mnemonic: "SET 5,(IY+$d)", size: 4),    //  0xEE
            opCode(mnemonic: "SET 5,(IY+$d),A", size: 4),    //  0xEF
            opCode(mnemonic: "SET 6,(IY+$d),B", size: 4),    //  0xF0
            opCode(mnemonic: "SET 6,(IY+$d),C", size: 4),    //  0xF1
            opCode(mnemonic: "SET 6,(IY+$d),D", size: 4),    //  0xF2
            opCode(mnemonic: "SET 6,(IY+$d),E", size: 4),    //  0xF3
            opCode(mnemonic: "SET 6,(IY+$d),H", size: 4),    //  0xF4
            opCode(mnemonic: "SET 6,(IY+$d),L", size: 4),    //  0xF5
            opCode(mnemonic: "SET 6,(IY+$d)", size: 4),    //  0xF6
            opCode(mnemonic: "SET 6,(IY+$d),A", size: 4),    //  0xF7
            opCode(mnemonic: "SET 7,(IY+$d),B", size: 4),    //  0xF8
            opCode(mnemonic: "SET 7,(IY+$d),C", size: 4),    //  0xF9
            opCode(mnemonic: "SET 7,(IY+$d),D", size: 4),    //  0xFA
            opCode(mnemonic: "SET 7,(IY+$d),E", size: 4),    //  0xFB
            opCode(mnemonic: "SET 7,(IY+$d),H", size: 4),    //  0xFC
            opCode(mnemonic: "SET 7,(IY+$d),L", size: 4),    //  0xFD
            opCode(mnemonic: "SET 7,(IY+$d)", size: 4),    //  0xFE
            opCode(mnemonic: "SET 7,(IY+$d),A", size: 4)    //  0xFF
        ]
    
    func decodeMnemonic(mnemonic: String, dataBytes: [UInt8]) -> String
    {
        var tempString : String
        
        switch dataBytes.count
        {
            case 1 :
                tempString = mnemonic.replacingOccurrences(of: "$n", with: "0x"+String(format:"%02X",dataBytes[0]))
                tempString = tempString.replacingOccurrences(of: "$d", with: "0x"+String(format:"%02X",dataBytes[0]))
            case 2 :
                tempString = mnemonic.replacingOccurrences(of: "$nn", with: "0x"+String(format:"%04X",UInt16(dataBytes[1]) << 8 | UInt16(dataBytes[0])))
                tempString = tempString.replacingOccurrences(of: "$d", with: "0x"+String(format:"%02X",dataBytes[0]))
                tempString = tempString.replacingOccurrences(of: "$n", with: "0x"+String(format:"%02X",dataBytes[1]))
            default: tempString = mnemonic
        }
        return tempString
    }
    
    func decodeInstructions(opCodes: [UInt8], dataBytes: [UInt8]) -> String
    {
        var tempString : String
        
        guard !opCodes.isEmpty else { return "" }
    
        switch opCodes[0]
            {
                case 0x00...0xCA,0xCD...0xDC,0xDE...0xEC,0xEE...0xFC,0xFE...0xFF : tempString = decodeMnemonic(mnemonic: singleOpcode[Int(opCodes[0])].mnemonic,dataBytes: dataBytes)
                case 0xCB : tempString = decodeMnemonic(mnemonic: CBPrefixOpcode[Int(opCodes[1])].mnemonic,dataBytes: dataBytes)
                case 0xDD :
                switch opCodes[1]
                {
                    case 0xCB : tempString = decodeMnemonic(mnemonic: DDCBPrefixOpcode[Int(opCodes[3])].mnemonic,dataBytes: dataBytes)
                    default : tempString = decodeMnemonic(mnemonic: DDPrefixOpcode[Int(opCodes[1])].mnemonic,dataBytes: dataBytes)
                }
                case 0xED : tempString = decodeMnemonic(mnemonic: EDPrefixOpcode[Int(opCodes[1])].mnemonic,dataBytes: dataBytes)
                case 0xFD :
                    switch opCodes[1]
                    {
                        case 0xCB : tempString = decodeMnemonic(mnemonic: FDCBPrefixOpcode[Int(opCodes[3])].mnemonic,dataBytes: dataBytes)
                        default : tempString = decodeMnemonic(mnemonic: FDPrefixOpcode[Int(opCodes[1])].mnemonic,dataBytes: dataBytes)
                    }
                default: tempString = ""
            }
        return tempString.padding(toLength: 16, withPad: " ", startingAt: 0)
    }
}
