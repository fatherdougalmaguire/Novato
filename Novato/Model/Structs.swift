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

enum emulatorState {
    case stopped, running, paused, halted
}

enum executionMode {
    case continuous,singleStep
}
