import UIKit
import CoreText

// MARK: - Symbol Weight
public enum SymbolWeightA: String {
    case ultralight, thin, light, regular, medium, semibold, bold, heavy, black
}

// MARK: - Symbol Scale
public enum SymbolScaleA {
    case small, medium, large
}

// MARK: - SFSymbols Manager
public class SFSymbols {
    public static let shared = SFSymbols()
    
    private var lookup: [UInt32: UInt16] = [:]
    private var registeredFonts: Set<String> = []

    private init() { loadLookupDat() }

    private func fnv1aHash(_ s: String) -> UInt32 {
        var h: UInt32 = 0x811C9DC5
        for byte in s.utf8 {
            h ^= UInt32(byte)
            h = (h &* 0x01000193) & 0xFFFFFFFF
        }
        return h
    }

    private func loadLookupDat() {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: "lookup", withExtension: "dat"),
              let data = try? Data(contentsOf: url) else {
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
    }

    private func registerFontIfNeeded(weight: SymbolWeightA) {
        guard !registeredFonts.contains(weight.rawValue) else { return }
        let bundle = Bundle.module
        if let url = bundle.url(forResource: "SFSymbols-\(weight.rawValue)", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            registeredFonts.insert(weight.rawValue)
        }
    }

    public func font(weight: SymbolWeightA, size: CGFloat) -> UIFont? {
        registerFontIfNeeded(weight: weight)
        return UIFont(name: "SFSymbols-\(weight.rawValue)", size: size)
    }

    public func unicode(for name: String) -> String? {
        let hash = fnv1aHash(name)
        guard let code = lookup[hash],
              let scalar = UnicodeScalar(UInt32(code)) else { return nil }
        return String(scalar)
    }
}

// MARK: - UIImage Backport Extension

public extension UIImage {

    /// Backport SymbolConfiguration for iOS <13
    @available(iOS, introduced: 6.0, obsoleted: 13.0)
    struct SymbolConfigurationA {
        public var pointSize: CGFloat
        public var weight: SymbolWeightA
        public var scale: SymbolScaleA

        public init(pointSize: CGFloat = 17, weight: SymbolWeightA = .regular, scale: SymbolScaleA = .medium) {
            self.pointSize = pointSize
            self.weight = weight
            self.scale = scale
        }
    }
    
    typealias SymbolConfiguration = SymbolConfigurationA

    @available(iOS, introduced: 6.0, obsoleted: 13.0)
    convenience init?(systemName name: String, withConfiguration config: SymbolConfigurationA? = nil) {
        let config = config ?? SymbolConfigurationA()

        var fontSize = config.pointSize * 1.22
        switch config.scale {
        case .small: fontSize *= 0.75
        case .medium: break
        case .large: fontSize *= 1.25
        }

        guard let unicode = SFSymbols.shared.unicode(for: name),
              let font = SFSymbols.shared.font(weight: config.weight, size: fontSize) else { return nil }

        let attrString = NSAttributedString(string: unicode, attributes: [
            .font: font,
            .foregroundColor: UIColor.black
        ])

        // Measure tight glyph bounds using CoreText
        let line = CTLineCreateWithAttributedString(attrString)
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]

        var tightBounds = CGRect.null
        for run in runs {
            let runCount = CTRunGetGlyphCount(run)
            for i in 0..<runCount {
                let glyphBounds = CTRunGetImageBounds(run, nil, CFRange(location: i, length: 1))
                tightBounds = tightBounds.union(glyphBounds)
            }
        }

        // Calculate original left padding
        let originalSize = attrString.size()
        let leftPadding = tightBounds.minX

        // Remove all padding and add original left padding to each side
        let paddedRect = CGRect(
            x: 0,
            y: 0,
            width: tightBounds.width + leftPadding * 2,
            height: tightBounds.height + leftPadding * 2
        )

        UIGraphicsBeginImageContextWithOptions(paddedRect.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.translateBy(x: 0, y: paddedRect.height)
        context.scaleBy(x: 1, y: -1)

        
        // Red background
        //UIColor.red.setFill()
        //context.fill(CGRect(origin: .zero, size: paddedRect.size))

        // Draw glyph, offset to account for removed padding
        context.translateBy(x: -tightBounds.minX + leftPadding, y: -tightBounds.minY + leftPadding)
        CTLineDraw(line, context)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }


}
