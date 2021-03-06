//
//  EnterYourWeightViewController.swift
//  WeightLogger
//
//  Created by Tony on 10/14/14.
//  Copyright (c) 2014 Abbouds Corner. All rights reserved.
//

import UIKit
import CoreData

// Global name for our local png photo
let noPhotoPNG = "no_photo.png"

class EnterYourWeightViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var photoFullURL: String!
    var photoThumbURL: String!
    
    @IBOutlet var photoPreview: UIImageView!
    @IBOutlet var txtWeight : UITextField!
    @IBOutlet var units : UISwitch!
    
    @IBAction func btnSavePressed(sender : AnyObject) {
        // Check if the user entered a weight
        if let weight = txtWeight.text{
            if weight.isEmpty == false{
                let appDel: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
                let context: NSManagedObjectContext = appDel.managedObjectContext
                
                
                let ent = NSEntityDescription.entityForName("UserWeights", inManagedObjectContext: context)!
                
                //Instance of our custom class, reference to entity
                let newWeight = UserWeights(entity: ent, insertIntoManagedObjectContext: context)
                
                // Fill in the Core Data
                newWeight.weight = weight
                if(units.on){
                    newWeight.units = "lbs"
                }else{
                    //Switch is off
                    newWeight.units = "kgs"
                }
                
                let dateFormatter = NSDateFormatter()
                let curLocale: NSLocale = NSLocale.currentLocale()
                let formatString: NSString = NSDateFormatter.dateFormatFromTemplate("EdMMM h:mm a", options: 0, locale: curLocale)!
                dateFormatter.dateFormat = formatString as String
                newWeight.date = dateFormatter.stringFromDate(NSDate())
                
                
                // Save the reference to photo (i.e. URL) to CoreData
                if(self.photoFullURL == nil){
                    let URL = NSURL(fileURLWithPath: noPhotoPNG).absoluteString
                    newWeight.photoFullURL = URL
                    newWeight.photoThumbURL = URL
                }else{
                    newWeight.photoFullURL = self.photoFullURL
                    newWeight.photoThumbURL = self.photoThumbURL
                }
                
                do {
                    try context.save()
                } catch _ {
                }
                
                // Reset all parameters upon saving
                resetParameters()
            }else{
                //User carelessly pressed save button without entering weight.
                var alert:UIAlertController = UIAlertController(title: "No Weight Entered", message: "Enter your weight before pressing save.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: {(result)in
                    alert.dismissViewControllerAnimated(true, completion: nil)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }else{
            print("No element text for the UITextField 'txtWeight'")
        }
    }
    
    @IBAction func btnPhotoLibPressed(sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.sourceType = .PhotoLibrary
        picker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary)!
        picker.delegate = self
        picker.allowsEditing = false
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    @IBAction func btnCameraPressed(sender: AnyObject) {
        if(UIImagePickerController.isSourceTypeAvailable(.Camera)){
            let picker = UIImagePickerController()
            picker.sourceType = .Camera
            picker.delegate = self
            picker.allowsEditing = false
            self.presentViewController(picker, animated: true, completion: nil)
        }else{
            //no camera available
            let alert = UIAlertController(title: "Error", message: "There is no camera available!", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .Default,
                handler: {(alertAction)in
                    alert.dismissViewControllerAnimated(true, completion: nil)
                }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetParameters()
    }
    override func viewWillAppear(animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
// UIImagePickerControllerDelegate Methods
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]){
        let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0), {
            // Scale the original image down before saving it (Good Practice)
            
            // Get the screen size for the target device
            let screenSize: CGSize = UIScreen.mainScreen().bounds.size
            let newImage: UIImage = self.scaledImageWithImage(image, size: CGSize(width: screenSize.width, height: screenSize.height))
            
            dispatch_async(dispatch_get_main_queue(), {
                    self.photoPreview.image = newImage
                    picker.dismissViewControllerAnimated(true, completion: nil)
            })
            // Get path to the Documents Dir.
            let paths: NSArray = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            let documentsDir: NSString = paths.objectAtIndex(0) as! NSString
            
            // Get current date and time for unique name
            let dateFormat = NSDateFormatter()
            dateFormat.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            let now:NSDate = NSDate(timeIntervalSinceNow: 0)
            let theDate: NSString = dateFormat.stringFromDate(now)
            
            // Set URL for the full screen image
            self.photoFullURL = NSString(format: "/%@.png", theDate) as String
            
            // Save the full screen image via pngData
            let pathFull: NSString = documentsDir.stringByAppendingString(self.photoFullURL)
            let pngFullData: NSData = UIImagePNGRepresentation(newImage)!
            pngFullData.writeToFile(pathFull as String, atomically: true)
            
            //  Create the thumbnail from the original image
            let thumbnailImage: UIImage = self.scaledImageWithImage(newImage, size: CGSize(width: 100, height: 100))
            self.photoThumbURL = NSString(format: "/%@_THUMB.png", theDate) as String
            
            // Save the thumbnail image
            let pathThumb: NSString = documentsDir.stringByAppendingString(self.photoThumbURL)
            let pngThumbData: NSData = UIImagePNGRepresentation(thumbnailImage)!
            pngThumbData.writeToFile(pathThumb as String, atomically: true)
        })
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController){
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    

// My Methods
    
// Scale the photos
    func scaledImageWithImage(image: UIImage, size: CGSize) -> UIImage{
        let scale: CGFloat = max(size.width/image.size.width, size.height/image.size.height)
        let width: CGFloat = image.size.width * scale
        let height: CGFloat  = image.size.height * scale
        let imageRect: CGRect = CGRectMake((size.width-width)/2.0, (size.height - height)/2.0, width, height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        image.drawInRect(imageRect)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }

// Reset all local parameters
    func resetParameters(){
        self.photoFullURL = nil
        txtWeight.text = ""
        self.photoPreview.image = UIImage(named: noPhotoPNG)
    }
}
























