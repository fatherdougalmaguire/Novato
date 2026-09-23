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
    case dashKey
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
    case dummy5Key
    case rightArrowKey
    
    case shiftKey
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
        case 0x33: return .backSpaceKey
        case 0x35: return .escapeKey
            
        case 0x30: return .tabKey
            
        case 0x1B: return .dashKey
        case 0x21: return .leftSquareBracketKey
        case 0x1E: return .rightSquareBracketKey
        case 0x2A: return .backSlashKey
        case 0x29: return .semicolonKey
        case 0x27: return .ampersandKey
        case 0x2B: return .commaKey
        case 0x2F: return .periodKey
        case 0x2C: return .forwardSlashKey
            
        case 0x73 : return .lineFeedKey     //  Home maps to Line Feed
        case 0x77 : return .deleteKey       //  End maps to Delete
        case 0x74 : return .breakKey        //  Page up maps to Break
        case 0x79 : return .resetKey        //  Page down maps to Reset
            
        case 0x7E : return .upArrowKey
        case 0x7D : return .downArrowKey
        case 0x7B : return .leftArrowKey
        case 0x7C : return .rightArrowKey
            
        default: return nil
        }
    }
    
    static func modifierChange(for event: NSEvent) -> MicrobeeModifierChange?
    {
        switch event.keyCode
        {
        case 0x38: return MicrobeeModifierChange(modifier: .leftShift, pressed: event.modifierFlags.contains(.shift))
        case 0x3C: return MicrobeeModifierChange(modifier: .rightShift, pressed: event.modifierFlags.contains(.shift))
        case 0x3B,0x3E: return MicrobeeModifierChange(modifier: .control, pressed: event.modifierFlags.contains(.control))
        case 0x39: return MicrobeeModifierChange(modifier: .capsLock, pressed: event.modifierFlags.contains(.capsLock))
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
    
    func highResTimestamp() -> UInt64 {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)

        let t = mach_absolute_time()
        return t &* UInt64(timebase.numer) / UInt64(timebase.denom)
    }
    
    private(set) var keyMatrix: [Bool] = Array(repeating: false, count: 64)

    private var keyMatrixCounter: [Int] = Array(repeating: 0, count: 64)

    private var keyMatrixHostDown: [Bool] = Array(repeating: false, count: 64)
    
    //var keyMatrix: UInt64 = 0
    
    var shiftKey: Bool = false
    var controlKey: Bool = false
    var capsLockKey: Bool = false
    
    private let stickyFrames: Int = 5

    @inline(__always)
    func keyDown(_ key: MicrobeeKey)
    {
        let position = Int(key.rawValue)

        guard position >= 0 && position < 64
        else { return }
        
        keyMatrix[position] = true
        keyMatrixCounter[position] = stickyFrames
        keyMatrixHostDown[position] = true
        
        print("down",position,key,keyMatrix[position],
              keyMatrixCounter[position],keyMatrixHostDown[position])
       
    }

    @inline(__always)
    func keyUp(_ key: MicrobeeKey)
    {
        let position = Int(key.rawValue)

        
        guard position >= 0 && position < 64
        else { return }

        keyMatrixHostDown[position] = false
        
        print("up",position,key,keyMatrix[position],
              keyMatrixCounter[position],keyMatrixHostDown[position])
    }

    @inline(__always)
    func isPressed(_ position: Int) -> Bool
    {
        guard position >= 0 && position < 64
        else { return false }
        
        return keyMatrix[position]
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
        keyMatrix = Array(repeating: false, count: 64)
        keyMatrixCounter = Array(repeating: 0, count: 64)
        keyMatrixHostDown = Array(repeating: false, count: 64)
    }
    
    func tickFrame()
    {
        for i in 0..<64
        {
            if keyMatrixCounter[i] > 0
            {
                keyMatrixCounter[i] = keyMatrixCounter[i] - 1
            }

            // Only release the key once the hold period has expired
            // AND the host has already released it
            if keyMatrixCounter[i] == 0 && !keyMatrixHostDown[i] && keyMatrix[i]
            {
                keyMatrix[i] = false
                print("MATRIX released  key \(i)")
            }
        }
    }
    
    @inline(__always)
    func printMatrix( _ message : String, _ matrix: UInt64)
    {
//        var bob : String = ""
//        for matrixpos in 0...63
//        {
//            let mask = UInt64(1) << UInt64(matrixpos)
//            let pressed = (matrix & mask) != 0
//            if pressed{
//                switch matrixpos
//                {
//                case 0 : bob = bob + "@(0) "
//                case 1...26 : if let scalar = UnicodeScalar(matrixpos + 64) { bob = bob+String(scalar)+"("+String(matrixpos)+") " } else { bob = "?" }
//                case 27: bob = bob + "[(27) "
//                case 28: bob = bob + "\\(28) "
//                case 29: bob = bob + "](29) "
//                case 30: bob = bob + "`(30) "
//                case 32...41: if let scalar = UnicodeScalar(matrixpos + 16) { bob = bob + String(scalar)+"("+String(matrixpos)+") " } else { bob = "?" }
//                case 42: bob = bob + "colon(42) "
//                case 43: bob = bob + "+(43) "
//                case 44: bob = bob + ",(44) "
//                case 45: bob = bob + "-(45) "
//                case 46: bob = bob + ".(46) "
//                case 47: bob = bob + "/(47) "
//                case 48: bob = bob + "ESC(48) "
//                case 49: bob = bob + "BACKSPACE(49) "
//                case 50: bob = bob + "TAB(50) "
//                case 51: bob = bob + "LINE FEED(51) "
//                case 52: bob = bob + "RETURN(52) "
//                case 53: bob = bob + "CAPS LOCK(53) "
//                case 54: bob = bob + "BREAK(54) "
//                case 55: bob = bob + "SPACE(55) "
//                case 57: bob = bob + "CTRL(57) "
//                case 63: bob = bob + "SHIFT(63) "
//                default : bob = bob + "No key(255) "
//                }}
//        }
//        print(message+bob)
    }
}
