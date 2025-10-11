import UIKit
import SwiftSVG

public enum SFSymbolWeight: String {
    case ultralight, thin, light, regular, medium, semibold, bold, heavy, black
}

public extension UIImage {

    /// Backported SF Symbols initializer
    convenience init?(systemName name: String, weight: SFSymbolWeight = .regular, pointSize: CGFloat = 100) {

        // Use native SF Symbols on iOS 13+
        if #available(iOS 13.0, *) {
            if let img = UIImage(systemName: name) {
                self.init(cgImage: img.cgImage!)
                return
            }
        }

        // Determine folder for weight
        let folderName = weight.rawValue

        // Use the bundle of this class to locate SVGs
        let bundle = Bundle.module
        var url = bundle.url(forResource: name, withExtension: "svg", subdirectory: "Assets/\(folderName)")

        // Fallback to regular weight if SVG not found
        if url == nil {
            url = bundle.url(forResource: name, withExtension: "svg", subdirectory: "Assets/regular")
        }
        guard let svgURL = url else { return nil }

        // Offscreen view with desired size
        let size = CGSize(width: pointSize, height: pointSize)
        let svgView = UIView(frame: CGRect(origin: .zero, size: size))
        svgView.backgroundColor = .clear

        // Use SwiftSVG to load the SVG into the view
        let _ = UIView(SVGURL: svgURL) { layer in
            layer.frame = svgView.bounds
            svgView.layer.addSublayer(layer)
        }

        // Render into UIImage
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        svgView.layer.render(in: context)
        guard let renderedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()

        self.init(cgImage: renderedImage.cgImage!)
    }
}



