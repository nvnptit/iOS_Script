import UIKit

struct TabItem: Codable {
    let iconWeb: Data?
    let titleWeb: String?
    let thumbnailWeb: Data?
    let urlWeb: String?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case iconWeb
        case titleWeb
        case thumbnailWeb
        case urlWeb
        case isActive
    }
    
    init(iconWeb: UIImage?, titleWeb: String?, thumbnailWeb: UIImage?, urlWeb: String?, isActive: Bool) {
        self.iconWeb = iconWeb?.pngData()
        self.titleWeb = titleWeb
        self.thumbnailWeb = thumbnailWeb?.pngData()
        self.urlWeb = urlWeb
        self.isActive = isActive
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        iconWeb = try container.decodeIfPresent(Data.self, forKey: .iconWeb)
        titleWeb = try container.decodeIfPresent(String.self, forKey: .titleWeb)
        thumbnailWeb = try container.decodeIfPresent(Data.self, forKey: .thumbnailWeb)
        urlWeb = try container.decodeIfPresent(String.self, forKey: .urlWeb)
        isActive = try container.decode(Bool.self, forKey: .isActive)
    }
    
    func getIconImage() -> UIImage? {
        if let iconWebData = iconWeb {
            return UIImage(data: iconWebData)
        }
        return nil
    }
    
    func getThumbnailImage() -> UIImage? {
        if let thumbnailWebData = thumbnailWeb {
            return UIImage(data: thumbnailWebData)
        }
        return nil
    }
}

class TaskManager {
    static let shared = TaskManager()
    let userDefaults = UserDefaults.standard
    var dataTabs: [TabItem] = []
    
    private init() {
        // Load saved data from UserDefaults
        if let savedData = userDefaults.data(forKey: "dataTabs"),
           let decodedData = try? JSONDecoder().decode([TabItem].self, from: savedData) {
            dataTabs = decodedData
        }
    }
    
    // Get the list of objects
    func getListObject() -> [TabItem] {
        return dataTabs
    }
    
    // Save the object
    func saveObject(_ tabItem: TabItem) {
        dataTabs.append(tabItem)
        saveDataToUserDefaults()
    }
    
    // Remove the object at a specific index
    func removeObject(at index: Int) {
        guard index >= 0 && index < dataTabs.count else {
            return
        }
        
        dataTabs.remove(at: index)
        saveDataToUserDefaults()
    }
    
    // Update the object at a specific index
    func updateObject(at index: Int, with newTabItem: TabItem) {
        guard index >= 0 && index < dataTabs.count else {
            return
        }
        
        dataTabs[index] = newTabItem
        saveDataToUserDefaults()
    }
    
    // Save the updated data to UserDefaults
    private func saveDataToUserDefaults() {
        if let encodedData = try? JSONEncoder().encode(dataTabs) {
            userDefaults.set(encodedData, forKey: "dataTabs")
        }
    }
}





//
//  ViewController.swift

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var thumb: UIImageView!
    
    @IBOutlet weak var icon: UIImageView!
    
    @IBOutlet weak var titleWeb: UILabel!
   
    @IBOutlet weak var urlWeb: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    func captureScreen() -> UIImage? {
        // Tạo một UIGraphicsImageRenderer với kích thước của màn hình hiện tại
        let renderer = UIGraphicsImageRenderer(size: UIScreen.main.bounds.size)
        
        // Sử dụng UIGraphicsImageRenderer để vẽ nội dung của màn hình hiện tại vào một UIImage
        let image = renderer.image { context in
            UIApplication.shared.keyWindow?.layer.render(in: context.cgContext)
        }
        
        return image
    }

    @IBAction func didTapSave(_ sender: UIButton) {
        // Gọi hàm captureScreen() để chụp màn hình và lưu ảnh
//        if let capturedImage = captureScreen() {
//            // Lưu ảnh vào Photo Library
//            print(type(of: capturedImage))
//            print(capturedImage)
////            UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil)
//        }
//        let tabItem1 = TabItem(iconWeb: UIImage(systemName: "lock.fill"), titleWeb: "Zing news tin tức mới nhất 2023", thumbnailWeb:  UIImage(systemName: "book"), urlWeb: "https://zingnews.vn", isActive: true)
//        TaskManager.shared.saveObject(tabItem1)
        
        let data = TaskManager.shared.getListObject()
        print("\ndata: \(data) \n\n")
        thumb.image = data[1].getThumbnailImage()
        icon.image = data[1].getIconImage()
        titleWeb.text = data[1].titleWeb
        urlWeb.text = data[1].urlWeb
        
    }
}


