import SwiftUI

struct registerView: View
{
    @Environment(emulatorViewModel.self) private var vm
    
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
                .foregroundColor(.orange)
               // .font(.headline)
                .font(.system(.body, design: .monospaced))
            Text(getFlags(flag: value))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.orange)
        }
    }
    
    @ViewBuilder
    func registerRow(label: String, value: UInt8) -> some View
    {
        VStack
        {
            Text(label)
                .foregroundColor(.orange)
                .font(.headline)
            Text(String(format:"%02X", value))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.orange)
        }
    }
    
    @ViewBuilder
    func booleanRow(label: String, value: Bool) -> some View
    {
        VStack
        {
            Text(label)
                .foregroundColor(.orange)
                .font(.headline)
            Text(String(value))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.orange)
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
        if let snapshot = vm.snapshot
        {
            VStack(spacing: 20)
            {
                HStack(spacing: 40)
                {
                    VStack
                    {
                        Text("PC").font(.headline).foregroundColor(.orange)
                        Text(String(format: "%04X",snapshot.z80Snapshot.PC)).font(.system(.title3, design: .monospaced)).foregroundColor(.orange)
                    }
                    VStack
                    {
                        Text("SP").font(.headline).foregroundColor(.orange)
                        Text(String(format: "%04X",snapshot.z80Snapshot.SP)).font(.system(.title3, design: .monospaced)).foregroundColor(.orange)
                    }
                    VStack
                    {
                        Text("IX").font(.headline).foregroundColor(.orange)
                        Text(String(format: "%04X",snapshot.z80Snapshot.IX)).font(.system(.title3, design: .monospaced)).foregroundColor(.orange)
                    }
                    VStack
                    {
                        Text("IY").font(.headline).foregroundColor(.orange)
                        Text(String(format: "%04X",snapshot.z80Snapshot.IY)).font(.system(.title3, design: .monospaced)).foregroundColor(.orange)
                    }
                    VStack
                    {
                        Text("BC").font(.headline).foregroundColor(.orange)
                        Text(String(format: "%04X",snapshot.z80Snapshot.BC)).font(.system(.title3, design: .monospaced)).foregroundColor(.orange)
                    }
                    VStack
                    {
                        Text("DE").font(.headline).foregroundColor(.orange)
                        Text(String(format: "%04X",snapshot.z80Snapshot.DE)).font(.system(.title3, design: .monospaced)).foregroundColor(.orange)
                    }
                    VStack
                    {
                        Text("HL").font(.headline).foregroundColor(.orange)
                        Text(String(format: "%04X",snapshot.z80Snapshot.HL)).font(.system(.title3, design: .monospaced)).foregroundColor(.orange)
                    }
                    VStack
                    {
                        Text("BC'").font(.headline).foregroundColor(.orange)
                        Text(String(format: "%04X",snapshot.z80Snapshot.altBC)).font(.system(.title3, design: .monospaced)).foregroundColor(.orange)
                    }
                    VStack
                    {
                        Text("DE'").font(.headline).foregroundColor(.orange)
                        Text(String(format: "%04X",snapshot.z80Snapshot.altDE)).font(.system(.title3, design: .monospaced)).foregroundColor(.orange)
                    }
                    VStack
                    {
                        Text("HL'").font(.headline).foregroundColor(.orange)
                        Text(String(format: "%04X",snapshot.z80Snapshot.altHL)).font(.system(.title3, design: .monospaced)).foregroundColor(.orange)
                    }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(60)), count: 8), spacing: 10)
                {
                    registerRow(label: "A", value: snapshot.z80Snapshot.A)
                    registerRow(label: "F", value: snapshot.z80Snapshot.F)
                    registerRow(label: "B", value: snapshot.z80Snapshot.B)
                    registerRow(label: "C", value: snapshot.z80Snapshot.C)
                    registerRow(label: "D", value: snapshot.z80Snapshot.D)
                    registerRow(label: "E", value: snapshot.z80Snapshot.E)
                    registerRow(label: "H", value: snapshot.z80Snapshot.H)
                    registerRow(label: "L", value: snapshot.z80Snapshot.L)

                    registerRow(label: "A'", value: snapshot.z80Snapshot.altA)
                    registerRow(label: "F'", value: snapshot.z80Snapshot.altF)
                    registerRow(label: "B'", value: snapshot.z80Snapshot.altB)
                    registerRow(label: "C'", value: snapshot.z80Snapshot.altC)
                    registerRow(label: "D'", value: snapshot.z80Snapshot.altD)
                    registerRow(label: "E'", value: snapshot.z80Snapshot.altE)
                    registerRow(label: "H'", value: snapshot.z80Snapshot.altH)
                    registerRow(label: "L'", value: snapshot.z80Snapshot.altL)

                    registerRow(label: "I", value: snapshot.z80Snapshot.I)
                    registerRow(label: "R", value: snapshot.z80Snapshot.R)
                    registerRow(label: "IM", value: snapshot.z80Snapshot.IM)
                    booleanRow(label: "IFF1", value: snapshot.z80Snapshot.IFF1)
                    booleanRow(label: "IFF2", value: snapshot.z80Snapshot.IFF2)
                }
                FlagRegister(label: "S   Z   X   H   Y  P/V  N   C   ", value: snapshot.z80Snapshot.F)
                
                Text("T-States").font(.headline).foregroundColor(.orange)
                Text(snapshot.executionSnapshot.tStates.formatted()).foregroundColor(.orange)
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

