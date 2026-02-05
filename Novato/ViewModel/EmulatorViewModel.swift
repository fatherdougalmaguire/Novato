import Foundation

@Observable
final class EmulatorViewModel
{
//    var aReg   : UInt8 = 0
//    var bReg   : UInt8 = 0
//    var cReg   : UInt8 = 0
//    var dReg   : UInt8 = 0
//    var eReg   : UInt8 = 0
//    var fReg   : UInt8 = 0
//    var hReg   : UInt8 = 0
//    var lReg   : UInt8 = 0
//    
//    var bcReg   : UInt16 = 0
//    var deReg   : UInt16 = 0
//    var hlReg   : UInt16 = 0
//    
//    var altaReg   : UInt8 = 0
//    var altbReg   : UInt8 = 0
//    var altcReg   : UInt8 = 0
//    var altdReg   : UInt8 = 0
//    var alteReg   : UInt8 = 0
//    var altfReg   : UInt8 = 0
//    var althReg   : UInt8 = 0
//    var altlReg   : UInt8 = 0
//    
//    var altbcReg   : UInt16 = 0
//    var altdeReg   : UInt16 = 0
//    var althlReg   : UInt16 = 0
//    
//    var iReg   : UInt8 = 0
//    var rReg   : UInt8 = 0
//    var imReg  : UInt8 = 0
//    var iFF1Reg  : Bool = false
//    var iFF2Reg  : Bool = false
//    
//    var ixReg  : UInt16 = 0
//    var iyReg  : UInt16 = 0
//    
//    var pcReg  : UInt16 = 0
//    var lastpcReg  : UInt16 = 0
//    var spReg  : UInt16 = 0
//    
//    var memoryDump: [UInt8] = []
//    var ports: [UInt8] = Array(repeating: 0,count: 256)
//    var VDU: [Float] = []
//    var CharRom : [Float] = []
//    var PcgRam: [Float] = []
//    var ColourRam : [Float] = []
//    
//    var vmR1_HorizDisplayed : UInt8 = 0
//    var vmR6_VertDisplayed : UInt8 = 0
//    var vmR9_ScanLinesMinus1 : UInt8 = 0
//    var vmR10_CursorStartAndBlinkMode : UInt8 = 0
//    var vmR11_CursorEnd : UInt8 = 0
//    var vmR12_DisplayStartAddrH : UInt8 = 0
//    var vmR13_DisplayStartAddrL : UInt8 = 0
//    var vmR14_CursorPositionH : UInt8 = 0
//    var vmR15_CursorPositionL : UInt8 = 0
//    
//    var vmRedBackgroundIntensity : UInt8 = 0
//    var vmGreenBackgroundIntensity : UInt8 = 0
//    var vmBlueBackgroundIntensity : UInt8 = 0
//    
//    var Z80Queue : Z80Queue? = nil
//    
//    var emulatorState : emulatorState = .stopped
//    
//    var tStates  : UInt64 = 0
    
    private let cpu: Microbee
    private(set) var snapshot: microbeeSnapshot?
    private var snapshotTask: Task<Void, Never>?
        
    init(cpu: Microbee)
    {
        self.cpu = cpu
     //   Task { await updateLoop() }
    }

    func startSnapshots() {
            snapshotTask?.cancel()
            snapshotTask = Task { await takeSnapshot() }
        }

        func stopSnapshots() {
            snapshotTask?.cancel()
            snapshotTask = nil
        }
    
    func ClearEmulationScreen() async
    {
        await cpu.ClearVideoMemory()
    }
    
    func writeToMemory( address : UInt16, value : UInt8) async
    {
        await cpu.writeToMemory(address : address, value : value)
    }
    
    func startEmulation() async
    {
        await cpu.start()
    }
    
    func stepEmulation() async
    {
        await cpu.step()
    }

    func stopEmulation() async
    {
        await cpu.stop()
    }
    
    func resetEmulation() async
    {
        await cpu.reset()
    }

    private func takeSnapshot() async
    {
        while !Task.isCancelled {
            let currentSnapshot = await cpu.returnSnapshot()

            guard !Task.isCancelled else { break }

            snapshot = currentSnapshot
            
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }
    
//    private func updateLoop() async
//    {
//        while !Task.isCancelled
//        {
//            let state = await cpu.getState()
//            await MainActor.run
//            {
//                self.pcReg  = state.PC
//                self.lastpcReg  = state.lastPC
//                self.spReg  = state.SP
//
//                self.bcReg  = state.BC
//                self.deReg  = state.DE
//                self.hlReg  = state.HL
//
//                self.altbcReg  = state.AltBC
//                self.altdeReg  = state.AltDE
//                self.althlReg  = state.AltHL
//
//                self.ixReg  = state.IX
//                self.iyReg  = state.IY
//
//                self.iReg = state.I
//                self.rReg = state.R
//
//                self.imReg = state.IM
//                self.iFF1Reg = state.IFF1
//                self.iFF2Reg = state.IFF2
//
//                self.aReg = state.A
//                self.fReg = state.F
//                self.bReg = state.B
//                self.cReg = state.C
//                self.dReg = state.D
//                self.eReg = state.E
//                self.hReg = state.H
//                self.lReg = state.L
//
//                self.altaReg = state.AltA
//                self.altfReg = state.AltF
//                self.altbReg = state.AltB
//                self.altcReg = state.AltC
//                self.altdReg = state.AltD
//                self.alteReg = state.AltE
//                self.althReg = state.AltH
//                self.altlReg = state.AltL
//
//                self.memoryDump = state.memoryDump
//                self.ports = state.ports
//                self.VDU = state.VDU
//                self.CharRom = state.CharRom
//                self.PcgRam = state.PcgRam
//                self.ColourRam = state.ColourRam
//
//                self.vmR1_HorizDisplayed = state.vmR1_HorizDisplayed
//                self.vmR6_VertDisplayed = state.vmR6_VertDisplayed
//                self.vmR9_ScanLinesMinus1 = state.vmR9_ScanLinesMinus1
//                self.vmR10_CursorStartAndBlinkMode = state.vmR10_CursorStartAndBlinkMode
//                self.vmR11_CursorEnd = state.vmR11_CursorEnd
//                self.vmR12_DisplayStartAddrH = state.vmR12_DisplayStartAddrH
//                self.vmR13_DisplayStartAddrL = state.vmR13_DisplayStartAddrL
//                self.vmR14_CursorPositionH = state.vmR14_CursorPositionH
//                self.vmR15_CursorPositionL = state.vmR15_CursorPositionL
//
//                self.vmRedBackgroundIntensity = state.vmRedBackgroundIntensity
//                self.vmGreenBackgroundIntensity = state.vmGreenBackgroundIntensity
//                self.vmBlueBackgroundIntensity = state.vmBlueBackgroundIntensity
//
//                self.Z80Queue = state.Z80Queue
//                self.tStates = state.tStates
//            }
//            try? await Task.sleep(nanoseconds: 20_000_000) // pause for 20ms or 50HZ frame to stop hammering the CPU updating the snapshot
//        }
//    }
}
