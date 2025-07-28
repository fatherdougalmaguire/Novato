import SwiftUI

struct MemoryView: View {
    var memory: [UInt8]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                Text("Memory View").font(.headline)
                ForEach(0..<memory.count / 16, id: \.self) { row in
                    let address = row * 16
                    let bytes = memory[address..<address+16]
                    let hexBytes = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                    Text(String(format: "0x%04X: %@", address, hexBytes))
                        .font(.system(.body, design: .monospaced))
                }
            }
            .padding()
        }
        .frame(height: 300)
    }
}