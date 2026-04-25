import Foundation
import Testing

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

struct Z80InstructionTests
{
    static func loadJsonTests(named filename: String) -> [Z80Test]
    {
            // 1. Locate the file in the test bundle
            // Using Bundle(for:) ensures it works even if the tests are in a separate target
            let bundle = Bundle(for: BundleToken.self)
            
            guard let url = bundle.url(forResource: filename, withExtension: "json") else
            {
                print("Error: Could not find \(filename).json in bundle.")
                return []
            }

            do
            {
                // 2. Load raw data from disk
                let data = try Data(contentsOf: url)
                
                // 3. Decode JSON into our Swift Structs
                let decoder = JSONDecoder()
                let tests = try decoder.decode([Z80Test].self, from: data)
                
                print("Successfully loaded \(tests.count) tests from \(filename).json")
                return tests
                
            }
            catch
            {
                print("Error decoding \(filename).json: \(error)")
                return []
            }
    }

    /// A dummy class used to locate the current bundle
    private class BundleToken {}

    @Test("Validate NOP (0x00)", arguments: loadJsonTests(named: "00"))
    func testNOP(testCase: Z80Test) async throws
    {
        let cpu = microbee()
        
        // 1. Initial State
        await cpu.loadCPUState(cpuState: testCase.initial)
        
        // 2. Execute
        await cpu.nextInstruction()
        
        // 3. Compare Results
        let finalState = await cpu.returnCPUState(cpuState: testCase.initial)
        
        #expect(finalState.A == testCase.final.A,"register A fail: Initial \(testCase.initial.A), expected \(testCase.final.A), got \(finalState.A) in \(testCase.name)")
        #expect(finalState.F == testCase.final.F,"register F fail: Initial \(testCase.initial.F), expected \(testCase.final.F), got \(finalState.F) in \(testCase.name)")
        #expect(finalState.B == testCase.final.B,"register B fail: Initial \(testCase.initial.B), expected \(testCase.final.B), got \(finalState.B) in \(testCase.name)")
        #expect(finalState.C == testCase.final.C,"register C fail: Initial \(testCase.initial.C), expected \(testCase.final.C), got \(finalState.C) in \(testCase.name)")
        #expect(finalState.D == testCase.final.D,"register D fail: Initial \(testCase.initial.D), expected \(testCase.final.D), got \(finalState.D) in \(testCase.name)")
        #expect(finalState.E == testCase.final.E,"register E fail: Initial \(testCase.initial.E), expected \(testCase.final.E), got \(finalState.E) in \(testCase.name)")
        #expect(finalState.H == testCase.final.H,"register H fail: Initial \(testCase.initial.H), expected \(testCase.final.H), got \(finalState.H) in \(testCase.name)")
        #expect(finalState.L == testCase.final.L,"register L fail: Initial \(testCase.initial.L), expected \(testCase.final.L), got \(finalState.L) in \(testCase.name)")
        #expect(finalState.altAF == testCase.final.altAF,"register altAF fail: Initial \(testCase.initial.altAF), expected \(testCase.final.altAF), got \(finalState.altAF) in \(testCase.name)")
        #expect(finalState.altBC == testCase.final.altBC,"register altBC fail: Initial \(testCase.initial.altBC), expected \(testCase.final.altBC), got \(finalState.altBC) in \(testCase.name)")
        #expect(finalState.altDE == testCase.final.altDE,"register altDE fail: Initial \(testCase.initial.altBC), expected \(testCase.final.altDE), got \(finalState.altDE) in \(testCase.name)")
        #expect(finalState.altHL == testCase.final.altHL,"register altHL fail: Initial \(testCase.initial.altBC) ,expected \(testCase.final.altHL), got \(finalState.altHL) in \(testCase.name)")
        #expect(finalState.I == testCase.final.I,"register I fail: Initial \(testCase.initial.I), expected \(testCase.final.I), got \(finalState.I) in \(testCase.name)")
        #expect(finalState.R == testCase.final.R,"register R fail: Initial \(testCase.initial.R) ,expected \(testCase.final.R), got \(finalState.R) in \(testCase.name)")
        #expect(finalState.IM == testCase.final.IM,"register IM fail: Initial \(testCase.initial.IM), expected \(testCase.final.IM), got \(finalState.IM) in \(testCase.name)")
        #expect(finalState.IX == testCase.final.IX,"register IX fail: Initial \(testCase.initial.IX), expected \(testCase.final.IX), got \(finalState.IX) in \(testCase.name)")
        #expect(finalState.IY == testCase.final.IY,"register IY fail: Initial \(testCase.initial.IY), expected \(testCase.final.IY), got \(finalState.IY) in \(testCase.name)")
        #expect(finalState.PC == testCase.final.PC,"register PC fail: Initial \(testCase.initial.PC), expected \(testCase.final.PC), got \(finalState.PC) in \(testCase.name)")
        #expect(finalState.SP == testCase.final.SP,"register SP fail: Initial \(testCase.initial.SP), expected \(testCase.final.SP), got \(finalState.SP) in \(testCase.name)")
        #expect(finalState.WZ == testCase.final.WZ,"register WZ fail: Initial \(testCase.initial.WZ), expected \(testCase.final.WZ), got \(finalState.WZ) in \(testCase.name)")
       // #expect(finalState.Q == testCase.final.Q,"register Q fail: Initial \(testCase.initial.Q), expected \(testCase.final.Q), got \(finalState.Q) in \(testCase.name)")
       // #expect(finalState.P == testCase.final.P,"register P fail: Initial \(testCase.initial.P) ,expected \(testCase.final.P), got \(finalState.P) in \(testCase.name)")
       // #expect(finalState.EI == testCase.final.EI,"register EI fail: Initial \(testCase.initial.EI), expected \(testCase.final.EI), got \(finalState.EI) in \(testCase.name)")
        #expect(finalState.ram == testCase.final.ram,"Ram fail: Initial \(testCase.initial.ram), expected \(testCase.final.ram), got \(finalState.ram) in \(testCase.name)")
    }
    
