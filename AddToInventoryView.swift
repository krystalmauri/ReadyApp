//
//  AddToInventoryView.swift
//  Ready4Pickup
//
//  Created by Krys Welch on 11/16/22.
//

import SwiftUI
import Combine

struct AddToInventoryView: View {
    
    @State var itemName = ""
    @State var itemDescription = ""
    @State var price = ""
    @State var quantity = ""
    @State var defaultImg = ""
    @State var shouldShowImagePicker = false
    @State var shouldShowNewMessageScreen = false
    var itemIDString = String.random(of: 12)
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var imageMessage = "(you can add more later)"
    
    @State var image: UIImage?
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Inventory Details")) {
                    TextField("Name", text: $itemName)
                    TextField("Description (up to 350 characters)", text: $itemDescription, axis: .vertical)
                    TextField("Price in USD ($)", text: $price)
                        .keyboardType(.decimalPad)
                                .onReceive(Just(price)) { newValue in
                                    let filtered = newValue.filter { "0123456789.".contains($0) }
                                    if filtered != newValue {
                                        self.price = filtered
                                    }
                                }
                    TextField("Quantity", text: $quantity)
                                .keyboardType(.numberPad)
                                .onReceive(Just(price)) { newValue in
                                    let filtered = newValue.filter { "0123456789.".contains($0) }
                                    if filtered != newValue {
                                        self.price = filtered
                                    }
                                }
                 
                    Button{
                         shouldShowImagePicker.toggle()
                    }label: {
                        
                        Text(imageMessage)
                            .padding()
                        
                        HStack(alignment: .center, spacing: 6){
                            Spacer()
                            if let image = self.image{
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height:200)
                                    .clipped()
                                
                            } else{
                                
                                Image("Logo")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width:200, height: 200)
                                    .clipped()
                                
                            }
                            Spacer()
                        }
                        
                    }
                    
                    
                }
                
                addToInventoryButton
            }.navigationBarTitle("Add To Inventory")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button{
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Cancel")
                        }
                    }
                }
                //.background(Image("Logo"))
                .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil){
                    ImagePicker(image: $image)
                }
        }
        
    }
    
    private var addToInventoryButton: some View{
        Button {
            shouldShowNewMessageScreen.toggle()
            handleAction()
        } label: {
            HStack {
                Spacer()
                Text("Add To Inventory")
                Spacer()
            }
            .foregroundColor(.black)
            .padding(.vertical)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 5)
            
        }
        
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen){
           InventoryView()
        }
    }

    
    private func persistImageToStorage(){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else {return}
        let ref = FirebaseManager.shared.storage.reference(withPath: "\(uid)/inventory/\(self.itemIDString)/")
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else {return}
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
            print("Failed to append image to storage \(err)")
                return
            }
            ref.downloadURL { url, err in
                if let err = err {
                print("Failed to append image to storage \(err)")
                    return
                }
                guard let url = url else {return}
                self.saveUserData(imageURL: url)
                
            }
        }
    }
    
    private func saveUserData(imageURL: URL){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else{
            return
        }
        let userData = ["name": self.itemName, "id": self.itemIDString, "description": self.itemDescription, "quantity": self.quantity, "price": self.price, "defaultImg": imageURL.absoluteString,  "created": Date()] as [String : Any]
        FirebaseManager.shared.firestore.collection("users").document(uid).collection("inventory").document(self.itemIDString).setData(userData) { err in
            if let err = err {
                print(err)
                return
            }
            print("success")
          //  self.didCompleteLogin()
        }
    }
    
    private func handleAction(){
     
            createUser()
        
    }
    
    private func createUser() {
        if self.image == nil {
            self.defaultImg = "photo.fill"
            self.persistImageToStorage()
        } else{
            self.imageMessage = "Looks good!"
            self.persistImageToStorage()
        }
        }
     
}

struct AddToInventoryView_Previews: PreviewProvider {
    static var previews: some View {
        AddToInventoryView()
    }
}
