import SwiftUI

struct PortView: View
{
    @Environment(EmulatorViewModel.self) private var vm
    
    func padBinary(value: UInt8) -> String
    {
        let binString = String(value, radix: 2)
        let paddingCount: Int = max(0, 8 - binString.count)
        let padded = String(repeating: "0", count: paddingCount) + binString
        return padded
    }
    
    var body: some View
    {
        ZStack
        {
            Color.white
                VStack(alignment: .leading)
                {
                    Text("Port View")
                        .font(.headline)
                    
                    Spacer()
                    
                    let port00Hex: String = String(format: "0x%02X", vm.ports[0])
                    let port00Bin: String = padBinary(value: vm.ports[0])
                    Text("0x00   \(port00Hex) \(port00Bin) PIO port A data port")
                        .foregroundColor(Color.orange)
                        .font(.system(.body, design: .monospaced))
                    
                    let port01Hex: String = String(format: "0x%02X", vm.ports[1])
                    let port01Bin: String = padBinary(value: vm.ports[1])
                    Text("0x01   \(port01Hex) \(port01Bin) PIO port A control port       ")
                        .foregroundColor(Color.orange)
                        .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                        .font(.system(.body, design: .monospaced))
                    
                    let port02Hex: String = String(format: "0x%02X", vm.ports[2])
                    let port02Bin: String = padBinary(value: vm.ports[2])
                    Text("0x02   \(port02Hex) \(port02Bin) PIO port B data port          ")
                        .foregroundColor(Color.orange)
                        .font(.system(.body, design: .monospaced))
                    
                    let port03Hex: String = String(format: "0x%02X", vm.ports[3])
                    let port03Bin: String = padBinary(value: vm.ports[3])
                    Text("0x03   \(port03Hex) \(port03Bin) PIO port B data port          ")
                        .foregroundColor(Color.orange)
                        .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                        .font(.system(.body, design: .monospaced))
                    
                    let port08Hex: String = String(format: "0x%02X", vm.ports[8])
                    let port08Bin: String = padBinary(value: vm.ports[8])
                    Text("0x08   \(port08Hex) \(port08Bin) Colour control port          ")
                        .foregroundColor(Color.orange)
                        .font(.system(.body, design: .monospaced))
                    
                    let port0AHex: String = String(format: "0x%02X", vm.ports[10])
                    let port0ABin: String = padBinary(value: vm.ports[10])
                    Text("0x0A   \(port0AHex) \(port0ABin) PAK/NET selection port        ")
                        .foregroundColor(Color.orange)
                        .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                        .font(.system(.body, design: .monospaced))
                    
                    let port0BHex: String = String(format: "0x%02X", vm.ports[11])
                    let port0BBin: String = padBinary(value: vm.ports[11])
                    Text("0x0B   \(port0BHex) \(port0BBin) Character generator latch port")
                        .foregroundColor(Color.orange)
                        .font(.system(.body, design: .monospaced))
                    
                    let port0CHex: String = String(format: "0x%02X", vm.ports[12])
                    let port0CBin: String = padBinary(value: vm.ports[12])
                    Text("0x0C   \(port0CHex) \(port0CBin) 6545 CRTC register port       ")
                        .foregroundColor(Color.orange)
                        .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                        .font(.system(.body, design: .monospaced))
                    
                    let port0DHex: String = String(format: "0x%02X", vm.ports[13])
                    let port0DBin: String = padBinary(value: vm.ports[13])
                    Text("0x0D   \(port0DHex) \(port0DBin) 6545 CRTC data port          ")
                        .foregroundColor(Color.orange)
                        .font(.system(.body, design: .monospaced))
                }
        }
        .fixedSize()
        .padding(10)
    }
}

