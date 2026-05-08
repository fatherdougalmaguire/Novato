import Foundation
import Testing

let testCycles = 1000

var finalPortValue : UInt8 = 0

private class sentinelClass {} // is required to find the json tests.  Feels like some kind of bullshit to me

@testable import Novato

struct PortActivity: Decodable, Sendable, Equatable
{
    let address: UInt16
    let value: UInt8
    let isWrite: Bool

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        self.address = try container.decode(UInt16.self)
        self.value = try container.decode(UInt8.self)
        let mode = try container.decode(String.self)
        self.isWrite = (mode == "w")
    }
}

struct BusCycle: Decodable
{
    let address: UInt16
    let data: UInt8
    let signals: String

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        self.address = try container.decode(UInt16.self)
        self.data = try container.decode(UInt8.self)
        self.signals = try container.decode(String.self)
    }
}

struct Z80Test: Decodable, Sendable
{
    let name: String
    let initial: CPUState
    let final: CPUState
    let ports: [PortActivity]

    enum CodingKeys: String, CodingKey
    {
        case name, initial, final, ports
    }

    init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.initial = try container.decode(CPUState.self, forKey: .initial)
        self.final = try container.decode(CPUState.self, forKey: .final)
        self.ports = try container.decodeIfPresent([PortActivity].self, forKey: .ports) ?? []
    }
}
protocol testHelper {}

extension testHelper
{
    static func loadJsonTests(named filename: String) -> [Z80Test]
    {
        // A whole bunch of jibberish to include linked JSON tests
        let bundle = Bundle(for: sentinelClass.self)
                
        guard let url = bundle.url(forResource: filename, withExtension: "json")
        else
        {
            print("Can't find test \(filename).json")
            return []
        }

        do
        {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Z80Test].self, from: data)
        }
        catch
        {
            print("Error decoding \(filename).json: \(error)")
            return []
        }
    }
    
    func testError(finalState: CPUState, expected: CPUState, finalPortValue: UInt8, ports: [PortActivity], context: String)
    {
        #expect(finalState.A == expected.A, "Register A fail in \(context)")
        #expect(finalState.F == expected.F, "Register F fail in \(context)")
        #expect(finalState.B == expected.B, "Register B fail in \(context)")
        #expect(finalState.C == expected.C, "Register C fail in \(context)")
        #expect(finalState.D == expected.D, "Register D fail in \(context)")
        #expect(finalState.E == expected.E, "Register E fail in \(context)")
        #expect(finalState.H == expected.H, "Register H fail in \(context)")
        #expect(finalState.L == expected.L, "Register L fail in \(context)")
        #expect(finalState.I == expected.I, "Register I fail in \(context)")
        #expect(finalState.R == expected.R, "Register R fail in \(context)")
        #expect(finalState.altAF == expected.altAF, "Register altAF fail in \(context)")
        #expect(finalState.altBC == expected.altBC, "Register altBC fail in \(context)")
        #expect(finalState.altDE == expected.altDE, "Register altDE fail in \(context)")
        #expect(finalState.altHL == expected.altHL, "Register altHL fail in \(context)")
        #expect(finalState.IM == expected.IM, "Register IM fail in \(context)")
       // #expect(finalState.IFF1 == expected.IFF1, "Register IFF1 fail in \(context)")
       // #expect(finalState.IFF2 == expected.IFF2, "Register IFF2 fail in \(context)")
        #expect(finalState.PC == expected.PC, "Register PC fail in \(context)")
        #expect(finalState.SP == expected.SP, "Register SP fail in \(context)")
        #expect(finalState.IX == expected.IX, "Register IX fail in \(context)")
        #expect(finalState.IY == expected.IY, "Register IY fail in \(context)")
        #expect(finalState.WZ == expected.WZ, "Register WZ fail in \(context)")
        #expect(finalState.ram == expected.ram, "RAM fail in \(context)")
        // #expect(finalState.Q == testCase.final.Q,"Register Q fail in \(context)")
        // #expect(finalState.P == testCase.final.P,"Register P fail in \(context)")
        // #expect(finalState.EI == testCase.final.EI,"Register EI fail in \(context)")
        if ports[0].isWrite
        {
            #expect( finalPortValue == ports[0].value, "Ports fail in \(context)")
        }
    }
    
    func runTest(_ testCase: Z80Test) async throws
    {
        let cpu = microbee()
        await cpu.loadCPUState(cpuState: testCase.initial)
        await cpu.loadPorts(portNum: testCase.ports[0].address, portValue: testCase.ports[0].value)
        await cpu.nextInstruction()
        let finalState = await cpu.returnCPUState(cpuState: testCase.initial)
        let finalPortValue = await cpu.returnPortValue(portNum: testCase.ports[0].address)
        testError(finalState: finalState, expected: testCase.final, finalPortValue: finalPortValue, ports: testCase.ports, context: testCase.name)
    }
}

@Suite("Z80 Opcodes")
struct Z80Opcodes: testHelper
{
    func instanceCPU() -> microbee { microbee() }
    
    @Suite("Primary Opcodes")
    struct primaryOpcodes
    {
        let parent = Z80Opcodes()
        
