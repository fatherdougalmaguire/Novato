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
    
    @ViewBuilder
    func booleanRow(label: String, value: Bool) -> some View
    {
        VStack
        {
            Text(label)
                .font(.system(.body, design: .monospaced))
            Text(String(value))
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
                HStack(spacing: 40)
                {
                    VStack
                    {
                        Text("PC").font(.headline)
                        Text(String(format: "%04X",vm.snapshot?.z80Snapshot.PC ?? 0)).font(.system(.title3, design: .monospaced))
                    }
                    VStack
                    {
                        Text("SP").font(.headline)
                        Text(String(format: "%04X",vm.snapshot?.z80Snapshot.SP ?? 0)).font(.system(.title3, design: .monospaced))
                    }
                    VStack
                    {
                        Text("IX").font(.headline)
                        Text(String(format: "%04X",vm.snapshot?.z80Snapshot.IX ?? 0)).font(.system(.title3, design: .monospaced))
                    }
                    VStack
                    {
                        Text("IY").font(.headline)
                        Text(String(format: "%04X",vm.snapshot?.z80Snapshot.IY ?? 0)).font(.system(.title3, design: .monospaced))
                    }
                    VStack
                    {
                        Text("BC").font(.headline)
                        Text(String(format: "%04X",vm.snapshot?.z80Snapshot.BC ?? 0)).font(.system(.title3, design: .monospaced))
                    }
                    VStack
                    {
                        Text("DE").font(.headline)
                        Text(String(format: "%04X",vm.snapshot?.z80Snapshot.DE ?? 0)).font(.system(.title3, design: .monospaced))
                    }
                    VStack
                    {
                        Text("HL").font(.headline)
                        Text(String(format: "%04X",vm.snapshot?.z80Snapshot.HL ?? 0)).font(.system(.title3, design: .monospaced))
                    }
                    VStack
                    {
                        Text("BC'").font(.headline)
                        Text(String(format: "%04X",vm.snapshot?.z80Snapshot.AltBC ?? 0)).font(.system(.title3, design: .monospaced))
                    }
                    VStack
                    {
                        Text("DE'").font(.headline)
                        Text(String(format: "%04X",vm.snapshot?.z80Snapshot.AltDE ?? 0)).font(.system(.title3, design: .monospaced))
                    }
                    VStack
                    {
                        Text("HL'").font(.headline)
                        Text(String(format: "%04X",vm.snapshot?.z80Snapshot.AltHL ?? 0)).font(.system(.title3, design: .monospaced))
                    }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(60)), count: 8), spacing: 10)
                {
                    Group
                    {
                        registerRow(label: "A", value: vm.snapshot?.z80Snapshot.A ?? 0)
                        registerRow(label: "F", value: vm.snapshot?.z80Snapshot.F ?? 0)
                        registerRow(label: "B", value: vm.snapshot?.z80Snapshot.B ?? 0)
                        registerRow(label: "C", value: vm.snapshot?.z80Snapshot.C ?? 0)
                        registerRow(label: "D", value: vm.snapshot?.z80Snapshot.D ?? 0)
                        registerRow(label: "E", value: vm.snapshot?.z80Snapshot.E ?? 0)
                        registerRow(label: "H", value: vm.snapshot?.z80Snapshot.H ?? 0)
                        registerRow(label: "L", value: vm.snapshot?.z80Snapshot.L ?? 0)
                    }
                    Group
                    {
                        registerRow(label: "A'", value: vm.snapshot?.z80Snapshot.AltA ?? 0)
                        registerRow(label: "F'", value: vm.snapshot?.z80Snapshot.AltF ?? 0)
                        registerRow(label: "B'", value: vm.snapshot?.z80Snapshot.AltB ?? 0)
                        registerRow(label: "C'", value: vm.snapshot?.z80Snapshot.AltC ?? 0)
                        registerRow(label: "D'", value: vm.snapshot?.z80Snapshot.AltD ?? 0)
                        registerRow(label: "E'", value: vm.snapshot?.z80Snapshot.AltE ?? 0)
                        registerRow(label: "H'", value: vm.snapshot?.z80Snapshot.AltH ?? 0)
                        registerRow(label: "L'", value: vm.snapshot?.z80Snapshot.AltL ?? 0)
                    }
                    Group
                    {
                        registerRow(label: "I", value: vm.snapshot?.z80Snapshot.I ?? 0)
                        registerRow(label: "R", value: vm.snapshot?.z80Snapshot.R ?? 0)
                        registerRow(label: "IM", value: vm.snapshot?.z80Snapshot.IM ?? 0)
                        booleanRow(label: "IFF1", value: vm.snapshot?.z80Snapshot.IFF1 ?? 0)
                        booleanRow(label: "IFF2", value: vm.vm.snapshot?.z80Snapshot.IFF2 ?? 0)
                    }
                }
                FlagRegister(label: "S   Z   X   H   Y  P/V  N   C   ", value: vm.snapshot?.z80Snapshot.F ?? 0)
                
                Text("T-States : "+vm.snapshot?.z80Snapshot.tStates.formatted())
            }
            .fixedSize()
            .padding(10)
            .background(.white)
        }
    }
