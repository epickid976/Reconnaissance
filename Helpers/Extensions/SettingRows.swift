//
//  SettingRows.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/15/24.
//
import SwiftUI

struct PreferenceRow: View {
    var icon: String
    var title: String
    var description: String? = nil
    var foregroundColor: Color = .blue
    var iconColor: Color = .blue // New parameter
    var toggleValue: Binding<Bool>?
    var action: (() -> Void)?

    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack {
                // Icon
                Image(systemName: icon)
                    .imageScale(.large)
                    .foregroundColor(iconColor) // Use iconColor
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(iconColor.opacity(0.2)) // Use iconColor
                    )

                // Title and Optional Description
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    if let description = description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Toggle or Chevron
                if let toggleValue = toggleValue {
                    Toggle("", isOn: toggleValue)
                        .toggleStyle(SwitchToggleStyle(tint: foregroundColor))
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .contentShape(Rectangle()) // Makes the entire row tappable
        }
        .buttonStyle(PlainButtonStyle()) // Prevents the button from having a highlighted effect
        #if os(iOS)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        #elseif os(watchOS)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThickMaterial)
        )
        #endif
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct GroupedPreferenceRow: View {
    struct Preference {
        var icon: String
        var title: String
        var iconColor: Color = .blue // New parameter with default
        var toggleValue: Binding<Bool>?
        var action: (() -> Void)?
    }

    var preferences: [Preference]
    var foregroundColor: Color = .blue

    var body: some View {
        VStack(spacing: 0) {
            ForEach(preferences.indices, id: \.self) { index in
                let preference = preferences[index]

                Button(action: {
                    preference.action?()
                }) {
                    HStack {
                        // Icon
                        Image(systemName: preference.icon)
                            .imageScale(.large)
                            .foregroundColor(preference.iconColor) // Use iconColor from preference
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(preference.iconColor.opacity(0.2)) // Use iconColor from preference
                            )

                        // Title
                        Text(preference.title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        // Toggle or Chevron
                        if let toggleValue = preference.toggleValue {
                            Toggle("", isOn: toggleValue)
                                .toggleStyle(SwitchToggleStyle(tint: foregroundColor))
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12) // Add vertical padding for better spacing
                    .contentShape(Rectangle()) // Makes the entire row tappable
                }
                .buttonStyle(PlainButtonStyle()) // Prevents button highlight effects

                // Divider
                if index < preferences.count - 1 {
                    Divider()
                        .padding(.leading, 12) // Align with text and icon
                        .padding(.trailing, 12) // Optional trailing padding for symmetry
                }
            }
        }
        #if os(iOS)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        #elseif os(watchOS)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThickMaterial)
        )
        #endif
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
