//
//  ReceiptImageView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 12/21/25.
//

import SwiftUI
import PhotosUI

/// The view for select and OCR of receipt images
struct ReceiptImageView: View
{
    // MARK: - Binding Attributes
    @Binding var receiptData: Data?
    
    // MARK: - Private  Attributes
    @State private var viewModel = ReceiptImageViewModel()
    @State private var pickerViewModel = ReceiptImagePickerViewModel()
    @State private var isCameraPresented: Bool = false
    @State private var isLibraryPresented: Bool = false
    
    // MARK: - UI
    var body: some View
    {
        VStack
        {
            if viewModel.uiImage != nil
            {
                // MARK: Image & OCR Display
                imageDisplayArea
            }
            else
            {
                // MARK: Initial Selection Buttons
                initialSelectionButtons
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
                 .stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        .onAppear
        {
            if let data = receiptData, viewModel.uiImage == nil, let img = UIImage(data: data)
            { viewModel.setImage(img) }
        }
        .onChange(of: viewModel.uiImage)
        { _, _ in
            receiptData = viewModel.getCompressedData()
        }
        // Photo Library
        .onChange(of: pickerViewModel.selectedItem)
        { _, newItem in
            pickerViewModel.loadTransferable(from: newItem)
            { image in
                if let image = image
                { viewModel.setImage(image) }
            }
        }
        // Camera Sheet
        .sheet(isPresented: $isCameraPresented)
        {
            ReceiptImageCamera(sourceType: .camera)
            { image in
                viewModel.setImage(image)
            }
        }
    }
    
    // MARK: - Components
    // Image Selection Buttons
    private var initialSelectionButtons: some View
    {
        VStack(spacing: 20)
        {
            Image(systemName: "doc.text.viewfinder")
            .font(.system(size: 40))
            .foregroundColor(.secondary)
            Text("Add Receipt")
            .font(.headline)
            .foregroundColor(.secondary)
            HStack(spacing: 20)
            {
                // Photo Library Button
                PhotosPicker(selection: $pickerViewModel.selectedItem, matching: .images)
                {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .padding()
                    .frame(height: 50)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                // Camera Button
                Button(action: { isCameraPresented = true })
                {
                    Label("Take Photo", systemImage: "camera")
                    .font(.headline)
                    .padding()
                    .frame(height: 50)
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                }
            }
        }
    }
    // Image Area Background
    private var imageDisplayArea: some View
    {
        ZStack
        {
            // Image + bubbles
            GeometryReader
            { geometry in
                if let image = viewModel.uiImage
                {
                    // alignment center -> Image and bubbles same anchor point.
                    ZStack(alignment: .center)
                    {
                        Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .opacity(viewModel.isProcessing ? 0.4 : 1.0)
                        .grayscale(viewModel.isProcessing ? 1.0 : 0.0)
                        // OCR Bubbles Overlay
                        if !viewModel.isProcessing
                        { AllBubbles(imageSize: image.size, viewSize: geometry.size) }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(viewModel.scale)
                    .offset(viewModel.offset)
                    .gesture(makeGestures())
                }
            }
            .clipped()
            // Loading Indicator
            if viewModel.isProcessing
            {
                ProgressView("Recognizing Text...")
                .padding()
                .background(Color(UIColor.secondaryLabel).opacity(0.4))
                .cornerRadius(10)
            }
            // Floating Controls
            VStack
            {
                Spacer()
                HStack(spacing: 12)
                {
                    // Reset Transform
                    FloatingButtonGlass(icon: "arrow.counterclockwise")
                    { withAnimation { viewModel.resetTransformations() } }
                    Spacer()
                    // Clear Image
                    FloatingButtonGlass(icon: "xmark", color: .red)
                    { viewModel.clear() }
                    // New Camera
                    FloatingButtonGlass(icon: "camera")
                    { isCameraPresented = true }
                    // New Library
                    PhotosPicker(selection: $pickerViewModel.selectedItem, matching: .images)
                    {
                        if #available(iOS 26.0, *)
                        {
                            Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                            .glassEffect(.regular.tint(Color.accentColor).interactive())
                        }
                        else
                        {
                            Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                        }
                    }
                }
                .padding()
            }
        }
    }
    // all the bubbles
    private func AllBubbles(imageSize: CGSize, viewSize: CGSize) -> some View
    {
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height
        var renderW: CGFloat
        var renderH: CGFloat
        if imageAspect > viewAspect // Fit by width
        {
            renderW = viewSize.width
            renderH = viewSize.width / imageAspect
        }
        else // by height
        {
            renderH = viewSize.height
            renderW = viewSize.height * imageAspect
        }
        let offX = (viewSize.width - renderW) / 2
        let offY = (viewSize.height - renderH) / 2
        // Allow bubbles to remain same size even as image zooms in
        let bubbleScale = 1.0 / max(1.0, viewModel.scale)
        return ForEach(viewModel.ocrBubbles)
        { bubble in
            // vision rect (x, y, w, h) is normalized.
            let bX = bubble.rect.minX * renderW + offX
            let bY = (1 - bubble.rect.maxY) * renderH + offY // (0,0) is bottom-left so need conert to (0,0) top-left
            let bW = bubble.rect.width * renderW
            let bH = bubble.rect.height * renderH
            OCRBubbleGlass(text: bubble.text, rect: bubble.rect)
            .scaleEffect(bubbleScale)
            .position(x: bX + bW/2, y: bY + bH/2)
        }
    }
    // Gestures for image transformation
    private func makeGestures() -> some Gesture
    {
        SimultaneousGesture(
            MagnificationGesture()
            .onChanged
            { val in
                let delta = val / viewModel.lastScale
                viewModel.lastScale = val
                viewModel.scale *= delta
            }
            .onEnded
            { _ in
                viewModel.lastScale = 1.0
                // No zooming out too far
                if viewModel.scale < 1.0 { withAnimation { viewModel.scale = 1.0 } }
            },
            DragGesture()
            .onChanged
            { val in
                let delta = CGSize(width: val.translation.width - viewModel.lastOffset.width,
                                   height: val.translation.height - viewModel.lastOffset.height)
                viewModel.offset.width += delta.width
                viewModel.offset.height += delta.height
                viewModel.lastOffset = val.translation
            }
            .onEnded
            { _ in
                viewModel.lastOffset = .zero
            }
        )
    }
}
