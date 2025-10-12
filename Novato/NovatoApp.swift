import SwiftUI

@main
struct NovatoApp: App
{
    @State private var vm = EmulatorViewModel(cpu: Z80CPU())
    
    var body: some Scene
    {
        WindowGroup("Novato - Emulator",id: "EmulatorWindow")
        {
            EmulatorView().environment(vm)
        }
        WindowGroup("Novato - Debug", id: "DebugWindow")
        {
            DebugView().environment(vm)
        }
    }
}
