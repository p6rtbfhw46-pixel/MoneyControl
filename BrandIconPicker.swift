import SwiftUI

enum BrandfetchConfiguration {
    static let clientID = "1idy7idNdmFtB8DmWUH"

    static func logoURL(for domain: String?) -> URL? {
        guard let domain else { return nil }
        let trimmedDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDomain.isEmpty else { return nil }

        let candidate = trimmedDomain.contains("://") ? trimmedDomain : "https://\(trimmedDomain)"
        guard let host = URL(string: candidate)?.host, !host.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "cdn.brandfetch.io"
        components.path = "/domain/\(host)"
        components.queryItems = [URLQueryItem(name: "c", value: clientID)]
        return components.url
    }
}

struct BrandSearchResult: Codable, Identifiable, Equatable, Sendable {
    let name: String
    let domain: String
    let icon: String?

    var id: String { domain }
}

enum BrandfetchService {
    static func search(_ text: String) async throws -> [BrandSearchResult] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        var components = URLComponents(string: "https://api.brandfetch.io/v2/search/\(query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query)")
        components?.queryItems = [URLQueryItem(name: "c", value: BrandfetchConfiguration.clientID)]
        guard let url = components?.url else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else { throw URLError(.badServerResponse) }

        return try JSONDecoder().decode([BrandSearchResult].self, from: data)
    }
}

struct TransactionBrandIconView: View {
    let brandIconURL: String?
    let brandDomain: String?
    let fallbackSystemName: String
    let color: Color
    let background: Color
    let size: CGFloat

    private var resolvedIconURL: URL? {
        BrandfetchConfiguration.logoURL(for: brandDomain)
            ?? brandIconURL.flatMap(URL.init(string:))
    }

    var body: some View {
        ZStack {
            Circle().fill(background)

            if let resolvedIconURL {
                AsyncImage(url: resolvedIconURL, transaction: Transaction(animation: nil)) { phase in
                    if case let .success(image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    } else {
                        fallbackIcon
                    }
                }
            } else {
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
    }

    private var fallbackIcon: some View {
        Image(systemName: fallbackSystemName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(color)
    }
}

struct BrandIconPickerSection: View {
    @Binding var selectedBrandName: String?
    @Binding var selectedBrandDomain: String?
    @Binding var selectedBrandIconURL: String?
    let suggestedSearchText: String

    @State private var isExpanded = false
    @State private var searchText = ""
    @State private var results: [BrandSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        Section {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    selectedBrandRow
                    searchControls

                    if isSearching {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("A procurar marcas…")
                        }
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(AppPalette.warning)
                    } else {
                        BrandSearchResultsView(
                            results: results,
                            selectedDomain: selectedBrandDomain,
                            onSelect: select
                        )
                    }
                }
                .padding(.top, 10)
            } label: {
                Label("Personalizar ícone", systemImage: "photo.badge.plus")
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)
            }
            .onChange(of: isExpanded) { _, isNowExpanded in
                guard isNowExpanded,
                      selectedBrandDomain == nil,
                      searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { return }

                let suggestion = suggestedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !suggestion.isEmpty else { return }
                searchText = suggestion
                search()
            }
        }
    }

    private var selectedBrandRow: some View {
        HStack(spacing: 10) {
            if selectedBrandDomain != nil {
                TransactionBrandIconView(
                    brandIconURL: selectedBrandIconURL,
                    brandDomain: selectedBrandDomain,
                    fallbackSystemName: "tag.fill",
                    color: AppPalette.primary,
                    background: AppPalette.primary.opacity(0.12),
                    size: 42
                )
            } else {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(AppPalette.primary)
                    .frame(width: 42, height: 42)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedBrandName ?? "Ícone automático")
                    .font(.subheadline.weight(.semibold))
                Text(selectedBrandDomain == nil ? "Será utilizado o ícone definido pela aplicação." : "Esta marca ficará associada ao registo.")
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
            }

            Spacer(minLength: 0)

            if selectedBrandDomain != nil {
                Button("Automático") {
                    selectedBrandName = nil
                    selectedBrandDomain = nil
                    selectedBrandIconURL = nil
                }
                .font(.caption.weight(.semibold))
            }
        }
    }

    private var searchControls: some View {
        HStack(spacing: 8) {
            TextField("Escreva o nome da marca ou site", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { search() }
                .padding(.trailing, searchText.isEmpty ? 0 : 28)
                .overlay(alignment: .trailing) {
                    if !searchText.isEmpty {
                        Button {
                            searchTask?.cancel()
                            searchText = ""
                            results = []
                            errorMessage = nil
                            isSearching = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppPalette.mutedText)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(AppStrings.text(.clearSearch))
                    }
                }

            Button(action: search) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppPalette.background)
            .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
        }
    }

    private func search() {
        searchTask?.cancel()
        isSearching = true
        errorMessage = nil
        searchTask = Task {
            do {
                let matches = try await BrandfetchService.search(searchText)
                guard !Task.isCancelled else { return }
                results = Array(matches.prefix(8))
                if results.isEmpty {
                    errorMessage = "Não foram encontradas marcas para esta pesquisa."
                }
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = "Não foi possível procurar marcas. Verifique a ligação e tente novamente."
            }
            isSearching = false
        }
    }

    private func select(_ result: BrandSearchResult) {
        selectedBrandName = result.name
        selectedBrandDomain = result.domain
        selectedBrandIconURL = result.icon
    }
}

private struct BrandSearchResultsView: View {
    let results: [BrandSearchResult]
    let selectedDomain: String?
    let onSelect: (BrandSearchResult) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(results) { result in
                Button {
                    onSelect(result)
                } label: {
                    HStack(spacing: 10) {
                        TransactionBrandIconView(
                            brandIconURL: result.icon,
                            brandDomain: result.domain,
                            fallbackSystemName: "building.2.fill",
                            color: AppPalette.background,
                            background: AppPalette.appBackground,
                            size: 40
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.name)
                                .font(.subheadline.weight(.semibold))
                            Text(result.domain)
                                .font(.caption)
                                .foregroundStyle(AppPalette.mutedText)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: selectedDomain == result.domain ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedDomain == result.domain ? AppPalette.primary : AppPalette.mutedText)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
