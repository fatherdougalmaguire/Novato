import SwiftUI

struct EmulatorView: View
{
    @Environment(EmulatorViewModel.self) private var vm
    @Environment(\.openWindow) var openWindow
        
    let charScale : CGFloat = 2             // Scale for visibility on 27" screen ( 2560 x 1440 )
    let charAspect : CGFloat = 4/3          // Correction for CRT aspect ratio
    let phosphorColour : Float = 1          // 0 - green, 1 - amber, 2 - white, else black on white
    
    var body: some View
    {
        let frameWidth = 8*Int(vm.vmR1_HorizDisplayed)
        let frameHeight = Int(vm.vmR9_ScanLinesMinus1+1)*Int(vm.vmR6_VertDisplayed)
        let scanLineHeight = Float(vm.vmR9_ScanLinesMinus1+1)
        let displayColumns = Float(vm.vmR1_HorizDisplayed)
        let cursorStartScanLine = Float(Int(vm.vmR10_CursorStartAndBlinkMode) & 0b00001111 )
        let cursorEndScanLine = Float(vm.vmR11_CursorEnd)
        let cursorBlinkType = Float(Int(vm.vmR10_CursorStartAndBlinkMode) & 0b01110000 >> 4)
        let fontLocationOffset = Float(Int(vm.vmR12_DisplayStartAddrH) << 8 | Int(vm.vmR13_DisplayStartAddrL))
        let cursorPosition = Float(Int(vm.vmR14_CursorPositionH) << 8 | Int(vm.vmR15_CursorPositionL))
        let cursorBlinkCounter = Float(20)
        
        ZStack {
            Color.white
            VStack {
                Rectangle()
                    .frame(width: CGFloat(frameWidth), height: CGFloat(frameHeight),alignment: .center)
                    .colorEffect(ShaderLibrary.ScreenBuffer(.float(scanLineHeight), .float(displayColumns), .float(fontLocationOffset), .float(cursorPosition), .float(cursorStartScanLine), .float(cursorEndScanLine), .float(cursorBlinkType), .float( cursorBlinkCounter),.float(phosphorColour),.floatArray(vm.VDU),.floatArray(vm.CharRom)))
                    .scaleEffect(x: charScale,y:charScale*charAspect)
                    .frame(width: CGFloat(frameWidth)*charScale, height: CGFloat(frameHeight)*charScale*charAspect,alignment: .center)                
                HStack
                {
                    Button("Start", systemImage:"play.fill")
                    {
                        Task { await vm.startEmulation() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)
                    //.symbolEffect(.pulse, value: true)
                    
                    Button("Stop", systemImage:"stop.fill")
                    {
                        Task { await vm.stopEmulation() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)
                    
                    Button("Step", systemImage:"play.square.fill")
                    {
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)
                    .disabled(true)
                    
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
