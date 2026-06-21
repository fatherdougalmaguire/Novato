import Foundation

struct Z80Disassembler
{
    enum dataPatterns
    {
        case noData
        case byte1N
        case byte1D
        case byte1NN
        case byte1Byte2
        case byte1Byte2N
        case byte1Byte2D
        case byte1Byte2DN
        case byte1Byte2NN
        case byte1Byte2DByte4
    }
    
    struct opCode
    {
        var mnemonic: String
        var dataPattern: dataPatterns
    }
    
        let singleOpcode: [opCode] =
        [
            opCode(mnemonic: "NOP", dataPattern: dataPatterns.noData),          // 0x00
            opCode(mnemonic: "LD BC,$nn", dataPattern: dataPatterns.byte1NN),    // 0x01
            opCode(mnemonic: "LD (BC),A", dataPattern: dataPatterns.noData),    // 0x02
            opCode(mnemonic: "INC BC", dataPattern: dataPatterns.noData),       // 0x03
            opCode(mnemonic: "INC B", dataPattern: dataPatterns.noData),        // 0x04
            opCode(mnemonic: "DEC B", dataPattern: dataPatterns.noData),        // 0x05
            opCode(mnemonic: "LD B,$n", dataPattern: dataPatterns.byte1N),      // 0x06
            opCode(mnemonic: "RLCA", dataPattern: dataPatterns.noData),         // 0x07
            opCode(mnemonic: "EX AF,AF'", dataPattern: dataPatterns.noData),    // 0x08
            opCode(mnemonic: "ADD HL,BC", dataPattern: dataPatterns.noData),    // 0x09
            opCode(mnemonic: "LD A,(BC)", dataPattern: dataPatterns.noData),    // 0x0A
            opCode(mnemonic: "DEC BC", dataPattern: dataPatterns.noData),       // 0x0B
            opCode(mnemonic: "INC C", dataPattern: dataPatterns.noData),        // 0x0C
            opCode(mnemonic: "DEC C", dataPattern: dataPatterns.noData),        // 0x0D
            opCode(mnemonic: "LD C,$n", dataPattern: dataPatterns.byte1N),      // 0x0E
            opCode(mnemonic: "RRCA", dataPattern: dataPatterns.noData),         // 0x0F
            opCode(mnemonic: "DJNZ $d", dataPattern: dataPatterns.byte1D),      // 0x10
            opCode(mnemonic: "LD DE,$nn", dataPattern: dataPatterns.byte1NN),    // 0x11
            opCode(mnemonic: "LD (DE),A", dataPattern: dataPatterns.noData),    // 0x12
            opCode(mnemonic: "INC DE", dataPattern: dataPatterns.noData),       // 0x13
            opCode(mnemonic: "INC D", dataPattern: dataPatterns.noData),        // 0x14
            opCode(mnemonic: "DEC D", dataPattern: dataPatterns.noData),        // 0x15
            opCode(mnemonic: "LD D,$n", dataPattern: dataPatterns.byte1N),      // 0x16
            opCode(mnemonic: "RLA", dataPattern: dataPatterns.noData),          // 0x17
            opCode(mnemonic: "JR $d", dataPattern: dataPatterns.byte1D),       // 0x18
            opCode(mnemonic: "ADD HL,DE", dataPattern: dataPatterns.noData),    // 0x19
            opCode(mnemonic: "LD A,(DE)", dataPattern: dataPatterns.noData),    // 0x1A
            opCode(mnemonic: "DEC DE", dataPattern: dataPatterns.noData),       // 0x1B
            opCode(mnemonic: "INC E", dataPattern: dataPatterns.noData),        // 0x1C
            opCode(mnemonic: "DEC E", dataPattern: dataPatterns.noData),        // 0x1D
            opCode(mnemonic: "LD E,$n", dataPattern: dataPatterns.byte1N),      // 0x1E
            opCode(mnemonic: "RRA", dataPattern: dataPatterns.noData),          // 0x1F
            opCode(mnemonic: "JR NZ,$d", dataPattern: dataPatterns.byte1D),     // 0x20
            opCode(mnemonic: "LD HL,$nn", dataPattern: dataPatterns.byte1NN),     // 0x21
            opCode(mnemonic: "LD ($nn),HL", dataPattern: dataPatterns.byte1NN),  // 0x22
            opCode(mnemonic: "INC HL", dataPattern: dataPatterns.noData),       // 0x23
            opCode(mnemonic: "INC H", dataPattern: dataPatterns.noData),        // 0x24
            opCode(mnemonic: "DEC H", dataPattern: dataPatterns.noData),        // 0x25
            opCode(mnemonic: "LD H,$n", dataPattern: dataPatterns.byte1N),      // 0x26
            opCode(mnemonic: "DAA", dataPattern: dataPatterns.noData),          // 0x27
            opCode(mnemonic: "JR Z,$d", dataPattern: dataPatterns.byte1D),      // 0x28
            opCode(mnemonic: "ADD HL,HL", dataPattern: dataPatterns.noData),    // 0x29
            opCode(mnemonic: "LD HL,($nn)", dataPattern: dataPatterns.byte1NN),   // 0x2A
            opCode(mnemonic: "DEC HL", dataPattern: dataPatterns.noData),       // 0x2B
            opCode(mnemonic: "INC L", dataPattern: dataPatterns.noData),        // 0x2C
            opCode(mnemonic: "DEC L", dataPattern: dataPatterns.noData),        // 0x2D
            opCode(mnemonic: "LD L,$n", dataPattern: dataPatterns.byte1N),     // 0x2E
            opCode(mnemonic: "CPL", dataPattern: dataPatterns.noData),          // 0x2F
            opCode(mnemonic: "JR NC,$d", dataPattern: dataPatterns.byte1D),      // 0x30
            opCode(mnemonic: "LD SP,$nn", dataPattern: dataPatterns.byte1NN),    // 0x31
            opCode(mnemonic: "LD ($nn),A", dataPattern: dataPatterns.byte1NN),   // 0x32
            opCode(mnemonic: "INC SP", dataPattern: dataPatterns.noData),       // 0x33
            opCode(mnemonic: "INC (HL)", dataPattern: dataPatterns.noData),     // 0x34
            opCode(mnemonic: "DEC (HL)", dataPattern: dataPatterns.noData),     // 0x35
            opCode(mnemonic: "LD (HL),$n", dataPattern: dataPatterns.byte1N),     // 0x36
            opCode(mnemonic: "SCF", dataPattern: dataPatterns.noData),          // 0x37
            opCode(mnemonic: "JR C,$d", dataPattern: dataPatterns.byte1D),      // 0x38
            opCode(mnemonic: "ADD HL,SP", dataPattern: dataPatterns.noData),    // 0x39
            opCode(mnemonic: "LD A,($nn)", dataPattern: dataPatterns.byte1NN),    // 0x3A
            opCode(mnemonic: "DEC SP", dataPattern: dataPatterns.noData),       // 0x3B
            opCode(mnemonic: "INC A", dataPattern: dataPatterns.noData),        // 0x3C
            opCode(mnemonic: "DEC A", dataPattern: dataPatterns.noData),      // 0x3D
            opCode(mnemonic: "LD A,$n", dataPattern: dataPatterns.byte1N),    // 0x3E
            opCode(mnemonic: "CCF", dataPattern: dataPatterns.noData),       // 0x3F
            opCode(mnemonic: "LD B,B", dataPattern: dataPatterns.noData),    // 0x40
            opCode(mnemonic: "LD B,C", dataPattern: dataPatterns.noData),    // 0x41
            opCode(mnemonic: "LD B,D", dataPattern: dataPatterns.noData),    // 0x42
            opCode(mnemonic: "LD B,E", dataPattern: dataPatterns.noData),    // 0x43
            opCode(mnemonic: "LD B,H", dataPattern: dataPatterns.noData),    // 0x44
            opCode(mnemonic: "LD B,L", dataPattern: dataPatterns.noData),    // 0x45
            opCode(mnemonic: "LD B,(HL)", dataPattern: dataPatterns.noData), // 0x46
            opCode(mnemonic: "LD B,A", dataPattern: dataPatterns.noData),    // 0x47
            opCode(mnemonic: "LD C,B", dataPattern: dataPatterns.noData),    // 0x48
            opCode(mnemonic: "LD C,C", dataPattern: dataPatterns.noData),    // 0x49
            opCode(mnemonic: "LD C,D", dataPattern: dataPatterns.noData),    // 0x4A
            opCode(mnemonic: "LD C,E", dataPattern: dataPatterns.noData),    // 0x4B
            opCode(mnemonic: "LD C,H", dataPattern: dataPatterns.noData),    // 0x4C
            opCode(mnemonic: "LD C,L", dataPattern: dataPatterns.noData),    // 0x4D
            opCode(mnemonic: "LD C,(HL)", dataPattern: dataPatterns.noData),    // 0x4E
            opCode(mnemonic: "LD C,A", dataPattern: dataPatterns.noData),    // 0x4F
            opCode(mnemonic: "LD D,B", dataPattern: dataPatterns.noData),    // 0x50
            opCode(mnemonic: "LD D,C", dataPattern: dataPatterns.noData),    // 0x51
            opCode(mnemonic: "LD D,D", dataPattern: dataPatterns.noData),    // 0x52
            opCode(mnemonic: "LD D,E", dataPattern: dataPatterns.noData),    // 0x53
            opCode(mnemonic: "LD D,H", dataPattern: dataPatterns.noData),    // 0x54
            opCode(mnemonic: "LD D,L", dataPattern: dataPatterns.noData),    // 0x55
            opCode(mnemonic: "LD D,(HL)", dataPattern: dataPatterns.noData),    // 0x56
            opCode(mnemonic: "LD D,A", dataPattern: dataPatterns.noData),    // 0x57
            opCode(mnemonic: "LD E,B", dataPattern: dataPatterns.noData),    // 0x58
            opCode(mnemonic: "LD E,C", dataPattern: dataPatterns.noData),    // 0x59
            opCode(mnemonic: "LD E,D", dataPattern: dataPatterns.noData),    // 0x5A
            opCode(mnemonic: "LD E,E", dataPattern: dataPatterns.noData),    // 0x5B
            opCode(mnemonic: "LD E,H", dataPattern: dataPatterns.noData),    // 0x5C
            opCode(mnemonic: "LD E,L", dataPattern: dataPatterns.noData),    // 0x5D
            opCode(mnemonic: "LD E,(HL)", dataPattern: dataPatterns.noData),    // 0x5E
            opCode(mnemonic: "LD E,A", dataPattern: dataPatterns.noData),    // 0x5F
            opCode(mnemonic: "LD H,B", dataPattern: dataPatterns.noData),    // 0x60
            opCode(mnemonic: "LD H,C", dataPattern: dataPatterns.noData),    // 0x61
            opCode(mnemonic: "LD H,D", dataPattern: dataPatterns.noData),    // 0x62
            opCode(mnemonic: "LD H,E", dataPattern: dataPatterns.noData),    // 0x63
            opCode(mnemonic: "LD H,H", dataPattern: dataPatterns.noData),    // 0x64
            opCode(mnemonic: "LD H,L", dataPattern: dataPatterns.noData),    // 0x65
            opCode(mnemonic: "LD H,(HL)", dataPattern: dataPatterns.noData),    // 0x66
            opCode(mnemonic: "LD H,A", dataPattern: dataPatterns.noData),    // 0x67
            opCode(mnemonic: "LD L,B", dataPattern: dataPatterns.noData),    // 0x68
            opCode(mnemonic: "LD L,C", dataPattern: dataPatterns.noData),    // 0x69
            opCode(mnemonic: "LD L,D", dataPattern: dataPatterns.noData),    // 0x6A
            opCode(mnemonic: "LD L,E", dataPattern: dataPatterns.noData),    // 0x6B
            opCode(mnemonic: "LD L,H", dataPattern: dataPatterns.noData),    // 0x6C
            opCode(mnemonic: "LD L,L", dataPattern: dataPatterns.noData),    // 0x6D
            opCode(mnemonic: "LD L,(HL)", dataPattern: dataPatterns.noData),    // 0x6E
            opCode(mnemonic: "LD L,A", dataPattern: dataPatterns.noData),    // 0x6F
            opCode(mnemonic: "LD (HL),B", dataPattern: dataPatterns.noData),    // 0x70
            opCode(mnemonic: "LD (HL),C", dataPattern: dataPatterns.noData),    // 0x71
            opCode(mnemonic: "LD (HL),D", dataPattern: dataPatterns.noData),    // 0x72
            opCode(mnemonic: "LD (HL),E", dataPattern: dataPatterns.noData),    // 0x73
            opCode(mnemonic: "LD (HL),H", dataPattern: dataPatterns.noData),    // 0x74
            opCode(mnemonic: "LD (HL),L", dataPattern: dataPatterns.noData),    // 0x75
            opCode(mnemonic: "HALT", dataPattern: dataPatterns.noData),    // 0x76
            opCode(mnemonic: "LD (HL),A", dataPattern: dataPatterns.noData),    // 0x77
            opCode(mnemonic: "LD A,B", dataPattern: dataPatterns.noData),    // 0x78
            opCode(mnemonic: "LD A,C", dataPattern: dataPatterns.noData),    // 0x79
            opCode(mnemonic: "LD A,D", dataPattern: dataPatterns.noData),    // 0x7A
            opCode(mnemonic: "LD A,E", dataPattern: dataPatterns.noData),    // 0x7B
            opCode(mnemonic: "LD A,H", dataPattern: dataPatterns.noData),    // 0x7C
            opCode(mnemonic: "LD A,L", dataPattern: dataPatterns.noData),    // 0x7D
            opCode(mnemonic: "LD A,(HL)", dataPattern: dataPatterns.noData),    // 0x7E
            opCode(mnemonic: "LD A,A", dataPattern: dataPatterns.noData),    // 0x7F
            opCode(mnemonic: "ADD A,B", dataPattern: dataPatterns.noData),    // 0x80
            opCode(mnemonic: "ADD A,C", dataPattern: dataPatterns.noData),    // 0x81
            opCode(mnemonic: "ADD A,D", dataPattern: dataPatterns.noData),    // 0x82
            opCode(mnemonic: "ADD A,E", dataPattern: dataPatterns.noData),    // 0x83
            opCode(mnemonic: "ADD A,H", dataPattern: dataPatterns.noData),    // 0x84
            opCode(mnemonic: "ADD A,L", dataPattern: dataPatterns.noData),    // 0x85
            opCode(mnemonic: "ADD A,(HL)", dataPattern: dataPatterns.noData),    // 0x86
            opCode(mnemonic: "ADD A,A", dataPattern: dataPatterns.noData),    // 0x87
            opCode(mnemonic: "ADC A,B", dataPattern: dataPatterns.noData),    // 0x88
            opCode(mnemonic: "ADC A,C", dataPattern: dataPatterns.noData),    // 0x89
            opCode(mnemonic: "ADC A,D", dataPattern: dataPatterns.noData),    // 0x8A
            opCode(mnemonic: "ADC A,E", dataPattern: dataPatterns.noData),    // 0x8B
            opCode(mnemonic: "ADC A,H", dataPattern: dataPatterns.noData),    // 0x8C
            opCode(mnemonic: "ADC A,L", dataPattern: dataPatterns.noData),    // 0x8D
            opCode(mnemonic: "ADC A,(HL)", dataPattern: dataPatterns.noData),    // 0x8E
            opCode(mnemonic: "ADC A,A", dataPattern: dataPatterns.noData),    // 0x8F
            opCode(mnemonic: "SUB B", dataPattern: dataPatterns.noData),    // 0x90
            opCode(mnemonic: "SUB C", dataPattern: dataPatterns.noData),    // 0x91
            opCode(mnemonic: "SUB D", dataPattern: dataPatterns.noData),    // 0x92
            opCode(mnemonic: "SUB E", dataPattern: dataPatterns.noData),    // 0x93
            opCode(mnemonic: "SUB H", dataPattern: dataPatterns.noData),        // 0x94
            opCode(mnemonic: "SUB L", dataPattern: dataPatterns.noData),        // 0x95
            opCode(mnemonic: "SUB (HL)", dataPattern: dataPatterns.noData),     // 0x96
            opCode(mnemonic: "SUB A", dataPattern: dataPatterns.noData),        // 0x97
            opCode(mnemonic: "SBC A,B", dataPattern: dataPatterns.noData),    // 0x98
            opCode(mnemonic: "SBC A,C", dataPattern: dataPatterns.noData),    // 0x99
            opCode(mnemonic: "SBC A,D", dataPattern: dataPatterns.noData),    // 0x9A
            opCode(mnemonic: "SBC A,E", dataPattern: dataPatterns.noData),    // 0x9B
            opCode(mnemonic: "SBC A,H", dataPattern: dataPatterns.noData),    // 0x9C
            opCode(mnemonic: "SBC A,L", dataPattern: dataPatterns.noData),    // 0x9D
            opCode(mnemonic: "SBC A,(HL)", dataPattern: dataPatterns.noData),    // 0x9E
            opCode(mnemonic: "SBC A,A", dataPattern: dataPatterns.noData),    // 0x9F
            opCode(mnemonic: "AND B", dataPattern: dataPatterns.noData),    // 0xA0
            opCode(mnemonic: "AND C", dataPattern: dataPatterns.noData),    // 0xA1
            opCode(mnemonic: "AND D", dataPattern: dataPatterns.noData),    // 0xA2
            opCode(mnemonic: "AND E", dataPattern: dataPatterns.noData),    // 0xA3
            opCode(mnemonic: "AND H", dataPattern: dataPatterns.noData),    // 0xA4
            opCode(mnemonic: "AND L", dataPattern: dataPatterns.noData),    // 0xA5
            opCode(mnemonic: "AND (HL)", dataPattern: dataPatterns.noData),    // 0xA6
            opCode(mnemonic: "AND A", dataPattern: dataPatterns.noData),    // 0xA7
            opCode(mnemonic: "XOR B", dataPattern: dataPatterns.noData),    // 0xA8
            opCode(mnemonic: "XOR C", dataPattern: dataPatterns.noData),    // 0xA9
            opCode(mnemonic: "XOR D", dataPattern: dataPatterns.noData),    // 0xAA
            opCode(mnemonic: "XOR E", dataPattern: dataPatterns.noData),    // 0xAB
            opCode(mnemonic: "XOR H", dataPattern: dataPatterns.noData),    // 0xAC
            opCode(mnemonic: "XOR L", dataPattern: dataPatterns.noData),    // 0xAD
            opCode(mnemonic: "XOR (HL)", dataPattern: dataPatterns.noData),    // 0xAE
            opCode(mnemonic: "XOR A", dataPattern: dataPatterns.noData),    // 0xAF
            opCode(mnemonic: "OR B", dataPattern: dataPatterns.noData),    // 0xB0
            opCode(mnemonic: "OR C", dataPattern: dataPatterns.noData),    // 0xB1
            opCode(mnemonic: "OR D", dataPattern: dataPatterns.noData),    // 0xB2
            opCode(mnemonic: "OR E", dataPattern: dataPatterns.noData),    // 0xB3
            opCode(mnemonic: "OR H", dataPattern: dataPatterns.noData),    // 0xB4
            opCode(mnemonic: "OR L", dataPattern: dataPatterns.noData),    // 0xB5
            opCode(mnemonic: "OR (HL)", dataPattern: dataPatterns.noData),    // 0xB6
            opCode(mnemonic: "OR A", dataPattern: dataPatterns.noData),    // 0xB7
            opCode(mnemonic: "CP B", dataPattern: dataPatterns.noData),    // 0xB8
            opCode(mnemonic: "CP C", dataPattern: dataPatterns.noData),    // 0xB9
            opCode(mnemonic: "CP D", dataPattern: dataPatterns.noData),    // 0xBA
            opCode(mnemonic: "CP E", dataPattern: dataPatterns.noData),    // 0xBB
            opCode(mnemonic: "CP H", dataPattern: dataPatterns.noData),    // 0xBC
            opCode(mnemonic: "CP L", dataPattern: dataPatterns.noData),    // 0xBD
            opCode(mnemonic: "CP (HL)", dataPattern: dataPatterns.noData),    // 0xBE
            opCode(mnemonic: "CP A", dataPattern: dataPatterns.noData),    // 0xBF
            opCode(mnemonic: "RET NZ", dataPattern: dataPatterns.noData),    // 0xC0
            opCode(mnemonic: "POP BC", dataPattern: dataPatterns.noData),    // 0xC1
            opCode(mnemonic: "JP NZ,$nn", dataPattern: dataPatterns.byte1NN),     // 0xC2
            opCode(mnemonic: "JP $nn", dataPattern: dataPatterns.byte1NN),    // 0xC3
            opCode(mnemonic: "CALL NZ,$nn", dataPattern: dataPatterns.byte1NN),    // 0xC4
            opCode(mnemonic: "PUSH BC", dataPattern: dataPatterns.noData),    // 0xC5
            opCode(mnemonic: "ADD A,$n", dataPattern: dataPatterns.byte1N),    // 0xC6
            opCode(mnemonic: "RST 0x00", dataPattern: dataPatterns.noData),    // 0xC7
            opCode(mnemonic: "RET Z", dataPattern: dataPatterns.noData),    // 0xC8
            opCode(mnemonic: "RET", dataPattern: dataPatterns.noData),    // 0xC9
            opCode(mnemonic: "JP Z,$nn", dataPattern: dataPatterns.byte1NN),    // 0xCA
            opCode(mnemonic: "*CB prefix", dataPattern: dataPatterns.noData),    // 0xCB
            opCode(mnemonic: "CALL Z,$nn", dataPattern: dataPatterns.byte1NN),    // 0xCC
            opCode(mnemonic: "CALL $nn", dataPattern: dataPatterns.byte1NN),    // 0xCD
            opCode(mnemonic: "ADC A,$n", dataPattern: dataPatterns.byte1N),    // 0xCE
            opCode(mnemonic: "RST 0x08", dataPattern: dataPatterns.noData),    // 0xCF
            opCode(mnemonic: "RET NC", dataPattern: dataPatterns.noData),    // 0xD0
            opCode(mnemonic: "POP DE", dataPattern: dataPatterns.noData),    // 0xD1
            opCode(mnemonic: "JP NC,$nn", dataPattern: dataPatterns.byte1NN),   // 0xD2
            opCode(mnemonic: "OUT ($n),A", dataPattern: dataPatterns.byte1N),     // 0xD3
            opCode(mnemonic: "CALL NC,$nn", dataPattern: dataPatterns.byte1NN),     // 0xD4
            opCode(mnemonic: "PUSH DE", dataPattern: dataPatterns.noData),    // 0xD5
            opCode(mnemonic: "SUB $n", dataPattern: dataPatterns.byte1N),   // 0xD6
            opCode(mnemonic: "RST 0x10", dataPattern: dataPatterns.noData),    // 0xD7
            opCode(mnemonic: "RET C", dataPattern: dataPatterns.noData),    // 0xD8
            opCode(mnemonic: "EXX", dataPattern: dataPatterns.noData),    // 0xD9
            opCode(mnemonic: "JP C,$nn", dataPattern: dataPatterns.byte1NN),   // 0xDA
            opCode(mnemonic: "IN A,($n)", dataPattern: dataPatterns.byte1N),     // 0xDB
            opCode(mnemonic: "CALL C,$nn", dataPattern: dataPatterns.byte1NN),    // 0xDC
            opCode(mnemonic: "*DD prefix", dataPattern: dataPatterns.noData),    // 0xDD
            opCode(mnemonic: "SBC A,$n", dataPattern: dataPatterns.byte1N),     // 0xDE
            opCode(mnemonic: "RST 0x18", dataPattern: dataPatterns.noData),    // 0xDF
            opCode(mnemonic: "RET PO", dataPattern: dataPatterns.noData),    // 0xE0
            opCode(mnemonic: "POP HL", dataPattern: dataPatterns.noData),    // 0xE1
            opCode(mnemonic: "JP PO,$nn", dataPattern: dataPatterns.byte1NN),    // 0xE2
            opCode(mnemonic: "EX (SP),HL", dataPattern: dataPatterns.noData),    // 0xE3
            opCode(mnemonic: "CALL PO,$nn", dataPattern: dataPatterns.byte1NN),   // 0xE4
            opCode(mnemonic: "PUSH HL", dataPattern: dataPatterns.noData),    // 0xE5
            opCode(mnemonic: "AND $n", dataPattern: dataPatterns.byte1N),    // 0xE6
            opCode(mnemonic: "RST 0x20", dataPattern: dataPatterns.noData),    // 0xE7
            opCode(mnemonic: "RET PE", dataPattern: dataPatterns.noData),    // 0xE8
            opCode(mnemonic: "JP (HL)", dataPattern: dataPatterns.noData),    // 0xE9
            opCode(mnemonic: "JP PE,$nn", dataPattern: dataPatterns.byte1NN),   // 0xEA
            opCode(mnemonic: "EX DE,HL", dataPattern: dataPatterns.noData),    // 0xEB
            opCode(mnemonic: "CALL PE,$nn", dataPattern: dataPatterns.byte1NN),   // 0xEC
            opCode(mnemonic: "*ED prefix", dataPattern: dataPatterns.noData),    // 0xED
            opCode(mnemonic: "XOR $n", dataPattern: dataPatterns.byte1N),      // 0xEE
            opCode(mnemonic: "RST 0x28", dataPattern: dataPatterns.noData),    // 0xEF
            opCode(mnemonic: "RET P", dataPattern: dataPatterns.noData),    // 0xF0
            opCode(mnemonic: "POP AF", dataPattern: dataPatterns.noData),    // 0xF1
            opCode(mnemonic: "JP P,$nn", dataPattern: dataPatterns.byte1NN),   // 0xF2
            opCode(mnemonic: "DI", dataPattern: dataPatterns.noData),    // 0xF3
            opCode(mnemonic: "CALL P,$nn", dataPattern: dataPatterns.byte1NN),    // 0xF4
            opCode(mnemonic: "PUSH AF", dataPattern: dataPatterns.noData),    // 0xF5
            opCode(mnemonic: "OR $n", dataPattern: dataPatterns.byte1N),     // 0xF6
            opCode(mnemonic: "RST 0x30", dataPattern: dataPatterns.noData),    // 0xF7
            opCode(mnemonic: "RET M", dataPattern: dataPatterns.noData),    // 0xF8
            opCode(mnemonic: "LD SP,HL", dataPattern: dataPatterns.noData),    // 0xF9
            opCode(mnemonic: "JP M,$nn", dataPattern: dataPatterns.byte1NN),    // 0xFA
            opCode(mnemonic: "EI", dataPattern: dataPatterns.noData),    // 0xFB
            opCode(mnemonic: "CALL M,$nn", dataPattern: dataPatterns.byte1NN),   // 0xFC
            opCode(mnemonic: "*FD prefix", dataPattern: dataPatterns.noData),    // 0xFD
            opCode(mnemonic: "CP $n", dataPattern: dataPatterns.byte1N),     // 0xFE
            opCode(mnemonic: "RST 0x38", dataPattern: dataPatterns.noData)     // 0xFF
        ]
        
