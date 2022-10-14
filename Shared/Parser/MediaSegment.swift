//
//  MediaSegment.swift
//  HLSPlayer
//
//  Created by JimmyTai on 2022/10/13.
//

import Foundation

open class MediaSegment {
    var mediaPlaylist: MediaPlaylist?
    open var duration: Float?
    open var sequence: Int = 0
    open var subrangeLength: Int?
    open var subrangeStart: Int?
    open var title: String?
    open var discontinuity: Bool = false
    open var path: String?
    
    public init() {}
    
    open func getMediaPlayList() -> MediaPlaylist? {
        return self.mediaPlaylist
    }
}
