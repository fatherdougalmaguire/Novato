import SwiftUI
import AppKit


func focusWindow(withId id: String)
{
    if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == id })
    {
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

struct StatusLED: View
{
    let colour: Color
    
    private let ledOnColor = Color.green
    private let ledOffColor = Color.red
    
    var body: some View
    {
        Circle()
            .fill(colour != ledOffColor ? colour : ledOffColor)
            .frame(width: 15, height: 15)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(colour != ledOffColor ? 0.4 : 0.1))
                    .frame(width: 3, height: 3)
                    .offset(x: -2, y: -2)
            )
            .shadow(color: colour != ledOffColor ? ledOnColor.opacity(0.8) : .clear, radius: 3)
            .animation(.easeInOut(duration: 0.1), value: colour != ledOffColor)
    }
}

struct emulatorView: View
{
    @Environment(emulatorViewModel.self) private var vm
    @Environment(\.openWindow) var openWindow
    
    @AppStorage("scalingSelection") private var charScale: Double = 2.0 // Scale for visibility on 27" screen ( 2560 x 1440 )
    @AppStorage("aspectSelection") private var charAspect: Double = 4/3  // Correction for CRT aspect ratio
    @AppStorage("colorSelection") private var colourSelection = "Colour"
    @AppStorage("bootModeSelection") private var bootModeSelection = "MicroWorld Basic 5.22e"
    @AppStorage("autoStartSelection") private var autoStartSelection: Bool = false
    @AppStorage("registerWindowVisible") private var registerWindowVisible: Bool = true
    @AppStorage("portWindowVisible") private var portWindowVisible: Bool = true
    @AppStorage("memoryWindowVisible") private var memoryWindowVisible: Bool = true
    @AppStorage("breakpointWindowVisible") private var breakpointWindowVisible: Bool = true
    
    let colourOptions: [String:Int] = ["Green":0,"Amber":1,"White":2,"Blue":3,"Colour":4]
    // 0 - green on black, 1 - amber on black, 2 - white on black, 3 - blue on black, 4 - Colour
    
    let startDate = Date()
    
    struct CRTCDisplayView: View
    {
        let snapshot: microbeeSnapshot
        let vm: emulatorViewModel
        let startDate: Date
        let colourSelection: String
        let colourOptions: [String: Int]
        let charScale: CGFloat
        let charAspect: CGFloat
        
        @AppStorage("interlaceEnabled") private var interlaceEnabled: Bool = false
        
        struct ScreenPipelineView: View {
            let baseWidth: CGFloat
            let baseHeight: CGFloat
            let scaledWidth: CGFloat
            let scaledHeight: CGFloat
            let charScale: CGFloat
            let charAspect: CGFloat
            let frameXScale: Double
            let frameYScale: Double
            let interlaceEnabled: Bool

            // Shader inputs
            let scanLineHeight: Float
            let displayColumns: Float
            let fontLocationOffset: Float
            let cursorPosition: Float
            let cursorStartScanLine: Float
            let cursorEndScanLine: Float
            let cursorBlinkType: Float
            let colourMode: Float
            let backGroundIntensity: Float
            let elapsedTime: Float
            let vduArray: [Float]
            let charRomArray: [Float]
            let pcgRamArray: [Float]
            let colourRamArray: [Float]

