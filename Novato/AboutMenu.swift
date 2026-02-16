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
//            modelSettingsView()
//                .tabItem { Label("Pick your model", systemImage: "gear") }
//                .tag("model")
            bootSettingsView()
                .tabItem { Label("Boot Settings", systemImage: "gear") }
                .tag("general")
            screenSettingsView()
                .tabItem { Label("Screen Settings", systemImage: "gear") }
                .tag("general")
            
        }
        .frame(width: 450, height: 250) // Standard starting size
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
            .pickerStyle(.menu) // Standard macOS pop-up button
            
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
    @AppStorage("bootModeSelection") private var bootModeSelection = "Demo #1 - Basic"
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
            .pickerStyle(.menu) // Standard macOS pop-up button
            
            Divider()
                        
            Picker("Operation Mode", selection: $autoStartSelection) {
                            Text("Splash Screen").tag(false)
                            Text("Auto-Start").tag(true)
                        }
                        .pickerStyle(.menu) // Works great on macOS and iOS
        }
        .padding(30)
        .frame(width: 400, height: 150)
    }
}

struct screenSettingsView: View
{
    @AppStorage("scalingSelection") private var scalingSelection: Double = 2.0
    @AppStorage("aspectSelection") private var aspectSelection: Double = 4/3
    @AppStorage("colorSelection") private var colourSelection = "Colour"
    
    var body: some View
    {
        let themes = ["Green","Amber","White","Blue","Colour"]
        
        Form
        {
            Slider(value: $scalingSelection, in: 1...4, step: 0.25)
            { Text("Screen Scaling") }
            minimumValueLabel: { Text("1") }
            maximumValueLabel: { Text("4") }
            
            Divider()
            
            Slider(value: $aspectSelection, in: 0...2, step: 0.1)
            { Text("Aspect Ratio") }
            minimumValueLabel: { Text("0") }
            maximumValueLabel: { Text("2") }
            
            Divider()
            
            Picker("Colour Mode:", selection: $colourSelection)
            {
                ForEach(themes, id: \.self) { theme in Text(theme) }
            }
            .pickerStyle(.menu) // Standard macOS pop-up button
        }
        .padding(30)
        .frame(width: 400, height: 150)
    }
}
