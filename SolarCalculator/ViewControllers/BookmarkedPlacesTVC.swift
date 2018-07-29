//
//  BookmarkedPlacesTVC.swift
//  SolarCalculator
//
//  Created by Aakash Srivastav on 28/07/18.
//  Copyright © 2018 Aakash Srivastav. All rights reserved.
//

import UIKit

class BookmarkedPlacesTVC: UITableViewController {

    private var locations: [Locations] = Locations.fetch(using: nil)
    private var filteredPlaces: [Locations] = []
    private let cellIdentifier = "cell"
    
    lazy var searchController = UISearchController(searchResultsController: nil)
    
    private var searchBarIsEmpty: Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    weak var delegate: GooglePlacesAutocompleteViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = K_BOOKMARKS.localized
        tableView.tableFooterView = UIView()
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Bookmarks"
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        }
        definesPresentationContext = true
    }
    
    // MARK: - Private instance methods
    
    private func filterContentForSearchText(_ searchText: String) {
        filteredPlaces = locations.filter({( location : Locations) -> Bool in
            let locationName = (location.name ?? "")
            return (locationName.lowercased().contains(searchText.lowercased()))
        })
        tableView.reloadData()
    }
}

// MARK: Search Results Updating Delegate Methods
extension BookmarkedPlacesTVC: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

// MARK: Table View DataSource Methods
extension BookmarkedPlacesTVC {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredPlaces.count
        }
        return locations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        
        let location: Locations
        if isFiltering {
            location = filteredPlaces[indexPath.row]
        } else {
            location = locations[indexPath.row]
        }
        
        cell.textLabel?.text = location.name
        cell.detailTextLabel?.text = "\(location.latitude) \(location.longitude)"
        
        return cell
    }
}

// MARK: Table View Delegate Methods
extension BookmarkedPlacesTVC {
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            if let placeId = locations[indexPath.row].placeId {
                Locations.deleteLocation(having: placeId)
            }
            locations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let location = locations[indexPath.row]
        guard let id = location.placeId else {
            return
        }
        
        GooglePlacesRequestHelpers
            .getPlaceDetails(id: id, apiKey: APIKeys.GooglePlacesAPIKey) { [weak self] in
                guard let strongSelf = self, let value = $0 else { return }
                strongSelf.delegate?.viewController(didAutocompleteWith: value)
                strongSelf.navigationController?.popViewController(animated: true)
        }
    }
}
