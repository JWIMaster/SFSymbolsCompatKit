import UIKit
import CoreText

// MARK: - Symbol Weight
public enum SymbolWeightA: String {
    case ultralight, thin, light, regular, medium, semibold, bold, heavy, black
}

// MARK: - SFSymbols Manager
public class SFSymbols {
    public static let shared = SFSymbols()
    
    public var lookup: [String: String] = [:] // now only 1 dictionary
    
    private let availableWeights: [SymbolWeightA] = [.ultralight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
    private var registeredFonts: Set<String> = []

    private init() {
        loadLookup()
    }
    
    // Load cleaned JSON
    private func loadLookup() {
        let bundle = Bundle(for: SFSymbols.self)
        guard let url = bundle.url(forResource: "glyph_lookup_clean", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
            print("Failed to load glyph lookup")
            return
        }
        lookup = json
    }

    // Lazy register font
    private func registerFontIfNeeded(weight: SymbolWeightA) {
        guard !registeredFonts.contains(weight.rawValue) else { return }
        let bundle = Bundle(for: SFSymbols.self)
        if let url = bundle.url(forResource: "SFSymbols-\(weight.rawValue)", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            registeredFonts.insert(weight.rawValue)
        }
    }
    
    // UIFont for weight
    public func font(weight: SymbolWeightA, size: CGFloat) -> UIFont? {
        registerFontIfNeeded(weight: weight)
        return UIFont(name: "SFSymbols-\(weight.rawValue)", size: size)
    }
    
    // Unicode for symbol name
    public func unicode(for name: String) -> String? {
        guard let hex = lookup[name],
              let codePoint = UInt32(hex, radix: 16),
              let scalar = UnicodeScalar(codePoint) else { return nil }
        return String(scalar)
    }
}

// MARK: - UIImage Backport
public extension UIImage {
    @available(iOS, introduced: 6.0, obsoleted: 13.0)
    convenience init?(systemName name: String, weight: SymbolWeightA = .regular, pointSize: CGFloat = 30, color: UIColor = .black) {
        guard let unicode = SFSymbols.shared.unicode(for: name),
              let font = SFSymbols.shared.font(weight: weight, size: pointSize) else {
            return nil
        }
        
        let attrString = NSAttributedString(string: unicode, attributes: [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: color
        ])
        
        var size = attrString.size()
        if size.width < 1 { size.width = 1 }
        if size.height < 1 { size.height = 1 }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        attrString.draw(at: CGPoint.zero)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
}

// MARK: - UILabel Convenience
public extension UILabel {
    func setSymbol(_ name: String, weight: SymbolWeightA = .regular, size: CGFloat = 30, color: UIColor = .black) {
        self.font = SFSymbols.shared.font(weight: weight, size: size)
        self.textColor = color
        self.text = SFSymbols.shared.unicode(for: name)
    }
}

// MARK: - UIButton Convenience
public extension UIButton {
    func setSymbol(_ name: String, weight: SymbolWeightA = .regular, size: CGFloat = 30, color: UIColor = .black, forState state: UIControl.State = .normal) {
        if let image = UIImage(systemName: name, weight: weight, pointSize: size, color: color) {
            self.setImage(image, for: state)
        }
    }
}
