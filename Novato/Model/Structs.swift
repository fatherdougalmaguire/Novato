import Foundation

enum emulatorState {
    case stopped, running, paused, halted
}

enum executionMode {
    case continuous,singleStep
}

struct z80Snapshot: Sendable, Equatable
{
    let PC: UInt16
    let SP: UInt16
    
    let BC: UInt16
    let DE: UInt16
    let HL: UInt16
    
    let altAF: UInt16
    let altBC: UInt16
    let altDE: UInt16
    let altHL: UInt16
    
    let IX: UInt16
    let IY: UInt16
    
    let I: UInt8
    let R: UInt8
    
    let IM: UInt8
    let IFF1: Bool
    let IFF2: Bool
    
    let A: UInt8
    let F: UInt8
    let B: UInt8
    let C: UInt8
    let D: UInt8
    let E: UInt8
    let H: UInt8
    let L: UInt8
    
    let altA: UInt8
    let altF: UInt8
    let altB: UInt8
    let altC: UInt8
    let altD: UInt8
    let altE: UInt8
    let altH: UInt8
    let altL: UInt8
}

struct crtcSnapshot: Sendable, Equatable
{
    let R0: UInt8         // Horiz Total-1
    let R1: UInt8        // Horiz Displayed
    let R2: UInt8        // Horiz Sync Position
    let R3: UInt8         // VSYSNC, HSYNC Widths
    let R4: UInt8         // Vert Total-1
    let R5: UInt8          // Vert Total Adjust
    let R6: UInt8          // Vert Displayed
    let R7: UInt8          // Vert Sync Position
    let R8: UInt8         // Mode Control
    let R9: UInt8          // Scan Lines-1
    let R10: UInt8         // Cursor Start and Blink Mode
    let R11: UInt8         // Cursor End
    let R12: UInt8        // Display Start Addr (H)
    let R13: UInt8          // Display Start Addr (L)
    let R14: UInt8         // Cursor Position (H)
    let R15: UInt8         // Cursor Position (L)
    let R16: UInt8        // Light Pen Reg (H)
    let R17: UInt8        // Light Pen Reg (L)
    let R18: UInt8         // Update Address Reg (H)
    let R19: UInt8         // Update Address Reg (L)
    
    let statusRegister : UInt8
    
    let redBackgroundIntensity : UInt8
    let greenBackgroundIntensity : UInt8
    let blueBackgroundIntensity : UInt8
}

struct memorySnapshot: Sendable, Equatable
{
    let VDU : [Float]
    let CharRom : [Float]
    let PcgRam: [Float]
    let ColourRam : [Float]
    let memoryDump : [UInt8]
}

struct executionSnapshot: Sendable, Equatable
{
    let tStates: UInt64
    
    let emulatorState: emulatorState
    let executionMode: executionMode
    
    let ports: [UInt8]

    let orderedZ80Queue: [String]
}

struct microbeeSnapshot: Sendable, Equatable, Identifiable
{
    let id: UUID
    let timestamp: Date

    let z80Snapshot: z80Snapshot
    let crtcSnapshot: crtcSnapshot
    let executionSnapshot: executionSnapshot
    let memorySnapshot: memorySnapshot
}
