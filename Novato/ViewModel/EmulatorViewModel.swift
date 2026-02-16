import Foundation

@Observable
final class emulatorViewModel
{
    private let cpu: microbee

    private(set) var snapshot: microbeeSnapshot?
    private var snapshotTask: Task<Void, Never>?

    func startSnapshots()
    {
        snapshotTask?.cancel()
        snapshotTask = Task { await takeSnapshot() }
    }

    func stopSnapshots()
    {
        snapshotTask?.cancel()
        snapshotTask = nil
    }
        
    init(cpu: microbee)
    {
        self.cpu = cpu
        Task { await takeSnapshot() }
    }

    func ClearEmulationScreen() async
    {
        await cpu.ClearVideoMemory()
    }
    
    func splashScreen() async
    {
        await cpu.splashScreen()
    }
    
    func writeToMemory( address : UInt16, value : UInt8) async
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
    
    private func takeSnapshot() async
    {
        while !Task.isCancelled
        {
            let currentSnapshot = await cpu.returnSnapshot()

            guard !Task.isCancelled else { break }

            snapshot = currentSnapshot
                
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}