        @Test("NOP (0x00)", arguments: loadJsonTests(named: "00").prefix(testCycles))
        func test_NOP(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("LD BC,nn (0x01)", arguments: loadJsonTests(named: "01").prefix(testCycles))
        func test_LD_BC_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (BC),A (0x02)", arguments: loadJsonTests(named: "02").prefix(testCycles))
        func test_LD_CON_BC_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC BC (0x03)", arguments: loadJsonTests(named: "03").prefix(testCycles))
        func test_INC_BC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,$n (0x06)", arguments: loadJsonTests(named: "06").prefix(testCycles))
        func test_LD_B_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EX AF,AF'(0x08)", arguments: loadJsonTests(named: "08").prefix(testCycles))
        func test_EX_AF_altAF(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,(BC) (0x0A)", arguments: loadJsonTests(named: "0a").prefix(testCycles))
        func test_LD_A_CON_BC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC BC (0x0B)", arguments: loadJsonTests(named: "0b").prefix(testCycles))
        func test_DEC_BC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,$n (0x0E)", arguments: loadJsonTests(named: "0e").prefix(testCycles))
        func test_LD_C_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DJNZ $d (0x10)", arguments: loadJsonTests(named: "10").prefix(testCycles))
        func test_DJNZ_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD DE,$nn (0x11)", arguments: loadJsonTests(named: "11").prefix(testCycles))
        func test_LD_DE_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (DE),A (0x12)", arguments: loadJsonTests(named: "12").prefix(testCycles))
        func test_LD_CON_DE_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC DE (0x13)", arguments: loadJsonTests(named: "13").prefix(testCycles))
        func test_INC_DE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,$n (0x16)", arguments: loadJsonTests(named: "16").prefix(testCycles))
        func test_LD_D_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JR $d (0x18)", arguments: loadJsonTests(named: "18").prefix(testCycles))
        func test_JR_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,(DE) (0x1A)", arguments: loadJsonTests(named: "1a").prefix(testCycles))
        func test_LD_A_CON_DE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC DE (0x1B)", .serialized, arguments: loadJsonTests(named: "1b").prefix(testCycles))
        func test_DEC_DE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,$n (0x1E)", .serialized, arguments: loadJsonTests(named: "1e").prefix(testCycles))
        func test_LD_E_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JR NZ,$d (0x20)", arguments: loadJsonTests(named: "20").prefix(testCycles))
        func test_JR_NZ_d(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD HL,$nn (0x21)", .serialized, arguments: loadJsonTests(named: "21").prefix(testCycles))
        func test_LD_HL_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),HL (0x22)", .serialized, arguments: loadJsonTests(named: "22").prefix(testCycles))
        func test_LD_CON_NN_HL_(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC HL (0x23)", .serialized, arguments: loadJsonTests(named: "23").prefix(testCycles))
        func test_INC_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,$n (0x26)", .serialized, arguments: loadJsonTests(named: "26").prefix(testCycles))
        func test_LD_H_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JR Z,$d (0x28)", .serialized, arguments: loadJsonTests(named: "28").prefix(testCycles))
        func test_JR_Z_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD HL,($nn) (0x2A)", .serialized, arguments: loadJsonTests(named: "2a").prefix(testCycles))
        func test_LD_HL_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC HL (0x2B)", .serialized, arguments: loadJsonTests(named: "2b").prefix(testCycles))
        func test_DEC_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,$n (0x2E)", .serialized, arguments: loadJsonTests(named: "2e").prefix(testCycles))
        func test_LD_L_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JR NC,$d (0x30)", .serialized, arguments: loadJsonTests(named: "30").prefix(testCycles))
        func test_JR_NC_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD SP,$nn (0x31)", .serialized, arguments: loadJsonTests(named: "31").prefix(testCycles))
        func test_LD_SP_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),A (0x32)", .serialized, arguments: loadJsonTests(named: "32").prefix(testCycles))
        func test_LD_CON_NN_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC SP (0x33)", .serialized, arguments: loadJsonTests(named: "33").prefix(testCycles))
        func test_INC_SP(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),$n (0x36)", .serialized, arguments: loadJsonTests(named: "36").prefix(testCycles))
        func test_LD_CON_HL_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JR C,$d (0x38)", .serialized, arguments: loadJsonTests(named: "38").prefix(testCycles))
        func test_JR_C_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,($nn) (0x3A)", .serialized, arguments: loadJsonTests(named: "3a").prefix(testCycles))
        func test_LD_A_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC SP (0x3B)", .serialized, arguments: loadJsonTests(named: "3b").prefix(testCycles))
        func test_DEC_SP(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,$n (0x3E)", .serialized, arguments: loadJsonTests(named: "3e").prefix(testCycles))
        func test_LD_A_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,B (0x40)", .serialized, arguments: loadJsonTests(named: "40").prefix(testCycles))
        func test_LD_B_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,C (0x41)", .serialized, arguments: loadJsonTests(named: "41").prefix(testCycles))
        func test_LD_B_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,D (0x42)", .serialized, arguments: loadJsonTests(named: "42").prefix(testCycles))
        func test_LD_B_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,E (0x43)", .serialized, arguments: loadJsonTests(named: "43").prefix(testCycles))
        func test_LD_B_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,H (0x44)", .serialized, arguments: loadJsonTests(named: "44").prefix(testCycles))
        func test_LD_B_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,L (0x45)", .serialized, arguments: loadJsonTests(named: "45").prefix(testCycles))
        func test_LD_B_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,(HL) (0x46)", .serialized, arguments: loadJsonTests(named: "46").prefix(testCycles))
        func test_LD_B_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,A (0x47)", .serialized, arguments: loadJsonTests(named: "47").prefix(testCycles))
        func test_LD_B_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,B (0x48)", .serialized, arguments: loadJsonTests(named: "48").prefix(testCycles))
        func test_LD_C_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,C (0x49)", .serialized, arguments: loadJsonTests(named: "49").prefix(testCycles))
        func test_LD_C_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,D (0x4A)", .serialized, arguments: loadJsonTests(named: "4a").prefix(testCycles))
        func test_LD_C_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,E (0x4B)", .serialized, arguments: loadJsonTests(named: "4b").prefix(testCycles))
        func test_LD_C_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,H (0x4C)", .serialized, arguments: loadJsonTests(named: "4c").prefix(testCycles))
        func test_LD_C_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,L (0x4D)", .serialized, arguments: loadJsonTests(named: "4d").prefix(testCycles))
        func test_LD_C_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,(HL) (0x4E)", .serialized, arguments: loadJsonTests(named: "4e").prefix(testCycles))
        func test_LD_C_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,A (0x4F)", .serialized, arguments: loadJsonTests(named: "4f").prefix(testCycles))
        func test_LD_C_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,B (0x50)", .serialized, arguments: loadJsonTests(named: "50").prefix(testCycles))
        func test_LD_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,C (0x51)", .serialized, arguments: loadJsonTests(named: "51").prefix(testCycles))
        func test_LD_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,D (0x52)", .serialized, arguments: loadJsonTests(named: "52").prefix(testCycles))
        func test_LD_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,E (0x53)", arguments: loadJsonTests(named: "53").prefix(testCycles))
        func test_LD_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,H (0x54)", arguments: loadJsonTests(named: "54").prefix(testCycles))
        func test_LD_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,L (0x55)", arguments: loadJsonTests(named: "55").prefix(testCycles))
        func test_LD_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,(HL) (0x56)", arguments: loadJsonTests(named: "56").prefix(testCycles))
        func test_LD_D_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,A (0x57)", arguments: loadJsonTests(named: "57").prefix(testCycles))
        func test_LD_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,B (0x58)", .serialized, arguments: loadJsonTests(named: "58").prefix(testCycles))
        func test_LD_E_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,C (0x59)", .serialized, arguments: loadJsonTests(named: "59").prefix(testCycles))
        func test_LD_E_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,D (0x5A)", .serialized, arguments: loadJsonTests(named: "5a").prefix(testCycles))
        func test_LD_E_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,E (0x5B)", .serialized, arguments: loadJsonTests(named: "5b").prefix(testCycles))
        func test_LD_E_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,H (0x5C)", .serialized, arguments: loadJsonTests(named: "5c").prefix(testCycles))
        func test_LD_E_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,L (0x5D)", .serialized, arguments: loadJsonTests(named: "5d").prefix(testCycles))
        func test_LD_E_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,(HL) (0x5E)", .serialized, arguments: loadJsonTests(named: "5e").prefix(testCycles))
        func test_LD_E_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,A (0x5F)", .serialized, arguments: loadJsonTests(named: "5f").prefix(testCycles))
        func test_LD_E_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,B (0x60)", .serialized, arguments: loadJsonTests(named: "60").prefix(testCycles))
        func test_LD_H_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,C (0x61)", .serialized, arguments: loadJsonTests(named: "61").prefix(testCycles))
        func test_LD_H_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,D (0x62)", .serialized, arguments: loadJsonTests(named: "62").prefix(testCycles))
        func test_LD_H_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,E (0x63)", arguments: loadJsonTests(named: "63").prefix(testCycles))
        func test_LD_H_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,H (0x64)", arguments: loadJsonTests(named: "64").prefix(testCycles))
        func test_LD_H_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,L (0x65)", arguments: loadJsonTests(named: "65").prefix(testCycles))
        func test_LD_H_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,(HL) (0x66)", arguments: loadJsonTests(named: "66").prefix(testCycles))
        func test_LD_H_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,A (0x67)", arguments: loadJsonTests(named: "67").prefix(testCycles))
        func test_LD_H_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,B (0x68)", arguments: loadJsonTests(named: "68").prefix(testCycles))
        func test_LD_L_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,C (0x69)", arguments: loadJsonTests(named: "69").prefix(testCycles))
        func test_LD_L_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,D (0x6A)", arguments: loadJsonTests(named: "6a").prefix(testCycles))
        func test_LD_L_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,E (0x6B)",  arguments: loadJsonTests(named: "6b").prefix(testCycles))
        func test_LD_L_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,H (0x6C)",  arguments: loadJsonTests(named: "6c").prefix(testCycles))
        func test_LD_L_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,L (0x6D)",  arguments: loadJsonTests(named: "6d").prefix(testCycles))
        func test_LD_L_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,(HL) (0x6E)", arguments: loadJsonTests(named: "6e").prefix(testCycles))
        func test_LD_L_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,A (0x6F)",  arguments: loadJsonTests(named: "6f").prefix(testCycles))
        func test_LD_L_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),B (0x70)",  arguments: loadJsonTests(named: "70").prefix(testCycles))
        func test_LD_CON_HL_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),C (0x71)",  arguments: loadJsonTests(named: "71").prefix(testCycles))
        func test_LD_CON_HL_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),D (0x72)",  arguments: loadJsonTests(named: "72").prefix(testCycles))
        func test_LD_CON_HL_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),E (0x73)",  arguments: loadJsonTests(named: "73").prefix(testCycles))
        func test_LD_CON_HL_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),H (0x74)",  arguments: loadJsonTests(named: "74").prefix(testCycles))
        func test_LD_CON_HL_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),L (0x75)",  arguments: loadJsonTests(named: "75").prefix(testCycles))
        func test_LD_CON_HL_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate HALT (0x76)",  arguments: loadJsonTests(named: "76").prefix(testCycles))
        func test_HALT(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),A (0x77)",  arguments: loadJsonTests(named: "77").prefix(testCycles))
        func test_LD_CON_HL_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,B (0x78)",  arguments: loadJsonTests(named: "78").prefix(testCycles))
        func test_LD_A_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,C (0x79)",  arguments: loadJsonTests(named: "79").prefix(testCycles))
        func test_LD_A_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,D (0x7A)",  arguments: loadJsonTests(named: "7a").prefix(testCycles))
        func test_LD_A_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,E (0x7B)",  arguments: loadJsonTests(named: "7b").prefix(testCycles))
        func test_LD_A_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,H (0x7C)",  arguments: loadJsonTests(named: "7c").prefix(testCycles))
        func test_LD_A_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,L (0x7D)",  arguments: loadJsonTests(named: "7d").prefix(testCycles))
        func test_LD_A_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,(HL) (0x7E)",  arguments: loadJsonTests(named: "7e").prefix(testCycles))
        func test_LD_A_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,A (0x7F)",  arguments: loadJsonTests(named: "7f").prefix(testCycles))
        func test_LD_A_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET NZ (0xC0)",  arguments: loadJsonTests(named: "c0").prefix(testCycles))
        func test_RET_NZ(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }
        
        @Test("Validate POP BC (0xC1)",  arguments: loadJsonTests(named: "c1").prefix(testCycles))
        func test_POP_BC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP NZ,$nn (0xC2)",  arguments: loadJsonTests(named: "c2").prefix(testCycles))
        func test_JP_NZ_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP $nn (0xC3)",  arguments: loadJsonTests(named: "c3").prefix(testCycles))
        func test_JP_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL NZ,$nn (0xC4)",  arguments: loadJsonTests(named: "c4").prefix(testCycles))
        func test_CALL_NZ_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate PUSH BC (0xC5)",  arguments: loadJsonTests(named: "c5").prefix(testCycles))
        func test_PUSH_BC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x00 (0xC7)",  arguments: loadJsonTests(named: "c7").prefix(testCycles))
        func test_RST_0x00(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET Z (0xC8)",  arguments: loadJsonTests(named: "c8").prefix(testCycles))
        func test_RET_Z(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET (0xC9)",  arguments: loadJsonTests(named: "c9").prefix(testCycles))
        func test_RET(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP Z,$nn (0xCA)",  arguments: loadJsonTests(named: "ca").prefix(testCycles))
        func test_JP_Z_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL Z,$nn (0xCC)",  arguments: loadJsonTests(named: "cc").prefix(testCycles))
        func test_CALL_Z_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL $nn (0xCD)",  arguments: loadJsonTests(named: "cd").prefix(testCycles))
        func test_CALL_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x08 (0xCF)",  arguments: loadJsonTests(named: "cf").prefix(testCycles))
        func test_RST_0x08(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET NC (0xD0)",  arguments: loadJsonTests(named: "d0").prefix(testCycles))
        func test_RET_NC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate POP DE (0xD1)",  arguments: loadJsonTests(named: "d1").prefix(testCycles))
        func test_POP_DE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP NC,$nn (0xD2)",  arguments: loadJsonTests(named: "d2").prefix(testCycles))
        func test_JP_NC_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT ($n),A (0xD3)",  arguments: loadJsonTests(named: "d3").prefix(testCycles))
        func test_OUT_N_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL NC,$nn (0xD4)",  arguments: loadJsonTests(named: "d4").prefix(testCycles))
        func test_CALL_NC_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate PUSH DE (0xD5)",  arguments: loadJsonTests(named: "d5").prefix(testCycles))
        func test_PUSH_DE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x10 (0xD7)",  arguments: loadJsonTests(named: "d7").prefix(testCycles))
        func test_RST_0x10(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET C (0xD8)",  arguments: loadJsonTests(named: "d8").prefix(testCycles))
        func test_RET_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EXX (0xD9)",  arguments: loadJsonTests(named: "d9").prefix(testCycles))
        func test_EXX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP C,$nn (0xDA)",  arguments: loadJsonTests(named: "da").prefix(testCycles))
        func test_JP_C_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate IN A,($n) (0xDB)",  arguments: loadJsonTests(named: "db").prefix(testCycles))
        func test_IN_A_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        // use .filter { $0.name == "DB 0145" } against loadJsonTests to filter specific use case
        
        @Test("Validate CALL C,$nn (0xDC)",  arguments: loadJsonTests(named: "dc").prefix(testCycles))
        func test_CALL_C_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x18 (0xDF)",  arguments: loadJsonTests(named: "df").prefix(testCycles))
        func test_RST_0x18(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET PO (0xE0)",  arguments: loadJsonTests(named: "e0").prefix(testCycles))
        func test_RET_PO(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate POP HL (0xE1)",  arguments: loadJsonTests(named: "e1").prefix(testCycles))
        func test_POP_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP PO,$nn (0xE2)",  arguments: loadJsonTests(named: "e2").prefix(testCycles))
        func test_JP_PO_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EX (SP),HL (0xE3)",  arguments: loadJsonTests(named: "e3").prefix(testCycles))
        func test_EX_CON_SP_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL PO,$nn (0xE4)",  arguments: loadJsonTests(named: "e4").prefix(testCycles))
        func test_CALL_PO_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate PUSH HL (0xE5)",  arguments: loadJsonTests(named: "e5").prefix(testCycles))
        func test_PUSH_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x20 (0xE7)",  arguments: loadJsonTests(named: "e7").prefix(testCycles))
        func test_RST_0x20(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET PE (0xE8)",  arguments: loadJsonTests(named: "e8").prefix(testCycles))
        func test_RET_PE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP (HL) (0xE9)",  arguments: loadJsonTests(named: "e9").prefix(testCycles))
        func test_JP_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP PE,$nn (0xEA)",  arguments: loadJsonTests(named: "ea").prefix(testCycles))
        func test_JP_PE_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EX DE,HL (0xEB)",  arguments: loadJsonTests(named: "eb").prefix(testCycles))
        func test_EX_DE_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL PE,$nn (0xEC)",  arguments: loadJsonTests(named: "ec").prefix(testCycles))
        func test_CALL_PE_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x28 (0xEF)",  arguments: loadJsonTests(named: "ef").prefix(testCycles))
        func test_RST_0x28(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET P (0xF0)",  arguments: loadJsonTests(named: "f0").prefix(testCycles))
        func test_RET_P(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate POP AF (0xF1)",  arguments: loadJsonTests(named: "f1").prefix(testCycles))
        func test_POP_AF(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP P,$nn (0xF2)",  arguments: loadJsonTests(named: "f2").prefix(testCycles))
        func test_JP_P_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DI (0xF3)",  arguments: loadJsonTests(named: "f3").prefix(testCycles))
        func test_DI(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL P,$nn (0xF4)",  arguments: loadJsonTests(named: "f4").prefix(testCycles))
        func test_CALL_P_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate PUSH AF (0xF5)",  .timeLimit(.minutes(2)), arguments: loadJsonTests(named: "f5").prefix(testCycles))
        func test_PUSH_AF(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x30 (0xF7)",  arguments: loadJsonTests(named: "f7").prefix(testCycles))
        func test_RST_0x30(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET M (0xF8)",  arguments: loadJsonTests(named: "f8").prefix(testCycles))
        func test_RET_M(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD SP,HL (0xF9)",  arguments: loadJsonTests(named: "f9").prefix(testCycles))
        func test_LD_SP_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP M,$nn (0xFA)",  arguments: loadJsonTests(named: "fa").prefix(testCycles))
        func test_JP_M_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EI (0xFB)",  arguments: loadJsonTests(named: "fb").prefix(testCycles))
        func test_EI(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL M,$nn (0xFC)",  arguments: loadJsonTests(named: "fc").prefix(testCycles))
        func test_CALL_M_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x38 (0xFF)",  arguments: loadJsonTests(named: "ff").prefix(testCycles))
        func test_RST_0x38(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes CB")
    struct ExtendedOpcodesCB: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate RES 0,B (0xCB80)",  arguments: loadJsonTests(named: "cb 80").prefix(testCycles))
        func test_RES_0_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,C (0xCB81)",  arguments: loadJsonTests(named: "cb 81").prefix(testCycles))
        func test_RES_0_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,D (0xCB82)",  arguments: loadJsonTests(named: "cb 82").prefix(testCycles))
        func test_RES_0_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,E (0xCB83)",  arguments: loadJsonTests(named: "cb 83").prefix(testCycles))
        func test_RES_0_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,H (0xCB84)",  arguments: loadJsonTests(named: "cb 84").prefix(testCycles))
        func test_RES_0_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,L (0xCB85)",  arguments: loadJsonTests(named: "cb 85").prefix(testCycles))
        func test_RES_0_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(HL) (0xCB86)",  arguments: loadJsonTests(named: "cb 86").prefix(testCycles))
        func test_RES_0_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,A (0xCB87)",  arguments: loadJsonTests(named: "cb 87").prefix(testCycles))
        func test_RES_0_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,B (0xCB88)",  arguments: loadJsonTests(named: "cb 88").prefix(testCycles))
        func test_RES_1_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,C (0xCB89)",  arguments: loadJsonTests(named: "cb 89").prefix(testCycles))
        func test_RES_1_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,D (0xCB8A)",  arguments: loadJsonTests(named: "cb 8a").prefix(testCycles))
        func test_RES_1_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,E (0xCB8B)",  arguments: loadJsonTests(named: "cb 8b").prefix(testCycles))
        func test_RES_1_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,H (0xCB8C)",  arguments: loadJsonTests(named: "cb 8c").prefix(testCycles))
        func test_RES_1_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,L (0xCB8D)",  arguments: loadJsonTests(named: "cb 8d").prefix(testCycles))
        func test_RES_1_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(HL) (0xCB8E)",  arguments: loadJsonTests(named: "cb 8e").prefix(testCycles))
        func test_RES_1_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,A (0xCB8F)",  arguments: loadJsonTests(named: "cb 8f").prefix(testCycles))
        func test_RES_1_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,B (0xCB90)",  arguments: loadJsonTests(named: "cb 90").prefix(testCycles))
        func test_RES_2_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,C (0xCB91)",  arguments: loadJsonTests(named: "cb 91").prefix(testCycles))
        func test_RES_2_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,D (0xCB92)",  arguments: loadJsonTests(named: "cb 92").prefix(testCycles))
        func test_RES_2_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,E (0xCB93)",  arguments: loadJsonTests(named: "cb 93").prefix(testCycles))
        func test_RES_2_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,H (0xCB94)",  arguments: loadJsonTests(named: "cb 94").prefix(testCycles))
        func test_RES_2_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,L (0xCB95)",  arguments: loadJsonTests(named: "cb 95").prefix(testCycles))
        func test_RES_2_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(HL) (0xCB96)",  arguments: loadJsonTests(named: "cb 96").prefix(testCycles))
        func test_RES_2_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,A (0xCB97)",  arguments: loadJsonTests(named: "cb 97").prefix(testCycles))
        func test_RES_2_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,B (0xCB98)",  arguments: loadJsonTests(named: "cb 98").prefix(testCycles))
        func test_RES_3_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,C (0xCB99)",  arguments: loadJsonTests(named: "cb 99").prefix(testCycles))
        func test_RES_3_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,D (0xCB9A)",  arguments: loadJsonTests(named: "cb 9a").prefix(testCycles))
        func test_RES_3_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,E (0xCB9B)",  arguments: loadJsonTests(named: "cb 9b").prefix(testCycles))
        func test_RES_3_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,H (0xCB9C)",  arguments: loadJsonTests(named: "cb 9c").prefix(testCycles))
        func test_RES_3_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,L (0xCB9D)",  arguments: loadJsonTests(named: "cb 9d").prefix(testCycles))
        func test_RES_3_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(HL) (0xCB9E)",  arguments: loadJsonTests(named: "cb 9e").prefix(testCycles))
        func test_RES_3_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,A (0xCB9F)",  arguments: loadJsonTests(named: "cb 9f").prefix(testCycles))
        func test_RES_3_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,B (0xCBA0)",  arguments: loadJsonTests(named: "cb a0").prefix(testCycles))
        func test_RES_4_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,C (0xCBA1)",  arguments: loadJsonTests(named: "cb a1").prefix(testCycles))
        func test_RES_4_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,D (0xCBA2)",  arguments: loadJsonTests(named: "cb a2").prefix(testCycles))
        func test_RES_4_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,E (0xCBA3)",  arguments: loadJsonTests(named: "cb a3").prefix(testCycles))
        func test_RES_4_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,H (0xCBA4)",  arguments: loadJsonTests(named: "cb a4").prefix(testCycles))
        func test_RES_4_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,L (0xCBA5)",  arguments: loadJsonTests(named: "cb a5").prefix(testCycles))
        func test_RES_4_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(HL) (0xCBA6)",  arguments: loadJsonTests(named: "cb a6").prefix(testCycles))
        func test_RES_4_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,A (0xCBA7)",  arguments: loadJsonTests(named: "cb a7").prefix(testCycles))
        func test_RES_4_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,B (0xCBA8)",  arguments: loadJsonTests(named: "cb a8").prefix(testCycles))
        func test_RES_5_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,C (0xCBA9)",  arguments: loadJsonTests(named: "cb a9").prefix(testCycles))
        func test_RES_5_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,D (0xCBAA)",  arguments: loadJsonTests(named: "cb aa").prefix(testCycles))
        func test_RES_5_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,E (0xCBAB)",  arguments: loadJsonTests(named: "cb ab").prefix(testCycles))
        func test_RES_5_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,H (0xCBAC)",  arguments: loadJsonTests(named: "cb ac").prefix(testCycles))
        func test_RES_5_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,L (0xCBAD)",  arguments: loadJsonTests(named: "cb ad").prefix(testCycles))
        func test_RES_5_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(HL) (0xCBAE)",  arguments: loadJsonTests(named: "cb ae").prefix(testCycles))
        func test_RES_5_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,A (0xCBAF)",  arguments: loadJsonTests(named: "cb af").prefix(testCycles))
        func test_RES_5_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,B (0xCBB0)",  arguments: loadJsonTests(named: "cb b0").prefix(testCycles))
        func test_RES_6_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,C (0xCBB1)",  arguments: loadJsonTests(named: "cb b1").prefix(testCycles))
        func test_RES_6_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,D (0xCBB2)",  arguments: loadJsonTests(named: "cb b2").prefix(testCycles))
        func test_RES_6_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,E (0xCBB3)",  arguments: loadJsonTests(named: "cb b3").prefix(testCycles))
        func test_RES_6_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,H (0xCBB4)",  arguments: loadJsonTests(named: "cb b4").prefix(testCycles))
        func test_RES_6_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,L (0xCBB5)",  arguments: loadJsonTests(named: "cb b5").prefix(testCycles))
        func test_RES_6_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(HL) (0xCBB6)",  arguments: loadJsonTests(named: "cb b6").prefix(testCycles))
        func test_RES_6_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,A (0xCBB7)",  arguments: loadJsonTests(named: "cb b7").prefix(testCycles))
        func test_RES_6_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,B (0xCBB8)",  arguments: loadJsonTests(named: "cb b8").prefix(testCycles))
        func test_RES_7_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,C (0xCBB9)",  arguments: loadJsonTests(named: "cb b9").prefix(testCycles))
        func test_RES_7_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,D (0xCBBA)",  arguments: loadJsonTests(named: "cb ba").prefix(testCycles))
        func test_RES_7_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,E (0xCBBB)",  arguments: loadJsonTests(named: "cb bb").prefix(testCycles))
        func test_RES_7_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,H (0xCBBC)",  arguments: loadJsonTests(named: "cb bc").prefix(testCycles))
        func test_RES_7_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,L (0xCBBD)",  arguments: loadJsonTests(named: "cb bd").prefix(testCycles))
        func test_RES_7_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(HL) (0xCBBE)",  arguments: loadJsonTests(named: "cb be").prefix(testCycles))
        func test_RES_7_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,A (0xCBBF)",  arguments: loadJsonTests(named: "cb bf").prefix(testCycles))
        func test_RES_7_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,B (0xCBC0)",  arguments: loadJsonTests(named: "cb c0").prefix(testCycles))
        func test_SET_0_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,C (0xCBC1)",  arguments: loadJsonTests(named: "cb c1").prefix(testCycles))
        func test_SET_0_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,D (0xCBC2)",  arguments: loadJsonTests(named: "cb c2").prefix(testCycles))
        func test_SET_0_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,E (0xCBC3)",  arguments: loadJsonTests(named: "cb c3").prefix(testCycles))
        func test_SET_0_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,H (0xCBC4)",  arguments: loadJsonTests(named: "cb c4").prefix(testCycles))
        func test_SET_0_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        @Test("Validate SET 0,L (0xCBC5)",  arguments: loadJsonTests(named: "cb c5").prefix(testCycles))
        func test_SET_0_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(HL) (0xCBC6)",  arguments: loadJsonTests(named: "cb c6").prefix(testCycles))
        func test_SET_0_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,A (0xCBC7)",  arguments: loadJsonTests(named: "cb c7").prefix(testCycles))
        func test_SET_0_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,B (0xCBC8)",  arguments: loadJsonTests(named: "cb c8").prefix(testCycles))
        func test_SET_1_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,C (0xCBC9)",  arguments: loadJsonTests(named: "cb c9").prefix(testCycles))
        func test_SET_1_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,D (0xCBCA)",  arguments: loadJsonTests(named: "cb ca").prefix(testCycles))
        func test_SET_1_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,E (0xCBCB)",  arguments: loadJsonTests(named: "cb cb").prefix(testCycles))
        func test_SET_1_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,H (0xCBCC)",  arguments: loadJsonTests(named: "cb cc").prefix(testCycles))
        func test_SET_1_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,L (0xCBCD)",  arguments: loadJsonTests(named: "cb cd").prefix(testCycles))
        func test_SET_1_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(HL) (0xCBCE)",  arguments: loadJsonTests(named: "cb ce").prefix(testCycles))
        func test_SET_1_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,A (0xCBCF)",  arguments: loadJsonTests(named: "cb cf").prefix(testCycles))
        func test_SET_1_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,B (0xCBD0)",  arguments: loadJsonTests(named: "cb d0").prefix(testCycles))
        func test_SET_2_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,C (0xCBD1)",  arguments: loadJsonTests(named: "cb d1").prefix(testCycles))
        func test_SET_2_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,D (0xCBD2)",  arguments: loadJsonTests(named: "cb d2").prefix(testCycles))
        func test_SET_2_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,E (0xCBD3)",  arguments: loadJsonTests(named: "cb d3").prefix(testCycles))
        func test_SET_2_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,H (0xCBD4)",  arguments: loadJsonTests(named: "cb d4").prefix(testCycles))
        func test_SET_2_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,L (0xCBD5)",  arguments: loadJsonTests(named: "cb d5").prefix(testCycles))
        func test_SET_2_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(HL) (0xCBD6)",  arguments: loadJsonTests(named: "cb d6").prefix(testCycles))
        func test_SET_2_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,A (0xCBD7)",  arguments: loadJsonTests(named: "cb d7").prefix(testCycles))
        func test_SET_2_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,B (0xCBD8)",  arguments: loadJsonTests(named: "cb d8").prefix(testCycles))
        func test_SET_3_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,C (0xCBD9)",  arguments: loadJsonTests(named: "cb d9").prefix(testCycles))
        func test_SET_3_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,D (0xCBDA)",  arguments: loadJsonTests(named: "cb da").prefix(testCycles))
        func test_SET_3_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,E (0xCBDB)",  arguments: loadJsonTests(named: "cb db").prefix(testCycles))
        func test_SET_3_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,H (0xCBDC)",  arguments: loadJsonTests(named: "cb dc").prefix(testCycles))
        func test_SET_3_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,L (0xCBDD)",  arguments: loadJsonTests(named: "cb dd").prefix(testCycles))
        func test_SET_3_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(HL) (0xCBDE)",  arguments: loadJsonTests(named: "cb de").prefix(testCycles))
        func test_SET_3_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,A (0xCBDF)",  arguments: loadJsonTests(named: "cb df").prefix(testCycles))
        func test_SET_3_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,B (0xCBE0)",  arguments: loadJsonTests(named: "cb e0").prefix(testCycles))
        func test_SET_4_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,C (0xCBE1)",  arguments: loadJsonTests(named: "cb e1").prefix(testCycles))
        func test_SET_4_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,D (0xCBE2)",  arguments: loadJsonTests(named: "cb e2").prefix(testCycles))
        func test_SET_4_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,E (0xCBE3)",  arguments: loadJsonTests(named: "cb e3").prefix(testCycles))
        func test_SET_4_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,H (0xCBE4)",  arguments: loadJsonTests(named: "cb e4").prefix(testCycles))
        func test_SET_4_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,L (0xCBE5)",  arguments: loadJsonTests(named: "cb e5").prefix(testCycles))
        func test_SET_4_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(HL) (0xCBE6)",  arguments: loadJsonTests(named: "cb e6").prefix(testCycles))
        func test_SET_4_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,A (0xCBE7)",  arguments: loadJsonTests(named: "cb e7").prefix(testCycles))
        func test_SET_4_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,B (0xCBE8)",  arguments: loadJsonTests(named: "cb e8").prefix(testCycles))
        func test_SET_5_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,C (0xCBE9)",  arguments: loadJsonTests(named: "cb e9").prefix(testCycles))
        func test_SET_5_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,D (0xCBEA)",  arguments: loadJsonTests(named: "cb ea").prefix(testCycles))
        func test_SET_5_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,E (0xCBEB)",  arguments: loadJsonTests(named: "cb eb").prefix(testCycles))
        func test_SET_5_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,H (0xCBEC)",  arguments: loadJsonTests(named: "cb ec").prefix(testCycles))
        func test_SET_5_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,L (0xCBED)",  arguments: loadJsonTests(named: "cb ed").prefix(testCycles))
        func test_SET_5_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(HL) (0xCBEE)",  arguments: loadJsonTests(named: "cb ee").prefix(testCycles))
        func test_SET_5_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,A (0xCBEF)",  arguments: loadJsonTests(named: "cb ef").prefix(testCycles))
        func test_SET_5_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,B (0xCBF0)",  arguments: loadJsonTests(named: "cb f0").prefix(testCycles))
        func test_SET_6_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,C (0xCBF1)",  arguments: loadJsonTests(named: "cb f1").prefix(testCycles))
        func test_SET_6_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,D (0xCBF2)",  arguments: loadJsonTests(named: "cb f2").prefix(testCycles))
        func test_SET_6_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,E (0xCBF3)",  arguments: loadJsonTests(named: "cb f3").prefix(testCycles))
        func test_SET_6_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,H (0xCBF4)",  arguments: loadJsonTests(named: "cb f4").prefix(testCycles))
        func test_SET_6_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,L (0xCBF5)",  arguments: loadJsonTests(named: "cb f5").prefix(testCycles))
        func test_SET_6_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(HL) (0xCBF6)",  arguments: loadJsonTests(named: "cb f6").prefix(testCycles))
        func test_SET_6_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,A (0xCBF7)",  arguments: loadJsonTests(named: "cb f7").prefix(testCycles))
        func test_SET_6_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,B (0xCBF8)",  arguments: loadJsonTests(named: "cb f8").prefix(testCycles))
        func test_SET_7_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,C (0xCBF9)",  arguments: loadJsonTests(named: "cb f9").prefix(testCycles))
        func test_SET_7_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,D (0xCBFA)",  arguments: loadJsonTests(named: "cb fa").prefix(testCycles))
        func test_SET_7_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,E (0xCBFB)",  arguments: loadJsonTests(named: "cb fb").prefix(testCycles))
        func test_SET_7_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,H (0xCBFC)",  arguments: loadJsonTests(named: "cb fc").prefix(testCycles))
        func test_SET_7_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,L (0xCBFD)",  arguments: loadJsonTests(named: "cb fd").prefix(testCycles))
        func test_SET_7_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(HL) (0xCBFE)",  arguments: loadJsonTests(named: "cb fe").prefix(testCycles))
        func test_SET_7_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,A (0xCBFF)",  arguments: loadJsonTests(named: "cb ff").prefix(testCycles))
        func test_SET_7_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes DD")
    struct ExtendedOpcodesDD: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate LD IX,$nn (0xDD21)",  arguments: loadJsonTests(named: "dd 21").prefix(testCycles))
        func test_LD_IX_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),IX (0xDD22)",  arguments: loadJsonTests(named: "dd 22").prefix(testCycles))
        func test_LD_CON_NN_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC IX (0xDD23)",  arguments: loadJsonTests(named: "dd 23").prefix(testCycles))
        func test_INC_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IX,($nn) (0xDD2A)",  arguments: loadJsonTests(named: "dd 2a").prefix(testCycles))
        func test_LD_IX_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC IX (0xDD2B)",  arguments: loadJsonTests(named: "dd 2b").prefix(testCycles))
        func test_DEC_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),$n (0xDD36)",  arguments: loadJsonTests(named: "dd 36").prefix(testCycles))
        func test_LD_CON_IX_D_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,(IX+$d) (0xDD46)",  arguments: loadJsonTests(named: "dd 46").prefix(testCycles))
        func test_LD_B_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,(IX+$d) (0xDD4E)",  arguments: loadJsonTests(named: "dd 4e").prefix(testCycles))
        func test_LD_C_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,(IX+$d) (0xDD56)",  arguments: loadJsonTests(named: "dd 56").prefix(testCycles))
        func test_LD_D_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,(IX+$d) (0xDD5E)",  arguments: loadJsonTests(named: "dd 5e").prefix(testCycles))
        func test_LD_E_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,(IX+$d) (0xDD66)",  arguments: loadJsonTests(named: "dd 66").prefix(testCycles))
        func test_LD_H_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,(IX+$d) (0xDD6E)",  arguments: loadJsonTests(named: "dd 6e").prefix(testCycles))
        func test_LD_L_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),B (0xDD70)",  arguments: loadJsonTests(named: "dd 70").prefix(testCycles))
        func test_LD_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),C (0xDD71)",  arguments: loadJsonTests(named: "dd 71").prefix(testCycles))
        func test_LD_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),D (0xDD72)",  arguments: loadJsonTests(named: "dd 72").prefix(testCycles))
        func test_LD_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),E (0xDD73)",  arguments: loadJsonTests(named: "dd 73").prefix(testCycles))
        func test_LD_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),H (0xDD74)",  arguments: loadJsonTests(named: "dd 74").prefix(testCycles))
        func test_LD_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),L (0xDD75)",  arguments: loadJsonTests(named: "dd 75").prefix(testCycles))
        func test_LD_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),A (0xDD77)",  arguments: loadJsonTests(named: "dd 77").prefix(testCycles))
        func test_LD_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,(IX+$d) (0xDD7E)",  arguments: loadJsonTests(named: "dd 7e").prefix(testCycles))
        func test_LD_A_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate POP IX (0xDDE1)",  arguments: loadJsonTests(named: "dd e1").prefix(testCycles))
        func test_POP_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EX (SP),IX (0xDDE3)",  arguments: loadJsonTests(named: "dd e3").prefix(testCycles))
        func test_EX_CON_SP_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate PUSH IX (0xDDE5)",  arguments: loadJsonTests(named: "dd e5").prefix(testCycles))
        func test_PUSH_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP (IX) (0xDDE9)",  arguments: loadJsonTests(named: "dd e9").prefix(testCycles))
        func test_JP_CON_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD SP,IX (0xDDF9)",  arguments: loadJsonTests(named: "dd f9").prefix(testCycles))
        func test_LD_SP_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes DDCB")
    struct ExtendedOpcodesDDCB: testHelper
    {
        let parent = Z80Opcodes()
        
        //dd cb __ 00
        
        @Test("Validate RES 0,(IX+$d) (0xDDCB__86)",  arguments: loadJsonTests(named: "dd cb __ 86").prefix(testCycles))
        func test_RES_0_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IX+$d) (0xDDCB__8E)",  arguments: loadJsonTests(named: "dd cb __ 8e").prefix(testCycles))
        func test_RES_1_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IX+$d) (0xDDCB__96)",  arguments: loadJsonTests(named: "dd cb __ 96").prefix(testCycles))
        func test_RES_2_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IX+$d) (0xDDCB__9E)",  arguments: loadJsonTests(named: "dd cb __ 9e").prefix(testCycles))
        func test_RES_3_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IX+$d) (0xDDCB__A6)",  arguments: loadJsonTests(named: "dd cb __ a6").prefix(testCycles))
        func test_RES_4_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IX+$d) (0xDDCB__AE)",  arguments: loadJsonTests(named: "dd cb __ ae").prefix(testCycles))
        func test_RES_5_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IX+$d) (0xDDCB__B6)",  arguments: loadJsonTests(named: "dd cb __ b6").prefix(testCycles))
        func test_RES_6_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IX+$d) (0xDDCB__BE)",  arguments: loadJsonTests(named: "dd cb __ be").prefix(testCycles))
        func test_RES_7_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IX+$d) (0xDDCB__C6)",  arguments: loadJsonTests(named: "dd cb __ c6").prefix(testCycles))
        func test_SET_0_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IX+$d) (0xDDCB__CE)",  arguments: loadJsonTests(named: "dd cb __ ce").prefix(testCycles))
        func test_SET_1_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IX+$d) (0xDDCB__D6)",  arguments: loadJsonTests(named: "dd cb __ d6").prefix(testCycles))
        func test_SET_2_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IX+$d) (0xDDCB__DE)",  arguments: loadJsonTests(named: "dd cb __ de").prefix(testCycles))
        func test_SET_3_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IX+$d) (0xDDCB__E6)",  arguments: loadJsonTests(named: "dd cb __ Ee6").prefix(testCycles))
        func test_SET_4_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IX+$d) (0xDDCB__EE)",  arguments: loadJsonTests(named: "dd cb __ ee").prefix(testCycles))
        func test_SET_5_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IX+$d) (0xDDCB__F6)",  arguments: loadJsonTests(named: "dd cb __ f6").prefix(testCycles))
        func test_SET_6_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IX+$d) (0xDDCB__FE)",  arguments: loadJsonTests(named: "dd cb __ fe").prefix(testCycles))
        func test_SET_7_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes ED")
    struct ExtendedOpcodesED: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate OUT (C),B (0xED41)",  arguments: loadJsonTests(named: "ed 41").prefix(testCycles))
        func test_OUT_C_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),BC (0xED43)",  arguments: loadJsonTests(named: "ed 43").prefix(testCycles))
        func test_LD_CON_NN_BC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RETN (0xED45)",  arguments: loadJsonTests(named: "ed 45").prefix(testCycles))
        func test_RETN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate IM 0 (0xED46)",  arguments: loadJsonTests(named: "ed 46").prefix(testCycles))
        func test_IM_0(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD I,A (0xED47)",  arguments: loadJsonTests(named: "ed 47").prefix(testCycles))
        func test_LD_I_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT (C),C (0xED49)",  arguments: loadJsonTests(named: "ed 49").prefix(testCycles))
        func test_OUT_C_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD BC,($nn) (0xED4B)",  arguments: loadJsonTests(named: "ed 4b").prefix(testCycles))
        func test_LD_BC_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RETI (0xED4D)",  arguments: loadJsonTests(named: "ed 4d").prefix(testCycles))
        func test_RETI(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD R,A (0xED4F)",  arguments: loadJsonTests(named: "ed 4f").prefix(testCycles))
        func test_LD_R_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT (C),D (0xED51)",  arguments: loadJsonTests(named: "ed 51").prefix(testCycles))
        func test_OUT_C_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),DE (0xED53)",  arguments: loadJsonTests(named: "ed 53").prefix(testCycles))
        func test_LD_CON_NN_DE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate IM 1 (0xED56)",  arguments: loadJsonTests(named: "ed 56").prefix(testCycles))
        func test_IM_1(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT (C),E (0xED59)",  arguments: loadJsonTests(named: "ed 59").prefix(testCycles))
        func test_OUT_C_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD DE,($nn) (0xED5B)",  arguments: loadJsonTests(named: "ed 5b").prefix(testCycles))
        func test_LD_DE_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate IM 2 (0xED5E)",  arguments: loadJsonTests(named: "ed 5e").prefix(testCycles))
        func test_IM_2(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT (C),H (0xED61)",  arguments: loadJsonTests(named: "ed 61").prefix(testCycles))
        func test_OUT_C_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT (C),L (0xED69)",  arguments: loadJsonTests(named: "ed 69").prefix(testCycles))
        func test_OUT_C_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),SP (0xED73)",  arguments: loadJsonTests(named: "ed 73").prefix(testCycles))
        func test_LD_CON_NN_SP(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT (C),A (0xED79)",  arguments: loadJsonTests(named: "ed 79").prefix(testCycles))
        func test_OUT_C_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD SP,($nn) (0xED7B)",  arguments: loadJsonTests(named: "ed 7b").prefix(testCycles))
        func test_LD_SP_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes FD")
    struct ExtendedOpcodesFD: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate LD IY,$nn (0xFD21)",  arguments: loadJsonTests(named: "fd 21").prefix(testCycles))
        func test_LD_IY_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),IY (0xFD22)",  arguments: loadJsonTests(named: "fd 22").prefix(testCycles))
        func test_LD_CON_NN_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC IY (0xFD23)",  arguments: loadJsonTests(named: "fd 23").prefix(testCycles))
        func test_INC_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IY,($nn) (0xFD2A)",  arguments: loadJsonTests(named: "fd 2a").prefix(testCycles))
        func test_LD_IY_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC IY (0xFD2B)",  arguments: loadJsonTests(named: "fd 2b").prefix(testCycles))
        func test_DEC_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),$n (0xFD36)",  arguments: loadJsonTests(named: "fd 36").prefix(testCycles))
        func test_LD_CON_IY_D_$n(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,(IY+$d) (0xFD46)",  arguments: loadJsonTests(named: "fd 46").prefix(testCycles))
        func test_LD_B_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,(IY+$d) (0xFD4E)",  arguments: loadJsonTests(named: "fd 4e").prefix(testCycles))
        func test_LD_C_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,(IY+$d) (0xFD56)",  arguments: loadJsonTests(named: "fd 56").prefix(testCycles))
        func test_LD_D_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,(IY+$d) (0xFD5E)",  arguments: loadJsonTests(named: "fd 5e").prefix(testCycles))
        func test_LD_E_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,(IY+$d) (0xFD66)",  arguments: loadJsonTests(named: "fd 66").prefix(testCycles))
        func test_LD_H_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,(IY+$d) (0xFD6E)",  arguments: loadJsonTests(named: "fd 6e").prefix(testCycles))
        func test_LD_L_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),B (0xFD70)",  arguments: loadJsonTests(named: "fd 70").prefix(testCycles))
        func test_LD_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),C (0xFD71)",  arguments: loadJsonTests(named: "fd 71").prefix(testCycles))
        func test_LD_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),D (0xFD72)",  arguments: loadJsonTests(named: "fd 72").prefix(testCycles))
        func test_LD_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),E (0xFD73)",  arguments: loadJsonTests(named: "fd 73").prefix(testCycles))
        func test_LD_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),H (0xFD74)",  arguments: loadJsonTests(named: "fd 74").prefix(testCycles))
        func test_LD_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),L (0xFD75)",  arguments: loadJsonTests(named: "fd 75").prefix(testCycles))
        func test_LD_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),A (0xFD77)",  arguments: loadJsonTests(named: "fd 77").prefix(testCycles))
        func test_LD_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,(IY+$d) (0xFD7E)",  arguments: loadJsonTests(named: "fd 7e").prefix(testCycles))
        func test_LD_A_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate POP IY (0xFDE1)",  arguments: loadJsonTests(named: "fd e1").prefix(testCycles))
        func test_POP_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EX (SP),IY (0xFDE3)",  arguments: loadJsonTests(named: "fd e3").prefix(testCycles))
        func test_EX_CON_SP_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate PUSH IY (0xFDE5)",  arguments: loadJsonTests(named: "fd e5").prefix(testCycles))
        func test_PUSH_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP (IY) (0xFDE9)",  arguments: loadJsonTests(named: "fd e9").prefix(testCycles))
        func test_JP_CON_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD SP,IY (0xFDF9)",  arguments: loadJsonTests(named: "fd f9").prefix(testCycles))
        func test_LD_SP_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes FDCB")
    struct ExtendedOpcodesFDCB: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate RES 0,(IY+$d) (0xFDCB__86)",  arguments: loadJsonTests(named: "fd cb __ 86").prefix(testCycles))
        func test_RES_0_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IY+$d) (0xFDCB__8E)",  arguments: loadJsonTests(named: "fd cb __ 8e").prefix(testCycles))
        func test_RES_1_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IY+$d) (0xFDCB__96)",  arguments: loadJsonTests(named: "fd cb __ 96").prefix(testCycles))
        func test_RES_2_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IY+$d) (0xFDCB__9E)",  arguments: loadJsonTests(named: "fd cb __ 9e").prefix(testCycles))
        func test_RES_3_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IY+$d) (0xFDCB__A6)",  arguments: loadJsonTests(named: "fd cb __ a6").prefix(testCycles))
        func test_RES_4_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IY+$d) (0xFDCB__AE)",  arguments: loadJsonTests(named: "fd cb __ ae").prefix(testCycles))
        func test_RES_5_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IY+$d) (0xFDCB__B6)",  arguments: loadJsonTests(named: "fd cb __ b6").prefix(testCycles))
        func test_RES_6_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IY+$d) (0xFDCB__BE)",  arguments: loadJsonTests(named: "fd cb __ be").prefix(testCycles))
        func test_RES_7_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IY+$d) (0xFDCB__C6)",  arguments: loadJsonTests(named: "fd cb __ c6").prefix(testCycles))
        func test_SET_0_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IY+$d) (0xFDCB__CE)",  arguments: loadJsonTests(named: "fd cb __ ce").prefix(testCycles))
        func test_SET_1_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IY+$d) (0xFDCB__D6)",  arguments: loadJsonTests(named: "fd cb __ d6").prefix(testCycles))
        func test_SET_2_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IY+$d) (0xFDCB__DE)",  arguments: loadJsonTests(named: "fd cb __ de").prefix(testCycles))
        func test_SET_3_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IY+$d) (0xFDCB__E6)",  arguments: loadJsonTests(named: "fd cb __ e6").prefix(testCycles))
        func test_SET_4_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IY+$d) (0xFDCB__EE)",  arguments: loadJsonTests(named: "fd cb __ ee").prefix(testCycles))
        func test_SET_5_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IY+$d) (0xFDCB__F6)",  arguments: loadJsonTests(named: "fd cb __ f6").prefix(testCycles))
        func test_SET_6_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IY+$d) (0xFDCB__FE)",  arguments: loadJsonTests(named: "fd cb __ fe").prefix(testCycles))
        func test_SET_7_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        
    }
}

