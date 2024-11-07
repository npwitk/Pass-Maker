//
//  ContentView.swift
//  PassGenerator
//
//  Created by Nonprawich I. on 16/10/2024.
//

import SwiftUI
import PassKit
import Firebase
import FirebaseStorage

struct ContentView: View {
    @State private var qrText = "https://www.github.com/mentaln"
    @State private var thumbnailImageLink = "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png"
    
    @State private var primaryLabel = ""
    @State private var primaryValue = ""
    
    @State private var secondaryLabel1 = ""
    @State private var secondaryValue1 = ""
    
    @State private var secondaryLabel2 = ""
    @State private var secondaryValue2 = ""
    
    @State private var auxiliaryLabel1 = ""
    @State private var auxiliaryValue1 = ""
    
    @State private var auxiliaryLabel2 = ""
    @State private var auxiliaryValue2 = ""
    
    @State private var backgroundColor = Color.white
    @State private var textColor = Color.black
    
    @State private var isLoading = false
    
    @State private var newPass: PKPass?
    
    @State private var passSheetVisible = false
    
    let storageRef = Storage.storage().reference()
    
    func getColorHex(color: Color) -> String {
        let colorRGB = color.cgColor?.components!
        var colorHex = Color(red: Double(colorRGB![0]), green: Double(colorRGB![1]), blue: Double(colorRGB![2]), opacity: Double(colorRGB![3])).description
        colorHex = colorHex.replacingOccurrences(of: "#", with: "")
        if (colorHex == "black") {
            return "000000"
        }
        else if (colorHex == "white") {
            return "FFFFFF"
        }
        else {
            colorHex = colorHex.dropLast(2).description
            return colorHex
        }
    }
    
    func generatePass(completion: @escaping((Bool) -> () )) {
        let params: [String: Any] = [
            "qrText": self.qrText,
            "thumbnail": self.thumbnailImageLink,
            "primary": [
                "value": self.primaryValue,
                "label": self.primaryLabel
            ],
            "secondary": [
                [
                    "value": self.secondaryValue1,
                    "label": self.secondaryLabel1
                ],
                [
                    "value": self.secondaryValue2,
                    "label": self.secondaryLabel2
                ]
            ],
            "auxiliary": [
                [
                    "value": self.auxiliaryValue1,
                    "label": self.auxiliaryLabel1
                ],
                [
                    "value": self.auxiliaryValue2,
                    "label": self.auxiliaryLabel2
                ]
            ],
            "backgroundColor": self.getColorHex(color: self.backgroundColor),
            "textColor": self.getColorHex(color: self.textColor)
        ]
        
        var request = URLRequest(url: URL(string: "https://us-central1-npwitk-passmaker.cloudfunctions.net/pass")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! [String: Any]
                completion(json["result"]! as! String == "SUCCESS" ? true : false)
            } catch {
                print("error")
                completion(false)
            }
        }
        
        task.resume()
    }
    
    func downloadPass(completion: @escaping((Bool) -> () )) {
        self.storageRef.child("passes/custom.pkpass").getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error downloading resource: " + error.localizedDescription)
            }
            else {
                do {
                    let canAddPassResult = PKAddPassesViewController.canAddPasses()
                    if (canAddPassResult) {
                        print("Can add passes. Proceed with creating pass.")
                        self.newPass = try PKPass.init(data: data!)
                        completion(true)
                    }
                    else {
                        print("Can NOT add pass. Abort!")
                        completion(false)
                    }
                }
                catch {
                    print("Something is wrong.")
                    completion(false)
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            Form {
                Section("content") {
                    TextField("QR Text", text: self.$qrText)
                    TextField("Thumbnail Image URL", text: self.$thumbnailImageLink)
                }
                
                Section("Primary Fields") {
                    TextField("Label", text: self.$primaryLabel)
                    TextField("Value", text: self.$primaryValue)
                }
                
                Section("Secondary Fields") {
                    TextField("Label 1", text: self.$secondaryLabel1)
                    TextField("Value 1", text: self.$secondaryValue1)
                    
                    TextField("Label 2", text: self.$secondaryLabel2)
                    TextField("Value 2", text: self.$secondaryValue2)
                }
                
                Section("Auxiliary Fields") {
                    TextField("Label 1", text: self.$auxiliaryLabel1)
                    TextField("Value 1", text: self.$auxiliaryValue1)
                    
                    TextField("Label 2", text: self.$auxiliaryLabel2)
                    TextField("Value 2", text: self.$auxiliaryValue2)
                }
                
                Section("Colors") {
                    ColorPicker("Background Color", selection: self.$backgroundColor)
                    ColorPicker("Text Color", selection: self.$textColor)
                }
                
                Section("Add to wallet") {
                    if (!self.isLoading) {
                        AddPassToWalletButton {
                            self.isLoading = true
                            self.generatePass { generatePassResult in
                                if (generatePassResult) {
                                    self.downloadPass { downloadPassResult in
                                        if (downloadPassResult) {
                                            self.passSheetVisible = true
                                            self.isLoading = false
                                        }
                                        else {
                                            self.isLoading = false
                                            print("failed to download pass")
                                        }
                                    }
                                }
                                else {
                                    self.isLoading = false
                                    print("failed to generate pass")
                                }
                            }
                        }
                    }
                    else {
                        ProgressView()
                    }
                }
                
            }
            .navigationTitle("Pass Generator")
            .sheet(isPresented: self.$passSheetVisible) {
                AddPassView(pass: self.$newPass)
            }
        }
    }
}

#Preview {
    ContentView()
}
