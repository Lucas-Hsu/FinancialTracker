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
    @State private var lastZoomScale: CGFloat = .zero
    private let minZoomScale : CGFloat = 1
    private let maxZoomScale : CGFloat = 3.0
    @State private var offset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero
    
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
                    .offset(x: offset.width, y: offset.height)
                    .scaleEffect(scale, anchor: .center)
                    .gesture(
                        SimultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastDragOffset.width + value.translation.width,
                                        height: lastDragOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { value in
                                    lastDragOffset = offset
                                },
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = min(max(lastZoomScale * value, minZoomScale), maxZoomScale)
                                }
                                .onEnded { value in
                                    lastZoomScale = scale
                                }
                        )
                    )
                
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
                            x: ( imageWidth * (result.x-0.5) + offset.width ) * scale  + size.width/2,
                            y: ( imageHeight * (result.y-0.5) + offset.height ) * scale + size.height/2
                        )
                }
                
                Button(action: {
                    scale = 1
                    lastZoomScale = scale
                    offset = .zero
                    lastDragOffset = offset
                }) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.blue))
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 4)
                }
                    .padding(10)
                    .position( x: size.width * 0.5,
                               y: size.height * 0.9 )
            }
                .frame(width: size.width, height: size.height)
        }
    }
}
