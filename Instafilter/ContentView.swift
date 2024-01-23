//
//  ContentView.swift
//  Instafilter
//
//  Created by Kirill Baranov on 22/01/24.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import StoreKit
import SwiftUI

struct ContentView: View {
    
    @State private var processedImage: Image?
    @State private var selectedItem: PhotosPickerItem?
    
    //image filtering
    @State private var showingFilters = false
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 100.0
    @State private var filterScale = 5.0
    @State private var filterAngle = 0.5
    @State private var currentFilter: CIFilter = .sepiaTone()
    private let context = CIContext()
    
    //review
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                PhotosPicker(selection: $selectedItem) {
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView("No Picture", systemImage: "photo.badge.plus", description: Text("Import a photo to get started"))
                        
                    }
                    
                }
                .onChange(of: selectedItem, loadImage)
                
                Spacer()
                VStack {
                    HStack {
                        Text("Intensity")
                            .frame(width: 100)
                        Slider(value: $filterIntensity)
                            .disabled(processedImage == nil)
                            .onChange(of: filterIntensity, applyProcessing)
                    }
                    HStack {
                        Text("Radius")
                            .frame(width: 100)
                        Slider(value: $filterRadius, in: 0...200, step: 1)
                            .disabled(processedImage == nil)
                            .onChange(of: filterRadius, applyProcessing)
                    }
                    HStack {
                        Text("Scale")
                            .frame(width: 100)
                        Slider(value: $filterScale, in: 0...10, step: 1)
                            .disabled(processedImage == nil)
                            .onChange(of: filterScale, applyProcessing)
                    }
                    HStack {
                        Text("Angle")
                            .frame(width: 100)
                        Slider(value: $filterAngle)
                            .disabled(processedImage == nil)
                            .onChange(of: filterAngle, applyProcessing)
                    }
                }
                .padding(.vertical)
                HStack {
                    Button("Change Filter", action: changeFilter)
                        .disabled(processedImage == nil)
                    Spacer()
                    
                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("Instafilter image:", image: processedImage))
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .confirmationDialog("Select a filter", isPresented: $showingFilters) {
                Button("Crystallize") { setFilter(CIFilter.crystallize()) }
                Button("Edges") { setFilter(CIFilter.edges()) }
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                Button("Vignette") { setFilter(CIFilter.vignette()) }
                Button("Hue") { setFilter(CIFilter.hueAdjust())}
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    func changeFilter() {
        showingFilters.toggle()
        
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterScale, forKey: kCIInputScaleKey) }
        if inputKeys.contains(kCIInputAngleKey) {currentFilter.setValue(filterAngle, forKey: kCIInputAngleKey)}
        
        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        
        filterCount += 1
        
        if filterCount >= 5 {
            requestReview()
            filterCount = 0
        }
    }
}

#Preview {
    ContentView()
}
