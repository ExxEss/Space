//
//  SpaceController.swift
//  Space
//
//  Created by Yuguo Xie on 10/06/22.
//

import Foundation
import Cocoa

enum PresetSpaces: String, CaseIterable {
    case empty = "Hide All Files"
    case whole = "Show All Files"
    
    func localize() -> String {
        return self.rawValue.localize()
    }
}

class SpaceController {
    var currentTargetURL: URL?
    private var _container: SpaceContainer?
    var localizedDict: [String: String] = [:]
    weak var timer: Timer?
    
    static let shared: SpaceController = {
        let instance = SpaceController()
        for spaceKey in PresetSpaces.allCases {
            instance.localizedDict[
                spaceKey.localize()
            ] = spaceKey.rawValue
        }
        instance.checkState()
        return instance
    }()
    
    func setup(targetURL: URL) {
        if self.currentTargetURL != targetURL {
            do {
                let currentContainer =
                try UserDefaults.spaceDefaults.getObject(
                    forKey: targetURL.path,
                    castTo: SpaceContainer.self
                )
                _container = currentContainer
            } catch {
                var spaces: [Space] = []
                var currentSpace: Space?
                
                for spaceKey in PresetSpaces.allCases {
                    let space = Space(name: spaceKey.rawValue,
                                      isPreset: true)
                    if spaceKey == PresetSpaces.whole {
                        currentSpace = space
                    }
                    spaces.append(space)
                }
                
                let newContainer = SpaceContainer(
                    targetURL: targetURL,
                    current: currentSpace!,
                    spaces: spaces
                )
                _container = newContainer
            }
            self.currentTargetURL = targetURL
        }
        checkState()
    }
    
    deinit {
        timer?.invalidate()
    }

    var container: SpaceContainer {
        get { _container! }
        set(newContainer) { _container = newContainer }
    }
    
    func create(spaceName: String, items: [URL]?) {
        let alreadyExists = _container!.spaces!.filter {
            $0.name == spaceName
        }.count > 0
        
        if !alreadyExists {
            do {
                let urlBookmarks = try items!.map {
                    try $0.bookmarkData()
                }
                let newSpace = Space(name: spaceName,
                                     urlBookmarks: urlBookmarks)
                _container!.spaces?.append(newSpace)
                _container!.current = newSpace
            } catch {
                print("Failed to create space")
                return
            }
        }
        show()
        persist()
    }
    
    func alter(spaceName: String) {
        update()
        for space in _container!.spaces! {
            if space.name == spaceName {
                _container!.current = space
                break
            }
        }
        show()
        
        if _container!.spaces!.count > 2 {
            persist()
        }
    }
    
    func alterPreset(spaceName: String) {
        alter(spaceName: localizedDict[spaceName]!)
    }
    
    private func update() {
        if _container!.current != nil &&
            !_container!.current!.isPreset {
            let path = _container!.targetURL.path
            let total = getTargetItems(targetPath: path) ?? []
            var bookmarks: [Data]?
            
            do {
                for item in total {
                    let url = URL(fileURLWithPath: item,
                                  relativeTo: _container!.targetURL)
                    
                    let bookmark = try url.bookmarkData()
                    
                    if !url.isHidden {
                        if bookmarks == nil {
                            bookmarks = [bookmark]
                        } else {
                            bookmarks?.append(bookmark)
                        }
                    }
                }
            } catch {
                DialogCreator.alertInfo(info: "Failed to update")
                return
            }
            
            var spaces = _container!.spaces!
            for i in spaces.indices {
                if (spaces[i].name == _container!.current!.name) {
                    spaces[i].urlBookmarks = bookmarks
                    _container!.spaces = spaces
                }
            }
        }
    }
    
    func delete(spaceName: String) {
        _container!.spaces = _container!.spaces!.filter {
            $0.name != spaceName
        }
        
        if spaceName == _container!.current!.name {
            alter(spaceName: PresetSpaces.empty.rawValue)
            show()
        }
        persist()
    }
    
