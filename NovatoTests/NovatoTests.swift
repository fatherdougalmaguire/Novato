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
    func test_NOP(testCase: Z80Test) async throws
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
    func test_LD_BC_NN(testCase: Z80Test) async throws
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
    func test_LD_CON_BC_A(testCase: Z80Test) async throws
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
    
    @Test("Validate LD B,$n (0x06)", arguments: loadJsonTests(named: "06").prefix(1000))
    func test_LD_B_N(testCase: Z80Test) async throws
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
    
    @Test("Validate EX AF,AF'(0x08)", arguments: loadJsonTests(named: "08").prefix(1000))
    func test_EX_AF_altAF(testCase: Z80Test) async throws
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
    
    @Test("Validate LD A,(BC) (0x0A)", arguments: loadJsonTests(named: "0a").prefix(1000))
    func test_LD_A_CON_BC(testCase: Z80Test) async throws
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
    
    @Test("Validate DEC BC (0x0B)", arguments: loadJsonTests(named: "0b").prefix(1000))
    func test_DEC_BC(testCase: Z80Test) async throws
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
    
    @Test("Validate LD C,$n (0x0E)", arguments: loadJsonTests(named: "0e").prefix(1000))
    func test_LD_C_N(testCase: Z80Test) async throws
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
    
    @Test("Validate DJNZ $d (0x10)", arguments: loadJsonTests(named: "10").prefix(1000))
    func test_DJNZ_D(testCase: Z80Test) async throws
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
    @Test("Validate LD DE,$nn (0x11)", arguments: loadJsonTests(named: "11").prefix(1000))
    func test_LD_DE_NN(testCase: Z80Test) async throws
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
    
    @Test("Validate LD (DE),A (0x12)", arguments: loadJsonTests(named: "12").prefix(1000))
    func test_LD_CON_DE_A(testCase: Z80Test) async throws
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
    
    @Test("Validate INC DE (0x13)", arguments: loadJsonTests(named: "13").prefix(1000))
    func test_INC_DE(testCase: Z80Test) async throws
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
    
    @Test("Validate LD D,$n (0x16)", arguments: loadJsonTests(named: "16").prefix(1000))
    func test_LD_D_N(testCase: Z80Test) async throws
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
    
    @Test("Validate JR $d (0x18)", arguments: loadJsonTests(named: "18").prefix(1000))
    func test_JR_D(testCase: Z80Test) async throws
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
    
    @Test("Validate LD A,(DE) (0x1A)", arguments: loadJsonTests(named: "1a").prefix(1000))
    func test_LD_A_CON_DE(testCase: Z80Test) async throws
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
    
    @Test("Validate DEC DE (0x1B)", .serialized, arguments: loadJsonTests(named: "1b").prefix(1000))
    func test_DEC_DE(testCase: Z80Test) async throws
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
    
    @Test("Validate LD E,$n (0x1E)", .serialized, arguments: loadJsonTests(named: "1e").prefix(1000))
    func test_LD_E_N(testCase: Z80Test) async throws
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
    
    @Test("Validate JR NZ,$d (0x20)", arguments: loadJsonTests(named: "20").prefix(1000))
    func test_JR_NZ_d(testCase: Z80Test) async throws
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
    
    @Test("Validate LD HL,$nn (0x21)", .serialized, arguments: loadJsonTests(named: "21").prefix(1000))
    func test_LD_HL_NN(testCase: Z80Test) async throws
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
    
    @Test("Validate LD ($nn),HL (0x22)", .serialized, arguments: loadJsonTests(named: "22").prefix(1000))
    func test_LD_CON_NN_HL_(testCase: Z80Test) async throws
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
    
    @Test("Validate INC HL (0x23)", .serialized, arguments: loadJsonTests(named: "23").prefix(1000))
    func test_INC_HL(testCase: Z80Test) async throws
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
    
    @Test("Validate LD H,$n (0x26)", .serialized, arguments: loadJsonTests(named: "26").prefix(1000))
    func test_LD_H_N(testCase: Z80Test) async throws
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
    
    @Test("Validate JR Z,$d (0x28)", .serialized, arguments: loadJsonTests(named: "28").prefix(1000))
    func test_JR_Z_D(testCase: Z80Test) async throws
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
    
    @Test("Validate LD HL,($nn) (0x2A)", .serialized, arguments: loadJsonTests(named: "2a").prefix(1000))
    func test_LD_HL_CON_NN(testCase: Z80Test) async throws
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
    
    @Test("Validate DEC HL (0x2B)", .serialized, arguments: loadJsonTests(named: "2b").prefix(1000))
    func test_DEC_HL(testCase: Z80Test) async throws
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
    
    @Test("Validate LD L,$n (0x2E)", .serialized, arguments: loadJsonTests(named: "2e").prefix(1000))
    func test_LD_L_N(testCase: Z80Test) async throws
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
