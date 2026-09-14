import SwiftUI

struct memoryInspectorView: View
{
    @Environment(emulatorViewModel.self) private var vm
    @State private var memoryAddressText = "0000"
    
    struct MemoryRowView: View
    {
        let row: Int
        let snapshot: microbeeSnapshot
        let vm: emulatorViewModel
        let startAddress: UInt16
        
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
        
        func highlightString(originalString: String, numDigits: Int, offset: Int, activate: Bool) -> AttributedString
        {
            var tempResult = AttributedString(originalString)
            
            if activate
            {
                let beginindex = tempResult.characters.index(tempResult.startIndex, offsetBy: offset)
                let finalindex = tempResult.characters.index(tempResult.startIndex, offsetBy: offset+numDigits)
                
                tempResult[beginindex..<finalindex].backgroundColor = .orange
                tempResult[beginindex..<finalindex].foregroundColor = .white
            }
            
            return tempResult
        }
        
        var body: some View
        {
            let address = row * 16
            let nextAddress = (row+1)*16
            let dispAddress = startAddress &+ UInt16(address)
            let dispNextAddress = startAddress &+ UInt16(nextAddress)
            let bytes: ArraySlice<UInt8> = snapshot.memoryInspectorSnapshot.memoryInspectorDump[address..<(address+16)]
            let hexBytes: String = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
            let charBytes: String = bytes.map { mapascii(ascii:$0) }.joined(separator: "")
            let highlight = (snapshot.memoryInspectorSnapshot.memoryInspectorAddress >= dispAddress) && (snapshot.memoryInspectorSnapshot.memoryInspectorAddress < dispNextAddress)
            let alternateRow = (row % 2) == 1
            let offset = abs(Int(snapshot.memoryInspectorSnapshot.memoryInspectorAddress) - Int(dispAddress))
            let addressString = String(format:"0x%04X", dispAddress)
            let byteString = highlightString(originalString: hexBytes, numDigits: 2, offset: offset * 3, activate: highlight)
            let charString = highlightString(originalString: charBytes, numDigits: 1, offset: offset, activate: highlight)
        
            HStack(alignment: .firstTextBaseline, spacing: 8)
            {
                Text(addressString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
                Text("   ")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
                Text(byteString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
                Text(charString)
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
                Spacer()
                HStack(spacing: 8)
                {
                    Button
                    {
                        Task {
                            if let base = UInt16(memoryAddressText, radix: 16)
                            {
                                let newAddress = base &- 0x100

                                await vm.updateMemoryInspector(address: newAddress)

                                memoryAddressText = String(format: "%04X",newAddress)
                            }
                        }
                    }
                    label:
                    {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.bordered)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
                    
                    TextField(
                        "Address",
                        text: Binding(
                            get: { memoryAddressText },
                            set: { newValue in
                                let filtered = newValue
                                    .uppercased()
                                    .filter { "0123456789ABCDEF".contains($0) }

                                memoryAddressText = String(filtered.prefix(4))
                            }
                        ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .multilineTextAlignment(.center)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
                    .onSubmit
                    {                        
                        Task
                        {
                            let value = UInt16(memoryAddressText, radix: 16) ?? 0
                            await vm.updateMemoryInspector(address: value)
                        }
                    }
                    
                    Button
                    {
                        Task
                        {
                            if let base = UInt16(memoryAddressText, radix: 16)
                            {
                                let newAddress = base &+ 0x100

                                await vm.updateMemoryInspector(address: newAddress)

                                memoryAddressText = String(format: "%04X",newAddress)
                            }
                        }
                    }
                    label:
                    {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.bordered)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
                }
                
                Spacer()
                Spacer()
                
                VStack()
                {
                    let startAddress = snapshot.memoryInspectorSnapshot.memoryInspectorAddress & 0xFF00
                    let limit : Int = snapshot.memoryInspectorSnapshot.memoryInspectorDump.count / 16
                    ForEach(0..<limit, id: \.self)
                    {
                        row in MemoryRowView(row: row, snapshot: snapshot, vm: vm, startAddress: startAddress)
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

