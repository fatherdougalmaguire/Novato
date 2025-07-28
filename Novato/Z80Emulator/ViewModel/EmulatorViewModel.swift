import Foundation

class EmulatorViewModel: ObservableObject {
    @Published var cpu = Z80CPU()

    func start() {
        cpu.isRunning = true
    }

    func stop() {
        cpu.isRunning = false
    }

    func step() {
        cpu.step()
    }

    func run(cycles: Int) {
        cpu.run(cycles: cycles)
    }
}
