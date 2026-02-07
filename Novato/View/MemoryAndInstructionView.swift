import SwiftUI

struct memoryAndInstructionView: View
{
    @Environment(emulatorViewModel.self) private var vm
    
    let shizz = Z80Opcodes()
    
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
            case 32...127:
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
            let nextaddress = (row+1)*16
            let dispaddress = startAddress &+ UInt16(address)
            let bytes: ArraySlice<UInt8> = snapshot.memorySnapshot.memoryDump[address..<(address+16)]
            let hexBytes: String = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
            let charBytes: String = bytes.map { mapascii(ascii:$0) }.joined(separator: "")
            let highlight = (snapshot.z80Snapshot.PC >= address) && (snapshot.z80Snapshot.PC < nextaddress)
            let alternateRow = (row % 2) == 1
            let offset = Int(snapshot.z80Snapshot.PC) - address
            
            let addressString = String(format:"0x%04X", dispaddress)
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
                VStack()
                {
                    Text("Memory")
                        .font(.headline)
                    
                    Spacer()
                    
                    let startAddress = snapshot.z80Snapshot.PC & 0xFF00
                    let limit : Int = snapshot.memorySnapshot.memoryDump.count / 16
                    ForEach(0..<limit, id: \.self)
                    {
                        row in MemoryRowView(row: row, snapshot: snapshot, vm: vm, startAddress: startAddress)
                    }
                    
                    Spacer()
                    
                    Text("Instructions")
                        .font(.headline)
                    
                    Spacer()
                    
                    let ken = snapshot.executionSnapshot.z80Queue
                    Group {
                        ForEach(0...15, id: \.self) { row in
                            let outputString = ken.decodeAddress(index: row) + "   " + ken.decodeBytes(index: row) + "    " + shizz.decodeInstructions(opCodes: ken.returnOpcodes(index: row), dataBytes: ken.returnDataBytes(index: row))
                            let alternateRow = (row % 2) == 1

                            if ken.checkEmptyQueue(index: row) {
                                Text("")
                            } else {
                                if snapshot.executionSnapshot.lastPC == ken.returnAddress(index: row) {
                                    Text(outputString)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.white)
                                        .background(Color.orange)
                                } else {
                                    Text(outputString)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.orange)
                                        .background(alternateRow ? Color(red: 0.95, green: 0.95, blue: 0.97) : Color.clear)
                                }
                            }
                        }
                    }
                }
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

