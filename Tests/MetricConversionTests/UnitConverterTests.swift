import Foundation
import Testing
@testable import MetricConversion

struct UnitConverterTests {
    @Test func convertsMillimetresToInches() {
        let result = UnitConverter.convert(90, from: .millimetres, to: .inches)

        #expect(abs(result - 3.5433070866) < 0.0000000001)
    }

    @Test func convertsInchesToMillimetres() {
        let result = UnitConverter.convert(21, from: .inches, to: .millimetres)

        #expect(abs(result - 533.4) < 0.0000000001)
    }

    @Test func formatsValuesToExactlyTwoDecimalPlaces() {
        #expect(UnitConverter.formatted(533.4) == "533.40")
        #expect(UnitConverter.formatted(3.5433070866) == "3.54")
    }

    @Test func convertsBetweenAdditionalLengthUnitsAndFormatsCustomPrecision() {
        let result = UnitConverter.convert(2, from: .metres, to: .yards)
        #expect(abs(result - 2.187226596675415) < 0.000000000000001)
        #expect(UnitConverter.formatted(3.5433070866, decimalPlaces: 4) == "3.5433")
    }

    @Test func rejectsEmptyOrNonFiniteInput() {
        #expect(UnitConverter.parseInput("") == nil)
        #expect(UnitConverter.parseInput("infinity") == nil)
        #expect(UnitConverter.parseInput(" 34 ") == 34)
    }

    @Test @MainActor func keepsNewestHistoryEntriesAndRestoresThem() {
        let suiteName = "MetricConversionTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let history = ConversionHistoryStore(defaults: defaults, maximumEntries: 2)
        history.record(inputValue: 21, sourceUnit: .inches, destinationUnit: .millimetres)
        history.record(inputValue: 90, sourceUnit: .millimetres, destinationUnit: .inches)
        history.record(inputValue: 34, sourceUnit: .millimetres, destinationUnit: .inches)

        #expect(history.entries.map(\.inputValue) == [34, 90])

        let restoredHistory = ConversionHistoryStore(defaults: defaults, maximumEntries: 2)
        #expect(restoredHistory.entries.map(\.inputValue) == [34, 90])
    }
}