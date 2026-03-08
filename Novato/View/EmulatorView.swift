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
    let isOn: Bool
    
    private let ledOnColor = Color.green
    private let ledOffColor = Color.red
    
    var body: some View
    {
        Circle()
            .fill(isOn ? ledOnColor : ledOffColor)
            .frame(width: 15, height: 15)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(isOn ? 0.4 : 0.1))
                    .frame(width: 3, height: 3)
                    .offset(x: -2, y: -2)
            )
            .shadow(color: isOn ? ledOnColor.opacity(0.8) : .clear, radius: 3)
            .animation(.easeInOut(duration: 0.1), value: isOn)
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
    
    @State private var isRunning = false
    
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
        if let snapshot = vm.snapshot
        {
            NavigationStack
            {
                VStack
                {
                    CRTCDisplayView( snapshot: snapshot, vm: vm, startDate: startDate, colourSelection: colourSelection, colourOptions: colourOptions, charScale: charScale, charAspect: charAspect)
                }
                .toolbar
                {
                    ToolbarItem(placement: .primaryAction)
                    {
                        StatusLED(isOn: isRunning)
                    }
                    ToolbarItem(placement: .principal)
                    {
                        HStack(spacing: 40)
                        {
                            HStack(spacing: 12)
                            {
                                Button(isRunning ? "Pause" : "Start", systemImage: isRunning ? "pause.fill" : "play.fill")
                                {
                                    Task
                                    {
                                        
                                        if isRunning
                                        {
                                            await vm.pauseEmulation()
                                        }
                                        else
                                        {
                                            await vm.startEmulation()
                                        }
                                        isRunning.toggle()
                                    }
                                }
                                .labelStyle(.titleAndIcon)
                                Button("Step", systemImage: "forward.frame.fill")
                                {
                                    Task
                                    {
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
                                        await vm.resetEmulation()
                                        
                                        switch bootModeSelection
                                        {
                                            //case "Demo #1 - Basic" : await vm.updateProgramCounter(address: 0x0900)
                                            case "Demo #1 - CP/M" : await vm.updateProgramCounter(address: 0x0903)
                                            case "Demo #2 - Viatel" : await vm.updateProgramCounter(address: 0x0906)
                                            case "MicroWorld Basic 5.22e" : await vm.updateProgramCounter(address: 0x8000)
                                            default: break
                                        }
                                        if autoStartSelection
                                        {
                                            isRunning =  true
                                            await vm.startEmulation()
                                        }
                                        else
                                        {
                                            isRunning =  false
                                            await vm.ClearEmulationScreen()
                                            await vm.splashScreen()
                                        }
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
                    openWindow(id: "registerWindow")
                    openWindow(id: "portAndCrtcWindow")
                    openWindow(id: "memoryAndInstructionWindow")
                    focusWindow(withId: "emulatorWindow")
                    Task
                    {
                        switch bootModeSelection
                        {
                            //case "Demo #1 - Basic" : await vm.updateProgramCounter(address: 0x0900)
                            case "Demo #1 - CP/M" : await vm.updateProgramCounter(address: 0x0903)
                            case "Demo #2 - Viatel" : await vm.updateProgramCounter(address: 0x0906)
                            case "MicroWorld Basic 5.22e" : await vm.updateProgramCounter(address: 0x8000)
                            default: break
                        }
                        if autoStartSelection
                        {
                            await vm.startEmulation()
                        }
                        else
                        {
                            await vm.splashScreen()
                        }
                    }
                }
            }
        }
        else
        {
            Text("Nothing to see here folks")
        }
    } //body
} // emulatorView


