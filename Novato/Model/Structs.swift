import Foundation

struct CPUState
{
    let PC : UInt16
    let lastPC : UInt16
    
    let SP : UInt16
    
    let BC : UInt16
    let DE : UInt16
    let HL : UInt16
    
    let AltBC : UInt16
    let AltDE : UInt16
    let AltHL : UInt16
    
    let IX : UInt16
    let IY : UInt16
    
    let I : UInt8
    let R : UInt8
    
    let IM : UInt8        
    let IFF1 : Bool
    let IFF2 : Bool
    
    let A : UInt8
    let F : UInt8
    let B : UInt8
    let C : UInt8
    let D : UInt8
    let E : UInt8
    let H : UInt8
    let L : UInt8
    
    let AltA : UInt8
    let AltF : UInt8
    let AltB : UInt8
    let AltC : UInt8
    let AltD : UInt8
    let AltE : UInt8
    let AltH : UInt8
    let AltL : UInt8
    
    let memoryDump : [UInt8]
    let ports : [UInt8]
    
    let VDU : [Float]
    let CharRom : [Float]
    var PcgRam: [Float]
    var ColourRam : [Float]
    
    let vmR1_HorizDisplayed : UInt8
    let vmR6_VertDisplayed : UInt8
    let vmR9_ScanLinesMinus1 : UInt8
    let vmR10_CursorStartAndBlinkMode : UInt8
    let vmR11_CursorEnd : UInt8
    let vmR12_DisplayStartAddrH : UInt8
    let vmR13_DisplayStartAddrL : UInt8
    let vmR14_CursorPositionH : UInt8
    let vmR15_CursorPositionL : UInt8
    
    let vmRedBackgroundIntensity : UInt8
    let vmGreenBackgroundIntensity : UInt8
    let vmBlueBackgroundIntensity : UInt8
    
    let Z80Queue : Z80Queue
    
    let emulatorState : emulatorState

    var tStates  : UInt64
}

enum emulatorState: Sendable, Equatable
{
    case stopped, running, paused, halted
}

enum executionMode: Sendable, Equatable
{
    case continuous,singleStep
}

struct z80Snapshot: Sendable, Equatable
{
    let PC : UInt16
    let lastPC : UInt16
    
    let SP : UInt16
    
    let BC : UInt16
    let DE : UInt16
    let HL : UInt16
    
    let AltBC : UInt16
    let AltDE : UInt16
    let AltHL : UInt16
    
    let IX : UInt16
    let IY : UInt16
    
    let I : UInt8
    let R : UInt8
    
    let IM : UInt8
    let IFF1 : Bool
    let IFF2 : Bool
    
    let A : UInt8
    let F : UInt8
    let B : UInt8
    let C : UInt8
    let D : UInt8
    let E : UInt8
    let H : UInt8
    let L : UInt8
    
    let AltA : UInt8
    let AltF : UInt8
    let AltB : UInt8
    let AltC : UInt8
    let AltD : UInt8
    let AltE : UInt8
    let AltH : UInt8
    let AltL : UInt8
}

struct crtcSnapshot: Sendable, Equatable
{
    let R0: UInt8                                     // Ignored by emulator - Total length of line (displayed and non-displayed cycles (retrace) in CCLK cylces minus 1
    let R1 : UInt8                                       // Number of characters displayed in a line
    let R2 : UInt8 = 0x00                             // Ignored by emulator - The position of the horizontal sync pulse start in distance from line start
    let R3 : UInt8 = 0x00                            // Ignored by emulator
    let R4 : UInt8 = 0x12                               // The number of character lines of the screen minus 1
    let R5 : UInt8 = 0x00                               // Ignored by emulator - The additional number of scanlines to complete a screen
    let R6 : UInt8
    let R7 : UInt8 = 0x00                              // Ignored by emulator - Position of the vertical sync pulse in character lines.
    let R8 : UInt8 = 0x00                                   // Ignored by emulator
    let R9 : UInt8
    let R10 : UInt8
    let R11 : UInt8
    let R12 : UInt8
    let R13 : UInt8
    let R14 : UInt8
    let R15 : UInt8
    let R16 : UInt8 = 0x00                                 // Ignored by emulator
    let R17 : UInt8 = 0x00                                 // Ignored by emulator
    let R18 : UInt8 = 0x00                            // Ignored by emulator
    let R19 : UInt8 = 0x00                            // Ignored by emulator
    
    let StatusRegister : UInt8 = 0b10000000
    
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
    
    let ports : [UInt8]

    let z80Queue : Z80Queue
}

struct microbeeSnapshot: Sendable, Equatable, Identifiable
{
    let id: UUID
 // let timestamp: ContinuousClock.Instant

    let z80Snapshot: z80Snapshot
    let crtcSnapshot: crtcSnapshot
    let executionSnapshot: executionSnapshot
    let memorySnapshot: memorySnapshot
}


