import UIKit
import CoreText

// MARK: - Symbol Weight
public enum SymbolWeightA: String {
    case ultralight, thin, light, regular, medium, semibold, bold, heavy, black
}

// MARK: - SFSymbols Manager
public class SFSymbols {
    public static let shared = SFSymbols()
    
    private var registeredFonts: Set<String> = []

    private init() { }

    // MARK: Lazy font registration
    private func registerFontIfNeeded(weight: SymbolWeightA) {
        guard !registeredFonts.contains(weight.rawValue) else { return }
        let bundle = Bundle(for: SFSymbols.self)
        if let url = bundle.url(forResource: "SFSymbols-\(weight.rawValue)", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            registeredFonts.insert(weight.rawValue)
        }
    }

    // MARK: UIFont for weight
    public func font(weight: SymbolWeightA, size: CGFloat) -> UIFont? {
        registerFontIfNeeded(weight: weight)
        return UIFont(name: "SFSymbols-\(weight.rawValue)", size: size)
    }

    // MARK: Convert hex string (e.g., "f005") to Unicode character
    public func unicode(from hex: String) -> String? {
        guard let codePoint = UInt32(hex, radix: 16),
              let scalar = UnicodeScalar(codePoint) else { return nil }
        return String(scalar)
    }

    // MARK: Create UIImage from Unicode hex
    public func image(for hex: String, weight: SymbolWeightA = .regular, size: CGFloat = 30, color: UIColor = .black) -> UIImage? {
        guard let unicode = unicode(from: hex),
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

        return image
    }
}

// MARK: - UIImage Convenience
public extension UIImage {
    @available(iOS, introduced: 6.0, obsoleted: 13.0)
    convenience init?(hex: String, weight: SymbolWeightA = .regular, pointSize: CGFloat = 30, color: UIColor = .black) {
        guard let img = SFSymbols.shared.image(for: hex, weight: weight, size: pointSize, color: color),
              let cgImage = img.cgImage else { return nil }
        self.init(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
}

// MARK: - UILabel Convenience
public extension UILabel {
    func setSymbol(hex: String, weight: SymbolWeightA = .regular, size: CGFloat = 30, color: UIColor = .black) {
        self.font = SFSymbols.shared.font(weight: weight, size: size)
        self.textColor = color
        self.text = SFSymbols.shared.unicode(from: hex)
    }
}

// MARK: - UIButton Convenience
public extension UIButton {
    func setSymbol(hex: String, weight: SymbolWeightA = .regular, size: CGFloat = 30, color: UIColor = .black, forState state: UIControl.State = .normal) {
        if let image = UIImage(hex: hex, weight: weight, pointSize: size, color: color) {
            self.setImage(image, for: state)
        }
    }
}
