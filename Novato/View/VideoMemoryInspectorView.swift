import SwiftUI

struct videoMemoryInspectorView: View
{
    @Environment(emulatorViewModel.self) private var vm
    @State private var memoryAddressText = "0000"
    @State private var videoMemorySelection = "Video RAM"
    let videoMemoryOptions = ["Video RAM", "Attribute RAM", "Colour RAM", "Font ROM", "PCG Bank 0", "PCG Bank 1","PCG Bank 2","PCG Bank 3","PCG Bank 4","PCG Bank 5","PCG Bank 6","PCG Bank 7"]

    struct MemoryRowView: View
    {
        let row: Int
        let snapshot: microbeeSnapshot
        let vm: emulatorViewModel
        let videoRAMType : String
        
        func mapascii (ascii : UInt8) -> String
        {
            switch ascii
            {
            case 32...126:
                return String(UnicodeScalar(Int(ascii))!)
            default:
                return "."
            }
        }
        
        var body: some View
        {
            let config: (start: UInt16, bytes: [UInt8]) = {
                switch videoRAMType
                {
                    case "Attribute RAM":
                        return (0xF000, snapshot.memorySnapshot.attributeRAM.map { UInt8(clamping: Int($0)) })
                    case "Colour RAM":
                        return (0xF800, snapshot.memorySnapshot.colourRAM.map { UInt8(clamping: Int($0)) })
                    case "PCG Bank 0":
                        return (0xF800, snapshot.memorySnapshot.pcgRAM[0...0x7ff].map { UInt8(clamping: Int($0)) })
                    case "PCG Bank 1":
                        return (0xF800, snapshot.memorySnapshot.pcgRAM[0x800...0xfff].map { UInt8(clamping: Int($0)) })
                    case "PCG Bank 2":
                        return (0xF800, snapshot.memorySnapshot.pcgRAM[0x1000...0x17ff].map { UInt8(clamping: Int($0)) })
                    case "PCG Bank 3":
                        return (0xF800, snapshot.memorySnapshot.pcgRAM[0x1800...0x1fff].map { UInt8(clamping: Int($0)) })
                    case "PCG Bank 4":
                        return (0xF800, snapshot.memorySnapshot.pcgRAM[0x2000...0x27ff].map { UInt8(clamping: Int($0)) })
                    case "PCG Bank 5":
                        return (0xF800, snapshot.memorySnapshot.pcgRAM[0x2800...0x2fff].map { UInt8(clamping: Int($0)) })
                    case "PCG Bank 6":
                        return (0xF800, snapshot.memorySnapshot.pcgRAM[0x3000...0x37ff].map { UInt8(clamping: Int($0)) })
                    case "PCG Bank 7":
                        return (0xF800, snapshot.memorySnapshot.pcgRAM[0x3800...0x3fff].map { UInt8(clamping: Int($0)) })
                    case "Font ROM":
                        return (0xF000, snapshot.memorySnapshot.charROM.map { UInt8(clamping: Int($0)) })
                    default:
                        return (0xF000, snapshot.memorySnapshot.videoRAM.map { UInt8(clamping: Int($0)) })
                }
            }()
            let startAddress = config.start
            let sourceBytes = config.bytes

            let address = row * 32
            let dispAddress = startAddress &+ UInt16(address)
            
            let bytes: [UInt8] = sourceBytes[address..<(address+32)].map { $0 }
            let hexBytes: String = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
            let charBytes: String = bytes.map { mapascii(ascii:$0) }.joined(separator: "")
            let alternateRow = (row % 2) == 1
            let addressString = String(format:"0x%04X", dispAddress)
        
            HStack(alignment: .firstTextBaseline, spacing: 8)
            {
                Text(addressString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
                Text("   ")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
                Text(hexBytes)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
                Text(charBytes)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
            }
            .background(alternateRow ? Color(red: 0.95, green: 0.95, blue: 0.97) : Color.clear)
        }
    }
    
    var body: some View
    
    {
        if let snapshot = vm.snapshot
        {
            ScrollView
            {
                Picker("Video Memory", selection: $videoMemorySelection)
                {
                    ForEach(videoMemoryOptions, id: \.self) { Text($0) }
                }
                
                Spacer()
                Spacer()
                
                VStack()
                {
                    let limit : Int = 32
                    ForEach(0..<limit, id: \.self)
                    {
                        row in MemoryRowView(row: row, snapshot: snapshot, vm: vm, videoRAMType : videoMemorySelection)
                    }
                }
            }
            .fixedSize()
            .padding(10)
            .background(.white)
            .onAppear
            {
                memoryAddressText = String(format: "%04X", snapshot.memoryInspectorSnapshot.memoryInspectorAddress)
            }
        }
        else
        {
            Text("Nothing to see here folks")
        }
    }
}

