import Foundation
import Combine

/// The user's selected cities, persisted to `UserDefaults`.
///
/// Semantics:
/// - Hard cap of 3 rows (`maxCities`). The whole point of the Time
///   Circuits layout is the three-row display; a fourth row would break
///   the visual identity, so every mutation is clamped.
/// - First launch seeds `defaultSelection` (New York · London · Hong Kong).
/// - Row colour is derived from slot index in `TimeCircuitRowView`, not
///   stored here — reordering therefore changes a city's display colour.
@MainActor
final class CityStore: ObservableObject {
    /// Storage key, versioned so we can migrate in the future without
    /// colliding with any older format.
    static let storageKey = "bttfclock.selectedCityIds.v1"

    /// Maximum number of rows; matches the three-colour display design.
    static let maxCities = 3

    @Published private(set) var selected: [CityTimezone]

    private let userDefaults: UserDefaults

    /// - Parameter userDefaults: override for tests. Production uses
    ///   `.standard`; tests pass an isolated suite so they don't stomp on
    ///   each other or the running app's state.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let stored = Self.loadFromDefaults(userDefaults) {
            self.selected = stored
        } else {
            self.selected = CityCatalog.defaultSelection
        }
    }

    /// Decodes the persisted city list. Returns nil (triggering the
    /// default selection) when the defaults entry is absent, empty, or
    /// fails to resolve against the current catalog.
    static func loadFromDefaults(_ defaults: UserDefaults) -> [CityTimezone]? {
        guard let ids = defaults.stringArray(forKey: storageKey), !ids.isEmpty else {
            return nil
        }
        let cities = ids.compactMap { CityCatalog.city(withId: $0) }
        return cities.isEmpty ? nil : Array(cities.prefix(maxCities))
    }

    /// Wholesale replace. Used by the `-cities` launch arg and by tests;
    /// always truncated to `maxCities`.
    func replace(with cities: [CityTimezone]) {
        selected = Array(cities.prefix(Self.maxCities))
        persist()
    }

    /// Appends a city if room and not already present. No-op otherwise —
    /// intentionally silent so the settings UI doesn't need to handle
    /// error states.
    func add(_ city: CityTimezone) {
        guard selected.count < Self.maxCities else { return }
        guard !selected.contains(where: { $0.id == city.id }) else { return }
        selected.append(city)
        persist()
    }

    func remove(at offsets: IndexSet) {
        selected.remove(atOffsets: offsets)
        persist()
    }

    func move(from source: IndexSet, to destination: Int) {
        selected.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    func resetToDefaults() {
        selected = CityCatalog.defaultSelection
        persist()
    }

    /// Cities in the catalog that aren't already selected — used to
    /// populate `AddCityView`.
    var availableToAdd: [CityTimezone] {
        let chosen = Set(selected.map { $0.id })
        return CityCatalog.all.filter { !chosen.contains($0.id) }
    }

    private func persist() {
        let ids = selected.map { $0.id }
        userDefaults.set(ids, forKey: Self.storageKey)
    }
}
