import SwiftUI

struct breakpointsView: View
{
    @Environment(emulatorViewModel.self) private var vm
    
    struct StatusLED: View
    {
        let isOn: Bool
        
        private let ledOnColor = Color.green
        private let ledOffColor = Color.red
        
        var body: some View
        {
            Circle()
                .fill(isOn ? ledOnColor : ledOffColor)
                .frame(width: 15, height: 15)
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(isOn ? 0.4 : 0.4))
                        .frame(width: 3, height: 3)
                        .offset(x: -2, y: -2)
                )
                .shadow(color: isOn ? ledOnColor.opacity(0.8) : .clear, radius: 3)
                .animation(.easeInOut(duration: 0.1), value: isOn)
        }
    }
    
    struct ValidateAddress: View
    {
        @State private var localText: String
        let labelText: String
        let onCommit: (String) -> Void
        
        init(text: String, labelText: String, onCommit: @escaping (String) -> Void) {
            self._localText = State(initialValue: text)
            self.labelText = labelText
            self.onCommit = onCommit
        }
        
        var body: some View
        {
            HStack
            {
                StatusLED(isOn: !localText.isEmpty)
                TextField(labelText, text: $localText)
                    .textFieldStyle(SquareBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
                    .autocorrectionDisabled()
                    .onChange(of: localText) { _, newValue in
                        let filtered = newValue.filter { $0.isHexDigit }
                        if filtered.count > 4 {
                            localText = String(filtered.prefix(4)).uppercased()
                        } else {
                            localText = filtered.uppercased()
                        }
                        onCommit(localText)
                    }
            }
        }
    }
    
    private func updateActor(index: Int, hex: String, mask: Bool)
    {
        if let value = UInt16(hex, radix: 16)
        {
            Task {
                await vm.updateBreakpoints(index: index, value: value, mask : mask)
            }
        }
    }
    
    var body: some View
    {
        if let snapshot = vm.snapshot
        {
            let displayedBreakpoints: [String] = snapshot.executionSnapshot.breakpointQueue
            let displayedBreakpointMask : [Bool] = snapshot.executionSnapshot.breakpointQueueMask
            let adjustedMask: [Bool] = zip(displayedBreakpoints, displayedBreakpointMask).map { (bp, mask) in
                bp.isEmpty ? false : mask
            }
            
            VStack(alignment: .leading)
            {
                ForEach(displayedBreakpoints.indices, id: \.self) { index in
                    ValidateAddress(
                        text: displayedBreakpoints[index],
                        labelText: "Breakpoint \(index+1)",
                        onCommit: { newValue in
                            updateActor(index: index, hex: newValue, mask: true)
                        }
                    )
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

