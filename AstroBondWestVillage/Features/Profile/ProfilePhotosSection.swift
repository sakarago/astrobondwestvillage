import SwiftUI
import PhotosUI

/// "Fotoğraflarım" — up to 6 photos. First one is the main photo (big tile).
/// Tap a photo to view it full screen, use the ••• menu to make it main or delete it,
/// tap an empty tile to add (multi-select supported).
struct ProfilePhotosSection: View {
    let userId: String
    @Binding var photos: [ProfilePhoto]
    /// Called with the new main-photo URL whenever the gallery changes.
    var onPrimaryChanged: (String?) -> Void = { _ in }

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var uploading = 0
    @State private var busyId: String?
    @State private var error: String?
    @State private var viewerIndex: Int?
    @State private var dropTarget: String?

    private let service = ProfilePhotoService()
    private let gap: CGFloat = 8
    private let hPad: CGFloat = 24
    private var remaining: Int { max(0, ProfilePhotoService.maxPhotos - photos.count - uploading) }

    private var rim: Color { Color.adaptive(light: "#E3C3B1", dark: "#FFFFFF").opacity(0.35) }

    var body: some View {
        let width = UIScreen.main.bounds.width - hPad * 2
        let small = (width - gap * 2) / 3
        let big = small * 2 + gap

        VStack(alignment: .leading, spacing: 14) {
            header
            VStack(spacing: gap) {
                HStack(spacing: gap) {
                    tile(0, size: CGSize(width: big, height: big * 1.1), isMain: true)
                    VStack(spacing: gap) {
                        tile(1, size: CGSize(width: small, height: (big * 1.1 - gap) / 2))
                        tile(2, size: CGSize(width: small, height: (big * 1.1 - gap) / 2))
                    }
                }
                HStack(spacing: gap) {
                    ForEach(3..<6, id: \.self) { tile($0, size: CGSize(width: small, height: small * 1.25)) }
                }
            }
            .padding(.horizontal, hPad)

            Text("Sıralamayı değiştirmek için fotoğrafı basılı tutup sürükle. İlk fotoğraf ana fotoğrafın. En fazla \(ProfilePhotoService.maxPhotos) fotoğraf ekleyebilirsin.")
                .font(ABFont.body(12))
                .foregroundStyle(ABColor.inkMuted)
                .padding(.horizontal, hPad + 4)
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            let batch = items
            pickerItems = []
            // Own task: resetting the picker selection must not cancel the upload.
            Task { await handlePicked(batch) }
        }
        .alert("Fotoğraf", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Tamam", role: .cancel) { error = nil }
        } message: { Text(error ?? "") }
        .fullScreenCover(item: Binding(get: { viewerIndex.map { ViewerItem(index: $0) } }, set: { viewerIndex = $0?.index })) { item in
            PhotoViewer(photos: photos, startIndex: item.index)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("✦").font(.system(size: 9)).foregroundStyle(ABColor.lavender)
                Text("PROFİL").font(ABFont.body(10.5, weight: .semibold)).tracking(2.6)
                    .foregroundStyle(Color.adaptive(light: "#8A7F92", dark: "#B7BDC7"))
            }
            HStack(alignment: .firstTextBaseline) {
                Text("Fotoğraflarım").font(ABFont.display(24, weight: .regular)).foregroundStyle(ABColor.ink)
                Spacer()
                Text("\(photos.count)/\(ProfilePhotoService.maxPhotos)")
                    .font(ABFont.body(13, weight: .medium)).foregroundStyle(ABColor.inkMuted)
            }
        }
        .padding(.horizontal, hPad + 4)
    }

    // MARK: Tiles

    @ViewBuilder
    private func tile(_ index: Int, size: CGSize, isMain: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: isMain ? 24 : 18, style: .continuous)
        if index < photos.count {
            let photo = photos[index]
            ZStack(alignment: .topLeading) {
                Button { viewerIndex = index } label: {
                    photoImage(photo, big: isMain, size: size)
                }
                .buttonStyle(.plain)

                if isMain {
                    Text("ANA")
                        .font(ABFont.body(9.5, weight: .bold)).tracking(1.6)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.45)))
                        .padding(10)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(shape)
            .overlay(shape.strokeBorder(rim, lineWidth: 1))
            .overlay(alignment: .topTrailing) { menu(for: photo, index: index) }
            .overlay { if busyId == photo.id { shape.fill(Color.black.opacity(0.4)); ProgressView().tint(.white) } }
            .overlay { if dropTarget == photo.id { shape.strokeBorder(ABColor.lavenderSoft, lineWidth: 3) } }
            .draggable(photo.id) {
                photoImage(photo, big: false, size: CGSize(width: 90, height: 110))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .dropDestination(for: String.self) { ids, _ in
                guard let id = ids.first else { return false }
                Task { await move(id, to: index) }
                return true
            } isTargeted: { targeted in
                if targeted { dropTarget = photo.id } else if dropTarget == photo.id { dropTarget = nil }
            }
        } else if index < photos.count + uploading {
            shape.fill(ABColor.veil.opacity(0.06))
                .frame(width: size.width, height: size.height)
                .overlay { ProgressView().tint(ABColor.lavenderSoft) }
        } else {
            PhotosPicker(selection: $pickerItems, maxSelectionCount: max(1, remaining), matching: .images) {
                shape.fill(ABColor.veil.opacity(0.04))
                    .overlay(shape.strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [5, 5])).foregroundStyle(ABColor.lavenderSoft.opacity(0.6)))
                    .overlay {
                        VStack(spacing: 6) {
                            Image(systemName: "plus").font(.system(size: isMain ? 26 : 18, weight: .light))
                            if isMain { Text("Fotoğraf ekle").font(ABFont.body(12.5, weight: .medium)) }
                        }
                        .foregroundStyle(ABColor.lavenderSoft)
                    }
                    .frame(width: size.width, height: size.height)
            }
            .buttonStyle(.plain)
            .disabled(remaining == 0)
        }
    }

    private func photoImage(_ photo: ProfilePhoto, big: Bool, size: CGSize) -> some View {
        let url = URL(string: photo.url)
        let thumb = url.flatMap { ProfilePhotoService.thumbURL(for: $0) }
        return Group {
            if let url {
                CachedAsyncImage(primary: big ? url : (thumb ?? url), fallback: big ? nil : (thumb == nil ? nil : url)) {
                    ABColor.veil.opacity(0.08)
                }
            } else {
                ABColor.veil.opacity(0.08)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    private func menu(for photo: ProfilePhoto, index: Int) -> some View {
        Menu {
            if index != 0 {
                Button("Ana fotoğraf yap", systemImage: "star") { Task { await makePrimary(photo) } }
            }
            Button("Sil", systemImage: "trash", role: .destructive) { Task { await delete(photo) } }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.black.opacity(0.45)))
                .padding(8)
        }
    }

    // MARK: Actions

    private func handlePicked(_ items: [PhotosPickerItem]) async {
        let take = Array(items.prefix(max(0, ProfilePhotoService.maxPhotos - photos.count)))
        uploading = take.count
        defer { uploading = 0 }
        for item in take {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                error = ProfilePhotoError.unreadableImage.errorDescription
                continue
            }
            do {
                let photo = try await service.addPhoto(userId: userId, imageData: data, position: photos.count)
                photos.append(photo)
                if photos.count == 1 { onPrimaryChanged(photo.url) }
            } catch {
                self.error = error.localizedDescription
                break
            }
            uploading -= 1
        }
    }

    /// Drag & drop: moves the dragged photo to the dropped tile's slot (slot 0 = main photo).
    private func move(_ id: String, to index: Int) async {
        dropTarget = nil
        guard let from = photos.firstIndex(where: { $0.id == id }), from != index, index < photos.count else { return }
        let before = photos
        var list = photos
        list.insert(list.remove(at: from), at: index)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { photos = list }
        do {
            photos = try await service.saveOrder(userId: userId, photos: list)
            onPrimaryChanged(photos.first?.url)
        } catch {
            withAnimation { photos = before }
            self.error = error.localizedDescription
        }
    }

    private func makePrimary(_ photo: ProfilePhoto) async {
        busyId = photo.id
        defer { busyId = nil }
        do {
            photos = try await service.makePrimary(userId: userId, photo: photo, in: photos)
            onPrimaryChanged(photos.first?.url)
        } catch { self.error = error.localizedDescription }
    }

    private func delete(_ photo: ProfilePhoto) async {
        busyId = photo.id
        defer { busyId = nil }
        do {
            photos = try await service.deletePhoto(userId: userId, photo: photo, in: photos)
            onPrimaryChanged(photos.first?.url)
        } catch { self.error = error.localizedDescription }
    }
}

private struct ViewerItem: Identifiable { let index: Int; var id: Int { index } }

/// Full-screen swipeable viewer with page dots.
struct PhotoViewer: View {
    let photos: [ProfilePhoto]
    let startIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            TabView(selection: $page) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { i, photo in
                    Group {
                        if let url = URL(string: photo.url) {
                            CachedAsyncImage(primary: url, fill: false) { ProgressView().tint(.white) }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack {
                HStack(spacing: 5) {
                    ForEach(0..<photos.count, id: \.self) { i in
                        Capsule().fill(Color.white.opacity(i == page ? 0.95 : 0.3)).frame(height: 3)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8)
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 36, height: 36).background(Circle().fill(Color.white.opacity(0.18)))
                    }
                }
                .padding(.horizontal, 16)
                Spacer()
            }
        }
        .onAppear { page = startIndex }
        .preferredColorScheme(.dark)
    }
}