    func addItems(spaceName: String, items: [URL]?) {
        guard let items = items else { return }
        var spaces = _container!.spaces!
        
        for i in spaces.indices {
            if (spaces[i].name == spaceName) {
                do {
                    var spaceItems: [String] = []
                    let bookmarks = spaces[i].urlBookmarks
                    
                    if bookmarks?.isEmpty == false {
                        for bookmark in bookmarks! {
                            var isStale = false
                            let resolvedURL = try
                            URL(resolvingBookmarkData: bookmark,
                                bookmarkDataIsStale: &isStale)
                            spaceItems.append(resolvedURL.lastPathComponent)
                        }
                    }
                    
                    for item in items {
                        if !spaceItems.contains(item.lastPathComponent) {
                            let bookmark = try item.bookmarkData()
                            spaces[i].urlBookmarks?.append(bookmark)
                        }
                    }
                    _container!.spaces = spaces
                    alter(spaceName: spaceName)
                } catch {
                    DialogCreator.alertInfo(info: "Failed to add items")
                    return
                }
            }
        }
    }
    
    func _addItems(spaceName: String, items: [URL]?) {
        guard let items = items else { return }
        
        if let index = findSpaceIndex(spaceName: spaceName) {
            do {
                let spaceItems = extractSpaceItems(space: _container!.spaces![index])
                let newItems = items.filter { !spaceItems.contains($0.lastPathComponent) }
                let newBookmarks = try createBookmarks(from: newItems)
                
                _container!.spaces![index].urlBookmarks?.append(contentsOf: newBookmarks)
                alter(spaceName: spaceName)
            } catch {
                DialogCreator.alertInfo(info: "Failed to add items")
                return
            }
        }
    }

    private func findSpaceIndex(spaceName: String) -> Int? {
        return _container!.spaces!.firstIndex { $0.name == spaceName }
    }

