import Foundation
import SwiftUI
import UIKit
import Vision
import VisionKit

struct ReceiptScanResult {
    var title: String
    var amount: Double?
    var date: Date?
    var category: ExpenseCategory
    var expenseName: String
    var recognizedText: String
}

struct ReceiptScannerView: UIViewControllerRepresentable {
    let onComplete: (ReceiptScanResult) -> Void
    let onCancel: () -> Void
    let onFailure: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete, onCancel: onCancel, onFailure: onFailure)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onComplete: (ReceiptScanResult) -> Void
        let onCancel: () -> Void
        let onFailure: (String) -> Void

        init(
            onComplete: @escaping (ReceiptScanResult) -> Void,
            onCancel: @escaping () -> Void,
            onFailure: @escaping (String) -> Void
        ) {
            self.onComplete = onComplete
            self.onCancel = onCancel
            self.onFailure = onFailure
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true)
            Task {
                let lines = Self.recognizeText(in: scan)
                let result = ReceiptParser.parse(lines: lines)
                self.onComplete(result)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
            onFailure(error.localizedDescription)
        }

        private static func recognizeText(in scan: VNDocumentCameraScan) -> [String] {
            var lines: [String] = []

            for pageIndex in 0..<scan.pageCount {
                guard let cgImage = scan.imageOfPage(at: pageIndex).cgImage else { continue }

                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["pt-PT", "en-US"]

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    let recognizedLines = request.results?.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    } ?? []
                    lines.append(contentsOf: recognizedLines)
                } catch {
                    continue
                }
            }

            return lines
        }
    }
}

enum ReceiptParser {
    static func parse(lines: [String]) -> ReceiptScanResult {
        let normalizedLines = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let title = merchantName(from: normalizedLines)
        let amount = totalAmount(from: normalizedLines)
        let date = receiptDate(from: normalizedLines)
        let suggestion = categorySuggestion(for: title, lines: normalizedLines)

        return ReceiptScanResult(
            title: title.isEmpty ? "Fatura" : title,
            amount: amount,
            date: date,
            category: suggestion.category,
            expenseName: suggestion.expenseName,
            recognizedText: normalizedLines.joined(separator: "\n")
        )
    }

    private static func merchantName(from lines: [String]) -> String {
        for line in lines.prefix(8) {
            let cleanedLine = line
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard cleanedLine.count >= 3,
                  cleanedLine.filter({ $0.isLetter }).count >= 3 else {
                continue
            }

            return cleanedLine
        }

        return "Fatura"
    }

    private static func totalAmount(from lines: [String]) -> Double? {
        if let amountAfterTotal = amountAfterTotalKeyword(from: lines) {
            return amountAfterTotal
        }

        var bestCandidate: (amount: Double, score: Int)?
        let totalKeywords = ["total", "valor pago", "pago", "importancia", "montante", "a pagar", "eur"]
        let negativeKeywords = ["troco", "nif", "contribuinte", "iva", "taxa", "subtotal", "desconto"]

        for (index, line) in lines.enumerated() {
            let normalizedLine = normalized(line)
            let amounts = amounts(in: line)
            guard !amounts.isEmpty else { continue }

            var score = 0
            if totalKeywords.contains(where: { normalizedLine.contains($0) }) { score += 20 }
            if negativeKeywords.contains(where: { normalizedLine.contains($0) }) { score -= 12 }
            score += max(0, 8 - index)

            for amount in amounts where amount > 0 && amount < 100_000 {
                let candidateScore = score + Int(min(amount, 999) / 100)
                if bestCandidate == nil || candidateScore > bestCandidate!.score || (candidateScore == bestCandidate!.score && amount > bestCandidate!.amount) {
                    bestCandidate = (amount, candidateScore)
                }
            }
        }

        return bestCandidate?.amount
    }

