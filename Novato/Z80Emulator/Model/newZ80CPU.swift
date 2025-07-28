//import Foundation
//
//@MainActor
//public class Z80CPU: ObservableObject {
//    @Published public var registers: [String: UInt16] = [
//        "AF": 0, "BC": 0, "DE": 0, "HL": 0, "IX": 0, "IY": 0, "SP": 0, "PC": 0
//    ]
//    @Published public var memory: [UInt8] = Array(repeating: 0, count: 65536)
//    @Published public var isRunning = false
//
//    public init() {}
//
//    public func step() {
//        let pc = Int(registers["PC"]!)
//        let opcode = memory[pc]
//        execute(opcode)
//    }
//
//    public func startExecution() {
//        isRunning = true
//        Task {
//            while isRunning {
//                step()
//                try? await Task.sleep(nanoseconds: 10_000_000)
//            }
//        }
//    }
//
//    public func stopExecution() {
//        isRunning = false
//    }
//}
