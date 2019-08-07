//
//  ViewController.swift
//  FilterApp
//
//  Created by Absoluit on 04/08/2019.
//  Copyright © 2019 Absoluit. All rights reserved.
//

import UIKit
import CoreImage
import FBSDKShareKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, SharingDelegate {
    
    struct Filter {
        let filterName: String
        var filterEffectValue: Any?
        var filterEffectValueName: String?
        
        init(filterName: String, filterEffectValue: Any?, filterEffectValueName: String?) {
            self.filterName = filterName
            self.filterEffectValue = filterEffectValue
            self.filterEffectValueName = filterEffectValueName
        }
    }
    
    @IBOutlet weak var shareBtn: UIBarButtonItem!
    @IBOutlet weak var imageToShow: UIImageView!
    @IBOutlet weak var detailsLbl: UILabel!
    
    @IBOutlet weak var filterCollectionView: UICollectionView!
    
    var imagePicker = UIImagePickerController()
    var orignalImage = UIImage()
    
    var filterNameArray = [
                           "CIPhotoEffectChrome",
                           "CIColorPosterize",
                           "CIColorMonochrome",
                           "CIPhotoEffectFade",
                           "CIFalseColor",
                           "CIPhotoEffectProcess",
                           "CIMinimumComponent",
                           "CIPhotoEffectInstant",
                           "CIPhotoEffectMono",
                           "CIPhotoEffectNoir",
                           "CIPhotoEffectTonal",
                           "CIPhotoEffectTransfer",
                           "CIMaximumComponent",
                           "CIColorInvert"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        shareBtn.isEnabled = false
        filterCollectionView.isHidden = true
        
        imagePicker.delegate = self
        
    }


    // MARK:- IBActions
    @IBAction func addAction(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController.init(title: "Take Photo", message: "Please select from where you wanna take photo", preferredStyle: .alert)
        alertController.addAction(UIAlertAction.init(title: "Gallery", style: .default, handler: { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
                self.imagePicker.delegate = self
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }))
        alertController.addAction(UIAlertAction.init(title: "Camera", style: .default, handler: { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.camera){
                self.imagePicker.delegate = self
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }))
        alertController.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func shareAction(_ sender: UIBarButtonItem) {
        let shareController = UIAlertController.init(title: nil, message: nil , preferredStyle: .actionSheet)
        shareController.addAction(UIAlertAction.init(title: "Save to Library", style: .default, handler: { (action) in
            UIImageWriteToSavedPhotosAlbum(self.imageToShow.image!, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }))
        
        shareController.addAction(UIAlertAction.init(title: "Share on Facebook", style: .default, handler: { (action) in
            self.shareonFacebook()
        }))
        
        shareController.addAction(UIAlertAction.init(title: "Share", style: .default, handler: { (action) in
            self.basicShare()
        }))
        
        shareController.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(shareController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        imageToShow.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        self.detailsLbl.isHidden = true
        self.shareBtn.isEnabled = true
        self.filterCollectionView.isHidden = false
        
        self.orignalImage = imageToShow.image!
    }
    
    
    func shareonFacebook(){
        let photo = SharePhoto(image: self.imageToShow.image!, userGenerated: true)
        let content = SharePhotoContent()
        content.photos = [photo]
        let showDialog = ShareDialog(fromViewController: self, content: content, delegate: self)
        showDialog.show()
    }
    
    func basicShare(){
        // image to share
        let image = self.imageToShow.image
        
        // set up activity view controller
        let imageToShare = [ image! ]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    //MARK: - Add image to Library
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    // MARK:- Filters
    private func applyFilterTo(image: UIImage, filterEffect: Filter) -> UIImage? {
        guard let cgImage = image.cgImage, let openGLContext = EAGLContext.init(api: .openGLES3) else {
            return nil
        }
        
        let context = CIContext.init(eaglContext: openGLContext)
        let ciImage = CIImage.init(cgImage: cgImage)
        let filter = CIFilter.init(name: filterEffect.filterName)
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        if let filterEffectValue = filterEffect.filterEffectValue,
            let filterEffectValueName = filterEffect.filterEffectValueName{
            filter?.setValue(filterEffectValue, forKey: filterEffectValueName)
        }
        
        var filteredImage: UIImage?
        if let output = filter?.value(forKey: kCIOutputImageKey) as? CIImage,
            let cgiImageResult = context.createCGImage(output, from: output.extent){
            filteredImage = UIImage.init(cgImage: cgiImageResult)
        }
        
        return filteredImage
    }
    
    // MARK:- UICollectionView Methods
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filterNameArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.filterCollectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! FilterCell
        let name = "\(indexPath.row + 1)"
        cell.filterImg.image = UIImage.init(named: name)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let image = imageToShow.image else{
            return
        }
        
        imageToShow.image = orignalImage
        
        let filterName = filterNameArray[indexPath.row]
        print("filterName: \(indexPath.row) \(filterName)")
        let filter = Filter.init(filterName: filterName, filterEffectValue: nil, filterEffectValueName: kCIInputIntensityKey)
        imageToShow.image = applyFilterTo(image: imageToShow.image!, filterEffect: filter)
    }
    
    // MARK:- FB Sharing
    func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        print(error)
    }
    
    func sharerDidCancel(_ sharer: Sharing) {
        
    }
    
    func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        
    }
    
}

