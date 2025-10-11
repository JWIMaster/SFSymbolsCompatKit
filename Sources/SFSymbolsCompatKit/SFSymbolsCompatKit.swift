import UIKit
import SwiftSVG

public enum SFSymbolWeight: String {
    case ultralight, thin, light, regular, medium, semibold, bold, heavy, black
}

public extension UIImage {
    
    /// Backported SF Symbols initializer with robust SVG handling
    convenience init?(systemName name: String,
                      weight: SFSymbolWeight = .regular,
                      pointSize: CGFloat = 100,
                      scale: CGFloat = UIScreen.main.scale) {
        
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
        let containerView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: pointSize, height: pointSize)))
        containerView.backgroundColor = .clear
        
        var svgLayer: CALayer?
        let semaphore = DispatchSemaphore(value: 0) // force synchronous execution
        
        UIView(SVGURL: svgURL) { layer in
            // Skip unsupported elements gracefully
            if layer.bounds.width > 0 && layer.bounds.height > 0 {
                let originalBounds = layer.bounds
                let scaleX = pointSize / originalBounds.width
                let scaleY = pointSize / originalBounds.height
                let scaleFactor = min(scaleX, scaleY)
                layer.setAffineTransform(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
                layer.position = CGPoint(x: pointSize/2, y: pointSize/2)
                svgLayer = layer
            }
            semaphore.signal()
        }
        
        // Wait for layer to be prepared
        semaphore.wait()
        
        guard let layer = svgLayer else { return nil }
        containerView.layer.addSublayer(layer)
        
        // Render to UIImage at the desired scale
        UIGraphicsBeginImageContextWithOptions(CGSize(width: pointSize, height: pointSize), false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        containerView.layer.render(in: context)
        guard let renderedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()
        
        self.init(cgImage: renderedImage.cgImage!)
    }
    
    // Convenience initializers for regular SF Symbols API
    convenience init?(systemName name: String, weight: SFSymbolWeight) {
        self.init(systemName: name, weight: weight, pointSize: 100, scale: UIScreen.main.scale)
    }
    
    convenience init?(systemName name: String, pointSize: CGFloat) {
        self.init(systemName: name, weight: .regular, pointSize: pointSize, scale: UIScreen.main.scale)
    }
    
    convenience init?(systemName name: String, scale: CGFloat) {
        self.init(systemName: name, weight: .regular, pointSize: 100, scale: scale)
    }
}
