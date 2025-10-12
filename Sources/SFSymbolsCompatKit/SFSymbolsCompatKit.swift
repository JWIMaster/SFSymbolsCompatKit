import UIKit
import CoreText

// MARK: - Symbol Weight
public enum SymbolWeightA: String {
    case ultralight, thin, light, regular, medium, semibold, bold, heavy, black
}

// MARK: - Symbol Scale
public enum SymbolScaleA {
    case small, medium, large
    
    func scaleFactor() -> CGFloat {
        switch self {
        case .small: return 0.8
        case .medium: return 1.0
        case .large: return 1.2
        }
    }
}

// MARK: - Symbol Configuration Backport
public class SymbolConfigurationA {
    public let pointSize: CGFloat
    public let weight: SymbolWeightA
    public let scale: SymbolScaleA
    
    public init(pointSize: CGFloat = 30, weight: SymbolWeightA = .regular, scale: SymbolScaleA = .medium) {
        self.pointSize = pointSize
        self.weight = weight
        self.scale = scale
    }
}

// MARK: - SFSymbols Manager
public class SFSymbols {
    public static let shared = SFSymbols()
    
    private var lookup: [UInt32: UInt16] = [:] // hash -> unicode
    private var registeredFonts: Set<String> = []

    private init() {
        loadLookupDat()
    }
    
    // MARK: - FNV-1a Hash
    private func fnv1aHash(_ s: String) -> UInt32 {
        var h: UInt32 = 0x811C9DC5
        for byte in s.utf8 {
            h ^= UInt32(byte)
            h = (h &* 0x01000193) & 0xFFFFFFFF
        }
        return h
    }

    private func loadLookupDat() {
        let bundle = Bundle(for: SFSymbols.self)
        guard let url = bundle.url(forResource: "lookup", withExtension: "dat"),
              let data = try? Data(contentsOf: url) else {
            print("❌ Failed to load lookup.dat")
            return
        }

        var cursor = 0
        while cursor + 6 <= data.count {
            let hash = UInt32(data[cursor]) |
                       UInt32(data[cursor + 1]) << 8 |
                       UInt32(data[cursor + 2]) << 16 |
                       UInt32(data[cursor + 3]) << 24
            let code = UInt16(data[cursor + 4]) |
                       UInt16(data[cursor + 5]) << 8
            lookup[hash] = code
            cursor += 6
        }

        print("✅ Loaded \(lookup.count) symbols from lookup.dat")
    }

    // MARK: - Lazy font registration
    private func registerFontIfNeeded(weight: SymbolWeightA) {
        guard !registeredFonts.contains(weight.rawValue) else { return }
        let bundle = Bundle(for: SFSymbols.self)
        if let url = bundle.url(forResource: "SFSymbols-\(weight.rawValue)", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            registeredFonts.insert(weight.rawValue)
        }
    }
    
    // MARK: - UIFont for weight and scale
    public func font(weight: SymbolWeightA, pointSize: CGFloat, scale: SymbolScaleA = .medium) -> UIFont? {
        registerFontIfNeeded(weight: weight)
        let scaledSize = pointSize * scale.scaleFactor()
        return UIFont(name: "SFSymbols-\(weight.rawValue)", size: scaledSize)
    }

    // MARK: - Unicode lookup
    public func unicode(for name: String) -> String? {
        let hash = fnv1aHash(name)
        guard let code = lookup[hash],
              let scalar = UnicodeScalar(UInt32(code)) else { return nil }
        return String(scalar)
    }
}

// MARK: - UIImage Backport
public extension UIImage {
    
    // Direct weight + pointSize
    @available(iOS, introduced: 6.0, obsoleted: 13.0)
    convenience init?(systemName name: String, weight: SymbolWeightA = .regular, pointSize: CGFloat = 30, scale: SymbolScaleA = .medium, color: UIColor = .black) {
        guard let unicode = SFSymbols.shared.unicode(for: name),
              let font = SFSymbols.shared.font(weight: weight, pointSize: pointSize, scale: scale) else { return nil }
        let attrString = NSAttributedString(string: unicode, attributes: [
            .font: font,
            .foregroundColor: color
        ])
        let size = attrString.size()
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        attrString.draw(at: .zero)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }
    
    // SymbolConfiguration style
    @available(iOS, introduced: 6.0, obsoleted: 13.0)
    convenience init?(systemName name: String, configuration: SymbolConfigurationA, color: UIColor = .black) {
        self.init(systemName: name, weight: configuration.weight, pointSize: configuration.pointSize, scale: configuration.scale, color: color)
    }
}

// MARK: - UILabel Convenience
public extension UILabel {
    func setSymbol(_ name: String, configuration: SymbolConfigurationA = SymbolConfigurationA(), color: UIColor = .black) {
        self.font = SFSymbols.shared.font(weight: configuration.weight, pointSize: configuration.pointSize, scale: configuration.scale)
        self.textColor = color
        self.text = SFSymbols.shared.unicode(for: name)
    }
}

// MARK: - UIButton Convenience
public extension UIButton {
    func setSymbol(_ name: String, configuration: SymbolConfigurationA = SymbolConfigurationA(), color: UIColor = .black, forState state: UIControl.State = .normal) {
        if let image = UIImage(systemName: name, configuration: configuration, color: color) {
            self.setImage(image, for: state)
        }
    }
}
