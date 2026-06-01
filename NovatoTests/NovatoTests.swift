import Foundation
import Testing

let testCycles = 1000
let testTiming = 30

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
    let data: UInt8?
    let signals: String

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        self.address = try container.decode(UInt16.self)
        self.data = try container.decodeIfPresent(UInt8.self)
        self.signals = try container.decode(String.self)
    }
}

struct Z80Test: Decodable, Sendable
{
    let name: String
    let initial: CPUState
    let final: CPUState
    let cycles : [BusCycle]
    let ports: [PortActivity]

    enum CodingKeys: String, CodingKey
    {
        case name, initial, final, cycles, ports
    }

    init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.initial = try container.decode(CPUState.self, forKey: .initial)
        self.final = try container.decode(CPUState.self, forKey: .final)
        self.cycles = try container.decode([BusCycle].self, forKey: .cycles)
        self.ports = try container.decodeIfPresent([PortActivity].self, forKey: .ports) ?? []
    }
}
protocol testHelper {}

extension testHelper
{
    static func loadJsonTests(named filename: String, range: ClosedRange<Int>? = nil) -> [Z80Test]
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
            let tests = try JSONDecoder().decode([Z80Test].self, from: data)
            
            guard let range
            else
            {
               return tests
            }

            let safeLower = max(0, range.lowerBound)

            let safeUpper = min(tests.count - 1, range.upperBound)

            guard safeLower <= safeUpper
            else
            {
               return []
            }

