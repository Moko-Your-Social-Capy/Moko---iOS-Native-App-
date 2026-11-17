//
//  MokoButtonStyle.swift
//  Moko
//
//  Button styles following MokoScreenTheme design system.
//  Supports primary, secondary, and icon button variants.
//

import SwiftUI

/// Button styles for the Moko app following the design system.
enum MokoButtonStyle {
    /// Primary button - filled with brand color
    case primary
    
    /// Secondary button - outlined with brand color
    case secondary
    
    /// Icon button - circular with icon only
    case icon
    
    /// Small primary button
    case smallPrimary
    
    /// Small secondary button
    case smallSecondary
}

/// Custom button style implementation for Moko design system.
struct MokoStyledButton: ButtonStyle {
    let style: MokoButtonStyle
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    @Environment(\.isEnabled) private var isEnabled
    
    private var effectiveIsDisabled: Bool {
        isDisabled || !isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(foregroundColor)
                    .scaleEffect(0.8)
            }
            
            configuration.label
                .font(font)
                .foregroundStyle(foregroundColor)
                .opacity(isLoading ? 0 : 1)
        }
        .padding(padding)
        .frame(minWidth: minWidth, minHeight: minHeight)
        .background {
            Group {
                switch style {
                case .primary:
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(strokeColor, lineWidth: strokeWidth)
                        )
                    
                case .secondary, .smallSecondary:
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(strokeColor, lineWidth: strokeWidth)
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(backgroundColor)
                        )
                    
                case .icon:
                    Circle()
                        .fill(backgroundColor)
                        .overlay(
                            Circle()
                                .strokeBorder(strokeColor, lineWidth: strokeWidth)
                        )
                case .smallPrimary:
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(strokeColor, lineWidth: strokeWidth)
                        )
                }
            }
        }
        .scaleEffect(configuration.isPressed ? 0.98 : 1)
        .opacity(effectiveIsDisabled ? 0.5 : 1)
        .animation(.snappy(duration: 0.15), value: configuration.isPressed)
        .animation(.snappy(duration: 0.2), value: isLoading)
        .contentShape(Rectangle())
    }
    
    // MARK: - Style Properties
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .smallPrimary:
            return MokoScreenTheme.Colors.textOnBrand
        case .secondary, .smallSecondary:
            return effectiveIsDisabled ? MokoScreenTheme.Colors.textMuted : MokoScreenTheme.Colors.dataVioletDeep
        case .icon:
            return effectiveIsDisabled ? MokoScreenTheme.Colors.textMuted : MokoScreenTheme.Colors.dataVioletDeep
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary, .smallPrimary:
            return effectiveIsDisabled ? MokoScreenTheme.Colors.buttonDisabled : MokoScreenTheme.Colors.dataVioletDeep
        case .secondary, .smallSecondary, .icon:
            return .clear
        }
    }
    
    private var strokeColor: Color {
        switch style {
        case .primary, .smallPrimary:
            return .clear
        case .secondary, .smallSecondary:
            return effectiveIsDisabled ? MokoScreenTheme.Colors.borderSubtle : MokoScreenTheme.Colors.dataVioletDeep
        case .icon:
            return effectiveIsDisabled ? MokoScreenTheme.Colors.borderSubtle : MokoScreenTheme.Colors.dataVioletDeep
        }
    }
    
    private var strokeWidth: CGFloat {
        switch style {
        case .primary, .smallPrimary:
            return 0
        case .secondary, .smallSecondary, .icon:
            return 1.5
        }
    }
    
    private var font: Font {
        let textStyle: MokoScreenTheme.TextStyle = switch style {
        case .primary, .secondary, .icon: MokoScreenTheme.Typeface.button
        case .smallPrimary, .smallSecondary: MokoScreenTheme.Typeface.caption
        }
        return Font.system(size: textStyle.size, weight: textStyle.weight)
    }
    
    private var padding: EdgeInsets {
        switch style {
        case .primary, .secondary:
            return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        case .smallPrimary, .smallSecondary:
            return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .icon:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        }
    }
    
    private var minWidth: CGFloat? {
        switch style {
        case .primary, .secondary:
            return 120
        case .smallPrimary, .smallSecondary, .icon:
            return nil
        }
    }
    
    private var minHeight: CGFloat {
        switch style {
        case .primary, .secondary, .smallPrimary, .smallSecondary:
            return 44
        case .icon:
            return 44
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .primary, .secondary, .smallPrimary, .smallSecondary:
            return 12
        case .icon:
            return 22 // Half of minHeight for circle
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a Moko button style to this button.
    func mokoButtonStyle(
        _ style: MokoButtonStyle,
        isLoading: Bool = false,
        isDisabled: Bool = false
    ) -> some View {
        buttonStyle(MokoStyledButton(
            style: style,
            isLoading: isLoading,
            isDisabled: isDisabled
        ))
    }
}

// MARK: - Convenience Button Builders

/// Creates a primary button with Moko styling.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    var body: some View {
        Button(title, action: action)
            .mokoButtonStyle(.primary, isLoading: isLoading, isDisabled: isDisabled)
    }
}

/// Creates a secondary button with Moko styling.
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    var body: some View {
        Button(title, action: action)
            .mokoButtonStyle(.secondary, isLoading: isLoading, isDisabled: isDisabled)
    }
}

/// Creates an icon button with Moko styling.
struct IconButton: View {
    let systemName: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 44, height: 44)
        }
        .mokoButtonStyle(.icon, isLoading: isLoading, isDisabled: isDisabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Primary buttons
        PrimaryButton(title: "Continue", action: {})
        
        PrimaryButton(title: "Loading...", action: {}, isLoading: true)
        
        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
        
        // Secondary buttons
        SecondaryButton(title: "Back", action: {})
        
        SecondaryButton(title: "Loading...", action: {}, isLoading: true)
        
        SecondaryButton(title: "Disabled", action: {}, isDisabled: true)
        
        // Icon button
        HStack {
            IconButton(systemName: "chevron.left", action: {})
            IconButton(systemName: "chevron.right", action: {})
            IconButton(systemName: "checkmark", action: {}, isLoading: true)
            IconButton(systemName: "xmark", action: {}, isDisabled: true)
        }
        
        // Small buttons
        HStack {
            Button("Small", action: {})
                .mokoButtonStyle(.smallPrimary)
            
            Button("Small", action: {})
                .mokoButtonStyle(.smallSecondary)
        }
    }
    .padding()
}