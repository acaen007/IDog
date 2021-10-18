//
//  ViewController.swift
//  WhatFlower
//
//  Created by Andy Caen on 9/28/21.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    var pickedImage : UIImage?

    
    @IBOutlet weak var imageView: UIImageView!
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

    
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
                
                guard let convertedCIImage = CIImage(image: userPickedImage) else {
                    fatalError("could not convert image to CIImage")
                }
                
                
                detect(image: convertedCIImage)
            }
        
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage){
        
        guard let model = try? VNCoreMLModel(for: dogClassifier().model) else{
            fatalError("cannot import model")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("could not get classification")
            }
            
            let dogName = classification.identifier.dropFirst(10)
            
            
            self.navigationItem.title = dogName.capitalized + " " + String(format:"%.2f", classification.confidence)
            self.requestInfo(dogName: String(dogName))
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(dogName:String){
        
        let parameters : [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts|pageimages",
        "exintro" : "",
        "explaintext" : "",
        "titles" : dogName,
        "indexpageids" : "",
        "redirects" : "1",
        "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                print("got the wikipedia info")
            }
            
            let dogJSON : JSON = JSON(response.result.value!)
            
            print(dogJSON)
            
            let pageid = dogJSON["query"]["pageids"][0].stringValue
            
            let dogDescription = dogJSON["query"]["pages"][pageid]["extract"].stringValue
            
            let dogImageURL = dogJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
            
            print("hey" + dogDescription)
            
            self.imageView.sd_setImage(with: URL(string: dogImageURL))
            
            self.label.text = dogDescription
        }
        
    }
    
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}

