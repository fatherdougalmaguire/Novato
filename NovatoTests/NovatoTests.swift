import Foundation
import Testing

let testCycles = 1000

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
        // Map 0 -> false (Read), 1 -> true (Write)
        self.isWrite = try container.decode(Int.self) == 1
    }
}

struct BusCycle: Decodable
{
    let address: UInt16
    let data: UInt8
    let signals: String

    init(from decoder: Decoder) throws {
        // UnkeyedContainer lets us step through an array one-by-one
        var container = try decoder.unkeyedContainer()
        
        // We decode each "slot" in the array into the specific type we want
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
   // let cycles : BusCycle
   // let ports : PortActivity
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
    
    func testError(finalState: CPUState, expected: CPUState, context: String)
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
    }
    
    func runTest(_ testCase: Z80Test) async throws
    {
        let cpu = microbee()
        await cpu.loadCPUState(cpuState: testCase.initial)
        await cpu.nextInstruction()
        let finalState = await cpu.returnCPUState(cpuState: testCase.initial)
        testError(finalState: finalState, expected: testCase.final, context: testCase.name)
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
    }
    
    @Suite("Extended Opcodes ED")
    struct ExtendedOpcodesED: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("LD I,A (0xED47)", arguments: loadJsonTests(named: "ed 47").prefix(testCycles))
        func test_LD_I_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
}

