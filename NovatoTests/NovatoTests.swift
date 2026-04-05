import Testing
import Foundation

struct CPUState: Decodable, Sendable
{
    let pc, sp, ix, iy: UInt16
    let a, b, c, d, e, h, l, f: UInt8
    let i, r, iff1, iff2, im: UInt8
    let a_prime, b_prime, c_prime, d_prime, e_prime, h_prime, l_prime, f_prime: UInt8
    let ram: [[Int]]
}

struct Z80Test: Decodable, Sendable
{
    let name: String
    let initial: CPUState
    let final: CPUState
    let cycles: [[TestValue]]
}

enum CodingKeys: String, CodingKey
{
    case pc, sp, ix, iy, a, b, c, d, e, h, l, f, i, r, iff1, iff2, im
    case a_prime = "af'", b_prime = "bc'", d_prime = "de'", h_prime = "hl'"
    case ram
}

// Handles the mixed types in the 'cycles' array (sometimes Strings, sometimes Ints)
enum TestValue: Decodable, Sendable {
    case integer(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
        } else {
            self = .string(try container.decode(String.self))
        }
    }
}

@testable import Novato

// Test-only helpers to interact with actor-isolated state safely
#if DEBUG
extension microbee {
    // Expose async setters so mutations happen on the actor
    func setPC(_ value: UInt16) async { registers.PC = value }
    func setSP(_ value: UInt16) async { registers.SP = value }
    func setA(_ value: UInt8) async { registers.A = value }
    func setB(_ value: UInt8) async { registers.B = value }
    func setC(_ value: UInt8) async { registers.C = value }
    func setD(_ value: UInt8) async { registers.D = value }
    func setE(_ value: UInt8) async { registers.E = value }
    func setH(_ value: UInt8) async { registers.H = value }
    func setL(_ value: UInt8) async { registers.L = value }
    func writeRAM(address: UInt16, value: UInt8) async { mmu.writeByte(address: address, value: value) }
    func readRAM(address: UInt16) async -> UInt8 { mmu.readByte(address: address) }
}
#endif

private final class _Z80TestsBundleToken: NSObject {}

struct Z80InstructionTests {
    
    // Static helper to load JSON from the bundle
    static var loadNopTests: [Z80Test] {
        // Resolve resource URL depending on environment (SwiftPM vs Xcode test bundle)
        #if SWIFT_PACKAGE
        let resourceURL = Bundle.module.url(forResource: "00", withExtension: "json")
        #else
        // Fallback to the test bundle in Xcode using an ObjC-compatible token class
        let testBundle = Bundle(for: _Z80TestsBundleToken.self)
        let resourceURL = testBundle.url(forResource: "00", withExtension: "json")
        #endif

        guard let url = resourceURL else {
            fatalError("Missing test resource: 00.json")
        }
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode([Z80Test].self, from: data)
    }

    @Test("Test NOP Instruction (0x00)", arguments: loadNopTests)
    func nop(testCase: Z80Test) async throws
    {
        // 1. Initialize Emulator
        let cpu = microbee()
        
        // 2. Setup Initial State
        await cpu.setA(testCase.initial.a)
        await cpu.setPC(testCase.initial.pc)
        for entry in testCase.initial.ram
        {
            await cpu.writeRAM(address: UInt16(entry[0]), value: UInt8(entry[1]))
        }
        
        // 3. Execute
        await cpu.step()
        
        // 4. Assert using #expect (the new replacement for XCTAssert)
        #expect(await cpu.registers.PC == testCase.final.pc)
        #expect(await cpu.registers.A == testCase.final.a)
        
        // Check RAM state
        for entry in testCase.final.ram {
            let actualValue = await cpu.readRAM(address: UInt16(entry[0]))
            #expect(actualValue == UInt8(entry[1]), "RAM mismatch at \(entry[0])")
        }
    }
}

