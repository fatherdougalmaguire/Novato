import Foundation
import AppKit

@Observable
final class emulatorViewModel
{
private let cpu: microbee

var isStepActive = false

private(set) var snapshot: microbeeSnapshot?
private var snapshotTask: Task<Void, Never>?
    
private(set)var memoryInspection: memoryInspector?

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

        var lastUIUpdate =
            ContinuousClock.now - minimumUIUpdateInterval

        var lastState: emulatorState?

        for await snapshot in stream
        {
            guard !Task.isCancelled else {
                break
            }

            let state = snapshot.executionSnapshot.emulatorState

            let stateChanged = state != lastState

            let now = ContinuousClock.now

            if !stateChanged &&
               now - lastUIUpdate < minimumUIUpdateInterval
            {
                continue
            }

            lastState = state
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
    
    UserDefaults.standard.register(
        defaults:
        [
            "memoryInspectionSelection": 0x0000
        ]
    )
    
    Task
    {
        @MainActor in
                let initialAddress: UInt16 = UInt16(UserDefaults.standard.integer(forKey: "memoryInspectionSelection"))
                let initialData = await cpu.updateMemoryInspector(address: initialAddress)
                
                self.memoryInspection = memoryInspector(memoryInspectorDump: initialData,memoryInspectionAddress: initialAddress)
    }
                
    startSnapshots()
}

//func updateMemoryInspector() async
//{
//    memoryInspection = await cpu.updateMemoryInspector(address: 0x0102)
//}
    
func toggleLogging() async

{
    await cpu.toggleLogging()
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
    
//        print(
//                "VM AFTER PAUSE:",
//                snapshot?.executionSnapshot.emulatorState as Any
//            )
}

func resetEmulation() async
{
    await cpu.reset()
}

func keyDown(_ key: MicrobeeKey) async
{
    await cpu.keyDown(key)
}

func keyUp(_ key: MicrobeeKey) async
{
    await cpu.keyUp(key)
}

func modifierChanged(_ modifier: HostModifier, pressed: Bool) async
{
    await cpu.modifierChanged(modifier, pressed: pressed)
}
}
