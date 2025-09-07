import SwiftUI

struct EmulatorView: View
{
    @Environment(EmulatorViewModel.self) private var vm
    @Environment(\.openWindow) var openWindow
    
    let charWidth = 8 // Pixels per character (width)
    let charHeight = 16 // Pixels per character (height)
    let cols = 64 // Characters per row
    let rows = 16 // Number of rows
    let scale: CGFloat = 1.0 // Scale for visibility (512x256 -> 2048x1024 pixels)
    
    func getAppVersion() -> String
    {
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        {
            return appVersion
        }
        return "Unknown"
    }
    
    func getBuildNumber() -> String
    {
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        {
            return buildNumber
        }
        return "Unknown"
    }
    
    var body: some View
    {
        ZStack {
            Color.white
            
            VStack(spacing: 20)
            {
                Text("Microbee 32IC compatible emulator")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top,20)

                Text("App Version: "+getAppVersion()+"/"+getBuildNumber())

                Spacer()
                
                Rectangle()
                    .colorEffect(ShaderLibrary.ScreenBuffer(.floatArray(vm.VDU),.floatArray(vm.CharRom)))
                    .scaleEffect(x: 1, y:1.333)
                    .colorEffect(ShaderLibrary.interlace(.float(0)))
                    .frame(width: CGFloat(512), height: CGFloat(256))
                
                Spacer()
                
                HStack(spacing: 40)
                {
                    Button(action: { Task { await vm.startEmulation() } })
                    {
                        Label("Start", systemImage:"play.fill")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { Task { await vm.stopEmulation() } })
                    {
                        Label("Stop", systemImage:"stop.fill")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {})
                    {
                        Label("Step", systemImage:"play.square.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                    
                }
                
                HStack(spacing: 40)
                {
                    Button(action: {})
                    {
                        Label("Reset", systemImage:"arrow.trianglehead.clockwise.rotate.90")
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                    
                    Button(action: {NSApp.terminate(nil)})
                    {
                        Label("Quit", systemImage:"power")
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
            } // vstack
        }  //zstack
        .onAppear
        {
            openWindow(id: "DebugWindow")
        }
    } // body
} // struct
