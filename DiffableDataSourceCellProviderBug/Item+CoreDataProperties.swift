//
//  Item+CoreDataProperties.swift
//  DiffableDataSourceCellProviderBug
//
//  Created by Gene Bogdanovich on 28.01.21.
//
//

import Foundation
import CoreData


extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var name: String?
}

extension Item: Identifiable {}
