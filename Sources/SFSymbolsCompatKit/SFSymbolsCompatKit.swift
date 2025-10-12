import UIKit
import CoreText

// MARK: - Symbol Weight
public enum SymbolWeightA: String {
    case ultralight, thin, light, regular, medium, semibold, bold, heavy, black
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

    // MARK: - Load binary lookup table safely
    private func loadLookupDat() {
        let bundle = Bundle(for: SFSymbols.self)
        guard let url = bundle.url(forResource: "lookup", withExtension: "dat"),
              let data = try? Data(contentsOf: url) else {
            print("❌ Failed to load lookup.dat")
            return
        }

        var cursor = 0
        while cursor + 6 <= data.count {
            // Use copyBytes to avoid misaligned load crashes
            let hash: UInt32 = data[cursor..<(cursor+4)].withUnsafeBytes { buffer in
                var value: UInt32 = 0
                _ = buffer.copyBytes(to: &value, count: 4)
                return UInt32(littleEndian: value)
            }
            let code: UInt16 = data[(cursor+4)..<(cursor+6)].withUnsafeBytes { buffer in
                var value: UInt16 = 0
                _ = buffer.copyBytes(to: &value, count: 2)
                return UInt16(littleEndian: value)
            }
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
    
    // MARK: - UIFont for weight
    public func font(weight: SymbolWeightA, size: CGFloat) -> UIFont? {
        registerFontIfNeeded(weight: weight)
        return UIFont(name: "SFSymbols-\(weight.rawValue)", size: size)
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
    @available(iOS, introduced: 6.0, obsoleted: 13.0)
    convenience init?(systemName name: String, weight: SymbolWeightA = .regular, pointSize: CGFloat = 30, color: UIColor = .black) {
        guard let unicode = SFSymbols.shared.unicode(for: name),
              let font = SFSymbols.shared.font(weight: weight, size: pointSize) else { return nil }

        let attrString = NSAttributedString(string: unicode, attributes: [
            .font: font,
            .foregroundColor: color
        ])

        let size = attrString.size()
        UIGraphicsBeginImageContextWithOptions(size, false, 0) // Use device scale
        attrString.draw(at: .zero)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
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
