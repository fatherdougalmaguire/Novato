import SwiftUI

struct breakpointsView: View {
    @Environment(emulatorViewModel.self) private var vm
    
    struct statusLED: View
    {
        let isOn: Bool
        var body: some View
        {
            Circle()
                .fill(isOn ? Color.green : Color.red)
                .frame(width: 14, height: 14)
                .overlay(Circle().fill(.white.opacity(0.4)).frame(width: 3, height: 3).offset(x: -2, y: -2))
                .shadow(color: isOn ? .green.opacity(0.8) : .clear, radius: 3)
        }
    }
    
    struct validateAddress: View
    {
        let text: String
        let isActive: Bool
        let labelText: String
        let onCommit: (String) -> Void
        let onToggle: (String) -> Void
        
        @State private var localText: String = ""

        var body: some View
        {
            HStack(spacing: 12)
            {
                Button(action: { onToggle(localText) }) { statusLED(isOn: isActive) }
                .buttonStyle(.plain)
                
                TextField(labelText, text: $localText)
                    .textFieldStyle(.squareBorder)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
                    .frame(minWidth: 180)
                    .autocorrectionDisabled()
                    .onSubmit
                    {
                        onCommit(localText)
                    }
                    .onChange(of: localText)
                    { _, newValue in
                        let filtered = newValue.filter { $0.isHexDigit }.uppercased()
                        localText = String(filtered.prefix(4))
                    }
            }
            .onAppear { localText = text }
            .onChange(of: text)
            { _, newValue in
                if localText != newValue
                {
                    localText = newValue
                }
            }
        }
    }
    
    private func updateActor(index: Int, hex: String, mask: Bool)
    {
        let scrubbed = hex.filter { $0.isHexDigit }
        
        if scrubbed.isEmpty
        {
            Task { await vm.updateBreakpoints(index: index, value: 0, mask: false) }
        }
        else if let value = UInt16(scrubbed, radix: 16)
        {
            Task { await vm.updateBreakpoints(index: index, value: value, mask: mask) }
        }
    }

    var body: some View
    {
        if let snapshot = vm.snapshot
        {
            let breakpoints = snapshot.executionSnapshot.breakpointQueue
            let masks = snapshot.executionSnapshot.breakpointQueueMask
            
            VStack(alignment: .leading, spacing: 10)
            {

                ForEach(breakpoints.indices, id: \.self)
                { index in
                    let addrRaw = breakpoints[index]
                    let isMasked = masks[index]
                    
                    let hexDisplay: String =
                    {

                        let val = UInt16(addrRaw, radix: 16) ?? UInt16(addrRaw) ?? 0

                        if val == 0 && !isMasked
                        {
                            return ""
                        }
                    
                        return String(format: "%04X", val)
                    }()
    

                    validateAddress(
                        text: hexDisplay,
                        isActive: isMasked,
                        labelText: "Breakpoint \(index + 1)",
                        onCommit: { newValue in updateActor(index: index, hex: newValue, mask: isMasked) },
                        onToggle:
                        {
                            currentText in
                            let finalHex = currentText.isEmpty ? hexDisplay : currentText
                            updateActor(index: index, hex: finalHex, mask: !isMasked)
                        }
                    )
                }
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
        }
        else
        {
            Text("Nothing to see here folks")
        }
    }
}
