//
//  PressScaleButtonStyle.swift
//  QRCodeMaster
//

import SwiftUI

/// A button style that slightly shrinks the button on press, giving a
/// satisfying tactile-feel bounce when the finger lifts.
struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(
                configuration.isPressed
                    ? .spring(response: 0.2, dampingFraction: 0.6)
                    : .spring(response: 0.3, dampingFraction: 0.5),
                value: configuration.isPressed
            )
    }
}
