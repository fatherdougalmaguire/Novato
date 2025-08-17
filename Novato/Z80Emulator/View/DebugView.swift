import SwiftUI

struct DebugView: View
{
    @Environment(EmulatorViewModel.self) private var vm
    
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
    
    func mapascii (ascii : UInt8) -> String
    {
        switch ascii
        {
        case 32...127:
            return String(UnicodeScalar(Int(ascii))!)
        default:
            return "."
        }
    }
    
    @ViewBuilder
    func FlagRegister(label: String, value: UInt8) -> some View
    {
        VStack
        {
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
            Text(label)
                .font(.system(.body, design: .monospaced))
            Text(String(format:"%02X", value))
                .font(.system(.body, design: .monospaced))
        }
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
    
    var body: some View
    {
        VStack(spacing: 20)
        {
            Spacer()
            HStack(spacing: 40)
            {
                VStack
                {
                    Text("PC").font(.headline)
                    Text(String(format: "%04X",vm.pcReg)).font(.system(.title3, design: .monospaced))
                }
                VStack
                {
                    Text("SP").font(.headline)
                    Text(String(format: "%04X",vm.spReg)).font(.system(.title3, design: .monospaced))
                }
                VStack
                {
                    Text("IX").font(.headline)
                    Text(String(format: "%04X",vm.ixReg)).font(.system(.title3, design: .monospaced))
                }
                VStack
                {
                    Text("IY").font(.headline)
                    Text(String(format: "%04X",vm.iyReg)).font(.system(.title3, design: .monospaced))
                }
                VStack
                {
                    Text("BC").font(.headline)
                    Text(String(format: "%04X",vm.bcReg)).font(.system(.title3, design: .monospaced))
                }
                VStack
                {
                    Text("DE").font(.headline)
                    Text(String(format: "%04X",vm.deReg)).font(.system(.title3, design: .monospaced))
                }
                VStack
                {
                    Text("HL").font(.headline)
                    Text(String(format: "%04X",vm.hlReg)).font(.system(.title3, design: .monospaced))
                }
                VStack
                {
                    Text("BC'").font(.headline)
                    Text(String(format: "%04X",vm.altbcReg)).font(.system(.title3, design: .monospaced))
                }
                VStack
                {
                    Text("DE'").font(.headline)
                    Text(String(format: "%04X",vm.altdeReg)).font(.system(.title3, design: .monospaced))
                }
                VStack
                {
                    Text("HL'").font(.headline)
                    Text(String(format: "%04X",vm.althlReg)).font(.system(.title3, design: .monospaced))
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(60)), count: 10), spacing: 10)
            {
                Group
                {
                    registerRow(label: "A", value: vm.aReg)
                    registerRow(label: "F", value: vm.fReg)
                    registerRow(label: "B", value: vm.bReg)
                    registerRow(label: "C", value: vm.cReg)
                    registerRow(label: "D", value: vm.dReg)
                    registerRow(label: "E", value: vm.eReg)
                    registerRow(label: "H", value: vm.hReg)
                    registerRow(label: "L", value: vm.lReg)
                    registerRow(label: "I", value: vm.iReg)
                    registerRow(label: "R", value: vm.rReg)
                }
                Group
                {
                    registerRow(label: "A'", value: vm.altaReg)
                    registerRow(label: "F'", value: vm.altfReg)
                    registerRow(label: "B'", value: vm.altbReg)
                    registerRow(label: "C'", value: vm.altcReg)
                    registerRow(label: "D'", value: vm.altdReg)
                    registerRow(label: "E'", value: vm.alteReg)
                    registerRow(label: "H'", value: vm.althReg)
                    registerRow(label: "L'", value: vm.altlReg)
                }
            }
            FlagRegister(label: "S   Z   x   H   y  P/V  N   C   ", value: vm.fReg)
            
            VStack(alignment: .leading)
            {
                Text("Memory View")
                    .font(.headline)
                ScrollView
                {
                    VStack(alignment: .leading, spacing: 2)
                    {
                        ForEach(0..<vm.memoryDump.count / 16, id: \.self)
                        { row in
                            let address = row * 16
                            let bytes = vm.memoryDump[address..<address+16]
                            let dispaddress = Int(vm.pcReg)+address
                            let hexBytes = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                            let charBytes = bytes.map { mapascii(ascii:$0) }.joined(separator: "")
                            Text(String(format: "0x%04X: %@ %@", dispaddress, hexBytes,charBytes))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(.white)
    }
}