            var body: some View {
                Rectangle()
                    .frame(width: baseWidth, height: baseHeight)
                    .colorEffect(
                        ShaderLibrary.ScreenBuffer(
                            .float(scanLineHeight),
                            .float(displayColumns),
                            .float(fontLocationOffset),
                            .float(cursorPosition),
                            .float(cursorStartScanLine),
                            .float(cursorEndScanLine),
                            .float(cursorBlinkType),
                            .float(colourMode),
                            .float(backGroundIntensity),
                            .float(elapsedTime),
                            .floatArray(vduArray),
                            .floatArray(charRomArray),
                            .floatArray(pcgRamArray),
                            .floatArray(colourRamArray)
                        )
                    )
                    .colorEffect(
                        ShaderLibrary.interlace(.float(1.0), .float(0.2), .float(1.8), .float(interlaceEnabled ? 1.0 : 0.0)))
                                .brightness(Double(interlaceEnabled ? 0.1 : 0.0))
                                .saturation(Double(interlaceEnabled ? 1.8 : 1.0))
                    .scaleEffect(
                        x: charScale * CGFloat(frameXScale),
                        y: charScale * charAspect * CGFloat(frameYScale)
                    )
                    .frame(width: scaledWidth, height: scaledHeight)
            }
        }
        
        var body: some View
        {
            // Extract and clamp CRTC values with explicit typing to help the type checker
            let rawHorizDisplayed: Int = Int(snapshot.crtcSnapshot.R1)
            let horizDisplayed: Int = max(rawHorizDisplayed, 1)
            let rawScanLines: Int = Int(snapshot.crtcSnapshot.R9 + 1)
            let scanLines: Int = max(rawScanLines, 1)
            let vertDisplayed: Int = max(Int(snapshot.crtcSnapshot.R6), 1)

            // Compute frame dimensions
            let frameWidth: Int = 8 * horizDisplayed
            let frameHeight: Int = scanLines * vertDisplayed

            // Compute scale factors with explicit defaults
            let baseXScaleValue = 512.0 / Double(max(frameWidth, 1))
            let frameXScale: Double = baseXScaleValue.isFinite ? baseXScaleValue : 1.0
            let baseYScaleValue = 256.0 / Double(max(frameHeight, 1))
            let frameYScale: Double = baseYScaleValue.isFinite ? baseYScaleValue : 1.0

            // Cursor and display parameters
            let scanLineHeight: Float = Float(scanLines)
            let displayColumns: Float = Float(horizDisplayed)
            let cursorStartScanLine: Float = Float(Int(snapshot.crtcSnapshot.R10) & 0b00011111)
            let cursorEndScanLine: Float = Float(snapshot.crtcSnapshot.R11)
            let cursorBlinkType: Float = Float(Int(snapshot.crtcSnapshot.R10 >> 5))
            let fontLocationOffset: Float = Float(Int(snapshot.crtcSnapshot.R12) << 8 | Int(snapshot.crtcSnapshot.R13))
            let cursorPosition: Float = Float(Int(snapshot.crtcSnapshot.R14) << 8 | Int(snapshot.crtcSnapshot.R15))

            let colourMode: Float = Float(colourOptions[colourSelection] ?? 0)

            // Base and scaled sizes
            let baseWidth: CGFloat = max(CGFloat(frameWidth), 1)
            let baseHeight: CGFloat = max(CGFloat(frameHeight), 1)
            let scaledWidth: CGFloat = baseWidth * charScale * CGFloat(frameXScale)
            let scaledHeight: CGFloat = baseHeight * charScale * charAspect * CGFloat(frameYScale)

            let backGroundIntensity: Float = Float(
                (Int(snapshot.crtcSnapshot.redBackgroundIntensity) << 2) +
                (Int(snapshot.crtcSnapshot.greenBackgroundIntensity) << 1) +
                Int(snapshot.crtcSnapshot.blueBackgroundIntensity)
            )

            // Pre-extract large arrays to avoid recomputation and inference across modifier chains
            let vduArray: [Float] = snapshot.memorySnapshot.VDU
            let charRomArray: [Float] = snapshot.memorySnapshot.CharRom
            let pcgRamArray: [Float] = snapshot.memorySnapshot.PcgRam
            let colourRamArray: [Float] = snapshot.memorySnapshot.ColourRam

            TimelineView(.periodic(from: startDate, by: 0.02)) { context in
                let elapsedTime: Float = Float(context.date.timeIntervalSince(startDate))

                ScreenPipelineView(
                    baseWidth: baseWidth,
                    baseHeight: baseHeight,
                    scaledWidth: scaledWidth,
                    scaledHeight: scaledHeight,
                    charScale: charScale,
                    charAspect: charAspect,
                    frameXScale: frameXScale,
                    frameYScale: frameYScale,
                    interlaceEnabled: interlaceEnabled,
                    scanLineHeight: scanLineHeight,
                    displayColumns: displayColumns,
                    fontLocationOffset: fontLocationOffset,
                    cursorPosition: cursorPosition,
                    cursorStartScanLine: cursorStartScanLine,
                    cursorEndScanLine: cursorEndScanLine,
                    cursorBlinkType: cursorBlinkType,
                    colourMode: colourMode,
                    backGroundIntensity: backGroundIntensity,
                    elapsedTime: elapsedTime,
                    vduArray: vduArray,
                    charRomArray: charRomArray,
                    pcgRamArray: pcgRamArray,
                    colourRamArray: colourRamArray
                )
            }
        }
    }
    
