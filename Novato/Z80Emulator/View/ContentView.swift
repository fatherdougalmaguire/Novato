import SwiftUI

struct ContentView: View {
    @StateObject var cpu = Z80CPU()

    var body: some View
    {
        VStack(spacing: 20)
        {
            RegisterView(registers: cpu.registers)
            MemoryView(memory: cpu.memory)
            HStack(spacing: 10)
            {
                Button("Start") { cpu.start() }
                Button("Stop") { cpu.stop()  }
                Button("Step") { cpu.step() }
            }
        }
        .padding()
    }
}