    private func extractSpaceItems(space: Space) -> [String] {
        guard let bookmarks = space.urlBookmarks, !bookmarks.isEmpty else { return [] }
        
        return bookmarks.compactMap { bookmark -> String? in
            var isStale = false
            return (try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale))?.lastPathComponent
        }
    }

    private func createBookmarks(from items: [URL]) throws -> [Data] {
        return try items.map { try $0.bookmarkData() }
    }
    
    func moveItems(spaceName: String, items: [URL]?) {
        guard let items = items else { return }
        
        _moveItems(from: _container!.current!.name, to: spaceName, items: items)
    }
    
    private func _moveItems(from sourceSpace: String, to destinationSpace: String, items: [URL]) {
        removeItems(spaceName: sourceSpace, items: items)
        addItems(spaceName: destinationSpace, items: items)
    }

    func removeItems(spaceName: String, items: [URL]?) {
        guard let items = items else { return }
        
        hideItems(items: items)
        
        if let index = findSpaceIndex(spaceName: spaceName) {
            let filteredBookmarks = _container!.spaces![index].urlBookmarks?.filter { bookmark in
                var isStale = false
                guard let resolvedURL = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) else {
                    return true
                }
                return !items.contains(resolvedURL)
            }
            
            _container!.spaces![index].urlBookmarks = filteredBookmarks
//            alter(spaceName: spaceName)
        }
    }
    
    var addableSpaces: [Space] {
        get {
            container.spaces!.filter {
                !$0.isPreset && $0.name != container.current?.name
            }
        }
    }
    
    func hideItems(items: [URL]?) {
        for item in items! {
            var tmp = item
            tmp.isHidden = true
        }
    }
    
    func showItem(item: String) {
        var url = URL(fileURLWithPath: item,
            relativeTo: _container!.targetURL)
        url.isHidden = false
    }
    
    private func setCurrentAsNil() {
        if let isPreset = _container!.current?.isPreset {
            if isPreset {
                _container!.current = nil
            }
        }
    }
    
    private func checkState() {
        self._checkState()
        if timer == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.timer =
                Timer.scheduledTimer(withTimeInterval: 1.0,
                                     repeats: true) { timer in
                    self._checkState()
                }
            }
        }
    }
    
    private func _checkState() {
        if _container != nil && (_container!.current == nil ||
                                 _container!.current!.isPreset) {
            let path = _container!.targetURL.path
            let total = getTargetItems(targetPath: path) ?? []
            
            let hiddenItems = total.filter {
                URL(fileURLWithPath: $0,
                    relativeTo: _container!.targetURL).isHidden
            }
            
            let dotItems = total.filter {
                $0.prefix(1) == "."
            }
            
            if total.count == hiddenItems.count ||
                hiddenItems.count == dotItems.count {
                let spaceName = total.count == hiddenItems.count
                ? PresetSpaces.empty.rawValue
                : PresetSpaces.whole.rawValue
                
                for space in _container!.spaces! {
                    if space.name == spaceName {
                        _container!.current = space
                    }
                }
            } else {
                _container!.current = nil
            }
        }
    }
    
    private func persist() {
        do {
            try UserDefaults.spaceDefaults.setObject(
                _container!, forKey: _container!.targetURL.path)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func showOnly(items: [URL]?) {
        let path = _container!.targetURL.path
        let total = getTargetItems(targetPath: path)
        let items = items!.map { $0.lastPathComponent }
        
        for item in total! {
            if !items.contains(item) {
                var url = URL(fileURLWithPath: item,
                              relativeTo: _container!.targetURL)
                url.isHidden = true
            }
        }
        setCurrentAsNil()
    }
    
    func replace(item: String, items: [URL]?) {
        var items = items!.map { $0.lastPathComponent }
        items.append(item)
        
        for _item in items {
            var url = URL(fileURLWithPath: _item,
                          relativeTo: _container!.targetURL)
            url.isHidden = item != _item
        }
    }
    
    private func show() {
        if _container!.current != nil {
            let path = _container!.targetURL.path
            let total = getTargetItems(targetPath: path)
            let spaceName = _container!.current!.name
            
            let bookmarks = _container!.current!.urlBookmarks ?? []
            var items: [String] = []
            
            do {
                if bookmarks.count > 0 {
                    for bookmark in bookmarks {
                        var isStale = false
                        let resolvedURL = try
                        URL(resolvingBookmarkData: bookmark,
                            bookmarkDataIsStale: &isStale)
                        items.append(resolvedURL.lastPathComponent)
                    }
                }
            } catch {
                DialogCreator.alertInfo(info: "Failed to show")
                return
            }
            
            for item in total! {
                var url = URL(fileURLWithPath: item,
                              relativeTo: _container!.targetURL)
                
                if spaceName == PresetSpaces.whole.rawValue ||
                    items.contains(item) {
                    url.isHidden = false
                } else if spaceName == PresetSpaces.empty.rawValue ||
                            !items.contains(item) {
                    url.isHidden = true
                }
            }
            
            if items.count == 1 {
                let url = URL(fileURLWithPath: items[0],
                              relativeTo: _container!.targetURL)
                if url.isDirectory {
                    showInFinder(url: url)
                }
            }
        }
    }
    
    private func showInFinder(url: URL?) {
        guard let url = url else { return }
        
        if url.isDirectory {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
        } else {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
    
    private func getTargetItems(targetPath: String) -> [String]? {
        do {
            let items =
            try FileManager.default.contentsOfDirectory(
                atPath: targetPath)
            return items
        } catch {
            return []
        }
    }
    
    var hiddenItems: [String] {
        get {
            let path = _container!.targetURL.path
            let total = getTargetItems(targetPath: path)
            return total!.filter {
                URL(fileURLWithPath: $0,
                    relativeTo: _container!.targetURL).isHidden &&
                $0.prefix(1) != "."
            }
        }
    }
    
    var totalItems: [String] {
        get {
            let path = _container!.targetURL.path
            let total = getTargetItems(targetPath: path)
            return total!.filter {
                $0.prefix(1) != "."
            }
        }
    }
    
    func hasUnavailableTargetURL() -> Bool {
        let path = _container!.targetURL.path

        return !isHomeRelative(path: path)
    }
    
    func isEmptyTargetURL() -> Bool {
        let path = _container!.targetURL.path
        let total = getTargetItems(targetPath: path)

        return total!.count == 0
    }
    
    private func isHomeRelative(path: String) -> Bool {
        return path.contains(homeDirectoryPath)
    }
    
    private var homeDirectoryPath: String {
        get {
            let pw = getpwuid(getuid());
            let home = pw?.pointee.pw_dir!
            let homePath =
            FileManager.default.string(withFileSystemRepresentation: home!,
                                       length: Int(strlen(home!)))
            return homePath
        }
    }
}

