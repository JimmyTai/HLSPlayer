//
//  ContentView.swift
//  Shared
//
//  Created by JimmyTai on 2022/10/7.
//

import SwiftUI
import AVKit

class PlayerManager: NSObject, M3u8ResourceLoaderDelegate {
    
    let asset: AVURLAsset
    let playerItem: AVPlayerItem
    let player: AVPlayer
    
    override init() {
        asset = AVURLAsset(url: URL(string: "m3u8Scheme://watch.swag.live/60ca1f7d6c648bdd7c95542f/public-blurout-3-27.m3u8")!)
        asset.resourceLoader.setDelegate(M3u8ResourceLoader.shared, queue: .main)
        playerItem = AVPlayerItem(asset: asset)
        if #available(iOS 9.0, *) {
            playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        }
        player = AVPlayer(playerItem: playerItem)
        super.init()
        M3u8ResourceLoader.shared.delegate = self
        print("[PlayerManager] prepare done")
    }
    
    var count: Int = 0
    
    func onMediaPlaylistLoad(playlist: MediaPlaylist) {
        guard let lastEvent = playerItem.accessLog()?.events.last else {
            return
        }
        
        
        for range in player.currentItem?.seekableTimeRanges ?? [] {
            let r: CMTimeRange = range as! CMTimeRange
            print("[PlayerManager] seekable range => start: \(r.start), duration: \(r.duration)")
        }
        print("[PlayerManager] first segment sequence: \(playlist.segments.first?.sequence)")
        guard let firstSequenceId: Int = playlist.segments.first?.sequence else { return }
        var timeOffset: Int
        if firstSequenceId % 10 <= 1 {
            timeOffset = firstSequenceId % 10 * 3
        } else {
            timeOffset = (10 - (firstSequenceId % 10)) * 3
        }
        let seekableRanges = player.currentItem!.seekableTimeRanges
        guard seekableRanges.count > 0 else {
            return
        }
        
        let range = seekableRanges.last as! CMTimeRange
        let livePosition = range.start + range.duration
        
        let minus = CMTime(seconds: Double(12 - timeOffset), preferredTimescale: Int32(NSEC_PER_SEC))
        let time = livePosition - minus
        
        
        if count == 1 {
            print("[PlayerManager] seek")
            player.seek(to: time)
        }
        count += 1
    }
}

class M3u8ResourceLoader : NSObject, AVAssetResourceLoaderDelegate {
    /// 假的链接(乱写的，前缀反正不要http或者https，后缀一定要.m3u8，中间随便)
    fileprivate let m3u8_url_vir: String = "m3u8Scheme://watch.swag.live/60ca1f7d6c648bdd7c95542f/public-blurout-3-27.m3u8"
    
    fileprivate var m3u8_host: String = "https://watch.swag.live/60ca1f7d6c648bdd7c95542f"
    
    /// 真的链接
    fileprivate var m3u8_url: String = "https://watch.swag.live/60ca1f7d6c648bdd7c95542f/public-blurout-3-27.m3u8"
    
    /// 单例
    fileprivate static let instance = M3u8ResourceLoader()
    
    /// 获取单例
    public static var shared: M3u8ResourceLoader {
        get {
            return instance
        }
    }
    
    public var delegate: M3u8ResourceLoaderDelegate?
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        /// 获取到拦截的链接url
        guard let url = loadingRequest.request.url?.absoluteString else {
            return false
        }
        
        //        print("[PlayerManager] resource loader url: \(url)")
        
        let targetUrl: String = url.replacingOccurrences(of: "m3u8Scheme", with: "https")
        
        if url.hasSuffix(".m3u8") {
            if let data = self.M3u8Request(targetUrl) {
                let dataStr: String = String(decoding: data, as: UTF8.self)
                if url.hasSuffix("/preview-blurout-3-27.m3u8") {
                    let mediaPlaylist: MediaPlaylist = ManifestBuilder().parseMediaPlaylist(StringBufferedReader(data: dataStr), onMediaSegment: nil)
                    DispatchQueue.main.async {
                        self.delegate?.onMediaPlaylistLoad(playlist: mediaPlaylist)
                    }
                }
                DispatchQueue.main.async {
                    /// 将数据塞给系统
                    loadingRequest.dataRequest?.respond(with: data)
                    
                    /// 通知系统请求结束
                    loadingRequest.finishLoading()
                }
            } else {
                
                DispatchQueue.main.async {
                    
                    /// 通知系统请求结束，请求有误
                    self.finishLoadingError(loadingRequest)
                }
            }
        } else {
            DispatchQueue.main.async {
                loadingRequest.redirect = URLRequest(url: URL(string: targetUrl)!)
                loadingRequest.response = HTTPURLResponse(url: URL(string: targetUrl)!, statusCode: 302, httpVersion: nil, headerFields: nil)
                if let data = try? Data(contentsOf: URL(string: targetUrl)!) {
                    
                    /// 将操作后的数据塞给系统
                    loadingRequest.dataRequest?.respond(with: data)
                    
                    /// 通知系统请求结束
                    loadingRequest.finishLoading()
                    
                } else {
                    
                    /// 通知系统请求结束，请求有误
                    self.finishLoadingError(loadingRequest)
                }
            }
        }
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        
        /// 获取到拦截的链接url
        guard let url = renewalRequest.request.url?.absoluteString else {
            return false
        }
        
        //        print("[PlayerManager] renewal request url: \(url)")
        
        return false
    }
    
    /// 为了演示，模拟同步网络请求，网络请求获取的是数据Data
    func M3u8Request(_ url: String) -> Data? {
        let sem = DispatchSemaphore(value: 0)
        var responseData: Data?
        URLSession.shared.dataTask(with: URL(string: url)!) { data, response, error in
            responseData = data
            sem.signal()
        }.resume()
        sem.wait()
        
        return responseData
    }
    
    /// 请求失败的，全部返回Error
    func finishLoadingError(_ loadingRequest: AVAssetResourceLoadingRequest) {
        loadingRequest.finishLoading(with: NSError(domain: NSURLErrorDomain, code: 400, userInfo: nil) as Error)
    }
}

protocol M3u8ResourceLoaderDelegate: NSObjectProtocol {
    func onMediaPlaylistLoad(playlist: MediaPlaylist) -> Void
}

struct ContentView: View {
    let playerManager: PlayerManager = PlayerManager()
    
    var body: some View {
        VideoPlayer(player: playerManager.player).onAppear {
            playerManager.player.play()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
