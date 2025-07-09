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

            // Calculate the center offset for the image based on the available space
            let imageXOffset = (size.width - imageWidth) / 2
            let imageYOffset = (size.height - imageHeight) / 2

            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageWidth, height: imageHeight)
                    .offset(x: imageXOffset + offset.width, y: offset.height)
                    .scaleEffect(scale, anchor: .center) // Ensure zoom is centered
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

                // Position the OCR results relative to the image
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
                    // Position relative to image scaling and offsets
                    .position(
                        x: imageXOffset + imageWidth * result.x * scale + offset.width,
                        y: imageYOffset + imageHeight * result.y * scale + offset.height
                    )
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }
}
