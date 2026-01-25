import SwiftUI

struct MemoryView: View
{
    @Environment(EmulatorViewModel.self) private var vm
    
    let shizz = Z80Opcodes()
    
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
        ZStack
        {
            Color.white

            ScrollView
            {
                VStack()
                {
                    Text("Memory View")
                        .font(.headline)
                    
                    Spacer()
                    
                    let startAddress = vm.pcReg & 0xFF00
                    let limit = vm.memoryDump.count / 16
                    ForEach(0..<limit, id: \.self)
                    { row in
                        let address = row * 16
                        let nextaddress = (row+1)*16
                        let dispaddress = startAddress &+ UInt16(address)
                        let bytes: ArraySlice<UInt8> = vm.memoryDump[address..<(address+16)]
                        let hexBytes: String = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                        let charBytes: String = bytes.map { mapascii(ascii:$0) }.joined(separator: "")
                        let highlight = (vm.pcReg >= address) && (vm.pcReg < nextaddress)
                        let alternateRow = (row % 2) == 1
                        let offset = vm.pcReg &- UInt16(address)
                        let addressString = String(format:"0x%04X", dispaddress)
                        
                        let byteString = highlightString(originalString: hexBytes, numDigits: 2, offset: Int(offset)*3, activate: highlight)
                        let charString = highlightString(originalString: charBytes, numDigits: 1, offset: Int(offset), activate: highlight)
                        
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
                    
                    Spacer()
                    
                    Text("Instruction view")
                        .font(.headline)

                    Spacer()
                    
                    if let ken = vm.Z80Queue
                    {
                            ForEach(0...15, id: \.self)
                            { row in
                      
                                    let outputString = ken.decodeAddress(index: row) + "   " + ken.decodeBytes(index: row) + "    " + shizz.decodeInstructions(opCodes: ken.returnOpcodes(index: row), dataBytes: ken.returnDataBytes(index: row))
                                    let alternateRow = (row % 2) == 1
                                    
                                if ken.checkEmptyQueue(index: row)
                                {
                                    Text("")
                                }
                                else
                                {
                                    if vm.lastpcReg == ken.returnAddress(index: row)
                                    {
                                        Text(outputString)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.white)
                                            .background(Color.orange)
                                    }
                                    else
                                    {
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
        }
        .fixedSize()
        .padding(10)
    }
    
}

