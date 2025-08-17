import SwiftUI

struct EmulatorView: View
{
    @Environment(EmulatorViewModel.self) private var vm
    @Environment(\.openWindow) var openWindow

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
    
    func VDUChar (column : Int, Row : Int ) -> String
    {
        guard vm.VDU.count > Row*64+column
        else
        {
            return " "
        }
        let ascii = Int(vm.VDU[Row*64+column])
        switch ascii
        {
        case 32...126:
            return String(UnicodeScalar(ascii)!)
        default:
            return " "
        }
    }
    
    var body: some View
    {
        VStack(spacing: 20)
        {
            Text("Microbee 32IC compatible emulator")
                .font(.largeTitle)
                .bold()
            Text("App Version: "+getAppVersion()+"/"+getBuildNumber())
            
            Spacer()
            
            VStack(spacing: 0)
            {
                ForEach(0..<16, id: \.self)
                    { row in
                        HStack(spacing: 0)
                        {
                            ForEach(0..<64, id: \.self)
                            { col in
                                Text(VDUChar(column: col, Row: row))
                                    .font(.system(.body, design: .monospaced))
                                    .background(.black)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
            }
            
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
        }
        .padding(200) // fix this to fill all visible area
        .background(.white)
        .onAppear
        {
            openWindow(id: "DebugWindow")
        }
    }
}

