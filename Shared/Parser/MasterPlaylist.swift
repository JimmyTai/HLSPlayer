//
//  MasterPlaylist.swift
//  HLSPlayer
//
//  Created by JimmyTai on 2022/10/13.
//

import Foundation

open class MasterPlaylist: CustomStringConvertible {
    var playlists = [MediaPlaylist]()
    open var path: String?
    
    public init() {}
    
    open func addPlaylist(_ playlist: MediaPlaylist) {
        playlists.append(playlist)
    }
    
    open func getPlaylist(_ index: Int) -> MediaPlaylist? {
        if index > playlists.count {
            return nil
        }
        return playlists[index]
    }
    
    open func getPlaylistCount() -> Int {
        return playlists.count
    }
    
    public var description: String {
        return """
        path: \(String(describing: path)),
        playlists: \(String(describing: playlists))
        """
    }
}
