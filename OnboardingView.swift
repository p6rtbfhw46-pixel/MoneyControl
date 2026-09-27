//
//  OnboardingView.swift
//  MoneyControl
//

import Charts
import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var selectedPage = 0

    private let pages = OnboardingPage.pages

    var body: some View {
        ZStack {
            AppPalette.appBackground.ignoresSafeArea()

            VStack(spacing: 18) {
                TabView(selection: $selectedPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index], pageIndex: index, pageCount: pages.count)
                            .tag(index)
                            .padding(.horizontal, 16)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(index == selectedPage ? AppPalette.background : AppPalette.background.opacity(0.14))
                            .frame(width: index == selectedPage ? 9 : 8, height: index == selectedPage ? 9 : 8)
                    }
                }

                Button {
                    if selectedPage < pages.count - 1 {
                        withAnimation(.snappy) {
                            selectedPage += 1
                        }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(selectedPage == pages.count - 1 ? "Começar" : "Seguinte")
                        .font(.headline)
                        .foregroundStyle(AppPalette.surface)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(AppPalette.background, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
                .padding(.bottom, 14)
            }
        }
    }
}

private struct OnboardingPage: Identifiable {
    enum Illustration {
        case wallet
        case spending
        case rule
        case privacy
        case start
    }

    let id = UUID()
    let titleParts: [(String, Bool)]
    let body: String
    let illustration: Illustration

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            titleParts: [("Tenha ", false), ("controlo", true), ("\nsobre o seu\n", false), ("dinheiro", true)],
            body: "Registe os seus rendimentos e despesas em segundos e descubra para onde vai o seu dinheiro todos os meses.",
            illustration: .wallet
        ),
        OnboardingPage(
            titleParts: [("Saiba\nexatamente\n", false), ("onde gasta", true)],
            body: "A SpendWise organiza automaticamente as suas despesas por categorias para lhe mostrar os seus maiores gastos.",
            illustration: .spending
        ),
        OnboardingPage(
            titleParts: [("Siga a regra\n", false), ("50/30/20", true)],
            body: "Compare os seus gastos com uma distribuição equilibrada e perceba onde pode ajustar.",
            illustration: .rule
        ),
        OnboardingPage(
            titleParts: [("Os seus dados\nsão apenas ", false), ("seus", true)],
            body: "Todos os dados permanecem no seu dispositivo. Nunca são enviados para servidores nem partilhados com terceiros.",
            illustration: .privacy
        ),
        OnboardingPage(
            titleParts: [("Vamos organizar\nas suas ", false), ("finanças", true)],
            body: "Em menos de um minuto terá o seu primeiro orçamento criado.",
            illustration: .start
        )
    ]
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let pageIndex: Int
    let pageCount: Int

    var body: some View {
        VStack(spacing: 0) {
            highlightedTitle
                .padding(.top, 40)
                .font(.system(size: 30, weight: .bold))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 18)

            Text(page.body)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppPalette.background)
                .lineSpacing(4)
                .padding(.horizontal, 24)
                .padding(.top, 22)

            Spacer(minLength: 18)

            illustration
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .padding(.horizontal, 14)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppPalette.background.opacity(0.08), radius: 18, y: 8)
    }

    private var highlightedTitle: Text {
        var title = AttributedString()

        for part in page.titleParts {
            var segment = AttributedString(part.0)
            segment.foregroundColor = part.1 ? AppPalette.positive : AppPalette.background
            title += segment
        }

        return Text(title)
    }

    @ViewBuilder
    private var illustration: some View {
        switch page.illustration {
        case .wallet:
            WalletIllustration()
        case .spending:
            SpendingIllustration()
        case .rule:
            RuleIllustration()
        case .privacy:
            PrivacyIllustration()
        case .start:
            StartIllustration()
        }
    }
}

