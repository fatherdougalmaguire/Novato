import Foundation
import AppKit

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
            
#if arch(arm64)
            let minimumUIUpdateInterval = Duration.milliseconds(20)
#elseif arch(x86_64)
            let minimumUIUpdateInterval = Duration.milliseconds(50)
#endif
            
            var lastUIUpdate = ContinuousClock.now - minimumUIUpdateInterval
            
            for await snapshot in stream
            {
                guard !Task.isCancelled else
                {
                    break
                }
                
                let now = ContinuousClock.now
                
                guard now - lastUIUpdate >= minimumUIUpdateInterval else {
                    continue
                }
                
                lastUIUpdate = now
                
                await MainActor.run
                {
                    self.snapshot = snapshot
                }
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
    
    func keyDown(_ key: MicrobeeKey) async
    {
        print("key down",key)
        await cpu.keyDown(key)
    }

    func keyUp(_ key: MicrobeeKey) async
    {
        print("key up",key)
        await cpu.keyUp(key)
    }
    
    func modifiersChanged(_ modifiers: NSEvent.ModifierFlags) async
    {
        print("Modifier pressed",modifiers)
        await cpu.modifiersChanged(
            shift: modifiers.contains(.shift),
            control: modifiers.contains(.control)
        )
    }
}
