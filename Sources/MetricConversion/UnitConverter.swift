import Foundation

enum ConversionDirection: String, CaseIterable, Codable, Identifiable {
    case metricToImperial
    case imperialToMetric

    var id: String { rawValue }

    var isMetricToImperial: Bool {
        self == .metricToImperial
    }
}

enum LengthUnit: String, CaseIterable, Codable, Identifiable {
    case millimetres
    case centimetres
    case metres
    case inches
    case feet
    case yards

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .millimetres:
            "Millimetres"
        case .centimetres:
            "Centimetres"
        case .metres:
            "Metres"
        case .inches:
            "Inches"
        case .feet:
            "Feet"
        case .yards:
            "Yards"
        }
    }

    var symbol: String {
        switch self {
        case .millimetres:
            "mm"
        case .centimetres:
            "cm"
        case .metres:
            "m"
        case .inches:
            "in"
        case .feet:
            "ft"
        case .yards:
            "yd"
        }
    }

    var millimetresPerUnit: Double {
        switch self {
        case .millimetres:
            1
        case .centimetres:
            10
        case .metres:
            1_000
        case .inches:
            25.4
        case .feet:
            304.8
        case .yards:
            914.4
        }
    }

    static let metricUnits: [LengthUnit] = [.millimetres, .centimetres, .metres]
    static let imperialUnits: [LengthUnit] = [.inches, .feet, .yards]
}

enum UnitConverter {
    static let millimetresPerInch = 25.4

    static func convert(_ value: Double, from sourceUnit: LengthUnit, to destinationUnit: LengthUnit) -> Double {
        value * sourceUnit.millimetresPerUnit / destinationUnit.millimetresPerUnit
    }

    static func parseInput(_ text: String) -> Double? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmedText), value.isFinite else {
            return nil
        }

        return value
    }

    static func formatted(_ value: Double, decimalPlaces: Int = 2) -> String {
        guard value.isFinite else {
            return ""
        }

        let precision = min(max(decimalPlaces, 0), 4)
        return String(
            format: "%.\(precision)f",
            locale: Locale(identifier: "en_US_POSIX"),
            value
        )
    }
}