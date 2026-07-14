import SwiftUI

struct TickdayCommands: Commands {
    @FocusedValue(\.createCurrentItem) private var createCurrentItem
    @FocusedValue(\.deleteCurrentItem) private var deleteCurrentItem
    @FocusedValue(\.toggleCurrentTask) private var toggleCurrentTask

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Item") { createCurrentItem?() }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(createCurrentItem == nil)
        }
        CommandGroup(after: .pasteboard) {
            Button("Delete") { deleteCurrentItem?() }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(deleteCurrentItem == nil)
            Button("Toggle Task") { toggleCurrentTask?() }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(toggleCurrentTask == nil)
        }
    }
}

private struct CreateCurrentItemKey: FocusedValueKey { typealias Value = () -> Void }
private struct DeleteCurrentItemKey: FocusedValueKey { typealias Value = () -> Void }
private struct ToggleCurrentTaskKey: FocusedValueKey { typealias Value = () -> Void }

extension FocusedValues {
    var createCurrentItem: (() -> Void)? { get { self[CreateCurrentItemKey.self] } set { self[CreateCurrentItemKey.self] = newValue } }
    var deleteCurrentItem: (() -> Void)? { get { self[DeleteCurrentItemKey.self] } set { self[DeleteCurrentItemKey.self] = newValue } }
    var toggleCurrentTask: (() -> Void)? { get { self[ToggleCurrentTaskKey.self] } set { self[ToggleCurrentTaskKey.self] = newValue } }
}
