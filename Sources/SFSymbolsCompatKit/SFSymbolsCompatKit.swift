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
    public var lookup: [String: [String: String]] = [:]
    private let availableWeights: [SymbolWeightA] = [.ultralight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
    
    private init() {
        loadLookup()
        registerFonts()
    }
    
    // MARK: Load glyph lookup JSON from module bundle
    private func loadLookup() {
        // Use the bundle of this class as the module bundle
        let bundle = Bundle(for: SFSymbols.self)
        
        guard let url = bundle.url(forResource: "glyph_lookup", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: String]] else {
            print("Failed to load glyph lookup")
            return
        }
        
        lookup = json
    }
    
    // MARK: Register custom fonts
    private func registerFonts() {
        let bundle = Bundle(for: SFSymbols.self)
        
        for weight in availableWeights {
            guard let url = bundle.url(forResource: "SFSymbols-\(weight.rawValue)", withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
    
    // MARK: Return UIFont for weight
    public func font(weight: SymbolWeightA, size: CGFloat) -> UIFont? {
        return UIFont(name: "SFSymbols-\(weight.rawValue)", size: size)
    }
    
    // MARK: Return Unicode character for symbol name
    public func unicode(for name: String, weight: SymbolWeightA = .regular) -> String? {
        guard let hex = lookup[weight.rawValue]?[name],
              let codePoint = UInt32(hex, radix: 16),
              let scalar = UnicodeScalar(codePoint) else { return nil }
        return String(scalar)
    }
}

// MARK: - UIImage Init Backport
public extension UIImage {
    @available(iOS, introduced: 6.0, obsoleted: 13.0)
    convenience init?(systemName name: String, weight: SymbolWeightA = .regular, pointSize: CGFloat = 30, color: UIColor = .black) {
        
        guard let unicode = SFSymbols.shared.unicode(for: name, weight: weight),
              let font = SFSymbols.shared.font(weight: weight, size: pointSize) else { return nil }
        
        // Use iOS 6 compatible NSAttributedString keys
        let attrString = NSAttributedString(string: unicode, attributes: [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: color
        ])
        
        // Ensure minimum size
        var size = attrString.size()
        if size.width < 1 { size.width = 1 }
        if size.height < 1 { size.height = 1 }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0) // scale 1.0 for iOS 6
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
        self.text = SFSymbols.shared.unicode(for: name, weight: weight)
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
