//
//  PurchasesViewController.swift
//  IAPSample2
//
//  Created by Davide D'Andrea on 18/09/2020.
//  Copyright © 2020 IdeaSolutions. All rights reserved.
//

import UIKit
import StoreKit


class PurchasesViewController: UITableViewController {

    var products: [SKProduct] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Purchases"
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
            self.navigationItem.largeTitleDisplayMode = .automatic
        } else {
            // Fallback on earlier versions
        }
        
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(reload), for: .valueChanged)
        
        let restoreButton = UIBarButtonItem(title: "Restore", style: .plain, target: self, action: #selector(restoreAction(_:)))
        navigationItem.rightBarButtonItem = restoreButton
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseNotification(_:)), name: .IAPManagerPurchaseNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchasesReceivedNotification(_:)), name: .IAPManagerPurchasesReceivedNotification, object: nil)
        
        
        let productIdentifiers: Set<String> = ["purchase1","purchase2","subscription1"]
    }
    
    @objc func reload() {
        products = []
        
        tableView.reloadData()
        
        // Da rimuovere se uso le Notifications
        IAPManager.shared.requestProducts{ [weak self] success, products in
            guard let self = self else {return}
            guard let products = products else {
                self.endRefreshing()
                return
            }
            
            if success {
                self.products = products
            }
            self.endRefreshing()
        }
    }
    
    private func endRefreshing() {
        DispatchQueue.main.async {
            self.refreshControl?.endRefreshing()
        }
    }
    
    
    
    @objc func restoreAction(_ sender: AnyObject) {
        IAPManager.shared.restorePurchases()
    }
    
    @objc func handlePurchaseNotification(_ notification: Notification) {
        guard let productID = notification.object as? String,
            let index = products.firstIndex(where: {$0.productIdentifier == productID})
        else { return }
        
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
    }
    @objc func handlePurchasesReceivedNotification(_ notification: Notification) {
        guard let products = notification.object as? [SKProduct] else {return}
        self.products = products
        endRefreshing()
    }
}

extension PurchasesViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        cell.textLabel?.text = products[indexPath.row].localizedTitle
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        cell.detailTextLabel?.text = String(products[indexPath.row].price.floatValue) + " €"
        
        let buyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
        buyLabel.text = "Buy"
        buyLabel.textColor = .systemBlue
        cell.accessoryView = buyLabel
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        IAPManager.shared.buyProduct(products[indexPath.row])
    }
}
