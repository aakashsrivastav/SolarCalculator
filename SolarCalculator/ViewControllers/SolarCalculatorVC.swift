//
//  SolarCalculatorVC.swift
//  SolarCalculator
//
//  Created by Aakash Srivastav on 28/07/18.
//  Copyright © 2018 Aakash Srivastav. All rights reserved.
//

import MapKit
import UserNotifications

class SolarCalculatorVC: BaseVC {

    // MARK: Private Properties
    private var choosenDate = Date()
    private var selectedLocation: Locations!
    
    private lazy var sunCalc = SunCalc()
    private lazy var dateFormatter = DateFormatter()
    private lazy var locationManager = CLLocationManager()
    
    private lazy var placesSearchController: GooglePlacesSearchController = {
        let controller = GooglePlacesSearchController(delegate: self,
                                                      apiKey: APIKeys.GooglePlacesAPIKey,
                                                      placeType: .address
            
            // Optional: coordinate: CLLocationCoordinate2D(latitude: 55.751244, longitude: 37.618423),
            // Optional: radius: 10,
            // Optional: strictBounds: true,
            // Optional: searchBarPlaceholder: "Start typing..."
        )
        //Optional: controller.searchBar.isTranslucent = false
        //Optional: controller.searchBar.barStyle = .black
        //Optional: controller.searchBar.tintColor = .white
        //Optional: controller.searchBar.barTintColor = .black
        return controller
    }()
    
    // MARK: IBOutlets
    @IBOutlet weak var locationNameLbl: UILabel!
    @IBOutlet weak var changeLocationBtn: UIButton!
    @IBOutlet weak var pinLocationBtn: UIButton!
    @IBOutlet weak var bookmarkLocationBtn: UIButton!
    @IBOutlet weak var viewAllBookmarksBtn: UIButton!

    @IBOutlet weak var mkMapView: MapViewWithZoom!
    @IBOutlet weak var myLocationBtn: UIButton!
    
    @IBOutlet weak var sunRiseTimeLbl: UILabel!
    @IBOutlet weak var sunSetTimeLbl: UILabel!
    
    @IBOutlet weak var moonRiseTimeLbl: UILabel!
    @IBOutlet weak var moonSetTimeLbl: UILabel!
    
    @IBOutlet weak var sunSetImageView: UIImageView!
    @IBOutlet weak var moonSetImageView: UIImageView!

    @IBOutlet weak var selectedDateLbl: UILabel!
    @IBOutlet weak var prevDateBtn: UIButton!

    // MARK: View Controller Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = K_APP_NAME.localized
        
        locationManager.delegate = self
        locationManager(locationManager, didChangeAuthorization: CLLocationManager.authorizationStatus())
        
        //mkMapView.delegate = self
        mkMapView.showsUserLocation = true
        mkMapView.userTrackingMode = .follow
        
        let transform = CGAffineTransform(rotationAngle: 180.degreesToRadians)
        sunSetImageView.transform = transform
        moonSetImageView.transform = transform
        prevDateBtn.transform = transform
        
        let predicate = NSPredicate(format: "\(Locations.Keys.isPinned.name) == %@", NSNumber(value: true))
        let locations = Locations.fetch(using: predicate)
        selectedLocation = locations.first
        
