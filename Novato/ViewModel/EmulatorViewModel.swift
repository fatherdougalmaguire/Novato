import Foundation

@Observable
final class emulatorViewModel
{
    private let cpu: microbee
    
    var isStepActive = false
    private var lastUIUpdate = ContinuousClock.now
    
    private(set) var snapshot: microbeeSnapshot?
    private var snapshotTask: Task<Void, Never>?

    func startSnapshots()
    {
        snapshotTask?.cancel()

        snapshotTask = Task
        {
            let stream = await cpu.snapshots

               for await snapshot in stream
               {
//                   let start = ContinuousClock.now
//                   
//                   if start - lastUIUpdate < .milliseconds(50)
//                   {
//                       continue
//                   }
//
//                   lastUIUpdate = start
                   
                   await MainActor.run
                   {
                       self.snapshot = snapshot
                   }
                //   print("Main Actor update:", start.duration(to: .now))
               }
        }
    }

    func stopSnapshots()
    {
        snapshotTask?.cancel()
        snapshotTask = nil
    }
    
    init(cpu: microbee)
    {
        self.cpu = cpu
        startSnapshots()
    }
    
    func setClockSpeedMultiplier(multiplier: Double) async
    {
        await cpu.setClockSpeedMultiplier(multiplier: multiplier)
    }
    
    func quickload(path: URL, loadAddress: UInt16) async
    {
        await cpu.bus.quickLoad(path: path, loadAddress: loadAddress)
    }

    func updateBreakpoints(index: Int, value: UInt16, mask: Bool) async
    {
        await cpu.updateBreakpoints(index: index, value: value, mask: mask)
    }
    
//    func ClearEmulationScreen() async
//    {
//        await cpu.ClearVideoMemory()
//    }
//    
//    func splashScreen() async
//    {
//        await cpu.splashScreen()
//    }
    
    func writeToMemory(address : UInt16, value : UInt8) async
    {
        await cpu.writeToMemory(address : address, value : value)
    }
    
    func updateProgramCounter(address: UInt16) async
    {
        await cpu.updatePC(address : address)
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

    func pauseEmulation() async
    {
        await cpu.pause()
    }
    
    func resetEmulation() async
    {
        await cpu.reset()
    }
    
//    private func takeSnapshot() async
//    {
//        while !Task.isCancelled
//        {
//            let currentSnapshot = await cpu.returnSnapshot(stepping: false)
//
//            guard !Task.isCancelled else { break }
//
//            snapshot = currentSnapshot
//                
//            try? await Task.sleep(nanoseconds: 20_000_000)
//        }
//    }
}
