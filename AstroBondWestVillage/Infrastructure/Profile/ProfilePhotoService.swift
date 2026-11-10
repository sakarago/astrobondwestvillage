import Foundation
import UIKit
import Supabase

enum ProfilePhotoError: LocalizedError {
    case unreadableImage
    case upload(String)
    var errorDescription: String? {
        switch self {
        case .unreadableImage: return "Fotoğraf okunamadı. Başka bir fotoğraf dene."
        case .upload(let m): return "Fotoğraf yüklenemedi: \(m)"
        }
    }
}

struct ProfilePhoto: Identifiable, Equatable, Sendable, Decodable {
    let id: String
    let url: String
    let path: String
    var position: Int
}

/// Multi-photo profile gallery on Supabase Storage (public bucket, served via the Supabase CDN)
/// plus the `profile_photos` table (see `Notes/ProfilePhotosGallery.sql`).
///
/// Every photo is a new, uniquely named object with a one-year `Cache-Control`, so edge and device
/// caches never serve a stale image. A 256px `-thumb` copy sits next to each photo for grids/avatars.
/// `profiles.profile_photo_url` always mirrors the first (primary) photo, so existing screens keep working.
final class ProfilePhotoService: Sendable {
    static let bucket = "profile-photos"
    static let maxPhotos = 6
    static let fullMaxSide: CGFloat = 1080
    static let thumbMaxSide: CGFloat = 256

    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }

    func fetchPhotos(userId: String) async throws -> [ProfilePhoto] {
        do {
            return try await client.from("profile_photos")
                .select("id,url,path,position")
                .eq("user_id", value: userId.lowercased())
                .order("position", ascending: true)
                .execute()
                .value
        } catch {
            throw ProfilePhotoError.upload(error.localizedDescription)
        }
    }

    /// Resizes, uploads (full + thumbnail) and appends the photo to the gallery.
    func addPhoto(userId: String, imageData: Data, position: Int) async throws -> ProfilePhoto {
        guard let image = UIImage(data: imageData) else { throw ProfilePhotoError.unreadableImage }
        guard let full = Self.jpeg(image, maxSide: Self.fullMaxSide, quality: 0.8),
              let thumb = Self.jpeg(image, maxSide: Self.thumbMaxSide, quality: 0.75)
        else { throw ProfilePhotoError.unreadableImage }

        let uid = userId.lowercased()
        let name = "photo-\(UUID().uuidString.lowercased())"
        let fullPath = "\(uid)/\(name).jpg"
        let thumbPath = "\(uid)/\(name)-thumb.jpg"
        let options = FileOptions(cacheControl: "31536000", contentType: "image/jpeg", upsert: false)

        do {
            let files = client.storage.from(Self.bucket)
            try await files.upload(fullPath, data: full, options: options)
            try await files.upload(thumbPath, data: thumb, options: options)
            let url = try files.getPublicURL(path: fullPath).absoluteString

            struct Row: Encodable { let user_id: String; let path: String; let url: String; let position: Int }
            let saved: ProfilePhoto = try await client.from("profile_photos")
                .insert(Row(user_id: uid, path: fullPath, url: url, position: position))
                .select("id,url,path,position")
                .single()
                .execute()
                .value
            if position == 0 { try await syncPrimary(userId: userId, url: url) }
            return saved
        } catch {
            _ = try? await client.storage.from(Self.bucket).remove(paths: [fullPath, thumbPath])
            throw ProfilePhotoError.upload(error.localizedDescription)
        }
    }

    /// Moves `photo` to the front and returns the re-numbered list.
    func makePrimary(userId: String, photo: ProfilePhoto, in photos: [ProfilePhoto]) async throws -> [ProfilePhoto] {
        var list = photos
        guard let idx = list.firstIndex(of: photo), idx != 0 else { return photos }
        list.insert(list.remove(at: idx), at: 0)
        do {
            list = try await renumber(list)
            try await syncPrimary(userId: userId, url: list.first?.url)
            return list
        } catch {
            throw ProfilePhotoError.upload(error.localizedDescription)
        }
    }

    /// Persists a new order (already applied locally) and keeps the primary photo URL in sync.
    func saveOrder(userId: String, photos: [ProfilePhoto]) async throws -> [ProfilePhoto] {
        do {
            let list = try await renumber(photos)
            try await syncPrimary(userId: userId, url: list.first?.url)
            return list
        } catch {
            throw ProfilePhotoError.upload(error.localizedDescription)
        }
    }

    func deletePhoto(userId: String, photo: ProfilePhoto, in photos: [ProfilePhoto]) async throws -> [ProfilePhoto] {
        do {
            try await client.from("profile_photos").delete().eq("id", value: photo.id).execute()
            let thumb = photo.path.replacingOccurrences(of: ".jpg", with: "-thumb.jpg")
            _ = try? await client.storage.from(Self.bucket).remove(paths: [photo.path, thumb])
            let list = try await renumber(photos.filter { $0.id != photo.id })
            try await syncPrimary(userId: userId, url: list.first?.url)
            return list
        } catch {
            throw ProfilePhotoError.upload(error.localizedDescription)
        }
    }

    private func renumber(_ list: [ProfilePhoto]) async throws -> [ProfilePhoto] {
        var out = list
        for i in out.indices where out[i].position != i {
            out[i].position = i
            struct Patch: Encodable { let position: Int }
            try await client.from("profile_photos").update(Patch(position: i)).eq("id", value: out[i].id).execute()
        }
        return out
    }

    private func syncPrimary(userId: String, url: String?) async throws {
        struct Patch: Encodable {
            let profile_photo_url: String?
            enum CodingKeys: String, CodingKey { case profile_photo_url }
            func encode(to encoder: Encoder) throws {
                var c = encoder.container(keyedBy: CodingKeys.self)
                try c.encode(profile_photo_url, forKey: .profile_photo_url)   // encodes null when nil
            }
        }
        try await client.from("profiles")
            .update(Patch(profile_photo_url: url))
            .eq("id", value: userId)
            .execute()
    }

    /// Conventional thumbnail URL for photos uploaded by this service; nil for legacy URLs.
    static func thumbURL(for url: URL) -> URL? {
        let s = url.absoluteString
        guard s.contains("/\(bucket)/"), s.contains("/photo-") || s.contains("/avatar-"),
              s.hasSuffix(".jpg"), !s.hasSuffix("-thumb.jpg")
        else { return nil }
        return URL(string: s.replacingOccurrences(of: ".jpg", with: "-thumb.jpg"))
    }

    static func jpeg(_ image: UIImage, maxSide: CGFloat, quality: CGFloat) -> Data? {
        let size = image.size
        let longest = max(size.width, size.height)
        let scale = longest > maxSide ? maxSide / longest : 1
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
