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
            modelSettingsView()
                .tabItem { Label("Pick your model", systemImage: "gear") }
                .tag("model")
            demoSettingsView()
                .tabItem { Label("Demo screen", systemImage: "gear") }
                .tag("general")
            colourSettingsView()
                .tabItem { Label("Colour mode", systemImage: "gear") }
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

struct demoSettingsView: View
{
    @AppStorage("demoSelection") private var demoSelection = "Microworld Basic (64x16)"

    var body: some View
    {
        let themes = ["Microworld Basic (64x16)","CP/M (80x24)","Viatel (40x24)"]
        Form
        {
            Picker("Demo Screen:", selection: $demoSelection)
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

struct colourSettingsView: View
{
    @AppStorage("colorSelection") private var colourSelection = "Colour"

    var body: some View
    {
        let themes = ["Green","Amber","White","Blue","Colour","Premium Colour"]
        Form
        {
            Picker("Colour Mode:", selection: $colourSelection)
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
