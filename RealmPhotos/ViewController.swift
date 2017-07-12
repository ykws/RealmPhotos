//
//  ViewController.swift
//  RealmPhotos
//
//  Created by Yoshiyuki Kawashima on 2017/07/12.
//  Copyright © 2017 ykws. All rights reserved.
//

import UIKit
import RealmSwift
import Keys

// MARK: - Model

final class PhotoList: Object {
  dynamic var text = ""
  dynamic var id = ""
  let items = List<Photo>()
  
  override static func primaryKey() -> String? {
    return "id"
  }
}

final class Photo: Object {
  dynamic var text = ""
  dynamic var _image: UIImage? = nil
  dynamic var image: UIImage? {
    set {
      _image = newValue
      if let value = newValue {
        let size = value.size.applying(CGAffineTransform(scaleX: 0.5, y: 0.5))
        UIGraphicsBeginImageContext(size)
        value.draw(in: CGRect.init(origin: .zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        imageData = UIImagePNGRepresentation(scaledImage!) as NSData?
      }
    }
    get {
      if let image = _image {
        return image
      }
      if let data = imageData {
        _image = UIImage(data: data as Data)
        return _image
      }
      return nil
    }
  }
  dynamic var imageData: NSData? = nil
  
  override static func ignoredProperties() -> [String] {
    return ["image", "_image"]
  }
}

class ViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  // MARK: - Properties
  
  var items = List<Photo>()
  var notificationToken: NotificationToken!
  var realm: Realm!

  // MARK: - Actions
  
  @IBAction func add(_ sender: Any) {
    let imagePicker = UIImagePickerController()
    imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
    if UIImagePickerController.isSourceTypeAvailable(imagePicker.sourceType) {
      imagePicker.delegate = self
      present(imagePicker, animated: true, completion: nil)
    }
  }
  
  // MARK: - Life Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupRealm()
  }
  
  // MARK: - TableView
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let item = items[indexPath.row]
    cell.imageView?.image = item.image
    cell.textLabel?.text = item.text
    return cell
  }
  
  // MARK: - Navigation Controller Delegate
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
      let photo = Photo()
      photo.image = image

      picker.dismiss(animated: true, completion: {
        let alertController = UIAlertController(title: "New Photo", message: "Enter photo info", preferredStyle: .alert)
        var alertTextField: UITextField!
        alertController.addTextField { textField in
          alertTextField = textField
          textField.placeholder = "Photo Name"
        }
        alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
          guard let text = alertTextField.text, !text.isEmpty else { return }

          photo.text = text
          let items = self.items
          try! items.realm?.write {
            items.append(photo)
          }
        })
        self.present(alertController, animated: true, completion: nil)
      })
    }
  }
  
  // MARK: - Realm
  
  func setupRealm() {
    let keys = RealmPhotosKeys()
    let username = keys.realmUsername
    let password = keys.realmPassword
    
    SyncUser.logIn(with: .usernamePassword(username: username, password: password, register: false), server: URL(string: "http://127.0.0.1:9080")!) { user, error in
      guard let user = user else {
        fatalError(String(describing: error))
      }
      
      DispatchQueue.main.async {
        let configuration = Realm.Configuration(
          syncConfiguration: SyncConfiguration(user: user, realmURL: URL(string: "realm://127.0.0.1:9080/~/realmphotos")!)
        )
        self.realm = try! Realm(configuration: configuration)
        
        func updateList() {
          if self.items.realm == nil, let list = self.realm.objects(PhotoList.self).first {
            self.items = list.items
          }
          self.tableView.reloadData()
        }
        updateList()
        
        self.notificationToken = self.realm.addNotificationBlock { _ in
          updateList()
        }
      }
    }
  }
  
  deinit {
    notificationToken.stop()
  }
  
}