    @Test("Validate LD BC,$nn (0x01)", arguments: loadJsonTests(named: "01").prefix(1000))
    func testLD_BC_NN(testCase: Z80Test) async throws
    {
        let cpu = microbee()
        
        // 1. Initial State
        await cpu.loadCPUState(cpuState: testCase.initial)
        
        // 2. Execute
        await cpu.nextInstruction()
        
        // 3. Compare Results
        let finalState = await cpu.returnCPUState(cpuState: testCase.initial)
        
        #expect(finalState.A == testCase.final.A,"register A fail: Initial \(testCase.initial.A), expected \(testCase.final.A), got \(finalState.A) in \(testCase.name)")
        #expect(finalState.F == testCase.final.F,"register F fail: Initial \(testCase.initial.F), expected \(testCase.final.F), got \(finalState.F) in \(testCase.name)")
        #expect(finalState.B == testCase.final.B,"register B fail: Initial \(testCase.initial.B), expected \(testCase.final.B), got \(finalState.B) in \(testCase.name)")
        #expect(finalState.C == testCase.final.C,"register C fail: Initial \(testCase.initial.C), expected \(testCase.final.C), got \(finalState.C) in \(testCase.name)")
        #expect(finalState.D == testCase.final.D,"register D fail: Initial \(testCase.initial.D), expected \(testCase.final.D), got \(finalState.D) in \(testCase.name)")
        #expect(finalState.E == testCase.final.E,"register E fail: Initial \(testCase.initial.E), expected \(testCase.final.E), got \(finalState.E) in \(testCase.name)")
        #expect(finalState.H == testCase.final.H,"register H fail: Initial \(testCase.initial.H), expected \(testCase.final.H), got \(finalState.H) in \(testCase.name)")
        #expect(finalState.L == testCase.final.L,"register L fail: Initial \(testCase.initial.L), expected \(testCase.final.L), got \(finalState.L) in \(testCase.name)")
        #expect(finalState.altAF == testCase.final.altAF,"register altAF fail: Initial \(testCase.initial.altAF), expected \(testCase.final.altAF), got \(finalState.altAF) in \(testCase.name)")
        #expect(finalState.altBC == testCase.final.altBC,"register altBC fail: Initial \(testCase.initial.altBC), expected \(testCase.final.altBC), got \(finalState.altBC) in \(testCase.name)")
        #expect(finalState.altDE == testCase.final.altDE,"register altDE fail: Initial \(testCase.initial.altBC), expected \(testCase.final.altDE), got \(finalState.altDE) in \(testCase.name)")
        #expect(finalState.altHL == testCase.final.altHL,"register altHL fail: Initial \(testCase.initial.altBC) ,expected \(testCase.final.altHL), got \(finalState.altHL) in \(testCase.name)")
        #expect(finalState.I == testCase.final.I,"register I fail: Initial \(testCase.initial.I), expected \(testCase.final.I), got \(finalState.I) in \(testCase.name)")
        #expect(finalState.R == testCase.final.R,"register R fail: Initial \(testCase.initial.R) ,expected \(testCase.final.R), got \(finalState.R) in \(testCase.name)")
        #expect(finalState.IM == testCase.final.IM,"register IM fail: Initial \(testCase.initial.IM), expected \(testCase.final.IM), got \(finalState.IM) in \(testCase.name)")
        #expect(finalState.IX == testCase.final.IX,"register IX fail: Initial \(testCase.initial.IX), expected \(testCase.final.IX), got \(finalState.IX) in \(testCase.name)")
        #expect(finalState.IY == testCase.final.IY,"register IY fail: Initial \(testCase.initial.IY), expected \(testCase.final.IY), got \(finalState.IY) in \(testCase.name)")
        #expect(finalState.PC == testCase.final.PC,"register PC fail: Initial \(testCase.initial.PC), expected \(testCase.final.PC), got \(finalState.PC) in \(testCase.name)")
        #expect(finalState.SP == testCase.final.SP,"register SP fail: Initial \(testCase.initial.SP), expected \(testCase.final.SP), got \(finalState.SP) in \(testCase.name)")
        #expect(finalState.WZ == testCase.final.WZ,"register WZ fail: Initial \(testCase.initial.WZ), expected \(testCase.final.WZ), got \(finalState.WZ) in \(testCase.name)")
       // #expect(finalState.Q == testCase.final.Q,"register Q fail: Initial \(testCase.initial.Q), expected \(testCase.final.Q), got \(finalState.Q) in \(testCase.name)")
       // #expect(finalState.P == testCase.final.P,"register P fail: Initial \(testCase.initial.P) ,expected \(testCase.final.P), got \(finalState.P) in \(testCase.name)")
       // #expect(finalState.EI == testCase.final.EI,"register EI fail: Initial \(testCase.initial.EI), expected \(testCase.final.EI), got \(finalState.EI) in \(testCase.name)")
        #expect(finalState.ram == testCase.final.ram,"Ram fail: Initial \(testCase.initial.ram), expected \(testCase.final.ram), got \(finalState.ram) in \(testCase.name)")
    }
    