    var body: some View
    {
        
            NavigationStack
            {
                VStack
                {
                    if let snapshot = vm.snapshot
                    {
                        CRTCDisplayView( snapshot: snapshot, vm: vm, startDate: startDate, colourSelection: colourSelection, colourOptions: colourOptions, charScale: charScale, charAspect: charAspect)
                    }
                    else
                    {
                        Color.black
                    }
                }
                .toolbar
                {
                    ToolbarItem(placement: .primaryAction)
                    {
                        StatusLED(colour: vm.isStepActive ? .orange : vm.snapshot?.executionSnapshot.emulatorState == .running ? .green : .red)
                    }
                    ToolbarItem(placement: .principal)
                    {
                        HStack(spacing: 40)
                        {
                            HStack(spacing: 12)
                            {
                                Button(vm.snapshot?.executionSnapshot.emulatorState == .running ? "Pause" : "Resume", systemImage: vm.snapshot?.executionSnapshot.emulatorState == .running ? "pause.fill" : "play.fill")
                                {
                                    Task
                                    {
                                        if vm.snapshot?.executionSnapshot.emulatorState == .running
                                        {
                                            await vm.pauseEmulation()
                                        }
                                        else
                                        {
                                            await vm.startEmulation()
                                        }
                                    }
                                }
                                .labelStyle(.titleAndIcon)
                                Button("Step", systemImage: "forward.frame.fill")
                                {
                                    Task
                                    {
                                        vm.isStepActive = true
                                        try? await Task.sleep(for: .milliseconds(200))
                                        vm.isStepActive = false
                                        await vm.stepEmulation()
                                    }
                                }
                                .labelStyle(.titleAndIcon)
                            }
                            HStack(spacing: 12)
                            {
                                Button("Reset", systemImage: "arrow.counterclockwise")
                                {
                                    Task
                                    {
                                        await vm.stopEmulation()
                                        try? await Task.sleep(for: .milliseconds(20))
                                        await vm.resetEmulation()
                                        await vm.startEmulation()
                                    }
                                }
                                .labelStyle(.titleAndIcon)
                                Button("Quit", systemImage: "xmark.circle")
                                { NSApp.terminate(nil) }
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                        .fixedSize()
                    }
                }
                .onAppear
                {
                    if registerWindowVisible { openWindow(id: "registerWindow") }
                    if portWindowVisible { openWindow(id: "portAndCrtcWindow") }
                    if memoryWindowVisible { openWindow(id: "memoryAndInstructionWindow") }
                    if breakpointWindowVisible { openWindow(id: "breakpointsWindow") }
                    focusWindow(withId: "emulatorWindow")
                    Task
                    {
                        await vm.updateProgramCounter(address: 0x8000)
                        await vm.startEmulation()
                    }
                }
            }
    } //body
} // emulatorView


