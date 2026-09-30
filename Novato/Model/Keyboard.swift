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
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  0
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  1
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  2
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  3
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  4
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  5
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  6
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  7
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  8
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  9
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  10
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  11
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  12
    pastedKeyStroke(matrixValue: .returnKey, shiftStatus: false),               //  13  carriage return
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  14
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  15
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  16
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  17
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  18
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  19
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  20
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  21
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  22
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  23
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  24
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  25
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  26
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  27
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  28
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  29
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  30
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  31
    pastedKeyStroke(matrixValue: .spaceKey, shiftStatus: false),                //  32  space
    pastedKeyStroke(matrixValue: .oneKey, shiftStatus: true),                   //  33  !
    pastedKeyStroke(matrixValue: .twoKey , shiftStatus: true),                  //  34  "
    pastedKeyStroke(matrixValue: .threeKey, shiftStatus: true),                 //  35  #
    pastedKeyStroke(matrixValue: .fourKey, shiftStatus: true),                  //  36  $
    pastedKeyStroke(matrixValue: .fiveKey, shiftStatus: true),                  //  37  %
    pastedKeyStroke(matrixValue: .sixKey, shiftStatus: true),                   //  38  &
    pastedKeyStroke(matrixValue: .sevenKey, shiftStatus: true),                 //  39  '
    pastedKeyStroke(matrixValue: .eightKey, shiftStatus: true),                 //  40  (
    pastedKeyStroke(matrixValue: .nineKey, shiftStatus: true),                  //  41  )
    pastedKeyStroke(matrixValue: .colonKey, shiftStatus: true),                 //  42  *
    pastedKeyStroke(matrixValue: .semicolonKey, shiftStatus: true),             //  43  +
    pastedKeyStroke(matrixValue: .commaKey, shiftStatus: false),                //  44  ,
    pastedKeyStroke(matrixValue: .minusKey, shiftStatus: false),                //  45  -
    pastedKeyStroke(matrixValue: .periodKey, shiftStatus: false),               //  46  .
    pastedKeyStroke(matrixValue: .forwardSlashKey, shiftStatus: false),         //  47  /
    pastedKeyStroke(matrixValue: .zeroKey, shiftStatus: false),                 //  48  0
    pastedKeyStroke(matrixValue: .oneKey, shiftStatus: false),                  //  49  1
    pastedKeyStroke(matrixValue: .twoKey, shiftStatus: false),                  //  50  2
    pastedKeyStroke(matrixValue: .threeKey, shiftStatus: false),                //  51  3
    pastedKeyStroke(matrixValue: .fourKey, shiftStatus: false),                 //  52  4
    pastedKeyStroke(matrixValue: .fiveKey, shiftStatus: false),                 //  53  5
    pastedKeyStroke(matrixValue: .sixKey, shiftStatus: false),                  //  54  6
    pastedKeyStroke(matrixValue: .sevenKey, shiftStatus: false),                //  55  7
    pastedKeyStroke(matrixValue: .eightKey, shiftStatus: false),                //  56  8
    pastedKeyStroke(matrixValue: .nineKey, shiftStatus: false),                 //  57  9
    pastedKeyStroke(matrixValue: .colonKey, shiftStatus: false),                //  58  :
    pastedKeyStroke(matrixValue: .semicolonKey, shiftStatus: false),            //  59  ;
    pastedKeyStroke(matrixValue: .commaKey, shiftStatus: true),                 //  60  <
    pastedKeyStroke(matrixValue: .minusKey, shiftStatus: true),                 //  61  =
    pastedKeyStroke(matrixValue: .periodKey, shiftStatus: true),                //  62  >
    pastedKeyStroke(matrixValue: .forwardSlashKey, shiftStatus: true),          //  63  ?
    pastedKeyStroke(matrixValue: .atKey, shiftStatus: false),                   //  64  @
    pastedKeyStroke(matrixValue: .aKey, shiftStatus: true),                     //  65  A
    pastedKeyStroke(matrixValue: .bKey, shiftStatus: true),                     //  66  B
    pastedKeyStroke(matrixValue: .cKey, shiftStatus: true),                     //  67  C
    pastedKeyStroke(matrixValue: .dKey, shiftStatus: true),                     //  68  D
    pastedKeyStroke(matrixValue: .eKey, shiftStatus: true),                     //  69  E
    pastedKeyStroke(matrixValue: .fKey, shiftStatus: true),                     //  70  F
    pastedKeyStroke(matrixValue: .gKey, shiftStatus: true),                     //  71  G
    pastedKeyStroke(matrixValue: .hKey, shiftStatus: true),                     //  72  H
    pastedKeyStroke(matrixValue: .iKey, shiftStatus: true),                     //  73  I
    pastedKeyStroke(matrixValue: .jKey, shiftStatus: true),                     //  74  J
    pastedKeyStroke(matrixValue: .kKey, shiftStatus: true),                     //  75  K
    pastedKeyStroke(matrixValue: .lKey, shiftStatus: true),                     //  76  L
    pastedKeyStroke(matrixValue: .mKey, shiftStatus: true),                     //  77  M
    pastedKeyStroke(matrixValue: .nKey, shiftStatus: true),                     //  78  N
    pastedKeyStroke(matrixValue: .oKey, shiftStatus: true),                     //  79  O
    pastedKeyStroke(matrixValue: .pKey, shiftStatus: true),                     //  80  P
    pastedKeyStroke(matrixValue: .qKey, shiftStatus: true),                     //  81  Q
    pastedKeyStroke(matrixValue: .rKey, shiftStatus: true),                     //  82  R
    pastedKeyStroke(matrixValue: .sKey, shiftStatus: true),                     //  83  S
    pastedKeyStroke(matrixValue: .tKey, shiftStatus: true),                     //  84  T
    pastedKeyStroke(matrixValue: .uKey, shiftStatus: true),                     //  85  U
    pastedKeyStroke(matrixValue: .vKey, shiftStatus: true),                     //  86  V
    pastedKeyStroke(matrixValue: .wKey, shiftStatus: true),                     //  87  W
    pastedKeyStroke(matrixValue: .xKey, shiftStatus: true),                     //  88  X
    pastedKeyStroke(matrixValue: .yKey, shiftStatus: true),                     //  89  Y
    pastedKeyStroke(matrixValue: .zKey, shiftStatus: true),                     //  90  Z
    pastedKeyStroke(matrixValue: .leftSquareBracketKey, shiftStatus: false),    //  91  [
    pastedKeyStroke(matrixValue: .backSlashKey, shiftStatus: false),            //  92  \
    pastedKeyStroke(matrixValue: .rightSquareBracketKey, shiftStatus: false),   //  93  ]
    pastedKeyStroke(matrixValue: .caretKey, shiftStatus: false),                //  94  ^
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false),                //  95
    pastedKeyStroke(matrixValue: .atKey, shiftStatus: true),                    //  96  `
    pastedKeyStroke(matrixValue: .aKey, shiftStatus: false),                    //  97  a
    pastedKeyStroke(matrixValue: .bKey, shiftStatus: false),                    //  98  b
    pastedKeyStroke(matrixValue: .cKey, shiftStatus: false),                    //  99  c
    pastedKeyStroke(matrixValue: .dKey, shiftStatus: false),                    //  100 d
    pastedKeyStroke(matrixValue: .eKey, shiftStatus: false),                    //  101 e
    pastedKeyStroke(matrixValue: .fKey, shiftStatus: false),                    //  102 f
    pastedKeyStroke(matrixValue: .gKey, shiftStatus: false),                    //  103 g
    pastedKeyStroke(matrixValue: .hKey, shiftStatus: false),                    //  104 h
    pastedKeyStroke(matrixValue: .iKey, shiftStatus: false),                    //  105 i
    pastedKeyStroke(matrixValue: .jKey, shiftStatus: false),                    //  106 j
    pastedKeyStroke(matrixValue: .kKey, shiftStatus: false),                    //  107 k
    pastedKeyStroke(matrixValue: .lKey, shiftStatus: false),                    //  108 l
    pastedKeyStroke(matrixValue: .mKey, shiftStatus: false),                    //  109 m
    pastedKeyStroke(matrixValue: .nKey, shiftStatus: false),                    //  110 n
    pastedKeyStroke(matrixValue: .oKey, shiftStatus: false),                    //  111 o
    pastedKeyStroke(matrixValue: .pKey, shiftStatus: false),                    //  112 p
    pastedKeyStroke(matrixValue: .qKey, shiftStatus: false),                    //  113 q
    pastedKeyStroke(matrixValue: .rKey, shiftStatus: false),                    //  114 r
    pastedKeyStroke(matrixValue: .sKey, shiftStatus: false),                    //  115 s
    pastedKeyStroke(matrixValue: .tKey, shiftStatus: false),                    //  116 t
    pastedKeyStroke(matrixValue: .uKey, shiftStatus: false),                    //  117 u
    pastedKeyStroke(matrixValue: .vKey, shiftStatus: false),                    //  118 v
    pastedKeyStroke(matrixValue: .wKey, shiftStatus: false),                    //  119 w
    pastedKeyStroke(matrixValue: .xKey, shiftStatus: false),                    //  120 x
    pastedKeyStroke(matrixValue: .yKey, shiftStatus: false),                    //  121 y
    pastedKeyStroke(matrixValue: .zKey, shiftStatus: false),                    //  122 z
    pastedKeyStroke(matrixValue: .leftSquareBracketKey, shiftStatus: true),     //  123 {
    pastedKeyStroke(matrixValue: .backSlashKey, shiftStatus: true),             //  124 |
    pastedKeyStroke(matrixValue: .rightSquareBracketKey, shiftStatus: true),    //  125 }
    pastedKeyStroke(matrixValue: .caretKey, shiftStatus: true),                 //  126 ~
    pastedKeyStroke(matrixValue: .dummyKey, shiftStatus: false)]                //  127

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
