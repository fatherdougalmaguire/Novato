import Foundation

class CRTC
{
    var crtcRegisters = CRTCRegisters()

    struct HiResTimer
    {
        private static let timebase: mach_timebase_info_data_t =
        {
            var info = mach_timebase_info_data_t()
            mach_timebase_info(&info)
            return info
        }()
        
        static func now() -> UInt64
        {
            let ticks = mach_absolute_time()
            return ticks * UInt64(timebase.numer) / UInt64(timebase.denom)
        }
        
        static func secondsSince(_ start: UInt64) -> Double
        {
            let timePassed = Double(now() - start) / 1_000_000_000.0
            guard timePassed == 0.00
            else
            {
                return 0.0015
            }
            return timePassed
        }
    }

    func SetCursorDutyCycle()
    {
        var flashRate : Double
        
        let frameStart = HiResTimer.now()
        for _ in 0..<10000 { }
        let elapsed = HiResTimer.secondsSince(frameStart)
        if Int(crtcRegisters.R10_CursorStartAndBlinkMode >> 5) == 2
        {
            flashRate = 12.5
        }
        else
        {
            flashRate = 6.25
        }
        guard !(((flashRate/elapsed).isNaN) || ((flashRate/elapsed).isInfinite))
        else
        {
            crtcRegisters.CursorFlashLimit = 4166
            return
        }
        crtcRegisters.CursorFlashLimit = Int(flashRate/elapsed)
    }
    
    func ResetCursorDutyCycle()
    
    {
        crtcRegisters.CursorBlinkCounter = crtcRegisters.CursorBlinkCounter+1
        if crtcRegisters.CursorBlinkCounter > crtcRegisters.CursorFlashLimit*2
        {
            crtcRegisters.CursorBlinkCounter = 0
        }
    }
    
    func ReadStatusRegister() -> UInt8
    {
     return crtcRegisters.StatusRegister
    }
    
    func WriteRegister(RegNum:UInt8, RegValue:UInt8)
    {
        switch RegNum
        {
        case 0: crtcRegisters.R0_HorizTotalMinus1 = RegValue
        case 1: crtcRegisters.R1_HorizDisplayed = RegValue
        case 2: crtcRegisters.R2_HorizSyncPosition = RegValue
        case 3: crtcRegisters.R3_VSynchHSynchWidths = RegValue
        case 4: crtcRegisters.R4_VertTotalMinus1 = RegValue
        case 5: crtcRegisters.R5_VertTotalAdjust = RegValue
        case 6: crtcRegisters.R6_VertDisplayed = RegValue
        case 7: crtcRegisters.R7_VertSyncPosition = RegValue
        case 8: crtcRegisters.R8_ModeControl = RegValue
        case 9: crtcRegisters.R9_ScanLinesMinus1 = RegValue
        case 10:
            let oldBlinkMode = Int(crtcRegisters.R10_CursorStartAndBlinkMode >> 5)
            let NewBlinkMode = Int(RegValue >> 5)
            if oldBlinkMode != NewBlinkMode
            {
                SetCursorDutyCycle()
                crtcRegisters.CursorBlinkCounter = 0
            }
            crtcRegisters.R10_CursorStartAndBlinkMode = RegValue
        case 11: crtcRegisters.R11_CursorEnd = RegValue
        case 12: crtcRegisters.R12_DisplayStartAddrH = RegValue
        case 13: crtcRegisters.R13_DisplayStartAddrL = RegValue
        case 14: crtcRegisters.R14_CursorPositionH = RegValue
        case 15: crtcRegisters.R15_CursorPositionL = RegValue
        case 16: crtcRegisters.R16_LightPenRegH  = RegValue
        case 17: crtcRegisters.R17_LightPenRegL = RegValue
        case 18: crtcRegisters.R18_UpdateAddressRegH = RegValue
        case 19: crtcRegisters.R19_UpdateAddressRegL = RegValue
        default: break
        }
    }
    
    func ReadRegister(RegNum:UInt8) -> UInt8
    {
        switch RegNum
        {
        case 0: return crtcRegisters.R0_HorizTotalMinus1
        case 1: return crtcRegisters.R1_HorizDisplayed
        case 2: return crtcRegisters.R2_HorizSyncPosition
        case 3: return crtcRegisters.R3_VSynchHSynchWidths
        case 4: return crtcRegisters.R4_VertTotalMinus1
        case 5: return crtcRegisters.R5_VertTotalAdjust
        case 6: return crtcRegisters.R6_VertDisplayed
        case 7: return crtcRegisters.R7_VertSyncPosition
        case 8: return crtcRegisters.R8_ModeControl
        case 9: return crtcRegisters.R9_ScanLinesMinus1
        case 10: return crtcRegisters.R10_CursorStartAndBlinkMode
        case 11: return crtcRegisters.R11_CursorEnd
        case 12: return crtcRegisters.R12_DisplayStartAddrH
        case 13: return crtcRegisters.R13_DisplayStartAddrL
        case 14: return crtcRegisters.R14_CursorPositionH
        case 15: return crtcRegisters.R15_CursorPositionL
        case 16: return crtcRegisters.R16_LightPenRegH
        case 17: return crtcRegisters.R17_LightPenRegL
        case 18: return crtcRegisters.R18_UpdateAddressRegH
        case 19: return crtcRegisters.R19_UpdateAddressRegL
        default: return 0
        }
    }
}
