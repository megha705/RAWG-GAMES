//
//  HomeTableViewHelper.swift
//  RAWG GAMES
//
//  Created by Mahmut Yazar on 16.01.2023.
//

import UIKit
import Alamofire

class HomeTableViewHelper: NSObject {
    
    typealias RowItem = HomeCellModel
    typealias SearchItem = [HomeCellModel]
    
    private let model = HomeModel()
    
    private let cellIdentifier = "HomeTableViewCell"
    private var tableView: UITableView?
    private var searchBar: UISearchBar?
    private var navigationController: UINavigationController?
    private weak var viewModel: HomeViewModel?
    private var pendingRequestWorkItem: DispatchWorkItem?
    
    private var items: [RowItem] = []
    private var searchResults: SearchItem
    
    private var nextPageURL : String?
    
    init(tableView: UITableView, viewModel: HomeViewModel, searchBar: UISearchBar, searchResults: SearchItem, navigationController: UINavigationController) {
        self.tableView = tableView
        self.viewModel = viewModel
        self.searchBar = searchBar
        self.searchResults = searchResults
        self.navigationController = navigationController
        
        super.init()
        setupTableView()
    }
    
    private func setupTableView() {
        tableView?.separatorStyle = .none
        tableView?.register(.init(nibName: "HomeTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
        tableView?.dataSource = self
        tableView?.delegate = self
        searchBar?.delegate = self
    }

    func setItems(_ items: [RowItem]) {
        self.items = items
        self.searchResults = items
        tableView?.reloadData()
    }
}

extension HomeTableViewHelper: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let detailsVC = storyBoard.instantiateViewController(withIdentifier: "detailViewController") as? DetailViewController else {
            return
        }
        let id = searchResults[indexPath.row].id
        detailsVC.getID(id)
        detailsVC.title = searchResults[indexPath.row].name
        
        navigationController?.pushViewController(detailsVC, animated: true)
    }
}

extension HomeTableViewHelper: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if InternetManager.shared.isInternetActive() {
            return searchResults.count
        } else {
            return items.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! HomeTableViewCell
        
        if InternetManager.shared.isInternetActive() {
            cell.configure(with: searchResults[indexPath.row])
        } else {
            cell.configure(with: items[indexPath.row])
        }
        cell.backgroundColor = .systemGray6
        return cell
    }
}


//MARK: -Service search.

extension HomeTableViewHelper: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        pendingRequestWorkItem?.cancel()
        
        let requestWorkItem = DispatchWorkItem { [weak self] in
            if let searchText = searchBar.text {
                
                AF.request("\(Constants.sharedURL)?key=\(Constants.apiKey)&search=\(searchText)&page_size=20").responseDecodable(of: ApiGame.self) { search in
                    
                    guard let response = search.value else {
                        print("no data")
                        return
                    }
                    let results = response.results ?? []
                    let homeCellModel: [HomeCellModel] = results.map {.init(id: $0.id ?? 0, name: $0.name ?? "", backgroundImage: $0.backgroundImage ?? "", released: $0.released ?? "", rating: $0.rating ?? 0.0, ratingTop: $0.ratingTop ?? 0)}
                    
                    self!.searchResults = homeCellModel
                    self!.tableView?.reloadData()
                }
            }
        }
        pendingRequestWorkItem = requestWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: requestWorkItem)
    }
}
