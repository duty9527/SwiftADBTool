import SwiftUI

extension ContentView {
    func panel<Content: View>(
        _ title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.display(17, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.bodySans(12, weight: .medium))
                    .foregroundStyle(Theme.slate)
            }

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .appCard(fill: Color.white)
    }

    func settingsBlock<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.bodySans(12, weight: .bold))
                .foregroundStyle(Theme.ink)
            content()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.82), lineWidth: 1)
                }
        )
    }

    var selectedRebootModeHint: String {
        switch vm.rebootMode {
        case .system:
            return "系统重启: 正常重启到 Android。"
        case .recovery:
            return "恢复模式: 重启进入 Recovery。"
        case .bootloader:
            return "Bootloader: 重启进入引导加载模式。"
        case .sideload:
            return "Sideload: 进入 OTA sideload 模式。"
        }
    }

    func labelTag(_ text: String) -> some View {
        Text(text)
            .font(.bodySans(11, weight: .bold))
            .foregroundStyle(Theme.slate)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.mist)
            )
    }

    func textSendOptionLabel(_ title: String, help: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .lineLimit(1)

            Image(systemName: "questionmark.circle")
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(Theme.slate.opacity(0.95))
                .help(help)
        }
    }

    func textSendActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.bodySans(12, weight: .semibold))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }

    func commandAuxActionButton(_ title: String, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.bodySans(12, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .frame(width: width, alignment: .trailing)
    }

    func commandSendActionButton(_ title: String, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.bodySans(12, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .frame(width: width, alignment: .trailing)
    }

    func infoPill(_ title: String, _ value: String) -> some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.bodySans(11, weight: .bold))
                .foregroundStyle(Theme.slate)
            Text(value)
                .font(.mono(11.5))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
    }

    func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.bodySans(12, weight: .semibold))
                .foregroundStyle(Theme.slate)
                .frame(width: 76, alignment: .leading)

            Text(value)
                .font(.mono(12.5))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
        }
    }
}
