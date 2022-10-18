//
//  ManifestBuilder.swift
//  HLSPlayer
//
//  Created by Jimmy on 2022/10/14.
//

import Foundation

open class ManifestBuilder {
    public init() {}
    
    func parseMasterPlaylist(_ reader: BufferedReader, onMediaPlaylist: ((_ playlist: MediaPlaylist) -> Void)?) -> MasterPlaylist {
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
    
    func parseMediaPlaylist(_ reader: BufferedReader, mediaPlaylist: MediaPlaylist = MediaPlaylist(), onMediaSegment: ((_ segment: MediaSegment) -> Void)?) -> MediaPlaylist {
        var currentSegment: MediaSegment?
        var currentSequence: Int = 0
        
        defer {
            reader.close()
        }
        
        while let line = reader.readLine() {
            if line.isEmpty {
                // skip empty lines
            } else if line.hasPrefix("#EXT") {
                // tags
                if line.hasPrefix("#EXTM3U") {
                    // do nothing
                } else if line.hasPrefix("#EXT-X-VERSION") {
                    do {
                        let version: String = try line.replace("(.*):(\\d+)(.*)", replacement: "$2")
                        mediaPlaylist.version = Int(version)
                    } catch {
                        print("Failed to parse the version of media playlist. Line = \(line)")
                    }
                } else if line.hasPrefix("#EXT-X-TARGETDURATION") {
                    do {
                        let durationString: String = try line.replace("(.*):(\\d+)(.*)", replacement: "$2")
                        mediaPlaylist.targetDuration = Int(durationString)
                    } catch {
                        print("Failed to parse the target duration of media playlist. Line = \(line)")
                    }
                } else if line.hasPrefix("#EXT-X-MEDIA-SEQUENCE") {
                    do {
                        let mediaSequence: String = try line.replace("(.*):(\\d+)(.*)", replacement: "$2")
                        if let mediaSequenceExtracted = Int(mediaSequence) {
                            mediaPlaylist.mediaSequence = mediaSequenceExtracted
                            currentSequence = mediaSequenceExtracted
                        }
                    } catch {
                        print("Failed to parse the media sequence in media playlist. Line = \(line)")
                    }
                } else if line.hasPrefix("#EXTINF") {
                    currentSegment = MediaSegment()
                    do {
                        let segmentDurationString: String = try line.replace("(.*):(\\d.*),(.*)", replacement: "$2")
                        let segmentTitle: String = try line.replace("(.*):(\\d.*),(.*)", replacement: "$3")
                        currentSegment!.duration = Float(segmentDurationString)
                        currentSegment!.title = segmentTitle
                    } catch {
                        print("Failed to parse the segment duration and title. Line = \(line)")
                    }
                } else if line.hasPrefix("#EXT-X-BYTERANGE") {
                    if line.contains("@") {
                        do {
                            let subrangeLength: String = try line.replace("(.*):(\\d.*)@(.*)", replacement: "$2")
                            let subrangeStart: String = try line.replace("(.*):(\\d.*)@(.*)", replacement: "$3")
                            currentSegment!.subrangeLength = Int(subrangeLength)
                            currentSegment!.subrangeStart = Int(subrangeStart)
                        } catch {
                            print("Failed to parse byte range. Line = \(line)")
                        }
                    } else {
                        do {
                            let subrangeLength: String = try line.replace("(.*):(\\d.*)", replacement: "$2")
                            currentSegment!.subrangeLength = Int(subrangeLength)
                            currentSegment!.subrangeStart = nil
                        } catch {
                            print("Failed to parse the byte range. Line = \(line)")
                        }
                    }
                } else if line.hasPrefix("#EXT-X-DISCONTINUITY") {
                    currentSegment!.discontinuity = true
                }
            } else if line.hasPrefix("#") {
                // Comments are ignored
            } else {
                // URI - must be
                if let currentSegmentExists = currentSegment {
                    currentSegmentExists.mediaPlaylist = mediaPlaylist
                    currentSegmentExists.path = line
                    currentSegmentExists.sequence = currentSequence
                    currentSequence += 1
                    mediaPlaylist.addSegment(currentSegmentExists)
                    if let callableOnMediaSegment = onMediaSegment {
                        callableOnMediaSegment(currentSegmentExists)
                    }
                }
            }
        }
        
        return mediaPlaylist
    }
}