            return Array(tests[safeLower...safeUpper]
           )
        }
        catch
        {
            print("Error decoding \(filename).json: \(error)")
            return []
        }
    }
    
    func testError(finalState: CPUState, expected: CPUState, testForPorts: Bool, finalPortValue: UInt8, ports: [PortActivity], expectedCycles: Int, finalCycles : Int, context: String)
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
       #expect(finalState.PC == expected.PC, "Register PC fail in \(context)")
       #expect(finalState.SP == expected.SP, "Register SP fail in \(context)")
       #expect(finalState.IX == expected.IX, "Register IX fail in \(context)")
       #expect(finalState.IY == expected.IY, "Register IY fail in \(context)")
       #expect(finalState.WZ == expected.WZ, "Register WZ fail in \(context)")
       #expect(finalState.ram == expected.ram, "RAM fail in \(context)")
       #expect(finalState.Q == expected.Q,"Register Q fail in \(context)")
       #expect(finalState.P == expected.P,"Register P fail in \(context)")
       #expect(finalState.EI == expected.EI,"Register EI fail in \(context)")
       #expect(finalState.IFF1 == expected.IFF1, "Register IFF1 fail in \(context)")
       #expect(finalState.IFF2 == expected.IFF2, "Register IFF2 fail in \(context)")
       if testForPorts
       {
           #expect( finalPortValue == ports[0].value, "Ports fail in \(context)")
       }
       #expect(expectedCycles == finalCycles,"T-States fail in \(context)")
    }
    
    func runTest(_ testCase: Z80Test) async throws
    {
        let testForPorts : Bool = !testCase.ports.isEmpty
        let cpu = microbee()
        await cpu.loadCPUState(cpuState: testCase.initial)
        if testForPorts
        {
            await cpu.loadPorts(portNum: testCase.ports[0].address, portValue: testCase.ports[0].value)
        }
        await cpu.nextInstruction()
        let finalState = await cpu.returnCPUState(cpuState: testCase.initial)
        let finalPortValue = testForPorts ? await cpu.returnPortValue(portNum: testCase.ports[0].address) : 0
        let finalCycles = await cpu.returnTStates()
        testError(finalState: finalState, expected: testCase.final, testForPorts: testForPorts, finalPortValue: finalPortValue, ports: testCase.ports, expectedCycles: testCase.cycles.count, finalCycles: finalCycles, context: testCase.name)
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
        
        @Test("NOP (0x00)", arguments: loadJsonTests(named: "00", range: 0...testCycles-1))
        func test_NOP(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("LD BC,nn (0x01)", arguments: loadJsonTests(named: "01", range: 0...testCycles-1))
        func test_LD_BC_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (BC),A (0x02)", arguments: loadJsonTests(named: "02", range: 0...testCycles-1))
        func test_LD_CON_BC_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC BC (0x03)", arguments: loadJsonTests(named: "03", range: 0...testCycles-1))
        func test_INC_BC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,$n (0x06)", arguments: loadJsonTests(named: "06", range: 0...testCycles-1))
        func test_LD_B_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EX AF,AF'(0x08)", arguments: loadJsonTests(named: "08", range: 0...testCycles-1))
        func test_EX_AF_altAF(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,(BC) (0x0A)", arguments: loadJsonTests(named: "0a", range: 0...testCycles-1))
        func test_LD_A_CON_BC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC BC (0x0B)", arguments: loadJsonTests(named: "0b", range: 0...testCycles-1))
        func test_DEC_BC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,$n (0x0E)", arguments: loadJsonTests(named: "0e", range: 0...testCycles-1))
        func test_LD_C_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DJNZ $d (0x10)", arguments: loadJsonTests(named: "10", range: 0...testCycles-1))
        func test_DJNZ_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD DE,$nn (0x11)", arguments: loadJsonTests(named: "11", range: 0...testCycles-1))
        func test_LD_DE_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (DE),A (0x12)", arguments: loadJsonTests(named: "12", range: 0...testCycles-1))
        func test_LD_CON_DE_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC DE (0x13)", arguments: loadJsonTests(named: "13", range: 0...testCycles-1))
        func test_INC_DE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,$n (0x16)", arguments: loadJsonTests(named: "16", range: 0...testCycles-1))
        func test_LD_D_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JR $d (0x18)", arguments: loadJsonTests(named: "18", range: 0...testCycles-1))
        func test_JR_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,(DE) (0x1A)", arguments: loadJsonTests(named: "1a", range: 0...testCycles-1))
        func test_LD_A_CON_DE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC DE (0x1B)", .serialized, arguments: loadJsonTests(named: "1b", range: 0...testCycles-1))
        func test_DEC_DE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,$n (0x1E)", .serialized, arguments: loadJsonTests(named: "1e", range: 0...testCycles-1))
        func test_LD_E_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JR NZ,$d (0x20)", arguments: loadJsonTests(named: "20", range: 0...testCycles-1))
        func test_JR_NZ_d(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD HL,$nn (0x21)", .serialized, arguments: loadJsonTests(named: "21", range: 0...testCycles-1))
        func test_LD_HL_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),HL (0x22)", .serialized, arguments: loadJsonTests(named: "22", range: 0...testCycles-1))
        func test_LD_CON_NN_HL_(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC HL (0x23)", .serialized, arguments: loadJsonTests(named: "23", range: 0...testCycles-1))
        func test_INC_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,$n (0x26)", .serialized, arguments: loadJsonTests(named: "26", range: 0...testCycles-1))
        func test_LD_H_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JR Z,$d (0x28)", .serialized, arguments: loadJsonTests(named: "28", range: 0...testCycles-1))
        func test_JR_Z_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD HL,($nn) (0x2A)", .serialized, arguments: loadJsonTests(named: "2a", range: 0...testCycles-1))
        func test_LD_HL_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC HL (0x2B)", .serialized, arguments: loadJsonTests(named: "2b", range: 0...testCycles-1))
        func test_DEC_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,$n (0x2E)", .serialized, arguments: loadJsonTests(named: "2e", range: 0...testCycles-1))
        func test_LD_L_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JR NC,$d (0x30)", .serialized, arguments: loadJsonTests(named: "30", range: 0...testCycles-1))
        func test_JR_NC_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD SP,$nn (0x31)", .serialized, arguments: loadJsonTests(named: "31", range: 0...testCycles-1))
        func test_LD_SP_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),A (0x32)", .serialized, arguments: loadJsonTests(named: "32", range: 0...testCycles-1))
        func test_LD_CON_NN_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC SP (0x33)", .serialized, arguments: loadJsonTests(named: "33", range: 0...testCycles-1))
        func test_INC_SP(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),$n (0x36)", .serialized, arguments: loadJsonTests(named: "36", range: 0...testCycles-1))
        func test_LD_CON_HL_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JR C,$d (0x38)", .serialized, arguments: loadJsonTests(named: "38", range: 0...testCycles-1))
        func test_JR_C_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,($nn) (0x3A)", .serialized, arguments: loadJsonTests(named: "3a", range: 0...testCycles-1))
        func test_LD_A_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC SP (0x3B)", .serialized, arguments: loadJsonTests(named: "3b", range: 0...testCycles-1))
        func test_DEC_SP(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,$n (0x3E)", .serialized, arguments: loadJsonTests(named: "3e", range: 0...testCycles-1))
        func test_LD_A_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,B (0x40)", .serialized, arguments: loadJsonTests(named: "40", range: 0...testCycles-1))
        func test_LD_B_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,C (0x41)", .serialized, arguments: loadJsonTests(named: "41", range: 0...testCycles-1))
        func test_LD_B_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,D (0x42)", .serialized, arguments: loadJsonTests(named: "42", range: 0...testCycles-1))
        func test_LD_B_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,E (0x43)", .serialized, arguments: loadJsonTests(named: "43", range: 0...testCycles-1))
        func test_LD_B_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,H (0x44)", .serialized, arguments: loadJsonTests(named: "44", range: 0...testCycles-1))
        func test_LD_B_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,L (0x45)", .serialized, arguments: loadJsonTests(named: "45", range: 0...testCycles-1))
        func test_LD_B_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,(HL) (0x46)", .serialized, arguments: loadJsonTests(named: "46", range: 0...testCycles-1))
        func test_LD_B_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,A (0x47)", .serialized, arguments: loadJsonTests(named: "47", range: 0...testCycles-1))
        func test_LD_B_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,B (0x48)", .serialized, arguments: loadJsonTests(named: "48", range: 0...testCycles-1))
        func test_LD_C_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,C (0x49)", .serialized, arguments: loadJsonTests(named: "49", range: 0...testCycles-1))
        func test_LD_C_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,D (0x4A)", .serialized, arguments: loadJsonTests(named: "4a", range: 0...testCycles-1))
        func test_LD_C_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,E (0x4B)", .serialized, arguments: loadJsonTests(named: "4b", range: 0...testCycles-1))
        func test_LD_C_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,H (0x4C)", .serialized, arguments: loadJsonTests(named: "4c", range: 0...testCycles-1))
        func test_LD_C_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,L (0x4D)", .serialized, arguments: loadJsonTests(named: "4d", range: 0...testCycles-1))
        func test_LD_C_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,(HL) (0x4E)", .serialized, arguments: loadJsonTests(named: "4e", range: 0...testCycles-1))
        func test_LD_C_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,A (0x4F)", .serialized, arguments: loadJsonTests(named: "4f", range: 0...testCycles-1))
        func test_LD_C_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,B (0x50)", .serialized, arguments: loadJsonTests(named: "50", range: 0...testCycles-1))
        func test_LD_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,C (0x51)", .serialized, arguments: loadJsonTests(named: "51", range: 0...testCycles-1))
        func test_LD_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,D (0x52)", .serialized, arguments: loadJsonTests(named: "52", range: 0...testCycles-1))
        func test_LD_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,E (0x53)", arguments: loadJsonTests(named: "53", range: 0...testCycles-1))
        func test_LD_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,H (0x54)", arguments: loadJsonTests(named: "54", range: 0...testCycles-1))
        func test_LD_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,L (0x55)", arguments: loadJsonTests(named: "55", range: 0...testCycles-1))
        func test_LD_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,(HL) (0x56)", arguments: loadJsonTests(named: "56", range: 0...testCycles-1))
        func test_LD_D_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,A (0x57)", arguments: loadJsonTests(named: "57", range: 0...testCycles-1))
        func test_LD_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,B (0x58)", .serialized, arguments: loadJsonTests(named: "58", range: 0...testCycles-1))
        func test_LD_E_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,C (0x59)", .serialized, arguments: loadJsonTests(named: "59", range: 0...testCycles-1))
        func test_LD_E_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,D (0x5A)", .serialized, arguments: loadJsonTests(named: "5a", range: 0...testCycles-1))
        func test_LD_E_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,E (0x5B)", .serialized, arguments: loadJsonTests(named: "5b", range: 0...testCycles-1))
        func test_LD_E_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,H (0x5C)", .serialized, arguments: loadJsonTests(named: "5c", range: 0...testCycles-1))
        func test_LD_E_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,L (0x5D)", .serialized, arguments: loadJsonTests(named: "5d", range: 0...testCycles-1))
        func test_LD_E_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,(HL) (0x5E)", .serialized, arguments: loadJsonTests(named: "5e", range: 0...testCycles-1))
        func test_LD_E_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,A (0x5F)", .serialized, arguments: loadJsonTests(named: "5f", range: 0...testCycles-1))
        func test_LD_E_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,B (0x60)", .serialized, arguments: loadJsonTests(named: "60", range: 0...testCycles-1))
        func test_LD_H_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,C (0x61)", .serialized, arguments: loadJsonTests(named: "61", range: 0...testCycles-1))
        func test_LD_H_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,D (0x62)", .serialized, arguments: loadJsonTests(named: "62", range: 0...testCycles-1))
        func test_LD_H_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,E (0x63)", arguments: loadJsonTests(named: "63", range: 0...testCycles-1))
        func test_LD_H_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,H (0x64)", arguments: loadJsonTests(named: "64", range: 0...testCycles-1))
        func test_LD_H_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,L (0x65)", arguments: loadJsonTests(named: "65", range: 0...testCycles-1))
        func test_LD_H_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,(HL) (0x66)", arguments: loadJsonTests(named: "66", range: 0...testCycles-1))
        func test_LD_H_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,A (0x67)", arguments: loadJsonTests(named: "67", range: 0...testCycles-1))
        func test_LD_H_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,B (0x68)", arguments: loadJsonTests(named: "68", range: 0...testCycles-1))
        func test_LD_L_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,C (0x69)", arguments: loadJsonTests(named: "69", range: 0...testCycles-1))
        func test_LD_L_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,D (0x6A)", arguments: loadJsonTests(named: "6a", range: 0...testCycles-1))
        func test_LD_L_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,E (0x6B)",  arguments: loadJsonTests(named: "6b", range: 0...testCycles-1))
        func test_LD_L_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,H (0x6C)",  arguments: loadJsonTests(named: "6c", range: 0...testCycles-1))
        func test_LD_L_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,L (0x6D)",  arguments: loadJsonTests(named: "6d", range: 0...testCycles-1))
        func test_LD_L_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,(HL) (0x6E)", arguments: loadJsonTests(named: "6e", range: 0...testCycles-1))
        func test_LD_L_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,A (0x6F)",  arguments: loadJsonTests(named: "6f", range: 0...testCycles-1))
        func test_LD_L_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),B (0x70)",  arguments: loadJsonTests(named: "70", range: 0...testCycles-1))
        func test_LD_CON_HL_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),C (0x71)",  arguments: loadJsonTests(named: "71", range: 0...testCycles-1))
        func test_LD_CON_HL_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),D (0x72)",  arguments: loadJsonTests(named: "72", range: 0...testCycles-1))
        func test_LD_CON_HL_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),E (0x73)",  arguments: loadJsonTests(named: "73", range: 0...testCycles-1))
        func test_LD_CON_HL_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),H (0x74)",  arguments: loadJsonTests(named: "74", range: 0...testCycles-1))
        func test_LD_CON_HL_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),L (0x75)",  arguments: loadJsonTests(named: "75", range: 0...testCycles-1))
        func test_LD_CON_HL_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate HALT (0x76)",  arguments: loadJsonTests(named: "76", range: 0...testCycles-1))
        func test_HALT(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (HL),A (0x77)",  arguments: loadJsonTests(named: "77", range: 0...testCycles-1))
        func test_LD_CON_HL_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,B (0x78)",  arguments: loadJsonTests(named: "78", range: 0...testCycles-1))
        func test_LD_A_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,C (0x79)",  arguments: loadJsonTests(named: "79", range: 0...testCycles-1))
        func test_LD_A_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,D (0x7A)",  arguments: loadJsonTests(named: "7a", range: 0...testCycles-1))
        func test_LD_A_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,E (0x7B)",  arguments: loadJsonTests(named: "7b", range: 0...testCycles-1))
        func test_LD_A_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,H (0x7C)",  arguments: loadJsonTests(named: "7c", range: 0...testCycles-1))
        func test_LD_A_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,L (0x7D)",  arguments: loadJsonTests(named: "7d", range: 0...testCycles-1))
        func test_LD_A_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,(HL) (0x7E)",  arguments: loadJsonTests(named: "7e", range: 0...testCycles-1))
        func test_LD_A_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,A (0x7F)",  arguments: loadJsonTests(named: "7f", range: 0...testCycles-1))
        func test_LD_A_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET NZ (0xC0)",  arguments: loadJsonTests(named: "c0", range: 0...testCycles-1))
        func test_RET_NZ(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }
        
        @Test("Validate POP BC (0xC1)",  arguments: loadJsonTests(named: "c1", range: 0...testCycles-1))
        func test_POP_BC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP NZ,$nn (0xC2)",  arguments: loadJsonTests(named: "c2", range: 0...testCycles-1))
        func test_JP_NZ_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP $nn (0xC3)",  arguments: loadJsonTests(named: "c3", range: 0...testCycles-1))
        func test_JP_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL NZ,$nn (0xC4)",  arguments: loadJsonTests(named: "c4", range: 0...testCycles-1))
        func test_CALL_NZ_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate PUSH BC (0xC5)",  arguments: loadJsonTests(named: "c5", range: 0...testCycles-1))
        func test_PUSH_BC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x00 (0xC7)",  arguments: loadJsonTests(named: "c7", range: 0...testCycles-1))
        func test_RST_0x00(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET Z (0xC8)",  arguments: loadJsonTests(named: "c8", range: 0...testCycles-1))
        func test_RET_Z(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET (0xC9)",  arguments: loadJsonTests(named: "c9", range: 0...testCycles-1))
        func test_RET(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP Z,$nn (0xCA)",  arguments: loadJsonTests(named: "ca", range: 0...testCycles-1))
        func test_JP_Z_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL Z,$nn (0xCC)",  arguments: loadJsonTests(named: "cc", range: 0...testCycles-1))
        func test_CALL_Z_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL $nn (0xCD)",  arguments: loadJsonTests(named: "cd", range: 0...testCycles-1))
        func test_CALL_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x08 (0xCF)",  arguments: loadJsonTests(named: "cf", range: 0...testCycles-1))
        func test_RST_0x08(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET NC (0xD0)",  arguments: loadJsonTests(named: "d0", range: 0...testCycles-1))
        func test_RET_NC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate POP DE (0xD1)",  arguments: loadJsonTests(named: "d1", range: 0...testCycles-1))
        func test_POP_DE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP NC,$nn (0xD2)",  arguments: loadJsonTests(named: "d2", range: 0...testCycles-1))
        func test_JP_NC_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT ($n),A (0xD3)",  arguments: loadJsonTests(named: "d3", range: 0...testCycles-1))
        func test_OUT_N_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL NC,$nn (0xD4)",  arguments: loadJsonTests(named: "d4", range: 0...testCycles-1))
        func test_CALL_NC_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate PUSH DE (0xD5)",  arguments: loadJsonTests(named: "d5", range: 0...testCycles-1))
        func test_PUSH_DE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x10 (0xD7)",  arguments: loadJsonTests(named: "d7", range: 0...testCycles-1))
        func test_RST_0x10(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET C (0xD8)",  arguments: loadJsonTests(named: "d8", range: 0...testCycles-1))
        func test_RET_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EXX (0xD9)",  arguments: loadJsonTests(named: "d9", range: 0...testCycles-1))
        func test_EXX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP C,$nn (0xDA)",  arguments: loadJsonTests(named: "da", range: 0...testCycles-1))
        func test_JP_C_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate IN A,($n) (0xDB)",  arguments: loadJsonTests(named: "db", range: 0...testCycles-1))
        func test_IN_A_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL C,$nn (0xDC)",  arguments: loadJsonTests(named: "dc", range: 0...testCycles-1))
        func test_CALL_C_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x18 (0xDF)",  arguments: loadJsonTests(named: "df", range: 0...testCycles-1))
        func test_RST_0x18(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET PO (0xE0)",  arguments: loadJsonTests(named: "e0", range: 0...testCycles-1))
        func test_RET_PO(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate POP HL (0xE1)",  arguments: loadJsonTests(named: "e1", range: 0...testCycles-1))
        func test_POP_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP PO,$nn (0xE2)",  arguments: loadJsonTests(named: "e2", range: 0...testCycles-1))
        func test_JP_PO_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EX (SP),HL (0xE3)",  arguments: loadJsonTests(named: "e3", range: 0...testCycles-1))
        func test_EX_CON_SP_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL PO,$nn (0xE4)",  arguments: loadJsonTests(named: "e4", range: 0...testCycles-1))
        func test_CALL_PO_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate PUSH HL (0xE5)",  arguments: loadJsonTests(named: "e5", range: 0...testCycles-1))
        func test_PUSH_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x20 (0xE7)",  arguments: loadJsonTests(named: "e7", range: 0...testCycles-1))
        func test_RST_0x20(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET PE (0xE8)",  arguments: loadJsonTests(named: "e8", range: 0...testCycles-1))
        func test_RET_PE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP (HL) (0xE9)",  arguments: loadJsonTests(named: "e9", range: 0...testCycles-1))
        func test_JP_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP PE,$nn (0xEA)",  arguments: loadJsonTests(named: "ea", range: 0...testCycles-1))
        func test_JP_PE_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EX DE,HL (0xEB)",  arguments: loadJsonTests(named: "eb", range: 0...testCycles-1))
        func test_EX_DE_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL PE,$nn (0xEC)",  arguments: loadJsonTests(named: "ec", range: 0...testCycles-1))
        func test_CALL_PE_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x28 (0xEF)",  arguments: loadJsonTests(named: "ef", range: 0...testCycles-1))
        func test_RST_0x28(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET P (0xF0)",  arguments: loadJsonTests(named: "f0", range: 0...testCycles-1))
        func test_RET_P(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate POP AF (0xF1)",  arguments: loadJsonTests(named: "f1", range: 0...testCycles-1))
        func test_POP_AF(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP P,$nn (0xF2)",  arguments: loadJsonTests(named: "f2", range: 0...testCycles-1))
        func test_JP_P_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DI (0xF3)",  arguments: loadJsonTests(named: "f3", range: 0...testCycles-1))
        func test_DI(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL P,$nn (0xF4)",  arguments: loadJsonTests(named: "f4", range: 0...testCycles-1))
        func test_CALL_P_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate PUSH AF (0xF5)",  arguments: loadJsonTests(named: "f5", range: 0...testCycles-1))
        func test_PUSH_AF(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x30 (0xF7)",  arguments: loadJsonTests(named: "f7", range: 0...testCycles-1))
        func test_RST_0x30(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RET M (0xF8)",  arguments: loadJsonTests(named: "f8", range: 0...testCycles-1))
        func test_RET_M(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD SP,HL (0xF9)",  arguments: loadJsonTests(named: "f9", range: 0...testCycles-1))
        func test_LD_SP_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP M,$nn (0xFA)",  arguments: loadJsonTests(named: "fa", range: 0...testCycles-1))
        func test_JP_M_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EI (0xFB)",  arguments: loadJsonTests(named: "fb", range: 0...testCycles-1))
        func test_EI(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CALL M,$nn (0xFC)",  arguments: loadJsonTests(named: "fc", range: 0...testCycles-1))
        func test_CALL_M_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RST 0x38 (0xFF)",  arguments: loadJsonTests(named: "ff", range: 0...testCycles-1))
        func test_RST_0x38(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Primary Opcodes Flags")
    struct primaryOpcodesFlags
    {
        let parent = Z80Opcodes()
        
        @Test("Validate INC B (0x04)",  arguments: loadJsonTests(named: "04", range: 0...testCycles-1))
        func test_INC_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate DEC B (0x05)",  arguments: loadJsonTests(named: "05", range: 0...testCycles-1))
        func test_DEC_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RLCA (0x07)",  arguments: loadJsonTests(named: "07", range: 0...testCycles-1))
        func test_RLCA(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD HL,BC (0x09)",  arguments: loadJsonTests(named: "09", range: 0...testCycles-1))
        func test_ADD_HL_BC(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate INC C (0x0C)",  arguments: loadJsonTests(named: "0c", range: 0...testCycles-1))
        func test_INC_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate DEC C (0x0D)",  arguments: loadJsonTests(named: "0d", range: 0...testCycles-1))
        func test_DEC_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RRCA (0x0F)",  arguments: loadJsonTests(named: "0f", range: 0...testCycles-1))
        func test_RRCA(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate INC D (0x14)",  arguments: loadJsonTests(named: "14", range: 0...testCycles-1))
        func test_INC_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate DEC D (0x15)",  arguments: loadJsonTests(named: "15", range: 0...testCycles-1))
        func test_DEC_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RLA (0x17)",  arguments: loadJsonTests(named: "17", range: 0...testCycles-1))
        func test_RLA(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD HL,DE (0x19)",  arguments: loadJsonTests(named: "19", range: 0...testCycles-1))
        func test_ADD_HL_DE(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate INC E (0x1C)",  arguments: loadJsonTests(named: "1c", range: 0...testCycles-1))
        func test_INC_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate DEC E (0x1D)",  arguments: loadJsonTests(named: "1d", range: 0...testCycles-1))
        func test_DEC_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RRA (0x1F)",  arguments: loadJsonTests(named: "1f", range: 0...testCycles-1))
        func test_RRA(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate INC H (0x24)",  arguments: loadJsonTests(named: "24", range: 0...testCycles-1))
        func test_INC_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate DEC H (0x25)",  arguments: loadJsonTests(named: "25", range: 0...testCycles-1))
        func test_DEC_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate DAA (0x27)",  arguments: loadJsonTests(named: "27", range: 0...testCycles-1))
        func test_DAA(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD HL,HL (0x29)",  arguments: loadJsonTests(named: "29", range: 0...testCycles-1))
        func test_ADD_HL_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate INC L (0x2C)",  arguments: loadJsonTests(named: "2c", range: 0...testCycles-1))
        func test_INC_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate DEC L (0x2D)",  arguments: loadJsonTests(named: "2d", range: 0...testCycles-1))
        func test_DEC_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate CPL (0x2F)",  arguments: loadJsonTests(named: "2f", range: 0...testCycles-1))
        func test_CPL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate INC (HL) (0x34)",  arguments: loadJsonTests(named: "34", range: 0...testCycles-1))
        func test_INC_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate DEC (HL) (0x35)",  arguments: loadJsonTests(named: "35", range: 0...testCycles-1))
        func test_DEC_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SCF (0x37)",  arguments: loadJsonTests(named: "37", range: 0...testCycles-1))
        func test_SCF(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD HL,SP (0x39)",  arguments: loadJsonTests(named: "39", range: 0...testCycles-1))
        func test_ADD_HL_SP(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate INC A (0x3C)",  arguments: loadJsonTests(named: "3c", range: 0...testCycles-1))
        func test_INC_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate DEC A (0x3D)",  arguments: loadJsonTests(named: "3d", range: 0...testCycles-1))
        func test_DEC_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate CCF (0x3F)",  arguments: loadJsonTests(named: "3f", range: 0...testCycles-1))
        func test_CCF(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD A,B (0x80)",  arguments: loadJsonTests(named: "80", range: 0...testCycles-1))
        func test_ADD_A_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD A,C (0x81)",  arguments: loadJsonTests(named: "81", range: 0...testCycles-1))
        func test_ADD_A_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD A,D (0x82)",  arguments: loadJsonTests(named: "82", range: 0...testCycles-1))
        func test_ADD_A_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD A,E (0x83)",  arguments: loadJsonTests(named: "83", range: 0...testCycles-1))
        func test_ADD_A_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD A,H (0x84)",  arguments: loadJsonTests(named: "84", range: 0...testCycles-1))
        func test_ADD_A_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD A,L (0x85)",  arguments: loadJsonTests(named: "85", range: 0...testCycles-1))
        func test_ADD_A_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD A,(HL) (0x86)",  arguments: loadJsonTests(named: "86", range: 0...testCycles-1))
        func test_ADD_A_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD A,A (0x87)",  arguments: loadJsonTests(named: "87", range: 0...testCycles-1))
        func test_ADD_A_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC A,B (0x88)",  arguments: loadJsonTests(named: "88", range: 0...testCycles-1))
        func test_ADC_A_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC A,C (0x89)",  arguments: loadJsonTests(named: "89", range: 0...testCycles-1))
        func test_ADC_A_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC A,D (0x8A)",  arguments: loadJsonTests(named: "8a", range: 0...testCycles-1))
        func test_ADC_A_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC A,E (0x8B)",  arguments: loadJsonTests(named: "8b", range: 0...testCycles-1))
        func test_ADC_A_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC A,H (0x8C)",  arguments: loadJsonTests(named: "8c", range: 0...testCycles-1))
        func test_ADC_A_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC A,L (0x8D)",  arguments: loadJsonTests(named: "8d", range: 0...testCycles-1))
        func test_ADC_A_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC A,(HL) (0x8E)",  arguments: loadJsonTests(named: "8e", range: 0...testCycles-1))
        func test_ADC_A_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC A,A (0x8F)",  arguments: loadJsonTests(named: "8f", range: 0...testCycles-1))
        func test_ADC_AA(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SUB B (0x90)",  arguments: loadJsonTests(named: "90", range: 0...testCycles-1))
        func test_SUB_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SUB C (0x91)",  arguments: loadJsonTests(named: "91", range: 0...testCycles-1))
        func test_SUB_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SUB D (0x92)",  arguments: loadJsonTests(named: "92", range: 0...testCycles-1))
        func test_SUB_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SUB E (0x93)",  arguments: loadJsonTests(named: "93", range: 0...testCycles-1))
        func test_SUB_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SUB H (0x94)",  arguments: loadJsonTests(named: "94", range: 0...testCycles-1))
        func test_SUB_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SUB L (0x95)",  arguments: loadJsonTests(named: "95", range: 0...testCycles-1))
        func test_SUB_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SUB (HL) (0x96)",  arguments: loadJsonTests(named: "96", range: 0...testCycles-1))
        func test_SUB_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SUB A (0x97)",  arguments: loadJsonTests(named: "97", range: 0...testCycles-1))
        func test_SUB_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC A,B (0x98)",  arguments: loadJsonTests(named: "98", range: 0...testCycles-1))
        func test_SBC_A_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC A,C (0x99)",  arguments: loadJsonTests(named: "99", range: 0...testCycles-1))
        func test_SBC_A_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC A,D (0x9A)",  arguments: loadJsonTests(named: "9a", range: 0...testCycles-1))
        func test_SBC_A_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC A,E (0x9B)",  arguments: loadJsonTests(named: "9b", range: 0...testCycles-1))
        func test_SBC_A_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC A,H (0x9C)",  arguments: loadJsonTests(named: "9c", range: 0...testCycles-1))
        func test_SBC_A_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC A,L (0x9D)",  arguments: loadJsonTests(named: "9d", range: 0...testCycles-1))
        func test_SBC_A_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC A,(HL) (0x9E)",  arguments: loadJsonTests(named: "9e", range: 0...testCycles-1))
        func test_SBC_A_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC A,A (0x9F)",  arguments: loadJsonTests(named: "9f", range: 0...testCycles-1))
        func test_SBC_A_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate AND B (0xA0)",  arguments: loadJsonTests(named: "a0", range: 0...testCycles-1))
        func test_AND_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate AND C (0xA1)",  arguments: loadJsonTests(named: "a1", range: 0...testCycles-1))
        func test_AND_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate AND D (0xA2)",  arguments: loadJsonTests(named: "a2", range: 0...testCycles-1))
        func test_AND_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate AND E (0xA3)",  arguments: loadJsonTests(named: "a3", range: 0...testCycles-1))
        func test_AND_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate AND H (0xA4)",  arguments: loadJsonTests(named: "a4", range: 0...testCycles-1))
        func test_AND_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate AND L (0xA5)",  arguments: loadJsonTests(named: "a5", range: 0...testCycles-1))
        func test_AND_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate AND (HL) (0xA6)",  arguments: loadJsonTests(named: "a6", range: 0...testCycles-1))
        func test_AND_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate AND A (0xA7)",  arguments: loadJsonTests(named: "a7", range: 0...testCycles-1))
        func test_AND_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate XOR B (0xA8)",  arguments: loadJsonTests(named: "a8", range: 0...testCycles-1))
        func test_XOR_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate XOR C (0xA9)",  arguments: loadJsonTests(named: "a9", range: 0...testCycles-1))
        func test_XOR_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate XOR D (0xAA)",  arguments: loadJsonTests(named: "aa", range: 0...testCycles-1))
        func test_XOR_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate XOR E (0xAB)",  arguments: loadJsonTests(named: "ab", range: 0...testCycles-1))
        func test_XOR_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate XOR H (0xAC)",  arguments: loadJsonTests(named: "ac", range: 0...testCycles-1))
        func test_XOR_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate XOR L (0xAD)",  arguments: loadJsonTests(named: "ad", range: 0...testCycles-1))
        func test_XOR_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate XOR (HL) (0xAE)",  arguments: loadJsonTests(named: "ae", range: 0...testCycles-1))
        func test_XOR_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate XOR A (0xAF)",  arguments: loadJsonTests(named: "af", range: 0...testCycles-1))
        func test_XOR_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OR B (0xB0)",  arguments: loadJsonTests(named: "b0", range: 0...testCycles-1))
        func test_OR_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OR C (0xB1)",  arguments: loadJsonTests(named: "b1", range: 0...testCycles-1))
        func test_OR_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OR D (0xB2)",  arguments: loadJsonTests(named: "b2", range: 0...testCycles-1))
        func test_OR_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OR E (0xB3)",  arguments: loadJsonTests(named: "b3", range: 0...testCycles-1))
        func test_OR_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OR H (0xB4)",  arguments: loadJsonTests(named: "b4", range: 0...testCycles-1))
        func test_OR_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OR L (0xB5)",  arguments: loadJsonTests(named: "b5", range: 0...testCycles-1))
        func test_OR_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OR (HL) (0xB6)",  arguments: loadJsonTests(named: "b6", range: 0...testCycles-1))
        func test_OR_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OR A (0xB7)",  arguments: loadJsonTests(named: "b7", range: 0...testCycles-1))
        func test_OR_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate CP B (0xB8)",  arguments: loadJsonTests(named: "b8", range: 0...testCycles-1))
        func test_CP_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate CP C (0xB9)",  arguments: loadJsonTests(named: "b9", range: 0...testCycles-1))
        func test_CP_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate CP D (0xBA)",  arguments: loadJsonTests(named: "ba", range: 0...testCycles-1))
        func test_CP_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate CP E (0xBB)",  arguments: loadJsonTests(named: "bb", range: 0...testCycles-1))
        func test_CP_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate CP H (0xBC)",  arguments: loadJsonTests(named: "bc", range: 0...testCycles-1))
        func test_CP_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate CP L (0xBD)",  arguments: loadJsonTests(named: "bd", range: 0...testCycles-1))
        func test_CP_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate CP (HL) (0xBE)",  arguments: loadJsonTests(named: "be", range: 0...testCycles-1))
        func test_CP_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate CP A (0xBF)",  arguments: loadJsonTests(named: "bf", range: 0...testCycles-1))
        func test_CP_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD A,$n (0xC6)",  arguments: loadJsonTests(named: "c6", range: 0...testCycles-1))
        func test_ADD_A_N(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC A,$n (0xCE)",  arguments: loadJsonTests(named: "ce", range: 0...testCycles-1))
        func test_ADC_A_N(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SUB $n (0xD6)",  arguments: loadJsonTests(named: "d6", range: 0...testCycles-1))
        func test_SUB_N(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC A,$n (0xDE)",  arguments: loadJsonTests(named: "de", range: 0...testCycles-1))
        func test_SBC_A_N(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate AND $n (0xE6)",  arguments: loadJsonTests(named: "e6", range: 0...testCycles-1))
        func test_AND_N(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR $n (0xEE)",  arguments: loadJsonTests(named: "ee", range: 0...testCycles-1))
        func test_XOR_N(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OR $n (0xF6)",  arguments: loadJsonTests(named: "f6", range: 0...testCycles-1))
        func test_OR_N(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }





        @Test("Validate CP $n (0xFE)",  arguments: loadJsonTests(named: "fe", range: 0...testCycles-1))
        func test_CP_N(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }
        
        
    }
    
    @Suite("Extended Opcodes CB")
    struct ExtendedOpcodesCB: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate RES 0,B (0xCB80)",  arguments: loadJsonTests(named: "cb 80", range: 0...testCycles-1))
        func test_RES_0_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,C (0xCB81)",  arguments: loadJsonTests(named: "cb 81", range: 0...testCycles-1))
        func test_RES_0_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,D (0xCB82)",  arguments: loadJsonTests(named: "cb 82", range: 0...testCycles-1))
        func test_RES_0_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,E (0xCB83)",  arguments: loadJsonTests(named: "cb 83", range: 0...testCycles-1))
        func test_RES_0_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,H (0xCB84)",  arguments: loadJsonTests(named: "cb 84", range: 0...testCycles-1))
        func test_RES_0_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,L (0xCB85)",  arguments: loadJsonTests(named: "cb 85", range: 0...testCycles-1))
        func test_RES_0_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(HL) (0xCB86)",  arguments: loadJsonTests(named: "cb 86", range: 0...testCycles-1))
        func test_RES_0_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,A (0xCB87)",  arguments: loadJsonTests(named: "cb 87", range: 0...testCycles-1))
        func test_RES_0_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,B (0xCB88)",  arguments: loadJsonTests(named: "cb 88", range: 0...testCycles-1))
        func test_RES_1_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,C (0xCB89)",  arguments: loadJsonTests(named: "cb 89", range: 0...testCycles-1))
        func test_RES_1_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,D (0xCB8A)",  arguments: loadJsonTests(named: "cb 8a", range: 0...testCycles-1))
        func test_RES_1_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,E (0xCB8B)",  arguments: loadJsonTests(named: "cb 8b", range: 0...testCycles-1))
        func test_RES_1_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,H (0xCB8C)",  arguments: loadJsonTests(named: "cb 8c", range: 0...testCycles-1))
        func test_RES_1_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,L (0xCB8D)",  arguments: loadJsonTests(named: "cb 8d", range: 0...testCycles-1))
        func test_RES_1_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(HL) (0xCB8E)",  arguments: loadJsonTests(named: "cb 8e", range: 0...testCycles-1))
        func test_RES_1_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,A (0xCB8F)",  arguments: loadJsonTests(named: "cb 8f", range: 0...testCycles-1))
        func test_RES_1_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,B (0xCB90)",  arguments: loadJsonTests(named: "cb 90", range: 0...testCycles-1))
        func test_RES_2_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,C (0xCB91)",  arguments: loadJsonTests(named: "cb 91", range: 0...testCycles-1))
        func test_RES_2_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,D (0xCB92)",  arguments: loadJsonTests(named: "cb 92", range: 0...testCycles-1))
        func test_RES_2_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,E (0xCB93)",  arguments: loadJsonTests(named: "cb 93", range: 0...testCycles-1))
        func test_RES_2_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,H (0xCB94)",  arguments: loadJsonTests(named: "cb 94", range: 0...testCycles-1))
        func test_RES_2_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,L (0xCB95)",  arguments: loadJsonTests(named: "cb 95", range: 0...testCycles-1))
        func test_RES_2_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(HL) (0xCB96)",  arguments: loadJsonTests(named: "cb 96", range: 0...testCycles-1))
        func test_RES_2_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,A (0xCB97)",  arguments: loadJsonTests(named: "cb 97", range: 0...testCycles-1))
        func test_RES_2_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,B (0xCB98)",  arguments: loadJsonTests(named: "cb 98", range: 0...testCycles-1))
        func test_RES_3_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,C (0xCB99)",  arguments: loadJsonTests(named: "cb 99", range: 0...testCycles-1))
        func test_RES_3_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,D (0xCB9A)",  arguments: loadJsonTests(named: "cb 9a", range: 0...testCycles-1))
        func test_RES_3_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,E (0xCB9B)",  arguments: loadJsonTests(named: "cb 9b", range: 0...testCycles-1))
        func test_RES_3_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,H (0xCB9C)",  arguments: loadJsonTests(named: "cb 9c", range: 0...testCycles-1))
        func test_RES_3_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,L (0xCB9D)",  arguments: loadJsonTests(named: "cb 9d", range: 0...testCycles-1))
        func test_RES_3_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(HL) (0xCB9E)",  arguments: loadJsonTests(named: "cb 9e", range: 0...testCycles-1))
        func test_RES_3_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,A (0xCB9F)",  arguments: loadJsonTests(named: "cb 9f", range: 0...testCycles-1))
        func test_RES_3_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,B (0xCBA0)",  arguments: loadJsonTests(named: "cb a0", range: 0...testCycles-1))
        func test_RES_4_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,C (0xCBA1)",  arguments: loadJsonTests(named: "cb a1", range: 0...testCycles-1))
        func test_RES_4_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,D (0xCBA2)",  arguments: loadJsonTests(named: "cb a2", range: 0...testCycles-1))
        func test_RES_4_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,E (0xCBA3)",  arguments: loadJsonTests(named: "cb a3", range: 0...testCycles-1))
        func test_RES_4_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,H (0xCBA4)",  arguments: loadJsonTests(named: "cb a4", range: 0...testCycles-1))
        func test_RES_4_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,L (0xCBA5)",  arguments: loadJsonTests(named: "cb a5", range: 0...testCycles-1))
        func test_RES_4_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(HL) (0xCBA6)",  arguments: loadJsonTests(named: "cb a6", range: 0...testCycles-1))
        func test_RES_4_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,A (0xCBA7)",  arguments: loadJsonTests(named: "cb a7", range: 0...testCycles-1))
        func test_RES_4_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,B (0xCBA8)",  arguments: loadJsonTests(named: "cb a8", range: 0...testCycles-1))
        func test_RES_5_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,C (0xCBA9)",  arguments: loadJsonTests(named: "cb a9", range: 0...testCycles-1))
        func test_RES_5_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,D (0xCBAA)",  arguments: loadJsonTests(named: "cb aa", range: 0...testCycles-1))
        func test_RES_5_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,E (0xCBAB)",  arguments: loadJsonTests(named: "cb ab", range: 0...testCycles-1))
        func test_RES_5_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,H (0xCBAC)",  arguments: loadJsonTests(named: "cb ac", range: 0...testCycles-1))
        func test_RES_5_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,L (0xCBAD)",  arguments: loadJsonTests(named: "cb ad", range: 0...testCycles-1))
        func test_RES_5_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(HL) (0xCBAE)",  arguments: loadJsonTests(named: "cb ae", range: 0...testCycles-1))
        func test_RES_5_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,A (0xCBAF)",  arguments: loadJsonTests(named: "cb af", range: 0...testCycles-1))
        func test_RES_5_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,B (0xCBB0)",  arguments: loadJsonTests(named: "cb b0", range: 0...testCycles-1))
        func test_RES_6_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,C (0xCBB1)",  arguments: loadJsonTests(named: "cb b1", range: 0...testCycles-1))
        func test_RES_6_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,D (0xCBB2)",  arguments: loadJsonTests(named: "cb b2", range: 0...testCycles-1))
        func test_RES_6_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,E (0xCBB3)",  arguments: loadJsonTests(named: "cb b3", range: 0...testCycles-1))
        func test_RES_6_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,H (0xCBB4)",  arguments: loadJsonTests(named: "cb b4", range: 0...testCycles-1))
        func test_RES_6_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,L (0xCBB5)",  arguments: loadJsonTests(named: "cb b5", range: 0...testCycles-1))
        func test_RES_6_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(HL) (0xCBB6)",  arguments: loadJsonTests(named: "cb b6", range: 0...testCycles-1))
        func test_RES_6_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,A (0xCBB7)",  arguments: loadJsonTests(named: "cb b7", range: 0...testCycles-1))
        func test_RES_6_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,B (0xCBB8)",  arguments: loadJsonTests(named: "cb b8", range: 0...testCycles-1))
        func test_RES_7_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,C (0xCBB9)",  arguments: loadJsonTests(named: "cb b9", range: 0...testCycles-1))
        func test_RES_7_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,D (0xCBBA)",  arguments: loadJsonTests(named: "cb ba", range: 0...testCycles-1))
        func test_RES_7_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,E (0xCBBB)",  arguments: loadJsonTests(named: "cb bb", range: 0...testCycles-1))
        func test_RES_7_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,H (0xCBBC)",  arguments: loadJsonTests(named: "cb bc", range: 0...testCycles-1))
        func test_RES_7_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,L (0xCBBD)",  arguments: loadJsonTests(named: "cb bd", range: 0...testCycles-1))
        func test_RES_7_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(HL) (0xCBBE)",  arguments: loadJsonTests(named: "cb be", range: 0...testCycles-1))
        func test_RES_7_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,A (0xCBBF)",  arguments: loadJsonTests(named: "cb bf", range: 0...testCycles-1))
        func test_RES_7_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,B (0xCBC0)",  arguments: loadJsonTests(named: "cb c0", range: 0...testCycles-1))
        func test_SET_0_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,C (0xCBC1)",  arguments: loadJsonTests(named: "cb c1", range: 0...testCycles-1))
        func test_SET_0_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,D (0xCBC2)",  arguments: loadJsonTests(named: "cb c2", range: 0...testCycles-1))
        func test_SET_0_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,E (0xCBC3)",  arguments: loadJsonTests(named: "cb c3", range: 0...testCycles-1))
        func test_SET_0_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,H (0xCBC4)",  arguments: loadJsonTests(named: "cb c4", range: 0...testCycles-1))
        func test_SET_0_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        @Test("Validate SET 0,L (0xCBC5)",  arguments: loadJsonTests(named: "cb c5", range: 0...testCycles-1))
        func test_SET_0_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(HL) (0xCBC6)",  arguments: loadJsonTests(named: "cb c6", range: 0...testCycles-1))
        func test_SET_0_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,A (0xCBC7)",  arguments: loadJsonTests(named: "cb c7", range: 0...testCycles-1))
        func test_SET_0_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,B (0xCBC8)",  arguments: loadJsonTests(named: "cb c8", range: 0...testCycles-1))
        func test_SET_1_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,C (0xCBC9)",  arguments: loadJsonTests(named: "cb c9", range: 0...testCycles-1))
        func test_SET_1_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,D (0xCBCA)",  arguments: loadJsonTests(named: "cb ca", range: 0...testCycles-1))
        func test_SET_1_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,E (0xCBCB)",  arguments: loadJsonTests(named: "cb cb", range: 0...testCycles-1))
        func test_SET_1_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,H (0xCBCC)",  arguments: loadJsonTests(named: "cb cc", range: 0...testCycles-1))
        func test_SET_1_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,L (0xCBCD)",  arguments: loadJsonTests(named: "cb cd", range: 0...testCycles-1))
        func test_SET_1_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(HL) (0xCBCE)",  arguments: loadJsonTests(named: "cb ce", range: 0...testCycles-1))
        func test_SET_1_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,A (0xCBCF)",  arguments: loadJsonTests(named: "cb cf", range: 0...testCycles-1))
        func test_SET_1_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,B (0xCBD0)",  arguments: loadJsonTests(named: "cb d0", range: 0...testCycles-1))
        func test_SET_2_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,C (0xCBD1)",  arguments: loadJsonTests(named: "cb d1", range: 0...testCycles-1))
        func test_SET_2_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,D (0xCBD2)",  arguments: loadJsonTests(named: "cb d2", range: 0...testCycles-1))
        func test_SET_2_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,E (0xCBD3)",  arguments: loadJsonTests(named: "cb d3", range: 0...testCycles-1))
        func test_SET_2_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,H (0xCBD4)",  arguments: loadJsonTests(named: "cb d4", range: 0...testCycles-1))
        func test_SET_2_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,L (0xCBD5)",  arguments: loadJsonTests(named: "cb d5", range: 0...testCycles-1))
        func test_SET_2_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(HL) (0xCBD6)",  arguments: loadJsonTests(named: "cb d6", range: 0...testCycles-1))
        func test_SET_2_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,A (0xCBD7)",  arguments: loadJsonTests(named: "cb d7", range: 0...testCycles-1))
        func test_SET_2_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,B (0xCBD8)",  arguments: loadJsonTests(named: "cb d8", range: 0...testCycles-1))
        func test_SET_3_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,C (0xCBD9)",  arguments: loadJsonTests(named: "cb d9", range: 0...testCycles-1))
        func test_SET_3_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,D (0xCBDA)",  arguments: loadJsonTests(named: "cb da", range: 0...testCycles-1))
        func test_SET_3_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,E (0xCBDB)",  arguments: loadJsonTests(named: "cb db", range: 0...testCycles-1))
        func test_SET_3_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,H (0xCBDC)",  arguments: loadJsonTests(named: "cb dc", range: 0...testCycles-1))
        func test_SET_3_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,L (0xCBDD)",  arguments: loadJsonTests(named: "cb dd", range: 0...testCycles-1))
        func test_SET_3_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(HL) (0xCBDE)",  arguments: loadJsonTests(named: "cb de", range: 0...testCycles-1))
        func test_SET_3_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,A (0xCBDF)",  arguments: loadJsonTests(named: "cb df", range: 0...testCycles-1))
        func test_SET_3_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,B (0xCBE0)",  arguments: loadJsonTests(named: "cb e0", range: 0...testCycles-1))
        func test_SET_4_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,C (0xCBE1)",  arguments: loadJsonTests(named: "cb e1", range: 0...testCycles-1))
        func test_SET_4_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,D (0xCBE2)",  arguments: loadJsonTests(named: "cb e2", range: 0...testCycles-1))
        func test_SET_4_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,E (0xCBE3)",  arguments: loadJsonTests(named: "cb e3", range: 0...testCycles-1))
        func test_SET_4_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,H (0xCBE4)",  arguments: loadJsonTests(named: "cb e4", range: 0...testCycles-1))
        func test_SET_4_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,L (0xCBE5)",  arguments: loadJsonTests(named: "cb e5", range: 0...testCycles-1))
        func test_SET_4_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(HL) (0xCBE6)",  arguments: loadJsonTests(named: "cb e6", range: 0...testCycles-1))
        func test_SET_4_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,A (0xCBE7)",  arguments: loadJsonTests(named: "cb e7", range: 0...testCycles-1))
        func test_SET_4_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,B (0xCBE8)",  arguments: loadJsonTests(named: "cb e8", range: 0...testCycles-1))
        func test_SET_5_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,C (0xCBE9)",  arguments: loadJsonTests(named: "cb e9", range: 0...testCycles-1))
        func test_SET_5_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,D (0xCBEA)",  arguments: loadJsonTests(named: "cb ea", range: 0...testCycles-1))
        func test_SET_5_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,E (0xCBEB)",  arguments: loadJsonTests(named: "cb eb", range: 0...testCycles-1))
        func test_SET_5_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,H (0xCBEC)",  arguments: loadJsonTests(named: "cb ec", range: 0...testCycles-1))
        func test_SET_5_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,L (0xCBED)",  arguments: loadJsonTests(named: "cb ed", range: 0...testCycles-1))
        func test_SET_5_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(HL) (0xCBEE)",  arguments: loadJsonTests(named: "cb ee", range: 0...testCycles-1))
        func test_SET_5_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,A (0xCBEF)",  arguments: loadJsonTests(named: "cb ef", range: 0...testCycles-1))
        func test_SET_5_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,B (0xCBF0)",  arguments: loadJsonTests(named: "cb f0", range: 0...testCycles-1))
        func test_SET_6_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,C (0xCBF1)",  arguments: loadJsonTests(named: "cb f1", range: 0...testCycles-1))
        func test_SET_6_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,D (0xCBF2)",  arguments: loadJsonTests(named: "cb f2", range: 0...testCycles-1))
        func test_SET_6_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,E (0xCBF3)",  arguments: loadJsonTests(named: "cb f3", range: 0...testCycles-1))
        func test_SET_6_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,H (0xCBF4)",  arguments: loadJsonTests(named: "cb f4", range: 0...testCycles-1))
        func test_SET_6_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,L (0xCBF5)",  arguments: loadJsonTests(named: "cb f5", range: 0...testCycles-1))
        func test_SET_6_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(HL) (0xCBF6)",  arguments: loadJsonTests(named: "cb f6", range: 0...testCycles-1))
        func test_SET_6_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,A (0xCBF7)",  arguments: loadJsonTests(named: "cb f7", range: 0...testCycles-1))
        func test_SET_6_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,B (0xCBF8)",  arguments: loadJsonTests(named: "cb f8", range: 0...testCycles-1))
        func test_SET_7_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,C (0xCBF9)",  arguments: loadJsonTests(named: "cb f9", range: 0...testCycles-1))
        func test_SET_7_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,D (0xCBFA)",  arguments: loadJsonTests(named: "cb fa", range: 0...testCycles-1))
        func test_SET_7_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,E (0xCBFB)",  arguments: loadJsonTests(named: "cb fb", range: 0...testCycles-1))
        func test_SET_7_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,H (0xCBFC)",  arguments: loadJsonTests(named: "cb fc", range: 0...testCycles-1))
        func test_SET_7_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,L (0xCBFD)",  arguments: loadJsonTests(named: "cb fd", range: 0...testCycles-1))
        func test_SET_7_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(HL) (0xCBFE)",  arguments: loadJsonTests(named: "cb fe", range: 0...testCycles-1))
        func test_SET_7_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,A (0xCBFF)",  arguments: loadJsonTests(named: "cb ff", range: 0...testCycles-1))
        func test_SET_7_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes Flags CB")
    struct ExtendedOpcodesFlagsCB: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate RLC B (0xCB00)",  arguments: loadJsonTests(named: "cb 00", range: 0...testCycles-1))
        func test_RLC_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RLC C (0xCB01)",  arguments: loadJsonTests(named: "cb 01", range: 0...testCycles-1))
        func test_RLC_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RLC D (0xCB02)",  arguments: loadJsonTests(named: "cb 02", range: 0...testCycles-1))
        func test_RLC_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RLC E (0xCB03)",  arguments: loadJsonTests(named: "cb 03", range: 0...testCycles-1))
        func test_RLC_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RLC H (0xCB04)",  arguments: loadJsonTests(named: "cb 04", range: 0...testCycles-1))
        func test_RLC_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RLC L (0xCB05)",  arguments: loadJsonTests(named: "cb 05", range: 0...testCycles-1))
        func test_RLC_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RLC (HL) (0xCB06)",  arguments: loadJsonTests(named: "cb 06", range: 0...testCycles-1))
        func test_RLC_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RLC A (0xCB07)",  arguments: loadJsonTests(named: "cb 07", range: 0...testCycles-1))
        func test_RLC_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RRC B (0xCB08)",  arguments: loadJsonTests(named: "cb 08", range: 0...testCycles-1))
        func test_RRC_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RRC C (0xCB09)",  arguments: loadJsonTests(named: "cb 09", range: 0...testCycles-1))
        func test_RRC_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RRC D (0xCB0A)",  arguments: loadJsonTests(named: "cb 0a", range: 0...testCycles-1))
        func test_RRC_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RRC E (0xCB0B)",  arguments: loadJsonTests(named: "cb 0b", range: 0...testCycles-1))
        func test_RRC_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RRC H (0xCB0C)",  arguments: loadJsonTests(named: "cb 0c", range: 0...testCycles-1))
        func test_RRC_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RRC L (0xCB0D)",  arguments: loadJsonTests(named: "cb 0d", range: 0...testCycles-1))
        func test_RRC_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RRC (HL) (0xCB0E)",  arguments: loadJsonTests(named: "cb 0e", range: 0...testCycles-1))
        func test_RRC_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RRC A (0xCB0F)",  arguments: loadJsonTests(named: "cb 0f", range: 0...testCycles-1))
        func test_RRC_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RL B (0xCB10)",  arguments: loadJsonTests(named: "cb 10", range: 0...testCycles-1))
        func test_RL_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RL C (0xCB11)",  arguments: loadJsonTests(named: "cb 11", range: 0...testCycles-1))
        func test_RL_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RL D (0xCB12)",  arguments: loadJsonTests(named: "cb 12", range: 0...testCycles-1))
        func test_RL_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RL E (0xCB13)",  arguments: loadJsonTests(named: "cb 13", range: 0...testCycles-1))
        func test_RL_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RL H (0xCB14)",  arguments: loadJsonTests(named: "cb 14", range: 0...testCycles-1))
        func test_RL_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RL L (0xCB15)",  arguments: loadJsonTests(named: "cb 15", range: 0...testCycles-1))
        func test_RL_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RL (HL) (0xCB16)",  arguments: loadJsonTests(named: "cb 16", range: 0...testCycles-1))
        func test_RL_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RL A (0xCB17)",  arguments: loadJsonTests(named: "cb 17", range: 0...testCycles-1))
        func test_RL_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RR B (0xCB18)",  arguments: loadJsonTests(named: "cb 18", range: 0...testCycles-1))
        func test_RR_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RR C (0xCB19)",  arguments: loadJsonTests(named: "cb 19", range: 0...testCycles-1))
        func test_RR_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RR D (0xCB1A)",  arguments: loadJsonTests(named: "cb 1a", range: 0...testCycles-1))
        func test_RR_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RR E (0xCB1B)",  arguments: loadJsonTests(named: "cb 1b", range: 0...testCycles-1))
        func test_RR_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RR H (0xCB1C)",  arguments: loadJsonTests(named: "cb 1c", range: 0...testCycles-1))
        func test_RR_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RR L (0xCB1D)",  arguments: loadJsonTests(named: "cb 1d", range: 0...testCycles-1))
        func test_RR_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RR (HL) (0xCB1E)",  arguments: loadJsonTests(named: "cb 1e", range: 0...testCycles-1))
        func test_RR_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RR A (0xCB1F)",  arguments: loadJsonTests(named: "cb 1f", range: 0...testCycles-1))
        func test_RR_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SLA B (0xCB20)",  arguments: loadJsonTests(named: "cb 20", range: 0...testCycles-1))
        func test_SLA_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SLA C (0xCB21)",  arguments: loadJsonTests(named: "cb 21", range: 0...testCycles-1))
        func test_SLA_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SLA D (0xCB22)",  arguments: loadJsonTests(named: "cb 22", range: 0...testCycles-1))
        func test_SLA_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SLA E (0xCB23)",  arguments: loadJsonTests(named: "cb 23", range: 0...testCycles-1))
        func test_SLA_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SLA H (0xCB24)",  arguments: loadJsonTests(named: "cb 24", range: 0...testCycles-1))
        func test_SLA_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SLA L (0xCB25)",  arguments: loadJsonTests(named: "cb 25", range: 0...testCycles-1))
        func test_SLA_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SLA (HL) (0xCB26)",  arguments: loadJsonTests(named: "cb 26", range: 0...testCycles-1))
        func test_SLA_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SLA A (0xCB27)",  arguments: loadJsonTests(named: "cb 27", range: 0...testCycles-1))
        func test_SLA_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRA B (0xCB28)",  arguments: loadJsonTests(named: "cb 28", range: 0...testCycles-1))
        func test_SRA_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRA C (0xCB29)",  arguments: loadJsonTests(named: "cb 29", range: 0...testCycles-1))
        func test_SRA_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRA D (0xCB2A)",  arguments: loadJsonTests(named: "cb 2a", range: 0...testCycles-1))
        func test_SRA_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRA E (0xCB2B)",  arguments: loadJsonTests(named: "cb 2b", range: 0...testCycles-1))
        func test_SRA_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRA H (0xCB2C)",  arguments: loadJsonTests(named: "cb 2c", range: 0...testCycles-1))
        func test_SRA_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRA L (0xCB2D)",  arguments: loadJsonTests(named: "cb 2d", range: 0...testCycles-1))
        func test_SRA_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRA (HL) (0xCB2E)",  arguments: loadJsonTests(named: "cb 2e", range: 0...testCycles-1))
        func test_SRA_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRA A (0xCB2F)",  arguments: loadJsonTests(named: "cb 2f", range: 0...testCycles-1))
        func test_SRA_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRL B (0xCB38)",  arguments: loadJsonTests(named: "cb 38", range: 0...testCycles-1))
        func test_SRL_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRL C (0xCB39)",  arguments: loadJsonTests(named: "cb 39", range: 0...testCycles-1))
        func test_SRL_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRL D (0xCB3A)",  arguments: loadJsonTests(named: "cb 3a", range: 0...testCycles-1))
        func test_SRL_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRL E (0xCB3B)",  arguments: loadJsonTests(named: "cb 3b", range: 0...testCycles-1))
        func test_SRL_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRL H (0xCB3C)",  arguments: loadJsonTests(named: "cb 3c", range: 0...testCycles-1))
        func test_SRL_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRL L (0xCB3D)",  arguments: loadJsonTests(named: "cb 3d", range: 0...testCycles-1))
        func test_SRL_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRL (HL) (0xCB3E)",  arguments: loadJsonTests(named: "cb 3e", range: 0...testCycles-1))
        func test_SRL_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRL A (0xCB3F)",  arguments: loadJsonTests(named: "cb 3f", range: 0...testCycles-1))
        func test_SRL_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 0,B (0xCB40)",  arguments: loadJsonTests(named: "cb 40", range: 0...testCycles-1))
        func test_BIT_0_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 0,C (0xCB41)",  arguments: loadJsonTests(named: "cb 41", range: 0...testCycles-1))
        func test_BIT_0_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 0,D (0xCB42)",  arguments: loadJsonTests(named: "cb 42", range: 0...testCycles-1))
        func test_BIT_0_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 0,E (0xCB43)",  arguments: loadJsonTests(named: "cb 43", range: 0...testCycles-1))
        func test_BIT_0_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 0,H (0xCB44)",  arguments: loadJsonTests(named: "cb 44", range: 0...testCycles-1))
        func test_BIT_0_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 0,L (0xCB45)",  arguments: loadJsonTests(named: "cb 45", range: 0...testCycles-1))
        func test_BIT_0_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 0,(HL) (0xCB46)",  arguments: loadJsonTests(named: "cb 46", range: 0...testCycles-1))
        func test_BIT_0_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 0,A (0xCB47)",  arguments: loadJsonTests(named: "cb 47", range: 0...testCycles-1))
        func test_BIT_0_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 1,B (0xCB48)",  arguments: loadJsonTests(named: "cb 48", range: 0...testCycles-1))
        func test_BIT_1_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 1,C (0xCB49)",  arguments: loadJsonTests(named: "cb 49", range: 0...testCycles-1))
        func test_BIT_1_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 1,D (0xCB4A)",  arguments: loadJsonTests(named: "cb 4a", range: 0...testCycles-1))
        func test_BIT_1_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 1,E (0xCB4B)",  arguments: loadJsonTests(named: "cb 4b", range: 0...testCycles-1))
        func test_BIT_1_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 1,H (0xCB4C)",  arguments: loadJsonTests(named: "cb 4c", range: 0...testCycles-1))
        func test_BIT_1_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 1,L (0xCB4D)",  arguments: loadJsonTests(named: "cb 4d", range: 0...testCycles-1))
        func test_BIT_1_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 1,(HL) (0xCB4E)",  arguments: loadJsonTests(named: "cb 4e", range: 0...testCycles-1))
        func test_BIT_1_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 1,A (0xCB4F)",  arguments: loadJsonTests(named: "cb 4f", range: 0...testCycles-1))
        func test_BIT_1_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 2,B (0xCB50)",  arguments: loadJsonTests(named: "cb 50", range: 0...testCycles-1))
        func test_BIT_2_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 2,C (0xCB51)",  arguments: loadJsonTests(named: "cb 51", range: 0...testCycles-1))
        func test_BIT_2_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 2,D (0xCB52)",  arguments: loadJsonTests(named: "cb 52", range: 0...testCycles-1))
        func test_BIT_2_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 2,E (0xCB53)",  arguments: loadJsonTests(named: "cb 53", range: 0...testCycles-1))
        func test_BIT_2_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 2,H (0xCB54)",  arguments: loadJsonTests(named: "cb 54", range: 0...testCycles-1))
        func test_BIT_2_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 2,L (0xCB55)",  arguments: loadJsonTests(named: "cb 55", range: 0...testCycles-1))
        func test_BIT_2_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 2,(HL) (0xCB56)",  arguments: loadJsonTests(named: "cb 56", range: 0...testCycles-1))
        func test_BIT_2_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 2,A (0xCB57)",  arguments: loadJsonTests(named: "cb 57", range: 0...testCycles-1))
        func test_BIT_2_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 3,B (0xCB58)",  arguments: loadJsonTests(named: "cb 58", range: 0...testCycles-1))
        func test_BIT_3_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 3,C (0xCB59)",  arguments: loadJsonTests(named: "cb 59", range: 0...testCycles-1))
        func test_BIT_3_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 3,D (0xCB5A)",  arguments: loadJsonTests(named: "cb 5a", range: 0...testCycles-1))
        func test_BIT_3_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 3,E (0xCB5B)",  arguments: loadJsonTests(named: "cb 5b", range: 0...testCycles-1))
        func test_BIT_3_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 3,H (0xCB5C)",  arguments: loadJsonTests(named: "cb 5c", range: 0...testCycles-1))
        func test_BIT_3_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 3,L (0xCB5D)",  arguments: loadJsonTests(named: "cb 5d", range: 0...testCycles-1))
        func test_BIT_3_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 3,(HL) (0xCB5E)",  arguments: loadJsonTests(named: "cb 5e", range: 0...testCycles-1))
        func test_BIT_3_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 3,A (0xCB5F)",  arguments: loadJsonTests(named: "cb 5f", range: 0...testCycles-1))
        func test_BIT_3_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 4,B (0xCB60)",  arguments: loadJsonTests(named: "cb 60", range: 0...testCycles-1))
        func test_BIT_4_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 4,C (0xCB61)",  arguments: loadJsonTests(named: "cb 61", range: 0...testCycles-1))
        func test_BIT_4_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 4,D (0xCB62)",  arguments: loadJsonTests(named: "cb 62", range: 0...testCycles-1))
        func test_BIT_4_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 4,E (0xCB63)",  arguments: loadJsonTests(named: "cb 63", range: 0...testCycles-1))
        func test_BIT_4_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 4,H (0xCB64)",  arguments: loadJsonTests(named: "cb 64", range: 0...testCycles-1))
        func test_BIT_4_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 4,L (0xCB65)",  arguments: loadJsonTests(named: "cb 65", range: 0...testCycles-1))
        func test_BIT_4_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 4,(HL) (0xCB66)",  arguments: loadJsonTests(named: "cb 66", range: 0...testCycles-1))
        func test_BIT_4_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 4,A (0xCB67)",  arguments: loadJsonTests(named: "cb 67", range: 0...testCycles-1))
        func test_BIT_4_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 5,B (0xCB68)",  arguments: loadJsonTests(named: "cb 68", range: 0...testCycles-1))
        func test_BIT_5_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 5,C (0xCB69)",  arguments: loadJsonTests(named: "cb 69", range: 0...testCycles-1))
        func test_BIT_5_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 5,D (0xCB6A)",  arguments: loadJsonTests(named: "cb 6a", range: 0...testCycles-1))
        func test_BIT_5_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 5,E (0xCB6B)",  arguments: loadJsonTests(named: "cb 6b", range: 0...testCycles-1))
        func test_BIT_5_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 5,H (0xCB6C)",  arguments: loadJsonTests(named: "cb 6c", range: 0...testCycles-1))
        func test_BIT_5_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 5,L (0xCB6D)",  arguments: loadJsonTests(named: "cb 6d", range: 0...testCycles-1))
        func test_BIT_5_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 5,(HL) (0xCB6E)",  arguments: loadJsonTests(named: "cb 6e", range: 0...testCycles-1))
        func test_BIT_5_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 5,A (0xCB6F)",  arguments: loadJsonTests(named: "cb 6f", range: 0...testCycles-1))
        func test_BIT_5_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 6,B (0xCB70)",  arguments: loadJsonTests(named: "cb 70", range: 0...testCycles-1))
        func test_BIT_6_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 6,C (0xCB71)",  arguments: loadJsonTests(named: "cb 71", range: 0...testCycles-1))
        func test_BIT_6_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 6,D (0xCB72)",  arguments: loadJsonTests(named: "cb 72", range: 0...testCycles-1))
        func test_BIT_6_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 6,E (0xCB73)",  arguments: loadJsonTests(named: "cb 73", range: 0...testCycles-1))
        func test_BIT_6_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 6,H (0xCB74)",  arguments: loadJsonTests(named: "cb 74", range: 0...testCycles-1))
        func test_BIT_6_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 6,L (0xCB75)",  arguments: loadJsonTests(named: "cb 75", range: 0...testCycles-1))
        func test_BIT_6_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 6,(HL) (0xCB76)",  arguments: loadJsonTests(named: "cb 76", range: 0...testCycles-1))
        func test_BIT_6_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 6,A (0xCB77)",  arguments: loadJsonTests(named: "cb 77", range: 0...testCycles-1))
        func test_BIT_6_A(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 7,B (0xCB78)",  arguments: loadJsonTests(named: "cb 78", range: 0...testCycles-1))
        func test_BIT_7_B(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 7,C (0xCB79)",  arguments: loadJsonTests(named: "cb 79", range: 0...testCycles-1))
        func test_BIT_7_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 7,D (0xCB7A)",  arguments: loadJsonTests(named: "cb 7a", range: 0...testCycles-1))
        func test_BIT_7_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 7,E (0xCB7B)",  arguments: loadJsonTests(named: "cb 7b", range: 0...testCycles-1))
        func test_BIT_7_E(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 7,H (0xCB7C)",  arguments: loadJsonTests(named: "cb 7c", range: 0...testCycles-1))
        func test_BIT_7_H(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 7,L (0xCB7D)",  arguments: loadJsonTests(named: "cb 7d", range: 0...testCycles-1))
        func test_BIT_7_L(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 7,(HL) (0xCB7E)",  arguments: loadJsonTests(named: "cb 7e", range: 0...testCycles-1))
        func test_BIT_7_CON_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 7,A (0xCB7F)",  arguments: loadJsonTests(named: "cb 7f", range: 0...testCycles-1))
        func test_BIT_7_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes DD")
    struct ExtendedOpcodesDD: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate LD IX,$nn (0xDD21)",  arguments: loadJsonTests(named: "dd 21", range: 0...testCycles-1))
        func test_LD_IX_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),IX (0xDD22)",  arguments: loadJsonTests(named: "dd 22", range: 0...testCycles-1))
        func test_LD_CON_NN_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC IX (0xDD23)",  arguments: loadJsonTests(named: "dd 23", range: 0...testCycles-1))
        func test_INC_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IX,($nn) (0xDD2A)",  arguments: loadJsonTests(named: "dd 2a", range: 0...testCycles-1))
        func test_LD_IX_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC IX (0xDD2B)",  arguments: loadJsonTests(named: "dd 2b", range: 0...testCycles-1))
        func test_DEC_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),$n (0xDD36)",  arguments: loadJsonTests(named: "dd 36", range: 0...testCycles-1))
        func test_LD_CON_IX_D_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,(IX+$d) (0xDD46)",  arguments: loadJsonTests(named: "dd 46", range: 0...testCycles-1))
        func test_LD_B_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,(IX+$d) (0xDD4E)",  arguments: loadJsonTests(named: "dd 4e", range: 0...testCycles-1))
        func test_LD_C_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,(IX+$d) (0xDD56)",  arguments: loadJsonTests(named: "dd 56", range: 0...testCycles-1))
        func test_LD_D_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,(IX+$d) (0xDD5E)",  arguments: loadJsonTests(named: "dd 5e", range: 0...testCycles-1))
        func test_LD_E_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,(IX+$d) (0xDD66)",  arguments: loadJsonTests(named: "dd 66", range: 0...testCycles-1))
        func test_LD_H_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,(IX+$d) (0xDD6E)",  arguments: loadJsonTests(named: "dd 6e", range: 0...testCycles-1))
        func test_LD_L_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),B (0xDD70)",  arguments: loadJsonTests(named: "dd 70", range: 0...testCycles-1))
        func test_LD_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),C (0xDD71)",  arguments: loadJsonTests(named: "dd 71", range: 0...testCycles-1))
        func test_LD_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),D (0xDD72)",  arguments: loadJsonTests(named: "dd 72", range: 0...testCycles-1))
        func test_LD_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),E (0xDD73)",  arguments: loadJsonTests(named: "dd 73", range: 0...testCycles-1))
        func test_LD_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),H (0xDD74)",  arguments: loadJsonTests(named: "dd 74", range: 0...testCycles-1))
        func test_LD_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),L (0xDD75)",  arguments: loadJsonTests(named: "dd 75", range: 0...testCycles-1))
        func test_LD_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IX+$d),A (0xDD77)",  arguments: loadJsonTests(named: "dd 77", range: 0...testCycles-1))
        func test_LD_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,(IX+$d) (0xDD7E)",  arguments: loadJsonTests(named: "dd 7e", range: 0...testCycles-1))
        func test_LD_A_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate POP IX (0xDDE1)",  arguments: loadJsonTests(named: "dd e1", range: 0...testCycles-1))
        func test_POP_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EX (SP),IX (0xDDE3)",  arguments: loadJsonTests(named: "dd e3", range: 0...testCycles-1))
        func test_EX_CON_SP_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate PUSH IX (0xDDE5)",  arguments: loadJsonTests(named: "dd e5", range: 0...testCycles-1))
        func test_PUSH_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP (IX) (0xDDE9)",  arguments: loadJsonTests(named: "dd e9", range: 0...testCycles-1))
        func test_JP_CON_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD SP,IX (0xDDF9)",  arguments: loadJsonTests(named: "dd f9", range: 0...testCycles-1))
        func test_LD_SP_IX(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes Flags DD")
    struct ExtendedOpcodesFlagsDD: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate ADD IX,BC (0xDD09)",  arguments: loadJsonTests(named: "dd 09", range: 0...testCycles-1))
        func test_ADD_IX_BC(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD IX,DE (0xDD19)",  arguments: loadJsonTests(named: "dd 19", range: 0...testCycles-1))
        func test_ADD_IX_DE(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD IX,IX (0xDD29)",  arguments: loadJsonTests(named: "dd 29", range: 0...testCycles-1))
        func test_ADD_IX_IX(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate INC (IX+$d) (0xDD34)",  arguments: loadJsonTests(named: "dd 34", range: 0...testCycles-1))
        func test_INC_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate DEC (IX+$d) (0xDD35)",  arguments: loadJsonTests(named: "dd 35", range: 0...testCycles-1))
        func test_DEC_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD IX,SP (0xDD39)",  arguments: loadJsonTests(named: "dd 39", range: 0...testCycles-1))
        func test_ADD_IX_SP(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADD A,(IX+$d) (0xDD86)",  arguments: loadJsonTests(named: "dd 86", range: 0...testCycles-1))
        func test_ADD_A_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC A,(IX+$d) (0xDD8E)",  arguments: loadJsonTests(named: "dd 8e", range: 0...testCycles-1))
        func test_ADC_A_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SUB (IX+$d) (0xDD96)",  arguments: loadJsonTests(named: "dd 96", range: 0...testCycles-1))
        func test_SUB_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC A,(IX+$d) (0xDD9E)",  arguments: loadJsonTests(named: "dd 9e", range: 0...testCycles-1))
        func test_SBC_A_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate AND (IX+$d) (0xDDA6)",  arguments: loadJsonTests(named: "dd a6", range: 0...testCycles-1))
        func test_AND_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate XOR (IX+$d) (0xDDAE)",  arguments: loadJsonTests(named: "dd ae", range: 0...testCycles-1))
        func test_XOR_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OR (IX+$d) (0xDDB6)",  arguments: loadJsonTests(named: "dd b6", range: 0...testCycles-1))
        func test_OR_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate CP (IX+$d) (0xDDBE)",  arguments: loadJsonTests(named: "dd be", range: 0...testCycles-1))
        func test_CP_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes DDCB")
    struct ExtendedOpcodesDDCB: testHelper
    {
        let parent = Z80Opcodes()
        
        //dd cb __ 00
        
        @Test("Validate RES 0,(IX+$d) (0xDDCB__86)",  arguments: loadJsonTests(named: "dd cb __ 86", range: 0...testCycles-1))
        func test_RES_0_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IX+$d) (0xDDCB__8E)",  arguments: loadJsonTests(named: "dd cb __ 8e", range: 0...testCycles-1))
        func test_RES_1_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IX+$d) (0xDDCB__96)",  arguments: loadJsonTests(named: "dd cb __ 96", range: 0...testCycles-1))
        func test_RES_2_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IX+$d) (0xDDCB__9E)",  arguments: loadJsonTests(named: "dd cb __ 9e", range: 0...testCycles-1))
        func test_RES_3_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IX+$d) (0xDDCB__A6)",  arguments: loadJsonTests(named: "dd cb __ a6", range: 0...testCycles-1))
        func test_RES_4_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IX+$d) (0xDDCB__AE)",  arguments: loadJsonTests(named: "dd cb __ ae", range: 0...testCycles-1))
        func test_RES_5_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IX+$d) (0xDDCB__B6)",  arguments: loadJsonTests(named: "dd cb __ b6", range: 0...testCycles-1))
        func test_RES_6_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IX+$d) (0xDDCB__BE)",  arguments: loadJsonTests(named: "dd cb __ be", range: 0...testCycles-1))
        func test_RES_7_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IX+$d) (0xDDCB__C6)",  arguments: loadJsonTests(named: "dd cb __ c6", range: 0...testCycles-1))
        func test_SET_0_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IX+$d) (0xDDCB__CE)",  arguments: loadJsonTests(named: "dd cb __ ce", range: 0...testCycles-1))
        func test_SET_1_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IX+$d) (0xDDCB__D6)",  arguments: loadJsonTests(named: "dd cb __ d6", range: 0...testCycles-1))
        func test_SET_2_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IX+$d) (0xDDCB__DE)",  arguments: loadJsonTests(named: "dd cb __ de", range: 0...testCycles-1))
        func test_SET_3_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IX+$d) (0xDDCB__E6)",  arguments: loadJsonTests(named: "dd cb __ e6", range: 0...testCycles-1))
        func test_SET_4_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IX+$d) (0xDDCB__EE)",  arguments: loadJsonTests(named: "dd cb __ ee", range: 0...testCycles-1))
        func test_SET_5_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IX+$d) (0xDDCB__F6)",  arguments: loadJsonTests(named: "dd cb __ f6", range: 0...testCycles-1))
        func test_SET_6_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IX+$d) (0xDDCB__FE)",  arguments: loadJsonTests(named: "dd cb __ fe", range: 0...testCycles-1))
        func test_SET_7_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes Flags DDCB")
    struct ExtendedOpcodesFlagsDDCB: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate RLC (IX+$d) (0xDDCB__06)",  arguments: loadJsonTests(named: "dd cb __ 06", range: 0...testCycles-1))
        func test_RLC_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RRC (IX+$d) (0xDDCB__0E)",  arguments: loadJsonTests(named: "dd cb __ 0e", range: 0...testCycles-1))
        func test_RRC_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RL (IX+$d) (0xDDCB__16)",  arguments: loadJsonTests(named: "dd cb __ 16", range: 0...testCycles-1))
        func test_RL_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RR (IX+$d) (0xDDCB__1E)",  arguments: loadJsonTests(named: "dd cb __ 1e", range: 0...testCycles-1))
        func test_RR_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SLA (IX+$d) (0xDDCB__26)",  arguments: loadJsonTests(named: "dd cb __ 26", range: 0...testCycles-1))
        func test_SLA_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRA (IX+$d) (0xDDCB__2E)",  arguments: loadJsonTests(named: "dd cb __ 2e", range: 0...testCycles-1))
        func test_SRA_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRL (IX+$d) (0xDDCB__3E)",  arguments: loadJsonTests(named: "dd cb __ 3e", range: 0...testCycles-1))
        func test_SRL_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 0,(IX+$d) (0xDDCB__46)",  arguments: loadJsonTests(named: "dd cb __ 46", range: 0...testCycles-1))
        func test_BIT_0_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 1,(IX+$d) (0xDDCB__4E)",  arguments: loadJsonTests(named: "dd cb __ 4e", range: 0...testCycles-1))
        func test_BIT_1_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 2,(IX+$d) (0xDDCB__56)",  arguments: loadJsonTests(named: "dd cb __ 56", range: 0...testCycles-1))
        func test_BIT_2_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 3,(IX+$d) (0xDDCB__5E)",  arguments: loadJsonTests(named: "dd cb __ 5e", range: 0...testCycles-1))
        func test_BIT_3_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 4,(IX+$d) (0xDDCB__66)",  arguments: loadJsonTests(named: "dd cb __ 66", range: 0...testCycles-1))
        func test_BIT_4_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 5,(IX+$d) (0xDDCB__6E)",  arguments: loadJsonTests(named: "dd cb __ 6e", range: 0...testCycles-1))
        func test_BIT_5_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 6,(IX+$d) (0xDDCB__76)",  arguments: loadJsonTests(named: "dd cb __ 76", range: 0...testCycles-1))
        func test_BIT_6_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 7,(IX+$d) (0xDDCB__7E)",  arguments: loadJsonTests(named: "dd cb __ 7e", range: 0...testCycles-1))
        func test_BIT_7_CON_IX_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes ED")
    struct ExtendedOpcodesED: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate OUT (C),B (0xED41)",  arguments: loadJsonTests(named: "ed 41", range: 0...testCycles-1))
        func test_OUT_C_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),BC (0xED43)",  arguments: loadJsonTests(named: "ed 43", range: 0...testCycles-1))
        func test_LD_CON_NN_BC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RETN (0xED45)",  arguments: loadJsonTests(named: "ed 45", range: 0...testCycles-1))
        func test_RETN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate IM 0 (0xED46)",  arguments: loadJsonTests(named: "ed 46", range: 0...testCycles-1))
        func test_IM_0(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD I,A (0xED47)",  arguments: loadJsonTests(named: "ed 47", range: 0...testCycles-1))
        func test_LD_I_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT (C),C (0xED49)",  arguments: loadJsonTests(named: "ed 49", range: 0...testCycles-1))
        func test_OUT_C_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD BC,($nn) (0xED4B)",  arguments: loadJsonTests(named: "ed 4b", range: 0...testCycles-1))
        func test_LD_BC_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RETI (0xED4D)",  arguments: loadJsonTests(named: "ed 4d", range: 0...testCycles-1))
        func test_RETI(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD R,A (0xED4F)",  arguments: loadJsonTests(named: "ed 4f", range: 0...testCycles-1))
        func test_LD_R_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT (C),D (0xED51)",  arguments: loadJsonTests(named: "ed 51", range: 0...testCycles-1))
        func test_OUT_C_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),DE (0xED53)",  arguments: loadJsonTests(named: "ed 53", range: 0...testCycles-1))
        func test_LD_CON_NN_DE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate IM 1 (0xED56)",  arguments: loadJsonTests(named: "ed 56", range: 0...testCycles-1))
        func test_IM_1(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT (C),E (0xED59)",  arguments: loadJsonTests(named: "ed 59", range: 0...testCycles-1))
        func test_OUT_C_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD DE,($nn) (0xED5B)",  arguments: loadJsonTests(named: "ed 5b", range: 0...testCycles-1))
        func test_LD_DE_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate IM 2 (0xED5E)",  arguments: loadJsonTests(named: "ed 5e", range: 0...testCycles-1))
        func test_IM_2(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT (C),H (0xED61)",  arguments: loadJsonTests(named: "ed 61", range: 0...testCycles-1))
        func test_OUT_C_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT (C),L (0xED69)",  arguments: loadJsonTests(named: "ed 69", range: 0...testCycles-1))
        func test_OUT_C_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),SP (0xED73)",  arguments: loadJsonTests(named: "ed 73", range: 0...testCycles-1))
        func test_LD_CON_NN_SP(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT (C),A (0xED79)",  arguments: loadJsonTests(named: "ed 79", range: 0...testCycles-1))
        func test_OUT_C_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD SP,($nn) (0xED7B)",  arguments: loadJsonTests(named: "ed 7b", range: 0...testCycles-1))
        func test_LD_SP_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes Flags ED")
    struct ExtendedOpcodesFlagsED: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate IN B,(C) (0xED40)",  arguments: loadJsonTests(named: "ed 40", range: 0...testCycles-1))
        func test_IN_B_CON_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC HL,BC (0xED42)",  arguments: loadJsonTests(named: "ed 42", range: 0...testCycles-1))
        func test_SBC_HL_BC(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate NEG (0xED44)",  arguments: loadJsonTests(named: "ed 44", range: 0...testCycles-1))
        func test_NEG(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate IN C,(C) (0xED48)",  arguments: loadJsonTests(named: "ed 48", range: 0...testCycles-1))
        func test_IN_C_CON_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC HL,BC (0xED4A)",  arguments: loadJsonTests(named: "ed 4a", range: 0...testCycles-1))
        func test_ADC_HL_BC(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate IN D,(C) (0xED50)",  arguments: loadJsonTests(named: "ed 50", range: 0...testCycles-1))
        func test_IN_D_CON_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC HL,DE (0xED52)",  arguments: loadJsonTests(named: "ed 52", range: 0...testCycles-1))
        func test_SBC_HL_DE(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate LD A,I (0xED57)",  arguments: loadJsonTests(named: "ed 57", range: 0...testCycles-1))
        func test_LD_A_I(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate IN E,(C) (0xED58)",  arguments: loadJsonTests(named: "ed 58", range: 0...testCycles-1))
        func test_IN_E_CON_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC HL,DE (0xED5A)",  arguments: loadJsonTests(named: "ed 5a", range: 0...testCycles-1))
        func test_ADC_HL_DE(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate LD A,R (0xED5F)",  arguments: loadJsonTests(named: "ed 5f", range: 0...testCycles-1))
        func test_LD_A_R(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate IN H,(C) (0xED60)",  arguments: loadJsonTests(named: "ed 60", range: 0...testCycles-1))
        func test_IN_H_CON_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC HL,HL (0xED62)",  arguments: loadJsonTests(named: "ed 62", range: 0...testCycles-1))
        func test_SBC_HL_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RRD (0xED67)",  arguments: loadJsonTests(named: "ed 67", range: 0...testCycles-1))
        func test_RRD(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate IN L,(C) (0xED68)",  arguments: loadJsonTests(named: "ed 68", range: 0...testCycles-1))
        func test_IN_L_CON_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC HL,HL (0xED6A)",  arguments: loadJsonTests(named: "ed 6a", range: 0...testCycles-1))
        func test_ADC_HL_HL(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RLD (0xED6F)",  arguments: loadJsonTests(named: "ed 6f", range: 0...testCycles-1))
        func test_RLD(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SBC HL,SP (0xED72)",  arguments: loadJsonTests(named: "ed 72", range: 0...testCycles-1))
        func test_SBC_HL_SP(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate IN A,(C) (0xED78)",  arguments: loadJsonTests(named: "ed 78", range: 0...testCycles-1))
        func test_IN_A_CON_C(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate ADC HL,SP (0xED7A)",  arguments: loadJsonTests(named: "ed 7a", range: 0...testCycles-1))
        func test_ADC_HL_SP(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate LDI (0xEDA0)",  arguments: loadJsonTests(named: "ed a0", range: 0...testCycles-1))
        func test_LDI(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate CPI (0xEDA1)",  arguments: loadJsonTests(named: "ed a1", range: 0...testCycles-1))
        func test_CPI(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate INI (0xEDA2)",  arguments: loadJsonTests(named: "ed a2", range: 0...testCycles-1))
        func test_INI(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OUTI (0xEDA3)",  arguments: loadJsonTests(named: "ed a3", range: 0...testCycles-1))
        func test_OUTI(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate LDD (0xEDA8)",  arguments: loadJsonTests(named: "ed a8", range: 0...testCycles-1))
        func test_LDD(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate CPD (0xEDA9)",  arguments: loadJsonTests(named: "ed a9", range: 0...testCycles-1))
        func test_CPD(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate IND (0xEDAA)",  arguments: loadJsonTests(named: "ed aa", range: 0...testCycles-1))
        func test_IND(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OUTD (0xEDAB)",  arguments: loadJsonTests(named: "ed ab", range: 0...testCycles-1))
        func test_OUTD(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate LDIR (0xEDB0)",  arguments: loadJsonTests(named: "ed b0", range: 0...testCycles-1))
        func test_LDIR(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }

        @Test("Validate CPIR (0xEDB1)",  arguments: loadJsonTests(named: "ed b1", range: 0...testCycles-1))
        func test_CPIR(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }

        @Test("Validate INIR (0xEDB2)",  arguments: loadJsonTests(named: "ed b2", range: 0...testCycles-1))
        func test_INIR(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OTIR (0xEDB3)",  arguments: loadJsonTests(named: "ed b3", range: 0...testCycles-1))
        func test_OTIR(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate LDDR (0xEDB8)",  arguments: loadJsonTests(named: "ed b8", range: 0...testCycles-1))
        func test_LDDR(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }

        @Test("Validate CPDR (0xED:B9)",  arguments: loadJsonTests(named: "ed b9", range: 0...testCycles-1))
        func test_CPDR(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate INDR (0xEDBA)",  arguments: loadJsonTests(named: "ed ba", range: 0...testCycles-1))
        func test_INDR(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate OTDR (0xEDBB)",  arguments: loadJsonTests(named: "ed bb", range: 0...testCycles-1))
        func test_OTDR(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes FD")
    struct ExtendedOpcodesFD: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate LD IY,$nn (0xFD21)", .timeLimit(.minutes(testTiming)), arguments: loadJsonTests(named: "fd 21", range: 0...testCycles-1))
        func test_LD_IY_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD ($nn),IY (0xFD22)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 22", range: 0...testCycles-1))
        func test_LD_CON_NN_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC IY (0xFD23)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 23", range: 0...testCycles-1))
        func test_INC_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IY,($nn) (0xFD2A)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 2a", range: 0...testCycles-1))
        func test_LD_IY_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC IY (0xFD2B)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 2b", range: 0...testCycles-1))
        func test_DEC_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),$n (0xFD36)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 36", range: 0...testCycles-1))
        func test_LD_CON_IY_D_$n(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,(IY+$d) (0xFD46)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 46", range: 0...testCycles-1))
        func test_LD_B_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,(IY+$d) (0xFD4E)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 4e", range: 0...testCycles-1))
        func test_LD_C_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,(IY+$d) (0xFD56)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 56", range: 0...testCycles-1))
        func test_LD_D_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,(IY+$d) (0xFD5E)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 5e", range: 0...testCycles-1))
        func test_LD_E_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD H,(IY+$d) (0xFD66)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 66", range: 0...testCycles-1))
        func test_LD_H_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD L,(IY+$d) (0xFD6E)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 6e", range: 0...testCycles-1))
        func test_LD_L_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),B (0xFD70)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 70", range: 0...testCycles-1))
        func test_LD_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),C (0xFD71)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 71", range: 0...testCycles-1))
        func test_LD_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),D (0xFD72)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 72", range: 0...testCycles-1))
        func test_LD_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),E (0xFD73)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 73", range: 0...testCycles-1))
        func test_LD_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),H (0xFD74)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 74", range: 0...testCycles-1))
        func test_LD_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),L (0xFD75)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 75", range: 0...testCycles-1))
        func test_LD_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD (IY+$d),A (0xFD77)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 77", range: 0...testCycles-1))
        func test_LD_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,(IY+$d) (0xFD7E)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd 7e", range: 0...testCycles-1))
        func test_LD_A_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate POP IY (0xFDE1)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd e1", range: 0...testCycles-1))
        func test_POP_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate EX (SP),IY (0xFDE3)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd e3", range: 0...testCycles-1))
        func test_EX_CON_SP_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate PUSH IY (0xFDE5)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd e5", range: 0...testCycles-1))
        func test_PUSH_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate JP (IY) (0xFDE9)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd e9", range: 0...testCycles-1))
        func test_JP_CON_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD SP,IY (0xFDF9)", .timeLimit(.minutes(testTiming)),  arguments: loadJsonTests(named: "fd f9", range: 0...testCycles-1))
        func test_LD_SP_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes Flags FD")
    struct ExtendedOpcodesFlagsFD: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate ADD IY,BC (0xFD09)",  arguments: loadJsonTests(named: "fd 09", range: 0...testCycles-1))
        func test_ADD_IY_BC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD IY,DE (0xFD19)",  arguments: loadJsonTests(named: "fd 19", range: 0...testCycles-1))
        func test_ADD_IY_DE(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD IY,IY (0xFD29)",  arguments: loadJsonTests(named: "fd 29", range: 0...testCycles-1))
        func test_ADD_IY_IY(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC (IY+$d) (0xFD34)",  arguments: loadJsonTests(named: "fd 34", range: 0...testCycles-1))
        func test_INC_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC (IY+$d) (0xFD35)",  arguments: loadJsonTests(named: "fd 35", range: 0...testCycles-1))
        func test_DEC_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD IY,SP (0xFD39)",  arguments: loadJsonTests(named: "fd 39", range: 0...testCycles-1))
        func test_ADD_IY_SP(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,(IY+$d) (0xFD86)",  arguments: loadJsonTests(named: "fd 86", range: 0...testCycles-1))
        func test_ADD_A_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,(IY+$d) (0xFD8E)",  arguments: loadJsonTests(named: "fd 8e", range: 0...testCycles-1))
        func test_ADC_A_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB (IY+$d) (0xFD96)",  arguments: loadJsonTests(named: "fd 96", range: 0...testCycles-1))
        func test_SUB_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,(IY+$d) (0xFD9E)",  arguments: loadJsonTests(named: "fd 9e", range: 0...testCycles-1))
        func test_SBC_A_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND (IY+$d) (0xFDA6)",  arguments: loadJsonTests(named: "fd a6", range: 0...testCycles-1))
        func test_AND_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR (IY+$d) (0xFDAE)",  arguments: loadJsonTests(named: "fd ae", range: 0...testCycles-1))
        func test_XOR_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR (IY+$d) (0xFDB6)",  arguments: loadJsonTests(named: "fd b6", range: 0...testCycles-1))
        func test_OR_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP (IY+$d) (0xFDBE)",  arguments: loadJsonTests(named: "fd be", range: 0...testCycles-1))
        func test_CP_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes FDCB")
    struct ExtendedOpcodesFDCB: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate RES 0,(IY+$d) (0xFDCB__86)",  arguments: loadJsonTests(named: "fd cb __ 86", range: 0...testCycles-1))
        func test_RES_0_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IY+$d) (0xFDCB__8E)",  arguments: loadJsonTests(named: "fd cb __ 8e", range: 0...testCycles-1))
        func test_RES_1_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IY+$d) (0xFDCB__96)",  arguments: loadJsonTests(named: "fd cb __ 96", range: 0...testCycles-1))
        func test_RES_2_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IY+$d) (0xFDCB__9E)",  arguments: loadJsonTests(named: "fd cb __ 9e", range: 0...testCycles-1))
        func test_RES_3_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IY+$d) (0xFDCB__A6)",  arguments: loadJsonTests(named: "fd cb __ a6", range: 0...testCycles-1))
        func test_RES_4_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IY+$d) (0xFDCB__AE)",  arguments: loadJsonTests(named: "fd cb __ ae", range: 0...testCycles-1))
        func test_RES_5_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IY+$d) (0xFDCB__B6)",  arguments: loadJsonTests(named: "fd cb __ b6", range: 0...testCycles-1))
        func test_RES_6_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IY+$d) (0xFDCB__BE)",  arguments: loadJsonTests(named: "fd cb __ be", range: 0...testCycles-1))
        func test_RES_7_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IY+$d) (0xFDCB__C6)",  arguments: loadJsonTests(named: "fd cb __ c6", range: 0...testCycles-1))
        func test_SET_0_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IY+$d) (0xFDCB__CE)",  arguments: loadJsonTests(named: "fd cb __ ce", range: 0...testCycles-1))
        func test_SET_1_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IY+$d) (0xFDCB__D6)",  arguments: loadJsonTests(named: "fd cb __ d6", range: 0...testCycles-1))
        func test_SET_2_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IY+$d) (0xFDCB__DE)",  arguments: loadJsonTests(named: "fd cb __ de", range: 0...testCycles-1))
        func test_SET_3_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IY+$d) (0xFDCB__E6)",  arguments: loadJsonTests(named: "fd cb __ e6", range: 0...testCycles-1))
        func test_SET_4_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IY+$d) (0xFDCB__EE)",  arguments: loadJsonTests(named: "fd cb __ ee", range: 0...testCycles-1))
        func test_SET_5_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IY+$d) (0xFDCB__F6)",  arguments: loadJsonTests(named: "fd cb __ f6", range: 0...testCycles-1))
        func test_SET_6_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IY+$d) (0xFDCB__FE)",  arguments: loadJsonTests(named: "fd cb __ fe", range: 0...testCycles-1))
        func test_SET_7_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Extended Opcodes Flags FDCB")
    struct ExtendedOpcodesFlagsFDCB: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate RLC (IY+$d) (0xFDCB__06)",  arguments: loadJsonTests(named: "fd cb __ 06", range: 0...testCycles-1))
        func test_RLC_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RRC (IY+$d) (0xFDCB__0E)",  arguments: loadJsonTests(named: "fd cb __ 0e", range: 0...testCycles-1))
        func test_RRC_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RL (IY+$d) (0xFDCB__16)",  arguments: loadJsonTests(named: "fd cb __ 16", range: 0...testCycles-1))
        func test_RL_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate RR (IY+$d) (0xFDCB__1E)",  arguments: loadJsonTests(named: "fd cb __ 1e", range: 0...testCycles-1))
        func test_RR_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SLA (IY+$d) (0xFDCB__26)",  arguments: loadJsonTests(named: "fd cb __ 26", range: 0...testCycles-1))
        func test_SLA_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRA (IY+$d) (0xFDCB__2E)",  arguments: loadJsonTests(named: "fd cb __ 2e", range: 0...testCycles-1))
        func test_SRA_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate SRL (IY+$d) (0xFDCB__3E)",  arguments: loadJsonTests(named: "fd cb __ 3e", range: 0...testCycles-1))
        func test_SRL_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 0,(IY+$d) (0xFDCB__46)",  arguments: loadJsonTests(named: "fd cb __ 46", range: 0...testCycles-1))
        func test_BIT_0_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 1,(IY+$d) (0xFDCB__4E)",  arguments: loadJsonTests(named: "fd cb __ 4e", range: 0...testCycles-1))
        func test_BIT_1_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 2,(IY+$d) (0xFDCB__56)",  arguments: loadJsonTests(named: "fd cb __ 56", range: 0...testCycles-1))
        func test_BIT_2_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 3,(IY+$d) (0xFDCB__5E)",  arguments: loadJsonTests(named: "fd cb __ 5e", range: 0...testCycles-1))
        func test_BIT_3_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 4,(IY+$d) (0xFDCB__66)",  arguments: loadJsonTests(named: "fd cb __ 66", range: 0...testCycles-1))
        func test_BIT_4_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 5,(IY+$d) (0xFDCB__6E)",  arguments: loadJsonTests(named: "fd cb __ 6e", range: 0...testCycles-1))
        func test_BIT_5_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 6,(IY+$d) (0xFDCB__76)",  arguments: loadJsonTests(named: "fd cb __ 76", range: 0...testCycles-1))
        func test_BIT_6_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }

        @Test("Validate BIT 7,(IY+$d) (0xFDCB__7E)",  arguments: loadJsonTests(named: "fd cb __ 7e", range: 0...testCycles-1))
        func test_BIT_7_CON_IY_D(testCase: Z80Test) async throws
        {
        try await parent.runTest(testCase)
        }
    }
    
    @Suite("Undocumented Extended Opcodes CB")
    struct UndocumentExtendedOpcodesCB: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate SLL B (0xCB30)",  arguments: loadJsonTests(named: "cb 30", range: 0...testCycles-1))
        func test_SLL_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL C (0xCB31)",  arguments: loadJsonTests(named: "cb 31", range: 0...testCycles-1))
        func test_SLL_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL D (0xCB32)",  arguments: loadJsonTests(named: "cb 32", range: 0...testCycles-1))
        func test_SLL_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL E (0xCB33)",  arguments: loadJsonTests(named: "cb 33", range: 0...testCycles-1))
        func test_SLL_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL H (0xCB34)",  arguments: loadJsonTests(named: "cb 34", range: 0...testCycles-1))
        func test_SLL_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL L (0xCB35)",  arguments: loadJsonTests(named: "cb 35", range: 0...testCycles-1))
        func test_SLL_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (HL) (0xCB36)",  arguments: loadJsonTests(named: "cb 36", range: 0...testCycles-1))
        func test_SLL_CON_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL A (0xCB37)",  arguments: loadJsonTests(named: "cb 37", range: 0...testCycles-1))
        func test_SLL_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Undocumented Extended Opcodes DD")
    struct UndocumentExtendedOpcodesDD: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate INC B (0xDD04)",  arguments: loadJsonTests(named: "dd 04", range: 0...testCycles-1))
        func test_INC_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC B (0xDD05)",  arguments: loadJsonTests(named: "dd 05", range: 0...testCycles-1))
        func test_DEC_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,$n (0xDD06)",  arguments: loadJsonTests(named: "dd 06", range: 0...testCycles-1))
        func test_LD_B_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC C (0xDD0C)",  arguments: loadJsonTests(named: "dd 0c", range: 0...testCycles-1))
        func test_INC_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC C (0xDD0D)",  arguments: loadJsonTests(named: "dd 0d", range: 0...testCycles-1))
        func test_DEC_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,$n (0xDD0E)",  arguments: loadJsonTests(named: "dd 0E", range: 0...testCycles-1))
        func test_LD_C_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC D (0xDD14)",  arguments: loadJsonTests(named: "dd 14", range: 0...testCycles-1))
        func test_INC_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC D (0xDD15)",  arguments: loadJsonTests(named: "dd 15", range: 0...testCycles-1))
        func test_DEC_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,$n (0xDD16)",  arguments: loadJsonTests(named: "dd 16", range: 0...testCycles-1))
        func test_LD_D_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC E (0xDD1C)",  arguments: loadJsonTests(named: "dd 1c", range: 0...testCycles-1))
        func test_INC_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC E (0xDD1D)",  arguments: loadJsonTests(named: "dd 1d", range: 0...testCycles-1))
        func test_DEC_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,$n (0xDD1E)",  arguments: loadJsonTests(named: "dd 1e", range: 0...testCycles-1))
        func test_LD_E_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC IXH (0xDD24)",  arguments: loadJsonTests(named: "dd 24", range: 0...testCycles-1))
        func test_INC_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC IXH (0xDD25)",  arguments: loadJsonTests(named: "dd 25", range: 0...testCycles-1))
        func test_DEC_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IHX,$n (0xDD26)",  arguments: loadJsonTests(named: "dd 26", range: 0...testCycles-1))
        func test_LD_IHX_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC IXL (0xDD2C)",  arguments: loadJsonTests(named: "dd 2c", range: 0...testCycles-1))
        func test_INC_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC IXL (0xDD2D)",  arguments: loadJsonTests(named: "dd 2d", range: 0...testCycles-1))
        func test_DEC_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXL,$n (0xDD2E)",  arguments: loadJsonTests(named: "dd 2e", range: 0...testCycles-1))
        func test_LD_IXL_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC A (0xDD3C)",  arguments: loadJsonTests(named: "dd 3c", range: 0...testCycles-1))
        func test_INC_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC A (0xDD3D)",  arguments: loadJsonTests(named: "dd 3d", range: 0...testCycles-1))
        func test_DEC_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,$n (0xDD3E)",  arguments: loadJsonTests(named: "dd 3e", range: 0...testCycles-1))
        func test_LD_A_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,B (0xDD40)",  arguments: loadJsonTests(named: "dd 40", range: 0...testCycles-1))
        func test_LD_B_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,C (0xDD41)",  arguments: loadJsonTests(named: "dd 41", range: 0...testCycles-1))
        func test_LD_B_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,D (0xDD42)",  arguments: loadJsonTests(named: "dd 42", range: 0...testCycles-1))
        func test_LD_B_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,E (0xDD43)",  arguments: loadJsonTests(named: "dd 43", range: 0...testCycles-1))
        func test_LD_B_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,IXH (0xDD44)",  arguments: loadJsonTests(named: "dd 44", range: 0...testCycles-1))
        func test_LD_B_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,IXL (0xDD45)",  arguments: loadJsonTests(named: "dd 45", range: 0...testCycles-1))
        func test_LD_B_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,A (0xDD47)",  arguments: loadJsonTests(named: "dd 47", range: 0...testCycles-1))
        func test_LD_B_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,B (0xDD48)",  arguments: loadJsonTests(named: "dd 48", range: 0...testCycles-1))
        func test_LD_C_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,C (0xDD49)",  arguments: loadJsonTests(named: "dd 49", range: 0...testCycles-1))
        func test_LD_C_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,D (0xDD4A)",  arguments: loadJsonTests(named: "dd 4a", range: 0...testCycles-1))
        func test_LD_C_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,E (0xDD4B)",  arguments: loadJsonTests(named: "dd 4b", range: 0...testCycles-1))
        func test_LD_C_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,IXH (0xDD4C)",  arguments: loadJsonTests(named: "dd 4c", range: 0...testCycles-1))
        func test_LD_C_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,IXL (0xDD4D)",  arguments: loadJsonTests(named: "dd 4d", range: 0...testCycles-1))
        func test_LD_C_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,A (0xDD4F)",  arguments: loadJsonTests(named: "dd 4f", range: 0...testCycles-1))
        func test_LD_C_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,B (0xDD50)",  arguments: loadJsonTests(named: "dd 50", range: 0...testCycles-1))
        func test_LD_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,C (0xDD51)",  arguments: loadJsonTests(named: "dd 51", range: 0...testCycles-1))
        func test_LD_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,D (0xDD52)",  arguments: loadJsonTests(named: "dd 52", range: 0...testCycles-1))
        func test_LD_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,E (0xDD53)",  arguments: loadJsonTests(named: "dd 53", range: 0...testCycles-1))
        func test_LD_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,IXH (0xDD54)",  arguments: loadJsonTests(named: "dd 54", range: 0...testCycles-1))
        func test_LD_D_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,IXL (0xDD55)",  arguments: loadJsonTests(named: "dd 55", range: 0...testCycles-1))
        func test_LD_D_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,A (0xDD57)",  arguments: loadJsonTests(named: "dd 57", range: 0...testCycles-1))
        func test_LD_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,B (0xDD58)",  arguments: loadJsonTests(named: "dd 58", range: 0...testCycles-1))
        func test_LD_E_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,C (0xDD59)",  arguments: loadJsonTests(named: "dd 59", range: 0...testCycles-1))
        func test_LD_E_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,D (0xDD5A)",  arguments: loadJsonTests(named: "dd 5a", range: 0...testCycles-1))
        func test_LD_E_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,E (0xDD5B)",  arguments: loadJsonTests(named: "dd 5b", range: 0...testCycles-1))
        func test_LD_E_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,IXH (0xDD5C)",  arguments: loadJsonTests(named: "dd 5c", range: 0...testCycles-1))
        func test_LD_E_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,IXL (0xDD5D)",  arguments: loadJsonTests(named: "dd 5d", range: 0...testCycles-1))
        func test_LD_E_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,A (0xDD5F)",  arguments: loadJsonTests(named: "dd 5f", range: 0...testCycles-1))
        func test_LD_E_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXH,B (0xDD60)",  arguments: loadJsonTests(named: "dd 60", range: 0...testCycles-1))
        func test_LD_IXH_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXH,C (0xDD61)",  arguments: loadJsonTests(named: "dd 61", range: 0...testCycles-1))
        func test_LD_IXH_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXH,D (0xDD62)",  arguments: loadJsonTests(named: "dd 62", range: 0...testCycles-1))
        func test_LD_IXH_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXH,E (0xDD63)",  arguments: loadJsonTests(named: "dd 63", range: 0...testCycles-1))
        func test_LD_IXH_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXH,IXH (0xDD64)",  arguments: loadJsonTests(named: "dd 64", range: 0...testCycles-1))
        func test_LD_IXH_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXH,IXL (0xDD65)",  arguments: loadJsonTests(named: "dd 65", range: 0...testCycles-1))
        func test_LD_IXH_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXH,A (0xDD67)",  arguments: loadJsonTests(named: "dd 67", range: 0...testCycles-1))
        func test_LD_IXH_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXL,B (0xDD68)",  arguments: loadJsonTests(named: "dd 68", range: 0...testCycles-1))
        func test_LD_IXL_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXL,C (0xDD69)",  arguments: loadJsonTests(named: "dd 69", range: 0...testCycles-1))
        func test_LD_IXL_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXL,D (0xDD6A)",  arguments: loadJsonTests(named: "dd 6a", range: 0...testCycles-1))
        func test_LD_IXL_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXL,E (0xDD6B)",  arguments: loadJsonTests(named: "dd 6b", range: 0...testCycles-1))
        func test_LD_IXL_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXL,IXH (0xDD6C)",  arguments: loadJsonTests(named: "dd 6c", range: 0...testCycles-1))
        func test_LD_IXL_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXL,IXL (0xDD6D)",  arguments: loadJsonTests(named: "dd 6d", range: 0...testCycles-1))
        func test_LD_IXL_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IXL,A (0xDD6F)",  arguments: loadJsonTests(named: "dd 6f", range: 0...testCycles-1))
        func test_LD_IXL_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,B (0xDD78)",  arguments: loadJsonTests(named: "dd 78", range: 0...testCycles-1))
        func test_LD_A_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,C (0xDD79)",  arguments: loadJsonTests(named: "dd 79", range: 0...testCycles-1))
        func test_LD_A_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,D (0xDD7A)",  arguments: loadJsonTests(named: "dd 7a", range: 0...testCycles-1))
        func test_LD_A_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,E (0xDD7B)",  arguments: loadJsonTests(named: "dd 7b", range: 0...testCycles-1))
        func test_LD_A_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,IXH (0xDD7C)",  arguments: loadJsonTests(named: "dd 7c", range: 0...testCycles-1))
        func test_LD_A_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,IXL (0xDD7D)",  arguments: loadJsonTests(named: "dd 7d", range: 0...testCycles-1))
        func test_LD_A_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,A (0xDD7F)",  arguments: loadJsonTests(named: "dd 7f", range: 0...testCycles-1))
        func test_LD_A_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,B (0xDD80)",  arguments: loadJsonTests(named: "dd 80", range: 0...testCycles-1))
        func test_ADD_A_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,C (0xDD81)",  arguments: loadJsonTests(named: "dd 81", range: 0...testCycles-1))
        func test_ADD_A_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,D (0xDD82)",  arguments: loadJsonTests(named: "dd 82", range: 0...testCycles-1))
        func test_ADD_A_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,E (0xDD83)",  arguments: loadJsonTests(named: "dd 83", range: 0...testCycles-1))
        func test_ADD_A_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,IXH (0xDD84)",  arguments: loadJsonTests(named: "dd 84", range: 0...testCycles-1))
        func test_ADD_A_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,IXL (0xDD85)",  arguments: loadJsonTests(named: "dd 85", range: 0...testCycles-1))
        func test_ADD_A_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,A (0xDD87)",  arguments: loadJsonTests(named: "dd 87", range: 0...testCycles-1))
        func test_ADD_A_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,B (0xDD88)",  arguments: loadJsonTests(named: "dd 88", range: 0...testCycles-1))
        func test_ADC_A_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,C (0xDD89)",  arguments: loadJsonTests(named: "dd 89", range: 0...testCycles-1))
        func test_ADC_A_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,D (0xDD8A)",  arguments: loadJsonTests(named: "dd 8a", range: 0...testCycles-1))
        func test_ADC_A_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,E (0xDD8B)",  arguments: loadJsonTests(named: "dd 8b", range: 0...testCycles-1))
        func test_ADC_A_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,IXH (0xDD8C)",  arguments: loadJsonTests(named: "dd 8c", range: 0...testCycles-1))
        func test_ADC_A_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,IXL (0xDD8D)",  arguments: loadJsonTests(named: "dd 8d", range: 0...testCycles-1))
        func test_ADC_A_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,A (0xDD8F)",  arguments: loadJsonTests(named: "dd 8f", range: 0...testCycles-1))
        func test_ADC_A_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB B (0xDD90)",  arguments: loadJsonTests(named: "dd 90", range: 0...testCycles-1))
        func test_SUB_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB C (0xDD91)",  arguments: loadJsonTests(named: "dd 91", range: 0...testCycles-1))
        func test_SUB_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB D (0xDD92)",  arguments: loadJsonTests(named: "dd 92", range: 0...testCycles-1))
        func test_SUB_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB E (0xDD93)",  arguments: loadJsonTests(named: "dd 93", range: 0...testCycles-1))
        func test_SUB_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB IXH (0xDD94)",  arguments: loadJsonTests(named: "dd 94", range: 0...testCycles-1))
        func test_SUB_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB IXL (0xDD95)",  arguments: loadJsonTests(named: "dd 95", range: 0...testCycles-1))
        func test_SUB_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB A (0xDD97)",  arguments: loadJsonTests(named: "dd 97", range: 0...testCycles-1))
        func test_SUB_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,B (0xDD98)",  arguments: loadJsonTests(named: "dd 98", range: 0...testCycles-1))
        func test_SBC_A_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,C (0xDD99)",  arguments: loadJsonTests(named: "dd 99", range: 0...testCycles-1))
        func test_SBC_A_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,D (0xDD9A)",  arguments: loadJsonTests(named: "dd 9a", range: 0...testCycles-1))
        func test_SBC_A_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,E (0xDD9B)",  arguments: loadJsonTests(named: "dd 9b", range: 0...testCycles-1))
        func test_SBC_A_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,IXH (0xDD9C)",  arguments: loadJsonTests(named: "dd 9c", range: 0...testCycles-1))
        func test_SBC_A_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,IXL (0xDD9D)",  arguments: loadJsonTests(named: "dd 9d", range: 0...testCycles-1))
        func test_SBC_A_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,A (0xDD9F)",  arguments: loadJsonTests(named: "dd 9f", range: 0...testCycles-1))
        func test_SBC_A_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND B (0xDDA0)",  arguments: loadJsonTests(named: "dd a0", range: 0...testCycles-1))
        func test_AND_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND C (0xDDA1)",  arguments: loadJsonTests(named: "dd a1", range: 0...testCycles-1))
        func test_AND_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND D (0xDDA2)",  arguments: loadJsonTests(named: "dd a2", range: 0...testCycles-1))
        func test_AND_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND E (0xDDA3)",  arguments: loadJsonTests(named: "dd a3", range: 0...testCycles-1))
        func test_AND_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND IXH (0xDDA4)",  arguments: loadJsonTests(named: "dd a4", range: 0...testCycles-1))
        func test_AND_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND IXL (0xDDA5)",  arguments: loadJsonTests(named: "dd a5", range: 0...testCycles-1))
        func test_AND_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND A (0xDDA7)",  arguments: loadJsonTests(named: "dd a7", range: 0...testCycles-1))
        func test_AND_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR B (0xDDA8)",  arguments: loadJsonTests(named: "dd a8", range: 0...testCycles-1))
        func test_XOR_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR C (0xDDA9)",  arguments: loadJsonTests(named: "dd a9", range: 0...testCycles-1))
        func test_XOR_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR D (0xDDAA)",  arguments: loadJsonTests(named: "dd aa", range: 0...testCycles-1))
        func test_XOR_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR E (0xDDAB)",  arguments: loadJsonTests(named: "dd ab", range: 0...testCycles-1))
        func test_XOR_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR IXH (0xDDAC)",  arguments: loadJsonTests(named: "dd ac", range: 0...testCycles-1))
        func test_XOR_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR IXL (0xDDAD)",  arguments: loadJsonTests(named: "dd ad", range: 0...testCycles-1))
        func test_XOR_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR A (0xDDAF)",  arguments: loadJsonTests(named: "dd af", range: 0...testCycles-1))
        func test_XOR_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR B (0xDDB0)",  arguments: loadJsonTests(named: "dd b0", range: 0...testCycles-1))
        func test_OR_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR C (0xDDB1)",  arguments: loadJsonTests(named: "dd b1", range: 0...testCycles-1))
        func test_OR_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR D (0xDDB2)",  arguments: loadJsonTests(named: "dd b2", range: 0...testCycles-1))
        func test_OR_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR E (0xDDB3)",  arguments: loadJsonTests(named: "dd b3", range: 0...testCycles-1))
        func test_OR_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR IXH (0xDDB4)",  arguments: loadJsonTests(named: "dd b4", range: 0...testCycles-1))
        func test_OR_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR IXL (0xDDB5)",  arguments: loadJsonTests(named: "dd b5", range: 0...testCycles-1))
        func test_OR_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR A (0xDDB7)",  arguments: loadJsonTests(named: "dd b7", range: 0...testCycles-1))
        func test_OR_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP B (0xDDB8)",  arguments: loadJsonTests(named: "dd b8", range: 0...testCycles-1))
        func test_CP_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP C (0xDDB9)",  arguments: loadJsonTests(named: "dd b9", range: 0...testCycles-1))
        func test_CP_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP D (0xDDBA)",  arguments: loadJsonTests(named: "dd ba", range: 0...testCycles-1))
        func test_CP_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP E (0xDDBB)",  arguments: loadJsonTests(named: "dd bb", range: 0...testCycles-1))
        func test_CP_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP IXH (0xDDBC)",  arguments: loadJsonTests(named: "dd bc", range: 0...testCycles-1))
        func test_CP_IXH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP IXL (0xDDBD)",  arguments: loadJsonTests(named: "dd bd", range: 0...testCycles-1))
        func test_CP_IXL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP A (0xDDBF)",  arguments: loadJsonTests(named: "dd bf", range: 0...testCycles-1))
        func test_CP_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Undocumented Extended Opcodes DDCB")
    struct UndocumentExtendedOpcodesDDCB: testHelper
    {
        let parent = Z80Opcodes()
    
        @Test("Validate RLC (IX+$d),B (0xDDCB __ 00)",  arguments: loadJsonTests(named: "dd cb __ 00", range: 0...testCycles-1))
        func test_RLC_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RLC (IX+$d),C (0xDDCB __ 01)",  arguments: loadJsonTests(named: "dd cb __ 01", range: 0...testCycles-1))
        func test_RLC_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RLC (IX+$d),D (0xDDCB __ 02)",  arguments: loadJsonTests(named: "dd cb __ 02", range: 0...testCycles-1))
        func test_RLC_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RLC (IX+$d),E (0xDDCB __ 03)",  arguments: loadJsonTests(named: "dd cb __ 03", range: 0...testCycles-1))
        func test_RLC_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RLC (IX+$d),H (0xDDCB __ 04)",  arguments: loadJsonTests(named: "dd cb __ 04", range: 0...testCycles-1))
        func test_RLC_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RLC (IX+$d),L (0xDDCB __ 05)",  arguments: loadJsonTests(named: "dd cb __ 05", range: 0...testCycles-1))
        func test_RLC_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RLC (IX+$d),A (0xDDCB __ 07)",  arguments: loadJsonTests(named: "dd cb __ 07", range: 0...testCycles-1))
        func test_RLC_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IX+$d),B (0xDDCB __ 08)",  arguments: loadJsonTests(named: "dd cb __ 08", range: 0...testCycles-1))
        func test_RRC_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IX+$d),C (0xDDCB __ 09)",  arguments: loadJsonTests(named: "dd cb __ 09", range: 0...testCycles-1))
        func test_RRC_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IX+$d),D (0xDDCB __ 0A)",  arguments: loadJsonTests(named: "dd cb __ 0a", range: 0...testCycles-1))
        func test_RRC_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IX+$d),E (0xDDCB __ 0B)",  arguments: loadJsonTests(named: "dd cb __ 0b", range: 0...testCycles-1))
        func test_RRC_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IX+$d),H (0xDDCB __ 0C)",  arguments: loadJsonTests(named: "dd cb __ 0c", range: 0...testCycles-1))
        func test_RRC_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IX+$d),L (0xDDCB __ 0D)",  arguments: loadJsonTests(named: "dd cb __ 0d", range: 0...testCycles-1))
        func test_RRC_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IX+$d),A (0xDDCB __ 0F)",  arguments: loadJsonTests(named: "dd cb __ 0f", range: 0...testCycles-1))
        func test_RRC_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IX+$d),B (0xDDCB __ 10)",  arguments: loadJsonTests(named: "dd cb __ 10", range: 0...testCycles-1))
        func test_RL_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IX+$d),C (0xDDCB __ 11)",  arguments: loadJsonTests(named: "dd cb __ 11", range: 0...testCycles-1))
        func test_RL_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IX+$d),D (0xDDCB __ 12)",  arguments: loadJsonTests(named: "dd cb __ 12", range: 0...testCycles-1))
        func test_RL_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IX+$d),E (0xDDCB __ 13)",  arguments: loadJsonTests(named: "dd cb __ 13", range: 0...testCycles-1))
        func test_RL_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IX+$d),H (0xDDCB __ 14)",  arguments: loadJsonTests(named: "dd cb __ 14", range: 0...testCycles-1))
        func test_RL_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IX+$d),L (0xDDCB __ 15)",  arguments: loadJsonTests(named: "dd cb __ 15", range: 0...testCycles-1))
        func test_RL_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IX+$d),A (0xDDCB __ 17)",  arguments: loadJsonTests(named: "dd cb __ 17", range: 0...testCycles-1))
        func test_RL_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IX+$d),B (0xDDCB __ 18)",  arguments: loadJsonTests(named: "dd cb __ 18", range: 0...testCycles-1))
        func test_RR_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IX+$d),C (0xDDCB __ 19)",  arguments: loadJsonTests(named: "dd cb __ 19", range: 0...testCycles-1))
        func test_RR_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IX+$d),D (0xDDCB __ 1A)",  arguments: loadJsonTests(named: "dd cb __ 1a", range: 0...testCycles-1))
        func test_RR_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IX+$d),E (0xDDCB __ 1B)",  arguments: loadJsonTests(named: "dd cb __ 1b", range: 0...testCycles-1))
        func test_RR_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IX+$d),H (0xDDCB __ 1C)",  arguments: loadJsonTests(named: "dd cb __ 1c", range: 0...testCycles-1))
        func test_RR_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IX+$d),L (0xDDCB __ 1D)",  arguments: loadJsonTests(named: "dd cb __ 1d", range: 0...testCycles-1))
        func test_RR_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IX+$d),A (0xDDCB __ 1F)",  arguments: loadJsonTests(named: "dd cb __ 1f", range: 0...testCycles-1))
        func test_RR_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IX+$d),B (0xDDCB __ 20)",  arguments: loadJsonTests(named: "dd cb __ 20", range: 0...testCycles-1))
        func test_SLA_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IX+$d),C (0xDDCB __ 21)",  arguments: loadJsonTests(named: "dd cb __ 21", range: 0...testCycles-1))
        func test_SLA_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IX+$d),D (0xDDCB __ 22)",  arguments: loadJsonTests(named: "dd cb __ 22", range: 0...testCycles-1))
        func test_SLA_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IX+$d),E (0xDDCB __ 23)",  arguments: loadJsonTests(named: "dd cb __ 23", range: 0...testCycles-1))
        func test_SLA_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IX+$d),H (0xDDCB __ 24)",  arguments: loadJsonTests(named: "dd cb __ 24", range: 0...testCycles-1))
        func test_SLA_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IX+$d),L (0xDDCB __ 25)",  arguments: loadJsonTests(named: "dd cb __ 25", range: 0...testCycles-1))
        func test_SLA_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IX+$d),A (0xDDCB __ 27)",  arguments: loadJsonTests(named: "dd cb __ 27", range: 0...testCycles-1))
        func test_SLA_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IX+$d),B (0xDDCB __ 28)",  arguments: loadJsonTests(named: "dd cb __ 28", range: 0...testCycles-1))
        func test_SRA_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IX+$d),C (0xDDCB __ 29)",  arguments: loadJsonTests(named: "dd cb __ 29", range: 0...testCycles-1))
        func test_SRA_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IX+$d),D (0xDDCB __ 2A)",  arguments: loadJsonTests(named: "dd cb __ 2a", range: 0...testCycles-1))
        func test_SRA_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IX+$d),E (0xDDCB __ 2B)",  arguments: loadJsonTests(named: "dd cb __ 2b", range: 0...testCycles-1))
        func test_SRA_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IX+$d),H (0xDDCB __ 2C)",  arguments: loadJsonTests(named: "dd cb __ 2c", range: 0...testCycles-1))
        func test_SRA_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IX+$d),L (0xDDCB __ 2D)",  arguments: loadJsonTests(named: "dd cb __ 2d", range: 0...testCycles-1))
        func test_SRA_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IX+$d),A (0xDDCB __ 2F)",  arguments: loadJsonTests(named: "dd cb __ 2f", range: 0...testCycles-1))
        func test_SRA_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IX+$d),B (0xDDCB __ 30)",  arguments: loadJsonTests(named: "dd cb __ 30", range: 0...testCycles-1))
        func test_SLL_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IX+$d),C (0xDDCB __ 31)",  arguments: loadJsonTests(named: "dd cb __ 31", range: 0...testCycles-1))
        func test_SLL_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IX+$d),D (0xDDCB __ 32)",  arguments: loadJsonTests(named: "dd cb __ 32", range: 0...testCycles-1))
        func test_SLL_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IX+$d),E (0xDDCB __ 33)",  arguments: loadJsonTests(named: "dd cb __ 33", range: 0...testCycles-1))
        func test_SLL_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IX+$d),H (0xDDCB __ 34)",  arguments: loadJsonTests(named: "dd cb __ 34", range: 0...testCycles-1))
        func test_SLL_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IX+$d),L (0xDDCB __ 35)",  arguments: loadJsonTests(named: "dd cb __ 35", range: 0...testCycles-1))
        func test_SLL_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IX+$d) (0xDDCB __ 36)",  arguments: loadJsonTests(named: "dd cb __ 36", range: 0...testCycles-1))
        func test_SLL_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IX+$d),A (0xDDCB __ 37)",  arguments: loadJsonTests(named: "dd cb __ 37", range: 0...testCycles-1))
        func test_SLL_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IX+$d),B (0xDDCB __ 38)",  arguments: loadJsonTests(named: "dd cb __ 38", range: 0...testCycles-1))
        func test_SRL_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IX+$d),C (0xDDCB __ 39)",  arguments: loadJsonTests(named: "dd cb __ 39", range: 0...testCycles-1))
        func test_SRL_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IX+$d),D (0xDDCB __ 3A)",  arguments: loadJsonTests(named: "dd cb __ 3a", range: 0...testCycles-1))
        func test_SRL_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IX+$d),E (0xDDCB __ 3B)",  arguments: loadJsonTests(named: "dd cb __ 3b", range: 0...testCycles-1))
        func test_SRL_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IX+$d),H (0xDDCB __ 3C)",  arguments: loadJsonTests(named: "dd cb __ 3c", range: 0...testCycles-1))
        func test_SRL_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IX+$d),L (0xDDCB __ 3D)",  arguments: loadJsonTests(named: "dd cb __ 3d", range: 0...testCycles-1))
        func test_SRL_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IX+$d),A (0xDDCB __ 3F)",  arguments: loadJsonTests(named: "dd cb __ 3f", range: 0...testCycles-1))
        func test_SRL_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IX+$d) (0xDDCB __ 40)",  arguments: loadJsonTests(named: "dd cb __ 40", range: 0...testCycles-1))
        func test_BIT_0_CON_IX_D_40(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IX+$d) (0xDDCB __ 41)",  arguments: loadJsonTests(named: "dd cb __ 41", range: 0...testCycles-1))
        func test_BIT_0_CON_IX_D_41(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IX+$d) (0xDDCB __ 42)",  arguments: loadJsonTests(named: "dd cb __ 42", range: 0...testCycles-1))
        func test_BIT_0_CON_IX_D_42(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IX+$d) (0xDDCB __ 43)",  arguments: loadJsonTests(named: "dd cb __ 43", range: 0...testCycles-1))
        func test_BIT_0_CON_IX_D_43(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IX+$d) (0xDDCB __ 44)",  arguments: loadJsonTests(named: "dd cb __ 44", range: 0...testCycles-1))
        func test_BIT_0_CON_IX_D_44(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IX+$d) (0xDDCB __ 45)",  arguments: loadJsonTests(named: "dd cb __ 45", range: 0...testCycles-1))
        func test_BIT_0_CON_IX_D_45(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IX+$d) (0xDDCB __ 47)",  arguments: loadJsonTests(named: "dd cb __ 47", range: 0...testCycles-1))
        func test_BIT_0_CON_IX_D_47(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IX+$d) (0xDDCB __ 48)",  arguments: loadJsonTests(named: "dd cb __ 48", range: 0...testCycles-1))
        func test_BIT_1_CON_IX_D_48(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IX+$d) (0xDDCB __ 49)",  arguments: loadJsonTests(named: "dd cb __ 49", range: 0...testCycles-1))
        func test_BIT_1_CON_IX_D_49(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IX+$d) (0xDDCB __ 4A)",  arguments: loadJsonTests(named: "dd cb __ 4a", range: 0...testCycles-1))
        func test_BIT_1_CON_IX_D_4A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IX+$d) (0xDDCB __ 4B)",  arguments: loadJsonTests(named: "dd cb __ 4b", range: 0...testCycles-1))
        func test_BIT_1_CON_IX_D_4B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IX+$d) (0xDDCB __ 4C)",  arguments: loadJsonTests(named: "dd cb __ 4c", range: 0...testCycles-1))
        func test_BIT_1_CON_IX_D_4C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IX+$d) (0xDDCB __ 4D)",  arguments: loadJsonTests(named: "dd cb __ 4d", range: 0...testCycles-1))
        func test_BIT_1_CON_IX_D_4D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IX+$d) (0xDDCB __ 4F)",  arguments: loadJsonTests(named: "dd cb __ 4f", range: 0...testCycles-1))
        func test_BIT_1_CON_IX_D_4F(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IX+$d) (0xDDCB __ 50)",  arguments: loadJsonTests(named: "dd cb __ 50", range: 0...testCycles-1))
        func test_BIT_2_CON_IX_D_50(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IX+$d) (0xDDCB __ 51)",  arguments: loadJsonTests(named: "dd cb __ 51", range: 0...testCycles-1))
        func test_BIT_2_CON_IX_D_51(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IX+$d) (0xDDCB __ 52)",  arguments: loadJsonTests(named: "dd cb __ 52", range: 0...testCycles-1))
        func test_BIT_2_CON_IX_D_52(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IX+$d) (0xDDCB __ 53)",  arguments: loadJsonTests(named: "dd cb __ 53", range: 0...testCycles-1))
        func test_BIT_2_CON_IX_D_53(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IX+$d) (0xDDCB __ 54)",  arguments: loadJsonTests(named: "dd cb __ 54", range: 0...testCycles-1))
        func test_BIT_2_CON_IX_D_54(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IX+$d) (0xDDCB __ 55)",  arguments: loadJsonTests(named: "dd cb __ 55", range: 0...testCycles-1))
        func test_BIT_2_CON_IX_D_55(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IX+$d) (0xDDCB __ 57)",  arguments: loadJsonTests(named: "dd cb __ 57", range: 0...testCycles-1))
        func test_BIT_2_CON_IX_D_57(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IX+$d) (0xDDCB __ 58)",  arguments: loadJsonTests(named: "dd cb __ 58", range: 0...testCycles-1))
        func test_BIT_3_CON_IX_D_58(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IX+$d) (0xDDCB __ 59)",  arguments: loadJsonTests(named: "dd cb __ 59", range: 0...testCycles-1))
        func test_BIT_3_CON_IX_D_59(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IX+$d) (0xDDCB __ 5A)",  arguments: loadJsonTests(named: "dd cb __ 5a", range: 0...testCycles-1))
        func test_BIT_3_CON_IX_D_5A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IX+$d) (0xDDCB __ 5B)",  arguments: loadJsonTests(named: "dd cb __ 5b", range: 0...testCycles-1))
        func test_BIT_3_CON_IX_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IX+$d) (0xDDCB __ 5C)",  arguments: loadJsonTests(named: "dd cb __ 5c", range: 0...testCycles-1))
        func test_BIT_3_CON_IX_D_5C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IX+$d) (0xDDCB __ 5D)",  arguments: loadJsonTests(named: "dd cb __ 5d", range: 0...testCycles-1))
        func test_BIT_3_CON_IX_D_5D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IX+$d) (0xDDCB __ 5F)",  arguments: loadJsonTests(named: "dd cb __ 5f", range: 0...testCycles-1))
        func test_BIT_3_CON_IX_D_5F(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IX+$d) (0xDDCB __ 60)",  arguments: loadJsonTests(named: "dd cb __ 60", range: 0...testCycles-1))
        func test_BIT_4_CON_IX_D_60(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IX+$d) (0xDDCB __ 61)",  arguments: loadJsonTests(named: "dd cb __ 61", range: 0...testCycles-1))
        func test_BIT_4_CON_IX_D_61(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IX+$d) (0xDDCB __ 62)",  arguments: loadJsonTests(named: "dd cb __ 62", range: 0...testCycles-1))
        func test_BIT_4_CON_IX_D_62(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IX+$d) (0xDDCB __ 63)",  arguments: loadJsonTests(named: "dd cb __ 63", range: 0...testCycles-1))
        func test_BIT_4_CON_IX_D_63(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IX+$d) (0xDDCB __ 64)",  arguments: loadJsonTests(named: "dd cb __ 64", range: 0...testCycles-1))
        func test_BIT_4_CON_IX_D_64(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IX+$d) (0xDDCB __ 65)",  arguments: loadJsonTests(named: "dd cb __ 65", range: 0...testCycles-1))
        func test_BIT_4_CON_IX_D_65(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IX+$d) (0xDDCB __ 67)",  arguments: loadJsonTests(named: "dd cb __ 67", range: 0...testCycles-1))
        func test_BIT_4_CON_IX_D_67(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IX+$d) (0xDDCB __ 68)",  arguments: loadJsonTests(named: "dd cb __ 68", range: 0...testCycles-1))
        func test_BIT_5_CON_IX_D_68(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IX+$d) (0xDDCB __ 69)",  arguments: loadJsonTests(named: "dd cb __ 69", range: 0...testCycles-1))
        func test_BIT_5_CON_IX_D_69(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IX+$d) (0xDDCB __ 6A)",  arguments: loadJsonTests(named: "dd cb __ 6a", range: 0...testCycles-1))
        func test_BIT_5_CON_IX_D_6A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IX+$d) (0xDDCB __ 6B)",  arguments: loadJsonTests(named: "dd cb __ 6b", range: 0...testCycles-1))
        func test_BIT_5_CON_IX_D_6B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IX+$d) (0xDDCB __ 6C)",  arguments: loadJsonTests(named: "dd cb __ 6c", range: 0...testCycles-1))
        func test_BIT_5_CON_IX_D_6C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IX+$d) (0xDDCB __ 6D)",  arguments: loadJsonTests(named: "dd cb __ 6d", range: 0...testCycles-1))
        func test_BIT_5_CON_IX_D_6D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IX+$d) (0xDDCB __ 6F)",  arguments: loadJsonTests(named: "dd cb __ 6f", range: 0...testCycles-1))
        func test_BIT_5_CON_IX_D_6F(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IX+$d) (0xDDCB __ 70)",  arguments: loadJsonTests(named: "dd cb __ 70", range: 0...testCycles-1))
        func test_BIT_6_CON_IX_D_70(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IX+$d) (0xDDCB __ 71)",  arguments: loadJsonTests(named: "dd cb __ 71", range: 0...testCycles-1))
        func test_BIT_6_CON_IX_D_71(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IX+$d) (0xDDCB __ 72)",  arguments: loadJsonTests(named: "dd cb __ 72", range: 0...testCycles-1))
        func test_BIT_6_CON_IX_D_72(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IX+$d) (0xDDCB __ 73)",  arguments: loadJsonTests(named: "dd cb __ 73", range: 0...testCycles-1))
        func test_BIT_6_CON_IX_D_73(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IX+$d) (0xDDCB __ 74)",  arguments: loadJsonTests(named: "dd cb __ 74", range: 0...testCycles-1))
        func test_BIT_6_CON_IX_D_74(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IX+$d) (0xDDCB __ 75)",  arguments: loadJsonTests(named: "dd cb __ 75", range: 0...testCycles-1))
        func test_BIT_6_CON_IX_D_75(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IX+$d) (0xDDCB __ 77)",  arguments: loadJsonTests(named: "dd cb __ 77", range: 0...testCycles-1))
        func test_BIT_6_CON_IX_D_77(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IX+$d) (0xDDCB __ 78)",  arguments: loadJsonTests(named: "dd cb __ 78", range: 0...testCycles-1))
        func test_BIT_7_CON_IX_D_78(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IX+$d) (0xDDCB __ 79)",  arguments: loadJsonTests(named: "dd cb __ 79", range: 0...testCycles-1))
        func test_BIT_7_CON_IX_D_79(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IX+$d) (0xDDCB __ 7A)",  arguments: loadJsonTests(named: "dd cb __ 7a", range: 0...testCycles-1))
        func test_BIT_7_CON_IX_D_7A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IX+$d) (0xDDCB __ 7B)",  arguments: loadJsonTests(named: "dd cb __ 7b", range: 0...testCycles-1))
        func test_BIT_7_CON_IX_D_7B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IX+$d) (0xDDCB __ 7C)",  arguments: loadJsonTests(named: "dd cb __ 7c", range: 0...testCycles-1))
        func test_BIT_7_CON_IX_D_7C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IX+$d) (0xDDCB __ 7D)",  arguments: loadJsonTests(named: "dd cb __ 7d", range: 0...testCycles-1))
        func test_BIT_7_CON_IX_D_7D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IX+$d) (0xDDCB __ 7F)",  arguments: loadJsonTests(named: "dd cb __ 7f", range: 0...testCycles-1))
        func test_BIT_7_CON_IX_D_7F(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IX+$d),B (0xDDCB __ 80)",  arguments: loadJsonTests(named: "dd cb __ 80", range: 0...testCycles-1))
        func test_RES_0_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IX+$d),C (0xDDCB __ 81)",  arguments: loadJsonTests(named: "dd cb __ 81", range: 0...testCycles-1))
        func test_RES_0_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IX+$d),D (0xDDCB __ 82)",  arguments: loadJsonTests(named: "dd cb __ 82", range: 0...testCycles-1))
        func test_RES_0_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IX+$d),E (0xDDCB __ 83)",  arguments: loadJsonTests(named: "dd cb __ 83", range: 0...testCycles-1))
        func test_RES_0_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IX+$d),H (0xDDCB __ 84)",  arguments: loadJsonTests(named: "dd cb __ 84", range: 0...testCycles-1))
        func test_RES_0_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IX+$d),L (0xDDCB __ 85)",  arguments: loadJsonTests(named: "dd cb __ 85", range: 0...testCycles-1))
        func test_RES_0_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IX+$d),A (0xDDCB __ 87)",  arguments: loadJsonTests(named: "dd cb __ 87", range: 0...testCycles-1))
        func test_RES_0_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IX+$d),B (0xDDCB __ 88)",  arguments: loadJsonTests(named: "dd cb __ 88", range: 0...testCycles-1))
        func test_RES_1_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IX+$d),C (0xDDCB __ 89)",  arguments: loadJsonTests(named: "dd cb __ 89", range: 0...testCycles-1))
        func test_RES_1_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IX+$d),D (0xDDCB __ 8A)",  arguments: loadJsonTests(named: "dd cb __ 8a", range: 0...testCycles-1))
        func test_RES_1_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IX+$d),E (0xDDCB __ 8B)",  arguments: loadJsonTests(named: "dd cb __ 8b", range: 0...testCycles-1))
        func test_RES_1_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IX+$d),H (0xDDCB __ 8C)",  arguments: loadJsonTests(named: "dd cb __ 8c", range: 0...testCycles-1))
        func test_RES_1_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IX+$d),L (0xDDCB __ 8D)",  arguments: loadJsonTests(named: "dd cb __ 8d", range: 0...testCycles-1))
        func test_RES_1_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IX+$d),A (0xDDCB __ 8F)",  arguments: loadJsonTests(named: "dd cb __ 8f", range: 0...testCycles-1))
        func test_RES_1_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IX+$d),B (0xDDCB __ 90)",  arguments: loadJsonTests(named: "dd cb __ 90", range: 0...testCycles-1))
        func test_RES_2_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IX+$d),C (0xDDCB __ 91)",  arguments: loadJsonTests(named: "dd cb __ 91", range: 0...testCycles-1))
        func test_RES_2_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IX+$d),D (0xDDCB __ 92)",  arguments: loadJsonTests(named: "dd cb __ 92", range: 0...testCycles-1))
        func test_RES_2_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IX+$d),E (0xDDCB __ 93)",  arguments: loadJsonTests(named: "dd cb __ 93", range: 0...testCycles-1))
        func test_RES_2_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IX+$d),H (0xDDCB __ 94)",  arguments: loadJsonTests(named: "dd cb __ 94", range: 0...testCycles-1))
        func test_RES_2_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IX+$d),L (0xDDCB __ 95)",  arguments: loadJsonTests(named: "dd cb __ 95", range: 0...testCycles-1))
        func test_RES_2_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IX+$d),A (0xDDCB __ 97)",  arguments: loadJsonTests(named: "dd cb __ 97", range: 0...testCycles-1))
        func test_RES_2_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IX+$d),B (0xDDCB __ 98)",  arguments: loadJsonTests(named: "dd cb __ 98", range: 0...testCycles-1))
        func test_RES_3_CON_IX_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IX+$d),C (0xDDCB __ 99)",  arguments: loadJsonTests(named: "dd cb __ 99", range: 0...testCycles-1))
        func test_RES_3_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IX+$d),D (0xDDCB __ 9A)",  arguments: loadJsonTests(named: "dd cb __ 9a", range: 0...testCycles-1))
        func test_RES_3_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IX+$d),E (0xDDCB __ 9B)",  arguments: loadJsonTests(named: "dd cb __ 9b", range: 0...testCycles-1))
        func test_RES_3_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IX+$d),H (0xDDCB __ 9C)",  arguments: loadJsonTests(named: "dd cb __ 9c", range: 0...testCycles-1))
        func test_RES_3_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IX+$d),L (0xDDCB __ 9D)",  arguments: loadJsonTests(named: "dd cb __ 9d", range: 0...testCycles-1))
        func test_RES_3_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IX+$d),A (0xDDCB __ 9F)",  arguments: loadJsonTests(named: "dd cb __ 9f", range: 0...testCycles-1))
        func test_RES_3_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IX+$d),B (0xDDCB __ A0)",  arguments: loadJsonTests(named: "dd cb __ a0", range: 0...testCycles-1))
        func test_RES_4_CON_IX_D_B (testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IX+$d),C (0xDDCB __ A1)",  arguments: loadJsonTests(named: "dd cb __ a1", range: 0...testCycles-1))
        func test_RES_4_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IX+$d),D (0xDDCB __ A2)",  arguments: loadJsonTests(named: "dd cb __ a2", range: 0...testCycles-1))
        func test_RES_4_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IX+$d),E (0xDDCB __ A3)",  arguments: loadJsonTests(named: "dd cb __ a3", range: 0...testCycles-1))
        func test_RES_4_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IX+$d),H (0xDDCB __ A4)",  arguments: loadJsonTests(named: "dd cb __ a4", range: 0...testCycles-1))
        func test_RES_4_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IX+$d),L (0xDDCB __ A5)",  arguments: loadJsonTests(named: "dd cb __ a5", range: 0...testCycles-1))
        func test_RES_4_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IX+$d),A (0xDDCB __ A7)",  arguments: loadJsonTests(named: "dd cb __ a7", range: 0...testCycles-1))
        func test_RES_4_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IX+$d),B (0xDDCB __ A8)",  arguments: loadJsonTests(named: "dd cb __ a8", range: 0...testCycles-1))
        func test_RES_5_CON_IX_D_B (testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IX+$d),C (0xDDCB __ A9)",  arguments: loadJsonTests(named: "dd cb __ a9", range: 0...testCycles-1))
        func test_RES_5_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IX+$d),D (0xDDCB __ AA)",  arguments: loadJsonTests(named: "dd cb __ aa", range: 0...testCycles-1))
        func test_RES_5_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IX+$d),E (0xDDCB __ AB)",  arguments: loadJsonTests(named: "dd cb __ ab", range: 0...testCycles-1))
        func test_RES_5_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IX+$d),H (0xDDCB __ AC)",  arguments: loadJsonTests(named: "dd cb __ ac", range: 0...testCycles-1))
        func test_RES_5_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IX+$d),L (0xDDCB __ AD)",  arguments: loadJsonTests(named: "dd cb __ ad", range: 0...testCycles-1))
        func test_RES_5_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IX+$d),A (0xDDCB __ AF)",  arguments: loadJsonTests(named: "dd cb __ af", range: 0...testCycles-1))
        func test_RES_5_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IX+$d),B (0xDDCB __ B0)",  arguments: loadJsonTests(named: "dd cb __ b0", range: 0...testCycles-1))
        func test_RES_6_CON_IX_D_B (testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IX+$d),C (0xDDCB __ B1)",  arguments: loadJsonTests(named: "dd cb __ b1", range: 0...testCycles-1))
        func test_RES_6_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IX+$d),D (0xDDCB __ B2)",  arguments: loadJsonTests(named: "dd cb __ b2", range: 0...testCycles-1))
        func test_RES_6_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IX+$d),E (0xDDCB __ B3)",  arguments: loadJsonTests(named: "dd cb __ b3", range: 0...testCycles-1))
        func test_RES_6_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IX+$d),H (0xDDCB __ B4)",  arguments: loadJsonTests(named: "dd cb __ b4", range: 0...testCycles-1))
        func test_RES_6_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IX+$d),L (0xDDCB __ B5)",  arguments: loadJsonTests(named: "dd cb __ b5", range: 0...testCycles-1))
        func test_RES_6_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IX+$d),A (0xDDCB __ B7)",  arguments: loadJsonTests(named: "dd cb __ b7", range: 0...testCycles-1))
        func test_RES_6_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IX+$d),B (0xDDCB __ B8)",  arguments: loadJsonTests(named: "dd cb __ b8", range: 0...testCycles-1))
        func test_RES_7_CON_IX_D_B (testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IX+$d),C (0xDDCB __ B9)",  arguments: loadJsonTests(named: "dd cb __ b9", range: 0...testCycles-1))
        func test_RES_7_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IX+$d),D (0xDDCB __ BA)",  arguments: loadJsonTests(named: "dd cb __ ba", range: 0...testCycles-1))
        func test_RES_7_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IX+$d),E (0xDDCB __ BB)",  arguments: loadJsonTests(named: "dd cb __ bb", range: 0...testCycles-1))
        func test_RES_7_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IX+$d),H (0xDDCB __ BC)",  arguments: loadJsonTests(named: "dd cb __ bc", range: 0...testCycles-1))
        func test_RES_7_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IX+$d),L (0xDDCB __ BD)",  arguments: loadJsonTests(named: "dd cb __ bd", range: 0...testCycles-1))
        func test_RES_7_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IX+$d),A (0xDDCB __ BF)",  arguments: loadJsonTests(named: "dd cb __ bf", range: 0...testCycles-1))
        func test_RES_7_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IX+$d),B (0xDDCB __ C0)",  arguments: loadJsonTests(named: "dd cb __ c0", range: 0...testCycles-1))
        func test_SET_0_CON_IX_D_B (testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IX+$d),C (0xDDCB __ C1)",  arguments: loadJsonTests(named: "dd cb __ c1", range: 0...testCycles-1))
        func test_SET_0_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IX+$d),D (0xDDCB __ C2)",  arguments: loadJsonTests(named: "dd cb __ c2", range: 0...testCycles-1))
        func test_SET_0_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IX+$d),E (0xDDCB __ C3)",  arguments: loadJsonTests(named: "dd cb __ c3", range: 0...testCycles-1))
        func test_SET_0_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IX+$d),H (0xDDCB __ C4)",  arguments: loadJsonTests(named: "dd cb __ c4", range: 0...testCycles-1))
        func test_SET_0_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IX+$d),L (0xDDCB __ C5)",  arguments: loadJsonTests(named: "dd cb __ c5", range: 0...testCycles-1))
        func test_SET_0_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IX+$d),A (0xDDCB __ C7)",  arguments: loadJsonTests(named: "dd cb __ c7", range: 0...testCycles-1))
        func test_SET_0_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IX+$d),B (0xDDCB __ C8)",  arguments: loadJsonTests(named: "dd cb __ c8", range: 0...testCycles-1))
        func test_SET_1_CON_IX_D_B (testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IX+$d),C (0xDDCB __ C9)",  arguments: loadJsonTests(named: "dd cb __ c9", range: 0...testCycles-1))
        func test_SET_1_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IX+$d),D (0xDDCB __ CA)",  arguments: loadJsonTests(named: "dd cb __ ca", range: 0...testCycles-1))
        func test_SET_1_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IX+$d),E (0xDDCB __ CB)",  arguments: loadJsonTests(named: "dd cb __ cb", range: 0...testCycles-1))
        func test_SET_1_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IX+$d),H (0xDDCB __ CC)",  arguments: loadJsonTests(named: "dd cb __ cc", range: 0...testCycles-1))
        func test_SET_1_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IX+$d),L (0xDDCB __ CD)",  arguments: loadJsonTests(named: "dd cb __ cd", range: 0...testCycles-1))
        func test_SET_1_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IX+$d),A (0xDDCB __ CF)",  arguments: loadJsonTests(named: "dd cb __ cf", range: 0...testCycles-1))
        func test_SET_1_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IX+$d),B (0xDDCB __ D0)",  arguments: loadJsonTests(named: "dd cb __ d0", range: 0...testCycles-1))
        func test_SET_2_CON_IX_D_B (testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IX+$d),C (0xDDCB __ D1)",  arguments: loadJsonTests(named: "dd cb __ d1", range: 0...testCycles-1))
        func test_SET_2_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IX+$d),D (0xDDCB __ D2)",  arguments: loadJsonTests(named: "dd cb __ d2", range: 0...testCycles-1))
        func test_SET_2_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IX+$d),E (0xDDCB __ D3)",  arguments: loadJsonTests(named: "dd cb __ d3", range: 0...testCycles-1))
        func test_SET_2_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IX+$d),H (0xDDCB __ D4)",  arguments: loadJsonTests(named: "dd cb __ d4", range: 0...testCycles-1))
        func test_SET_2_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IX+$d),L (0xDDCB __ D5)",  arguments: loadJsonTests(named: "dd cb __ d5", range: 0...testCycles-1))
        func test_SET_2_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IX+$d),A (0xDDCB __ D7)",  arguments: loadJsonTests(named: "dd cb __ d7", range: 0...testCycles-1))
        func test_SET_2_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IX+$d),B (0xDDCB __ D8)",  arguments: loadJsonTests(named: "dd cb __ d8", range: 0...testCycles-1))
        func test_SET_3_CON_IX_D_B (testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IX+$d),C (0xDDCB __ D9)",  arguments: loadJsonTests(named: "dd cb __ d9", range: 0...testCycles-1))
        func test_SET_3_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IX+$d),D (0xDDCB __ DA)",  arguments: loadJsonTests(named: "dd cb __ da", range: 0...testCycles-1))
        func test_SET_3_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IX+$d),E (0xDDCB __ DB)",  arguments: loadJsonTests(named: "dd cb __ db", range: 0...testCycles-1))
        func test_SET_3_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IX+$d),H (0xDDCB __ DC)",  arguments: loadJsonTests(named: "dd cb __ dc", range: 0...testCycles-1))
        func test_SET_3_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IX+$d),L (0xDDCB __ DD)",  arguments: loadJsonTests(named: "dd cb __ dd", range: 0...testCycles-1))
        func test_SET_3_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IX+$d),A (0xDDCB __ DF)",  arguments: loadJsonTests(named: "dd cb __ df", range: 0...testCycles-1))
        func test_SET_3_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IX+$d),B (0xDDCB __ E0)",  arguments: loadJsonTests(named: "dd cb __ e0", range: 0...testCycles-1))
        func test_SET_4_CON_IX_D_B (testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IX+$d),C (0xDDCB __ E1)",  arguments: loadJsonTests(named: "dd cb __ e1", range: 0...testCycles-1))
        func test_SET_4_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IX+$d),D (0xDDCB __ E2)",  arguments: loadJsonTests(named: "dd cb __ e2", range: 0...testCycles-1))
        func test_SET_4_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IX+$d),E (0xDDCB __ E3)",  arguments: loadJsonTests(named: "dd cb __ e3", range: 0...testCycles-1))
        func test_SET_4_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IX+$d),H (0xDDCB __ E4)",  arguments: loadJsonTests(named: "dd cb __ e4", range: 0...testCycles-1))
        func test_SET_4_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IX+$d),L (0xDDCB __ E5)",  arguments: loadJsonTests(named: "dd cb __ e5", range: 0...testCycles-1))
        func test_SET_4_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IX+$d),A (0xDDCB __ E7)",  arguments: loadJsonTests(named: "dd cb __ e7", range: 0...testCycles-1))
        func test_SET_4_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IX+$d),B (0xDDCB __ E8)",  arguments: loadJsonTests(named: "dd cb __ e8", range: 0...testCycles-1))
        func test_SET_5_CON_IX_D_B (testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IX+$d),C (0xDDCB __ E9)",  arguments: loadJsonTests(named: "dd cb __ e9", range: 0...testCycles-1))
        func test_SET_5_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IX+$d),D (0xDDCB __ EA)",  arguments: loadJsonTests(named: "dd cb __ ea", range: 0...testCycles-1))
        func test_SET_5_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IX+$d),E (0xDDCB __ EB)",  arguments: loadJsonTests(named: "dd cb __ eb", range: 0...testCycles-1))
        func test_SET_5_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IX+$d),H (0xDDCB __ EC)",  arguments: loadJsonTests(named: "dd cb __ ec", range: 0...testCycles-1))
        func test_SET_5_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IX+$d),L (0xDDCB __ ED)",  arguments: loadJsonTests(named: "dd cb __ ed", range: 0...testCycles-1))
        func test_SET_5_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IX+$d),A (0xDDCB __ EF)",  arguments: loadJsonTests(named: "dd cb __ ef", range: 0...testCycles-1))
        func test_SET_5_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IX+$d),B (0xDDCB __ F0)",  arguments: loadJsonTests(named: "dd cb __ f0", range: 0...testCycles-1))
        func test_SET_6_CON_IX_D_B (testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IX+$d),C (0xDDCB __ F1)",  arguments: loadJsonTests(named: "dd cb __ f1", range: 0...testCycles-1))
        func test_SET_6_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IX+$d),D (0xDDCB __ F2)",  arguments: loadJsonTests(named: "dd cb __ f2", range: 0...testCycles-1))
        func test_SET_6_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IX+$d),E (0xDDCB __ F3)",  arguments: loadJsonTests(named: "dd cb __ f3", range: 0...testCycles-1))
        func test_SET_6_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IX+$d),H (0xDDCB __ F4)",  arguments: loadJsonTests(named: "dd cb __ f4", range: 0...testCycles-1))
        func test_SET_6_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IX+$d),L (0xDDCB __ F5)",  arguments: loadJsonTests(named: "dd cb __ f5", range: 0...testCycles-1))
        func test_SET_6_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IX+$d),A (0xDDCB __ F7)",  arguments: loadJsonTests(named: "dd cb __ f7", range: 0...testCycles-1))
        func test_SET_6_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IX+$d),B (0xDDCB __ F8)",  arguments: loadJsonTests(named: "dd cb __ f8", range: 0...testCycles-1))
        func test_SET_7_CON_IX_D_B (testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IX+$d),C (0xDDCB __ F9)",  arguments: loadJsonTests(named: "dd cb __ f9", range: 0...testCycles-1))
        func test_SET_7_CON_IX_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IX+$d),D (0xDDCB __ FA)",  arguments: loadJsonTests(named: "dd cb __ fa", range: 0...testCycles-1))
        func test_SET_7_CON_IX_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IX+$d),E (0xDDCB __ FB)",  arguments: loadJsonTests(named: "dd cb __ fb", range: 0...testCycles-1))
        func test_SET_7_CON_IX_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IX+$d),H (0xDDCB __ FC)",  arguments: loadJsonTests(named: "dd cb __ fc", range: 0...testCycles-1))
        func test_SET_7_CON_IX_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IX+$d),L (0xDDCB __ FD)",  arguments: loadJsonTests(named: "dd cb __ fd", range: 0...testCycles-1))
        func test_SET_7_CON_IX_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IX+$d),A (0xDDCB __ FF)",  arguments: loadJsonTests(named: "dd cb __ ff", range: 0...testCycles-1))
        func test_SET_7_CON_IX_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Undocumented Extended Opcodes ED")
    struct UndocumentExtendedOpcodesED: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate LD ($nn),HL (0xED63)",  arguments: loadJsonTests(named: "ed 63", range: 0...testCycles-1))
        func test_LD_CON_NN_HL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD HL,($nn) (0xED6B)",  arguments: loadJsonTests(named: "ed 6B", range: 0...testCycles-1))
        func test_LD_HL_CON_NN(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate IN (C) (0xED70)",  arguments: loadJsonTests(named: "ed 70", range: 0...testCycles-1))
        func test_IN_CON_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OUT (C),0 (0xED71)",  arguments: loadJsonTests(named: "ed 71", range: 0...testCycles-1))
        func test_OUT_CON_C_0(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Undocumented Extended Opcodes FD")
    struct UndocumentExtendedOpcodesFD: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate INC B (0xFD04)",  arguments: loadJsonTests(named: "fd 04", range: 0...testCycles-1))
        func test_INC_B_FD04(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC B (0xFD05)",  arguments: loadJsonTests(named: "fd 05", range: 0...testCycles-1))
        func test_DEC_B_FD05(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,$n (0xFD06)",  arguments: loadJsonTests(named: "fd 06", range: 0...testCycles-1))
        func test_LD_B_N_FD06(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC C (0xFD0C)",  arguments: loadJsonTests(named: "fd 0c", range: 0...testCycles-1))
        func test_INC_C_FD0C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC C (0xFD0D)",  arguments: loadJsonTests(named: "fd 0d", range: 0...testCycles-1))
        func test_DEC_C_FD0D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,$n (0xFD0E)",  arguments: loadJsonTests(named: "fd 0e", range: 0...testCycles-1))
        func test_LD_C_N_FD0E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC D (0xFD14)",  arguments: loadJsonTests(named: "fd 14", range: 0...testCycles-1))
        func test_INC_D_FD14(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC D (0xFD15)",  arguments: loadJsonTests(named: "fd 15", range: 0...testCycles-1))
        func test_DEC_D_FD15(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,$n (0xFD16)",  arguments: loadJsonTests(named: "fd 16", range: 0...testCycles-1))
        func test_LD_D_N_FD16(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC E (0xFD1C)",  arguments: loadJsonTests(named: "fd 1c", range: 0...testCycles-1))
        func test_INC_E_FD1C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC E (0xFD1D)",  arguments: loadJsonTests(named: "fd 1d", range: 0...testCycles-1))
        func test_DEC_E_FD1D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,$n (0xFD1E)",  arguments: loadJsonTests(named: "fd 1e", range: 0...testCycles-1))
        func test_LD_E_N_FD1E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC IYH (0xFD24)",  arguments: loadJsonTests(named: "fd 24", range: 0...testCycles-1))
        func test_INC_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC IYH (0xFD25)",  arguments: loadJsonTests(named: "fd 25", range: 0...testCycles-1))
        func test_DEC_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYH,$n (0xFD26)",  arguments: loadJsonTests(named: "fd 26", range: 0...testCycles-1))
        func test_LD_IYH_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC IYL (0xFD2C)",  arguments: loadJsonTests(named: "fd 2c", range: 0...testCycles-1))
        func test_INC_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC IYL (0xFD2D)",  arguments: loadJsonTests(named: "fd 2d", range: 0...testCycles-1))
        func test_DEC_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYL,$n (0xFD2E)",  arguments: loadJsonTests(named: "fd 2e", range: 0...testCycles-1))
        func test_LD_IYL_N(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate INC A (0xFD3C)",  arguments: loadJsonTests(named: "fd 3c", range: 0...testCycles-1))
        func test_INC_A_FD3XC(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate DEC A (0xFD3D)",  arguments: loadJsonTests(named: "fd 3d", range: 0...testCycles-1))
        func test_DEC_A_FD3D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,$n (0xFD3E)",  arguments: loadJsonTests(named: "fd 3e", range: 0...testCycles-1))
        func test_LD_A_N_FD3E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,B (0xFD40)",  arguments: loadJsonTests(named: "fd 40", range: 0...testCycles-1))
        func test_LD_B_B_FD40(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,C (0xFD41)",  arguments: loadJsonTests(named: "fd 41", range: 0...testCycles-1))
        func test_LD_B_C_FD41(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,D (0xFD42)",  arguments: loadJsonTests(named: "fd 42", range: 0...testCycles-1))
        func test_LD_B_D_FD42(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,E (0xFD43)",  arguments: loadJsonTests(named: "fd 43", range: 0...testCycles-1))
        func test_LD_B_E_FD43(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,IYH (0xFD44)",  arguments: loadJsonTests(named: "fd 44", range: 0...testCycles-1))
        func test_LD_B_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,IYL (0xFD45)",  arguments: loadJsonTests(named: "fd 45", range: 0...testCycles-1))
        func test_LD_B_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD B,A (0xFD47)",  arguments: loadJsonTests(named: "fd 47", range: 0...testCycles-1))
        func test_LD_B_A_FD47(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,B (0xFD48)",  arguments: loadJsonTests(named: "fd 48", range: 0...testCycles-1))
        func test_LD_C_B_FD48(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,C (0xFD49)",  arguments: loadJsonTests(named: "fd 49", range: 0...testCycles-1))
        func test_LD_C_C_FD49(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,D (0xFD4A)",  arguments: loadJsonTests(named: "fd 4a", range: 0...testCycles-1))
        func test_LD_C_D_FD4A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,E (0xFD4B)",  arguments: loadJsonTests(named: "fd 4b", range: 0...testCycles-1))
        func test_LD_C_E_FD4B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,IYH (0xFD4C)",  arguments: loadJsonTests(named: "fd 4c", range: 0...testCycles-1))
        func test_LD_C_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,IYL (0xFD4D)",  arguments: loadJsonTests(named: "fd 4d", range: 0...testCycles-1))
        func test_LD_C_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD C,A (0xFD4F)",  arguments: loadJsonTests(named: "fd 4f", range: 0...testCycles-1))
        func test_LD_C_A_FD4F(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,B (0xFD50)",  arguments: loadJsonTests(named: "fd 50", range: 0...testCycles-1))
        func test_LD_D_B_FD50(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,C (0xFD51)",  arguments: loadJsonTests(named: "fd 51", range: 0...testCycles-1))
        func test_LD_D_C_FD51(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,D (0xFD52)",  arguments: loadJsonTests(named: "fd 52", range: 0...testCycles-1))
        func test_LD_D_D_FD52(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,E (0xFD53)",  arguments: loadJsonTests(named: "fd 53", range: 0...testCycles-1))
        func test_LD_D_E_FD53(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,IYH (0xFD54)",  arguments: loadJsonTests(named: "fd 54", range: 0...testCycles-1))
        func test_LD_D_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,IYL (0xFD55)",  arguments: loadJsonTests(named: "fd 55", range: 0...testCycles-1))
        func test_LD_D_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD D,A (0xFD57)",  arguments: loadJsonTests(named: "fd 57", range: 0...testCycles-1))
        func test_LD_D_A_FD57(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,B (0xFD58)",  arguments: loadJsonTests(named: "fd 58", range: 0...testCycles-1))
        func test_LD_E_B_FD58(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,C (0xFD59)",  arguments: loadJsonTests(named: "fd 59", range: 0...testCycles-1))
        func test_LD_E_C_FD59(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,D (0xFD5A)",  arguments: loadJsonTests(named: "fd 5a", range: 0...testCycles-1))
        func test_LD_E_D_FD5A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,E (0xFD5B)",  arguments: loadJsonTests(named: "fd 5b", range: 0...testCycles-1))
        func test_LD_E_E_FD5B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,IYH (0xFD5C)",  arguments: loadJsonTests(named: "fd 5c", range: 0...testCycles-1))
        func test_LD_E_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,IYL (0xFD5D)",  arguments: loadJsonTests(named: "fd 5d", range: 0...testCycles-1))
        func test_LD_E_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD E,A (0xFD5F)",  arguments: loadJsonTests(named: "fd 5f", range: 0...testCycles-1))
        func test_LD_E_A_FD5F(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYH,B (0xFD60)",  arguments: loadJsonTests(named: "fd 60", range: 0...testCycles-1))
        func test_LD_IYH_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYH,C (0xFD61)",  arguments: loadJsonTests(named: "fd 61", range: 0...testCycles-1))
        func test_LD_IYH_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYH,D (0xFD62)",  arguments: loadJsonTests(named: "fd 62", range: 0...testCycles-1))
        func test_LD_IYH_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYH,E (0xFD63)",  arguments: loadJsonTests(named: "fd 63", range: 0...testCycles-1))
        func test_LD_IYH_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYH,IYH (0xFD64)",  arguments: loadJsonTests(named: "fd 64", range: 0...testCycles-1))
        func test_LD_IYH_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYH,IYL (0xFD65)",  arguments: loadJsonTests(named: "fd 65", range: 0...testCycles-1))
        func test_LD_IYH_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYH,A (0xFD67)",  arguments: loadJsonTests(named: "fd 67", range: 0...testCycles-1))
        func test_LD_IYH_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYL,B (0xFD68)",  arguments: loadJsonTests(named: "fd 68", range: 0...testCycles-1))
        func test_LD_IYL_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYL,C (0xFD69)",  arguments: loadJsonTests(named: "fd 69", range: 0...testCycles-1))
        func test_LD_IYL_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYL,D (0xFD6A)",  arguments: loadJsonTests(named: "fd 6a", range: 0...testCycles-1))
        func test_LD_IYL_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYL,E (0xFD6B)",  arguments: loadJsonTests(named: "fd 6b", range: 0...testCycles-1))
        func test_LD_IYL_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYL,IYH (0xFD6C)",  arguments: loadJsonTests(named: "fd 6c", range: 0...testCycles-1))
        func test_LD_IYL_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYL,IYL (0xFD6D)",  arguments: loadJsonTests(named: "fd 6d", range: 0...testCycles-1))
        func test_LD_IYL_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD IYL,A (0xFD6F)",  arguments: loadJsonTests(named: "fd 6f", range: 0...testCycles-1))
        func test_LD_IYL_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,B (0xFD78)",  arguments: loadJsonTests(named: "fd 78", range: 0...testCycles-1))
        func test_LD_A_B_FD78(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,C (0xFD79)",  arguments: loadJsonTests(named: "fd 79", range: 0...testCycles-1))
        func test_LD_A_C_FD79(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,D (0xFD7A)",  arguments: loadJsonTests(named: "fd 7a", range: 0...testCycles-1))
        func test_LD_A_D_FD7A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,E (0xFD7B)",  arguments: loadJsonTests(named: "fd 7b", range: 0...testCycles-1))
        func test_LD_A_E_FD7B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,IYH (0xFD7C)",  arguments: loadJsonTests(named: "fd 7c", range: 0...testCycles-1))
        func test_LD_A_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,IYL (0xFD7D)",  arguments: loadJsonTests(named: "fd 7d", range: 0...testCycles-1))
        func test_LD_A_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate LD A,A (0xFD7F)",  arguments: loadJsonTests(named: "fd 7f", range: 0...testCycles-1))
        func test_LD_A_A_FD7F(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,B (0xFD80)",  arguments: loadJsonTests(named: "fd 80", range: 0...testCycles-1))
        func test_ADD_A_B_FD80(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,C (0xFD81)",  arguments: loadJsonTests(named: "fd 81", range: 0...testCycles-1))
        func test_ADD_A_C_FD81(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,D (0xFD82)",  arguments: loadJsonTests(named: "fd 82", range: 0...testCycles-1))
        func test_ADD_A_D_FD82(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,E (0xFD83)",  arguments: loadJsonTests(named: "fd 83", range: 0...testCycles-1))
        func test_ADD_A_E_FD83(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,IYH (0xFD84)",  arguments: loadJsonTests(named: "fd 84", range: 0...testCycles-1))
        func test_ADD_A_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,IYL (0xFD85)",  arguments: loadJsonTests(named: "fd 85", range: 0...testCycles-1))
        func test_ADD_A_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADD A,A (0xFD87)",  arguments: loadJsonTests(named: "fd 87", range: 0...testCycles-1))
        func test_ADD_A_A_FD87(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,B (0xFD88)",  arguments: loadJsonTests(named: "fd 88", range: 0...testCycles-1))
        func test_ADC_A_B_FD88(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,C (0xFD89)",  arguments: loadJsonTests(named: "fd 89", range: 0...testCycles-1))
        func test_ADC_A_C_FD89(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,D (0xFD8A)",  arguments: loadJsonTests(named: "fd 8a", range: 0...testCycles-1))
        func test_ADC_A_D_FD8A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,E (0xFD8B)",  arguments: loadJsonTests(named: "fd 8b", range: 0...testCycles-1))
        func test_ADC_A_E_FD8B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,IYH (0xFD8C)",  arguments: loadJsonTests(named: "fd 8c", range: 0...testCycles-1))
        func test_ADC_A_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,IYL (0xFD8D)",  arguments: loadJsonTests(named: "fd 8d", range: 0...testCycles-1))
        func test_ADC_A_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate ADC A,A (0xFD8F)",  arguments: loadJsonTests(named: "fd 8f", range: 0...testCycles-1))
        func test_ADC_A_A_FD8F(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB B (0xFD90)",  arguments: loadJsonTests(named: "fd 90", range: 0...testCycles-1))
        func test_SUB_B_FD90(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB C (0xFD91)",  arguments: loadJsonTests(named: "fd 91", range: 0...testCycles-1))
        func test_SUB_C_FD91(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB D (0xFD92)",  arguments: loadJsonTests(named: "fd 92", range: 0...testCycles-1))
        func test_SUB_D_FD92(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB E (0xFD93)",  arguments: loadJsonTests(named: "fd 93", range: 0...testCycles-1))
        func test_SUB_E_FD93(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB IYH (0xFD94)",  arguments: loadJsonTests(named: "fd 94", range: 0...testCycles-1))
        func test_SUB_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB IYL (0xFD95)",  arguments: loadJsonTests(named: "fd 95", range: 0...testCycles-1))
        func test_SUB_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SUB A (0xFD97)",  arguments: loadJsonTests(named: "fd 97", range: 0...testCycles-1))
        func test_SUB_A_FD97(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,B (0xFD98)",  arguments: loadJsonTests(named: "fd 98", range: 0...testCycles-1))
        func test_SBC_A_B_FD98(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,C (0xFD99)",  arguments: loadJsonTests(named: "fd 99", range: 0...testCycles-1))
        func test_SBC_A_C_FD99(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,D (0xFD9A)",  arguments: loadJsonTests(named: "fd 9a", range: 0...testCycles-1))
        func test_SBC_A_D_FD9A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,E (0xFD9B)",  arguments: loadJsonTests(named: "fd 9b", range: 0...testCycles-1))
        func test_SBC_A_E_FD9B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,IYH (0xFD9C)",  arguments: loadJsonTests(named: "fd 9c", range: 0...testCycles-1))
        func test_SBC_A_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,IYL (0xFD9D)",  arguments: loadJsonTests(named: "fd 9d", range: 0...testCycles-1))
        func test_SBC_A_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SBC A,A (0xFD9F)",  arguments: loadJsonTests(named: "fd 9f", range: 0...testCycles-1))
        func test_SBC_A_A_FD9F(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND B (0xFDA0)",  arguments: loadJsonTests(named: "fd A0", range: 0...testCycles-1))
        func test_AND_B_FDA0(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND C (0xFDA1)",  arguments: loadJsonTests(named: "fd a1", range: 0...testCycles-1))
        func test_AND_C_FDA1(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND D (0xFDA2)",  arguments: loadJsonTests(named: "fd a", range: 0...testCycles-1))
        func test_AND_D_FDA2(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND E (0xFDA3)",  arguments: loadJsonTests(named: "fd a3", range: 0...testCycles-1))
        func test_AND_E_FDA3(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND IYH (0xFDA4)",  arguments: loadJsonTests(named: "fd a4", range: 0...testCycles-1))
        func test_AND_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND IYL (0xFDA5)",  arguments: loadJsonTests(named: "fd a5", range: 0...testCycles-1))
        func test_AND_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate AND A (0xFDA7)",  arguments: loadJsonTests(named: "fd a7", range: 0...testCycles-1))
        func test_AND_A_FDA7(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR B (0xFDA8)",  arguments: loadJsonTests(named: "fd a8", range: 0...testCycles-1))
        func test_XOR_B_FDA8(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR C (0xFDA9)",  arguments: loadJsonTests(named: "fd a9", range: 0...testCycles-1))
        func test_XOR_C_FDA9(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR D (0xFDAA)",  arguments: loadJsonTests(named: "fd aa", range: 0...testCycles-1))
        func test_XOR_D_FDAA(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR E (0xFDAB)",  arguments: loadJsonTests(named: "fd ab", range: 0...testCycles-1))
        func test_XOR_E_FDAB(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR IYH (0xFDAC)",  arguments: loadJsonTests(named: "fd ac", range: 0...testCycles-1))
        func test_XOR_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR IYL (0xFDAD)",  arguments: loadJsonTests(named: "fd ad", range: 0...testCycles-1))
        func test_XOR_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate XOR A (0xFDAF)",  arguments: loadJsonTests(named: "fd af", range: 0...testCycles-1))
        func test_XOR_A_FDAF(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR B (0xFDB0)",  arguments: loadJsonTests(named: "fd b0", range: 0...testCycles-1))
        func test_OR_B_FDB0(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR C (0xFDB1)",  arguments: loadJsonTests(named: "fd b1", range: 0...testCycles-1))
        func test_OR_C_FDB1(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR D (0xFDB2)",  arguments: loadJsonTests(named: "fd b2", range: 0...testCycles-1))
        func test_OR_D_FDB2(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR E (0xFDB3)",  arguments: loadJsonTests(named: "fd b3", range: 0...testCycles-1))
        func test_OR_E_FDB3(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR IYH (0xFDB4)",  arguments: loadJsonTests(named: "fd b4", range: 0...testCycles-1))
        func test_OR_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR IYL (0xFDB5)",  arguments: loadJsonTests(named: "fd b5", range: 0...testCycles-1))
        func test_OR_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate OR A (0xFDB7)",  arguments: loadJsonTests(named: "fd b7", range: 0...testCycles-1))
        func test_OR_A_FDB7(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP B (0xFDB8)",  arguments: loadJsonTests(named: "fd b8", range: 0...testCycles-1))
        func test_CP_B_FDB8(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP C (0xFDB9)",  arguments: loadJsonTests(named: "fd b9", range: 0...testCycles-1))
        func test_CP_C_FDB9(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP D (0xFDBA)",  arguments: loadJsonTests(named: "fd ba", range: 0...testCycles-1))
        func test_CP_D_FDBA(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP E (0xFDBB)",  arguments: loadJsonTests(named: "fd bb", range: 0...testCycles-1))
        func test_CP_E_FDBB(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP IYH (0xFDBC)",  arguments: loadJsonTests(named: "fd bc", range: 0...testCycles-1))
        func test_CP_IYH(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP IYL (0xFDBD)",  arguments: loadJsonTests(named: "fd bd", range: 0...testCycles-1))
        func test_CP_IYL(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate CP A (0xFDBF)",  arguments: loadJsonTests(named: "fd bf", range: 0...testCycles-1))
        func test_CP_A_FDBF(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
    
    @Suite("Undocumented Extended Opcodes FDCB")
    struct UndocumentExtendedOpcodesFDCB: testHelper
    {
        let parent = Z80Opcodes()
        
        @Test("Validate RLC (IY+$d),B (0xFDCB __ 00)",  arguments: loadJsonTests(named: "fd cb __ 00", range: 0...testCycles-1))
        func test_RLC_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RLC (IY+$d),C (0xFDCB __ 01)",  arguments: loadJsonTests(named: "fd cb __ 01", range: 0...testCycles-1))
        func test_RLC_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RLC (IY+$d),D (0xFDCB __ 02)",  arguments: loadJsonTests(named: "fd cb __ 02", range: 0...testCycles-1))
        func test_RLC_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RLC (IY+$d),E (0xFDCB __ 03)",  arguments: loadJsonTests(named: "fd cb __ 03", range: 0...testCycles-1))
        func test_RLC_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RLC (IY+$d),H (0xFDCB __ 04)",  arguments: loadJsonTests(named: "fd cb __ 04", range: 0...testCycles-1))
        func test_RLC_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RLC (IY+$d),L (0xFDCB __ 05)",  arguments: loadJsonTests(named: "fd cb __ 05", range: 0...testCycles-1))
        func test_RLC_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RLC (IY+$d),A (0xFDCB __ 07)",  arguments: loadJsonTests(named: "fd cb __ 07", range: 0...testCycles-1))
        func test_RLC_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IY+$d),B (0xFDCB __ 08)",  arguments: loadJsonTests(named: "fd cb __ 08", range: 0...testCycles-1))
        func test_RRC_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IY+$d),C (0xFDCB __ 09)",  arguments: loadJsonTests(named: "fd cb __ 09", range: 0...testCycles-1))
        func test_RRC_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IY+$d),D (0xFDCB __ 0A)",  arguments: loadJsonTests(named: "fd cb __ 0a", range: 0...testCycles-1))
        func test_RRC_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IY+$d),E (0xFDCB __ 0B)",  arguments: loadJsonTests(named: "fd cb __ 0b", range: 0...testCycles-1))
        func test_RRC_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IY+$d),H (0xFDCB __ 0C)",  arguments: loadJsonTests(named: "fd cb __ 0c", range: 0...testCycles-1))
        func test_RRC_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IY+$d),L (0xFDCB __ 0D)",  arguments: loadJsonTests(named: "fd cb __ 0d", range: 0...testCycles-1))
        func test_RRC_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RRC (IY+$d),A (0xFDCB __ 0F)",  arguments: loadJsonTests(named: "fd cb __ 0f", range: 0...testCycles-1))
        func test_RRC_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IY+$d),B (0xFDCB __ 10)",  arguments: loadJsonTests(named: "fd cb __ 10", range: 0...testCycles-1))
        func test_RL_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IY+$d),C (0xFDCB __ 11)",  arguments: loadJsonTests(named: "fd cb __ 11", range: 0...testCycles-1))
        func test_RL_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IY+$d),D (0xFDCB __ 12)",  arguments: loadJsonTests(named: "fd cb __ 12", range: 0...testCycles-1))
        func test_RL_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IY+$d),E (0xFDCB __ 13)",  arguments: loadJsonTests(named: "fd cb __ 13", range: 0...testCycles-1))
        func test_RL_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IY+$d),H (0xFDCB __ 14)",  arguments: loadJsonTests(named: "fd cb __ 14", range: 0...testCycles-1))
        func test_RL_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IY+$d),L (0xFDCB __ 15)",  arguments: loadJsonTests(named: "fd cb __ 15", range: 0...testCycles-1))
        func test_RL_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RL (IY+$d),A (0xFDCB __ 17)",  arguments: loadJsonTests(named: "fd cb __ 17", range: 0...testCycles-1))
        func test_RL_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IY+$d),B (0xFDCB __ 18)",  arguments: loadJsonTests(named: "fd cb __ 18", range: 0...testCycles-1))
        func test_RR_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IY+$d),C (0xFDCB __ 19)",  arguments: loadJsonTests(named: "fd cb __ 19", range: 0...testCycles-1))
        func test_RR_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IY+$d),D (0xFDCB __ 1A)",  arguments: loadJsonTests(named: "fd cb __ 1a", range: 0...testCycles-1))
        func test_RR_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IY+$d),E (0xFDCB __ 1B)",  arguments: loadJsonTests(named: "fd cb __ 1b", range: 0...testCycles-1))
        func test_RR_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IY+$d),H (0xFDCB __ 1C)",  arguments: loadJsonTests(named: "fd cb __ 1c", range: 0...testCycles-1))
        func test_RR_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IY+$d),L (0xFDCB __ 1D)",  arguments: loadJsonTests(named: "fd cb __ 1d", range: 0...testCycles-1))
        func test_RR_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RR (IY+$d),A (0xFDCB __ 1F)",  arguments: loadJsonTests(named: "fd cb __ 1f", range: 0...testCycles-1))
        func test_RR_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IY+$d),B (0xFDCB __ 20)",  arguments: loadJsonTests(named: "fd cb __ 20", range: 0...testCycles-1))
        func test_SLA_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IY+$d),C (0xFDCB __ 21)",  arguments: loadJsonTests(named: "fd cb __ 21", range: 0...testCycles-1))
        func test_SLA_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IY+$d),D (0xFDCB __ 22)",  arguments: loadJsonTests(named: "fd cb __ 22", range: 0...testCycles-1))
        func test_SLA_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IY+$d),E (0xFDCB __ 23)",  arguments: loadJsonTests(named: "fd cb __ 23", range: 0...testCycles-1))
        func test_SLA_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IY+$d),H (0xFDCB __ 24)",  arguments: loadJsonTests(named: "fd cb __ 24", range: 0...testCycles-1))
        func test_SLA_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IY+$d),L (0xFDCB __ 25)",  arguments: loadJsonTests(named: "fd cb __ 25", range: 0...testCycles-1))
        func test_SLA_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLA (IY+$d),A (0xFDCB __ 27)",  arguments: loadJsonTests(named: "fd cb __ 27", range: 0...testCycles-1))
        func test_SLA_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IY+$d),B (0xFDCB __ 28)",  arguments: loadJsonTests(named: "fd cb __ 28", range: 0...testCycles-1))
        func test_SRA_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IY+$d),C (0xFDCB __ 29)",  arguments: loadJsonTests(named: "fd cb __ 29", range: 0...testCycles-1))
        func test_SRA_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IY+$d),D (0xFDCB __ 2A)",  arguments: loadJsonTests(named: "fd cb __ 2a", range: 0...testCycles-1))
        func test_SRA_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IY+$d),E (0xFDCB __ 2B)",  arguments: loadJsonTests(named: "fd cb __ 2b", range: 0...testCycles-1))
        func test_SRA_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IY+$d),H (0xFDCB __ 2C)",  arguments: loadJsonTests(named: "fd cb __ 2c", range: 0...testCycles-1))
        func test_SRA_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IY+$d),L (0xFDCB __ 2D)",  arguments: loadJsonTests(named: "fd cb __ 2d", range: 0...testCycles-1))
        func test_SRA_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRA (IY+$d),A (0xFDCB __ 2F)",  arguments: loadJsonTests(named: "fd cb __ 2f", range: 0...testCycles-1))
        func test_SRA_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IY+$d),B (0xFDCB __ 30)",  arguments: loadJsonTests(named: "fd cb __ 30", range: 0...testCycles-1))
        func test_SLL_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IY+$d),C (0xFDCB __ 31)",  arguments: loadJsonTests(named: "fd cb __ 31", range: 0...testCycles-1))
        func test_SLL_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IY+$d),D (0xFDCB __ 32)",  arguments: loadJsonTests(named: "fd cb __ 32", range: 0...testCycles-1))
        func test_SLL_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IY+$d),E (0xFDCB __ 33)",  arguments: loadJsonTests(named: "fd cb __ 33", range: 0...testCycles-1))
        func test_SLL_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IY+$d),H (0xFDCB __ 34)",  arguments: loadJsonTests(named: "fd cb __ 34", range: 0...testCycles-1))
        func test_SLL_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IY+$d),L (0xFDCB __ 35)",  arguments: loadJsonTests(named: "fd cb __ 35", range: 0...testCycles-1))
        func test_SLL_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IY+$d) (0xFDCB __ 36)",  arguments: loadJsonTests(named: "fd cb __ 36", range: 0...testCycles-1))
        func test_SLL_CON_IY_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SLL (IY+$d),A (0xFDCB __ 37)",  arguments: loadJsonTests(named: "fd cb __ 37", range: 0...testCycles-1))
        func test_SLL_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IY+$d),B (0xFDCB __ 38)",  arguments: loadJsonTests(named: "fd cb __ 38", range: 0...testCycles-1))
        func test_SRL_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IY+$d),C (0xFDCB __ 39)",  arguments: loadJsonTests(named: "fd cb __ 39", range: 0...testCycles-1))
        func test_SRL_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IY+$d),D (0xFDCB __ 3A)",  arguments: loadJsonTests(named: "fd cb __ 3a", range: 0...testCycles-1))
        func test_SRL_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IY+$d),E (0xFDCB __ 3B)",  arguments: loadJsonTests(named: "fd cb __ 3b", range: 0...testCycles-1))
        func test_SRL_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IY+$d),H (0xFDCB __ 3C)",  arguments: loadJsonTests(named: "fd cb __ 3c", range: 0...testCycles-1))
        func test_SRL_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IY+$d),L (0xFDCB __ 3D)",  arguments: loadJsonTests(named: "fd cb __ 3d", range: 0...testCycles-1))
        func test_SRL_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SRL (IY+$d),A (0xFDCB __ 3F)",  arguments: loadJsonTests(named: "fd cb __ 3f", range: 0...testCycles-1))
        func test_SRL_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IY+$d) (0xFDCB __ 40)",  arguments: loadJsonTests(named: "fd cb __ 40", range: 0...testCycles-1))
        func test_BIT_0_CON_IY_D_40(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IY+$d) (0xFDCB __ 41)",  arguments: loadJsonTests(named: "fd cb __ 41", range: 0...testCycles-1))
        func test_BIT_0_CON_IY_D_41(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IY+$d) (0xFDCB __ 42)",  arguments: loadJsonTests(named: "fd cb __ 42", range: 0...testCycles-1))
        func test_BIT_0_CON_IY_D_42(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IY+$d) (0xFDCB __ 43)",  arguments: loadJsonTests(named: "fd cb __ 43", range: 0...testCycles-1))
        func test_BIT_0_CON_IY_D_43(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IY+$d) (0xFDCB __ 44)",  arguments: loadJsonTests(named: "fd cb __ 44", range: 0...testCycles-1))
        func test_BIT_0_CON_IY_D_44(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IY+$d) (0xFDCB __ 45)",  arguments: loadJsonTests(named: "fd cb __ 45", range: 0...testCycles-1))
        func test_BIT_0_CON_IY_D_45(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 0,(IY+$d) (0xFDCB __ 47)",  arguments: loadJsonTests(named: "fd cb __ 47", range: 0...testCycles-1))
        func test_BIT_0_CON_IY_D_47(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IY+$d) (0xFDCB __ 48)",  arguments: loadJsonTests(named: "fd cb __ 48", range: 0...testCycles-1))
        func test_BIT_1_CON_IY_D_48(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IY+$d) (0xFDCB __ 49)",  arguments: loadJsonTests(named: "fd cb __ 49", range: 0...testCycles-1))
        func test_BIT_1_CON_IY_D_49(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IY+$d) (0xFDCB __ 4A)",  arguments: loadJsonTests(named: "fd cb __ 4a", range: 0...testCycles-1))
        func test_BIT_1_CON_IY_D_4A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IY+$d) (0xFDCB __ 4B)",  arguments: loadJsonTests(named: "fd cb __ 4b", range: 0...testCycles-1))
        func test_BIT_1_CON_IY_D_4B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IY+$d) (0xFDCB __ 4C)",  arguments: loadJsonTests(named: "fd cb __ 4c", range: 0...testCycles-1))
        func test_BIT_1_CON_IY_D_4C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IY+$d) (0xFDCB __ 4D)",  arguments: loadJsonTests(named: "fd cb __ 4d", range: 0...testCycles-1))
        func test_BIT_1_CON_IY_D_4D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 1,(IY+$d) (0xFDCB __ 4F)",  arguments: loadJsonTests(named: "fd cb __ 4f", range: 0...testCycles-1))
        func test_BIT_1_CON_IY_D_4F(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IY+$d) (0xFDCB __ 50)",  arguments: loadJsonTests(named: "fd cb __ 50", range: 0...testCycles-1))
        func test_BIT_2_CON_IY_D_50(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IY+$d) (0xFDCB __ 51)",  arguments: loadJsonTests(named: "fd cb __ 51", range: 0...testCycles-1))
        func test_BIT_2_CON_IY_D_51(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IY+$d) (0xFDCB __ 52)",  arguments: loadJsonTests(named: "fd cb __ 52", range: 0...testCycles-1))
        func test_BIT_2_CON_IY_D_52(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IY+$d) (0xFDCB __ 53)",  arguments: loadJsonTests(named: "fd cb __ 53", range: 0...testCycles-1))
        func test_BIT_2_CON_IY_D_53(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IY+$d) (0xFDCB __ 54)",  arguments: loadJsonTests(named: "fd cb __ 54", range: 0...testCycles-1))
        func test_BIT_2_CON_IY_D_54(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IY+$d) (0xFDCB __ 55)",  arguments: loadJsonTests(named: "fd cb __ 55", range: 0...testCycles-1))
        func test_BIT_2_CON_IY_D_55(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 2,(IY+$d) (0xFDCB __ 57)",  arguments: loadJsonTests(named: "fd cb __ 57", range: 0...testCycles-1))
        func test_BIT_2_CON_IY_D_57(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IY+$d) (0xFDCB __ 58)",  arguments: loadJsonTests(named: "fd cb __ 58", range: 0...testCycles-1))
        func test_BIT_3_CON_IY_D_58(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IY+$d) (0xFDCB __ 59)",  arguments: loadJsonTests(named: "fd cb __ 59", range: 0...testCycles-1))
        func test_BIT_3_CON_IY_D_59(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IY+$d) (0xFDCB __ 5A)",  arguments: loadJsonTests(named: "fd cb __ 5a", range: 0...testCycles-1))
        func test_BIT_3_CON_IY_D_5A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IY+$d) (0xFDCB __ 5B)",  arguments: loadJsonTests(named: "fd cb __ 5b", range: 0...testCycles-1))
        func test_BIT_3_CON_IY_D_5B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IY+$d) (0xFDCB __ 5C)",  arguments: loadJsonTests(named: "fd cb __ 5c", range: 0...testCycles-1))
        func test_BIT_3_CON_IY_D_5C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IY+$d) (0xFDCB __ 5D)",  arguments: loadJsonTests(named: "fd cb __ 5d", range: 0...testCycles-1))
        func test_BIT_3_CON_IY_D_5D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 3,(IY+$d) (0xFDCB __ 5F)",  arguments: loadJsonTests(named: "fd cb __ 5f", range: 0...testCycles-1))
        func test_BIT_3_CON_IY_D_5F(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IY+$d) (0xFDCB __ 60)",  arguments: loadJsonTests(named: "fd cb __ 60", range: 0...testCycles-1))
        func test_BIT_4_CON_IY_D_60(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IY+$d) (0xFDCB __ 61)",  arguments: loadJsonTests(named: "fd cb __ 61", range: 0...testCycles-1))
        func test_BIT_4_CON_IY_D_61(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IY+$d) (0xFDCB __ 62)",  arguments: loadJsonTests(named: "fd cb __ 62", range: 0...testCycles-1))
        func test_BIT_4_CON_IY_D_62(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IY+$d) (0xFDCB __ 63)",  arguments: loadJsonTests(named: "fd cb __ 63", range: 0...testCycles-1))
        func test_BIT_4_CON_IY_D_63(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IY+$d) (0xFDCB __ 64)",  arguments: loadJsonTests(named: "fd cb __ 64", range: 0...testCycles-1))
        func test_BIT_4_CON_IY_D_64(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IY+$d) (0xFDCB __ 65)",  arguments: loadJsonTests(named: "fd cb __ 65", range: 0...testCycles-1))
        func test_BIT_4_CON_IY_D_65(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 4,(IY+$d) (0xFDCB __ 67)",  arguments: loadJsonTests(named: "fd cb __ 67", range: 0...testCycles-1))
        func test_BIT_4_CON_IY_D_67(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IY+$d) (0xFDCB __ 68)",  arguments: loadJsonTests(named: "fd cb __ 68", range: 0...testCycles-1))
        func test_BIT_5_CON_IY_D_68(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IY+$d) (0xFDCB __ 69)",  arguments: loadJsonTests(named: "fd cb __ 69", range: 0...testCycles-1))
        func test_BIT_5_CON_IY_D_69(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IY+$d) (0xFDCB __ 6A)",  arguments: loadJsonTests(named: "fd cb __ 6a", range: 0...testCycles-1))
        func test_BIT_5_CON_IY_6DA(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IY+$d) (0xFDCB __ 6B)",  arguments: loadJsonTests(named: "fd cb __ 6b", range: 0...testCycles-1))
        func test_BIT_5_CON_IY_D_6B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IY+$d) (0xFDCB __ 6C)",  arguments: loadJsonTests(named: "fd cb __ 6c", range: 0...testCycles-1))
        func test_BIT_5_CON_IY_D_6C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IY+$d) (0xFDCB __ 6D)",  arguments: loadJsonTests(named: "fd cb __ 6d", range: 0...testCycles-1))
        func test_BIT_5_CON_IY_D_6D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 5,(IY+$d) (0xFDCB __ 6F)",  arguments: loadJsonTests(named: "fd cb __ 6f", range: 0...testCycles-1))
        func test_BIT_5_CON_IY_D_6F(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IY+$d) (0xFDCB __ 70)",  arguments: loadJsonTests(named: "fd cb __ 70", range: 0...testCycles-1))
        func test_BIT_6_CON_IY_D_70(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IY+$d) (0xFDCB __ 71)",  arguments: loadJsonTests(named: "fd cb __ 71", range: 0...testCycles-1))
        func test_BIT_6_CON_IY_D_71(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IY+$d) (0xFDCB __ 72)",  arguments: loadJsonTests(named: "fd cb __ 72", range: 0...testCycles-1))
        func test_BIT_6_CON_IY_D_72(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IY+$d) (0xFDCB __ 73)",  arguments: loadJsonTests(named: "fd cb __ 73", range: 0...testCycles-1))
        func test_BIT_6_CON_IY_D_73(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IY+$d) (0xFDCB __ 74)",  arguments: loadJsonTests(named: "fd cb __ 74", range: 0...testCycles-1))
        func test_BIT_6_CON_IY_D_74(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IY+$d) (0xFDCB __ 75)",  arguments: loadJsonTests(named: "fd cb __ 75", range: 0...testCycles-1))
        func test_BIT_6_CON_IY_D_75(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 6,(IY+$d) (0xFDCB __ 77)",  arguments: loadJsonTests(named: "fd cb __ 77", range: 0...testCycles-1))
        func test_BIT_6_CON_IY_D_77(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IY+$d) (0xFDCB __ 78)",  arguments: loadJsonTests(named: "fd cb __ 78", range: 0...testCycles-1))
        func test_BIT_7_CON_IY_D_78(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IY+$d) (0xFDCB __ 79)",  arguments: loadJsonTests(named: "fd cb __ 79", range: 0...testCycles-1))
        func test_BIT_7_CON_IY_D_79(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IY+$d) (0xFDCB __ 7A)",  arguments: loadJsonTests(named: "fd cb __ 7a", range: 0...testCycles-1))
        func test_BIT_7_CON_IY_D_7A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IY+$d) (0xFDCB __ 7B)",  arguments: loadJsonTests(named: "fd cb __ 7b", range: 0...testCycles-1))
        func test_BIT_7_CON_IY_D_7B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IY+$d) (0xFDCB __ 7C)",  arguments: loadJsonTests(named: "fd cb __ 7c", range: 0...testCycles-1))
        func test_BIT_7_CON_IY_D_7C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IY+$d) (0xFDCB __ 7D)",  arguments: loadJsonTests(named: "fd cb __ 7d", range: 0...testCycles-1))
        func test_BIT_7_CON_IY_D_7D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate BIT 7,(IY+$d) (0xFDCB __ 7F)",  arguments: loadJsonTests(named: "fd cb __ 7f", range: 0...testCycles-1))
        func test_BIT_7_CON_IY_D_7F(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IY+$d),B (0xFDCB __ 80)",  arguments: loadJsonTests(named: "fd cb __ 80", range: 0...testCycles-1))
        func test_RES_0_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IY+$d),C (0xFDCB __ 81)",  arguments: loadJsonTests(named: "fd cb __ 81", range: 0...testCycles-1))
        func test_RES_0_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IY+$d),D (0xFDCB __ 82)",  arguments: loadJsonTests(named: "fd cb __ 82", range: 0...testCycles-1))
        func test_RES_0_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IY+$d),E (0xFDCB __ 83)",  arguments: loadJsonTests(named: "fd cb __ 83", range: 0...testCycles-1))
        func test_RES_0_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IY+$d),H (0xFDCB __ 84)",  arguments: loadJsonTests(named: "fd cb __ 84", range: 0...testCycles-1))
        func test_RES_0_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IY+$d),L (0xFDCB __ 85)",  arguments: loadJsonTests(named: "fd cb __ 85", range: 0...testCycles-1))
        func test_RES_0_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 0,(IY+$d),_A (0xFDCB __ 87)",  arguments: loadJsonTests(named: "fd cb __ 87", range: 0...testCycles-1))
        func test_RES_0_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IY+$d),B (0xFDCB __ 88)",  arguments: loadJsonTests(named: "fd cb __ 88", range: 0...testCycles-1))
        func test_RES_1_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IY+$d),C (0xFDCB __ 89)",  arguments: loadJsonTests(named: "fd cb __ 89", range: 0...testCycles-1))
        func test_RES_1_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IY+$d),D (0xFDCB __ 8A)",  arguments: loadJsonTests(named: "fd cb __ 8a", range: 0...testCycles-1))
        func test_RES_1_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IY+$d),E (0xFDCB __ 8B)",  arguments: loadJsonTests(named: "fd cb __ 8b", range: 0...testCycles-1))
        func test_RES_1_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IY+$d),H (0xFDCB __ 8C)",  arguments: loadJsonTests(named: "fd cb __ 8c", range: 0...testCycles-1))
        func test_RES_1_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IY+$d),L (0xFDCB __ 8D)",  arguments: loadJsonTests(named: "fd cb __ 8d", range: 0...testCycles-1))
        func test_RES_1_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 1,(IY+$d),A (0xFDCB __ 8F)",  arguments: loadJsonTests(named: "fd cb __ 8f", range: 0...testCycles-1))
        func test_RES_1_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IY+$d),B (0xFDCB __ 90)",  arguments: loadJsonTests(named: "fd cb __ 90", range: 0...testCycles-1))
        func test_RES_2_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IY+$d),C (0xFDCB __ 91)",  arguments: loadJsonTests(named: "fd cb __ 91", range: 0...testCycles-1))
        func test_RES_2_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IY+$d),D (0xFDCB __ 92)",  arguments: loadJsonTests(named: "fd cb __ 92", range: 0...testCycles-1))
        func test_RES_2_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IY+$d),E (0xFDCB __ 93)",  arguments: loadJsonTests(named: "fd cb __ 93", range: 0...testCycles-1))
        func test_RES_2_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IY+$d),H (0xFDCB __ 94)",  arguments: loadJsonTests(named: "fd cb __ 94", range: 0...testCycles-1))
        func test_RES_2_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IY+$d),L (0xFDCB __ 95)",  arguments: loadJsonTests(named: "fd cb __ 95", range: 0...testCycles-1))
        func test_RES_2_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 2,(IY+$d),A (0xFDCB __ 97)",  arguments: loadJsonTests(named: "fd cb __ 97", range: 0...testCycles-1))
        func test_RES_2_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IY+$d),B (0xFDCB __ 98)",  arguments: loadJsonTests(named: "fd cb __ 98", range: 0...testCycles-1))
        func test_RES_3_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IY+$d),C (0xFDCB __ 99)",  arguments: loadJsonTests(named: "fd cb __ 99", range: 0...testCycles-1))
        func test_RES_3_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IY+$d),D (0xFDCB __ 9A)",  arguments: loadJsonTests(named: "fd cb __ 9a", range: 0...testCycles-1))
        func test_RES_3_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IY+$d),E (0xFDCB __ 9B)",  arguments: loadJsonTests(named: "fd cb __ 9b", range: 0...testCycles-1))
        func test_RES_3_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IY+$d),H (0xFDCB __ 9C)",  arguments: loadJsonTests(named: "fd cb __ 9c", range: 0...testCycles-1))
        func test_RES_3_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IY+$d),L (0xFDCB __ 9D)",  arguments: loadJsonTests(named: "fd cb __ 9d", range: 0...testCycles-1))
        func test_RES_3_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 3,(IY+$d),A (0xFDCB __ 9F)",  arguments: loadJsonTests(named: "fd cb __ 9f", range: 0...testCycles-1))
        func test_RES_3_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IY+$d),B (0xFDCB __ A0)",  arguments: loadJsonTests(named: "fd cb __ a0", range: 0...testCycles-1))
        func test_RES_4_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IY+$d),C (0xFDCB __ A1)",  arguments: loadJsonTests(named: "fd cb __ a1", range: 0...testCycles-1))
        func test_RES_4_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IY+$d),D (0xFDCB __ A2)",  arguments: loadJsonTests(named: "fd cb __ a2", range: 0...testCycles-1))
        func test_RES_4_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IY+$d),E (0xFDCB __ A3)",  arguments: loadJsonTests(named: "fd cb __ a3", range: 0...testCycles-1))
        func test_RES_4_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IY+$d),H (0xFDCB __ A4)",  arguments: loadJsonTests(named: "fd cb __ a4", range: 0...testCycles-1))
        func test_RES_4_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IY+$d),L (0xFDCB __ A5)",  arguments: loadJsonTests(named: "fd cb __ a5", range: 0...testCycles-1))
        func test_RES_4_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 4,(IY+$d),A (0xFDCB __ A7)",  arguments: loadJsonTests(named: "fd cb __ a7", range: 0...testCycles-1))
        func test_RES_4_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IY+$d),B (0xFDCB __ A8)",  arguments: loadJsonTests(named: "fd cb __ a8", range: 0...testCycles-1))
        func test_RES_5_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IY+$d),C (0xFDCB __ A9)",  arguments: loadJsonTests(named: "fd cb __ a9", range: 0...testCycles-1))
        func test_RES_5_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IY+$d),D (0xFDCB __ AA)",  arguments: loadJsonTests(named: "fd cb __ aa", range: 0...testCycles-1))
        func test_RES_5_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IY+$d),E (0xFDCB __ AB)",  arguments: loadJsonTests(named: "fd cb __ ab", range: 0...testCycles-1))
        func test_RES_5_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IY+$d),H (0xFDCB __ AC)",  arguments: loadJsonTests(named: "fd cb __ ac", range: 0...testCycles-1))
        func test_RES_5_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IY+$d),L (0xFDCB __ AD)",  arguments: loadJsonTests(named: "fd cb __ ad", range: 0...testCycles-1))
        func test_RES_5_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 5,(IY+$d),A (0xFDCB __ AF)",  arguments: loadJsonTests(named: "fd cb __ af", range: 0...testCycles-1))
        func test_RES_5_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IY+$d),B (0xFDCB __ B0)",  arguments: loadJsonTests(named: "fd cb __ b0", range: 0...testCycles-1))
        func test_RES_6_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IY+$d),C (0xFDCB __ B1)",  arguments: loadJsonTests(named: "fd cb __ b1", range: 0...testCycles-1))
        func test_RES_6_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IY+$d),D (0xFDCB __ B2)",  arguments: loadJsonTests(named: "fd cb __ b2", range: 0...testCycles-1))
        func test_RES_6_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IY+$d),E (0xFDCB __ B3)",  arguments: loadJsonTests(named: "fd cb __ b3", range: 0...testCycles-1))
        func test_RES_6_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IY+$d),H (0xFDCB __ B4)",  arguments: loadJsonTests(named: "fd cb __ b4", range: 0...testCycles-1))
        func test_RES_6_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IY+$d),L (0xFDCB __ B5)",  arguments: loadJsonTests(named: "fd cb __ b5", range: 0...testCycles-1))
        func test_RES_6_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 6,(IY+$d),A (0xFDCB __ B7)",  arguments: loadJsonTests(named: "fd cb __ b7", range: 0...testCycles-1))
        func test_RES_6_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IY+$d),B (0xFDCB __ B8)",  arguments: loadJsonTests(named: "fd cb __ b8", range: 0...testCycles-1))
        func test_RES_7_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IY+$d),C (0xFDCB __ B9)",  arguments: loadJsonTests(named: "fd cb __ b9", range: 0...testCycles-1))
        func test_RES_7_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IY+$d),D (0xFDCB __ BA)",  arguments: loadJsonTests(named: "fd cb __ ba", range: 0...testCycles-1))
        func test_RES_7_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IY+$d),E (0xFDCB __ BB)",  arguments: loadJsonTests(named: "fd cb __ bb", range: 0...testCycles-1))
        func test_RES_7_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IY+$d),H (0xFDCB __ BC)",  arguments: loadJsonTests(named: "fd cb __ bc", range: 0...testCycles-1))
        func test_RES_7_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IY+$d),L (0xFDCB __ BD)",  arguments: loadJsonTests(named: "fd cb __ bd", range: 0...testCycles-1))
        func test_RES_7_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate RES 7,(IY+$d),A (0xFDCB __ BF)",  arguments: loadJsonTests(named: "fd cb __ bf", range: 0...testCycles-1))
        func test_RES_7_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IY+$d),B (0xFDCB __ C0)",  arguments: loadJsonTests(named: "fd cb __ c0", range: 0...testCycles-1))
        func test_SET_0_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IY+$d),C (0xFDCB __ C1)",  arguments: loadJsonTests(named: "fd cb __ c1", range: 0...testCycles-1))
        func test_SET_0_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IY+$d),D (0xFDCB __ C2)",  arguments: loadJsonTests(named: "fd cb __ c2", range: 0...testCycles-1))
        func test_SET_0_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IY+$d),E (0xFDCB __ C3)",  arguments: loadJsonTests(named: "fd cb __ c3", range: 0...testCycles-1))
        func test_SET_0_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IY+$d),H (0xFDCB __ C4)",  arguments: loadJsonTests(named: "fd cb __ c4", range: 0...testCycles-1))
        func test_SET_0_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IY+$d),L (0xFDCB __ C5)",  arguments: loadJsonTests(named: "fd cb __ c5", range: 0...testCycles-1))
        func test_SET_0_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 0,(IY+$d),A (0xFDCB __ C7)",  arguments: loadJsonTests(named: "fd cb __ c7", range: 0...testCycles-1))
        func test_SET_0_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IY+$d),B (0xFDCB __ C8)",  arguments: loadJsonTests(named: "fd cb __ c8", range: 0...testCycles-1))
        func test_SET_1_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IY+$d),C (0xFDCB __ C9)",  arguments: loadJsonTests(named: "fd cb __ c9", range: 0...testCycles-1))
        func test_SET_1_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IY+$d),D (0xFDCB __ CA)",  arguments: loadJsonTests(named: "fd cb __ ca", range: 0...testCycles-1))
        func test_SET_1_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IY+$d),E (0xFDCB __ CB)",  arguments: loadJsonTests(named: "fd cb __ cb", range: 0...testCycles-1))
        func test_SET_1_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IY+$d),H (0xFDCB __ CC)",  arguments: loadJsonTests(named: "fd cb __ cc", range: 0...testCycles-1))
        func test_SET_1_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IY+$d),L (0xFDCB __ CD)",  arguments: loadJsonTests(named: "fd cb __ cd", range: 0...testCycles-1))
        func test_SET_1_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 1,(IY+$d),A (0xFDCB __ CF)",  arguments: loadJsonTests(named: "fd cb __ cf", range: 0...testCycles-1))
        func test_SET_1_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IY+$d),B (0xFDCB __ D0)",  arguments: loadJsonTests(named: "fd cb __ d0", range: 0...testCycles-1))
        func test_SET_2_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IY+$d),C (0xFDCB __ D1)",  arguments: loadJsonTests(named: "fd cb __ d1", range: 0...testCycles-1))
        func test_SET_2_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IY+$d),D (0xFDCB __ D2)",  arguments: loadJsonTests(named: "fd cb __ d2", range: 0...testCycles-1))
        func test_SET_2_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IY+$d),E (0xFDCB __ D3)",  arguments: loadJsonTests(named: "fd cb __ d3", range: 0...testCycles-1))
        func test_SET_2_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IY+$d),H (0xFDCB __ D4)",  arguments: loadJsonTests(named: "fd cb __ d4", range: 0...testCycles-1))
        func test_SET_2_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IY+$d),L (0xFDCB __ D5)",  arguments: loadJsonTests(named: "fd cb __ d5", range: 0...testCycles-1))
        func test_SET_2_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 2,(IY+$d),A (0xFDCB __ D7)",  arguments: loadJsonTests(named: "fd cb __ d7", range: 0...testCycles-1))
        func test_SET_2_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IY+$d),B (0xFDCB __ D8)",  arguments: loadJsonTests(named: "fd cb __ d8", range: 0...testCycles-1))
        func test_SET_3_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IY+$d),C (0xFDCB __ D9)",  arguments: loadJsonTests(named: "fd cb __ d9", range: 0...testCycles-1))
        func test_SET_3_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IY+$d),D (0xFDCB __ DA)",  arguments: loadJsonTests(named: "fd cb __ da", range: 0...testCycles-1))
        func test_SET_3_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IY+$d),E (0xFDCB __ DB)",  arguments: loadJsonTests(named: "fd cb __ db", range: 0...testCycles-1))
        func test_SET_3_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IY+$d),H (0xFDCB __ DC)",  arguments: loadJsonTests(named: "fd cb __ dc", range: 0...testCycles-1))
        func test_SET_3_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IY+$d),L (0xFDCB __ DD)",  arguments: loadJsonTests(named: "fd cb __ dd", range: 0...testCycles-1))
        func test_SET_3_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 3,(IY+$d),A (0xFDCB __ DF)",  arguments: loadJsonTests(named: "fd cb __ df", range: 0...testCycles-1))
        func test_SET_3_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IY+$d),B (0xFDCB __ E0)",  arguments: loadJsonTests(named: "fd cb __ e0", range: 0...testCycles-1))
        func test_SET_4_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IY+$d),C (0xFDCB __ E1)",  arguments: loadJsonTests(named: "fd cb __ e1", range: 0...testCycles-1))
        func test_SET_4_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IY+$d),D (0xFDCB __ E2)",  arguments: loadJsonTests(named: "fd cb __ e2", range: 0...testCycles-1))
        func test_SET_4_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IY+$d),E (0xFDCB __ E3)",  arguments: loadJsonTests(named: "fd cb __ e3", range: 0...testCycles-1))
        func test_SET_4_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IY+$d),H (0xFDCB __ E4)",  arguments: loadJsonTests(named: "fd cb __ e4", range: 0...testCycles-1))
        func test_SET_4_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IY+$d),L (0xFDCB __ E5)",  arguments: loadJsonTests(named: "fd cb __ e5", range: 0...testCycles-1))
        func test_SET_4_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 4,(IY+$d),A (0xFDCB __ E7)",  arguments: loadJsonTests(named: "fd cb __ e7", range: 0...testCycles-1))
        func test_SET_4_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IY+$d),B (0xFDCB __ E8)",  arguments: loadJsonTests(named: "fd cb __ e8", range: 0...testCycles-1))
        func test_SET_5_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IY+$d),C (0xFDCB __ E9)",  arguments: loadJsonTests(named: "fd cb __ e9", range: 0...testCycles-1))
        func test_SET_5_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IY+$d),D (0xFDCB __ EA)",  arguments: loadJsonTests(named: "fd cb __ ea", range: 0...testCycles-1))
        func test_SET_5_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IY+$d),E (0xFDCB __ EB)",  arguments: loadJsonTests(named: "fd cb __ eb", range: 0...testCycles-1))
        func test_SET_5_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IY+$d),H (0xFDCB __ EC)",  arguments: loadJsonTests(named: "fd cb __ ec", range: 0...testCycles-1))
        func test_SET_5_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IY+$d),L (0xFDCB __ ED)",  arguments: loadJsonTests(named: "fd cb __ ed", range: 0...testCycles-1))
        func test_SET_5_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 5,(IY+$d),A (0xFDCB __ EF)",  arguments: loadJsonTests(named: "fd cb __ ef", range: 0...testCycles-1))
        func test_SET_5_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IY+$d),B (0xFDCB __ F0)",  arguments: loadJsonTests(named: "fd cb __ f0", range: 0...testCycles-1))
        func test_SET_6_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IY+$d),C (0xFDCB __ F1)",  arguments: loadJsonTests(named: "fd cb __ f1", range: 0...testCycles-1))
        func test_SET_6_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IY+$d),D (0xFDCB __ F2)",  arguments: loadJsonTests(named: "fd cb __ f2", range: 0...testCycles-1))
        func test_SET_6_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IY+$d),E (0xFDCB __ F3)",  arguments: loadJsonTests(named: "fd cb __ f3", range: 0...testCycles-1))
        func test_SET_6_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IY+$d),H (0xFDCB __ F4)",  arguments: loadJsonTests(named: "fd cb __ f4", range: 0...testCycles-1))
        func test_SET_6_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IY+$d),L (0xFDCB __ F5)",  arguments: loadJsonTests(named: "fd cb __ f5", range: 0...testCycles-1))
        func test_SET_6_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 6,(IY+$d),A (0xFDCB __ F7)",  arguments: loadJsonTests(named: "fd cb __ f7", range: 0...testCycles-1))
        func test_SET_6_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IY+$d),B (0xFDCB __ F8)",  arguments: loadJsonTests(named: "fd cb __ f8", range: 0...testCycles-1))
        func test_SET_7_CON_IY_D_B(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IY+$d),C (0xFDCB __ F9)",  arguments: loadJsonTests(named: "fd cb __ f9", range: 0...testCycles-1))
        func test_SET_7_CON_IY_D_C(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IY+$d),D (0xFDCB __ FA)",  arguments: loadJsonTests(named: "fd cb __ fa", range: 0...testCycles-1))
        func test_SET_7_CON_IY_D_D(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IY+$d),E (0xFDCB __ FB)",  arguments: loadJsonTests(named: "fd cb __ fb", range: 0...testCycles-1))
        func test_SET_7_CON_IY_D_E(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IY+$d),H (0xFDCB __ FC)",  arguments: loadJsonTests(named: "fd cb __ fc", range: 0...testCycles-1))
        func test_SET_7_CON_IY_D_H(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IY+$d),L (0xFDCB __ FD)",  arguments: loadJsonTests(named: "fd cb __ fd", range: 0...testCycles-1))
        func test_SET_7_CON_IY_D_L(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
        
        @Test("Validate SET 7,(IY+$d),A (0xFDCB __ FF)",  arguments: loadJsonTests(named: "fd cb __ ff", range: 0...testCycles-1))
        func test_SET_7_CON_IY_D_A(testCase: Z80Test) async throws
        {
            try await parent.runTest(testCase)
        }
    }
}

