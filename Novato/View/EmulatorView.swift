import SwiftUI

struct LED: View
{
    let isOn: Bool
    let color: Color   // e.g. .green, .red, .yellow
    
    var body: some View
    {
        Circle()
            .fill(isOn ? color : color.opacity(0.15))
            .frame(width: 15, height: 15)
            .overlay(
                Circle()
                    .strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isOn ? color.opacity(0.6) : .clear,
                    radius: isOn ? 6 : 0, x: 0, y: 0)
    }
}

struct EmulatorView: View
{
    @Environment(EmulatorViewModel.self) private var vm
    @Environment(\.openWindow) var openWindow
    
    @State var cursorBlinkCounter : Float = 0
    @State private var powerOn = true
        
    let charScale : CGFloat = 2             // Scale for visibility on 27" screen ( 2560 x 1440 )
    let charAspect : CGFloat = 4/3          // Correction for CRT aspect ratio
    let phosphorColour : Float = 1          // 0 - green, 1 - amber, 2 - white, 3 - blue else black on white
    
    var body: some View
    {
        // Safely derive dimensions and uniforms
        let rawHorizDisplayed = Int(vm.vmR1_HorizDisplayed)
        let horizDisplayed = max(rawHorizDisplayed, 1)
        let rawScanLines = Int(vm.vmR9_ScanLinesMinus1 + 1)
        let scanLines = max(rawScanLines, 1)
        let vertDisplayed = max(Int(vm.vmR6_VertDisplayed), 1)

        let frameWidth = 8 * horizDisplayed
        let frameHeight = scanLines * vertDisplayed

        // Prevent division by zero and non-finite scaling
        let baseXScale = 512.0 / Double(max(frameWidth, 1))
        let frameXScale = baseXScale.isFinite ? baseXScale : 1.0
        let baseYScale = 256.0 / Double(max(frameHeight, 1))
        let frameYScale = baseYScale.isFinite ? baseYScale : 1.0

        let scanLineHeight = Float(scanLines)
        let displayColumns = Float(horizDisplayed)
        let cursorStartScanLine = Float(Int(vm.vmR10_CursorStartAndBlinkMode) & 0b00011111)
        let cursorEndScanLine = Float(vm.vmR11_CursorEnd)
        let cursorBlinkType = Float(Int(vm.vmR10_CursorStartAndBlinkMode >> 5))
        let fontLocationOffset = Float(Int(vm.vmR12_DisplayStartAddrH) << 8 | Int(vm.vmR13_DisplayStartAddrL))
        let cursorPosition = Float(Int(vm.vmR14_CursorPositionH) << 8 | Int(vm.vmR15_CursorPositionL))
        let cursorBlinkCounter = Float(vm.vmCursorBlinkCounter)
        let cursorFlashLimit = Float(vm.vmCursorFlashLimit) / 2

        let baseWidth = max(CGFloat(frameWidth), 1)
        let baseHeight = max(CGFloat(frameHeight), 1)
        let scaledWidth = baseWidth * charScale * frameXScale
        let scaledHeight = baseHeight * charScale * charAspect * frameYScale

        ZStack {
            Color.white
            VStack {
                Rectangle()
                    .frame(width: baseWidth, height: baseHeight, alignment: .center)
                    .colorEffect(ShaderLibrary.ScreenBuffer(.float(scanLineHeight), .float(displayColumns), .float(fontLocationOffset), .float(cursorPosition), .float(cursorStartScanLine), .float(cursorEndScanLine), .float(cursorBlinkType), .float( cursorBlinkCounter),.float(cursorFlashLimit),.float(phosphorColour),.floatArray(vm.VDU),.floatArray(vm.CharRom)))
                    .scaleEffect(x: charScale * CGFloat(frameXScale), y: charScale * charAspect * CGFloat(frameYScale))
                    .frame(width: scaledWidth, height: scaledHeight, alignment: .center)
                HStack
                {
                    LED(isOn: powerOn, color: .red)
                    Button("Start", systemImage:"play.fill")
                    {
                        LED(isOn: powerOn, color: .green)
                        Task { await vm.startEmulation() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)
                    .symbolEffect(.pulse, value: true)
                    
                    Button("Stop", systemImage:"stop.fill")
                    {
                        Task { await vm.stopEmulation() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)
                    
                    Button("Step", systemImage:"play.square.fill")
                    {
                       Task { await vm.stepEmulation() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)
                } //hstack
                
                HStack
                {
                    Button("Reset", systemImage:"arrow.trianglehead.clockwise.rotate.90")
                    {
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)
                    .disabled(true)
                    
                    Button("Quit", systemImage:"power")
                    {
                        NSApp.terminate(nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)
                } //hstack
                
                Spacer()
                
            } //vstack
        }  //zstack
        .onAppear
        {
            openWindow(id: "DebugWindow")
        }
    }
} // struct
