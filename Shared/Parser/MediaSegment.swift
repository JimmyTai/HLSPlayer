//
//  MediaSegment.swift
//  HLSPlayer
//
//  Created by JimmyTai on 2022/10/13.
//

import Foundation

open class MediaSegment: CustomStringConvertible {
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
    
    public var description: String {
        return """
        MediaSegment:
            duration: \(String(describing: duration)),
            sequence: \(String(describing: sequence)),
            subrangeLength: \(String(describing: subrangeLength)),
            subrangeStart: \(String(describing: subrangeStart)),
            title: \(String(describing: title)),
            discontinuity: \(String(describing: discontinuity)),
            path: \(String(describing: path))
        """
    }
}
