import UIKit
import CoreText

// MARK: - Symbol Weight
public enum SymbolWeightA: String {
    case ultralight, thin, light, regular, medium, semibold, bold, heavy, black
}

// MARK: - SFSymbols Manager
public class SFSymbols {
    public static let shared = SFSymbols()

    // weight -> symbolName -> unicode
    private var lookup: [String: [String: String]] = [:]
    private var registeredFonts: Set<String> = []
    private var symbolCache: [String: UIImage] = [:] // cache drawn images

    private init() {
        loadLookup()
    }

    // MARK: Load glyph lookup JSON from bundle
    private func loadLookup() {
        let bundle = Bundle(for: SFSymbols.self)
        guard let url = bundle.url(forResource: "glyph_lookup", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: String]] else {
            print("Failed to load glyph lookup")
            return
        }
        lookup = json
    }

    // MARK: Register font lazily
    private func registerFontIfNeeded(weight: SymbolWeightA) {
        if registeredFonts.contains(weight.rawValue) { return }
        let bundle = Bundle(for: SFSymbols.self)
        if let url = bundle.url(forResource: "SFSymbols-\(weight.rawValue)", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            registeredFonts.insert(weight.rawValue)
        }
    }

    // MARK: Get UIFont
    public func font(weight: SymbolWeightA, size: CGFloat) -> UIFont? {
        registerFontIfNeeded(weight: weight)
        return UIFont(name: "SFSymbols-\(weight.rawValue)", size: size)
    }

    // MARK: Get unicode character
    public func unicode(for name: String, weight: SymbolWeightA = .regular) -> String? {
        return lookup[weight.rawValue]?[name].flatMap { UInt32($0, radix: 16) }.flatMap { UnicodeScalar($0) }.map { String($0) }
    }

    // MARK: Create UIImage for symbol
    public func image(for name: String, weight: SymbolWeightA = .regular, size: CGFloat = 30, color: UIColor = .black) -> UIImage? {
        let cacheKey = "\(name)-\(weight.rawValue)-\(size)-\(color.description)"
        if let cached = symbolCache[cacheKey] { return cached }

        guard let unicode = self.unicode(for: name, weight: weight),
              let font = self.font(weight: weight, size: size) else { return nil }

        let attrString = NSAttributedString(string: unicode, attributes: [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: color
        ])

        var imageSize = attrString.size()
        if imageSize.width < 1 { imageSize.width = 1 }
        if imageSize.height < 1 { imageSize.height = 1 }

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        attrString.draw(at: CGPoint.zero)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let img = image { symbolCache[cacheKey] = img }
        return image
    }
}

// MARK: - UILabel Convenience
public extension UILabel {
    func setSymbol(_ name: String, weight: SymbolWeightA = .regular, size: CGFloat = 30, color: UIColor = .black) {
        self.font = SFSymbols.shared.font(weight: weight, size: size)
        self.textColor = color
        self.text = SFSymbols.shared.unicode(for: name, weight: weight)
    }
}

// MARK: - UIButton Convenience
public extension UIButton {
    func setSymbol(_ name: String, weight: SymbolWeightA = .regular, size: CGFloat = 30, color: UIColor = .black, forState state: UIControl.State = .normal) {
        if let image = SFSymbols.shared.image(for: name, weight: weight, size: size, color: color) {
            self.setImage(image, for: state)
        }
    }
}
