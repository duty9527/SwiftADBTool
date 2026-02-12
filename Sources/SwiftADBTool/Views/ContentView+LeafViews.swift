import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DeviceRow: View {
    let device: ADBDevice
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.displayName)
                        .font(.bodySans(13, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(device.subtitle)
                        .font(.bodySans(11, weight: .medium))
                        .foregroundStyle(Theme.slate)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.mint)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Theme.mint.opacity(0.15) : Color.white.opacity(0.65))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Theme.mint.opacity(0.45) : Color.white.opacity(0.6), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct FileManagerEntryRow: View {
    let name: String
    let fullPath: String
    let isDirectory: Bool
    let isSelected: Bool
    let folderTint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isDirectory ? "folder.fill" : "doc.text")
                .foregroundStyle(isDirectory ? folderTint : Theme.slate)
                .frame(width: 16)

            Text(name)
                .font(.mono(12.5))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.mint)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? Theme.mint.opacity(0.12) : Color.clear)
        )
        .help(fullPath)
    }
}

final class ThreadSafePathStore: @unchecked Sendable {
    private var storage: [String] = []
    private let lock = NSLock()

    func append(_ path: String) {
        lock.lock()
        storage.append(path)
        lock.unlock()
    }

    func values() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

struct ResizableTextEditor: View {
    @Binding var text: String
    @Binding var height: CGFloat

    let minHeight: CGFloat
    let maxHeight: CGFloat
    let font: Font

    @State private var topDragStart: CGFloat?
    @State private var bottomDragStart: CGFloat?

    var body: some View {
        TextEditor(text: $text)
            .font(font)
            .scrollContentBackground(.hidden)
            .frame(height: height)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.paper.opacity(0.90))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.mist.opacity(0.95), lineWidth: 1)
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 7)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if topDragStart == nil {
                                        topDragStart = height
                                    }
                                    if let start = topDragStart {
                                        height = clamp(start - value.translation.height)
                                    }
                                }
                                .onEnded { _ in
                                    topDragStart = nil
                                }
                        )

                    Spacer(minLength: 0)

                    Color.clear
                        .frame(height: 7)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if bottomDragStart == nil {
                                        bottomDragStart = height
                                    }
                                    if let start = bottomDragStart {
                                        height = clamp(start + value.translation.height)
                                    }
                                }
                                .onEnded { _ in
                                    bottomDragStart = nil
                                }
                        )
                }
            }
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        max(minHeight, min(value, maxHeight))
    }
}

struct FileDropTextField: View {
    let placeholder: String
    @Binding var text: String
    let allowedExtensions: Set<String>?
    let allowDirectory: Bool

    @State private var isDropTargeted = false

    init(
        placeholder: String,
        text: Binding<String>,
        allowedExtensions: Set<String>?,
        allowDirectory: Bool
    ) {
        self.placeholder = placeholder
        self._text = text
        if let allowedExtensions {
            self.allowedExtensions = Set(allowedExtensions.map { $0.lowercased() })
        } else {
            self.allowedExtensions = nil
        }
        self.allowDirectory = allowDirectory
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isDropTargeted ? Theme.ocean : Color.clear, lineWidth: 2)
            )
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted, perform: handleDrop)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let url = FileDropTextField.decodeDroppedURL(item: item) else {
                return
            }

            let normalizedURL = url.standardizedFileURL
            let path = normalizedURL.path

            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
                return
            }

            if allowDirectory && !isDirectory.boolValue {
                return
            }

            if !allowDirectory && isDirectory.boolValue {
                return
            }

            if let allowedExtensions {
                let ext = normalizedURL.pathExtension.lowercased()
                if !allowedExtensions.contains(ext) {
                    return
                }
            }

            DispatchQueue.main.async {
                text = path
            }
        }

        return true
    }

    nonisolated static func decodeDroppedURL(item: NSSecureCoding?) -> URL? {
        if let data = item as? Data {
            return URL(dataRepresentation: data, relativeTo: nil)
        }

        if let url = item as? URL {
            return url
        }

        if let str = item as? String {
            return URL(string: str)
        }

        return nil
    }
}
