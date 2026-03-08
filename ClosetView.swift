//
//  ClosetView.swift
//  OOTD.AI
//

import SwiftUI
import UIKit


// MARK: - Image Picker Wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) { self.parent = parent }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let img = info[.originalImage] as? UIImage {
                parent.onImagePicked(img)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Closet View

struct ClosetView: View {
    
    // Shared closet
    @EnvironmentObject var closetVM: ClosetViewModel
    
    // Sections
    private let sections = ["Jackets", "Shirts", "Pants", "Shoes"]
    
    // Picker state
    @State private var showSourceDialog = false
    @State private var showImagePicker = false
    @State private var showCategoryPicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    
    @State private var pendingImage: UIImage? = nil
    @State private var activeSection: String? = nil   // which section "+" came from
    
    // DELETE state
    @State private var showDeletePrompt = false
    @State private var itemToDelete: ClosetItem? = nil
    @State private var deleteSection: String? = nil
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 30) {
                
                // HEADER
                HStack {
                    // Camera (take photo)
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            pickerSource = .camera
                            activeSection = nil
                            showImagePicker = true
                        }
                    } label: {
                        Image(systemName: "camera.fill")
                            .resizable()
                            .frame(width: 32, height: 26)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("MY CLOSET")
                        .font(.largeTitle.bold().italic())
                    
                    Spacer()
                    
                    // Global add (choose category after)
                    Button {
                        activeSection = nil
                        showSourceDialog = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // SECTIONS
                ForEach(sections, id: \.self) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text(section)
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        carousel(for: section)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        
        // SOURCE PICKER (Camera vs Photos)
        .confirmationDialog("Add Item", isPresented: $showSourceDialog) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    pickerSource = .camera
                    showImagePicker = true
                }
            }
            
            Button("Choose From Photos") {
                pickerSource = .photoLibrary
                showImagePicker = true
            }
            
            Button("Cancel", role: .cancel) {}
        }
        
        // IMAGE PICKER
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: pickerSource) { img in
                pendingImage = img
                
                if let section = activeSection {
                    // Section-specific +
                    finalizeAdd(to: section)
                } else {
                    // Global +
                    showCategoryPicker = true
                }
            }
        }
        
        // CATEGORY PICKER (only for global +)
        .confirmationDialog("Choose Category",
                            isPresented: $showCategoryPicker) {
            Button("Jackets") { finalizeAdd(to: "Jackets") }
            Button("Shirts")  { finalizeAdd(to: "Shirts") }
            Button("Pants")   { finalizeAdd(to: "Pants") }
            Button("Shoes")   { finalizeAdd(to: "Shoes") }
            Button("Cancel", role: .cancel) {}
        }
        
        // DELETE CONFIRMATION
        .confirmationDialog("Remove this item?",
                            isPresented: $showDeletePrompt,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteItem()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - Carousel
    
    func carousel(for section: String) -> some View {
        let items = closetVM.items(for: section)
        
        return GeometryReader { outerGeo in
            if items.isEmpty {
                // Empty state → centered +
                HStack {
                    Spacer()
                    addCard(for: section)
                    Spacer()
                }
                .frame(height: 200)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 22) {
                        ForEach(items) { item in
                            GeometryReader { geo in
                                let frame = geo.frame(in: .global)
                                let cardCenter = frame.midX
                                let screenCenter = outerGeo.frame(in: .global).midX
                                
                                let distance = abs(cardCenter - screenCenter)
                                let normalized = min(distance / 300, 1)
                                let scale = 1 - (0.5 * normalized)
                                let opacity = 1 - (0.6 * normalized)
                                let direction = cardCenter - screenCenter
                                let angle = Angle(degrees: Double(direction / 25))
                                
                                Image(uiImage: item.uiImage ?? UIImage(systemName: "photo")!)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 160, height: 210)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(radius: 8)
                                    .rotation3DEffect(
                                        angle,
                                        axis: (x: 0, y: 1, z: 0),
                                        perspective: 0.8
                                    )
                                    .scaleEffect(scale)
                                    .opacity(opacity)
                                    .animation(.easeInOut(duration: 0.25), value: normalized)
                                    .onLongPressGesture {
                                        itemToDelete = item
                                        deleteSection = section
                                        showDeletePrompt = true
                                    }
                            }
                            .frame(width: 160, height: 210)
                        }
                        
                        addCard(for: section)
                            .frame(width: 160, height: 210)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .frame(height: 240)
            }
        }
        .frame(height: 240)
    }
    
    // MARK: - Add card
    
    @ViewBuilder
    func addCard(for section: String) -> some View {
        Button {
            activeSection = section
            showSourceDialog = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.3), lineWidth: 2)
                    .frame(width: 160, height: 210)
                
                Image(systemName: "plus")
                    .font(.system(size: 34))
                    .foregroundColor(.black.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Add / Delete
    
    func finalizeAdd(to section: String) {
        guard let img = pendingImage else { return }
        let item = ClosetItem(name: "New Item", uiImage: img)
        
        closetVM.add(item, to: section)
        
        pendingImage = nil
        activeSection = nil
    }
    
    func deleteItem() {
        guard let item = itemToDelete,
              let section = deleteSection else { return }
        
        closetVM.delete(item, from: section)
        itemToDelete = nil
        deleteSection = nil
    }
}

#Preview {
    ClosetView()
        .environmentObject(ClosetViewModel())
}
