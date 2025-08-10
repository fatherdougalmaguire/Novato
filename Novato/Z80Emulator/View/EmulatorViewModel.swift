import Foundation
import Combine

final class EmulatorViewModel: ObservableObject
{

    @Published var pcText = "0000"
    @Published var aReg   : UInt8 = 0
    @Published var bReg   : UInt8 = 0
    @Published var cReg   : UInt8 = 0
    @Published var dReg   : UInt8 = 0
    @Published var eReg   : UInt8 = 0
    @Published var fReg   : UInt8 = 0
    @Published var hReg   : UInt8 = 0
    @Published var lReg   : UInt8 = 0
    @Published var spText = "FFFF"
    @Published var memoryDump: [UInt8] = []

    private let cpu: Z80CPU

    init(cpu: Z80CPU)
    {
        self.cpu = cpu
        // Keep pulling the latest CPU state every frame (~60 Hz)
        Task { await updateLoop() }
    }

    func startEmulation() async
    {
        await cpu.start()
    }

    func stopEmulation() async
    {
        await cpu.stop()
    }

    private func updateLoop() async
    {
        while true
        {
            let state = await cpu.getState()
            await MainActor.run
            {
                self.pcText   = String(format: "%04X", state.PC)
                self.spText   = String(format: "%04X", state.SP)

                self.aReg = state.A
                self.fReg = state.F
                self.bReg = state.B
                self.cReg = state.C
                self.dReg = state.D
                self.eReg = state.E
                self.hReg = state.H
                self.lReg = state.L

                self.memoryDump = state.memoryDump
            }

            // Aim for 60 Hz UI refresh – adjust as needed
           try? await Task.sleep(nanoseconds: 16_666_667)
        }
    }
}
    
