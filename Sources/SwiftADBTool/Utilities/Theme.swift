import SwiftUI

enum Theme {
    static let ink = Color(red: 0.08, green: 0.12, blue: 0.18)
    static let slate = Color(red: 0.29, green: 0.37, blue: 0.48)
    static let paper = Color(red: 0.97, green: 0.98, blue: 0.99)
    static let mist = Color(red: 0.90, green: 0.94, blue: 0.97)

    static let ocean = Color(red: 0.11, green: 0.47, blue: 0.71)
    static let mint = Color(red: 0.11, green: 0.66, blue: 0.58)
    static let amber = Color(red: 0.88, green: 0.57, blue: 0.18)
    static let coral = Color(red: 0.83, green: 0.34, blue: 0.27)

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.97, blue: 1.0),
            Color(red: 0.88, green: 0.93, blue: 0.98),
            Color(red: 0.94, green: 0.97, blue: 0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Font {
    static func display(_ size: CGFloat, weight: Weight = .semibold) -> Font {
        .custom("Avenir Next", size: size).weight(weight)
    }

    static func bodySans(_ size: CGFloat, weight: Weight = .regular) -> Font {
        .custom("Avenir Next", size: size).weight(weight)
    }

    static func mono(_ size: CGFloat) -> Font {
        .custom("Menlo", size: size)
    }
}

extension View {
    func appCard(fill: Color = .white, radius: CGFloat = 18) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill.opacity(0.78))
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(Color.white.opacity(0.75), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 8)
            )
    }
}