        if let location = locations.first {
            selectedLocation = location
            bookmarkLocationBtn.setImage(UIImage(named: "ic_bookmarked"), for: .normal)
        } else {
            bookmarkLocationBtn.setImage(UIImage(named: "ic_bookmark"), for: .normal)
        }
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didDragMap))
        panGesture.delegate = self
        
        calculate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if fetchSelectedLocationFromDB() == nil {
            bookmarkLocationBtn.setImage(UIImage(named: "ic_bookmark"), for: .normal)
        } else {
            bookmarkLocationBtn.setImage(UIImage(named: "ic_bookmarked"), for: .normal)
        }
    }
    
    // MARK: Private Methods
    
    @objc private func didDragMap(_ gesture: UIPanGestureRecognizer) {
        guard (gesture.state == .ended) else {
            return
        }
        GooglePlacesRequestHelpers.reverseGeocode(latitude: mkMapView.centerCoordinate.latitude,
                                                  longitude: mkMapView.centerCoordinate.longitude,
                                                  apiKey: APIKeys.GooglePlacesAPIKey) { (place) in
                                                    if let unwrappedPlace = place {
                                                        self.didSelectPlace(unwrappedPlace)
                                                    }
        }
    }
    
    // Method to calculate and set sun and moon's rise set times and other info
    private func calculate() {
        
        let formatter = dateFormatter
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        selectedDateLbl.text = formatter.string(from: choosenDate)

        guard let sLocation = selectedLocation else {
            return
        }
        
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = .current
        
        let location = SunCalc.Location(latitude: sLocation.latitude,
                                        longitude: sLocation.longitude)
        
        do {
            let rise = try sunCalc.time(ofDate: choosenDate, forSolarEvent: .sunrise, atLocation: location)
            let sunrise = formatter.string(from: rise)
            sunRiseTimeLbl.text = sunrise
        }
        catch let e as SunCalc.SolarEventError {
            switch e {
            case .sunNeverRise:
                print_debug("Sun never rise")
            case .sunNeverSet:
                print_debug("Sun never set")
            }
        }
        catch let e {
            print("Unknown error: \(e)")
        }
        
        do {
            let set = try sunCalc.time(ofDate: choosenDate, forSolarEvent: .sunset, atLocation: location)
            let sunset = formatter.string(from: set)
            sunSetTimeLbl.text = sunset
        }
        catch let e as SunCalc.SolarEventError {
            switch e {
            case .sunNeverRise:
                print_debug("Sun never rise")
            case .sunNeverSet:
                print_debug("Sun never set")
            }
        }
        catch let e {
            print_debug("Unknown error: \(e)")
        }
        
        do {
            let moonTimes = try sunCalc.moonTimes(date: choosenDate, location: location)
            moonRiseTimeLbl.text = formatter.string(from: moonTimes.moonRiseTime)
            moonSetTimeLbl.text = formatter.string(from: moonTimes.moonSetTime)
        }
        catch let e as SunCalc.LunarEventError {
            switch e {
            case .moonNeverRise:
                print_debug("Moon never rise")
            case .moonNeverSet:
                print_debug("Moon never set")
            }
        }
        catch let e {
            print_debug("Unknown error: \(e)")
        }
        
        do {
            let goldenHour = try sunCalc.time(ofDate: choosenDate, forSolarEvent: .goldenHour, atLocation: location)
            scheduleNotification(with: K_GOLDEN_HOUR_NOTIFICATION_TITLE.localized,
                                 body: K_GOLDEN_HOUR_NOTIFICATION_BODY.localized,
                                 at: goldenHour)
        }
        catch let e as SunCalc.SolarEventError {
            switch e {
            case .sunNeverRise:
                print_debug("Sun never rise")
            case .sunNeverSet:
                print_debug("Sun never set")
            }
        }
        catch let e {
            print_debug("Unknown error: \(e)")
        }
        
        setupLocationBtns()
    }
    
    private func setupLocationBtns() {
        let pinnedImage = UIImage(named: "ic_pin")
        locationNameLbl.text = selectedLocation.name
        
        if selectedLocation.isPinned, let img = pinnedImage {
            pinLocationBtn.setImage(img.withRenderingMode(.alwaysTemplate), for: .normal)
        } else {
            pinLocationBtn.setImage(pinnedImage, for: .normal)
        }
    }
    
    private func scheduleNotification(with title: String, body: String, at date: Date) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: timeComponents, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }
    
    // MARK: IBActions
    
    @IBAction func changeLocationBtnTapped(_ sender: UIButton) {
        present(placesSearchController, animated: true, completion: nil)
    }
    
    @IBAction func pinLocationBtnTapped(_ sender: UIButton) {
        let pinnedImage = UIImage(named: "ic_pin")
        
        if let location = fetchSelectedLocationFromDB() {
            location.isPinned.toggle()
            selectedLocation.isPinned = location.isPinned
            
            if location.isPinned, let img = pinnedImage {
                pinLocationBtn.setImage(img.withRenderingMode(.alwaysTemplate), for: .normal)
            } else {
                pinLocationBtn.setImage(pinnedImage, for: .normal)
            }
            AppDelegate.shared.saveContext()
            
        } else if let img = pinnedImage, let location = selectedLocation {
            pinLocationBtn.setImage(img.withRenderingMode(.alwaysTemplate), for: .normal)
            bookmarkLocationBtn.setImage(UIImage(named: "ic_bookmarked"), for: .normal)
            Locations.saveLocationInDB(location)
        }
    }
    
    @IBAction func bookmarkLocationBtnTapped(_ sender: UIButton) {
        if let location = fetchSelectedLocationFromDB() {
            AppDelegate.shared.persistentContainer.viewContext.delete(location)
            AppDelegate.shared.saveContext()
            bookmarkLocationBtn.setImage(UIImage(named: "ic_bookmark"), for: .normal)
        } else if let location = selectedLocation {
            Locations.saveLocationInDB(location)
            bookmarkLocationBtn.setImage(UIImage(named: "ic_bookmarked"), for: .normal)
        }
    }
    
    @IBAction func viewAllBookmarksBtnTapped(_ sender: UIButton) {
        let bookmarkedPlacesScene = BookmarkedPlacesTVC.instantiate(fromAppStoryboard: .main)
        bookmarkedPlacesScene.delegate = self
        navigationController?.pushViewController(bookmarkedPlacesScene, animated: true)
    }
    
    @IBAction func myLocationBtnTapped(_ sender: UIButton) {
        locationManager(locationManager, didChangeAuthorization: CLLocationManager.authorizationStatus())
    }
    
    @IBAction func changeDateBtnTapped(_ sender: UIButton) {
        let chooseDatePickerPopUpScene = ChooseDatePopUpVC.instantiate(fromAppStoryboard: .main)
        chooseDatePickerPopUpScene.modalPresentationStyle = .overCurrentContext
        chooseDatePickerPopUpScene.delegate = self
        present(chooseDatePickerPopUpScene, animated: false, completion: nil)
    }
    
    @IBAction func prevDateBtnTapped(_ sender: UIButton) {
        choosenDate = choosenDate.adding(.day, value: -1)
        calculate()
    }
    
    @IBAction func currentDateBtnTapped(_ sender: UIButton) {
        choosenDate = Date()
        calculate()
    }
    
    @IBAction func nextDateBtnTapped(_ sender: UIButton) {
        choosenDate = choosenDate.adding(.day, value: 1)
        calculate()
    }
}