    @Test("Validate LD (BC),A (0x02)", arguments: loadJsonTests(named: "02").prefix(1000))
    func testLD_CON_BC_A(testCase: Z80Test) async throws
    {
        let cpu = microbee()
        
        // 1. Initial State
        await cpu.loadCPUState(cpuState: testCase.initial)
        
        // 2. Execute
        await cpu.nextInstruction()
        
        // 3. Compare Results
        let finalState = await cpu.returnCPUState(cpuState: testCase.initial)
        
        #expect(finalState.A == testCase.final.A,"register A fail: Initial \(testCase.initial.A), expected \(testCase.final.A), got \(finalState.A) in \(testCase.name)")
        #expect(finalState.F == testCase.final.F,"register F fail: Initial \(testCase.initial.F), expected \(testCase.final.F), got \(finalState.F) in \(testCase.name)")
        #expect(finalState.B == testCase.final.B,"register B fail: Initial \(testCase.initial.B), expected \(testCase.final.B), got \(finalState.B) in \(testCase.name)")
        #expect(finalState.C == testCase.final.C,"register C fail: Initial \(testCase.initial.C), expected \(testCase.final.C), got \(finalState.C) in \(testCase.name)")
        #expect(finalState.D == testCase.final.D,"register D fail: Initial \(testCase.initial.D), expected \(testCase.final.D), got \(finalState.D) in \(testCase.name)")
        #expect(finalState.E == testCase.final.E,"register E fail: Initial \(testCase.initial.E), expected \(testCase.final.E), got \(finalState.E) in \(testCase.name)")
        #expect(finalState.H == testCase.final.H,"register H fail: Initial \(testCase.initial.H), expected \(testCase.final.H), got \(finalState.H) in \(testCase.name)")
        #expect(finalState.L == testCase.final.L,"register L fail: Initial \(testCase.initial.L), expected \(testCase.final.L), got \(finalState.L) in \(testCase.name)")
        #expect(finalState.altAF == testCase.final.altAF,"register altAF fail: Initial \(testCase.initial.altAF), expected \(testCase.final.altAF), got \(finalState.altAF) in \(testCase.name)")
        #expect(finalState.altBC == testCase.final.altBC,"register altBC fail: Initial \(testCase.initial.altBC), expected \(testCase.final.altBC), got \(finalState.altBC) in \(testCase.name)")
        #expect(finalState.altDE == testCase.final.altDE,"register altDE fail: Initial \(testCase.initial.altBC), expected \(testCase.final.altDE), got \(finalState.altDE) in \(testCase.name)")
        #expect(finalState.altHL == testCase.final.altHL,"register altHL fail: Initial \(testCase.initial.altBC) ,expected \(testCase.final.altHL), got \(finalState.altHL) in \(testCase.name)")
        #expect(finalState.I == testCase.final.I,"register I fail: Initial \(testCase.initial.I), expected \(testCase.final.I), got \(finalState.I) in \(testCase.name)")
        #expect(finalState.R == testCase.final.R,"register R fail: Initial \(testCase.initial.R) ,expected \(testCase.final.R), got \(finalState.R) in \(testCase.name)")
        #expect(finalState.IM == testCase.final.IM,"register IM fail: Initial \(testCase.initial.IM), expected \(testCase.final.IM), got \(finalState.IM) in \(testCase.name)")
        #expect(finalState.IX == testCase.final.IX,"register IX fail: Initial \(testCase.initial.IX), expected \(testCase.final.IX), got \(finalState.IX) in \(testCase.name)")
        #expect(finalState.IY == testCase.final.IY,"register IY fail: Initial \(testCase.initial.IY), expected \(testCase.final.IY), got \(finalState.IY) in \(testCase.name)")
        #expect(finalState.PC == testCase.final.PC,"register PC fail: Initial \(testCase.initial.PC), expected \(testCase.final.PC), got \(finalState.PC) in \(testCase.name)")
        #expect(finalState.SP == testCase.final.SP,"register SP fail: Initial \(testCase.initial.SP), expected \(testCase.final.SP), got \(finalState.SP) in \(testCase.name)")
        #expect(finalState.WZ == testCase.final.WZ,"register WZ fail: Initial \(testCase.initial.WZ), expected \(testCase.final.WZ), got \(finalState.WZ) in \(testCase.name)")
       // #expect(finalState.Q == testCase.final.Q,"register Q fail: Initial \(testCase.initial.Q), expected \(testCase.final.Q), got \(finalState.Q) in \(testCase.name)")
       // #expect(finalState.P == testCase.final.P,"register P fail: Initial \(testCase.initial.P) ,expected \(testCase.final.P), got \(finalState.P) in \(testCase.name)")
       // #expect(finalState.EI == testCase.final.EI,"register EI fail: Initial \(testCase.initial.EI), expected \(testCase.final.EI), got \(finalState.EI) in \(testCase.name)")
        #expect(finalState.ram == testCase.final.ram,"Ram fail: Initial \(testCase.initial.ram), expected \(testCase.final.ram), got \(finalState.ram) in \(testCase.name)")
    }
    
