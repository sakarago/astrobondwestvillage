import SwiftUI
import UIKit

/// Memory + disk image cache. Photo URLs are versioned (new upload = new URL), so cached
/// copies never go stale and can be kept for a long time.
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let memory = NSCache<NSURL, UIImage>()
    private let session: URLSession

    private init() {
        memory.countLimit = 300
        let cache = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 300 * 1024 * 1024, directory: nil)
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
    }

    func cached(_ url: URL) -> UIImage? { memory.object(forKey: url as NSURL) }

    func load(_ url: URL) async -> UIImage? {
        if let hit = cached(url) { return hit }
        guard let (data, response) = try? await session.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let image = UIImage(data: data)
        else { return nil }
        memory.setObject(image, forKey: url as NSURL)
        return image
    }
}

/// Drop-in `AsyncImage` replacement with caching. Tries `primary` first, then `fallback`.
struct CachedAsyncImage<Placeholder: View>: View {
    let primary: URL
    var fallback: URL? = nil
    var fill: Bool = true
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().aspectRatio(contentMode: fill ? .fill : .fit)
            } else if let hit = ImageCache.shared.cached(primary) {
                Image(uiImage: hit).resizable().aspectRatio(contentMode: fill ? .fill : .fit)
            } else {
                placeholder()
            }
        }
        .task(id: primary) {
            if let img = await ImageCache.shared.load(primary) { image = img; return }
            if let fallback, let img = await ImageCache.shared.load(fallback) { image = img }
        }
    }
}