    private static func amountAfterTotalKeyword(from lines: [String]) -> Double? {
        for (index, line) in lines.enumerated() {
            let normalizedLine = normalized(line)
            guard hasStandaloneTotalKeyword(in: normalizedLine) else { continue }

            let totalRange = line.range(of: "total", options: [.caseInsensitive, .diacriticInsensitive])
            let textAfterTotal: String
            if let totalRange {
                textAfterTotal = String(line[totalRange.upperBound...])
            } else {
                textAfterTotal = line
            }

            if let amount = amounts(in: textAfterTotal).last(where: { $0 > 0 && $0 < 100_000 }) {
                return amount
            }

            if lines.indices.contains(index + 1),
               let amount = amounts(in: lines[index + 1]).last(where: { $0 > 0 && $0 < 100_000 }) {
                return amount
            }
        }

        return nil
    }

    private static func hasStandaloneTotalKeyword(in line: String) -> Bool {
        let tokens = line.components(separatedBy: CharacterSet.letters.inverted)
        return tokens.contains("total")
    }

    private static func amounts(in line: String) -> [Double] {
        let pattern = #"(?<!\d)(\d{1,4}(?:[ .]\d{3})*[,.]\d{2})(?!\d)|(?<!\d)(\d{1,5})(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)

        return regex.matches(in: line, range: nsRange).compactMap { match in
            guard let range = Range(match.range, in: line) else { return nil }
            let rawValue = String(line[range])
            return decimalValue(from: rawValue)
        }
    }

    private static func decimalValue(from rawValue: String) -> Double? {
        var value = rawValue.replacingOccurrences(of: " ", with: "")

        if value.contains(",") {
            value = value.replacingOccurrences(of: ".", with: "")
            value = value.replacingOccurrences(of: ",", with: ".")
        }

        return Double(value)
    }

    private static func receiptDate(from lines: [String]) -> Date? {
        let text = lines.joined(separator: " ")
        let pattern = #"\b(\d{1,2})[\-/\.](\d{1,2})[\-/\.](\d{2,4})\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text)),
              let dayRange = Range(match.range(at: 1), in: text),
              let monthRange = Range(match.range(at: 2), in: text),
              let yearRange = Range(match.range(at: 3), in: text),
              let day = Int(text[dayRange]),
              let month = Int(text[monthRange]),
              var year = Int(text[yearRange]) else {
            return nil
        }

        if year < 100 { year += 2000 }
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }

    private static func categorySuggestion(for merchant: String, lines: [String]) -> (category: ExpenseCategory, expenseName: String) {
        let text = normalized(([merchant] + lines).joined(separator: " "))

        if containsAny(text, ["continente", "pingo doce", "lidl", "aldi", "auchan", "mercadona", "intermarche", "supermerc", "mini preco", "mercearia"]) {
            return (.needs, expenseName(in: .needs, index: 2, fallback: "Alimentação: compras de supermercado"))
        }

        if containsAny(text, ["uber", "bolt", "cp", "metro", "comboio", "bus", "autocarro", "galp", "bp", "repsol", "prio", "combustivel"]) {
            return (.needs, expenseName(in: .needs, index: 1, fallback: "Transportes: transporte público, prestações e combustível"))
        }

        if containsAny(text, ["restaurante", "cafe", "pastelaria", "pizz", "burger", "glovo", "ubereats", "takeaway", "snack"]) {
            return (.wants, expenseName(in: .wants, index: 0, fallback: "Refeições fora de casa"))
        }

        if containsAny(text, ["cinema", "teatro", "netflix", "spotify", "bilhete", "lazer"]) {
            return (.wants, expenseName(in: .wants, index: 2, fallback: "Atividades de lazer e entretenimento"))
        }

        if containsAny(text, ["zara", "hm", "primark", "worten", "fnac", "amazon", "loja", "moda"]) {
            return (.wants, expenseName(in: .wants, index: 4, fallback: "Roupa e acessórios"))
        }

        return (.wants, expenseName(in: .wants, index: 5, fallback: "Outros"))
    }

    private static func expenseName(in category: ExpenseCategory, index: Int, fallback: String) -> String {
        category.names.indices.contains(index) ? category.names[index] : fallback
    }

    private static func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }

    private static func normalized(_ text: String) -> String {
        text
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }
}
