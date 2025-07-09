//
//  ZoomableImageWithOCR.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 7/9/25.
//

import SwiftUI

struct ZoomableImageWithOCR: View {
    let image: UIImage
    let ocrResults: [OCRResult]
    var onTextTap: (OCRResult) -> Void

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let imageAspectRatio = image.size.width / image.size.height
            let imageWidth = size.width
            let imageHeight = imageWidth / imageAspectRatio

            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageWidth, height: imageHeight)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value
                            }
                            .onEnded { value in
                                scale = value
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = value.translation
                            }
                    ) // Removed .onEnded to keep translation continuous

                ForEach(ocrResults) { result in
                    Button(action: {
                        onTextTap(result)
                    }) {
                        Text(result.text)
                            .font(.caption)
                            .padding(6)
                            .background(Color.blue.opacity(0.7))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .position(
                        x: imageWidth * result.x * scale + offset.width,
                        y: imageHeight * result.y * scale + offset.height
                    )
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

