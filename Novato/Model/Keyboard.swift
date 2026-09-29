import Foundation
import AppKit
import Carbon.HIToolbox

enum MicrobeeKey: UInt8, CaseIterable, Hashable
{
    case atKey = 0
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
    case backSlashKey
    case rightSquareBracketKey
    case caretKey
    case deleteKey
    
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
    case minusKey
    case periodKey
    
    case forwardSlashKey
    case escapeKey
    case backSpaceKey
    case tabKey
    
    case lineFeedKey
    case returnKey
    
    case capsLockKey
    case breakKey
    case spaceKey
    
    case upArrowKey
    case ctrlKey
    
    case downArrowKey
    case leftArrowKey
    case resetKey
    case dummyKey
    case rightArrowKey
    
    case shiftKey
}

struct pastedKeyStroke
{
    let matrixValue: MicrobeeKey
    let shiftStatus: Bool
}

let symbolMap: [pastedKeyStroke] = [
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .returnKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .spaceKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .oneKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .twoKey , shiftStatus: true),
    pastedKeyStroke(matrixValue: .threeKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .fourKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .fiveKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .sixKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .sevenKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .eightKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .nineKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .colonKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .semicolonKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .commaKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .minusKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .periodKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .forwardSlashKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .zeroKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .oneKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .twoKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .threeKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .fourKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .fiveKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .sixKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .sevenKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .eightKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .nineKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .colonKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .semicolonKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .commaKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .minusKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .periodKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .backSlashKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .atKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .aKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .bKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .cKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .dKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .eKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .fKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .gKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .hKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .iKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .jKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .kKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .lKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .mKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .nKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .oKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .pKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .qKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .rKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .sKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .tKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .uKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .vKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .wKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .xKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .yKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .zKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .leftSquareBracketKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .backSlashKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .rightSquareBracketKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .caretKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .atKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .aKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .bKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .cKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .dKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .eKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .fKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .gKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .hKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .iKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .jKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .kKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .lKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .mKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .nKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .oKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .pKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .qKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .rKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .sKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .tKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .uKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .vKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .wKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .xKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .yKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .zKey, shiftStatus: false),
    pastedKeyStroke(matrixValue: .leftSquareBracketKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .backSlashKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .rightSquareBracketKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .caretKey, shiftStatus: true),
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false)]

struct MicrobeeKeyboardMapper
{
    static func key(for event: NSEvent) -> MicrobeeKey?
    {
        switch Int(event.keyCode)
        {
        case kVK_ANSI_1: return .oneKey
        case kVK_ANSI_2: return .twoKey
        case kVK_ANSI_3: return .threeKey
        case kVK_ANSI_4: return .fourKey
        case kVK_ANSI_5: return .fiveKey
        case kVK_ANSI_6: return .sixKey
        case kVK_ANSI_7: return .sevenKey
        case kVK_ANSI_8: return .eightKey
        case kVK_ANSI_9: return .nineKey
        case kVK_ANSI_0: return .zeroKey
            
        case kVK_ANSI_A: return .aKey
        case kVK_ANSI_B: return .bKey
        case kVK_ANSI_C: return .cKey
        case kVK_ANSI_D: return .dKey
        case kVK_ANSI_E: return .eKey
        case kVK_ANSI_F: return .fKey
        case kVK_ANSI_G: return .gKey
        case kVK_ANSI_H: return .hKey
        case kVK_ANSI_I: return .iKey
        case kVK_ANSI_J: return .jKey
        case kVK_ANSI_K: return .kKey
        case kVK_ANSI_L: return .lKey
        case kVK_ANSI_M: return .mKey
        case kVK_ANSI_N: return .nKey
        case kVK_ANSI_O: return .oKey
        case kVK_ANSI_P: return .pKey
        case kVK_ANSI_Q: return .qKey
        case kVK_ANSI_R: return .rKey
        case kVK_ANSI_S: return .sKey
        case kVK_ANSI_T: return .tKey
        case kVK_ANSI_U: return .uKey
        case kVK_ANSI_V: return .vKey
        case kVK_ANSI_W: return .wKey
        case kVK_ANSI_X: return .xKey
        case kVK_ANSI_Y: return .yKey
        case kVK_ANSI_Z: return .zKey
            
        case kVK_Space: return .spaceKey
        case kVK_Return: return .returnKey
        case kVK_Delete: return .backSpaceKey
        case kVK_Escape: return .escapeKey
            
        case kVK_Tab: return .tabKey
            
        case kVK_ANSI_Minus: return .minusKey
        case kVK_ANSI_LeftBracket: return .leftSquareBracketKey
        case kVK_ANSI_RightBracket: return .rightSquareBracketKey
        case kVK_ANSI_Backslash: return .backSlashKey
        case kVK_ANSI_Quote: return .atKey
        case kVK_ANSI_Comma: return .commaKey
        case kVK_ANSI_Semicolon: return .colonKey
        case kVK_ANSI_Period: return .periodKey
        case kVK_ANSI_Slash: return .forwardSlashKey
        case kVK_ANSI_Grave: return .caretKey
        case kVK_ANSI_Equal : return .semicolonKey
            
        case kVK_Home: return .lineFeedKey     //  Home maps to Line Feed
        case kVK_End: return .deleteKey       //  End maps to Delete
        case kVK_PageUp: return .breakKey        //  Page up maps to Break
        case kVK_PageDown: return .resetKey        //  Page down maps to Reset
            
        case kVK_UpArrow: return .upArrowKey
        case kVK_DownArrow: return .downArrowKey
        case kVK_LeftArrow: return .leftArrowKey
        case kVK_RightArrow: return .rightArrowKey
            
        default: return nil
        }
    }
    
    static func modifierChange(for event: NSEvent) -> MicrobeeModifierChange?
    {
        switch Int(event.keyCode)
        {
            case kVK_Shift: return MicrobeeModifierChange(modifier: .leftShift, pressed: event.modifierFlags.contains(.shift))
            case kVK_RightShift: return MicrobeeModifierChange(modifier: .rightShift, pressed: event.modifierFlags.contains(.shift))
            case kVK_Control,kVK_RightControl: return MicrobeeModifierChange(modifier: .control, pressed: event.modifierFlags.contains(.control))
            case kVK_CapsLock: return MicrobeeModifierChange(modifier: .capsLock, pressed: event.modifierFlags.contains(.capsLock))
            default: return nil
        }
    }
}

enum MicrobeeKeyboardType
{
    case emulated
    case natural
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
                case 31: bob = bob + "DEL(31) "
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
                case 56: bob = bob + "UP(56) "
                case 57: bob = bob + "CTRL(57) "
                case 58: bob = bob + "DOWN(58) "
                case 59: bob = bob + "LEFT(59) "
                case 60: bob = bob + "RESET(60) "
                case 62: bob = bob + "RIGHT(62) "
                case 63: bob = bob + "SHIFT(63) "
                default : bob = bob + "No key(255) "
                }}
        }
        print(message+bob)
    }
}
