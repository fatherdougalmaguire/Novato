import SwiftUI

@main
struct NovatoApp: App
{
    @State private var vm = EmulatorViewModel(cpu: Z80CPU())
    
    var body: some Scene
    {
        WindowGroup("Emulator",id: "EmulatorWindow")
        {
            EmulatorView().environment(vm)
        }
        WindowGroup("Debug", id: "DebugWindow")
        {
            DebugView().environment(vm)
        }
    }
}
