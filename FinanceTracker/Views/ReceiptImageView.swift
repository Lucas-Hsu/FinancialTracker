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
        .background(.clear)
        .cornerRadius(16)
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
        VStack(spacing: 40)
        {
            VStack(spacing: 20)
            {
                Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 120, weight: .thin))
                .foregroundColor(.secondary)
                Text("Add Receipt Image")
                    .font(.system(size: 32, weight: .regular))
                .foregroundColor(.secondary)
            }
            HStack(spacing: 20)
            {
                // Photo Library Button
                PhotosPicker(selection: $pickerViewModel.selectedItem, matching: .images)
                {
                    Group
                    {
                        if #available(iOS 26.0, *)
                        {
                            photoLibraryButton
                            .background(.clear)
                            .glassEffect(.regular.tint(Color.accentColor).interactive(), in: Capsule())
                        }
                        else
                        {
                            photoLibraryButton
                            .background(Color.accentColor)
                        }
                    }
                    .shadow(color: defaultButtonShadowColor, radius: 3, x: 0, y: 3)
                }
                // Camera Button
                TintedLabelButtonGlass(imageSystemName: "photo.on.rectangle",
                                       text: "Photo Library",
                                       tint: Color.white,
                                       color: Color(UIColor.systemGray),
                                       action: { isCameraPresented = true })
                .shadow(color: defaultButtonShadowColor.opacity(0.4), radius: 4, x: 0, y: 3)
            }
        }
    }
    // Photo Library Button
    private var photoLibraryButton: some View
    {
        Label("Photo Library", systemImage: "photo.on.rectangle")
        .font(.headline)
        .padding()
        .frame(height: 50)
        .foregroundColor(.white)
        .clipShape(Capsule())
    }
    // Image Area Background
    private var imageDisplayArea: some View
    {
        ZStack
        {
            // Image + bubbles
            geometryReader
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
                    .shadow(color: defaultButtonShadowColor, radius: 4, x: 0, y: 3)
                    Spacer()
                    // Clear Image
                    FloatingButtonGlass(icon: "xmark", color: .red)
                    { viewModel.clear() }
                    .shadow(color: defaultButtonShadowColor, radius: 4, x: 0, y: 3)
                    // New Camera
                    FloatingButtonGlass(icon: "camera")
                    { isCameraPresented = true }
                    .shadow(color: defaultButtonShadowColor, radius: 4, x: 0, y: 3)
                    // New Library
                    PhotosPicker(selection: $pickerViewModel.selectedItem, matching: .images)
                    {
                        if #available(iOS 26.0, *)
                        {
                            floatingPhotoPicker
                            .glassEffect(.regular.tint(Color.accentColor).interactive())
                        }
                        else
                        { floatingPhotoPicker }
                    }
                    .shadow(color: defaultButtonShadowColor, radius: 4, x: 0, y: 3)
                }
                .padding()
            }
        }
    }
    // The Floating Photo Picker
    private var floatingPhotoPicker: some View
    {
        Image(systemName: "photo.on.rectangle")
        .font(.title3)
        .foregroundColor(.white)
        .frame(width: 44, height: 44)
        .background(Color.accentColor)
        .clipShape(Circle())
    }
    // The image and the receipt
    private var geometryReader: some View
    {
        GeometryReader
        { geometry in
            if let image = viewModel.uiImage
            {
                ZStack(alignment: .center)
                {
                    // Receipt
                    Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .opacity(viewModel.isProcessing ? 0.4 : 1.0)
                    .grayscale(viewModel.isProcessing ? 1.0 : 0.0)
                    // Bubbles
                    if !viewModel.isProcessing
                    {
                        ZStack
                        { AllBubbles(imageSize: image.size, viewSize: geometry.size) }
                        .drawingGroup()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.clear)
                .scaleEffect(viewModel.scale)
                .offset(viewModel.offset)
                .animation(nil, value: viewModel.scale)
                .animation(nil, value: viewModel.offset)
                .gesture(makeGestures())
            }
        }
        .background(.clear)
        .clipped()
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
        let bubbleScale = 1.0 / max(1.0, viewModel.scale) // Allow bubbles to remain same size even as image zooms in
        return ForEach(viewModel.ocrBubbles)
        { bubble in
            // vision rect (x, y, w, h) is normalized.
            let bX = bubble.rect.minX * renderW + offX
            let bY = (1 - bubble.rect.maxY) * renderH + offY // (0,0) is bottom-left so need convert to (0,0) top-left
            let bW = bubble.rect.width * renderW
            let bH = bubble.rect.height * renderH
            OCRBubbleGlass(text: bubble.text, rect: bubble.rect)
            .scaleEffect(bubbleScale)
            .position(x: bX + bW/2, y: bY + bH/2)
        }
    }
    
    // MARK: - Private Helpers
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
                if viewModel.scale < 1.0
                { withAnimation { viewModel.scale = 1.0 } }
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
