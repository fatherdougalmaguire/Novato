import Foundation
import Combine

@Observable
class EmulatorViewModel
{
    var aReg   : UInt8 = 0
    var bReg   : UInt8 = 0
    var cReg   : UInt8 = 0
    var dReg   : UInt8 = 0
    var eReg   : UInt8 = 0
    var fReg   : UInt8 = 0
    var hReg   : UInt8 = 0
    var lReg   : UInt8 = 0
    
    var bcReg   : UInt16 = 0
    var deReg   : UInt16 = 0
    var hlReg   : UInt16 = 0
    
    var altaReg   : UInt8 = 0
    var altbReg   : UInt8 = 0
    var altcReg   : UInt8 = 0
    var altdReg   : UInt8 = 0
    var alteReg   : UInt8 = 0
    var altfReg   : UInt8 = 0
    var althReg   : UInt8 = 0
    var altlReg   : UInt8 = 0
    
    var altbcReg   : UInt16 = 0
    var altdeReg   : UInt16 = 0
    var althlReg   : UInt16 = 0
    
    var iReg   : UInt8 = 0
    var rReg   : UInt8 = 0
    
    var ixReg  : UInt16 = 0
    var iyReg  : UInt16 = 0
    
    var pcReg  : UInt16 = 0
    var spReg  : UInt16 = 0
    
    var memoryDump: [UInt8] = []
    var VDU: [Float] = []
    var CharRom : [Float] = []

    private let cpu: Z80CPU

    init(cpu: Z80CPU)
    {
        self.cpu = cpu
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
                self.pcReg  = state.PC
                self.spReg  = state.SP
                
                self.bcReg  = state.BC
                self.deReg  = state.DE
                self.hlReg  = state.HL
                
                self.altbcReg  = state.AltBC
                self.altdeReg  = state.AltDE
                self.althlReg  = state.AltHL
                
                self.ixReg  = state.IX
                self.iyReg  = state.IY
                
                self.iReg = state.I
                self.rReg = state.R

                self.aReg = state.A
                self.fReg = state.F
                self.bReg = state.B
                self.cReg = state.C
                self.dReg = state.D
                self.eReg = state.E
                self.hReg = state.H
                self.lReg = state.L
                
                self.altaReg = state.AltA
                self.altfReg = state.AltF
                self.altbReg = state.AltB
                self.altcReg = state.AltC
                self.altdReg = state.AltD
                self.alteReg = state.AltE
                self.althReg = state.AltH
                self.altlReg = state.AltL

                self.memoryDump = state.memoryDump
                self.VDU = state.VDU
                self.CharRom = state.CharRom
            }
        }
    }
}
    
