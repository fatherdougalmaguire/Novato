import SwiftUI

struct RegisterView: View {
    var registers: Registers

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Z80 Registers").font(.headline)
            ForEach([
                ("AF", registers.AF),
                ("BC", registers.BC),
                ("DE", registers.DE),
                ("HL", registers.HL),
                ("IX", registers.IX),
                ("IY", registers.IY),
                ("SP", registers.SP),
                ("PC", registers.PC)
            ], id: \.0) { name, value in
                Text("\(name): 0x\(String(format: "%04X", value))")
                    .font(.system(.body, design: .monospaced))
            }
        }
        .padding()
    }
}
