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
    @AppStorage("demoSelection") private var demoSelection = "Microworld Basic (64x16)"
    
   // @State private var powerOn = true
    @State private var ClearScreen = true
    @State private var isRunning = false
    
    let colourOptions: [String:Int] = ["Green":0,"Amber":1,"White":2,"Blue":3,"Colour":4,"Premium Colour":5]
    // 0 - green on black, 1 - amber on black, 2 - white on black, 3 - blue on black, 4 - Colour else Premium colour mode
    
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

        var body: some View
        {
            let rawHorizDisplayed = Int(snapshot.crtcSnapshot.R1)
            let horizDisplayed = max(rawHorizDisplayed, 1)
            let rawScanLines = Int(snapshot.crtcSnapshot.R9 + 1)
            let scanLines = max(rawScanLines, 1)
            let vertDisplayed = max(Int(snapshot.crtcSnapshot.R6), 1)
            
            let frameWidth = 8 * horizDisplayed
            let frameHeight = scanLines * vertDisplayed
            
            let baseXScale = 512.0 / Double(max(frameWidth, 1))
            let frameXScale = baseXScale.isFinite ? baseXScale : 1.0
            let baseYScale = 256.0 / Double(max(frameHeight, 1))
            let frameYScale = baseYScale.isFinite ? baseYScale : 1.0
            
            let scanLineHeight = Float(scanLines)
            let displayColumns = Float(horizDisplayed)
            let cursorStartScanLine = Float(Int(snapshot.crtcSnapshot.R10) & 0b00011111)
            let cursorEndScanLine = Float(snapshot.crtcSnapshot.R11)
            let cursorBlinkType = Float(Int(snapshot.crtcSnapshot.R10 >> 5))
            let fontLocationOffset = Float(Int(snapshot.crtcSnapshot.R12) << 8 | Int(snapshot.crtcSnapshot.R13))
            let cursorPosition = Float(Int(snapshot.crtcSnapshot.R14) << 8 | Int(snapshot.crtcSnapshot.R15))
            
            let colourMode = Float(colourOptions[colourSelection] ?? 0)
            
            let baseWidth = max(CGFloat(frameWidth), 1)
            let baseHeight = max(CGFloat(frameHeight), 1)
            let scaledWidth = baseWidth * charScale * CGFloat(frameXScale)
            let scaledHeight = baseHeight * charScale * charAspect * CGFloat(frameYScale)
            
            let backGroundIntensity = Float(
                (Int(snapshot.crtcSnapshot.redBackgroundIntensity) << 2) +
                (Int(snapshot.crtcSnapshot.greenBackgroundIntensity) << 1) +
                Int(snapshot.crtcSnapshot.blueBackgroundIntensity)
            )
            
            TimelineView(.periodic(from: startDate, by: 0.02))
            { context in
                let elapsedTime = Float(context.date.timeIntervalSince(startDate))
                
                let shaderScanLineHeight = Float(scanLineHeight)
                let shaderDisplayColumns = Float(displayColumns)
                let shaderFontLocationOffset = Float(fontLocationOffset)
                let shaderCursorPosition = Float(cursorPosition)
                let shaderCursorStartScanLine = Float(cursorStartScanLine)
                let shaderCursorEndScanLine = Float(cursorEndScanLine)
                let shaderCursorBlinkType = Float(cursorBlinkType)
                let shaderColourMode = Float(colourMode)
                let shaderBackGroundIntensity = Float(backGroundIntensity)
                let shaderElapsedTime = Float(elapsedTime)
                let vduArray = snapshot.memorySnapshot.VDU
                let charRomArray = snapshot.memorySnapshot.CharRom
                let pcgRamArray = snapshot.memorySnapshot.PcgRam
                let colourRamArray = snapshot.memorySnapshot.ColourRam
                
                Rectangle()
                    .frame(width: baseWidth, height: baseHeight)
                    .colorEffect(ShaderLibrary.ScreenBuffer(
                        .float(shaderScanLineHeight),
                        .float(shaderDisplayColumns),
                        .float(shaderFontLocationOffset),
                        .float(shaderCursorPosition),
                        .float(shaderCursorStartScanLine),
                        .float(shaderCursorEndScanLine),
                        .float(shaderCursorBlinkType),
                        .float(shaderColourMode),
                        .float(shaderBackGroundIntensity),
                        .float(shaderElapsedTime),
                        .floatArray(vduArray),
                        .floatArray(charRomArray),
                        .floatArray(pcgRamArray),
                        .floatArray(colourRamArray)
                    ))
                    .scaleEffect(x: charScale * CGFloat(frameXScale), y: charScale * charAspect * CGFloat(frameYScale))
                    .frame(width: scaledWidth, height: scaledHeight)
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
                                        isRunning.toggle()
                                        if ClearScreen
                                        {
                                            await vm.ClearEmulationScreen()
                                            ClearScreen = false
                                        }
                                        switch demoSelection
                                        {
                                        case "Microworld Basic (64x16)" : await vm.writeToMemory(address: 0x0901, value: 0x00)
                                        case "CP/M (80x24)" : await vm.writeToMemory(address: 0x0901, value: 0x01)
                                        case "Viatel (40x25)" : await vm.writeToMemory(address: 0x0901, value: 0x02)
                                        default: break
                                        }
                                        await vm.startEmulation()
                                    }
                                }
                                .labelStyle(.titleAndIcon)
                                //.buttonStyle(.borderedProminent)
                                //.tint(Color.orange)
                                Button("Step", systemImage: "forward.frame.fill")
                                {
                                    Task
                                    {
                                        if ClearScreen
                                        {
                                            await vm.ClearEmulationScreen()
                                            ClearScreen = false
                                        }
                                        switch demoSelection
                                        {
                                        case "Microworld Basic (64x16)" : await vm.writeToMemory(address: 0x0001, value: 0x00)
                                        case "CP/M (80x24)" : await vm.writeToMemory(address: 0x0001, value: 0x01)
                                        case "Viatel (40x25)" : await vm.writeToMemory(address: 0x0001, value: 0x02)
                                        default: break
                                        }
                                        await vm.stepEmulation()
                                    }
                                }
                                .labelStyle(.titleAndIcon)
                            }
                            HStack(spacing: 12)
                            {
                                Button("Reset", systemImage: "arrow.counterclockwise")
                                {
                                    Task { await vm.stopEmulation() }
                                }
                                .labelStyle(.titleAndIcon)
                                Button("Quit", systemImage: "xmark.circle")
                                { NSApp.terminate(nil) }
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                        .fixedSize() // Ensures SwiftUI doesn't truncate the labels
                    }
                }
                .onAppear
                {
                    openWindow(id: "registerWindow")
                    openWindow(id: "portAndCrtcWindow")
                    openWindow(id: "memoryAndInstructionWindow")
                    focusWindow(withId: "emulatorWindow")
                }
            }
        }
        else
        {
            Text("Nothing to see here folks")
        }
    } //body
} // emulatorView

