import Carbon
import Foundation

/// Manages global hotkey registration and handling
class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let hotkeyID = EventHotKeyID(signature: OSType(0x4A4D5020), id: 1) // "JMP "
    var onHotkeyPressed: (() -> Void)?

    /// Register the global hotkey: cmd + ctrl + shift + opt + space
    func registerHotkey() -> Bool {
        // Define the hotkey: space (49)
        let keyCode: UInt32 = 49 // Space key

        // Modifiers: cmd + ctrl + shift + opt
        let modifiers: UInt32 = UInt32(cmdKey | controlKey | shiftKey | optionKey)

        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            print("Failed to register hotkey: \(status)")
            return false
        }

        self.hotKeyRef = hotKeyRef

        // Install event handler
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let callback: EventHandlerUPP = { _, event, userData in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }

            let manager = Unmanaged<HotkeyManager>
                .fromOpaque(userData)
                .takeUnretainedValue()

            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                event,
                UInt32(kEventParamDirectObject),
                UInt32(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            if hotKeyID.id == manager.hotkeyID.id {
                DispatchQueue.main.async {
                    manager.onHotkeyPressed?()
                }
                return noErr
            }

            return OSStatus(eventNotHandledErr)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        var eventHandler: EventHandlerRef?

        let installStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventSpec,
            selfPtr,
            &eventHandler
        )

        guard installStatus == noErr else {
            print("Failed to install event handler: \(installStatus)")
            return false
        }

        self.eventHandler = eventHandler
        return true
    }

    /// Unregister the hotkey
    func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregisterHotkey()
    }
}
