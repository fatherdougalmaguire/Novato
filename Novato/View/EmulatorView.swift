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
    
    @State private var powerOn = true
    @State private var ClearScreen = true
    
    @AppStorage("scalingSelection") private var charScale: Double = 2.0 // Scale for visibility on 27" screen ( 2560 x 1440 )
    @AppStorage("aspectSelection") private var charAspect: Double = 4/3  // Correction for CRT aspect ratio
    @AppStorage("colorSelection") private var colourSelection = "Colour"
    @AppStorage("demoSelection") private var demoSelection = "Microworld Basic (64x16)"
    
    let colourOptions: [String:Int] = ["Green":0,"Amber":1,"White":2,"Blue":3,"Colour":4,"Premium Colour":5]
    
    // 0 - green on black, 1 - amber on black, 2 - white on black, 3 - blue on black, 4 - Colour else Premium colour mode
    
    let startDate = Date()
    @State private var isRunning = false
    
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
        
        let colourMode = Float(colourOptions[colourSelection] ?? 0)
        
        let baseWidth = max(CGFloat(frameWidth), 1)
        let baseHeight = max(CGFloat(frameHeight), 1)
        let scaledWidth = baseWidth * charScale * frameXScale
        let scaledHeight = baseHeight * charScale * charAspect * frameYScale
        
        let backGroundIntensity = Float(vm.vmRedBackgroundIntensity << 2 + vm.vmGreenBackgroundIntensity << 1 + vm.vmBlueBackgroundIntensity)
        
        NavigationStack {
            TimelineView((.periodic(from: startDate, by: 0.02)))
            { context in let elapsedTime = Float(context.date.timeIntervalSince(startDate))
                Rectangle()
                    .frame(width: baseWidth, height: baseHeight, alignment: .center)
                    .colorEffect(ShaderLibrary.ScreenBuffer(.float(scanLineHeight), .float(displayColumns), .float(fontLocationOffset), .float(cursorPosition), .float(cursorStartScanLine), .float(cursorEndScanLine), .float(cursorBlinkType), .float(colourMode), .float(backGroundIntensity),.float(elapsedTime), .floatArray(vm.VDU), .floatArray(vm.CharRom), .floatArray(vm.PcgRam), .floatArray(vm.ColourRam)))
                    .scaleEffect(x: charScale * CGFloat(frameXScale), y: charScale * charAspect * CGFloat(frameYScale))
                    .frame(width: scaledWidth, height: scaledHeight, alignment: .center)
            }
            .toolbar {
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
                                    case "Microworld Basic (64x16)" : await vm.writeToMemory(address: 0x0001, value: 0x00)
                                    case "CP/M (80x24)" : await vm.writeToMemory(address: 0x0001, value: 0x01)
                                    case "Viatel (40x25)" : await vm.writeToMemory(address: 0x0001, value: 0x02)
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
                            Button("Stop", systemImage: "stop.fill")
                            {
                                Task { await vm.stopEmulation() }
                            }
                            .labelStyle(.titleAndIcon)
                        }
                            HStack(spacing: 12)
                            {
                                Button("Reset", systemImage: "arrow.counterclockwise")
                                { NSApp.terminate(nil) }
                                    .labelStyle(.titleAndIcon)
                                
                                Button("Quit", systemImage: "xmark.circle")
                                { NSApp.terminate(nil) }
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                        .fixedSize() // Ensures SwiftUI doesn't truncate the labels
                    }
                }
            } //vstack
            .onAppear
            {
                openWindow(id: "RegisterWindow")
                openWindow(id: "PortWindow")
                openWindow(id: "MemoryWindow")
            }
    }
}
