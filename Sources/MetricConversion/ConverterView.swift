import AppKit
import SwiftUI

struct ConverterView: View {
    let launchAtLoginController: LaunchAtLoginController

    @AppStorage("conversionDirection") private var selectedDirection = ConversionDirection.imperialToMetric.rawValue
    @AppStorage("metricUnit") private var selectedMetricUnit = LengthUnit.millimetres.rawValue
    @AppStorage("imperialUnit") private var selectedImperialUnit = LengthUnit.inches.rawValue
    @AppStorage("decimalPrecision") private var decimalPrecision = 2
    @FocusState private var inputIsFocused: Bool
    @State private var input = ""
    @State private var showingSettings = false
    @StateObject private var historyStore = ConversionHistoryStore()

    private var direction: ConversionDirection {
        ConversionDirection(rawValue: selectedDirection) ?? .imperialToMetric
    }

    private var metricUnit: LengthUnit {
        LengthUnit(rawValue: selectedMetricUnit) ?? .millimetres
    }

    private var imperialUnit: LengthUnit {
        LengthUnit(rawValue: selectedImperialUnit) ?? .inches
    }

    private var sourceUnit: LengthUnit {
        direction.isMetricToImperial ? metricUnit : imperialUnit
    }

    private var destinationUnit: LengthUnit {
        direction.isMetricToImperial ? imperialUnit : metricUnit
    }

    private var inputValue: Double? {
        UnitConverter.parseInput(input)
    }

    private var resultText: String? {
        guard let inputValue else {
            return nil
        }

        let outputValue = UnitConverter.convert(inputValue, from: sourceUnit, to: destinationUnit)
        return "\(UnitConverter.formatted(inputValue, decimalPlaces: decimalPrecision)) \(sourceUnit.symbol) = \(UnitConverter.formatted(outputValue, decimalPlaces: decimalPrecision)) \(destinationUnit.symbol)"
    }

    private var outputText: String? {
        guard let inputValue else {
            return nil
        }

        let outputValue = UnitConverter.convert(inputValue, from: sourceUnit, to: destinationUnit)
        return "\(UnitConverter.formatted(outputValue, decimalPlaces: decimalPrecision)) \(destinationUnit.symbol)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Conversion direction", selection: $selectedDirection) {
                ForEach(ConversionDirection.allCases) { direction in
                    Text(direction.isMetricToImperial
                        ? "\(metricUnit.displayName) to \(imperialUnit.displayName)"
                        : "\(imperialUnit.displayName) to \(metricUnit.displayName)")
                        .tag(direction.rawValue)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Value", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .focused($inputIsFocused)
                    .onSubmit(recordCurrentConversion)

                if let resultText, let outputText {
                    HStack {
                        Text(resultText)
                            .font(.body.monospacedDigit())
                            .textSelection(.enabled)

                        Spacer()

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(outputText, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .help("Copy result")
                        .accessibilityLabel("Copy result")
                    }
                } else {
                    Text("Enter a valid number")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack {
                Text("Recent")
                    .font(.headline)

                Spacer()

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Conversion settings")
                .accessibilityLabel("Conversion settings")
                .popover(isPresented: $showingSettings, arrowEdge: .top) {
                    ConverterSettingsView(
                        metricUnit: $selectedMetricUnit,
                        imperialUnit: $selectedImperialUnit,
                        decimalPrecision: $decimalPrecision,
                        launchAtLoginController: launchAtLoginController
                    )
                }

                if !historyStore.entries.isEmpty {
                    Button(action: historyStore.clear) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Clear conversion history")
                    .accessibilityLabel("Clear conversion history")
                }
            }

            if historyStore.entries.isEmpty {
                Text("No conversions yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 96, alignment: .center)
            } else {
                List(historyStore.entries) { entry in
                    Text(entry.displayValue(decimalPlaces: decimalPrecision))
                        .font(.body.monospacedDigit())
                }
                .listStyle(.plain)
                .frame(height: 180)
            }

            if launchAtLoginController.state == .requiresApproval {
                Text("Approve this login item in System Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 340)
        .task {
            if ConversionDirection(rawValue: selectedDirection) == nil {
                selectedDirection = ConversionDirection.imperialToMetric.rawValue
            }
            inputIsFocused = true
        }
    }

    private func recordCurrentConversion() {
        guard let inputValue else {
            return
        }

        historyStore.record(
            inputValue: inputValue,
            sourceUnit: sourceUnit,
            destinationUnit: destinationUnit
        )
    }
}

private struct ConverterSettingsView: View {
    @Binding var metricUnit: String
    @Binding var imperialUnit: String
    @Binding var decimalPrecision: Int
    @ObservedObject var launchAtLoginController: LaunchAtLoginController
    @State private var launchAtLoginEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Conversion Settings")
                .font(.headline)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Metric")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Metric unit", selection: $metricUnit) {
                        ForEach(LengthUnit.metricUnits) { unit in
                            Text(unit.displayName).tag(unit.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Imperial")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Imperial unit", selection: $imperialUnit) {
                        ForEach(LengthUnit.imperialUnits) { unit in
                            Text(unit.displayName).tag(unit.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
            }

            Divider()

            Stepper(value: $decimalPrecision, in: 0...4) {
                Text("Decimal places: \(decimalPrecision)")
            }

            Divider()

            Toggle("Launch at login", isOn: $launchAtLoginEnabled)
                .onChange(of: launchAtLoginEnabled) { isEnabled in
                    launchAtLoginController.setEnabled(isEnabled)
                }

            if launchAtLoginController.state == .requiresApproval {
                Text("Approve this login item in System Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if launchAtLoginController.state == .unavailable {
                Text("Launch-at-login could not be updated.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 320)
        .onAppear {
            launchAtLoginEnabled = launchAtLoginController.state == .enabled || launchAtLoginController.state == .requiresApproval
        }
    }
}