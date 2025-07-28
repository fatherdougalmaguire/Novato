import SwiftUI

struct ContentView: View {
    @StateObject var cpu = Z80CPU()

    var body: some View {
        VStack(spacing: 20) {
            RegisterView(registers: cpu.registers)
            MemoryView(memory: cpu.memory)
            HStack(spacing: 10) {
                Button("Start") { cpu.isRunning = true }
                Button("Stop") { cpu.isRunning = false }
                Button("Step") { cpu.step() }
                Button("Run 10") { cpu.run(cycles: 10) }
            }
        }
        .padding()
    }
}