//
//  TableViewController.swift
//  DiffableDataSourceCellProviderBug
//
//  Created by Gene Bogdanovich on 28.01.21.
//

import UIKit
import CoreData

class TableViewController: UITableViewController {
    
    var moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    lazy var fetchedResultsController: NSFetchedResultsController<Item> = {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        let sort = NSSortDescriptor(key: #keyPath(Item.name), ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: moc,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        controller.delegate = self
        
        return controller
    }()
    
    var diffableDataSource: UITableViewDiffableDataSource<Int, NSManagedObjectID>?
    
    func configureDiffableDataSource() {
        let diffableDataSource = UITableViewDiffableDataSource<Int, NSManagedObjectID>(tableView: tableView) { (tableView, indexPath, objectID) -> UITableViewCell? in
            
            print("cellProvider id: \(objectID), isTemporaryID: \(objectID.isTemporaryID)")
            
            guard let object = try? self.moc.existingObject(with: objectID) as? Item else {
                fatalError("Managed object should be available.")
            }
            
            print("cellProvider name: \(object.name ?? "Unknown"), id: \(object.id), isTemporaryID: \(object.objectID.isTemporaryID)")
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell_id", for: indexPath)
            cell.textLabel?.text = object.name
            return cell
        }
        self.diffableDataSource = diffableDataSource
        tableView.dataSource = diffableDataSource
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Configure nav bar.
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(handleAdd))
        // Register cell.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell_id")
        configureDiffableDataSource()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.performWithoutAnimation {
            try! fetchedResultsController.performFetch()
        }
    }
    
    let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    var counter = 0
    
    @objc func handleAdd() {
        // Add item to Core Data.
        let context = moc
        let entity = Item.entity()
        let item = Item(entity: entity, insertInto: context)
        item.name = "\(letters[counter])"
        counter += 1
        try! context.save()
        try! fetchedResultsController.performFetch()
    }
}

extension TableViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        print("didChangeContentWith snapshot")
        guard let dataSource = tableView?.dataSource as? UITableViewDiffableDataSource<Int, NSManagedObjectID> else {
            assertionFailure("The data source has not implemented snapshot support while it should.")
            return
        }
        var snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        let currentSnapshot = dataSource.snapshot() as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        
        let reloadIdentifiers: [NSManagedObjectID] = snapshot.itemIdentifiers.compactMap { itemIdentifier in
            guard let currentIndex = currentSnapshot.indexOfItem(itemIdentifier), let index = snapshot.indexOfItem(itemIdentifier), index == currentIndex else {
                return nil
            }
            guard let existingObject = try? controller.managedObjectContext.existingObject(with: itemIdentifier), existingObject.isUpdated else { return nil }
            return itemIdentifier
        }
        snapshot.reloadItems(reloadIdentifiers)
        
        let shouldAnimate = tableView?.numberOfSections != 0
        dataSource.apply(snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>, animatingDifferences: shouldAnimate)
        
        fetchedResultsController.fetchedObjects?.forEach({ (object) in
            print("fetchedResultsController name: \(object.name ?? "Unknown"), id: \(object.id), isTemporaryID: \(object.objectID.isTemporaryID)")
        })
    }
}
