import Foundation
import AppKit

enum MicrobeeKey: UInt8, CaseIterable, Hashable
{
    case ampersandKey = 0
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
    
    case leftSquareBracketKey
    case backslashKey
    case rightSquareBracketKey
    case caretKey
    case delKey
    
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
    
    case colonKey
    case semicolonKey
  
    case commaKey
    case dashKey
    case periodKey
    
    case forwardslashKey
    case escapeKey
    case backspaceKey
    case tabKey
    
    case linefeedKey
    case returnKey
    
    case capsLockKey
    case breakKey
    case spaceKey
    
    case dummy1Key
    case ctrlKey
    
    case dummy2Key
    case dummy3Key
    case dummy4Key
    case dummy5Key
    case dummy6Key
    
    case shiftKey
    
    case equalsKey
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
        case 0x01: return .sKey
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
            
        case 0x30: return .tabKey
            
        case 0x1B: return .dashKey
        case 0x21: return .rightSquareBracketKey
        case 0x1E: return .leftSquareBracketKey
        case 0x2A: return .backslashKey
        case 0x29: return .semicolonKey
        case 0x27: return .ampersandKey
        case 0x2B: return .commaKey
        case 0x2F: return .periodKey
        case 0x2C: return .forwardslashKey
            
        case 0x18 : return .equalsKey
            
        default: return nil
        }
    }
    
    static func modifierChange(for event: NSEvent) -> MicrobeeModifierChange?
    {
        
        switch event.keyCode
        {
        case 56: return MicrobeeModifierChange(modifier: .leftShift, pressed: event.modifierFlags.contains(.shift))
        case 60: return MicrobeeModifierChange(modifier: .rightShift, pressed: event.modifierFlags.contains(.shift))
        case 59: return MicrobeeModifierChange(modifier: .control, pressed: event.modifierFlags.contains(.control))
        case 57: return MicrobeeModifierChange(modifier: .capsLock, pressed: event.modifierFlags.contains(.capsLock))
        default: return nil
        }
    }
}

enum HostModifier
{
    case leftShift
    case rightShift
    case control
    case capsLock
}

struct MicrobeeModifierChange
{
    let modifier: HostModifier
    let pressed: Bool
}

final class MicrobeeKeyboard
{
    var keyMatrix: UInt64 = 0
    var pendingKeyPresses: UInt64 = 0
    
    var shiftKey: Bool = false
    var controlKey: Bool = false
    var capsLockKey: Bool = false

    @inline(__always)
    func keyDown(_ key: MicrobeeKey)
    {
        let mask = UInt64(1) << UInt64(key.rawValue)
        
        guard (keyMatrix & mask) == 0
        else
        {
            return
        }
        
        keyMatrix |= mask
//        pendingKeyPresses |= mask
        
    }

    @inline(__always)
    func keyUp(_ key: MicrobeeKey)
    {
        let mask = UInt64(1) << UInt64(key.rawValue)
        
        keyMatrix &= ~mask
    }

    @inline(__always)
    func isPressed(_ position: Int) -> Bool
    {
        let mask = UInt64(1) << UInt64(position)
        return (keyMatrix & mask) != 0
    }
    
//    func isPending(_ position: Int) -> Bool
//    {
//        let mask = UInt64(1) << UInt64(position)
//        return (pendingKeyPresses & mask) != 0
//    }
//
//    @inline(__always)
//    func takePending(_ position: Int) -> Bool
//    {
//        let mask = UInt64(1) << UInt64(position)
//
//        guard (pendingKeyPresses & mask) != 0 else {
//            return false
//        }
//
//        pendingKeyPresses &= ~mask
//        return true
//    }
    
    @inline(__always)
    func set(_ key: MicrobeeKey, pressed: Bool)
    {
        if pressed
        {
            keyDown(key)
        }
        else
        {
            keyUp(key)
        }
    }
    
    @inline(__always)
    func releaseAll()
    {
        keyMatrix = 0
        pendingKeyPresses = 0
    }
    
    @inline(__always)
    func clearLatch(position: Int)
    {
        let mask = UInt64(1) << UInt64(position)

        pendingKeyPresses &= ~mask
    }
    
    @inline(__always)
    func printMatrix( _ message : String, _ matrix: UInt64)
    {
        var bob : String = ""
        for matrixpos in 0...63
        {
            let mask = UInt64(1) << UInt64(matrixpos)
            let pressed = (matrix & mask) != 0
            if pressed{
                switch matrixpos
                {
                case 0 : bob = bob + "@(0) "
                case 1...26 : if let scalar = UnicodeScalar(matrixpos + 64) { bob = bob+String(scalar)+"("+String(matrixpos)+") " } else { bob = "?" }
                case 27: bob = bob + "[(27) "
                case 28: bob = bob + "\\(28) "
                case 29: bob = bob + "](29) "
                case 30: bob = bob + "`(30) "
                case 32...41: if let scalar = UnicodeScalar(matrixpos + 16) { bob = bob + String(scalar)+"("+String(matrixpos)+") " } else { bob = "?" }
                case 42: bob = bob + "colon(42) "
                case 43: bob = bob + "+(43) "
                case 44: bob = bob + ",(44) "
                case 45: bob = bob + "-(45) "
                case 46: bob = bob + ".(46) "
                case 47: bob = bob + "/(47) "
                case 48: bob = bob + "ESC(48) "
                case 49: bob = bob + "BACKSPACE(49) "
                case 50: bob = bob + "TAB(50) "
                case 51: bob = bob + "LINE FEED(51) "
                case 52: bob = bob + "RETURN(52) "
                case 53: bob = bob + "CAPS LOCK(53) "
                case 54: bob = bob + "BREAK(54) "
                case 55: bob = bob + "SPACE(55) "
                case 57: bob = bob + "CTRL(57) "
                case 63: bob = bob + "SHIFT(63) "
                default : bob = bob + "No key(255) "
                }}
        }
        print(message+bob)
    }
    
}
