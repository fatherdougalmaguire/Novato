import SwiftUI

struct ContentView: View {
    @StateObject private var vm = EmulatorViewModel(cpu: Z80CPU())

    var body: some View {
        VStack(spacing: 20) {
            Text("Microbee 32IC compatible emulator")
                .font(.largeTitle)
                .bold()
            Text("App Version: "+getAppVersion()+"/"+getBuildNumber())
            HStack(spacing: 40) {
                VStack {
                    Text("PC").font(.headline)
                    Text(vm.pcText).font(.system(.title3, design: .monospaced))
                }
                VStack {
                    Text("SP").font(.headline)
                    Text(vm.spText).font(.system(.title3, design: .monospaced))
                }
            }

            // Register Grid
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(60)), count: 7), spacing: 10)
            {
                Group {
                    registerRow(label: "A", value: vm.aReg)
                    registerRow(label: "B", value: vm.bReg)
                    registerRow(label: "C", value: vm.cReg)
                    registerRow(label: "D", value: vm.dReg)
                    registerRow(label: "E", value: vm.eReg)
                    registerRow(label: "H", value: vm.hReg)
                    registerRow(label: "L", value: vm.lReg)
                }
            }
            
            FlagRegister(label: "S   Z   x   H   y   P/V N   C", value: vm.fReg)
            
            // Small memory dump (first 16 bytes)
            VStack(alignment: .leading)
            {
                Text("Memory View").font(.headline)
                ScrollView
                {
                    VStack(alignment: .leading, spacing: 2)
                    {
                        ForEach(0..<vm.memoryDump.count / 16, id: \.self)
                            { row in
                                  let address = row * 16
                                  let bytes = vm.memoryDump[address..<address+16]
                                  let hexBytes = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                                  Text(String(format: "0x%04X: %@", address, hexBytes))
                                      .font(.system(.body, design: .monospaced))
                                      .foregroundColor(.orange)
                            }
                    }
                    .padding()
                }
            }

            // Start / Stop buttons
            HStack(spacing: 40)
            {
                Button(action: { Task { await vm.startEmulation() } })
                {
                    Label("Start/Pause", systemImage:"playpause.fill")
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

                Button(action: {})
                {
                        Label("Reset", systemImage:"arrow.trianglehead.clockwise.rotate.90")
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding(20)
    }

    @ViewBuilder
    func FlagRegister(label: String, value: UInt8) -> some View
    {
        VStack
        {
            //Text(label).font(.caption)
            Text(label)
                .font(.system(.body, design: .monospaced))
            Text(getFlags(flag: value))
                .font(.system(.body, design: .monospaced))
        }
    }
    
    @ViewBuilder
    func registerRow(label: String, value: UInt8) -> some View
    {
        VStack
        {
            Text(label).font(.caption)
            Text(String(format:"%02X", value))
                .font(.system(.body, design: .monospaced))
        }
    }
    
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
    
    func getFlags( flag : UInt8) -> String
    {

        var result : String = ""
        
        for i in 0...7
        {
            let bitPosition = i
            let mask = 1 << bitPosition
            let isBitSet = (flag & UInt8(mask)) != 0
            if isBitSet
            {
                result = result+"1   "
            }
            else
            {
                result = result+"0   "
            }
        }
        return result
    }
    
}

