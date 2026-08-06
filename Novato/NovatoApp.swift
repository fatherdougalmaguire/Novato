import SwiftUI
import UniformTypeIdentifiers

@main
struct NovatoApp: App
{
    @Environment(\.openWindow) private var openWindow
    @State private var vm = emulatorViewModel(cpu: microbee())
    
    @State private var isImporting = false
    
    private var restrictedTypes: [UTType]
    {
        let binType = UTType(filenameExtension: "bin") ?? .item
        let beeType = UTType(filenameExtension: "bee") ?? .item
        let romType = UTType(filenameExtension: "rom") ?? .item
        
        return [binType, beeType, romType]
    }
    
    var body: some Scene
    {
        Window("Emulator",id: "emulatorWindow")
        {
            emulatorView().environment(vm)
        }
        .windowResizability(.contentSize)
        Window("Registers", id: "registerWindow")
        {
            registerView().environment(vm)
        }
        Window("Ports and CRTC", id: "portAndCrtcWindow")
        {
            portAndCrtcView().environment(vm)
        }
        Window("Memory and Instructions", id: "memoryAndInstructionWindow")
        {
            memoryAndInstructionView().environment(vm)
        }
        Window("Breakpoints", id: "breakpointsWindow")
        {
            breakpointsView().environment(vm)
        }
//        Window("QuickLoad", id: "quickloadWindow")
//        {
//            fileLoadView().environment(vm)
//        }
        Settings { SettingsView() }
        .commands
        {
            AboutMenu(
                title: "About Novato",
                applicationName: "Novato",
                credits: "Novato is a SwiftUI/Swift emulator compatible with the Microbee family of home computers.\n\n© Tony Sanchez 2025-2026\nAll Rights Reserved\n\nHello to Jason Isaacs"
            )
            CommandGroup(replacing: .newItem)
            {
                Button("QuickLoad")
                {
                    isImporting = true
                }
                    .fileImporter(
                        isPresented: $isImporting,
                        allowedContentTypes: restrictedTypes,
                        allowsMultipleSelection: false
                    )
                    {
                        result in

                        switch result
                        {
                        case .success(let urls):

                            guard let url = urls.first else { return }

                            Task
                            {
                                await vm.pauseEmulation()
                                await vm.quickload(path: url, loadAddress: 0x900)
                                await vm.updateProgramCounter(address: 0x900)
                                await vm.startEmulation()
                            }

                        case .failure(let error):

                            print(error)
                        }
                }.keyboardShortcut("L")
            }
            CommandMenu("Assembler")
            {
                Button("Nothing to see here folks")
                {
                }.keyboardShortcut("A")
            }
            CommandMenu("Disk")
            {
                Button("Create disk image")
                {
                }
                Button("Open disk image")
                {
                }
                Button("View disk image")
                {
                }
            }
            CommandMenu("Tape")
            {
                Button("Create tape")
                {
                }
                Button("Open tape")
                {
                }
                Button("Rewind tape")
                {
                }
                Button("Record tape")
                {
                }
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
                Button("Restore Emulator State")
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
            }
        }
    }
}

