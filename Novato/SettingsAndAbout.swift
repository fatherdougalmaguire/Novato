//  Adapted from code listed at https://danielsaidi.com/blog/2023/11/28/how-to-customize-the-macos-about-panel-in-swiftui

import Foundation
import SwiftUI

public struct AboutMenu: Commands {
    
    public init(
        title: String,
        applicationName: String = Bundle.main.displayName,
        credits: String? = nil
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let options: [NSApplication.AboutPanelOptionKey: Any]
        if let credits {
            options = [
                .applicationName: applicationName,
                .credits: NSAttributedString(
                    string: credits,
                    attributes: [
                        .paragraphStyle: paragraphStyle,
                        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
                        
                    ]
                )
            ]
        } else {
            options = [.applicationName: applicationName]
        }
        self.init(title: title, options: options)
    }
    
    public init(
        title: String,
        options: [NSApplication.AboutPanelOptionKey: Any]
    ) {
        self.title = title
        self.options = options
    }
    
    private let title: String
    private let options: [NSApplication.AboutPanelOptionKey: Any]
    
    public var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(title) {
                NSApplication.shared
                    .orderFrontStandardAboutPanel(options: options)
            }
        }
    }
}

public extension Bundle {
    
    var displayName: String {
        infoDictionary?["CFBundleDisplayName"] as? String ?? "-"
    }
}

struct SettingsView: View
{
    var body: some View
    {
        TabView
        {
            screenSettingsView()
                .tabItem { Label("Screen", systemImage: "gear") }
                .tag("general")
            windowsView()
                .tabItem { Label("Windows", systemImage: "gear") }
                .tag("general")
            speedSettingsView()
                .tabItem { Label("CPU Speed", systemImage: "gear") }
                .tag("general")
        }
        .frame(width: 450, height: 250)
    }
}

struct TooltipSlider: View
{
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1.0
    let formatter: (Double) -> String
    
    var onEditingChanged: ((Bool) -> Void)? = nil

    @State private var isHovering = false

    var body: some View
    {
        LabeledContent(label)
        {
            HStack(spacing: 8)
            {
                Text(formatter(range.lowerBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: $value, in: range, step: step, onEditingChanged: { editing in onEditingChanged?(editing) })
                    .onHover { isHovering = $0 }
                    .popover(isPresented: $isHovering, attachmentAnchor: .point(.top), arrowEdge: .bottom)
                {
                    Text(formatter(value)).font(.caption.bold()).padding(8)
                }
                Text(formatter(range.upperBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct speedSettingsView: View
{
    @AppStorage("speedSelection") private var speedSelection: Double = 1.0
    @Environment(emulatorViewModel.self) private var vm
    
    var body: some View
    {
        Form
        {
            TooltipSlider(
                label: "CPU Speed",
                value: $speedSelection,
                range: 1...8,
                step: 1.0,
                formatter: { "\($0)x" },
                onEditingChanged: { editing in
                    if !editing
                    {
                        //let value = speedSelection
                        Task
                        {
                            await vm.setClockSpeedMultiplier(multiplier: speedSelection)
                        }
                    }
                }
            )
        }
        .formStyle(.grouped)
    }
}

struct modelSettingsView: View
{
    @AppStorage("modelSelection") private var modelSelection = "Microbee 16K/32K IC"
    
    var body: some View
    {
        let themes = ["Microbee Kit","Microbee 16K/32K","Microbee 64K","Microbee 16K/32K Plus","Microbee 64K Plus","Microbee 16K/32K IC","Experimenter","Educator","Personal Communicator (PC)","Advanced Personal Computer (APC)","16K Educator","32K Communicator","64K Computer in a Book (CIAB)","128K Small Business Computer (SBC)","PC85","PC85 Premium","64K Computer in a Book Premium (CIAB Premium)","128K Small Business Computer Premium (SBC Premium)","128K Overdrive","TeleTerm","256TC (Telecomputer)"]
        Form
        {
            Picker("Model:", selection: $modelSelection)
            {
                ForEach(themes, id: \.self) { theme in Text(theme) }
            }
            .pickerStyle(.menu)
            
            Divider()
            
            Text("Changes will be applied immediately.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(30)
        .frame(width: 400, height: 150)
    }
}

struct bootSettingsView: View
{
    @AppStorage("bootModeSelection") private var bootModeSelection = "MicroWorld Basic 5.22e"
    @AppStorage("autoStartSelection") private var autoStartSelection: Bool = false
    
    var body: some View
    {
        let themes = ["Demo #1 - Basic","Demo #2 - CP/M","Demo #3 - Viatel","MicroWorld Basic 5.22e"]
        Form
        {
            Picker("Demo Screen:", selection: $bootModeSelection)
            {
                ForEach(themes, id: \.self) { theme in Text(theme) }
            }
            .pickerStyle(.menu)
            
            Picker("Operation Mode", selection: $autoStartSelection) {
                Text("Splash Screen").tag(false)
                Text("Auto-Start").tag(true)
            }
            .pickerStyle(.menu)
        }
        .formStyle(.grouped)
    }
}

struct screenSettingsView: View
{
    @AppStorage("scalingSelection") private var scalingSelection: Double = 2.0
    @AppStorage("aspectSelection") private var aspectSelection: Double = 4/3
    @AppStorage("interlaceEnabled") private var interlaceEnabled: Bool = false
    @AppStorage("colorSelection") private var colourSelection = "Colour"
    
    var body: some View
    {
        let themes = ["Green","Amber","White","Blue","Colour"]
        
        Form
        {
            TooltipSlider(label: "Screen Scaling", value: $scalingSelection, range: 1...4, step: 0.25) { String(format: "%.2fx", $0) }
            TooltipSlider(label: "Aspect Ratio", value: $aspectSelection, range: 0...2, step: 0.1) { String(format: "%.1fx", $0)}

            Picker("Colour Mode:", selection: $colourSelection)
            {
                ForEach(themes, id: \.self) { theme in Text(theme) }
            }
            .pickerStyle(.menu)
            
            Toggle("Ahistorical Scanline Mode:", isOn: $interlaceEnabled)
        }
        .formStyle(.grouped)
    }
}

struct windowsView: View
{
    @AppStorage("registerWindowVisible") private var registerWindowVisible: Bool = true
    @AppStorage("portWindowVisible") private var portWindowVisible: Bool = true
    @AppStorage("memoryWindowVisible") private var memoryWindowVisible: Bool = true
    @AppStorage("breakpointWindowVisible") private var breakpointWindowVisible: Bool = true
    
    var body: some View
    {
        Form
        {
            Toggle("Show register window", isOn: $registerWindowVisible)
            Toggle("Show port window", isOn: $portWindowVisible)
            Toggle("Show memory window", isOn: $memoryWindowVisible)
            Toggle("Show breakpoint window", isOn: $breakpointWindowVisible)
        }
        .formStyle(.grouped)
    }
}