    @Test("Validate INC BC (0x03)", arguments: loadJsonTests(named: "03").prefix(1000))
    func test_INC_BC(testCase: Z80Test) async throws
    {
        let cpu = microbee()
        
        // 1. Initial State
        await cpu.loadCPUState(cpuState: testCase.initial)
        
        // 2. Execute
        await cpu.nextInstruction()
        
        // 3. Compare Results
        let finalState = await cpu.returnCPUState(cpuState: testCase.initial)
        
        #expect(finalState.A == testCase.final.A,"register A fail: Initial \(testCase.initial.A), expected \(testCase.final.A), got \(finalState.A) in \(testCase.name)")
        #expect(finalState.F == testCase.final.F,"register F fail: Initial \(testCase.initial.F), expected \(testCase.final.F), got \(finalState.F) in \(testCase.name)")
        #expect(finalState.B == testCase.final.B,"register B fail: Initial \(testCase.initial.B), expected \(testCase.final.B), got \(finalState.B) in \(testCase.name)")
        #expect(finalState.C == testCase.final.C,"register C fail: Initial \(testCase.initial.C), expected \(testCase.final.C), got \(finalState.C) in \(testCase.name)")
        #expect(finalState.D == testCase.final.D,"register D fail: Initial \(testCase.initial.D), expected \(testCase.final.D), got \(finalState.D) in \(testCase.name)")
        #expect(finalState.E == testCase.final.E,"register E fail: Initial \(testCase.initial.E), expected \(testCase.final.E), got \(finalState.E) in \(testCase.name)")
        #expect(finalState.H == testCase.final.H,"register H fail: Initial \(testCase.initial.H), expected \(testCase.final.H), got \(finalState.H) in \(testCase.name)")
        #expect(finalState.L == testCase.final.L,"register L fail: Initial \(testCase.initial.L), expected \(testCase.final.L), got \(finalState.L) in \(testCase.name)")
        #expect(finalState.altAF == testCase.final.altAF,"register altAF fail: Initial \(testCase.initial.altAF), expected \(testCase.final.altAF), got \(finalState.altAF) in \(testCase.name)")
        #expect(finalState.altBC == testCase.final.altBC,"register altBC fail: Initial \(testCase.initial.altBC), expected \(testCase.final.altBC), got \(finalState.altBC) in \(testCase.name)")
        #expect(finalState.altDE == testCase.final.altDE,"register altDE fail: Initial \(testCase.initial.altBC), expected \(testCase.final.altDE), got \(finalState.altDE) in \(testCase.name)")
        #expect(finalState.altHL == testCase.final.altHL,"register altHL fail: Initial \(testCase.initial.altBC) ,expected \(testCase.final.altHL), got \(finalState.altHL) in \(testCase.name)")
        #expect(finalState.I == testCase.final.I,"register I fail: Initial \(testCase.initial.I), expected \(testCase.final.I), got \(finalState.I) in \(testCase.name)")
        #expect(finalState.R == testCase.final.R,"register R fail: Initial \(testCase.initial.R) ,expected \(testCase.final.R), got \(finalState.R) in \(testCase.name)")
        #expect(finalState.IM == testCase.final.IM,"register IM fail: Initial \(testCase.initial.IM), expected \(testCase.final.IM), got \(finalState.IM) in \(testCase.name)")
        #expect(finalState.IX == testCase.final.IX,"register IX fail: Initial \(testCase.initial.IX), expected \(testCase.final.IX), got \(finalState.IX) in \(testCase.name)")
        #expect(finalState.IY == testCase.final.IY,"register IY fail: Initial \(testCase.initial.IY), expected \(testCase.final.IY), got \(finalState.IY) in \(testCase.name)")
        #expect(finalState.PC == testCase.final.PC,"register PC fail: Initial \(testCase.initial.PC), expected \(testCase.final.PC), got \(finalState.PC) in \(testCase.name)")
        #expect(finalState.SP == testCase.final.SP,"register SP fail: Initial \(testCase.initial.SP), expected \(testCase.final.SP), got \(finalState.SP) in \(testCase.name)")
        #expect(finalState.WZ == testCase.final.WZ,"register WZ fail: Initial \(testCase.initial.WZ), expected \(testCase.final.WZ), got \(finalState.WZ) in \(testCase.name)")
       // #expect(finalState.Q == testCase.final.Q,"register Q fail: Initial \(testCase.initial.Q), expected \(testCase.final.Q), got \(finalState.Q) in \(testCase.name)")
       // #expect(finalState.P == testCase.final.P,"register P fail: Initial \(testCase.initial.P) ,expected \(testCase.final.P), got \(finalState.P) in \(testCase.name)")
       // #expect(finalState.EI == testCase.final.EI,"register EI fail: Initial \(testCase.initial.EI), expected \(testCase.final.EI), got \(finalState.EI) in \(testCase.name)")
        #expect(finalState.ram == testCase.final.ram,"Ram fail: Initial \(testCase.initial.ram), expected \(testCase.final.ram), got \(finalState.ram) in \(testCase.name)")
    }
}
