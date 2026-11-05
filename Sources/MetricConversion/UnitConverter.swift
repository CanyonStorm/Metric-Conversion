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
        if let value = Double(trimmedText), value.isFinite {
            return value
        }

        if let fraction = fractionValue(trimmedText) {
            return fraction
        }

        let components = trimmedText.split(whereSeparator: \.isWhitespace)
        guard components.count == 2,
              let whole = Int(components[0]),
              let fraction = fractionValue(String(components[1])),
              fraction >= 0 else {
            return nil
        }

        let sign = components[0].first == "-" ? -1.0 : 1.0
        return sign * (abs(Double(whole)) + fraction)
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

    private static func fractionValue(_ text: String) -> Double? {
        let components = text.split(separator: "/", omittingEmptySubsequences: false)
        guard components.count == 2,
              let numerator = Int(components[0].trimmingCharacters(in: .whitespaces)),
              let denominator = Int(components[1].trimmingCharacters(in: .whitespaces)),
              denominator != 0 else {
            return nil
        }

        let value = Double(numerator) / Double(denominator)
        return value.isFinite ? value : nil
    }
}