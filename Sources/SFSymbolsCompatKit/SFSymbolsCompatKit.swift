import UIKit
import SwiftSVG

public enum SFSymbolWeight: String {
    case ultralight, thin, light, regular, medium, semibold, bold, heavy, black
}

public extension UIImage {
    
    /// Backported SF Symbols initializer
    /// - Parameters:
    ///   - systemName: symbol name
    ///   - weight: desired weight, default is `.regular`
    ///   - pointSize: desired size in points, default 100
    ///   - scale: image scale, default is device main screen scale
    convenience init?(systemName name: String,
                      weight: SFSymbolWeight = .regular,
                      pointSize: CGFloat = 100,
                      scale: CGFloat = UIScreen.main.scale) {
        
        // Use native SF Symbols on iOS 13+
        if #available(iOS 13.0, *) {
            if let img = UIImage(systemName: name) {
                self.init(cgImage: img.cgImage!)
                return
            }
        }
        
        // Determine folder for weight
        let folderName = weight.rawValue
        
        // Use the package bundle
        let bundle = Bundle.module
        var url = bundle.url(forResource: name, withExtension: "svg", subdirectory: "Assets/\(folderName)")
        
        // Fallback to regular weight
        if url == nil {
            url = bundle.url(forResource: name, withExtension: "svg", subdirectory: "Assets/regular")
        }
        guard let svgURL = url else { return nil }
        
        // Load SVG layer
        var svgLayer: CALayer?
        let _ = UIView(SVGURL: svgURL) { layer in
            svgLayer = layer
        }
        guard let layer = svgLayer else { return nil }
        
        // Compute scaling to fit pointSize while preserving aspect ratio
        let targetSize = CGSize(width: pointSize, height: pointSize)
        let originalBounds = layer.bounds
        let scaleX = targetSize.width / originalBounds.width
        let scaleY = targetSize.height / originalBounds.height
        let scaleFactor = min(scaleX, scaleY)
        layer.setAffineTransform(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
        layer.position = CGPoint(x: targetSize.width/2, y: targetSize.height/2)
        
        // Render to UIImage at the desired scale
        UIGraphicsBeginImageContextWithOptions(targetSize, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        guard let renderedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()
        
        self.init(cgImage: renderedImage.cgImage!)
    }
    
    /// Convenience initializer that uses default point size and scale
    convenience init?(systemName name: String, weight: SFSymbolWeight) {
        self.init(systemName: name, weight: weight, pointSize: 100, scale: UIScreen.main.scale)
    }
    
    /// Convenience initializer that uses default weight and scale
    convenience init?(systemName name: String, pointSize: CGFloat) {
        self.init(systemName: name, weight: .regular, pointSize: pointSize, scale: UIScreen.main.scale)
    }
    
    /// Convenience initializer that uses default weight and point size
    convenience init?(systemName name: String, scale: CGFloat) {
        self.init(systemName: name, weight: .regular, pointSize: 100, scale: scale)
    }
}
