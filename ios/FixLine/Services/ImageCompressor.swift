import UIKit

/// Re-encodes picked photos against the AI gateway's ~4.5 MB request-body budget
/// using an iterative resize/quality ladder (see Rork AI skill, image-input).
nonisolated enum ImageCompressor {
    private static let ladder: [(longEdge: CGFloat, quality: CGFloat)] = [
        (1280, 0.82), (1024, 0.78), (832, 0.74), (640, 0.70), (512, 0.65)
    ]

    /// Returns raw base64 JPEG (no data: prefix) that fits the byte budget, or nil.
    static func jpegBase64(from image: UIImage, maxBytes: Int = 2_500_000) -> String? {
        for step in ladder {
            guard let resized = resized(image, longEdge: step.longEdge),
                  let data = resized.jpegData(compressionQuality: step.quality) else { continue }
            if data.count <= maxBytes {
                return data.base64EncodedString()
            }
        }
        return nil
    }

    static func resized(_ image: UIImage, longEdge: CGFloat) -> UIImage? {
        let longest = max(image.size.width, image.size.height)
        guard longest > 0 else { return nil }
        guard longest > longEdge else { return image }
        let scale = longEdge / longest
        let newSize = CGSize(width: floor(image.size.width * scale), height: floor(image.size.height * scale))
        guard newSize.width >= 1, newSize.height >= 1 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
