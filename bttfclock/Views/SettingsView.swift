import SwiftUI

/// Modal sheet for managing the active rows — reorder, remove, add, or
/// reset to defaults.
///
/// On iOS, the embedded `List` is forced into `.active` edit mode so the
/// drag handles and delete affordances are always visible (the whole
/// sheet's purpose is editing). `EditMode` doesn't exist on macOS, so
/// that behaviour is gated by the `.forceEditModeActive()` shim below;
/// the native Mac `List` exposes drag-to-reorder and contextual delete
/// without it.
///
/// Keep the `List` on the default system background — earlier attempts
/// to override it with `.scrollContentBackground(.hidden)` + a custom
/// colour caused the list to collapse to ~80pt wide on iOS 17/18.
struct SettingsView: View {
    @EnvironmentObject var store: CityStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            listContent
                .forceEditModeActive()
                .navigationTitle("Time Circuits")
                .inlineNavigationTitle()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        #if os(macOS)
        // macOS sheets default to the content's minimum size — without
        // this the List collapses to a few rows tall. Sized for
        // comfortable use but still resizable via the sheet's drag
        // handle if needed.
        .frame(minWidth: 420, idealWidth: 460, minHeight: 480, idealHeight: 540)
        #endif
    }

    private var listContent: some View {
        List {
            Section {
                ForEach(store.selected) { city in
                    selectedRow(for: city)
                }
                .onDelete { store.remove(at: $0) }
                .onMove { store.move(from: $0, to: $1) }
            } header: {
                HStack {
                    Text("Active rows")
                    Spacer()
                    Text("\(store.selected.count) of \(CityStore.maxCities)")
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Top row is red (Destination), middle is green (Present), bottom is amber (Last Departed). Drag the handles to reorder, swipe left to remove.")
            }

            if store.selected.count < CityStore.maxCities {
                Section {
                    NavigationLink {
                        AddCityView()
                            .environmentObject(store)
                    } label: {
                        Label("Add city", systemImage: "plus.circle.fill")
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    store.resetToDefaults()
                } label: {
                    Label("Reset to New York, London, Hong Kong",
                          systemImage: "arrow.counterclockwise")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Row showing the colour swatch for the slot the city currently
    /// occupies, plus its display name and IANA identifier. Colour
    /// updates live if the row is dragged to a new slot.
    @ViewBuilder
    private func selectedRow(for city: CityTimezone) -> some View {
        let idx = store.selected.firstIndex(where: { $0.id == city.id }) ?? 0
        HStack(spacing: 12) {
            Circle()
                .fill(RowColor.forIndex(idx).lit)
                .frame(width: 14, height: 14)
                .shadow(color: RowColor.forIndex(idx).bloom, radius: 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(city.displayName)
                    .font(.system(.body, weight: .semibold))
                Text(city.timezoneIdentifier)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Searchable picker for cities not already in the active list.
/// Selecting a city adds it via the store (which no-ops if max reached
/// or duplicate) and dismisses.
struct AddCityView: View {
    @EnvironmentObject var store: CityStore
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    /// Filter over both the display name and IANA identifier so
    /// searching "tokyo" and "asia/tokyo" both work.
    var filtered: [CityTimezone] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if trimmed.isEmpty { return store.availableToAdd }
        return store.availableToAdd.filter {
            $0.displayName.lowercased().contains(trimmed)
                || $0.timezoneIdentifier.lowercased().contains(trimmed)
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { city in
                Button {
                    store.add(city)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(city.displayName)
                                .font(.system(.body, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(city.timezoneIdentifier)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "plus")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .platformSearchable(text: $searchText)
        .navigationTitle("Add city")
        .inlineNavigationTitle()
    }
}

// MARK: - Platform shims
//
// Thin wrappers so the view bodies stay free of `#if` scaffolding. Each
// one applies the iOS-only modifier when compiling for iOS and returns
// `self` unchanged on macOS.

private extension View {
    /// Sets `.navigationBarTitleDisplayMode(.inline)` on iOS; no-op on
    /// macOS (where `NavigationStack` renders the title in the window
    /// titlebar automatically, so there's no "large vs inline" choice).
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Attaches a keyboard-drawer `.searchable` placement on iOS; on
    /// macOS uses the default toolbar placement SwiftUI chooses (which
    /// renders a proper titlebar search field).
    @ViewBuilder
    func platformSearchable(text: Binding<String>) -> some View {
        #if os(iOS)
        self.searchable(text: text, placement: .navigationBarDrawer(displayMode: .always))
        #else
        self.searchable(text: text)
        #endif
    }

    /// Forces the List into `.active` edit mode on iOS so drag handles
    /// and delete badges show without a separate Edit button. No-op on
    /// macOS — the native Mac List supports reorder/delete without an
    /// edit-mode environment.
    @ViewBuilder
    func forceEditModeActive() -> some View {
        #if os(iOS)
        self.modifier(ForceEditModeActiveModifier())
        #else
        self
        #endif
    }
}

#if os(iOS)
private struct ForceEditModeActiveModifier: ViewModifier {
    @State private var editMode: EditMode = .active
    func body(content: Content) -> some View {
        content.environment(\.editMode, $editMode)
    }
}
#endif
