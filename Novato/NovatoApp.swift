import SwiftUI

@main
struct NovatoApp: App
{
    @State private var vm = EmulatorViewModel(cpu: Z80CPU())
    @State private var colourOutputMode = "Colour"
    @State private var modelSelection = "model32IC"
    @State private var demoMode = "demoMode6416"
    
    var body: some Scene
    {
        WindowGroup("Novato - Emulator",id: "EmulatorWindow")
        {
            EmulatorView().environment(vm)
        }
        WindowGroup("Novato -  Debug", id: "DebugWindow")
        {
            DebugView().environment(vm)
        }
        Settings {
                    SettingsView()
                }
        .commands
        {
            AboutMenu(
                title: "About Novato",
                applicationName: "Novato",
                credits: "Novato is a SwiftUI/Swift emulator compatible with the Microbee family of home computers.\n\n© Tony Sanchez 2025-2026\nAll Rights Reserved\n\nHello to Jason Isaacs"
            )
            CommandGroup(replacing: .newItem)
            {
                Button("Load binary")
                {
                }.keyboardShortcut("L")
            }
            CommandMenu("Assembler")
            {
                Button("Nothing to see here folks")
                {
                }.keyboardShortcut("A")
            }
            CommandMenu("Emulator")
            {
                Button("Start Emulator")
                {
                }
                Button("Stop Emulator")
                {
                }
                Button("Reset Emulator")
                {
                }
                Button("Save Emulator State")
                {
                }
            }
            CommandGroup(replacing: .help)
            {
                Divider()
                Link("GitHub project page", destination: URL(string: "https://github.com/fatherdougalmaguire/Novato")!)
                Divider()
                Link("Microbee Software Preservation Project Forum", destination: URL(string: "https://microbee-mspp.org/forum")!)
                Link("Microbee Technology Forum", destination: URL(string: "https://microbeetechnology.com.au/forum")!)
                Divider()
                Link("Hello to Jason Isaacs", destination: URL(string: "https://www.kermodeandmayo.com")!)
            }
        }
    }
}
