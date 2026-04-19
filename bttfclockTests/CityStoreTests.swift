import Foundation
import Testing
@testable import bttfclock

@MainActor
struct CityStoreTests {
    private func makeDefaults(suiteName: String = UUID().uuidString) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func newStore_usesDefaultThreeCities() {
        let store = CityStore(userDefaults: makeDefaults())
        #expect(store.selected.count == 3)
        #expect(store.selected[0].id == "new_york")
        #expect(store.selected[1].id == "london")
        #expect(store.selected[2].id == "hong_kong")
    }

    @Test func addingCity_persistsAndAppends() {
        let defaults = makeDefaults()
        let store = CityStore(userDefaults: defaults)
        store.replace(with: [CityCatalog.city(withId: "london")!])
        store.add(CityCatalog.city(withId: "tokyo")!)
        #expect(store.selected.count == 2)
        #expect(store.selected[1].id == "tokyo")

        let reloaded = CityStore(userDefaults: defaults)
        #expect(reloaded.selected.map { $0.id } == ["london", "tokyo"])
    }

    @Test func adding_capsAtMaxThree() {
        let store = CityStore(userDefaults: makeDefaults())
        store.add(CityCatalog.city(withId: "tokyo")!)
        #expect(store.selected.count == 3, "should not exceed max of 3")
        #expect(store.selected.contains(where: { $0.id == "tokyo" }) == false)
    }

    @Test func adding_skipsDuplicates() {
        let store = CityStore(userDefaults: makeDefaults())
        store.replace(with: [CityCatalog.city(withId: "london")!])
        store.add(CityCatalog.city(withId: "london")!)
        #expect(store.selected.count == 1)
    }

    @Test func remove_shrinks() {
        let store = CityStore(userDefaults: makeDefaults())
        store.remove(at: IndexSet(integer: 1))
        #expect(store.selected.count == 2)
        #expect(store.selected[0].id == "new_york")
        #expect(store.selected[1].id == "hong_kong")
    }

    @Test func move_reorders() {
        let store = CityStore(userDefaults: makeDefaults())
        store.move(from: IndexSet(integer: 2), to: 0)
        #expect(store.selected[0].id == "hong_kong")
        #expect(store.selected[1].id == "new_york")
        #expect(store.selected[2].id == "london")
    }

    @Test func resetToDefaults_restoresOriginal() {
        let store = CityStore(userDefaults: makeDefaults())
        store.replace(with: [CityCatalog.city(withId: "tokyo")!])
        store.resetToDefaults()
        #expect(store.selected.map { $0.id } == ["new_york", "london", "hong_kong"])
    }

    @Test func availableToAdd_excludesSelected() {
        let store = CityStore(userDefaults: makeDefaults())
        let available = store.availableToAdd.map { $0.id }
        #expect(available.contains("new_york") == false)
        #expect(available.contains("tokyo"))
    }

    @Test func replace_truncatesToMax() {
        let store = CityStore(userDefaults: makeDefaults())
        store.replace(with: CityCatalog.all)
        #expect(store.selected.count == CityStore.maxCities)
    }
}
