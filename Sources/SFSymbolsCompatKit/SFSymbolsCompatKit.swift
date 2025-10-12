import UIKit
import CoreText

// MARK: - Symbol Weight
public enum SymbolWeightA: String {
    case ultralight, thin, light, regular, medium, semibold, bold, heavy, black
}

// MARK: - SFSymbols Manager
public class SFSymbols {
    public static let shared = SFSymbols()
    
    public var lookup: [String: [String: String]] = [:] // weight -> name -> unicode
    private let availableWeights: [SymbolWeightA] = [.ultralight,.thin,.light,.regular,.medium,.semibold,.bold,.heavy,.black]
    
    private init() {
        loadLookup()
        registerFonts()
    }
    
    private func loadLookup() {
        guard let url = Bundle.main.url(forResource: "glyph_lookup", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? NSJSONSerialization.jsonObject(with: data, options: []) as? [String: [String: String]] else {
            print("Failed to load glyph lookup")
            return
        }
        lookup = json
    }
    
    private func registerFonts() {
        for weight in availableWeights {
            guard let url = Bundle.main.url(forResource: "SFSymbols-\(weight.rawValue)", withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
    
    public func font(weight: SymbolWeightA, size: CGFloat) -> UIFont? {
        return UIFont(name: "SFSymbols-\(weight.rawValue)", size: size)
    }
    
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
    convenience init?(systemName name: String, weight: SymbolWeightA = .regular, pointSize: CGFloat = 30, color: UIColor = UIColor.black) {
        
        guard let unicode = SFSymbols.shared.unicode(for: name, weight: weight),
              let font = SFSymbols.shared.font(weight: weight, size: pointSize) else { return nil }
        
        // Draw the symbol safely
        let attrString = NSAttributedString(string: unicode, attributes: [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: color
        ])
        
        var size = attrString.size()
        if size.width < 1 { size.width = 1 }
        if size.height < 1 { size.height = 1 }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0) // fixed scale for iOS 6
        attrString.draw(at: .zero)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
    }
}
