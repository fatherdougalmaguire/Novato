import SwiftUI

struct PortCrtcView: View
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
        VStack(alignment: .leading)
        {
            Text("CPU Ports").font(.headline)
                    
            Spacer()
                    
            let port00Hex: String = String(format: "0x%02X", vm.snapshot?.executionSnapshot.ports[0] ?? 0)
            let port00Bin: String = padBinary(value: vm.snapshot?.executionSnapshot.ports[0] ?? 0)
            Text("0x00    \(port00Hex)  \(port00Bin)   PIO port A data port  ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let port01Hex: String = String(format: "0x%02X", vm.snapshot?.executionSnapshot.ports[1] ?? 0)
            let port01Bin: String = padBinary(value: vm.snapshot?.executionSnapshot.ports[1] ?? 0)
            Text("0x01    \(port01Hex)  \(port01Bin)   PIO port A control port         ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let port02Hex: String = String(format: "0x%02X", vm.snapshot?.executionSnapshot.ports[2] ?? 0)
            let port02Bin: String = padBinary(value: vm.snapshot?.executionSnapshot.ports[2] ?? 0)
            Text("0x02    \(port02Hex)  \(port02Bin)   PIO port B data port            ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let port03Hex: String = String(format: "0x%02X", vm.snapshot?.executionSnapshot.ports[3] ?? 0)
            let port03Bin: String = padBinary(value: vm.snapshot?.executionSnapshot.ports[3] ?? 0)
            Text("0x03    \(port03Hex)  \(port03Bin)   PIO port B data port            ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let port08Hex: String = String(format: "0x%02X", vm.snapshot?.executionSnapshot.ports[8] ?? 0)
            let port08Bin: String = padBinary(value: vm.snapshot?.executionSnapshot.ports[8] ?? 0)
            Text("0x08    \(port08Hex)  \(port08Bin)   Colour control port            ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let port0AHex: String = String(format: "0x%02X", vm.snapshot?.executionSnapshot.ports[10] ?? 0)
            let port0ABin: String = padBinary(value: vm.snapshot?.executionSnapshot.ports[10] ?? 0)
            Text("0x0A    \(port0AHex)  \(port0ABin)   PAK/NET selection port          ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let port0BHex: String = String(format: "0x%02X", vm.snapshot?.executionSnapshot.ports[11] ?? 0)
            let port0BBin: String = padBinary(value:vm.snapshot?.executionSnapshot.ports[11] ?? 0)
            Text("0x0B    \(port0BHex)  \(port0BBin)   Character generator latch port   ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let port0CHex: String = String(format: "0x%02X", vm.snapshot?.executionSnapshot.ports[12] ?? 0)
            let port0CBin: String = padBinary(value: vm.snapshot?.executionSnapshot.ports[12] ?? 0)
            Text("0x0C    \(port0CHex)  \(port0CBin)   6545 CRTC register port         ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let port0DHex: String = String(format: "0x%02X", vm.snapshot?.executionSnapshot.ports[13] ?? 0)
            let port0DBin: String = padBinary(value: vm.snapshot?.executionSnapshot.ports[13] ?? 0)
            Text("0x0D    \(port0DHex)  \(port0DBin)   6545 CRTC data port           ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            Spacer()
            
            Text("6545 Registers").font(.headline)
            
            Spacer()
            
            let R0Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R0 ?? 0)
            let R0Bin: String = padBinary(value:vm.snapshot?.crtcSnapshot.R0 ?? 0)
            Text("R0      \(R0Hex)  \(R0Bin)   Horizontal Total              ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let R1Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R1 ?? 0)
            let R1Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R1 ?? 0)
            Text("R1      \(R1Hex)  \(R1Bin)   Horizontal Displayed            ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let R2Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R2 ?? 0)
            let R2Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R2 ?? 0)
            Text("R2      \(R2Hex)  \(R2Bin)   Horizontal Sync Position               ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let R3Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R3 ?? 0)
            let R3Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R3 ?? 0)
            Text("R3      \(R3Hex)  \(R3Bin)   Sync Widths                     ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let R4Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R4 ?? 0)
            let R4Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R4 ?? 0)
            Text("R4      \(R4Hex)  \(R4Bin)   Vertical Total                ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let R5Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R5 ?? 0)
            let R5Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R5 ?? 0)
            Text("R5      \(R5Hex)  \(R5Bin)   Vertical Total Adjust           ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))

            let R6Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R6 ?? 0)
            let R6Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R6 ?? 0)
            Text("R6      \(R6Hex)  \(R6Bin)   Vertical Displayed             ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let R7Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R7 ?? 0)
            let R7Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R7 ?? 0)
            Text("R7      \(R7Hex)  \(R7Bin)   Vertical Sync Position          ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let R8Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R8 ?? 0)
            let R8Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R8 ?? 0)
            Text("R8      \(R8Hex)  \(R8Bin)   Interlace Mode and Skew           ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let R9Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R9 ?? 0)
            let R9Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R9 ?? 0)
            Text("R9      \(R9Hex)  \(R9Bin)   Maximum Raster Address          ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let R10Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R10 ?? 0)
            let R10Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R10 ?? 0)
            Text("R10     \(R10Hex)  \(R10Bin)   Cursor Start Line and Blink Mode")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let R11Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R11 ?? 0)
            let R11Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R11 ?? 0)
            Text("R11     \(R11Hex)  \(R11Bin)   Cursor End Line                 ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let R12Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R12 ?? 0)
            let R12Bin: String = padBinary(value:  vm.snapshot?.crtcSnapshot.R12 ?? 0)
            Text("R12     \(R12Hex)  \(R12Bin)   Display Address (High)         ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let R13Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R13 ?? 0)
            let R13Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R13 ?? 0)
            Text("R13     \(R13Hex)  \(R13Bin)   Display Address (Low)           ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let R14Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R14 ?? 0)
            let R14Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R14 ?? 0)
            Text("R14     \(R14Hex)  \(R14Bin)   Cursor Address (High)           ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let R15Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R15 ?? 0)
            let R15Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R15 ?? 0)
            Text("R15     \(R15Hex)  \(R15Bin)   Cursor Address (Low)            ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let R16Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R16 ?? 0)
            let R16Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R16 ?? 0)
            Text("R16     \(R16Hex)  \(R16Bin)   Light Pen Address (High)           ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let R17Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R17 ?? 0)
            let R17Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R17 ?? 0)
            Text("R17     \(R17Hex)  \(R17Bin)   Light Pen Address (Low)         ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let R18Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R18 ?? 0)
            let R18Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R18 ?? 0)
            Text("R18     \(R18Hex)  \(R18Bin)   Update Address (High)             ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let R19Hex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.R19 ?? 0)
            let R19Bin: String = padBinary(value: vm.snapshot?.crtcSnapshot.R19 ?? 0)
            Text("R19     \(R19Hex)  \(R19Bin)   Update Address (Low)            ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let statusRegHex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.StatusRegister ?? 0)
            let statusRegBin: String = padBinary(value: vm.snapshot?.crtcSnapshot.StatusRegister ?? 0)
            Text("Status  \(statusRegHex)  \(statusRegBin)   Status Register              ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let RBIHex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.redBackgroundIntensity ?? 0)
            let RBIBin: String = padBinary(value: vm.snapshot?.crtcSnapshot.redBackgroundIntensity ?? 0)
            Text("RBI     \(RBIHex)  \(RBIBin)   Red Background Intensity        ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
            
            let GBIHex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.greenBackgroundIntensity ?? 0)
            let GBIBin: String = padBinary(value: vm.snapshot?.crtcSnapshot.greenBackgroundIntensity ?? 0)
            Text("GBI     \(GBIHex)  \(GBIBin)   Green Background Intensity        ")
                .foregroundColor(Color.orange)
                .font(.system(.body, design: .monospaced))
            
            let BBIHex: String = String(format: "0x%02X", vm.snapshot?.crtcSnapshot.blueBackgroundIntensity ?? 0)
            let BBIBin: String = padBinary(value: vm.snapshot?.crtcSnapshot.blueBackgroundIntensity ?? 0)
            Text("BBI     \(BBIHex)  \(BBIBin)   Blue Background Intensity       ")
                .foregroundColor(Color.orange)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .font(.system(.body, design: .monospaced))
        }
        .fixedSize()
        .padding(10)
        .background(.white)
    }
}

