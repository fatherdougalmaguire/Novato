import SwiftUI

struct portAndCrtcView: View
{
    @Environment(emulatorViewModel.self) private var vm
    
    func padBinary(value: UInt8) -> String
    {
        let binString = String(value, radix: 2)
        let paddingCount: Int = max(0, 8 - binString.count)
        let padded = String(repeating: "0", count: paddingCount) + binString
        return padded
    }
    
    @ViewBuilder
    func displayPort(portLabel: String, portDescription: String, portValue: UInt8, alternateRow: Bool) -> some View
    {
        let portHex: String = String(format: "0x%02X", portValue)
        let portBinary: String = padBinary(value: portValue)
        Text(portLabel+"   " + portHex + " " + portBinary + " " + portDescription)
            .foregroundColor(Color.orange)
            .font(.system(.body, design: .monospaced))
            .background(alternateRow ? Color(red: 0.95, green: 0.95, blue: 0.97) : Color.clear)
    }
    
    var body: some View
    {
        if let snapshot = vm.snapshot
        {
            VStack(alignment: .leading)
            {
                Text("Z80 Ports").font(.headline)
                
                Spacer()
                
//                let port00Hex: String = String(format: "0x%02X", snapshot.executionSnapshot.ports[0])
//                let port00Bin: String = padBinary(value: snapshot.executionSnapshot.ports[0])
//                Text("0x00   \(port00Hex) \(port00Bin) PIO port A data port")
//                    .foregroundColor(Color.orange)
//                    .font(.system(.body, design: .monospaced))
                
                displayPort(portLabel: "0x00",portDescription: "PIO port A data port",portValue: snapshot.executionSnapshot.ports[0], alternateRow: false)
                displayPort(portLabel: "0x01",portDescription: "PIO port A control port       ",portValue: snapshot.executionSnapshot.ports[1], alternateRow: true)
                displayPort(portLabel: "0x02",portDescription: "PIO port B data port          ",portValue: snapshot.executionSnapshot.ports[2], alternateRow: false)
                displayPort(portLabel: "0x03",portDescription: "PIO port B control port       ",portValue: snapshot.executionSnapshot.ports[3], alternateRow: true)
                displayPort(portLabel: "0x08",portDescription: "Colour control port           ",portValue: snapshot.executionSnapshot.ports[8], alternateRow: false)
                displayPort(portLabel: "0x0A",portDescription: "PAK/NET selection port        ",portValue: snapshot.executionSnapshot.ports[10], alternateRow: true)
                displayPort(portLabel: "0x0B",portDescription: "Character generator latch port",portValue: snapshot.executionSnapshot.ports[11], alternateRow: false)
                displayPort(portLabel: "0x0C",portDescription: "6545 CRTC register port       ",portValue: snapshot.executionSnapshot.ports[12], alternateRow: true)
                displayPort(portLabel: "0x0D",portDescription: "6545 CRTC data port           ",portValue: snapshot.executionSnapshot.ports[13], alternateRow: false)
                
                Spacer()
                
                Text("CRTC registers").font(.headline)
                
                Spacer()
                
                displayPort(portLabel: "0x00",portDescription: "Horizontal Total-1            ",portValue: snapshot.crtcSnapshot.R0, alternateRow: false)
                displayPort(portLabel: "0x01",portDescription: "Horizontal Displayed          ",portValue: snapshot.crtcSnapshot.R1, alternateRow: true)
                displayPort(portLabel: "0x02",portDescription: "Horizontal Sync Position      ",portValue: snapshot.crtcSnapshot.R2, alternateRow: false)
                displayPort(portLabel: "0x03",portDescription: "V-SYNC and H-SYNC Width       ",portValue: snapshot.crtcSnapshot.R3, alternateRow: true)
                displayPort(portLabel: "0x04",portDescription: "Vertical Total-1              ",portValue: snapshot.crtcSnapshot.R4, alternateRow: false)
                displayPort(portLabel: "0x05",portDescription: "Vertical Total Adjust         ",portValue: snapshot.crtcSnapshot.R5, alternateRow: true)
                displayPort(portLabel: "0x06",portDescription: "Vertical Displayed            ",portValue: snapshot.crtcSnapshot.R6, alternateRow: false)
                displayPort(portLabel: "0x07",portDescription: "Vertical Sync Position        ",portValue: snapshot.crtcSnapshot.R7, alternateRow: true)
                displayPort(portLabel: "0x08",portDescription: "Mode Control                  ",portValue: snapshot.crtcSnapshot.R8, alternateRow: false)
                displayPort(portLabel: "0x09",portDescription: "Scan Lines-1                  ",portValue: snapshot.crtcSnapshot.R9, alternateRow: false)
                displayPort(portLabel: "0x0A",portDescription: "Cursor Start and Blink Mode   ",portValue: snapshot.crtcSnapshot.R10, alternateRow: true)
                displayPort(portLabel: "0x0B",portDescription: "Cursor End                    ",portValue: snapshot.crtcSnapshot.R11, alternateRow: false)
                displayPort(portLabel: "0x0C",portDescription: "Display Start Address - High  ",portValue: snapshot.crtcSnapshot.R12, alternateRow: true)
                displayPort(portLabel: "0x0D",portDescription: "Display Start Address - Low   ",portValue: snapshot.crtcSnapshot.R13, alternateRow: false)
                displayPort(portLabel: "0x0E",portDescription: "Cursor Position - High        ",portValue: snapshot.crtcSnapshot.R14, alternateRow: true)
                displayPort(portLabel: "0x0F",portDescription: "Cursor Position - Low         ",portValue: snapshot.crtcSnapshot.R15, alternateRow: false)
                displayPort(portLabel: "0x10",portDescription: "Light Pen Register - High     ",portValue: snapshot.crtcSnapshot.R16, alternateRow: true)
                displayPort(portLabel: "0x11",portDescription: "Light Pen Register - Low      ",portValue: snapshot.crtcSnapshot.R17, alternateRow: false)
                displayPort(portLabel: "0x12",portDescription: "Update Address Register - High",portValue: snapshot.crtcSnapshot.R18, alternateRow: true)
                displayPort(portLabel: "0x13",portDescription: "Update Address Register - Low ",portValue: snapshot.crtcSnapshot.R19, alternateRow: false)
                
                Spacer()
                
                displayPort(portLabel: "    ",portDescription: "Status Register               ",portValue: snapshot.crtcSnapshot.statusRegister, alternateRow: false)
                
                Spacer()
                
                displayPort(portLabel: "    ",portDescription: "Red Background Intensity      ",portValue: snapshot.crtcSnapshot.redBackgroundIntensity, alternateRow: false)
                displayPort(portLabel: "    ",portDescription: "Green Background Intensity    ",portValue: snapshot.crtcSnapshot.greenBackgroundIntensity, alternateRow: true)
                displayPort(portLabel: "    ",portDescription: "Blue Background Intensity     ",portValue: snapshot.crtcSnapshot.blueBackgroundIntensity, alternateRow: false)
                
            }
            .fixedSize()
            .padding(10)
            .background(.white)
        }
        else
        {
            Text("Nothing to see here folks")
        }
    }
}