        let CBPrefixOpcode: [opCode] =
        [
            opCode(mnemonic: "RLC B", dataPattern: dataPatterns.byte1Byte2),     // 0x00
            opCode(mnemonic: "RLC C", dataPattern: dataPatterns.byte1Byte2),     // 0x01
            opCode(mnemonic: "RLC D", dataPattern: dataPatterns.byte1Byte2),     // 0x02
            opCode(mnemonic: "RLC E", dataPattern: dataPatterns.byte1Byte2),     // 0x03
            opCode(mnemonic: "RLC H", dataPattern: dataPatterns.byte1Byte2),     // 0x04
            opCode(mnemonic: "RLC L", dataPattern: dataPatterns.byte1Byte2),     // 0x05
            opCode(mnemonic: "RLC (HL)", dataPattern: dataPatterns.byte1Byte2),  // 0x06
            opCode(mnemonic: "RLC A", dataPattern: dataPatterns.byte1Byte2),     //    0x07
            opCode(mnemonic: "RRC B", dataPattern: dataPatterns.byte1Byte2),     //    0x08
            opCode(mnemonic: "RRC C", dataPattern: dataPatterns.byte1Byte2),     //    0x09
            opCode(mnemonic: "RRC D", dataPattern: dataPatterns.byte1Byte2),     //    0x0A
            opCode(mnemonic: "RRC E", dataPattern: dataPatterns.byte1Byte2),     //    0x0B
            opCode(mnemonic: "RRC H", dataPattern: dataPatterns.byte1Byte2),     //    0x0C
            opCode(mnemonic: "RRC L", dataPattern: dataPatterns.byte1Byte2),     //    0x0D
            opCode(mnemonic: "RRC (HL)", dataPattern: dataPatterns.byte1Byte2),  //    0x0E
            opCode(mnemonic: "RRC A", dataPattern: dataPatterns.byte1Byte2),     //    0x0F
            opCode(mnemonic: "RL B", dataPattern: dataPatterns.byte1Byte2),      //    0x10
            opCode(mnemonic: "RL C", dataPattern: dataPatterns.byte1Byte2),      //    0x11
            opCode(mnemonic: "RL D", dataPattern: dataPatterns.byte1Byte2),      //    0x12
            opCode(mnemonic: "RL E", dataPattern: dataPatterns.byte1Byte2), //    0x13
            opCode(mnemonic: "RL H", dataPattern: dataPatterns.byte1Byte2), //    0x14
            opCode(mnemonic: "RL L", dataPattern: dataPatterns.byte1Byte2), //    0x15
            opCode(mnemonic: "RL (HL)", dataPattern: dataPatterns.byte1Byte2), //    0x16
            opCode(mnemonic: "RL A", dataPattern: dataPatterns.byte1Byte2), //    0x17
            opCode(mnemonic: "RR B", dataPattern: dataPatterns.byte1Byte2), //    0x18
            opCode(mnemonic: "RR C", dataPattern: dataPatterns.byte1Byte2), //    0x19
            opCode(mnemonic: "RR D", dataPattern: dataPatterns.byte1Byte2), //    0x1A
            opCode(mnemonic: "RR E", dataPattern: dataPatterns.byte1Byte2), //    0x1B
            opCode(mnemonic: "RR H", dataPattern: dataPatterns.byte1Byte2), //    0x1C
            opCode(mnemonic: "RR L", dataPattern: dataPatterns.byte1Byte2), //    0x1D
            opCode(mnemonic: "RR (HL)", dataPattern: dataPatterns.byte1Byte2), //    0x1E
            opCode(mnemonic: "RR A", dataPattern: dataPatterns.byte1Byte2), //    0x1F
            opCode(mnemonic: "SLA B", dataPattern: dataPatterns.byte1Byte2), //    0x20
            opCode(mnemonic: "SLA C", dataPattern: dataPatterns.byte1Byte2), //    0x21
            opCode(mnemonic: "SLA D", dataPattern: dataPatterns.byte1Byte2), //    0x22
            opCode(mnemonic: "SLA E", dataPattern: dataPatterns.byte1Byte2), //    0x23
            opCode(mnemonic: "SLA H", dataPattern: dataPatterns.byte1Byte2), //    0x24
            opCode(mnemonic: "SLA L", dataPattern: dataPatterns.byte1Byte2), //    0x25
            opCode(mnemonic: "SLA (HL)", dataPattern: dataPatterns.byte1Byte2), //    0x26
            opCode(mnemonic: "SLA A", dataPattern: dataPatterns.byte1Byte2), //    0x27
            opCode(mnemonic: "SRA B", dataPattern: dataPatterns.byte1Byte2), //    0x28
            opCode(mnemonic: "SRA C", dataPattern: dataPatterns.byte1Byte2), //    0x29
            opCode(mnemonic: "SRA D", dataPattern: dataPatterns.byte1Byte2), //    0x2A
            opCode(mnemonic: "SRA E", dataPattern: dataPatterns.byte1Byte2), //    0x2B
            opCode(mnemonic: "SRA H", dataPattern: dataPatterns.byte1Byte2), //    0x2C
            opCode(mnemonic: "SRA L", dataPattern: dataPatterns.byte1Byte2), //    0x2D
            opCode(mnemonic: "SRA (HL)", dataPattern: dataPatterns.byte1Byte2), //    0x2E
            opCode(mnemonic: "SRA A", dataPattern: dataPatterns.byte1Byte2), //    0x2F
            opCode(mnemonic: "+SLL B", dataPattern: dataPatterns.byte1Byte2), //    0x30
            opCode(mnemonic: "+SLL C", dataPattern: dataPatterns.byte1Byte2), //    0x31
            opCode(mnemonic: "+SLL D", dataPattern: dataPatterns.byte1Byte2), //    0x32
            opCode(mnemonic: "+SLL E", dataPattern: dataPatterns.byte1Byte2), //    0x33
            opCode(mnemonic: "+SLL H", dataPattern: dataPatterns.byte1Byte2), //    0x34
            opCode(mnemonic: "+SLL L", dataPattern: dataPatterns.byte1Byte2), //    0x35
            opCode(mnemonic: "+SLL (HL)", dataPattern: dataPatterns.byte1Byte2), //    0x36
            opCode(mnemonic: "+SLL A", dataPattern: dataPatterns.byte1Byte2), //    0x37
            opCode(mnemonic: "SRL B", dataPattern: dataPatterns.byte1Byte2), //    0x38
            opCode(mnemonic: "SRL C", dataPattern: dataPatterns.byte1Byte2), //    0x39
            opCode(mnemonic: "SRL D", dataPattern: dataPatterns.byte1Byte2), //    0x3A
            opCode(mnemonic: "SRL E", dataPattern: dataPatterns.byte1Byte2), //    0x3B
            opCode(mnemonic: "SRL H", dataPattern: dataPatterns.byte1Byte2), //    0x3C
            opCode(mnemonic: "SRL L", dataPattern: dataPatterns.byte1Byte2), //    0x3D
            opCode(mnemonic: "SRL (HL)", dataPattern: dataPatterns.byte1Byte2), //    0x3E
            opCode(mnemonic: "SRL A", dataPattern: dataPatterns.byte1Byte2), //    0x3F
            opCode(mnemonic: "BIT 0,B", dataPattern: dataPatterns.byte1Byte2), //    0x40
            opCode(mnemonic: "BIT 0,C", dataPattern: dataPatterns.byte1Byte2), //    0x41
            opCode(mnemonic: "BIT 0,D", dataPattern: dataPatterns.byte1Byte2), //    0x42
            opCode(mnemonic: "BIT 0,E", dataPattern: dataPatterns.byte1Byte2), //    0x43
            opCode(mnemonic: "BIT 0,H", dataPattern: dataPatterns.byte1Byte2), //    0x44
            opCode(mnemonic: "BIT 0,L", dataPattern: dataPatterns.byte1Byte2), //    0x45
            opCode(mnemonic: "BIT 0,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0x46
            opCode(mnemonic: "BIT 0,A", dataPattern: dataPatterns.byte1Byte2), //    0x47
            opCode(mnemonic: "BIT 1,B", dataPattern: dataPatterns.byte1Byte2), //    0x48
            opCode(mnemonic: "BIT 1,C", dataPattern: dataPatterns.byte1Byte2), //    0x49
            opCode(mnemonic: "BIT 1,D", dataPattern: dataPatterns.byte1Byte2), //    0x4A
            opCode(mnemonic: "BIT 1,E", dataPattern: dataPatterns.byte1Byte2), //    0x4B
            opCode(mnemonic: "BIT 1,H", dataPattern: dataPatterns.byte1Byte2), //    0x4C
            opCode(mnemonic: "BIT 1,L", dataPattern: dataPatterns.byte1Byte2), //    0x4D
            opCode(mnemonic: "BIT 1,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0x4E
            opCode(mnemonic: "BIT 1,A", dataPattern: dataPatterns.byte1Byte2), //    0x4F
            opCode(mnemonic: "BIT 2,B", dataPattern: dataPatterns.byte1Byte2), //    0x50
            opCode(mnemonic: "BIT 2,C", dataPattern: dataPatterns.byte1Byte2), //    0x51
            opCode(mnemonic: "BIT 2,D", dataPattern: dataPatterns.byte1Byte2), //    0x52
            opCode(mnemonic: "BIT 2,E", dataPattern: dataPatterns.byte1Byte2), //    0x53
            opCode(mnemonic: "BIT 2,H", dataPattern: dataPatterns.byte1Byte2), //    0x54
            opCode(mnemonic: "BIT 2,L", dataPattern: dataPatterns.byte1Byte2), //    0x55
            opCode(mnemonic: "BIT 2,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0x56
            opCode(mnemonic: "BIT 2,A", dataPattern: dataPatterns.byte1Byte2), //    0x57
            opCode(mnemonic: "BIT 3,B", dataPattern: dataPatterns.byte1Byte2), //    0x58
            opCode(mnemonic: "BIT 3,C", dataPattern: dataPatterns.byte1Byte2), //    0x59
            opCode(mnemonic: "BIT 3,D", dataPattern: dataPatterns.byte1Byte2), //    0x5A
            opCode(mnemonic: "BIT 3,E", dataPattern: dataPatterns.byte1Byte2), //    0x5B
            opCode(mnemonic: "BIT 3,H", dataPattern: dataPatterns.byte1Byte2), //    0x5C
            opCode(mnemonic: "BIT 3,L", dataPattern: dataPatterns.byte1Byte2), //    0x5D
            opCode(mnemonic: "BIT 3,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0x5E
            opCode(mnemonic: "BIT 3,A", dataPattern: dataPatterns.byte1Byte2), //    0x5F
            opCode(mnemonic: "BIT 4,B", dataPattern: dataPatterns.byte1Byte2), //    0x60
            opCode(mnemonic: "BIT 4,C", dataPattern: dataPatterns.byte1Byte2), //    0x61
            opCode(mnemonic: "BIT 4,D", dataPattern: dataPatterns.byte1Byte2), //    0x62
            opCode(mnemonic: "BIT 4,E", dataPattern: dataPatterns.byte1Byte2), //    0x63
            opCode(mnemonic: "BIT 4,H", dataPattern: dataPatterns.byte1Byte2), //    0x64
            opCode(mnemonic: "BIT 4,L", dataPattern: dataPatterns.byte1Byte2), //    0x65
            opCode(mnemonic: "BIT 4,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0x66
            opCode(mnemonic: "BIT 4,A", dataPattern: dataPatterns.byte1Byte2), //    0x67
            opCode(mnemonic: "BIT 5,B", dataPattern: dataPatterns.byte1Byte2), //    0x68
            opCode(mnemonic: "BIT 5,C", dataPattern: dataPatterns.byte1Byte2), //    0x69
            opCode(mnemonic: "BIT 5,D", dataPattern: dataPatterns.byte1Byte2), //    0x6A
            opCode(mnemonic: "BIT 5,E", dataPattern: dataPatterns.byte1Byte2), //    0x6B
            opCode(mnemonic: "BIT 5,H", dataPattern: dataPatterns.byte1Byte2), //    0x6C
            opCode(mnemonic: "BIT 5,L", dataPattern: dataPatterns.byte1Byte2), //    0x6D
            opCode(mnemonic: "BIT 5,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0x6E
            opCode(mnemonic: "BIT 5,A", dataPattern: dataPatterns.byte1Byte2), //    0x6F
            opCode(mnemonic: "BIT 6,B", dataPattern: dataPatterns.byte1Byte2), //    0x70
            opCode(mnemonic: "BIT 6,C", dataPattern: dataPatterns.byte1Byte2), //    0x71
            opCode(mnemonic: "BIT 6,D", dataPattern: dataPatterns.byte1Byte2), //    0x72
            opCode(mnemonic: "BIT 6,E", dataPattern: dataPatterns.byte1Byte2), //    0x73
            opCode(mnemonic: "BIT 6,H", dataPattern: dataPatterns.byte1Byte2), //    0x74
            opCode(mnemonic: "BIT 6,L", dataPattern: dataPatterns.byte1Byte2), //    0x75
            opCode(mnemonic: "BIT 6,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0x76
            opCode(mnemonic: "BIT 6,A", dataPattern: dataPatterns.byte1Byte2), //    0x77
            opCode(mnemonic: "BIT 7,B", dataPattern: dataPatterns.byte1Byte2), //    0x78
            opCode(mnemonic: "BIT 7,C", dataPattern: dataPatterns.byte1Byte2), //    0x79
            opCode(mnemonic: "BIT 7,D", dataPattern: dataPatterns.byte1Byte2), //    0x7A
            opCode(mnemonic: "BIT 7,E", dataPattern: dataPatterns.byte1Byte2), //    0x7B
            opCode(mnemonic: "BIT 7,H", dataPattern: dataPatterns.byte1Byte2), //    0x7C
            opCode(mnemonic: "BIT 7,L", dataPattern: dataPatterns.byte1Byte2), //    0x7D
            opCode(mnemonic: "BIT 7,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0x7E
            opCode(mnemonic: "BIT 7,A", dataPattern: dataPatterns.byte1Byte2), //    0x7F
            opCode(mnemonic: "RES 0,B", dataPattern: dataPatterns.byte1Byte2), //    0x80
            opCode(mnemonic: "RES 0,C", dataPattern: dataPatterns.byte1Byte2), //    0x81
            opCode(mnemonic: "RES 0,D", dataPattern: dataPatterns.byte1Byte2), //    0x82
            opCode(mnemonic: "RES 0,E", dataPattern: dataPatterns.byte1Byte2), //    0x83
            opCode(mnemonic: "RES 0,H", dataPattern: dataPatterns.byte1Byte2), //    0x84
            opCode(mnemonic: "RES 0,L", dataPattern: dataPatterns.byte1Byte2), //    0x85
            opCode(mnemonic: "RES 0,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0x86
            opCode(mnemonic: "RES 0,A", dataPattern: dataPatterns.byte1Byte2), //    0x87
            opCode(mnemonic: "RES 1,B", dataPattern: dataPatterns.byte1Byte2), //    0x88
            opCode(mnemonic: "RES 1,C", dataPattern: dataPatterns.byte1Byte2), //    0x89
            opCode(mnemonic: "RES 1,D", dataPattern: dataPatterns.byte1Byte2), //    0x8A
            opCode(mnemonic: "RES 1,E", dataPattern: dataPatterns.byte1Byte2), //    0x8B
            opCode(mnemonic: "RES 1,H", dataPattern: dataPatterns.byte1Byte2), //    0x8C
            opCode(mnemonic: "RES 1,L", dataPattern: dataPatterns.byte1Byte2), //    0x8D
            opCode(mnemonic: "RES 1,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0x8E
            opCode(mnemonic: "RES 1,A", dataPattern: dataPatterns.byte1Byte2), //    0x8F
            opCode(mnemonic: "RES 2,B", dataPattern: dataPatterns.byte1Byte2), //    0x90
            opCode(mnemonic: "RES 2,C", dataPattern: dataPatterns.byte1Byte2), //    0x91
            opCode(mnemonic: "RES 2,D", dataPattern: dataPatterns.byte1Byte2), //    0x92
            opCode(mnemonic: "RES 2,E", dataPattern: dataPatterns.byte1Byte2), //    0x93
            opCode(mnemonic: "RES 2,H", dataPattern: dataPatterns.byte1Byte2), //    0x94
            opCode(mnemonic: "RES 2,L", dataPattern: dataPatterns.byte1Byte2), //    0x95
            opCode(mnemonic: "RES 2,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0x96
            opCode(mnemonic: "RES 2,A", dataPattern: dataPatterns.byte1Byte2), //    0x97
            opCode(mnemonic: "RES 3,B", dataPattern: dataPatterns.byte1Byte2), //    0x98
            opCode(mnemonic: "RES 3,C", dataPattern: dataPatterns.byte1Byte2), //    0x99
            opCode(mnemonic: "RES 3,D", dataPattern: dataPatterns.byte1Byte2), //    0x9A
            opCode(mnemonic: "RES 3,E", dataPattern: dataPatterns.byte1Byte2), //    0x9B
            opCode(mnemonic: "RES 3,H", dataPattern: dataPatterns.byte1Byte2), //    0x9C
            opCode(mnemonic: "RES 3,L", dataPattern: dataPatterns.byte1Byte2), //    0x9D
            opCode(mnemonic: "RES 3,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0x9E
            opCode(mnemonic: "RES 3,A", dataPattern: dataPatterns.byte1Byte2), //    0x9F
            opCode(mnemonic: "RES 4,B", dataPattern: dataPatterns.byte1Byte2), //    0xA0
            opCode(mnemonic: "RES 4,C", dataPattern: dataPatterns.byte1Byte2), //    0xA1
            opCode(mnemonic: "RES 4,D", dataPattern: dataPatterns.byte1Byte2), //    0xA2
            opCode(mnemonic: "RES 4,E", dataPattern: dataPatterns.byte1Byte2), //    0xA3
            opCode(mnemonic: "RES 4,H", dataPattern: dataPatterns.byte1Byte2), //    0xA4
            opCode(mnemonic: "RES 4,L", dataPattern: dataPatterns.byte1Byte2), //    0xA5
            opCode(mnemonic: "RES 4,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0xA6
            opCode(mnemonic: "RES 4,A", dataPattern: dataPatterns.byte1Byte2), //    0xA7
            opCode(mnemonic: "RES 5,B", dataPattern: dataPatterns.byte1Byte2), //    0xA8
            opCode(mnemonic: "RES 5,C", dataPattern: dataPatterns.byte1Byte2), //    0xA9
            opCode(mnemonic: "RES 5,D", dataPattern: dataPatterns.byte1Byte2), //    0xAA
            opCode(mnemonic: "RES 5,E", dataPattern: dataPatterns.byte1Byte2), //    0xAB
            opCode(mnemonic: "RES 5,H", dataPattern: dataPatterns.byte1Byte2), //    0xAC
            opCode(mnemonic: "RES 5,L", dataPattern: dataPatterns.byte1Byte2), //    0xAD
            opCode(mnemonic: "RES 5,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0xAE
            opCode(mnemonic: "RES 5,A", dataPattern: dataPatterns.byte1Byte2), //    0xAF
            opCode(mnemonic: "RES 6,B", dataPattern: dataPatterns.byte1Byte2), //    0xB0
            opCode(mnemonic: "RES 6,C", dataPattern: dataPatterns.byte1Byte2), //    0xB1
            opCode(mnemonic: "RES 6,D", dataPattern: dataPatterns.byte1Byte2), //    0xB2
            opCode(mnemonic: "RES 6,E", dataPattern: dataPatterns.byte1Byte2), //    0xB3
            opCode(mnemonic: "RES 6,H", dataPattern: dataPatterns.byte1Byte2), //    0xB4
            opCode(mnemonic: "RES 6,L", dataPattern: dataPatterns.byte1Byte2), //    0xB5
            opCode(mnemonic: "RES 6,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0xB6
            opCode(mnemonic: "RES 6,A", dataPattern: dataPatterns.byte1Byte2), //    0xB7
            opCode(mnemonic: "RES 7,B", dataPattern: dataPatterns.byte1Byte2), //    0xB8
            opCode(mnemonic: "RES 7,C", dataPattern: dataPatterns.byte1Byte2), //    0xB9
            opCode(mnemonic: "RES 7,D", dataPattern: dataPatterns.byte1Byte2), //    0xBA
            opCode(mnemonic: "RES 7,E", dataPattern: dataPatterns.byte1Byte2), //    0xBB
            opCode(mnemonic: "RES 7,H", dataPattern: dataPatterns.byte1Byte2), //    0xBC
            opCode(mnemonic: "RES 7,L", dataPattern: dataPatterns.byte1Byte2), //    0xBD
            opCode(mnemonic: "RES 7,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0xBE
            opCode(mnemonic: "RES 7,A", dataPattern: dataPatterns.byte1Byte2), //    0xBF
            opCode(mnemonic: "SET 0,B", dataPattern: dataPatterns.byte1Byte2), //    0xC0
            opCode(mnemonic: "SET 0,C", dataPattern: dataPatterns.byte1Byte2), //    0xC1
            opCode(mnemonic: "SET 0,D", dataPattern: dataPatterns.byte1Byte2), //    0xC2
            opCode(mnemonic: "SET 0,E", dataPattern: dataPatterns.byte1Byte2), //    0xC3
            opCode(mnemonic: "SET 0,H", dataPattern: dataPatterns.byte1Byte2), //    0xC4
            opCode(mnemonic: "SET 0,L", dataPattern: dataPatterns.byte1Byte2), //    0xC5
            opCode(mnemonic: "SET 0,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0xC6
            opCode(mnemonic: "SET 0,A", dataPattern: dataPatterns.byte1Byte2), //    0xC7
            opCode(mnemonic: "SET 1,B", dataPattern: dataPatterns.byte1Byte2), //    0xC8
            opCode(mnemonic: "SET 1,C", dataPattern: dataPatterns.byte1Byte2), //    0xC9
            opCode(mnemonic: "SET 1,D", dataPattern: dataPatterns.byte1Byte2), //    0xCA
            opCode(mnemonic: "SET 1,E", dataPattern: dataPatterns.byte1Byte2), //    0xCB
            opCode(mnemonic: "SET 1,H", dataPattern: dataPatterns.byte1Byte2), //    0xCC
            opCode(mnemonic: "SET 1,L", dataPattern: dataPatterns.byte1Byte2), //    0xCD
            opCode(mnemonic: "SET 1,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0xCE
            opCode(mnemonic: "SET 1,A", dataPattern: dataPatterns.byte1Byte2), //    0xCF
            opCode(mnemonic: "SET 2,B", dataPattern: dataPatterns.byte1Byte2), //    0xD0
            opCode(mnemonic: "SET 2,C", dataPattern: dataPatterns.byte1Byte2), //    0xD1
            opCode(mnemonic: "SET 2,D", dataPattern: dataPatterns.byte1Byte2), //    0xD2
            opCode(mnemonic: "SET 2,E", dataPattern: dataPatterns.byte1Byte2), //    0xD3
            opCode(mnemonic: "SET 2,H", dataPattern: dataPatterns.byte1Byte2), //    0xD4
            opCode(mnemonic: "SET 2,L", dataPattern: dataPatterns.byte1Byte2), //    0xD5
            opCode(mnemonic: "SET 2,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0xD6
            opCode(mnemonic: "SET 2,A", dataPattern: dataPatterns.byte1Byte2), //    0xD7
            opCode(mnemonic: "SET 3,B", dataPattern: dataPatterns.byte1Byte2), //    0xD8
            opCode(mnemonic: "SET 3,C", dataPattern: dataPatterns.byte1Byte2), //    0xD9
            opCode(mnemonic: "SET 3,D", dataPattern: dataPatterns.byte1Byte2), //    0xDA
            opCode(mnemonic: "SET 3,E", dataPattern: dataPatterns.byte1Byte2), //    0xDB
            opCode(mnemonic: "SET 3,H", dataPattern: dataPatterns.byte1Byte2), //    0xDC
            opCode(mnemonic: "SET 3,L", dataPattern: dataPatterns.byte1Byte2), //    0xDD
            opCode(mnemonic: "SET 3,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0xDE
            opCode(mnemonic: "SET 3,A", dataPattern: dataPatterns.byte1Byte2), //    0xDF
            opCode(mnemonic: "SET 4,B", dataPattern: dataPatterns.byte1Byte2), //    0xE0
            opCode(mnemonic: "SET 4,C", dataPattern: dataPatterns.byte1Byte2), //    0xE1
            opCode(mnemonic: "SET 4,D", dataPattern: dataPatterns.byte1Byte2), //    0xE2
            opCode(mnemonic: "SET 4,E", dataPattern: dataPatterns.byte1Byte2), //    0xE3
            opCode(mnemonic: "SET 4,H", dataPattern: dataPatterns.byte1Byte2), //    0xE4
            opCode(mnemonic: "SET 4,L", dataPattern: dataPatterns.byte1Byte2), //    0xE5
            opCode(mnemonic: "SET 4,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0xE6
            opCode(mnemonic: "SET 4,A", dataPattern: dataPatterns.byte1Byte2), //    0xE7
            opCode(mnemonic: "SET 5,B", dataPattern: dataPatterns.byte1Byte2), //    0xE8
            opCode(mnemonic: "SET 5,C", dataPattern: dataPatterns.byte1Byte2), //    0xE9
            opCode(mnemonic: "SET 5,D", dataPattern: dataPatterns.byte1Byte2), //    0xEA
            opCode(mnemonic: "SET 5,E", dataPattern: dataPatterns.byte1Byte2), //    0xEB
            opCode(mnemonic: "SET 5,H", dataPattern: dataPatterns.byte1Byte2), //    0xEC
            opCode(mnemonic: "SET 5,L", dataPattern: dataPatterns.byte1Byte2), //    0xED
            opCode(mnemonic: "SET 5,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0xEE
            opCode(mnemonic: "SET 5,A", dataPattern: dataPatterns.byte1Byte2), //    0xEF
            opCode(mnemonic: "SET 6,B", dataPattern: dataPatterns.byte1Byte2), //    0xF0
            opCode(mnemonic: "SET 6,C", dataPattern: dataPatterns.byte1Byte2), //    0xF1
            opCode(mnemonic: "SET 6,D", dataPattern: dataPatterns.byte1Byte2), //    0xF2
            opCode(mnemonic: "SET 6,E", dataPattern: dataPatterns.byte1Byte2), //    0xF3
            opCode(mnemonic: "SET 6,H", dataPattern: dataPatterns.byte1Byte2), //    0xF4
            opCode(mnemonic: "SET 6,L", dataPattern: dataPatterns.byte1Byte2), //    0xF5
            opCode(mnemonic: "SET 6,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0xF6
            opCode(mnemonic: "SET 6,A", dataPattern: dataPatterns.byte1Byte2), //    0xF7
            opCode(mnemonic: "SET 7,B", dataPattern: dataPatterns.byte1Byte2), //    0xF8
            opCode(mnemonic: "SET 7,C", dataPattern: dataPatterns.byte1Byte2), //    0xF9
            opCode(mnemonic: "SET 7,D", dataPattern: dataPatterns.byte1Byte2), //    0xFA
            opCode(mnemonic: "SET 7,E", dataPattern: dataPatterns.byte1Byte2), //    0xFB
            opCode(mnemonic: "SET 7,H", dataPattern: dataPatterns.byte1Byte2), //    0xFC
            opCode(mnemonic: "SET 7,L", dataPattern: dataPatterns.byte1Byte2), //    0xFD
            opCode(mnemonic: "SET 7,(HL)", dataPattern: dataPatterns.byte1Byte2), //    0xFE
            opCode(mnemonic: "SET 7,A", dataPattern: dataPatterns.byte1Byte2) //    0xFF
        ]
        
        let DDPrefixOpcode: [opCode] =
        [
            opCode(mnemonic: "NOP", dataPattern: dataPatterns.byte1Byte2),    //  0x00
            opCode(mnemonic: "*DD01", dataPattern: dataPatterns.byte1Byte2),    //  0x01
            opCode(mnemonic: "*DD02", dataPattern: dataPatterns.byte1Byte2),    //  0x02
            opCode(mnemonic: "*DD03", dataPattern: dataPatterns.byte1Byte2),    //  0x03
            opCode(mnemonic: "INC B", dataPattern: dataPatterns.byte1Byte2),    //  0x04
            opCode(mnemonic: "DEC B", dataPattern: dataPatterns.byte1Byte2),    //  0x05
            opCode(mnemonic: "LD B,$n", dataPattern: dataPatterns.byte1Byte2N),    //  0x06
            opCode(mnemonic: "*DD07", dataPattern: dataPatterns.byte1Byte2),    //  0x07
            opCode(mnemonic: "*DD08", dataPattern: dataPatterns.byte1Byte2),    //  0x08
            opCode(mnemonic: "ADD IX,BC", dataPattern: dataPatterns.byte1Byte2),    //  0x09
            opCode(mnemonic: "*DD0A", dataPattern: dataPatterns.byte1Byte2),    //  0x0A
            opCode(mnemonic: "*DD0B", dataPattern: dataPatterns.byte1Byte2),    //  0x0B
            opCode(mnemonic: "INC C", dataPattern: dataPatterns.byte1Byte2),    //  0x0C
            opCode(mnemonic: "DEC C", dataPattern: dataPatterns.byte1Byte2),    //  0x0D
            opCode(mnemonic: "LD C,$n", dataPattern: dataPatterns.byte1Byte2N),   //  0x0E
            opCode(mnemonic: "*DD0F", dataPattern: dataPatterns.byte1Byte2),    //  0x0F
            opCode(mnemonic: "*DD10", dataPattern: dataPatterns.byte1Byte2),  //  0x10
            opCode(mnemonic: "*DD11", dataPattern: dataPatterns.byte1Byte2),    //  0x11
            opCode(mnemonic: "*DD12", dataPattern: dataPatterns.byte1Byte2),    //  0x12
            opCode(mnemonic: "*DD13", dataPattern: dataPatterns.byte1Byte2),    //  0x13
            opCode(mnemonic: "INC D", dataPattern: dataPatterns.byte1Byte2),    //  0x14
            opCode(mnemonic: "DEC D", dataPattern: dataPatterns.byte1Byte2),    //  0x15
            opCode(mnemonic: "LD D,$n", dataPattern: dataPatterns.byte1Byte2N),    //  0x16
            opCode(mnemonic: "*DD17", dataPattern: dataPatterns.byte1Byte2),    //  0x17
            opCode(mnemonic: "*DD18", dataPattern: dataPatterns.byte1Byte2),   //  0x18
            opCode(mnemonic: "ADD IX,DE", dataPattern: dataPatterns.byte1Byte2),    //  0x19
            opCode(mnemonic: "*DD1A", dataPattern: dataPatterns.byte1Byte2),    //  0x1A
            opCode(mnemonic: "*DD1B", dataPattern: dataPatterns.byte1Byte2),    //  0x1B
            opCode(mnemonic: "INC E", dataPattern: dataPatterns.byte1Byte2),    //  0x1C
            opCode(mnemonic: "DEC E", dataPattern: dataPatterns.byte1Byte2),    //  0x1D
            opCode(mnemonic: "LD E,$n", dataPattern: dataPatterns.byte1Byte2N),   //  0x1E
            opCode(mnemonic: "*DD1F", dataPattern: dataPatterns.byte1Byte2),    //  0x1F
            opCode(mnemonic: "*DD20", dataPattern: dataPatterns.byte1Byte2),  //  0x20
            opCode(mnemonic: "LD IX,$nn", dataPattern: dataPatterns.byte1Byte2NN),    //  0x21
            opCode(mnemonic: "LD ($nn),IX", dataPattern: dataPatterns.byte1Byte2NN),    //  0x22
            opCode(mnemonic: "INC IX", dataPattern: dataPatterns.byte1Byte2),    //  0x23
            opCode(mnemonic: "+INC IXH", dataPattern: dataPatterns.byte1Byte2),    //  0x24
            opCode(mnemonic: "+DEC IXH", dataPattern: dataPatterns.byte1Byte2),    //  0x25
            opCode(mnemonic: "+LD IHX,$n", dataPattern: dataPatterns.byte1Byte2N),   //  0x26
            opCode(mnemonic: "*DD27", dataPattern: dataPatterns.byte1Byte2),    //  0x27
            opCode(mnemonic: "*DD28", dataPattern: dataPatterns.byte1Byte2),  //  0x28
            opCode(mnemonic: "ADD IX,IX", dataPattern: dataPatterns.byte1Byte2),    //  0x29
            opCode(mnemonic: "LD IX,($nn)", dataPattern: dataPatterns.byte1Byte2NN),   //  0x2A
            opCode(mnemonic: "DEC IX", dataPattern: dataPatterns.byte1Byte2),    //  0x2B
            opCode(mnemonic: "+INC IXL", dataPattern: dataPatterns.byte1Byte2),    //  0x2C
            opCode(mnemonic: "+DEC IXL", dataPattern: dataPatterns.byte1Byte2),    //  0x2D
            opCode(mnemonic: "+LD IXL,$n", dataPattern: dataPatterns.byte1Byte2N),   //  0x2E
            opCode(mnemonic: "*DD2F", dataPattern: dataPatterns.byte1Byte2),    //  0x2F
            opCode(mnemonic: "*DD30", dataPattern: dataPatterns.byte1Byte2),    //  0x30
            opCode(mnemonic: "*DD31", dataPattern: dataPatterns.byte1Byte2),   //  0x31
            opCode(mnemonic: "*DD32", dataPattern: dataPatterns.byte1Byte2),     //  0x32
            opCode(mnemonic: "*DD33", dataPattern: dataPatterns.byte1Byte2),    //  0x33
            opCode(mnemonic: "INC (IX+$d)", dataPattern: dataPatterns.byte1Byte2D),    //  0x34
            opCode(mnemonic: "DEC (IX+$d)", dataPattern: dataPatterns.byte1Byte2D),    //  0x35
            opCode(mnemonic: "LD (IX+$d),$n", dataPattern: dataPatterns.byte1Byte2DN),   //  0x36
            opCode(mnemonic: "*DD37", dataPattern: dataPatterns.byte1Byte2),    //  0x37
            opCode(mnemonic: "*DD38", dataPattern: dataPatterns.byte1Byte2),   //  0x38
            opCode(mnemonic: "ADD IX,SP", dataPattern: dataPatterns.byte1Byte2),    //  0x39
            opCode(mnemonic: "*DD3A", dataPattern: dataPatterns.byte1Byte2),    //  0x3A
            opCode(mnemonic: "*DD3B", dataPattern: dataPatterns.byte1Byte2),    //  0x3B
            opCode(mnemonic: "INC A", dataPattern: dataPatterns.byte1Byte2),    //  0x3C
            opCode(mnemonic: "DEC A", dataPattern: dataPatterns.byte1Byte2),    //  0x3D
            opCode(mnemonic: "LD A,$n", dataPattern: dataPatterns.byte1Byte2N),   //  0x3E
            opCode(mnemonic: "*DD3F", dataPattern: dataPatterns.byte1Byte2),    //  0x3F
            opCode(mnemonic: "LD B,B", dataPattern: dataPatterns.byte1Byte2),    //  0x40
            opCode(mnemonic: "LD B,C", dataPattern: dataPatterns.byte1Byte2),    //  0x41
            opCode(mnemonic: "LD B,D", dataPattern: dataPatterns.byte1Byte2),    //  0x42
            opCode(mnemonic: "LD B,E", dataPattern: dataPatterns.byte1Byte2),    //  0x43
            opCode(mnemonic: "+LD B,IXH", dataPattern: dataPatterns.byte1Byte2),    //  0x44
            opCode(mnemonic: "+LD B,IXL", dataPattern: dataPatterns.byte1Byte2),    //  0x45
            opCode(mnemonic: "LD B,(IX+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0x46
            opCode(mnemonic: "LD B,A", dataPattern: dataPatterns.byte1Byte2),    //  0x47
            opCode(mnemonic: "LD C,B", dataPattern: dataPatterns.byte1Byte2),    //  0x48
            opCode(mnemonic: "LD C,C", dataPattern: dataPatterns.byte1Byte2),    //  0x49
            opCode(mnemonic: "LD C,D", dataPattern: dataPatterns.byte1Byte2),    //  0x4A
            opCode(mnemonic: "LD C,E", dataPattern: dataPatterns.byte1Byte2),    //  0x4B
            opCode(mnemonic: "+LD C,IXH", dataPattern: dataPatterns.byte1Byte2),    //  0x4C
            opCode(mnemonic: "+LD C,IXL", dataPattern: dataPatterns.byte1Byte2),    //  0x4D
            opCode(mnemonic: "LD C,(IX+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0x4E
            opCode(mnemonic: "LD C,A", dataPattern: dataPatterns.byte1Byte2),    //  0x4F
            opCode(mnemonic: "LD D,B", dataPattern: dataPatterns.byte1Byte2),    //  0x50
            opCode(mnemonic: "LD D,C", dataPattern: dataPatterns.byte1Byte2),    //  0x51
            opCode(mnemonic: "LD D,D", dataPattern: dataPatterns.byte1Byte2),    //  0x52
            opCode(mnemonic: "LD D,E", dataPattern: dataPatterns.byte1Byte2),    //  0x53
            opCode(mnemonic: "+LD D,IXH", dataPattern: dataPatterns.byte1Byte2),    //  0x54
            opCode(mnemonic: "+LD D,IXL", dataPattern: dataPatterns.byte1Byte2),    //  0x55
            opCode(mnemonic: "LD D,(IX+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0x56
            opCode(mnemonic: "LD D,A", dataPattern: dataPatterns.byte1Byte2),    //  0x57
            opCode(mnemonic: "LD E,B", dataPattern: dataPatterns.byte1Byte2),    //  0x58
            opCode(mnemonic: "LD E,C", dataPattern: dataPatterns.byte1Byte2),    //  0x59
            opCode(mnemonic: "LD E,D", dataPattern: dataPatterns.byte1Byte2),    //  0x5A
            opCode(mnemonic: "LD E,E", dataPattern: dataPatterns.byte1Byte2),    //  0x5B
            opCode(mnemonic: "+LD E,IXH", dataPattern: dataPatterns.byte1Byte2),    //  0x5C
            opCode(mnemonic: "+LD E,IXL", dataPattern: dataPatterns.byte1Byte2),    //  0x5D
            opCode(mnemonic: "LD E,(IX+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0x5E
            opCode(mnemonic: "LD E,A", dataPattern: dataPatterns.byte1Byte2),    //  0x5F
            opCode(mnemonic: "+LD IXH,B", dataPattern: dataPatterns.byte1Byte2),    //  0x60
            opCode(mnemonic: "+LD IXH,C", dataPattern: dataPatterns.byte1Byte2),    //  0x61
            opCode(mnemonic: "+LD IXH,D", dataPattern: dataPatterns.byte1Byte2),    //  0x62
            opCode(mnemonic: "+LD IXH,E", dataPattern: dataPatterns.byte1Byte2),    //  0x63
            opCode(mnemonic: "+LD IXH,IXH", dataPattern: dataPatterns.byte1Byte2),    //  0x64
            opCode(mnemonic: "+LD IXH,IXL", dataPattern: dataPatterns.byte1Byte2),    //  0x65
            opCode(mnemonic: "LD H,(IX+$d)", dataPattern: dataPatterns.byte1Byte2D),  //  0x66
            opCode(mnemonic: "+LD IXH,A", dataPattern: dataPatterns.byte1Byte2),    //  0x67
            opCode(mnemonic: "+LD IXL,B", dataPattern: dataPatterns.byte1Byte2),    //  0x68
            opCode(mnemonic: "+LD IXL,C", dataPattern: dataPatterns.byte1Byte2),    //  0x69
            opCode(mnemonic: "+LD IXL,D", dataPattern: dataPatterns.byte1Byte2),    //  0x6A
            opCode(mnemonic: "+LD IXL,E", dataPattern: dataPatterns.byte1Byte2),    //  0x6B
            opCode(mnemonic: "+LD IXL,IXH", dataPattern: dataPatterns.byte1Byte2),    //  0x6C
            opCode(mnemonic: "+LD IXL,IXL", dataPattern: dataPatterns.byte1Byte2),    //  0x6D
            opCode(mnemonic: "LD L,(IX+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0x6E
            opCode(mnemonic: "+LD IXL,A", dataPattern: dataPatterns.byte1Byte2),    //  0x6F
            opCode(mnemonic: "LD (IX+$d),B", dataPattern: dataPatterns.byte1Byte2D),  //  0x70
            opCode(mnemonic: "LD (IX+$d),C", dataPattern: dataPatterns.byte1Byte2D),   //  0x71
            opCode(mnemonic: "LD (IX+$d),D", dataPattern: dataPatterns.byte1Byte2D),   //  0x72
            opCode(mnemonic: "LD (IX+$d),E", dataPattern: dataPatterns.byte1Byte2D),  //  0x73
            opCode(mnemonic: "LD (IX+$d),H", dataPattern: dataPatterns.byte1Byte2D),   //  0x74
            opCode(mnemonic: "LD (IX+$d),L", dataPattern: dataPatterns.byte1Byte2D),  //  0x75
            opCode(mnemonic: "*DD76", dataPattern: dataPatterns.byte1Byte2),    //  0x76
            opCode(mnemonic: "LD (IX+$d),A", dataPattern: dataPatterns.byte1Byte2D), //  0x77
            opCode(mnemonic: "LD A,B", dataPattern: dataPatterns.byte1Byte2),    //  0x78
            opCode(mnemonic: "LD A,C", dataPattern: dataPatterns.byte1Byte2),    //  0x79
            opCode(mnemonic: "LD A,D", dataPattern: dataPatterns.byte1Byte2),    //  0x7A
            opCode(mnemonic: "LD A,E", dataPattern: dataPatterns.byte1Byte2),    //  0x7B
            opCode(mnemonic: "+LD A,IXH", dataPattern: dataPatterns.byte1Byte2),    //  0x7C
            opCode(mnemonic: "+LD A,IXL", dataPattern: dataPatterns.byte1Byte2),    //  0x7D
            opCode(mnemonic: "LD A,(IX+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0x7E
            opCode(mnemonic: "LD A,A", dataPattern: dataPatterns.byte1Byte2),    //  0x7F
            opCode(mnemonic: "ADD A,B", dataPattern: dataPatterns.byte1Byte2),    //  0x80
            opCode(mnemonic: "ADD A,C", dataPattern: dataPatterns.byte1Byte2),    //  0x81
            opCode(mnemonic: "ADD A,D", dataPattern: dataPatterns.byte1Byte2),    //  0x82
            opCode(mnemonic: "ADD A,E", dataPattern: dataPatterns.byte1Byte2),    //  0x83
            opCode(mnemonic: "+ADD A,IXH", dataPattern: dataPatterns.byte1Byte2),    //  0x84
            opCode(mnemonic: "+ADD A,IXL", dataPattern: dataPatterns.byte1Byte2),    //  0x85
            opCode(mnemonic: "ADD A,(IX+$d)", dataPattern: dataPatterns.byte1Byte2D),  //  0x86
            opCode(mnemonic: "ADD A,A", dataPattern: dataPatterns.byte1Byte2),    //  0x87
            opCode(mnemonic: "ADC A,B", dataPattern: dataPatterns.byte1Byte2),    //  0x88
            opCode(mnemonic: "ADC A,C", dataPattern: dataPatterns.byte1Byte2),    //  0x89
            opCode(mnemonic: "ADC A,D", dataPattern: dataPatterns.byte1Byte2),    //  0x8A
            opCode(mnemonic: "ADC A,E", dataPattern: dataPatterns.byte1Byte2),    //  0x8B
            opCode(mnemonic: "+ADC A,IXH", dataPattern: dataPatterns.byte1Byte2),    //  0x8C
            opCode(mnemonic: "+ADC A,IXL", dataPattern: dataPatterns.byte1Byte2),    //  0x8D
            opCode(mnemonic: "ADC A,(IX+$d)", dataPattern: dataPatterns.byte1Byte2D),  //  0x8E
            opCode(mnemonic: "ADC A,A", dataPattern: dataPatterns.byte1Byte2),    //  0x8F
            opCode(mnemonic: "SUB B", dataPattern: dataPatterns.byte1Byte2),    //  0x90
            opCode(mnemonic: "SUB C", dataPattern: dataPatterns.byte1Byte2),    //  0x91
            opCode(mnemonic: "SUB D", dataPattern: dataPatterns.byte1Byte2),    //  0x92
            opCode(mnemonic: "SUB E", dataPattern: dataPatterns.byte1Byte2),    //  0x93
            opCode(mnemonic: "+SUB IXH", dataPattern: dataPatterns.byte1Byte2),    //  0x94
            opCode(mnemonic: "+SUB IXL", dataPattern: dataPatterns.byte1Byte2),    //  0x95
            opCode(mnemonic: "SUB (IX+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0x96
            opCode(mnemonic: "SUB A", dataPattern: dataPatterns.byte1Byte2),    //  0x97
            opCode(mnemonic: "SBC A,B", dataPattern: dataPatterns.byte1Byte2),    //  0x98
            opCode(mnemonic: "SBC A,C", dataPattern: dataPatterns.byte1Byte2),    //  0x99
            opCode(mnemonic: "SBC A,D", dataPattern: dataPatterns.byte1Byte2),    //  0x9A
            opCode(mnemonic: "SBC A,E", dataPattern: dataPatterns.byte1Byte2),    //  0x9B
            opCode(mnemonic: "+SBC A,IXH", dataPattern: dataPatterns.byte1Byte2),    //  0x9C
            opCode(mnemonic: "+SBC A,IXL", dataPattern: dataPatterns.byte1Byte2),    //  0x9D
            opCode(mnemonic: "SBC A,(IX+$d)", dataPattern: dataPatterns.byte1Byte2D),  //  0x9E
            opCode(mnemonic: "SBC A,A", dataPattern: dataPatterns.byte1Byte2),    //  0x9F
            opCode(mnemonic: "AND B", dataPattern: dataPatterns.byte1Byte2),    //  0xA0
            opCode(mnemonic: "AND C", dataPattern: dataPatterns.byte1Byte2),    //  0xA1
            opCode(mnemonic: "AND D", dataPattern: dataPatterns.byte1Byte2),    //  0xA2
            opCode(mnemonic: "AND E", dataPattern: dataPatterns.byte1Byte2),    //  0xA3
            opCode(mnemonic: "+AND IXH", dataPattern: dataPatterns.byte1Byte2),    //  0xA4
            opCode(mnemonic: "+AND IXL", dataPattern: dataPatterns.byte1Byte2),    //  0xA5
            opCode(mnemonic: "AND (IX+$d)", dataPattern: dataPatterns.byte1Byte2D),    //  0xA6
            opCode(mnemonic: "AND A", dataPattern: dataPatterns.byte1Byte2),    //  0xA7
            opCode(mnemonic: "XOR B", dataPattern: dataPatterns.byte1Byte2),    //  0xA8
            opCode(mnemonic: "XOR C", dataPattern: dataPatterns.byte1Byte2),    //  0xA9
            opCode(mnemonic: "XOR D", dataPattern: dataPatterns.byte1Byte2),    //  0xAA
            opCode(mnemonic: "XOR E", dataPattern: dataPatterns.byte1Byte2),    //  0xAB
            opCode(mnemonic: "+XOR IXH", dataPattern: dataPatterns.byte1Byte2),    //  0xAC
            opCode(mnemonic: "+XOR IXL", dataPattern: dataPatterns.byte1Byte2),    //  0xAD
            opCode(mnemonic: "XOR (IX+$d)", dataPattern: dataPatterns.byte1Byte2D),  //  0xAE
            opCode(mnemonic: "XOR A", dataPattern: dataPatterns.byte1Byte2),    //  0xAF
            opCode(mnemonic: "OR B", dataPattern: dataPatterns.byte1Byte2),    //  0xB0
            opCode(mnemonic: "OR C", dataPattern: dataPatterns.byte1Byte2),    //  0xB1
            opCode(mnemonic: "OR D", dataPattern: dataPatterns.byte1Byte2),    //  0xB2
            opCode(mnemonic: "OR E", dataPattern: dataPatterns.byte1Byte2),    //  0xB3
            opCode(mnemonic: "+OR IXH", dataPattern: dataPatterns.byte1Byte2),    //  0xB4
            opCode(mnemonic: "+OR IXL", dataPattern: dataPatterns.byte1Byte2),    //  0xB5
            opCode(mnemonic: "OR (IX+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0xB6
            opCode(mnemonic: "OR A", dataPattern: dataPatterns.byte1Byte2),    //  0xB7
            opCode(mnemonic: "CP B", dataPattern: dataPatterns.byte1Byte2),    //  0xB8
            opCode(mnemonic: "CP C", dataPattern: dataPatterns.byte1Byte2),    //  0xB9
            opCode(mnemonic: "CP D", dataPattern: dataPatterns.byte1Byte2),    //  0xBA
            opCode(mnemonic: "CP E", dataPattern: dataPatterns.byte1Byte2),    //  0xBB
            opCode(mnemonic: "+CP IXH", dataPattern: dataPatterns.byte1Byte2),    //  0xBC
            opCode(mnemonic: "+CP IXL", dataPattern: dataPatterns.byte1Byte2),    //  0xBD
            opCode(mnemonic: "CP (IX+$d)", dataPattern: dataPatterns.byte1Byte2D), //  0xBE
            opCode(mnemonic: "CP A", dataPattern: dataPatterns.byte1Byte2),    //  0xBF
            opCode(mnemonic: "*DDC0", dataPattern: dataPatterns.byte1Byte2),    //  0xC0
            opCode(mnemonic: "*DDC1", dataPattern: dataPatterns.byte1Byte2),    //  0xC1
            opCode(mnemonic: "*DDC2", dataPattern: dataPatterns.byte1Byte2),    //  0xC2
            opCode(mnemonic: "*DDC3", dataPattern: dataPatterns.byte1Byte2),    //  0xC3
            opCode(mnemonic: "*DDC4", dataPattern: dataPatterns.byte1Byte2),    //  0xC4
            opCode(mnemonic: "*DDC5", dataPattern: dataPatterns.byte1Byte2),    //  0xC5
            opCode(mnemonic: "*DDC6", dataPattern: dataPatterns.byte1Byte2),    //  0xC6
            opCode(mnemonic: "*DDC7", dataPattern: dataPatterns.byte1Byte2),    //  0xC7
            opCode(mnemonic: "*DDC8", dataPattern: dataPatterns.byte1Byte2),    //  0xC8
            opCode(mnemonic: "*DDC9", dataPattern: dataPatterns.byte1Byte2),    //  0xC9
            opCode(mnemonic: "*DDCA", dataPattern: dataPatterns.byte1Byte2),    //  0xCA
            opCode(mnemonic: "*DBCB prefix", dataPattern: dataPatterns.byte1Byte2),    //  0xCB
            opCode(mnemonic: "*DDCC", dataPattern: dataPatterns.byte1Byte2),   //  0xCC
            opCode(mnemonic: "*DDCD", dataPattern: dataPatterns.byte1Byte2),   //  0xCD
            opCode(mnemonic: "*DDCE", dataPattern: dataPatterns.byte1Byte2),  //  0xCE
            opCode(mnemonic: "*DDCF", dataPattern: dataPatterns.byte1Byte2),    //  0xCF
            opCode(mnemonic: "*DDD0", dataPattern: dataPatterns.byte1Byte2),    //  0xD0
            opCode(mnemonic: "*DDD1", dataPattern: dataPatterns.byte1Byte2),    //  0xD1
            opCode(mnemonic: "*DDD2", dataPattern: dataPatterns.byte1Byte2),   //  0xD2
            opCode(mnemonic: "*DDD3", dataPattern: dataPatterns.byte1Byte2),//  0xD3
            opCode(mnemonic: "*DDD4", dataPattern: dataPatterns.byte1Byte2),     //  0xD4
            opCode(mnemonic: "*DDD5", dataPattern: dataPatterns.byte1Byte2),    //  0xD5
            opCode(mnemonic: "*DDD6", dataPattern: dataPatterns.byte1Byte2),  //  0xD6
            opCode(mnemonic: "*DDD7", dataPattern: dataPatterns.byte1Byte2),    //  0xD7
            opCode(mnemonic: "*DDD8", dataPattern: dataPatterns.byte1Byte2),    //  0xD8
            opCode(mnemonic: "*DDD9", dataPattern: dataPatterns.byte1Byte2),    //  0xD9
            opCode(mnemonic: "*DDDA", dataPattern: dataPatterns.byte1Byte2),   //  0xDA
            opCode(mnemonic: "*DDDB", dataPattern: dataPatterns.byte1Byte2),    //  0xDB
            opCode(mnemonic: "*DDDC", dataPattern: dataPatterns.byte1Byte2),  //  0xDC
            opCode(mnemonic: "*DDDD", dataPattern: dataPatterns.byte1Byte2),    //  0xDD
            opCode(mnemonic: "*DDDE", dataPattern: dataPatterns.byte1Byte2),   //  0xDE
            opCode(mnemonic: "*DDDF", dataPattern: dataPatterns.byte1Byte2),    //  0xDF
            opCode(mnemonic: "*DDE0", dataPattern: dataPatterns.byte1Byte2),    //  0xE0
            opCode(mnemonic: "POP IX", dataPattern: dataPatterns.byte1Byte2),    //  0xE1
            opCode(mnemonic: "*DDE2", dataPattern: dataPatterns.byte1Byte2),    //  0xE2
            opCode(mnemonic: "EX (SP),IX", dataPattern: dataPatterns.byte1Byte2),    //  0xE3
            opCode(mnemonic: "*DDE4", dataPattern: dataPatterns.byte1Byte2),    //  0xE4
            opCode(mnemonic: "PUSH IX", dataPattern: dataPatterns.byte1Byte2),    //  0xE5
            opCode(mnemonic: "*DDE6", dataPattern: dataPatterns.byte1Byte2),   //  0xE6
            opCode(mnemonic: "*DDE7", dataPattern: dataPatterns.byte1Byte2),    //  0xE7
            opCode(mnemonic: "*DDE8", dataPattern: dataPatterns.byte1Byte2),    //  0xE8
            opCode(mnemonic: "JP (IX)", dataPattern: dataPatterns.byte1Byte2),    //  0xE9
            opCode(mnemonic: "*DDEA", dataPattern: dataPatterns.byte1Byte2),    //  0xEA
            opCode(mnemonic: "*DDEB", dataPattern: dataPatterns.byte1Byte2),    //  0xEB
            opCode(mnemonic: "*DDEC", dataPattern: dataPatterns.byte1Byte2),   //  0xEC
            opCode(mnemonic: "*DDED", dataPattern: dataPatterns.byte1Byte2),    //  0xED
            opCode(mnemonic: "*DDEE", dataPattern: dataPatterns.byte1Byte2), //  0xEE
            opCode(mnemonic: "*DDEF", dataPattern: dataPatterns.byte1Byte2),    //  0xEF
            opCode(mnemonic: "*DDF0", dataPattern: dataPatterns.byte1Byte2),    //  0xF0
            opCode(mnemonic: "*DDF1", dataPattern: dataPatterns.byte1Byte2),    //  0xF1
            opCode(mnemonic: "*DDF2", dataPattern: dataPatterns.byte1Byte2),    //  0xF2
            opCode(mnemonic: "*DDF3", dataPattern: dataPatterns.byte1Byte2),    //  0xF3
            opCode(mnemonic: "*DDF4", dataPattern: dataPatterns.byte1Byte2),   //  0xF4
            opCode(mnemonic: "*DDF5", dataPattern: dataPatterns.byte1Byte2),    //  0xF5
            opCode(mnemonic: "*DDF6", dataPattern: dataPatterns.byte1Byte2),  //  0xF6
            opCode(mnemonic: "*DDF7", dataPattern: dataPatterns.byte1Byte2),    //  0xF7
            opCode(mnemonic: "*DDF8", dataPattern: dataPatterns.byte1Byte2),    //  0xF8
            opCode(mnemonic: "LD SP,IX", dataPattern: dataPatterns.byte1Byte2),    //  0xF9
            opCode(mnemonic: "*DDFA", dataPattern: dataPatterns.byte1Byte2),   //  0xFA
            opCode(mnemonic: "*DDFB", dataPattern: dataPatterns.byte1Byte2),    //  0xFB
            opCode(mnemonic: "*DDFC", dataPattern: dataPatterns.byte1Byte2),    //  0xFC
            opCode(mnemonic: "*DDFD", dataPattern: dataPatterns.byte1Byte2),    //  0xFD
            opCode(mnemonic: "*DDFE", dataPattern: dataPatterns.byte1Byte2),  //  0xFE
            opCode(mnemonic: "*DDFF", dataPattern: dataPatterns.byte1Byte2),    //  0xFF
        ]
        
        let EDPrefixOpcode: [opCode] =
        [
            opCode(mnemonic: "*ED00", dataPattern: dataPatterns.byte1Byte2),    //  0x00
            opCode(mnemonic: "*ED01", dataPattern: dataPatterns.byte1Byte2),    //  0x01
            opCode(mnemonic: "*ED02", dataPattern: dataPatterns.byte1Byte2),    //  0x02
            opCode(mnemonic: "*ED03", dataPattern: dataPatterns.byte1Byte2),    //  0x03
            opCode(mnemonic: "*ED04", dataPattern: dataPatterns.byte1Byte2),    //  0x04
            opCode(mnemonic: "*ED05", dataPattern: dataPatterns.byte1Byte2),    //  0x05
            opCode(mnemonic: "*ED06", dataPattern: dataPatterns.byte1Byte2),    //  0x06
            opCode(mnemonic: "*ED07", dataPattern: dataPatterns.byte1Byte2),    //  0x07
            opCode(mnemonic: "*ED08", dataPattern: dataPatterns.byte1Byte2),    //  0x08
            opCode(mnemonic: "*ED09", dataPattern: dataPatterns.byte1Byte2),    //  0x09
            opCode(mnemonic: "*ED0A", dataPattern: dataPatterns.byte1Byte2),    //  0x0A
            opCode(mnemonic: "*ED0B", dataPattern: dataPatterns.byte1Byte2),    //  0x0B
            opCode(mnemonic: "*ED0C", dataPattern: dataPatterns.byte1Byte2),    //  0x0C
            opCode(mnemonic: "*ED0D", dataPattern: dataPatterns.byte1Byte2),    //  0x0D
            opCode(mnemonic: "*ED0E", dataPattern: dataPatterns.byte1Byte2),    //  0x0E
            opCode(mnemonic: "*ED0F", dataPattern: dataPatterns.byte1Byte2),    //  0x0F
            opCode(mnemonic: "*ED10", dataPattern: dataPatterns.byte1Byte2),    //  0x10
            opCode(mnemonic: "*ED11", dataPattern: dataPatterns.byte1Byte2),    //  0x11
            opCode(mnemonic: "*ED12", dataPattern: dataPatterns.byte1Byte2),    //  0x12
            opCode(mnemonic: "*ED13", dataPattern: dataPatterns.byte1Byte2),    //  0x13
            opCode(mnemonic: "*ED14", dataPattern: dataPatterns.byte1Byte2),    //  0x14
            opCode(mnemonic: "*ED15", dataPattern: dataPatterns.byte1Byte2),    //  0x15
            opCode(mnemonic: "*ED16", dataPattern: dataPatterns.byte1Byte2),    //  0x16
            opCode(mnemonic: "*ED17", dataPattern: dataPatterns.byte1Byte2),    //  0x17
            opCode(mnemonic: "*ED18", dataPattern: dataPatterns.byte1Byte2),    //  0x18
            opCode(mnemonic: "*ED19", dataPattern: dataPatterns.byte1Byte2),    //  0x19
            opCode(mnemonic: "*ED1A", dataPattern: dataPatterns.byte1Byte2),    //  0x1A
            opCode(mnemonic: "*ED1B", dataPattern: dataPatterns.byte1Byte2),    //  0x1B
            opCode(mnemonic: "*ED1C", dataPattern: dataPatterns.byte1Byte2),    //  0x1C
            opCode(mnemonic: "*ED1D", dataPattern: dataPatterns.byte1Byte2),    //  0x1D
            opCode(mnemonic: "*ED1E", dataPattern: dataPatterns.byte1Byte2),    //  0x1E
            opCode(mnemonic: "*ED1F", dataPattern: dataPatterns.byte1Byte2),    //  0x1F
            opCode(mnemonic: "*ED20", dataPattern: dataPatterns.byte1Byte2),    //  0x20
            opCode(mnemonic: "*ED21", dataPattern: dataPatterns.byte1Byte2),    //  0x21
            opCode(mnemonic: "*ED22", dataPattern: dataPatterns.byte1Byte2),    //  0x22
            opCode(mnemonic: "*ED23", dataPattern: dataPatterns.byte1Byte2),    //  0x23
            opCode(mnemonic: "*ED24", dataPattern: dataPatterns.byte1Byte2),    //  0x24
            opCode(mnemonic: "*ED25", dataPattern: dataPatterns.byte1Byte2),    //  0x25
            opCode(mnemonic: "*ED26", dataPattern: dataPatterns.byte1Byte2),    //  0x26
            opCode(mnemonic: "*ED27", dataPattern: dataPatterns.byte1Byte2),    //  0x27
            opCode(mnemonic: "*ED28", dataPattern: dataPatterns.byte1Byte2),    //  0x28
            opCode(mnemonic: "*ED29", dataPattern: dataPatterns.byte1Byte2),    //  0x29
            opCode(mnemonic: "*ED2A", dataPattern: dataPatterns.byte1Byte2),    //  0x2A
            opCode(mnemonic: "*ED2B", dataPattern: dataPatterns.byte1Byte2),    //  0x2B
            opCode(mnemonic: "*ED2C", dataPattern: dataPatterns.byte1Byte2),    //  0x2C
            opCode(mnemonic: "*ED2D", dataPattern: dataPatterns.byte1Byte2),    //  0x2D
            opCode(mnemonic: "*ED2E", dataPattern: dataPatterns.byte1Byte2),    //  0x2E
            opCode(mnemonic: "*ED2F", dataPattern: dataPatterns.byte1Byte2),    //  0x2F
            opCode(mnemonic: "*ED30", dataPattern: dataPatterns.byte1Byte2),    //  0x30
            opCode(mnemonic: "*ED31", dataPattern: dataPatterns.byte1Byte2),    //  0x31
            opCode(mnemonic: "*ED32", dataPattern: dataPatterns.byte1Byte2),    //  0x32
            opCode(mnemonic: "*ED33", dataPattern: dataPatterns.byte1Byte2),    //  0x33
            opCode(mnemonic: "*ED34", dataPattern: dataPatterns.byte1Byte2),    //  0x34
            opCode(mnemonic: "*ED35", dataPattern: dataPatterns.byte1Byte2),    //  0x35
            opCode(mnemonic: "*ED36", dataPattern: dataPatterns.byte1Byte2),    //  0x36
            opCode(mnemonic: "*ED37", dataPattern: dataPatterns.byte1Byte2),    //  0x37
            opCode(mnemonic: "*ED38", dataPattern: dataPatterns.byte1Byte2),    //  0x38
            opCode(mnemonic: "*ED39", dataPattern: dataPatterns.byte1Byte2),    //  0x39
            opCode(mnemonic: "*ED3A", dataPattern: dataPatterns.byte1Byte2),    //  0x3A
            opCode(mnemonic: "*ED3B", dataPattern: dataPatterns.byte1Byte2),    //  0x3B
            opCode(mnemonic: "*ED3C", dataPattern: dataPatterns.byte1Byte2),    //  0x3C
            opCode(mnemonic: "*ED3D", dataPattern: dataPatterns.byte1Byte2),    //  0x3D
            opCode(mnemonic: "*ED3E", dataPattern: dataPatterns.byte1Byte2),    //  0x3E
            opCode(mnemonic: "*ED3F", dataPattern: dataPatterns.byte1Byte2),    //  0x3F
            opCode(mnemonic: "IN B,(C)", dataPattern: dataPatterns.byte1Byte2),    //  0x40
            opCode(mnemonic: "OUT (C),B", dataPattern: dataPatterns.byte1Byte2),    //  0x41
            opCode(mnemonic: "SBC HL,BC", dataPattern: dataPatterns.byte1Byte2),    //  0x42
            opCode(mnemonic: "LD ($nn),BC", dataPattern: dataPatterns.byte1Byte2NN),   //  0x43
            opCode(mnemonic: "NEG", dataPattern: dataPatterns.byte1Byte2),    //  0x44
            opCode(mnemonic: "RETN", dataPattern: dataPatterns.byte1Byte2),    //  0x45
            opCode(mnemonic: "IM 0", dataPattern: dataPatterns.byte1Byte2),    //  0x46
            opCode(mnemonic: "LD I,A", dataPattern: dataPatterns.byte1Byte2),    //  0x47
            opCode(mnemonic: "IN C,(C)", dataPattern: dataPatterns.byte1Byte2),    //  0x48
            opCode(mnemonic: "OUT (C),C", dataPattern: dataPatterns.byte1Byte2),    //  0x49
            opCode(mnemonic: "ADC HL,BC", dataPattern: dataPatterns.byte1Byte2),    //  0x4A
            opCode(mnemonic: "LD BC,($nn)", dataPattern: dataPatterns.byte1Byte2NN),     //  0x4B
            opCode(mnemonic: "*ED4C", dataPattern: dataPatterns.byte1Byte2),    //  0x4C
            opCode(mnemonic: "RETI", dataPattern: dataPatterns.byte1Byte2),    //  0x4D
            opCode(mnemonic: "*ED4E", dataPattern: dataPatterns.byte1Byte2),    //  0x4E
            opCode(mnemonic: "LD R,A", dataPattern: dataPatterns.byte1Byte2),    //  0x4F
            opCode(mnemonic: "IN D,(C)", dataPattern: dataPatterns.byte1Byte2),    //  0x50
            opCode(mnemonic: "OUT (C),D", dataPattern: dataPatterns.byte1Byte2),    //  0x51
            opCode(mnemonic: "SBC HL,DE", dataPattern: dataPatterns.byte1Byte2),    //  0x52
            opCode(mnemonic: "LD ($nn),DE", dataPattern: dataPatterns.byte1Byte2NN),   //  0x53
            opCode(mnemonic: "*ED54", dataPattern: dataPatterns.byte1Byte2),    //  0x54
            opCode(mnemonic: "*ED55", dataPattern: dataPatterns.byte1Byte2),    //  0x55
            opCode(mnemonic: "IM 1", dataPattern: dataPatterns.byte1Byte2),    //  0x56
            opCode(mnemonic: "LD A,I", dataPattern: dataPatterns.byte1Byte2),    //  0x57
            opCode(mnemonic: "IN E,(C)", dataPattern: dataPatterns.byte1Byte2),    //  0x58
            opCode(mnemonic: "OUT (C),E", dataPattern: dataPatterns.byte1Byte2),    //  0x59
            opCode(mnemonic: "ADC HL,DE", dataPattern: dataPatterns.byte1Byte2),    //  0x5A
            opCode(mnemonic: "LD DE,($nn)", dataPattern: dataPatterns.byte1Byte2NN),   //  0x5B
            opCode(mnemonic: "*ED5C", dataPattern: dataPatterns.byte1Byte2),    //  0x5C
            opCode(mnemonic: "*ED5D", dataPattern: dataPatterns.byte1Byte2),    //  0x5D
            opCode(mnemonic: "IM 2", dataPattern: dataPatterns.byte1Byte2),    //  0x5E
            opCode(mnemonic: "LD A,R", dataPattern: dataPatterns.byte1Byte2),    //  0x5F
            opCode(mnemonic: "IN H,(C)", dataPattern: dataPatterns.byte1Byte2),    //  0x60
            opCode(mnemonic: "OUT (C),H", dataPattern: dataPatterns.byte1Byte2),    //  0x61
            opCode(mnemonic: "SBC HL,HL", dataPattern: dataPatterns.byte1Byte2),    //  0x62
            opCode(mnemonic: "LD ($nn),HL", dataPattern: dataPatterns.byte1Byte2NN),    //  0x63
            opCode(mnemonic: "*ED64", dataPattern: dataPatterns.byte1Byte2),    //  0x64
            opCode(mnemonic: "*ED65", dataPattern: dataPatterns.byte1Byte2),    //  0x65
            opCode(mnemonic: "*ED66", dataPattern: dataPatterns.byte1Byte2),    //  0x66
            opCode(mnemonic: "RRD", dataPattern: dataPatterns.byte1Byte2),    //  0x67
            opCode(mnemonic: "IN L,(C)", dataPattern: dataPatterns.byte1Byte2),    //  0x68
            opCode(mnemonic: "OUT (C),L", dataPattern: dataPatterns.byte1Byte2),    //  0x69
            opCode(mnemonic: "ADC HL,HL", dataPattern: dataPatterns.byte1Byte2),    //  0x6A
            opCode(mnemonic: "LD HL,($nn)", dataPattern: dataPatterns.byte1Byte2NN),     //  0x6B
            opCode(mnemonic: "*ED6C", dataPattern: dataPatterns.byte1Byte2),    //  0x6C
            opCode(mnemonic: "*ED6D", dataPattern: dataPatterns.byte1Byte2),    //  0x6D
            opCode(mnemonic: "*ED6E", dataPattern: dataPatterns.byte1Byte2),    //  0x6E
            opCode(mnemonic: "RLD", dataPattern: dataPatterns.byte1Byte2),    //  0x6F
            opCode(mnemonic: "+IN (C)", dataPattern: dataPatterns.byte1Byte2),    //  0x70
            opCode(mnemonic: "+OUT (C),0", dataPattern: dataPatterns.byte1Byte2),    //  0x71
            opCode(mnemonic: "SBC HL,SP", dataPattern: dataPatterns.byte1Byte2),    //  0x72
            opCode(mnemonic: "LD ($nn),SP", dataPattern: dataPatterns.byte1Byte2NN),    //  0x73
            opCode(mnemonic: "*ED74", dataPattern: dataPatterns.byte1Byte2),    //  0x74
            opCode(mnemonic: "*ED75", dataPattern: dataPatterns.byte1Byte2),    //  0x75
            opCode(mnemonic: "*ED76", dataPattern: dataPatterns.byte1Byte2),    //  0x76
            opCode(mnemonic: "*ED77", dataPattern: dataPatterns.byte1Byte2),    //  0x77
            opCode(mnemonic: "IN A,(C)", dataPattern: dataPatterns.byte1Byte2),    //  0x78
            opCode(mnemonic: "OUT (C),A", dataPattern: dataPatterns.byte1Byte2),    //  0x79
            opCode(mnemonic: "ADC HL,SP", dataPattern: dataPatterns.byte1Byte2),    //  0x7A
            opCode(mnemonic: "LD SP,($nn)", dataPattern: dataPatterns.byte1Byte2NN),    //  0x7B
            opCode(mnemonic: "*ED7C", dataPattern: dataPatterns.byte1Byte2),    //  0x7C
            opCode(mnemonic: "*ED7D", dataPattern: dataPatterns.byte1Byte2),    //  0x7D
            opCode(mnemonic: "*ED7E", dataPattern: dataPatterns.byte1Byte2),    //  0x7E
            opCode(mnemonic: "*ED7F", dataPattern: dataPatterns.byte1Byte2),    //  0x7F
            opCode(mnemonic: "*ED80", dataPattern: dataPatterns.byte1Byte2),    //  0x80
            opCode(mnemonic: "*ED81", dataPattern: dataPatterns.byte1Byte2),    //  0x81
            opCode(mnemonic: "*ED82", dataPattern: dataPatterns.byte1Byte2),    //  0x82
            opCode(mnemonic: "*ED83", dataPattern: dataPatterns.byte1Byte2),    //  0x83
            opCode(mnemonic: "*ED84", dataPattern: dataPatterns.byte1Byte2),    //  0x84
            opCode(mnemonic: "*ED85", dataPattern: dataPatterns.byte1Byte2),    //  0x85
            opCode(mnemonic: "*ED86", dataPattern: dataPatterns.byte1Byte2),    //  0x86
            opCode(mnemonic: "*ED87", dataPattern: dataPatterns.byte1Byte2),    //  0x87
            opCode(mnemonic: "*ED88", dataPattern: dataPatterns.byte1Byte2),    //  0x88
            opCode(mnemonic: "*ED89", dataPattern: dataPatterns.byte1Byte2),    //  0x89
            opCode(mnemonic: "*ED8A", dataPattern: dataPatterns.byte1Byte2),    //  0x8A
            opCode(mnemonic: "*ED8B", dataPattern: dataPatterns.byte1Byte2),    //  0x8B
            opCode(mnemonic: "*ED8C", dataPattern: dataPatterns.byte1Byte2),    //  0x8C
            opCode(mnemonic: "*ED8D", dataPattern: dataPatterns.byte1Byte2),    //  0x8D
            opCode(mnemonic: "*ED8E", dataPattern: dataPatterns.byte1Byte2),    //  0x8E
            opCode(mnemonic: "*ED8F", dataPattern: dataPatterns.byte1Byte2),    //  0x8F
            opCode(mnemonic: "*ED90", dataPattern: dataPatterns.byte1Byte2),    //  0x90
            opCode(mnemonic: "*ED91", dataPattern: dataPatterns.byte1Byte2),    //  0x91
            opCode(mnemonic: "*ED92", dataPattern: dataPatterns.byte1Byte2),    //  0x92
            opCode(mnemonic: "*ED93", dataPattern: dataPatterns.byte1Byte2),    //  0x93
            opCode(mnemonic: "*ED94", dataPattern: dataPatterns.byte1Byte2),    //  0x94
            opCode(mnemonic: "*ED95", dataPattern: dataPatterns.byte1Byte2),    //  0x95
            opCode(mnemonic: "*ED96", dataPattern: dataPatterns.byte1Byte2),    //  0x96
            opCode(mnemonic: "*ED97", dataPattern: dataPatterns.byte1Byte2),    //  0x97
            opCode(mnemonic: "*ED98", dataPattern: dataPatterns.byte1Byte2),    //  0x98
            opCode(mnemonic: "*ED99", dataPattern: dataPatterns.byte1Byte2),    //  0x99
            opCode(mnemonic: "*ED9A", dataPattern: dataPatterns.byte1Byte2),    //  0x9A
            opCode(mnemonic: "*ED9B", dataPattern: dataPatterns.byte1Byte2),    //  0x9B
            opCode(mnemonic: "*ED9C", dataPattern: dataPatterns.byte1Byte2),    //  0x9C
            opCode(mnemonic: "*ED9D", dataPattern: dataPatterns.byte1Byte2),    //  0x9D
            opCode(mnemonic: "*ED9E", dataPattern: dataPatterns.byte1Byte2),    //  0x9E
            opCode(mnemonic: "*ED9F", dataPattern: dataPatterns.byte1Byte2),    //  0x9F
            opCode(mnemonic: "LDI", dataPattern: dataPatterns.byte1Byte2),    //  0xA0
            opCode(mnemonic: "CPI", dataPattern: dataPatterns.byte1Byte2),    //  0xA1
            opCode(mnemonic: "INI", dataPattern: dataPatterns.byte1Byte2),    //  0xA2
            opCode(mnemonic: "OUTI", dataPattern: dataPatterns.byte1Byte2),    //  0xA3
            opCode(mnemonic: "*EDA4", dataPattern: dataPatterns.byte1Byte2),    //  0xA4
            opCode(mnemonic: "*EDA5", dataPattern: dataPatterns.byte1Byte2),    //  0xA5
            opCode(mnemonic: "*EDA6", dataPattern: dataPatterns.byte1Byte2),    //  0xA6
            opCode(mnemonic: "*EDA7", dataPattern: dataPatterns.byte1Byte2),    //  0xA7
            opCode(mnemonic: "LDD", dataPattern: dataPatterns.byte1Byte2),         //  0xA8
            opCode(mnemonic: "CPD", dataPattern: dataPatterns.byte1Byte2),         //  0xA9
            opCode(mnemonic: "IND", dataPattern: dataPatterns.byte1Byte2),         //  0xAA
            opCode(mnemonic: "OUTD", dataPattern: dataPatterns.byte1Byte2),        //  0xAB
            opCode(mnemonic: "*EDAC", dataPattern: dataPatterns.byte1Byte2),    //  0xAC
            opCode(mnemonic: "*EDAD", dataPattern: dataPatterns.byte1Byte2),    //  0xAD
            opCode(mnemonic: "*EDAE", dataPattern: dataPatterns.byte1Byte2),    //  0xAE
            opCode(mnemonic: "*EDAF", dataPattern: dataPatterns.byte1Byte2),    //  0xAF
            opCode(mnemonic: "LDIR", dataPattern: dataPatterns.byte1Byte2),        //  0xB0
            opCode(mnemonic: "CPIR", dataPattern: dataPatterns.byte1Byte2),        //  0xB1
            opCode(mnemonic: "INIR", dataPattern: dataPatterns.byte1Byte2),        //  0xB2
            opCode(mnemonic: "OTIR", dataPattern: dataPatterns.byte1Byte2),        //  0xB3
            opCode(mnemonic: "*EDB4", dataPattern: dataPatterns.byte1Byte2),    //  0xB4
            opCode(mnemonic: "*EDB5", dataPattern: dataPatterns.byte1Byte2),    //  0xB5
            opCode(mnemonic: "*EDB6", dataPattern: dataPatterns.byte1Byte2),    //  0xB6
            opCode(mnemonic: "*EDB7", dataPattern: dataPatterns.byte1Byte2),    //  0xB7
            opCode(mnemonic: "LDDR", dataPattern: dataPatterns.byte1Byte2),        //  0xB8
            opCode(mnemonic: "CPDR", dataPattern: dataPatterns.byte1Byte2),        //  0xB9
            opCode(mnemonic: "INDR", dataPattern: dataPatterns.byte1Byte2),        //  0xBA
            opCode(mnemonic: "OTDR", dataPattern: dataPatterns.byte1Byte2),        //  0xBB
            opCode(mnemonic: "*EDBC", dataPattern: dataPatterns.byte1Byte2),    //  0xBC
            opCode(mnemonic: "*EDBD", dataPattern: dataPatterns.byte1Byte2),    //  0xBD
            opCode(mnemonic: "*EDBE", dataPattern: dataPatterns.byte1Byte2),    //  0xBE
            opCode(mnemonic: "*EDBF", dataPattern: dataPatterns.byte1Byte2),    //  0xBF
            opCode(mnemonic: "*EDC0", dataPattern: dataPatterns.byte1Byte2),    //  0xC0
            opCode(mnemonic: "*EDC1", dataPattern: dataPatterns.byte1Byte2),    //  0xC1
            opCode(mnemonic: "*EDC2", dataPattern: dataPatterns.byte1Byte2),    //  0xC2
            opCode(mnemonic: "*EDC3", dataPattern: dataPatterns.byte1Byte2),    //  0xC3
            opCode(mnemonic: "*EDC4", dataPattern: dataPatterns.byte1Byte2),    //  0xC4
            opCode(mnemonic: "*EDC5", dataPattern: dataPatterns.byte1Byte2),    //  0xC5
            opCode(mnemonic: "*EDC6", dataPattern: dataPatterns.byte1Byte2),    //  0xC6
            opCode(mnemonic: "*EDC7", dataPattern: dataPatterns.byte1Byte2),    //  0xC7
            opCode(mnemonic: "*EDC8", dataPattern: dataPatterns.byte1Byte2),    //  0xC8
            opCode(mnemonic: "*EDC9", dataPattern: dataPatterns.byte1Byte2),    //  0xC9
            opCode(mnemonic: "*EDCA", dataPattern: dataPatterns.byte1Byte2),    //  0xCA
            opCode(mnemonic: "*EDCB", dataPattern: dataPatterns.byte1Byte2),    //  0xCB
            opCode(mnemonic: "*EDCC", dataPattern: dataPatterns.byte1Byte2),    //  0xCC
            opCode(mnemonic: "*EDCD", dataPattern: dataPatterns.byte1Byte2),    //  0xCD
            opCode(mnemonic: "*EDCE", dataPattern: dataPatterns.byte1Byte2),    //  0xCE
            opCode(mnemonic: "*EDCF", dataPattern: dataPatterns.byte1Byte2),    //  0xCF
            opCode(mnemonic: "*EDD0", dataPattern: dataPatterns.byte1Byte2),    //  0xD0
            opCode(mnemonic: "*EDD1", dataPattern: dataPatterns.byte1Byte2),    //  0xD1
            opCode(mnemonic: "*EDD2", dataPattern: dataPatterns.byte1Byte2),    //  0xD2
            opCode(mnemonic: "*EDD3", dataPattern: dataPatterns.byte1Byte2),    //  0xD3
            opCode(mnemonic: "*EDD4", dataPattern: dataPatterns.byte1Byte2),    //  0xD4
            opCode(mnemonic: "*EDD5", dataPattern: dataPatterns.byte1Byte2),    //  0xD5
            opCode(mnemonic: "*EDD6", dataPattern: dataPatterns.byte1Byte2),    //  0xD6
            opCode(mnemonic: "*EDD7", dataPattern: dataPatterns.byte1Byte2),    //  0xD7
            opCode(mnemonic: "*EDD8", dataPattern: dataPatterns.byte1Byte2),    //  0xD8
            opCode(mnemonic: "*EDD9", dataPattern: dataPatterns.byte1Byte2),    //  0xD9
            opCode(mnemonic: "*EDDA", dataPattern: dataPatterns.byte1Byte2),    //  0xDA
            opCode(mnemonic: "*EDDB", dataPattern: dataPatterns.byte1Byte2),    //  0xDB
            opCode(mnemonic: "*EDDC", dataPattern: dataPatterns.byte1Byte2),    //  0xDC
            opCode(mnemonic: "*EDDD", dataPattern: dataPatterns.byte1Byte2),    //  0xDD
            opCode(mnemonic: "*EDDE", dataPattern: dataPatterns.byte1Byte2),    //  0xDE
            opCode(mnemonic: "*EDDF", dataPattern: dataPatterns.byte1Byte2),    //  0xDF
            opCode(mnemonic: "*EDE0", dataPattern: dataPatterns.byte1Byte2),    //  0xE0
            opCode(mnemonic: "*EDE1", dataPattern: dataPatterns.byte1Byte2),    //  0xE1
            opCode(mnemonic: "*EDE2", dataPattern: dataPatterns.byte1Byte2),    //  0xE2
            opCode(mnemonic: "*EDE3", dataPattern: dataPatterns.byte1Byte2),    //  0xE3
            opCode(mnemonic: "*EDE4", dataPattern: dataPatterns.byte1Byte2),    //  0xE4
            opCode(mnemonic: "*EDE5", dataPattern: dataPatterns.byte1Byte2),    //  0xE5
            opCode(mnemonic: "*EDE6", dataPattern: dataPatterns.byte1Byte2),    //  0xE6
            opCode(mnemonic: "*EDE7", dataPattern: dataPatterns.byte1Byte2),    //  0xE7
            opCode(mnemonic: "*EDE8", dataPattern: dataPatterns.byte1Byte2),    //  0xE8
            opCode(mnemonic: "*EDE9", dataPattern: dataPatterns.byte1Byte2),    //  0xE9
            opCode(mnemonic: "*EDEA", dataPattern: dataPatterns.byte1Byte2),    //  0xEA
            opCode(mnemonic: "*EDEB", dataPattern: dataPatterns.byte1Byte2),    //  0xEB
            opCode(mnemonic: "*EDEC", dataPattern: dataPatterns.byte1Byte2),    //  0xEC
            opCode(mnemonic: "*EDED", dataPattern: dataPatterns.byte1Byte2),    //  0xED
            opCode(mnemonic: "*EDEE", dataPattern: dataPatterns.byte1Byte2),    //  0xEE
            opCode(mnemonic: "*EDEF", dataPattern: dataPatterns.byte1Byte2),    //  0xEF
            opCode(mnemonic: "*EDF0", dataPattern: dataPatterns.byte1Byte2),    //  0xF0
            opCode(mnemonic: "*EDF1", dataPattern: dataPatterns.byte1Byte2),    //  0xF1
            opCode(mnemonic: "*EDF2", dataPattern: dataPatterns.byte1Byte2),    //  0xF2
            opCode(mnemonic: "*EDF3", dataPattern: dataPatterns.byte1Byte2),    //  0xF3
            opCode(mnemonic: "*EDF4", dataPattern: dataPatterns.byte1Byte2),    //  0xF4
            opCode(mnemonic: "*EDF5", dataPattern: dataPatterns.byte1Byte2),    //  0xF5
            opCode(mnemonic: "*EDF6", dataPattern: dataPatterns.byte1Byte2),    //  0xF6
            opCode(mnemonic: "*EDF7", dataPattern: dataPatterns.byte1Byte2),    //  0xF7
            opCode(mnemonic: "*EDF8", dataPattern: dataPatterns.byte1Byte2),    //  0xF8
            opCode(mnemonic: "*EDF9", dataPattern: dataPatterns.byte1Byte2),    //  0xF9
            opCode(mnemonic: "*EDFA", dataPattern: dataPatterns.byte1Byte2),    //  0xFA
            opCode(mnemonic: "*EDFB", dataPattern: dataPatterns.byte1Byte2),    //  0xFB
            opCode(mnemonic: "*EDFC", dataPattern: dataPatterns.byte1Byte2),    //  0xFC
            opCode(mnemonic: "*EDFD", dataPattern: dataPatterns.byte1Byte2),    //  0xFD
            opCode(mnemonic: "*EDFE", dataPattern: dataPatterns.byte1Byte2),    //  0xFE
            opCode(mnemonic: "*EDFF", dataPattern: dataPatterns.byte1Byte2)     //  0xFF
        ]
        
        let FDPrefixOpcode: [opCode] =
        [
            opCode(mnemonic: "*FD00", dataPattern: dataPatterns.byte1Byte2),    //  0x00
            opCode(mnemonic: "*FD01", dataPattern: dataPatterns.byte1Byte2),   //  0x01
            opCode(mnemonic: "*FD02", dataPattern: dataPatterns.byte1Byte2),    //  0x02
            opCode(mnemonic: "*FD03", dataPattern: dataPatterns.byte1Byte2),    //  0x03
            opCode(mnemonic: "INC B", dataPattern: dataPatterns.byte1Byte2),    //  0x04
            opCode(mnemonic: "DEC B", dataPattern: dataPatterns.byte1Byte2),    //  0x05
            opCode(mnemonic: "LD B,$n", dataPattern: dataPatterns.byte1Byte2N),   //  0x06
            opCode(mnemonic: "*FD07", dataPattern: dataPatterns.byte1Byte2),    //  0x07
            opCode(mnemonic: "*FD08'", dataPattern: dataPatterns.byte1Byte2),    //  0x08
            opCode(mnemonic: "ADD IY,BC", dataPattern: dataPatterns.byte1Byte2),    //  0x09
            opCode(mnemonic: "*FD0A", dataPattern: dataPatterns.byte1Byte2),    //  0x0A
            opCode(mnemonic: "*FD0B", dataPattern: dataPatterns.byte1Byte2),    //  0x0B
            opCode(mnemonic: "INC C", dataPattern: dataPatterns.byte1Byte2),    //  0x0C
            opCode(mnemonic: "DEC C", dataPattern: dataPatterns.byte1Byte2),    //  0x0D
            opCode(mnemonic: "LD C,$n", dataPattern: dataPatterns.byte1Byte2N),   //  0x0E
            opCode(mnemonic: "*FD0F", dataPattern: dataPatterns.byte1Byte2),    //  0x0F
            opCode(mnemonic: "*FD10", dataPattern: dataPatterns.byte1Byte2),  //  0x10
            opCode(mnemonic: "*FD11", dataPattern: dataPatterns.byte1Byte2),   //  0x11
            opCode(mnemonic: "*FD12", dataPattern: dataPatterns.byte1Byte2),    //  0x12
            opCode(mnemonic: "*FD13", dataPattern: dataPatterns.byte1Byte2),    //  0x13
            opCode(mnemonic: "INC D", dataPattern: dataPatterns.byte1Byte2),    //  0x14
            opCode(mnemonic: "DEC D", dataPattern: dataPatterns.byte1Byte2),    //  0x15
            opCode(mnemonic: "LD D,$n", dataPattern: dataPatterns.byte1Byte2N),    //  0x16
            opCode(mnemonic: "*FD17", dataPattern: dataPatterns.byte1Byte2),    //  0x17
            opCode(mnemonic: "*FD18", dataPattern: dataPatterns.byte1Byte2),  //  0x18
            opCode(mnemonic: "ADD IY,DE", dataPattern: dataPatterns.byte1Byte2),    //  0x19
            opCode(mnemonic: "*FD1A", dataPattern: dataPatterns.byte1Byte2),    //  0x1A
            opCode(mnemonic: "*FD1B", dataPattern: dataPatterns.byte1Byte2),    //  0x1B
            opCode(mnemonic: "INC E", dataPattern: dataPatterns.byte1Byte2),    //  0x1C
            opCode(mnemonic: "DEC E", dataPattern: dataPatterns.byte1Byte2),    //  0x1D
            opCode(mnemonic: "LD E,$n", dataPattern: dataPatterns.byte1Byte2N),   //  0x1E
            opCode(mnemonic: "*FD1F", dataPattern: dataPatterns.byte1Byte2),    //  0x1F
            opCode(mnemonic: "*FD20", dataPattern: dataPatterns.byte1Byte2),   //  0x20
            opCode(mnemonic: "LD IY,$nn", dataPattern: dataPatterns.byte1Byte2NN),    //  0x21
            opCode(mnemonic: "LD ($nn),IY", dataPattern: dataPatterns.byte1Byte2NN),   //  0x22
            opCode(mnemonic: "INC IY", dataPattern: dataPatterns.byte1Byte2),    //  0x23
            opCode(mnemonic: "+INC IYH", dataPattern: dataPatterns.byte1Byte2),    //  0x24
            opCode(mnemonic: "+DEC IYH", dataPattern: dataPatterns.byte1Byte2),    //  0x25
            opCode(mnemonic: "+LD IYH,$n", dataPattern: dataPatterns.byte1Byte2N),   //  0x26
            opCode(mnemonic: "*FD27", dataPattern: dataPatterns.byte1Byte2),    //  0x27
            opCode(mnemonic: "*FD28", dataPattern: dataPatterns.byte1Byte2),   //  0x28
            opCode(mnemonic: "ADD IY,IY", dataPattern: dataPatterns.byte1Byte2),    //  0x29
            opCode(mnemonic: "LD IY,($nn)", dataPattern: dataPatterns.byte1Byte2NN),  //  0x2A
            opCode(mnemonic: "DEC IY", dataPattern: dataPatterns.byte1Byte2),    //  0x2B
            opCode(mnemonic: "+INC IYL", dataPattern: dataPatterns.byte1Byte2),    //  0x2C
            opCode(mnemonic: "+DEC IYL", dataPattern: dataPatterns.byte1Byte2),    //  0x2D
            opCode(mnemonic: "+LD IYL,$n", dataPattern: dataPatterns.byte1Byte2N), //  0x2E
            opCode(mnemonic: "*FD2F", dataPattern: dataPatterns.byte1Byte2),    //  0x2F
            opCode(mnemonic: "*FD30", dataPattern: dataPatterns.byte1Byte2),  //  0x30
            opCode(mnemonic: "*FD31", dataPattern: dataPatterns.byte1Byte2),  //  0x31
            opCode(mnemonic: "*FD32", dataPattern: dataPatterns.byte1Byte2),   //  0x32
            opCode(mnemonic: "*FD33", dataPattern: dataPatterns.byte1Byte2),    //  0x33
            opCode(mnemonic: "INC (IY+$d)", dataPattern: dataPatterns.byte1Byte2D),  //  0x34
            opCode(mnemonic: "DEC (IY+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0x35
            opCode(mnemonic: "LD (IY+$d),$n", dataPattern: dataPatterns.byte1Byte2DN),    //  0x36
            opCode(mnemonic: "*FD37", dataPattern: dataPatterns.byte1Byte2),    //  0x37
            opCode(mnemonic: "*FD38", dataPattern: dataPatterns.byte1Byte2),  //  0x38
            opCode(mnemonic: "ADD IY,SP", dataPattern: dataPatterns.byte1Byte2),    //  0x39
            opCode(mnemonic: "*FD3A", dataPattern: dataPatterns.byte1Byte2),   //  0x3A
            opCode(mnemonic: "*FD3B", dataPattern: dataPatterns.byte1Byte2),    //  0x3B
            opCode(mnemonic: "INC A", dataPattern: dataPatterns.byte1Byte2),    //  0x3C
            opCode(mnemonic: "DEC A", dataPattern: dataPatterns.byte1Byte2),    //  0x3D
            opCode(mnemonic: "LD A,$n", dataPattern: dataPatterns.byte1Byte2N), //  0x3E
            opCode(mnemonic: "*FD3F", dataPattern: dataPatterns.byte1Byte2),    //  0x3F
            opCode(mnemonic: "LD B,B", dataPattern: dataPatterns.byte1Byte2),    //  0x40
            opCode(mnemonic: "LD B,C", dataPattern: dataPatterns.byte1Byte2),    //  0x41
            opCode(mnemonic: "LD B,D", dataPattern: dataPatterns.byte1Byte2),    //  0x42
            opCode(mnemonic: "LD B,E", dataPattern: dataPatterns.byte1Byte2),    //  0x43
            opCode(mnemonic: "+LD B,IYH", dataPattern: dataPatterns.byte1Byte2),    //  0x44
            opCode(mnemonic: "+LD B,IYL", dataPattern: dataPatterns.byte1Byte2),    //  0x45
            opCode(mnemonic: "LD B,(IY+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0x46
            opCode(mnemonic: "LD B,A", dataPattern: dataPatterns.byte1Byte2),    //  0x47
            opCode(mnemonic: "LD C,B", dataPattern: dataPatterns.byte1Byte2),    //  0x48
            opCode(mnemonic: "LD C,C", dataPattern: dataPatterns.byte1Byte2),    //  0x49
            opCode(mnemonic: "LD C,D", dataPattern: dataPatterns.byte1Byte2),    //  0x4A
            opCode(mnemonic: "LD C,E", dataPattern: dataPatterns.byte1Byte2),    //  0x4B
            opCode(mnemonic: "+LD C,IYH", dataPattern: dataPatterns.byte1Byte2),    //  0x4C
            opCode(mnemonic: "+LD C,IYL", dataPattern: dataPatterns.byte1Byte2),    //  0x4D
            opCode(mnemonic: "LD C,(IY+$d)", dataPattern: dataPatterns.byte1Byte2D),  //  0x4E
            opCode(mnemonic: "LD C,A", dataPattern: dataPatterns.byte1Byte2),    //  0x4F
            opCode(mnemonic: "LD D,B", dataPattern: dataPatterns.byte1Byte2),    //  0x50
            opCode(mnemonic: "LD D,C", dataPattern: dataPatterns.byte1Byte2),    //  0x51
            opCode(mnemonic: "LD D,D", dataPattern: dataPatterns.byte1Byte2),    //  0x52
            opCode(mnemonic: "LD D,E", dataPattern: dataPatterns.byte1Byte2),    //  0x53
            opCode(mnemonic: "+LD D,IYH", dataPattern: dataPatterns.byte1Byte2),    //  0x54
            opCode(mnemonic: "+LD D,IYL", dataPattern: dataPatterns.byte1Byte2),    //  0x55
            opCode(mnemonic: "LD D,(IY+$d)", dataPattern: dataPatterns.byte1Byte2D), //  0x56
            opCode(mnemonic: "LD D,A", dataPattern: dataPatterns.byte1Byte2),    //  0x57
            opCode(mnemonic: "LD E,B", dataPattern: dataPatterns.byte1Byte2),    //  0x58
            opCode(mnemonic: "LD E,C", dataPattern: dataPatterns.byte1Byte2),    //  0x59
            opCode(mnemonic: "LD E,D", dataPattern: dataPatterns.byte1Byte2),    //  0x5A
            opCode(mnemonic: "LD E,E", dataPattern: dataPatterns.byte1Byte2),    //  0x5B
            opCode(mnemonic: "+LD E,IYH", dataPattern: dataPatterns.byte1Byte2),    //  0x5C
            opCode(mnemonic: "+LD E,IYL", dataPattern: dataPatterns.byte1Byte2),    //  0x5D
            opCode(mnemonic: "LD E,(IY+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0x5E
            opCode(mnemonic: "LD E,A", dataPattern: dataPatterns.byte1Byte2),    //  0x5F
            opCode(mnemonic: "+LD IYH,B", dataPattern: dataPatterns.byte1Byte2),    //  0x60
            opCode(mnemonic: "+LD IYH,C", dataPattern: dataPatterns.byte1Byte2),    //  0x61
            opCode(mnemonic: "+LD IYH,D", dataPattern: dataPatterns.byte1Byte2),    //  0x62
            opCode(mnemonic: "+LD IYH,E", dataPattern: dataPatterns.byte1Byte2),    //  0x63
            opCode(mnemonic: "+LD IYH,IYH", dataPattern: dataPatterns.byte1Byte2),    //  0x64
            opCode(mnemonic: "+LD IYH,IYL", dataPattern: dataPatterns.byte1Byte2),    //  0x65
            opCode(mnemonic: "LD H,(IY+$d)", dataPattern: dataPatterns.byte1Byte2D),  //  0x66
            opCode(mnemonic: "+LD IYH,A", dataPattern: dataPatterns.byte1Byte2),    //  0x67
            opCode(mnemonic: "+LD IYL,B", dataPattern: dataPatterns.byte1Byte2),    //  0x68
            opCode(mnemonic: "+LD IYL,C", dataPattern: dataPatterns.byte1Byte2),    //  0x69
            opCode(mnemonic: "+LD IYL,D", dataPattern: dataPatterns.byte1Byte2),    //  0x6A
            opCode(mnemonic: "+LD IYL,E", dataPattern: dataPatterns.byte1Byte2),    //  0x6B
            opCode(mnemonic: "+LD IYL,IYH", dataPattern: dataPatterns.byte1Byte2),    //  0x6C
            opCode(mnemonic: "+LD IYL,IYL", dataPattern: dataPatterns.byte1Byte2),    //  0x6D
            opCode(mnemonic: "LD L,(IY+$d)", dataPattern: dataPatterns.byte1Byte2D),  //  0x6E
            opCode(mnemonic: "+LD IYL,A", dataPattern: dataPatterns.byte1Byte2),    //  0x6F
            opCode(mnemonic: "LD (IY+$d),B", dataPattern: dataPatterns.byte1Byte2D),    //  0x70
            opCode(mnemonic: "LD (IY+$d),C", dataPattern: dataPatterns.byte1Byte2D),  //  0x71
            opCode(mnemonic: "LD (IY+$d),D", dataPattern: dataPatterns.byte1Byte2D),    //  0x72
            opCode(mnemonic: "LD (IY+$d),E", dataPattern: dataPatterns.byte1Byte2D),  //  0x73
            opCode(mnemonic: "LD (IY+$d),H", dataPattern: dataPatterns.byte1Byte2D),    //  0x74
            opCode(mnemonic: "LD (IY+$d),L", dataPattern: dataPatterns.byte1Byte2D),   //  0x75
            opCode(mnemonic: "*FD76", dataPattern: dataPatterns.byte1Byte2),    //  0x76
            opCode(mnemonic: "LD (IY+$d),A", dataPattern: dataPatterns.byte1Byte2D),    //  0x77
            opCode(mnemonic: "LD A,B", dataPattern: dataPatterns.byte1Byte2),    //  0x78
            opCode(mnemonic: "LD A,C", dataPattern: dataPatterns.byte1Byte2),    //  0x79
            opCode(mnemonic: "LD A,D", dataPattern: dataPatterns.byte1Byte2),    //  0x7A
            opCode(mnemonic: "LD A,E", dataPattern: dataPatterns.byte1Byte2),    //  0x7B
            opCode(mnemonic: "+LD A,IYH", dataPattern: dataPatterns.byte1Byte2),    //  0x7C
            opCode(mnemonic: "+LD A,IYL", dataPattern: dataPatterns.byte1Byte2),    //  0x7D
            opCode(mnemonic: "LD A,(IY+$d)", dataPattern: dataPatterns.byte1Byte2D),    //  0x7E
            opCode(mnemonic: "LD A,A", dataPattern: dataPatterns.byte1Byte2),    //  0x7F
            opCode(mnemonic: "ADD A,B", dataPattern: dataPatterns.byte1Byte2),    //  0x80
            opCode(mnemonic: "ADD A,C", dataPattern: dataPatterns.byte1Byte2),    //  0x81
            opCode(mnemonic: "ADD A,D", dataPattern: dataPatterns.byte1Byte2),    //  0x82
            opCode(mnemonic: "ADD A,E", dataPattern: dataPatterns.byte1Byte2),    //  0x83
            opCode(mnemonic: "+ADD A,IYH", dataPattern: dataPatterns.byte1Byte2),    //  0x84
            opCode(mnemonic: "+ADD A,IYL", dataPattern: dataPatterns.byte1Byte2),    //  0x85
            opCode(mnemonic: "ADD A,(IY+$d)", dataPattern: dataPatterns.byte1Byte2D),  //  0x86
            opCode(mnemonic: "ADD A,A", dataPattern: dataPatterns.byte1Byte2),    //  0x87
            opCode(mnemonic: "ADC A,B", dataPattern: dataPatterns.byte1Byte2),    //  0x88
            opCode(mnemonic: "ADC A,C", dataPattern: dataPatterns.byte1Byte2),    //  0x89
            opCode(mnemonic: "ADC A,D", dataPattern: dataPatterns.byte1Byte2),    //  0x8A
            opCode(mnemonic: "ADC A,E", dataPattern: dataPatterns.byte1Byte2),    //  0x8B
            opCode(mnemonic: "+ADC A,IYH", dataPattern: dataPatterns.byte1Byte2),    //  0x8C
            opCode(mnemonic: "+ADC A,IYL", dataPattern: dataPatterns.byte1Byte2),    //  0x8D
            opCode(mnemonic: "ADC A,(IY+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0x8E
            opCode(mnemonic: "ADC A,A", dataPattern: dataPatterns.byte1Byte2),    //  0x8F
            opCode(mnemonic: "SUB B", dataPattern: dataPatterns.byte1Byte2),    //  0x90
            opCode(mnemonic: "SUB C", dataPattern: dataPatterns.byte1Byte2),    //  0x91
            opCode(mnemonic: "SUB D", dataPattern: dataPatterns.byte1Byte2),    //  0x92
            opCode(mnemonic: "SUB E", dataPattern: dataPatterns.byte1Byte2),    //  0x93
            opCode(mnemonic: "+SUB IYH", dataPattern: dataPatterns.byte1Byte2),    //  0x94
            opCode(mnemonic: "+SUB IYL", dataPattern: dataPatterns.byte1Byte2),    //  0x95
            opCode(mnemonic: "SUB (IY+$d)", dataPattern: dataPatterns.byte1Byte2D),  //  0x96
            opCode(mnemonic: "SUB A", dataPattern: dataPatterns.byte1Byte2),    //  0x97
            opCode(mnemonic: "SBC A,B", dataPattern: dataPatterns.byte1Byte2),    //  0x98
            opCode(mnemonic: "SBC A,C", dataPattern: dataPatterns.byte1Byte2),    //  0x99
            opCode(mnemonic: "SBC A,D", dataPattern: dataPatterns.byte1Byte2),    //  0x9A
            opCode(mnemonic: "SBC A,E", dataPattern: dataPatterns.byte1Byte2),    //  0x9B
            opCode(mnemonic: "+SBC A,IYH", dataPattern: dataPatterns.byte1Byte2),    //  0x9C
            opCode(mnemonic: "+SBC A,IYL", dataPattern: dataPatterns.byte1Byte2),    //  0x9D
            opCode(mnemonic: "SBC A,(IY+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0x9E
            opCode(mnemonic: "SBC A,A", dataPattern: dataPatterns.byte1Byte2),    //  0x9F
            opCode(mnemonic: "AND B", dataPattern: dataPatterns.byte1Byte2),    //  0xA0
            opCode(mnemonic: "AND C", dataPattern: dataPatterns.byte1Byte2),    //  0xA1
            opCode(mnemonic: "AND D", dataPattern: dataPatterns.byte1Byte2),    //  0xA2
            opCode(mnemonic: "AND E", dataPattern: dataPatterns.byte1Byte2),    //  0xA3
            opCode(mnemonic: "+AND IYH", dataPattern: dataPatterns.byte1Byte2),    //  0xA4
            opCode(mnemonic: "+AND IYL", dataPattern: dataPatterns.byte1Byte2),    //  0xA5
            opCode(mnemonic: "AND (IY+$d)", dataPattern: dataPatterns.byte1Byte2D),  //  0xA6
            opCode(mnemonic: "AND A", dataPattern: dataPatterns.byte1Byte2),    //  0xA7
            opCode(mnemonic: "XOR B", dataPattern: dataPatterns.byte1Byte2),    //  0xA8
            opCode(mnemonic: "XOR C", dataPattern: dataPatterns.byte1Byte2),    //  0xA9
            opCode(mnemonic: "XOR D", dataPattern: dataPatterns.byte1Byte2),    //  0xAA
            opCode(mnemonic: "XOR E", dataPattern: dataPatterns.byte1Byte2),    //  0xAB
            opCode(mnemonic: "+XOR IYH", dataPattern: dataPatterns.byte1Byte2),    //  0xAC
            opCode(mnemonic: "+XOR IYL", dataPattern: dataPatterns.byte1Byte2),    //  0xAD
            opCode(mnemonic: "XOR (IY+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0xAE
            opCode(mnemonic: "XOR A", dataPattern: dataPatterns.byte1Byte2),    //  0xAF
            opCode(mnemonic: "OR B", dataPattern: dataPatterns.byte1Byte2),    //  0xB0
            opCode(mnemonic: "OR C", dataPattern: dataPatterns.byte1Byte2),    //  0xB1
            opCode(mnemonic: "OR D", dataPattern: dataPatterns.byte1Byte2),    //  0xB2
            opCode(mnemonic: "OR E", dataPattern: dataPatterns.byte1Byte2),    //  0xB3
            opCode(mnemonic: "+OR IYH", dataPattern: dataPatterns.byte1Byte2),    //  0xB4
            opCode(mnemonic: "+OR IYL", dataPattern: dataPatterns.byte1Byte2),    //  0xB5
            opCode(mnemonic: "OR (IY+$d)", dataPattern: dataPatterns.byte1Byte2D),  //  0xB6
            opCode(mnemonic: "OR A", dataPattern: dataPatterns.byte1Byte2),    //  0xB7
            opCode(mnemonic: "CP B", dataPattern: dataPatterns.byte1Byte2),    //  0xB8
            opCode(mnemonic: "CP C", dataPattern: dataPatterns.byte1Byte2),    //  0xB9
            opCode(mnemonic: "CP D", dataPattern: dataPatterns.byte1Byte2),    //  0xBA
            opCode(mnemonic: "CP E", dataPattern: dataPatterns.byte1Byte2),    //  0xBB
            opCode(mnemonic: "+CP IYH", dataPattern: dataPatterns.byte1Byte2),    //  0xBC
            opCode(mnemonic: "+CP IYL", dataPattern: dataPatterns.byte1Byte2),    //  0xBD
            opCode(mnemonic: "CP (IY+$d)", dataPattern: dataPatterns.byte1Byte2D),   //  0xBE
            opCode(mnemonic: "CP A", dataPattern: dataPatterns.byte1Byte2),    //  0xBF
            opCode(mnemonic: "*FDC0", dataPattern: dataPatterns.byte1Byte2),    //  0xC0
            opCode(mnemonic: "*FDC1", dataPattern: dataPatterns.byte1Byte2),    //  0xC1
            opCode(mnemonic: "*FDC2", dataPattern: dataPatterns.byte1Byte2),   //  0xC2
            opCode(mnemonic: "*FDC3", dataPattern: dataPatterns.byte1Byte2),   //  0xC3
            opCode(mnemonic: "*FDC4", dataPattern: dataPatterns.byte1Byte2),   //  0xC4
            opCode(mnemonic: "*FDC5", dataPattern: dataPatterns.byte1Byte2),    //  0xC5
            opCode(mnemonic: "*FDC6", dataPattern: dataPatterns.byte1Byte2),   //  0xC6
            opCode(mnemonic: "*FDC7", dataPattern: dataPatterns.byte1Byte2),    //  0xC7
            opCode(mnemonic: "*FDC8", dataPattern: dataPatterns.byte1Byte2),    //  0xC8
            opCode(mnemonic: "*FDC9", dataPattern: dataPatterns.byte1Byte2),    //  0xC9
            opCode(mnemonic: "*FDCA", dataPattern: dataPatterns.byte1Byte2),   //  0xCA
            opCode(mnemonic: "*FDCB prefix", dataPattern: dataPatterns.byte1Byte2),    //  0xCB
            opCode(mnemonic: "*FDCC", dataPattern: dataPatterns.byte1Byte2),   //  0xCC
            opCode(mnemonic: "*FDCD", dataPattern: dataPatterns.byte1Byte2),  //  0xCD
            opCode(mnemonic: "*FDCE", dataPattern: dataPatterns.byte1Byte2),   //  0xCE
            opCode(mnemonic: "*FDCF", dataPattern: dataPatterns.byte1Byte2),    //  0xCF
            opCode(mnemonic: "*FDD0", dataPattern: dataPatterns.byte1Byte2),    //  0xD0
            opCode(mnemonic: "*FDD1", dataPattern: dataPatterns.byte1Byte2),    //  0xD1
            opCode(mnemonic: "*FDD2", dataPattern: dataPatterns.byte1Byte2),   //  0xD2
            opCode(mnemonic: "*FDD3", dataPattern: dataPatterns.byte1Byte2),   //  0xD3
            opCode(mnemonic: "*FDD4", dataPattern: dataPatterns.byte1Byte2),   //  0xD4
            opCode(mnemonic: "*FDD5", dataPattern: dataPatterns.byte1Byte2),    //  0xD5
            opCode(mnemonic: "*FDD6", dataPattern: dataPatterns.byte1Byte2),  //  0xD6
            opCode(mnemonic: "*FDD7", dataPattern: dataPatterns.byte1Byte2),    //  0xD7
            opCode(mnemonic: "*FDD8", dataPattern: dataPatterns.byte1Byte2),    //  0xD8
            opCode(mnemonic: "*FDD9", dataPattern: dataPatterns.byte1Byte2),    //  0xD9
            opCode(mnemonic: "*FDDA", dataPattern: dataPatterns.byte1Byte2),  //  0xDA
            opCode(mnemonic: "*FDDB", dataPattern: dataPatterns.byte1Byte2),   //  0xDB
            opCode(mnemonic: "*FDDC", dataPattern: dataPatterns.byte1Byte2),   //  0xDC
            opCode(mnemonic: "*FDDD", dataPattern: dataPatterns.byte1Byte2),    //  0xDD
            opCode(mnemonic: "*FDDE", dataPattern: dataPatterns.byte1Byte2),   //  0xDE
            opCode(mnemonic: "*FDDF", dataPattern: dataPatterns.byte1Byte2),    //  0xDF
            opCode(mnemonic: "*FDE0", dataPattern: dataPatterns.byte1Byte2),    //  0xE0
            opCode(mnemonic: "POP IY", dataPattern: dataPatterns.byte1Byte2),    //  0xE1
            opCode(mnemonic: "*FDE2", dataPattern: dataPatterns.byte1Byte2),  //  0xE2
            opCode(mnemonic: "EX (SP),IY", dataPattern: dataPatterns.byte1Byte2),    //  0xE3
            opCode(mnemonic: "*FDE4", dataPattern: dataPatterns.byte1Byte2),   //  0xE4
            opCode(mnemonic: "PUSH IY", dataPattern: dataPatterns.byte1Byte2),    //  0xE5
            opCode(mnemonic: "*FDE6", dataPattern: dataPatterns.byte1Byte2),  //  0xE6
            opCode(mnemonic: "*FDE7", dataPattern: dataPatterns.byte1Byte2),    //  0xE7
            opCode(mnemonic: "*FDE8", dataPattern: dataPatterns.byte1Byte2),    //  0xE8
            opCode(mnemonic: "JP (IY)", dataPattern: dataPatterns.byte1Byte2),    //  0xE9
            opCode(mnemonic: "*FDEA", dataPattern: dataPatterns.byte1Byte2),   //  0xEA
            opCode(mnemonic: "*FDEB", dataPattern: dataPatterns.byte1Byte2),    //  0xEB
            opCode(mnemonic: "*FDEC", dataPattern: dataPatterns.byte1Byte2), //  0xEC
            opCode(mnemonic: "*FDED", dataPattern: dataPatterns.byte1Byte2),    //  0xED
            opCode(mnemonic: "*FDEE", dataPattern: dataPatterns.byte1Byte2),  //  0xEE
            opCode(mnemonic: "*FDEF", dataPattern: dataPatterns.byte1Byte2),    //  0xEF
            opCode(mnemonic: "*FDF0", dataPattern: dataPatterns.byte1Byte2),    //  0xF0
            opCode(mnemonic: "*FDF1", dataPattern: dataPatterns.byte1Byte2),    //  0xF1
            opCode(mnemonic: "*FDF2", dataPattern: dataPatterns.byte1Byte2),   //  0xF2
            opCode(mnemonic: "*FDF3", dataPattern: dataPatterns.byte1Byte2),    //  0xF3
            opCode(mnemonic: "*FDF4", dataPattern: dataPatterns.byte1Byte2),  //  0xF4
            opCode(mnemonic: "*FDF5", dataPattern: dataPatterns.byte1Byte2),    //  0xF5
            opCode(mnemonic: "*FDF6", dataPattern: dataPatterns.byte1Byte2),   //  0xF6
            opCode(mnemonic: "*FDF7", dataPattern: dataPatterns.byte1Byte2),    //  0xF7
            opCode(mnemonic: "*FDF8", dataPattern: dataPatterns.byte1Byte2),    //  0xF8
            opCode(mnemonic: "LD SP,IY", dataPattern: dataPatterns.byte1Byte2),    //  0xF9
            opCode(mnemonic: "*FDFA", dataPattern: dataPatterns.byte1Byte2),  //  0xFA
            opCode(mnemonic: "*FDFB", dataPattern: dataPatterns.byte1Byte2),    //  0xFB
            opCode(mnemonic: "*FDFC", dataPattern: dataPatterns.byte1Byte2),   //  0xFC
            opCode(mnemonic: "*FDFD", dataPattern: dataPatterns.byte1Byte2),    //  0xFD
            opCode(mnemonic: "*FDFE", dataPattern: dataPatterns.byte1Byte2),   //  0xFE
            opCode(mnemonic: "*FDFF", dataPattern: dataPatterns.byte1Byte2)    //  0xFF
        ]
        
        let DDCBPrefixOpcode: [opCode] =
        [
            opCode(mnemonic: "+RLC (IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x00
            opCode(mnemonic: "+RLC (IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x01
            opCode(mnemonic: "+RLC (IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x02
            opCode(mnemonic: "+RLC (IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),   //  0x03
            opCode(mnemonic: "+RLC (IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),   //  0x04
            opCode(mnemonic: "+RLC (IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),   //  0x05
            opCode(mnemonic: "RLC (IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),     //  0x06
            opCode(mnemonic: "+RLC (IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),   //  0x07
            opCode(mnemonic: "+RRC (IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),   //  0x08
            opCode(mnemonic: "+RRC (IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x09
            opCode(mnemonic: "+RRC (IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x0A
            opCode(mnemonic: "+RRC (IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),   //  0x0B
            opCode(mnemonic: "+RRC (IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),   //  0x0C
            opCode(mnemonic: "+RRC (IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),   //  0x0D
            opCode(mnemonic: "RRC (IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),  //  0x0E
            opCode(mnemonic: "+RRC (IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),   //  0x0F
            opCode(mnemonic: "+RL (IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),  //  0x10
            opCode(mnemonic: "+RL (IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x11
            opCode(mnemonic: "+RL (IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),   //  0x12
            opCode(mnemonic: "+RL (IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x13
            opCode(mnemonic: "+RL (IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),   //  0x14
            opCode(mnemonic: "+RL (IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),   //  0x15
            opCode(mnemonic: "RL (IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x16
            opCode(mnemonic: "+RL (IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),   //  0x17
            opCode(mnemonic: "+RR (IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x18
            opCode(mnemonic: "+RR (IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x19
            opCode(mnemonic: "+RR (IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x1A
            opCode(mnemonic: "+RR (IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x1B
            opCode(mnemonic: "+RR (IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x1C
            opCode(mnemonic: "+RR (IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x1D
            opCode(mnemonic: "RR (IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x1E
            opCode(mnemonic: "+RR (IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x1F
            opCode(mnemonic: "+SLA (IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x20
            opCode(mnemonic: "+SLA (IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x21
            opCode(mnemonic: "+SLA (IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x22
            opCode(mnemonic: "+SLA (IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x23
            opCode(mnemonic: "+SLA (IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x24
            opCode(mnemonic: "+SLA (IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x25
            opCode(mnemonic: "SLA (IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x26
            opCode(mnemonic: "+SLA (IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x27
            opCode(mnemonic: "+SRA (IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x28
            opCode(mnemonic: "+SRA (IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x29
            opCode(mnemonic: "+SRA (IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x2A
            opCode(mnemonic: "+SRA (IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x2B
            opCode(mnemonic: "+SRA (IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x2C
            opCode(mnemonic: "+SRA (IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x2D
            opCode(mnemonic: "SRA (IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x2E
            opCode(mnemonic: "+SRA (IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x2F
            opCode(mnemonic: "+SLL (IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x30
            opCode(mnemonic: "+SLL (IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x31
            opCode(mnemonic: "+SLL (IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x32
            opCode(mnemonic: "+SLL (IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x33
            opCode(mnemonic: "+SLL (IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x34
            opCode(mnemonic: "+SLL (IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x35
            opCode(mnemonic: "+SLL (IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x36
            opCode(mnemonic: "+SLL (IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x37
            opCode(mnemonic: "+SRL (IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x38
            opCode(mnemonic: "+SRL (IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x39
            opCode(mnemonic: "+SRL (IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x3A
            opCode(mnemonic: "+SRL (IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x3B
            opCode(mnemonic: "+SRL (IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x3C
            opCode(mnemonic: "+SRL (IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x3D
            opCode(mnemonic: "SRL (IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x3E
            opCode(mnemonic: "+SRL (IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x3F
            opCode(mnemonic: "+BIT 0,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x40
            opCode(mnemonic: "+BIT 0,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x41
            opCode(mnemonic: "+BIT 0,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x42
            opCode(mnemonic: "+BIT 0,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x43
            opCode(mnemonic: "+BIT 0,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x44
            opCode(mnemonic: "+BIT 0,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x45
            opCode(mnemonic: "+BIT 0,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x46
            opCode(mnemonic: "+BIT 0,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x47
            opCode(mnemonic: "+BIT 1,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x48
            opCode(mnemonic: "+BIT 1,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x49
            opCode(mnemonic: "+BIT 1,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x4A
            opCode(mnemonic: "+BIT 1,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x4B
            opCode(mnemonic: "+BIT 1,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x4C
            opCode(mnemonic: "+BIT 1,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x4D
            opCode(mnemonic: "+BIT 1,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x4E
            opCode(mnemonic: "+BIT 1,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x4F
            opCode(mnemonic: "+BIT 2,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x50
            opCode(mnemonic: "+BIT 2,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x51
            opCode(mnemonic: "+BIT 2,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x52
            opCode(mnemonic: "+BIT 2,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x53
            opCode(mnemonic: "+BIT 2,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x54
            opCode(mnemonic: "+BIT 2,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x55
            opCode(mnemonic: "+BIT 2,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x56
            opCode(mnemonic: "+BIT 2,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x57
            opCode(mnemonic: "+BIT 3,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x58
            opCode(mnemonic: "+BIT 3,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x59
            opCode(mnemonic: "+BIT 3,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x5A
            opCode(mnemonic: "+BIT 3,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x5B
            opCode(mnemonic: "+BIT 3,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x5C
            opCode(mnemonic: "+BIT 3,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x5D
            opCode(mnemonic: "+BIT 3,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x5E
            opCode(mnemonic: "+BIT 3,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x5F
            opCode(mnemonic: "+BIT 4,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x60
            opCode(mnemonic: "+BIT 4,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x61
            opCode(mnemonic: "+BIT 4,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x62
            opCode(mnemonic: "+BIT 4,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x63
            opCode(mnemonic: "+BIT 4,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x64
            opCode(mnemonic: "+BIT 4,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x65
            opCode(mnemonic: "+BIT 4,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x66
            opCode(mnemonic: "+BIT 4,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x67
            opCode(mnemonic: "+BIT 5,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x68
            opCode(mnemonic: "+BIT 5,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x69
            opCode(mnemonic: "+BIT 5,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x6A
            opCode(mnemonic: "+BIT 5,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x6B
            opCode(mnemonic: "+BIT 5,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x6C
            opCode(mnemonic: "+BIT 5,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x6D
            opCode(mnemonic: "+BIT 5,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x6E
            opCode(mnemonic: "+BIT 5,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x6F
            opCode(mnemonic: "+BIT 6,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x70
            opCode(mnemonic: "+BIT 6,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x71
            opCode(mnemonic: "+BIT 6,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x72
            opCode(mnemonic: "+BIT 6,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x73
            opCode(mnemonic: "+BIT 6,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x74
            opCode(mnemonic: "+BIT 6,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x75
            opCode(mnemonic: "+BIT 6,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x76
            opCode(mnemonic: "+BIT 6,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x77
            opCode(mnemonic: "+BIT 7,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x78
            opCode(mnemonic: "+BIT 7,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x79
            opCode(mnemonic: "+BIT 7,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x7A
            opCode(mnemonic: "+BIT 7,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x7B
            opCode(mnemonic: "+BIT 7,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x7C
            opCode(mnemonic: "+BIT 7,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x7D
            opCode(mnemonic: "+BIT 7,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x7E
            opCode(mnemonic: "+BIT 7,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x7F
            opCode(mnemonic: "+RES 0,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x80
            opCode(mnemonic: "+RES 0,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x81
            opCode(mnemonic: "+RES 0,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x82
            opCode(mnemonic: "+RES 0,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x83
            opCode(mnemonic: "+RES 0,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x84
            opCode(mnemonic: "+RES 0,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x85
            opCode(mnemonic: "RES 0,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x86
            opCode(mnemonic: "+RES 0,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x87
            opCode(mnemonic: "+RES 1,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x88
            opCode(mnemonic: "+RES 1,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x89
            opCode(mnemonic: "+RES 1,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x8A
            opCode(mnemonic: "+RES 1,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x8B
            opCode(mnemonic: "+RES 1,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x8C
            opCode(mnemonic: "+RES 1,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x8D
            opCode(mnemonic: "RES 1,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x8E
            opCode(mnemonic: "+RES 1,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x8F
            opCode(mnemonic: "+RES 2,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x90
            opCode(mnemonic: "+RES 2,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x91
            opCode(mnemonic: "+RES 2,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x92
            opCode(mnemonic: "+RES 2,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x93
            opCode(mnemonic: "+RES 2,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x94
            opCode(mnemonic: "+RES 2,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x95
            opCode(mnemonic: "RES 2,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x96
            opCode(mnemonic: "+RES 2,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x97
            opCode(mnemonic: "+RES 3,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x98
            opCode(mnemonic: "+RES 3,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x99
            opCode(mnemonic: "+RES 3,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x9A
            opCode(mnemonic: "+RES 3,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x9B
            opCode(mnemonic: "+RES 3,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x9C
            opCode(mnemonic: "+RES 3,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x9D
            opCode(mnemonic: "RES 3,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x9E
            opCode(mnemonic: "+RES 3,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x9F
            opCode(mnemonic: "+RES 4,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA0
            opCode(mnemonic: "+RES 4,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA1
            opCode(mnemonic: "+RES 4,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA2
            opCode(mnemonic: "+RES 4,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA3
            opCode(mnemonic: "+RES 4,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA4
            opCode(mnemonic: "+RES 4,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA5
            opCode(mnemonic: "RES 4,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA6
            opCode(mnemonic: "+RES 4,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA7
            opCode(mnemonic: "+RES 5,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA8
            opCode(mnemonic: "+RES 5,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA9
            opCode(mnemonic: "+RES 5,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xAA
            opCode(mnemonic: "+RES 5,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xAB
            opCode(mnemonic: "+RES 5,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xAC
            opCode(mnemonic: "+RES 5,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xAD
            opCode(mnemonic: "RES 5,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xAE
            opCode(mnemonic: "+RES 5,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xAF
            opCode(mnemonic: "+RES 6,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB0
            opCode(mnemonic: "+RES 6,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB1
            opCode(mnemonic: "+RES 6,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB2
            opCode(mnemonic: "+RES 6,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB3
            opCode(mnemonic: "+RES 6,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB4
            opCode(mnemonic: "+RES 6,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB5
            opCode(mnemonic: "RES 6,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB6
            opCode(mnemonic: "+RES 6,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB7
            opCode(mnemonic: "+RES 7,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB8
            opCode(mnemonic: "+RES 7,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB9
            opCode(mnemonic: "+RES 7,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xBA
            opCode(mnemonic: "+RES 7,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xBB
            opCode(mnemonic: "+RES 7,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xBC
            opCode(mnemonic: "+RES 7,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xBD
            opCode(mnemonic: "RES 7,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xBE
            opCode(mnemonic: "+RES 7,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xBF
            opCode(mnemonic: "+SET 0,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC0
            opCode(mnemonic: "+SET 0,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC1
            opCode(mnemonic: "+SET 0,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC2
            opCode(mnemonic: "+SET 0,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC3
            opCode(mnemonic: "+SET 0,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC4
            opCode(mnemonic: "+SET 0,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC5
            opCode(mnemonic: "SET 0,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC6
            opCode(mnemonic: "+SET 0,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC7
            opCode(mnemonic: "+SET 1,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC8
            opCode(mnemonic: "+SET 1,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC9
            opCode(mnemonic: "+SET 1,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xCA
            opCode(mnemonic: "+SET 1,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xCB
            opCode(mnemonic: "+SET 1,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xCC
            opCode(mnemonic: "+SET 1,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xCD
            opCode(mnemonic: "SET 1,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xCE
            opCode(mnemonic: "+SET 1,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xCF
            opCode(mnemonic: "+SET 2,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD0
            opCode(mnemonic: "+SET 2,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD1
            opCode(mnemonic: "+SET 2,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD2
            opCode(mnemonic: "+SET 2,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD3
            opCode(mnemonic: "+SET 2,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD4
            opCode(mnemonic: "+SET 2,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD5
            opCode(mnemonic: "SET 2,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD6
            opCode(mnemonic: "+SET 2,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD7
            opCode(mnemonic: "+SET 3,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD8
            opCode(mnemonic: "+SET 3,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD9
            opCode(mnemonic: "+SET 3,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xDA
            opCode(mnemonic: "+SET 3,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xDB
            opCode(mnemonic: "+SET 3,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xDC
            opCode(mnemonic: "+SET 3,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xDD
            opCode(mnemonic: "SET 3,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xDE
            opCode(mnemonic: "+SET 3,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xDF
            opCode(mnemonic: "+SET 4,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE0
            opCode(mnemonic: "+SET 4,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE1
            opCode(mnemonic: "+SET 4,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE2
            opCode(mnemonic: "+SET 4,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE3
            opCode(mnemonic: "+SET 4,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE4
            opCode(mnemonic: "+SET 4,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE5
            opCode(mnemonic: "SET 4,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE6
            opCode(mnemonic: "+SET 4,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE7
            opCode(mnemonic: "+SET 5,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE8
            opCode(mnemonic: "+SET 5,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE9
            opCode(mnemonic: "+SET 5,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xEA
            opCode(mnemonic: "+SET 5,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xEB
            opCode(mnemonic: "+SET 5,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xEC
            opCode(mnemonic: "+SET 5,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xED
            opCode(mnemonic: "SET 5,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xEE
            opCode(mnemonic: "+SET 5,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xEF
            opCode(mnemonic: "+SET 6,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF0
            opCode(mnemonic: "+SET 6,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF1
            opCode(mnemonic: "+SET 6,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF2
            opCode(mnemonic: "+SET 6,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF3
            opCode(mnemonic: "+SET 6,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF4
            opCode(mnemonic: "+SET 6,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF5
            opCode(mnemonic: "SET 6,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF6
            opCode(mnemonic: "+SET 6,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF7
            opCode(mnemonic: "+SET 7,(IX+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF8
            opCode(mnemonic: "+SET 7,(IX+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF9
            opCode(mnemonic: "+SET 7,(IX+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xFA
            opCode(mnemonic: "+SET 7,(IX+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xFB
            opCode(mnemonic: "+SET 7,(IX+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xFC
            opCode(mnemonic: "+SET 7,(IX+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xFD
            opCode(mnemonic: "SET 7,(IX+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xFE
            opCode(mnemonic: "+SET 7,(IX+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4)    //  0xFF
        ]
        
        let FDCBPrefixOpcode: [opCode] =
        [
            opCode(mnemonic: "+RLC (IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x00
            opCode(mnemonic: "+RLC (IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x01
            opCode(mnemonic: "+RLC (IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x02
            opCode(mnemonic: "+RLC (IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x03
            opCode(mnemonic: "+RLC (IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x04
            opCode(mnemonic: "+RLC (IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x05
            opCode(mnemonic: "RLC (IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x06
            opCode(mnemonic: "+RLC (IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x07
            opCode(mnemonic: "+RRC (IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x08
            opCode(mnemonic: "+RRC (IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x09
            opCode(mnemonic: "+RRC (IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x0A
            opCode(mnemonic: "+RRC (IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x0B
            opCode(mnemonic: "+RRC (IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x0C
            opCode(mnemonic: "+RRC (IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x0D
            opCode(mnemonic: "RRC (IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x0E
            opCode(mnemonic: "+RRC (IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x0F
            opCode(mnemonic: "+RL (IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x10
            opCode(mnemonic: "+RL (IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x11
            opCode(mnemonic: "+RL (IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x12
            opCode(mnemonic: "+RL (IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x13
            opCode(mnemonic: "+RL (IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x14
            opCode(mnemonic: "+RL (IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x15
            opCode(mnemonic: "RL (IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x16
            opCode(mnemonic: "+RL (IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x17
            opCode(mnemonic: "+RR (IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x18
            opCode(mnemonic: "+RR (IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x19
            opCode(mnemonic: "+RR (IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x1A
            opCode(mnemonic: "+RR (IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x1B
            opCode(mnemonic: "+RR (IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x1C
            opCode(mnemonic: "+RR (IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x1D
            opCode(mnemonic: "RR (IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x1E
            opCode(mnemonic: "+RR (IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x1F
            opCode(mnemonic: "+SLA (IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x20
            opCode(mnemonic: "+SLA (IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x21
            opCode(mnemonic: "+SLA (IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x22
            opCode(mnemonic: "+SLA (IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x23
            opCode(mnemonic: "+SLA (IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x24
            opCode(mnemonic: "+SLA (IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x25
            opCode(mnemonic: "SLA (IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x26
            opCode(mnemonic: "+SLA (IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x27
            opCode(mnemonic: "+SRA (IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x28
            opCode(mnemonic: "+SRA (IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x29
            opCode(mnemonic: "+SRA (IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x2A
            opCode(mnemonic: "+SRA (IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x2B
            opCode(mnemonic: "+SRA (IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x2C
            opCode(mnemonic: "+SRA (IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x2D
            opCode(mnemonic: "SRA (IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x2E
            opCode(mnemonic: "+SRA (IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x2F
            opCode(mnemonic: "+SLL (IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x30
            opCode(mnemonic: "+SLL (IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x31
            opCode(mnemonic: "+SLL (IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x32
            opCode(mnemonic: "+SLL (IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x33
            opCode(mnemonic: "+SLL (IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x34
            opCode(mnemonic: "+SLL (IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x35
            opCode(mnemonic: "+SLL (IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x36
            opCode(mnemonic: "+SLL (IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x37
            opCode(mnemonic: "+SRL (IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x38
            opCode(mnemonic: "+SRL (IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x39
            opCode(mnemonic: "+SRL (IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x3A
            opCode(mnemonic: "+SRL (IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x3B
            opCode(mnemonic: "+SRL (IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x3C
            opCode(mnemonic: "+SRL (IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x3D
            opCode(mnemonic: "SRL (IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),      //  0x3E
            opCode(mnemonic: "+SRL (IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x3F
            opCode(mnemonic: "+BIT 0,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x40
            opCode(mnemonic: "+BIT 0,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x41
            opCode(mnemonic: "+BIT 0,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x42
            opCode(mnemonic: "+BIT 0,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x43
            opCode(mnemonic: "+BIT 0,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x44
            opCode(mnemonic: "+BIT 0,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x45
            opCode(mnemonic: "+BIT 0,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x46
            opCode(mnemonic: "+BIT 0,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x47
            opCode(mnemonic: "+BIT 1,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x48
            opCode(mnemonic: "+BIT 1,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x49
            opCode(mnemonic: "+BIT 1,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x4A
            opCode(mnemonic: "+BIT 1,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x4B
            opCode(mnemonic: "+BIT 1,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x4C
            opCode(mnemonic: "+BIT 1,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x4D
            opCode(mnemonic: "+BIT 1,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x4E
            opCode(mnemonic: "+BIT 1,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x4F
            opCode(mnemonic: "+BIT 2,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x50
            opCode(mnemonic: "+BIT 2,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x51
            opCode(mnemonic: "+BIT 2,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x52
            opCode(mnemonic: "+BIT 2,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x53
            opCode(mnemonic: "+BIT 2,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x54
            opCode(mnemonic: "+BIT 2,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x55
            opCode(mnemonic: "+BIT 2,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x56
            opCode(mnemonic: "+BIT 2,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x57
            opCode(mnemonic: "+BIT 3,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x58
            opCode(mnemonic: "+BIT 3,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x59
            opCode(mnemonic: "+BIT 3,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x5A
            opCode(mnemonic: "+BIT 3,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x5B
            opCode(mnemonic: "+BIT 3,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x5C
            opCode(mnemonic: "+BIT 3,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x5D
            opCode(mnemonic: "+BIT 3,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x5E
            opCode(mnemonic: "+BIT 3,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x5F
            opCode(mnemonic: "+BIT 4,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x60
            opCode(mnemonic: "+BIT 4,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x61
            opCode(mnemonic: "+BIT 4,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x62
            opCode(mnemonic: "+BIT 4,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x63
            opCode(mnemonic: "+BIT 4,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x64
            opCode(mnemonic: "+BIT 4,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x65
            opCode(mnemonic: "+BIT 4,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x66
            opCode(mnemonic: "+BIT 4,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x67
            opCode(mnemonic: "+BIT 5,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x68
            opCode(mnemonic: "+BIT 5,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x69
            opCode(mnemonic: "+BIT 5,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x6A
            opCode(mnemonic: "+BIT 5,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x6B
            opCode(mnemonic: "+BIT 5,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x6C
            opCode(mnemonic: "+BIT 5,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x6D
            opCode(mnemonic: "+BIT 5,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x6E
            opCode(mnemonic: "+BIT 5,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x6F
            opCode(mnemonic: "+BIT 6,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x70
            opCode(mnemonic: "+BIT 6,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x71
            opCode(mnemonic: "+BIT 6,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x72
            opCode(mnemonic: "+BIT 6,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x73
            opCode(mnemonic: "+BIT 6,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x74
            opCode(mnemonic: "+BIT 6,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x75
            opCode(mnemonic: "+BIT 6,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x76
            opCode(mnemonic: "+BIT 6,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x77
            opCode(mnemonic: "+BIT 7,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x78
            opCode(mnemonic: "+BIT 7,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x79
            opCode(mnemonic: "+BIT 7,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x7A
            opCode(mnemonic: "+BIT 7,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x7B
            opCode(mnemonic: "+BIT 7,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x7C
            opCode(mnemonic: "+BIT 7,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x7D
            opCode(mnemonic: "+BIT 7,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x7E
            opCode(mnemonic: "+BIT 7,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x7F
            opCode(mnemonic: "+RES 0,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x80
            opCode(mnemonic: "+RES 0,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x81
            opCode(mnemonic: "+RES 0,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x82
            opCode(mnemonic: "+RES 0,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x83
            opCode(mnemonic: "+RES 0,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x84
            opCode(mnemonic: "+RES 0,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x85
            opCode(mnemonic: "RES 0,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x86
            opCode(mnemonic: "+RES 0,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x87
            opCode(mnemonic: "+RES 1,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x88
            opCode(mnemonic: "+RES 1,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x89
            opCode(mnemonic: "+RES 1,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x8A
            opCode(mnemonic: "+RES 1,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x8B
            opCode(mnemonic: "+RES 1,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x8C
            opCode(mnemonic: "+RES 1,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x8D
            opCode(mnemonic: "RES 1,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x8E
            opCode(mnemonic: "+RES 1,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x8F
            opCode(mnemonic: "+RES 2,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x90
            opCode(mnemonic: "+RES 2,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x91
            opCode(mnemonic: "+RES 2,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x92
            opCode(mnemonic: "+RES 2,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x93
            opCode(mnemonic: "+RES 2,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x94
            opCode(mnemonic: "+RES 2,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x95
            opCode(mnemonic: "RES 2,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x96
            opCode(mnemonic: "+RES 2,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x97
            opCode(mnemonic: "+RES 3,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x98
            opCode(mnemonic: "+RES 3,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x99
            opCode(mnemonic: "+RES 3,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x9A
            opCode(mnemonic: "+RES 3,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x9B
            opCode(mnemonic: "+RES 3,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x9C
            opCode(mnemonic: "+RES 3,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x9D
            opCode(mnemonic: "RES 3,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x9E
            opCode(mnemonic: "+RES 3,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0x9F
            opCode(mnemonic: "+RES 4,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA0
            opCode(mnemonic: "+RES 4,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA1
            opCode(mnemonic: "+RES 4,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA2
            opCode(mnemonic: "+RES 4,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA3
            opCode(mnemonic: "+RES 4,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA4
            opCode(mnemonic: "+RES 4,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA5
            opCode(mnemonic: "RES 4,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA6
            opCode(mnemonic: "+RES 4,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA7
            opCode(mnemonic: "+RES 5,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA8
            opCode(mnemonic: "+RES 5,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xA9
            opCode(mnemonic: "+RES 5,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xAA
            opCode(mnemonic: "+RES 5,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xAB
            opCode(mnemonic: "+RES 5,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xAC
            opCode(mnemonic: "+RES 5,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xAD
            opCode(mnemonic: "RES 5,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xAE
            opCode(mnemonic: "+RES 5,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xAF
            opCode(mnemonic: "+RES 6,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB0
            opCode(mnemonic: "+RES 6,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB1
            opCode(mnemonic: "+RES 6,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB2
            opCode(mnemonic: "+RES 6,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB3
            opCode(mnemonic: "+RES 6,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB4
            opCode(mnemonic: "+RES 6,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB5
            opCode(mnemonic: "RES 6,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB6
            opCode(mnemonic: "+RES 6,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB7
            opCode(mnemonic: "+RES 7,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB8
            opCode(mnemonic: "+RES 7,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xB9
            opCode(mnemonic: "+RES 7,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xBA
            opCode(mnemonic: "+RES 7,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xBB
            opCode(mnemonic: "+RES 7,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xBC
            opCode(mnemonic: "+RES 7,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xBD
            opCode(mnemonic: "RES 7,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xBE
            opCode(mnemonic: "+RES 7,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xBF
            opCode(mnemonic: "+SET 0,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC0
            opCode(mnemonic: "+SET 0,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC1
            opCode(mnemonic: "+SET 0,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC2
            opCode(mnemonic: "+SET 0,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC3
            opCode(mnemonic: "+SET 0,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC4
            opCode(mnemonic: "+SET 0,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC5
            opCode(mnemonic: "SET 0,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC6
            opCode(mnemonic: "+SET 0,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC7
            opCode(mnemonic: "+SET 1,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC8
            opCode(mnemonic: "+SET 1,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xC9
            opCode(mnemonic: "+SET 1,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xCA
            opCode(mnemonic: "+SET 1,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xCB
            opCode(mnemonic: "+SET 1,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xCC
            opCode(mnemonic: "+SET 1,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xCD
            opCode(mnemonic: "SET 1,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xCE
            opCode(mnemonic: "+SET 1,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xCF
            opCode(mnemonic: "+SET 2,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD0
            opCode(mnemonic: "+SET 2,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD1
            opCode(mnemonic: "+SET 2,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD2
            opCode(mnemonic: "+SET 2,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD3
            opCode(mnemonic: "+SET 2,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD4
            opCode(mnemonic: "+SET 2,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD5
            opCode(mnemonic: "SET 2,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD6
            opCode(mnemonic: "+SET 2,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD7
            opCode(mnemonic: "+SET 3,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD8
            opCode(mnemonic: "+SET 3,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xD9
            opCode(mnemonic: "+SET 3,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xDA
            opCode(mnemonic: "+SET 3,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xDB
            opCode(mnemonic: "+SET 3,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xDC
            opCode(mnemonic: "+SET 3,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xDD
            opCode(mnemonic: "SET 3,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xDE
            opCode(mnemonic: "+SET 3,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xDF
            opCode(mnemonic: "+SET 4,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE0
            opCode(mnemonic: "+SET 4,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE1
            opCode(mnemonic: "+SET 4,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE2
            opCode(mnemonic: "+SET 4,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE3
            opCode(mnemonic: "+SET 4,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE4
            opCode(mnemonic: "+SET 4,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE5
            opCode(mnemonic: "SET 4,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE6
            opCode(mnemonic: "+SET 4,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE7
            opCode(mnemonic: "+SET 5,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE8
            opCode(mnemonic: "+SET 5,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xE9
            opCode(mnemonic: "+SET 5,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xEA
            opCode(mnemonic: "+SET 5,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xEB
            opCode(mnemonic: "+SET 5,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xEC
            opCode(mnemonic: "+SET 5,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xED
            opCode(mnemonic: "SET 5,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xEE
            opCode(mnemonic: "+SET 5,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xEF
            opCode(mnemonic: "+SET 6,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF0
            opCode(mnemonic: "+SET 6,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF1
            opCode(mnemonic: "+SET 6,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF2
            opCode(mnemonic: "+SET 6,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF3
            opCode(mnemonic: "+SET 6,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF4
            opCode(mnemonic: "+SET 6,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF5
            opCode(mnemonic: "SET 6,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF6
            opCode(mnemonic: "+SET 6,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF7
            opCode(mnemonic: "+SET 7,(IY+$d),B", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF8
            opCode(mnemonic: "+SET 7,(IY+$d),C", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xF9
            opCode(mnemonic: "+SET 7,(IY+$d),D", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xFA
            opCode(mnemonic: "+SET 7,(IY+$d),E", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xFB
            opCode(mnemonic: "+SET 7,(IY+$d),H", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xFC
            opCode(mnemonic: "+SET 7,(IY+$d),L", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xFD
            opCode(mnemonic: "SET 7,(IY+$d)", dataPattern: dataPatterns.byte1Byte2DByte4),    //  0xFE
            opCode(mnemonic: "+SET 7,(IY+$d),A", dataPattern: dataPatterns.byte1Byte2DByte4)    //  0xFF
        ]
    
    func decodeMnemonic(mnemonic: String, instructionBytes: [UInt8], dataPattern: dataPatterns) -> String
    {
        var tempMnemonic : String
        var tempInstructionBytes : [UInt8]
        
        switch dataPattern
        {
            case dataPatterns.noData :
                tempMnemonic = mnemonic
                tempInstructionBytes = [instructionBytes[0]]
            case dataPatterns.byte1D :
                tempMnemonic = mnemonic.replacingOccurrences(of: "$d", with: "0x"+String(format:"%02X",instructionBytes[1]))
                tempInstructionBytes = Array(instructionBytes[0...1])
            case dataPatterns.byte1N :
                tempMnemonic = mnemonic.replacingOccurrences(of: "$n", with: "0x"+String(format:"%02X",instructionBytes[1]))
                tempInstructionBytes = Array(instructionBytes[0...1])
            case dataPatterns.byte1NN :
                tempMnemonic = mnemonic.replacingOccurrences(of: "$nn", with: "0x"+String(format:"%04X",UInt16(instructionBytes[2]) << 8 | UInt16(instructionBytes[1])))
                tempInstructionBytes = Array(instructionBytes[0...2])
            case dataPatterns.byte1Byte2 :
                tempMnemonic = mnemonic
                tempInstructionBytes = Array(instructionBytes[0...1])
            case dataPatterns.byte1Byte2N :
                tempMnemonic = mnemonic.replacingOccurrences(of: "$n", with: "0x"+String(format:"%02X",instructionBytes[2]))
                tempInstructionBytes = Array(instructionBytes[0...2])
            case dataPatterns.byte1Byte2D :
                tempMnemonic = mnemonic.replacingOccurrences(of: "$d", with: "0x"+String(format:"%02X",instructionBytes[2]))
                tempInstructionBytes = Array(instructionBytes[0...2])
            case dataPatterns.byte1Byte2DN :
                tempMnemonic = mnemonic.replacingOccurrences(of: "$d", with: "0x"+String(format:"%02X",instructionBytes[2]))
                tempMnemonic = tempMnemonic.replacingOccurrences(of: "$n", with: "0x"+String(format:"%02X",instructionBytes[3]))
                tempInstructionBytes = Array(instructionBytes[0...3])
            case dataPatterns.byte1Byte2NN :
                tempMnemonic = mnemonic.replacingOccurrences(of: "$nn", with: "0x"+String(format:"%04X",UInt16(instructionBytes[3]) << 8 | UInt16(instructionBytes[2])))
                tempInstructionBytes = Array(instructionBytes[0...3])
            case dataPatterns.byte1Byte2DByte4 :
                tempMnemonic = mnemonic.replacingOccurrences(of: "$d", with: "0x"+String(format:"%02X",instructionBytes[2]))
                tempInstructionBytes = Array(instructionBytes[0...3])
        }
        return tempInstructionBytes.map { String(format: "%02X", $0) }.joined(separator: " ").padding(toLength: 12, withPad: " ", startingAt: 0)+"   "+tempMnemonic
    }
    
    func decodeInstructions(address: UInt16, bytes: [UInt8]) -> String
    {
        var tempString : String = String(format:"0x%04X",address) + "     "
        
        switch bytes[0]
            {
                case 0x00,0x02,0x03,0x04,0x05,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0F,0x12,0x13,0x14,0x15,0x17,0x19,0x1A,0x1B,0x1C,0x1D,0x1F,0x23,0x24,0x25,0x27,0x29,0x2B,0x2C,0x2D,0x2F,0x33,0x34,0x35,0x37,0x39,0x3B,0x3C,0x3D,0x3F,0x40,0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x4A,0x4B,0x4C,0x4D,0x4E,0x4F,0x50,0x51,0x52,0x53,0x54,0x55,0x56,0x57,0x58,0x59,0x5A,0x5B,0x5C,0x5D,0x5E,0x5F,0x60,0x61,0x62,0x63,0x64,0x65,0x66,0x67,0x68,0x69,0x6A,0x6B,0x6C,0x6D,0x6E,0x6F,0x70,0x71,0x72,0x73,0x74,0x75,0x76,0x77,0x78,0x79,0x7A,0x7B,0x7C,0x7D,0x7E,0x7F,0x80,0x81,0x82,0x83,0x84,0x85,0x86,0x87,0x88,0x89,0x8A,0x8B,0x8C,0x8D,0x8E,0x8F,0x90,0x91,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9A,0x9B,0x9C,0x9D,0x9E,0x9F,0xA0,0xA1,0xA2,0xA3,0xA4,0xA5,0xA6,0xA7,0xA8,0xA9,0xAA,0xAB,0xAC,0xAD,0xAE,0xAF,0xB0,0xB1,0xB2,0xB3,0xB4,0xB5,0xB6,0xB7,0xB8,0xB9,0xBA,0xBB,0xBC,0xBD,0xBE,0xBF,0xC0,0xC1,0xC5,0xC7,0xC8,0xC9,0xCF,0xD0,0xD1,0xD5,0xD7,0xD8,0xD9,0xDF,0xE0,0xE1,0xE3,0xE5,0xE7,0xE8,0xE9,0xEB,0xEF,0xF0,0xF1,0xF3,0xF5,0xF7,0xF8,0xF9,0xFB,0xFF :
                    let tempOpcode = singleOpcode[Int(bytes[0])]
                    tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.noData)
                case 0x06,0x0E,0x16,0x1E,0x26,0x2E,0x36,0x3E,0xC6,0xCE,0xD3,0xD6,0xDB,0xDE,0xE6,0xEE,0xF6,0xFE :
                    let tempOpcode = singleOpcode[Int(bytes[0])]
                    tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1N)
                case 0x10,0x18,0x20,0x28,0x30,0x38 :
                    let tempOpcode = singleOpcode[Int(bytes[0])]
                    tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1D)
                case 0x01,0x11,0x21,0x22,0x2A,0x31,0x32,0x3A,0xC2,0xC3,0xC4,0xCA,0xCC,0xCD,0xD2,0xD4,0xDA,0xDC,0xE2,0xE4,0xEA,0xEC,0xF2,0xF4,0xFA,0xFC :
                    let tempOpcode = singleOpcode[Int(bytes[0])]
                    tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1NN)
                case 0xCB :
                    let tempOpcode = CBPrefixOpcode[Int(bytes[1])]
                    tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2)
                case 0xDD :
                    switch bytes[1]
                    {
                        case 0xCB :
                            let tempOpcode = DDCBPrefixOpcode[Int(bytes[3])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2DByte4)
                        case 0x00,0x01,0x02,0x03,0x04,0x05,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0F,0x10,0x11,0x12,0x13,0x14,0x15,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1F,0x20,0x23,0x24,0x25,0x27,0x28,0x29,0x2B,0x2C,0x2D,0x2F,0x30,0x31,0x32,0x33,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,0x3F,0x40,0x41,0x42,0x43,0x44,0x45,0x47,0x48,0x49,0x4A,0x4B,0x4C,0x4D,0x4F,0x50,0x51,0x52,0x53,0x54,0x55,0x57,0x58,0x59,0x5A,0x5B,0x5C,0x5D,0x5F,0x60,0x61,0x62,0x63,0x64,0x65,0x67,0x68,0x69,0x6A,0x6B,0x6C,0x6D,0x6F,0x76,0x78,0x79,0x7A,0x7B,0x7C,0x7D,0x7F,0x80,0x81,0x82,0x83,0x84,0x85,0x87,0x88,0x89,0x8A,0x8B,0x8C,0x8D,0x8F,0x90,0x91,0x92,0x93,0x94,0x95,0x97,0x98,0x99,0x9A,0x9B,0x9C,0x9D,0x9F,0xA0,0xA1,0xA2,0xA3,0xA4,0xA5,0xA7,0xA8,0xA9,0xAA,0xAB,0xAC,0xAD,0xAF,0xB0,0xB1,0xB2,0xB3,0xB4,0xB5,0xB7,0xB8,0xB9,0xBA,0xBB,0xBC,0xBD,0xBF,0xC0,0xC1,0xC2,0xC3,0xC4,0xC5,0xC6,0xC7,0xC8,0xC9,0xCA,0xCC,0xCD,0xCE,0xCF,0xD0,0xD1,0xD2,0xD3,0xD4,0xD5,0xD6,0xD7,0xD8,0xD9,0xDA,0xDB,0xDC,0xDD,0xDE,0xDF,0xE0,0xE1,0xE2,0xE3,0xE4,0xE5,0xE6,0xE7,0xE8,0xE9,0xEA,0xEB,0xEC,0xED,0xEE,0xEF,0xF0,0xF1,0xF2,0xF3,0xF4,0xF5,0xF6,0xF7,0xF8,0xF9,0xFA,0xFB,0xFC,0xFD,0xFE,0xFF :
                            let tempOpcode = DDPrefixOpcode[Int(bytes[1])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2)
                        case 0x06,0x0E,0x16,0x1E,0x26,0x2E,0x3E :
                            let tempOpcode = DDPrefixOpcode[Int(bytes[1])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2N)
                        case 0x34,0x35,0x46,0x4E,0x56,0x5E,0x66,0x6E,0x70,0x71,0x72,0x73,0x74,0x75,0x77,0x7E,0x86,0x8E,0x96,0x9E,0xA6,0xAE,0xB6,0xBE :
                            let tempOpcode = DDPrefixOpcode[Int(bytes[1])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2D)
                        case 0x36:
                            let tempOpcode = DDPrefixOpcode[Int(bytes[1])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2DN)
                        case 0x21,0x22,0x2A :
                            let tempOpcode = DDPrefixOpcode[Int(bytes[1])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2NN)
                        default : break
                    }
                case 0xED :
                    switch bytes[1]
            {
                        case 0x43,0x4B,0x53,0x5B,0x63,0x6B,0x73,0x7B :
                            let tempOpcode = EDPrefixOpcode[Int(bytes[1])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2NN)
                        case 0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F,0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,0x2E,0x2F,0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,0x3E,0x3F,0x40,0x41,0x42,0x44,0x45,0x46,0x47,0x48,0x49,0x4A,0x4C,0x4D,0x4E,0x4F,0x50,0x51,0x52,0x54,0x55,0x56,0x57,0x58,0x59,0x5A,0x5C,0x5D,0x5E,0x5F,0x60,0x61,0x62,0x64,0x65,0x66,0x67,0x68,0x69,0x6A,0x6C,0x6D,0x6E,0x6F,0x70,0x71,0x72,0x74,0x75,0x76,0x77,0x78,0x79,0x7A,0x7C,0x7D,0x7E,0x7F,0x80,0x81,0x82,0x83,0x84,0x85,0x86,0x87,0x88,0x89,0x8A,0x8B,0x8C,0x8D,0x8E,0x8F,0x90,0x91,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9A,0x9B,0x9C,0x9D,0x9E,0x9F,0xA0,0xA1,0xA2,0xA3,0xA4,0xA5,0xA6,0xA7,0xA8,0xA9,0xAA,0xAB,0xAC,0xAD,0xAE,0xAF,0xB0,0xB1,0xB2,0xB3,0xB4,0xB5,0xB6,0xB7,0xB8,0xB9,0xBA,0xBB,0xBC,0xBD,0xBE,0xBF,0xC0,0xC1,0xC2,0xC3,0xC4,0xC5,0xC6,0xC7,0xC8,0xC9,0xCA,0xCB,0xCC,0xCD,0xCE,0xCF,0xD0,0xD1,0xD2,0xD3,0xD4,0xD5,0xD6,0xD7,0xD8,0xD9,0xDA,0xDB,0xDC,0xDD,0xDE,0xDF,0xE0,0xE1,0xE2,0xE3,0xE4,0xE5,0xE6,0xE7,0xE8,0xE9,0xEA,0xEB,0xEC,0xED,0xEE,0xEF,0xF0,0xF1,0xF2,0xF3,0xF4,0xF5,0xF6,0xF7,0xF8,0xF9,0xFA,0xFB,0xFC,0xFD,0xFE,0xFF :
                            let tempOpcode = EDPrefixOpcode[Int(bytes[1])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2)
                        default : break
                    }
                case 0xFD :
                    switch bytes[1]
                    {
                        case 0xCB :
                            let tempOpcode = FDCBPrefixOpcode[Int(bytes[3])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2DByte4)
                        case 0x00,0x01,0x02,0x03,0x04,0x05,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0F,0x10,0x11,0x12,0x13,0x14,0x15,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1F,0x20,0x23,0x24,0x25,0x27,0x28,0x29,0x2B,0x2C,0x2D,0x2F,0x30,0x31,0x32,0x33,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,0x3F,0x40,0x41,0x42,0x43,0x44,0x45,0x47,0x48,0x49,0x4A,0x4B,0x4C,0x4D,0x4F,0x50,0x51,0x52,0x53,0x54,0x55,0x57,0x58,0x59,0x5A,0x5B,0x5C,0x5D,0x5F,0x60,0x61,0x62,0x63,0x64,0x65,0x67,0x68,0x69,0x6A,0x6B,0x6C,0x6D,0x6F,0x76,0x78,0x79,0x7A,0x7B,0x7C,0x7D,0x7F,0x80,0x81,0x82,0x83,0x84,0x85,0x87,0x88,0x89,0x8A,0x8B,0x8C,0x8D,0x8F,0x90,0x91,0x92,0x93,0x94,0x95,0x97,0x98,0x99,0x9A,0x9B,0x9C,0x9D,0x9F,0xA0,0xA1,0xA2,0xA3,0xA4,0xA5,0xA7,0xA8,0xA9,0xAA,0xAB,0xAC,0xAD,0xAF,0xB0,0xB1,0xB2,0xB3,0xB4,0xB5,0xB7,0xB8,0xB9,0xBA,0xBB,0xBC,0xBD,0xBF,0xC0,0xC1,0xC2,0xC3,0xC4,0xC5,0xC6,0xC7,0xC8,0xC9,0xCA,0xCC,0xCD,0xCE,0xCF,0xD0,0xD1,0xD2,0xD3,0xD4,0xD5,0xD6,0xD7,0xD8,0xD9,0xDA,0xDB,0xDC,0xDD,0xDE,0xDF,0xE0,0xE1,0xE2,0xE3,0xE4,0xE5,0xE6,0xE7,0xE8,0xE9,0xEA,0xEB,0xEC,0xED,0xEE,0xEF,0xF0,0xF1,0xF2,0xF3,0xF4,0xF5,0xF6,0xF7,0xF8,0xF9,0xFA,0xFB,0xFC,0xFD,0xFE,0xFF :
                            let tempOpcode = FDPrefixOpcode[Int(bytes[1])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2)
                        case 0x06,0x0E,0x16,0x1E,0x26,0x2E,0x3E :
                            let tempOpcode = FDPrefixOpcode[Int(bytes[1])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2N)
                        case 0x34,0x35,0x46,0x4E,0x56,0x5E,0x66,0x6E,0x70,0x71,0x72,0x73,0x74,0x75,0x77,0x7E,0x86,0x8E,0x96,0x9E,0xA6,0xAE,0xB6,0xBE :
                            let tempOpcode = FDPrefixOpcode[Int(bytes[1])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2D)
                        case 0x36 :
                            let tempOpcode = FDPrefixOpcode[Int(bytes[1])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2DN)
                        case 0x21,0x22,0x2A :
                            let tempOpcode = FDPrefixOpcode[Int(bytes[1])]
                            tempString = tempString + decodeMnemonic(mnemonic: tempOpcode.mnemonic, instructionBytes : bytes, dataPattern: dataPatterns.byte1Byte2NN)
                        default : break
                    }
                default: break
            }
        return tempString.padding(toLength: 75, withPad: " ", startingAt: 0)
    }
}
