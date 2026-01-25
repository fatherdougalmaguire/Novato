import SwiftUI

struct RegisterView: View
{
    @Environment(EmulatorViewModel.self) private var vm
    
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
    
    func highlightString(originalString : String, numDigits : Int, offset : Int) -> AttributedString
    
    {
        var tempResult = AttributedString(originalString)
        
        let beginindex = tempResult.characters.index(tempResult.startIndex, offsetBy: offset)
        let finalindex = tempResult.characters.index(tempResult.startIndex, offsetBy: offset+numDigits)
        
        tempResult[beginindex..<finalindex].backgroundColor = .orange
        tempResult[beginindex..<finalindex].foregroundColor = .white
        
        return tempResult
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
        ZStack
        {
            Color.white
            VStack(spacing: 20)
            {
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
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(60)), count: 8), spacing: 10)
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
                    Group
                    {
                        registerRow(label: "I", value: vm.altaReg)
                        registerRow(label: "R", value: vm.altfReg)
                        registerRow(label: "IM", value: vm.altbReg)
                        registerRow(label: "IFF1", value: vm.altcReg)
                        registerRow(label: "IFF2", value: vm.altdReg)
                    }
                }
                FlagRegister(label: "S   Z   X   H   Y  P/V  N   C   ", value: vm.fReg)
                
                
                
            }
        }
        .fixedSize()
        .padding(10)
    }
}