private struct WalletIllustration: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Circle()
                .fill(AppPalette.mintSurface)
                .frame(width: 230, height: 230)
                .offset(x: 18, y: -8)

            VStack(alignment: .trailing, spacing: 10) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 34, weight: .bold))
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach([52, 86, 124, 166], id: \.self) { height in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(AppPalette.positive)
                            .frame(width: 24, height: CGFloat(height))
                    }
                }
            }
            .foregroundStyle(AppPalette.positive)
            .offset(x: 126, y: -108)

            RoundedRectangle(cornerRadius: 18)
                .fill(AppPalette.background)
                .frame(width: 228, height: 126)
                .overlay(alignment: .trailing) {
                    Circle()
                        .fill(AppPalette.secondary.opacity(0.35))
                        .frame(width: 46, height: 46)
                        .overlay {
                            Circle().fill(AppPalette.surface).frame(width: 14, height: 14)
                        }
                        .padding(.trailing, 14)
                }

            Image(systemName: "coloncurrencysign.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppPalette.accent)
                .offset(x: 184, y: 18)

            Image(systemName: "banknote.fill")
                .font(.system(size: 74))
                .foregroundStyle(AppPalette.positive)
                .rotationEffect(.degrees(-14))
                .offset(x: 26, y: -70)
        }
    }
}

private struct SpendingIllustration: View {
    private let values = [35.0, 25.0, 15.0, 15.0, 10.0]
    private let colors = [AppPalette.background, AppPalette.primary, AppPalette.positive, AppPalette.accent, AppPalette.purple]

    var body: some View {
        VStack(spacing: 18) {
            Chart(values.indices, id: \.self) { index in
                SectorMark(angle: .value("Percentagem", values[index]), innerRadius: .ratio(0.56), angularInset: 1.5)
                    .foregroundStyle(colors[index])
                    .cornerRadius(4)
            }
            .frame(width: 190, height: 190)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                iconLabel("Casa", "house.fill", colors[0], "35%")
                iconLabel("Alimentação", "fork.knife", colors[1], "25%")
                iconLabel("Transportes", "car.fill", colors[2], "15%")
                iconLabel("Lazer", "gift.fill", colors[3], "15%")
            }
        }
    }

    private func iconLabel(_ title: String, _ icon: String, _ color: Color, _ value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(AppPalette.surface)
                .frame(width: 36, height: 36)
                .background(color, in: Circle())
            Text(title)
                .font(.caption2.bold())
            Text(value)
                .font(.caption2)
        }
        .foregroundStyle(AppPalette.background)
    }
}

private struct RuleIllustration: View {
    private let values = [50.0, 30.0, 20.0]
    private let colors = [AppPalette.background, AppPalette.primary, AppPalette.savings]

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Chart(values.indices, id: \.self) { index in
                    SectorMark(angle: .value("Percentagem", values[index]), innerRadius: .ratio(0.58), angularInset: 1.5)
                        .foregroundStyle(colors[index])
                        .cornerRadius(4)
                }
                Text("50/30/20")
                    .font(.title2.bold())
                    .foregroundStyle(AppPalette.background)
            }
            .frame(width: 220, height: 220)

            VStack(alignment: .leading, spacing: 10) {
                legend("50% Necessidades (Essenciais)", AppPalette.background)
                legend("30% Desejos (Estilo de Vida)", AppPalette.primary)
                legend("20% Poupança", AppPalette.savings)
            }
        }
    }

    private func legend(_ text: String, _ color: Color) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 12, height: 12)
            Text(text).font(.caption).foregroundStyle(AppPalette.background)
        }
    }
}

private struct PrivacyIllustration: View {
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 34)
                    .fill(AppPalette.background)
                    .frame(width: 148, height: 236)
                RoundedRectangle(cornerRadius: 26)
                    .fill(AppPalette.mintSurface)
                    .frame(width: 124, height: 198)
                Image(systemName: "lock.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppPalette.surface)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 86))
                    .foregroundStyle(AppPalette.positive)
                    .offset(x: 78, y: 72)
            }

            Label("100% Privado", systemImage: "lock.fill")
                .font(.headline)
                .foregroundStyle(AppPalette.positive)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(AppPalette.mintSurface.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct StartIllustration: View {
    var body: some View {
        VStack(spacing: 24) {
            Image("SpendWiseIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 126, height: 126)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: AppPalette.background.opacity(0.22), radius: 16, y: 8)

            HStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundStyle(AppPalette.positive)
                Text("Pronto para começar")
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(AppPalette.mintSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

#Preview {
    OnboardingView {}
}
