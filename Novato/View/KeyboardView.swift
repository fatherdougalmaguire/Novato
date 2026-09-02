import SwiftUI
import AppKit

struct KeyboardResponderView: NSViewRepresentable
{
    let onKeyDown: (NSEvent) -> Void
    let onKeyUp: (NSEvent) -> Void
    let onFlagsChanged: (NSEvent) -> Void

    func makeNSView(context: Context) -> KeyboardNSView
    {
        let view = KeyboardNSView()

        view.onKeyDown = onKeyDown
        view.onKeyUp = onKeyUp
        view.onFlagsChanged = onFlagsChanged

        return view
    }

    func updateNSView(
        _ nsView: KeyboardNSView,
        context: Context
    )
    {
        nsView.onKeyDown = onKeyDown
        nsView.onKeyUp = onKeyUp
        nsView.onFlagsChanged = onFlagsChanged
    }
}

final class KeyboardNSView: NSView
{
    var onKeyDown: ((NSEvent) -> Void)?
    var onKeyUp: ((NSEvent) -> Void)?
    var onFlagsChanged: ((NSEvent) -> Void)?

    override var acceptsFirstResponder: Bool
    {
        true
    }

    override func becomeFirstResponder() -> Bool
    {
        true
    }

    override func viewDidMoveToWindow()
    {
        super.viewDidMoveToWindow()

        Task { @MainActor [weak self] in
            guard let self,
                  let window = self.window
            else
            {
                return
            }

            if window.firstResponder !== self
            {
                window.makeFirstResponder(self)
            }
        }
    }

    override func keyDown(with event: NSEvent)
    {
        onKeyDown?(event)
    }

    override func keyUp(with event: NSEvent)
    {
        onKeyUp?(event)
    }

    override func flagsChanged(with event: NSEvent)
    {
        onFlagsChanged?(event)
    }
}