// MARK: Choose Date Delegate Methods
extension SolarCalculatorVC: ChooseDateDelegate {
    
    func didSelectDate(_ date: Date) {
        choosenDate = date
        calculate()
    }
}

// MARK: Location Manager Delegate Methods
extension SolarCalculatorVC: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        var myLocationBtnImageName = "ic_disabled_location"
        
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            myLocationBtnImageName = "ic_my_location"
            locationManager.startUpdatingLocation()
        case .denied:
            showNoPermissionAlert(isDenied: true)
        case .restricted:
            showNoPermissionAlert(isDenied: true)
        }
        
        let btnImage = UIImage(named: myLocationBtnImageName)
        myLocationBtn.setImage(btnImage, for: .normal)
    }
    
    private func showNoPermissionAlert(isDenied: Bool) {
        
        let alertText = K_LOCATION_PERMISSION.localized
        let alertMessage: String
        
        if isDenied {
            alertMessage = K_LOCATION_PERMISSION_DENIED.localized
        } else {
            alertMessage = K_LOCATION_SERVICE_RESTRICTED.localized
        }

        let alert = UIAlertController(title: alertText, message: alertMessage, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: K_SETTINGS.localized, style: .cancel) { _ in
            self.moveToAppSettings()
        }
        
        let okAction = UIAlertAction(title: K_OK.localized, style: .default) { _ in
            
        }
        
        if isDenied {
            alert.addAction(settingsAction)
        }
        
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func moveToAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        mkMapView.setCenterCoordinate(coordinate: location.coordinate, zoomLevel: mkMapView.zoomLevel, animated: true)
        locationManager.stopUpdatingLocation()
    }
}

// MARK: Google Places Autocomplete View Controller Delegate Methods
extension SolarCalculatorVC: GooglePlacesAutocompleteViewControllerDelegate {
    
    func viewController(didAutocompleteWith place: PlaceDetails) {
        placesSearchController.isActive = false
        didSelectPlace(place)
    }
    
    private func didSelectPlace(_ place: PlaceDetails) {
        
        if selectedLocation == nil {
            selectedLocation = Locations.getBlankLocation()
        }
        
        guard selectedLocation.placeId != place.placeId,
            let coordinate = place.coordinate else {
                return
        }
        
        selectedLocation.placeId = place.placeId
        selectedLocation.latitude = coordinate.latitude
        selectedLocation.longitude = coordinate.longitude
        selectedLocation.name = place.formattedAddress
        
        if let location = fetchSelectedLocationFromDB() {
            selectedLocation.isPinned = location.isPinned
            bookmarkLocationBtn.setImage(UIImage(named: "ic_bookmarked"), for: .normal)
        } else {
            selectedLocation.isPinned = false
            bookmarkLocationBtn.setImage(UIImage(named: "ic_bookmark"), for: .normal)
        }
        calculate()
    }
    
    private func fetchSelectedLocationFromDB() -> Locations? {
        guard let sLocation = selectedLocation,
            let placeId = sLocation.placeId else {
                return nil
        }
        
        let predicate = NSPredicate(format: "\(Locations.Keys.placeId.name) = %@", placeId)
        let locations = Locations.fetch(using: predicate)
        return locations.first
    }
}

// MARK: Gesture Recognizer Delegate Methods
extension SolarCalculatorVC: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
