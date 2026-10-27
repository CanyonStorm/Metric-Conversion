import Combine
import Foundation

struct ConversionRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let inputValue: Double
    let outputValue: Double
    let sourceUnit: LengthUnit
    let destinationUnit: LengthUnit
    let recordedAt: Date

    init(
        inputValue: Double,
        outputValue: Double,
        sourceUnit: LengthUnit,
        destinationUnit: LengthUnit,
        recordedAt: Date = .now
    ) {
        self.id = UUID()
        self.inputValue = inputValue
        self.outputValue = outputValue
        self.sourceUnit = sourceUnit
        self.destinationUnit = destinationUnit
        self.recordedAt = recordedAt
    }

    func displayValue(decimalPlaces: Int) -> String {
        "\(UnitConverter.formatted(inputValue, decimalPlaces: decimalPlaces)) \(sourceUnit.symbol) = \(UnitConverter.formatted(outputValue, decimalPlaces: decimalPlaces)) \(destinationUnit.symbol)"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case inputValue
        case outputValue
        case sourceUnit
        case destinationUnit
        case direction
        case recordedAt
    }

    private enum LegacyDirection: String, Codable {
        case millimetresToInches
        case inchesToMillimetres
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        inputValue = try container.decode(Double.self, forKey: .inputValue)
        outputValue = try container.decode(Double.self, forKey: .outputValue)
        recordedAt = try container.decode(Date.self, forKey: .recordedAt)

        if let sourceUnit = try container.decodeIfPresent(LengthUnit.self, forKey: .sourceUnit),
           let destinationUnit = try container.decodeIfPresent(LengthUnit.self, forKey: .destinationUnit) {
            self.sourceUnit = sourceUnit
            self.destinationUnit = destinationUnit
        } else {
            let legacyDirection = try container.decode(LegacyDirection.self, forKey: .direction)
            sourceUnit = legacyDirection == .millimetresToInches ? .millimetres : .inches
            destinationUnit = legacyDirection == .millimetresToInches ? .inches : .millimetres
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(inputValue, forKey: .inputValue)
        try container.encode(outputValue, forKey: .outputValue)
        try container.encode(sourceUnit, forKey: .sourceUnit)
        try container.encode(destinationUnit, forKey: .destinationUnit)
        try container.encode(recordedAt, forKey: .recordedAt)
    }
}

@MainActor
final class ConversionHistoryStore: ObservableObject {
    @Published private(set) var entries: [ConversionRecord]

    private let defaults: UserDefaults
    private let storageKey: String
    private let maximumEntries: Int

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "conversionHistory",
        maximumEntries: Int = 25
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.maximumEntries = maximumEntries

        if let data = defaults.data(forKey: storageKey),
           let storedEntries = try? JSONDecoder().decode([ConversionRecord].self, from: data) {
            entries = Array(storedEntries.prefix(maximumEntries))
        } else {
            entries = []
        }
    }

    func record(inputValue: Double, sourceUnit: LengthUnit, destinationUnit: LengthUnit) {
        guard inputValue.isFinite else {
            return
        }

        let outputValue = UnitConverter.convert(inputValue, from: sourceUnit, to: destinationUnit)
        guard outputValue.isFinite else {
            return
        }

        entries.insert(
            ConversionRecord(
                inputValue: inputValue,
                outputValue: outputValue,
                sourceUnit: sourceUnit,
                destinationUnit: destinationUnit
            ),
            at: 0
        )
        entries = Array(entries.prefix(maximumEntries))
        persist()
    }

    func clear() {
        entries = []
        defaults.removeObject(forKey: storageKey)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }
}