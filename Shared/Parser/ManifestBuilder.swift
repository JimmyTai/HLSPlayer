//
//  ManifestBuilder.swift
//  HLSPlayer
//
//  Created by Jimmy on 2022/10/14.
//

import Foundation

open class ManifestBuilder {
    public init() {}
    
    fileprivate func parseMasterPlaylist(_ reader: BufferedReader, onMediaPlaylist: ((_ playlist: MediaPlaylist) -> Void)?) -> MasterPlaylist {
        let masterPlaylist = MasterPlaylist()
        var currentMediaPlaylist: MediaPlaylist?
        
        defer {
            reader.close()
        }
        
        while let line = reader.readLine() {
            if line.isEmpty {
                // skip empty lines
            } else if line.hasPrefix("#EXT") {
                if line.hasPrefix("#EXTM3U") {
                    // do nothing
                } else if line.hasPrefix("#EXT-X-STREAM-INF") {
                    // #EXT-X-STREAM-INF:PROGRAM-ID=1, BANDWIDTH=200000
                    currentMediaPlaylist = MediaPlaylist()
                    do {
                        let programIdString = try line.replace("(.*)=(\\d+),(.*)", replacement: "$2")
                        let bandwidthString = try line.replace("(.*),(.*)=(\\d+)(.*)", replacement: "$3")
                        if let currentMediaPlaylistExist = currentMediaPlaylist {
                            currentMediaPlaylistExist.programId = Int(programIdString)!
                            currentMediaPlaylistExist.bandwidth = Int(bandwidthString)!
                        }
                    } catch {
                        print("Failed to parse program-id and bandwidth on master playlist. Line = \(line)")
                    }
                }
            } else if line.hasPrefix("#") {
                // Comments are ignored
            } else {
                // URI - must be
                if let currentMediaPlaylistExist = currentMediaPlaylist {
                    currentMediaPlaylistExist.path = line
                    currentMediaPlaylistExist.masterPlayList = masterPlaylist
                    masterPlaylist.addPlaylist(currentMediaPlaylistExist)
                    if let callableOnMediaPlaylist = onMediaPlaylist {
                        callableOnMediaPlaylist(currentMediaPlaylistExist)
                    }
                }
            }
        }
        
        return masterPlaylist
    }
    
    fileprivate func parseMediaPlaylist(_ reader: BufferedReader, mediaPlaylist: MediaPlaylist = MediaPlaylist(), onMediaSegment: ((_ segment: MediaSegment) -> Void)?) -> MediaPlaylist {
        var currentSegment: MediaSegment?
    }
}
