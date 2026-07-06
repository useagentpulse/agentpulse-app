import SwiftUI

struct PreferencesView: View {
    @Bindable var viewModel: SessionViewModel

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $viewModel.settings.launchAtLogin)
            }

            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $viewModel.settings.notificationsEnabled)
                Toggle("Play Sound", isOn: $viewModel.settings.playSoundOnNotification)
                    .disabled(!viewModel.settings.notificationsEnabled)
            }

            Section("Sessions") {
                Toggle("Auto-focus Terminal on Click", isOn: $viewModel.settings.autoFocusTerminal)
                HStack {
                    Text("Retain completed sessions for")
                    Spacer()
                    Picker("", selection: $viewModel.settings.sessionRetentionMinutes) {
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                        Text("1 hour").tag(60)
                        Text("2 hours").tag(120)
                    }
                    .labelsHidden()
                    .frame(width: 100)
                }
            }

            Section("Appearance") {
                Picker("Theme", selection: $viewModel.settings.theme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue.capitalized).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 360)
        .onChange(of: viewModel.settings) { _, _ in
            viewModel.saveSettings()
        }
    }
}
