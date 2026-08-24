import Foundation
import AppKit

enum emulatorState
{
    case stopped, running, paused, halted
}

enum MicrobeeKey: Hashable
{
    case aKey
    case bKey
    case cKey
    case dKey
    case eKey
    case fKey
    case gKey
    case hKey
    case iKey
    case jKey
    case kKey
    case lKey
    case mKey
    case nKey
    case oKey
    case pKey
    case qKey
    case rKey
    case sKey
    case tKey
    case uKey
    case vKey
    case wKey
    case xKey
    case yKey
    case zKey

    case zeroKey
    case oneKey
    case twoKey
    case threeKey
    case fourKey
    case fiveKey
    case sixKey
    case sevenKey
    case eightKey
    case nineKey

    case spaceKey
    case returnKey
    case backspaceKey
    case escapeKey
    case tabKey

    case shiftKey
    case controlKey
    case capslockKey

    case resetKey
    case linefeedKey
    case breakKey

    case backtickKey
    case dashKey
    case equalsKey
    case rightSquareBracketKey
    case leftSquareBracketKey
    case backslashKey
    case semicolonKey
    case forwardtickKey
    case commaKey
    case periodKey
    case forwardslashKey
    
    case tildeKey
    case exclamationKey
    case atsignKey
    case hashKey
    case dollarsignKey
    case percentageKey
    case caretKey
    case ampersandKey
    case asteriskKey
    case leftRoundBracketKey
    case rightRoundBracketKey
    case plusKey
    case leftParenthesisKey
    case rightParenthesisKey
    case pipeKey
    case colonKey
    case doubleQuoteKey
    case lessThanKey
    case greaterThanKey
    case questionMarkKey
}

struct MicrobeeKeyboardMapper
{

    static func key(for event: NSEvent) -> MicrobeeKey?
    {
        switch event.keyCode
        {
            
        case 0x12: return .oneKey    
        case 0x13: return .twoKey
        case 0x14: return .threeKey
        case 0x15: return .fourKey
        case 0x16: return .sixKey
        case 0x17: return .fiveKey
        case 0x19: return .nineKey
        case 0x1A: return .sevenKey
        case 0x1C: return .eightKey
        case 0x1D: return .zeroKey
            
        case 0x00: return .aKey
        case 0x0B: return .bKey
        case 0x08: return .cKey
        case 0x02: return .dKey
        case 0x0E: return .eKey
        case 0x03: return .fKey
        case 0x05: return .gKey
        case 0x04: return .hKey
        case 0x22: return .iKey
        case 0x26: return .jKey
        case 0x28: return .kKey
        case 0x25: return .lKey
        case 0x2E: return .mKey
        case 0x2D: return .nKey
        case 0x1F: return .oKey
        case 0x23: return .pKey
        case 0x0C: return .qKey
        case 0x0F: return .rKey
        case 0x11: return .tKey
        case 0x20: return .uKey
        case 0x09: return .vKey
        case 0x0D: return .wKey
        case 0x07: return .xKey
        case 0x10: return .yKey
        case 0x06: return .zKey

        case 0x31: return .spaceKey
        case 0x24: return .returnKey
        case 0x33: return .backspaceKey
        case 0x35: return .escapeKey
            
        case 0x32: return .backtickKey
            
        case 0x30: return .tabKey
        
        case 0x1B: return .dashKey
        case 0x18: return .equalsKey
        case 0x21: return .rightSquareBracketKey
        case 0x1E: return .leftSquareBracketKey
        case 0x2A: return .backslashKey
        case 0x29: return .semicolonKey
        case 0x27: return .forwardtickKey
        case 0x2B: return .commaKey
        case 0x2F: return .periodKey
        case 0x2C: return .forwardslashKey

        default:
            return nil
        }
    }
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
    let R31: UInt8         // Dummy register
    
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
    let totalTStates: UInt64
    
    let emulatorState: emulatorState
    
    let ports: [UInt8]
    
    let orderedZ80Queue: [String]
    
    let breakpointQueue: [String]
    let breakpointQueueMask: [Bool]
    
    let currentInstruction : String
}

struct microbeeSnapshot: Sendable, Equatable, Identifiable
{
    let id: UUID
    let timestamp: Date

    let stepping: Bool
    
    let z80Snapshot: z80Snapshot
    let crtcSnapshot: crtcSnapshot
    let executionSnapshot: executionSnapshot
    let memorySnapshot: memorySnapshot
}

struct CPUState: Decodable, Sendable, Equatable
{
    let A,F,B,C,D,E,H,L : UInt8
    
    let altAF,altBC,altDE,altHL : UInt16
    
    let I,R : UInt8
    
    let IM : UInt8
    
    let IFF1,IFF2 : UInt8
    
    let IX,IY : UInt16
    
    let PC,SP : UInt16
    
    let WZ : UInt16
    
    let Q : UInt8
    
    let P : UInt8
    
    let EI : UInt8
  
    let ram: [[Int]]

    enum CodingKeys: String, CodingKey
    {
        case PC = "pc"
        case SP = "sp"
        case A = "a"
        case F = "f"
        case B = "b"
        case C = "c"
        case D = "d"
        case E = "e"
        case H = "h"
        case L = "l"

        case altAF = "af_"
        case altBC = "bc_"
        case altDE = "de_"
        case altHL = "hl_"
        
        case I = "i"
        case R = "r"
        
        case IM = "im"
        case IFF1 = "iff1"
        case IFF2 = "iff2"
        
        case IX = "ix"
        case IY = "iy"
        
        case WZ = "wz"
        
        case Q = "q"
        
        case P = "p"
        
        case EI = "ei"
        
        case ram = "ram"
    }
}
