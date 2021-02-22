//
//  SampleHandler.swift
//  RikiBroadcastExtension
//
//  Created by ThinhND3 on 03/02/2021.
//

import ReplayKit
import HaishinKit
import VideoToolbox
import Logboard
let logger = Logboard.with("com.Rikkeisoft.RikiLive.RikiBroadcastExtension")
class SampleHandler: RPBroadcastSampleHandler {
    private lazy var rtmpConnection: RTMPConnection = {
        let connection = RTMPConnection()
        connection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusEvent), observer: self)
        connection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        return connection
    }()

    private lazy var rtmpStream: RTMPStream = {
        RTMPStream(connection: rtmpConnection)
    }()

    deinit {
        rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusEvent), observer: self)
    }
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        logger.level = .debug
        Logboard.with(HaishinKitIdentifier).level = .trace
        rtmpConnection.connect("rtmp://192.53.113.159:1935/RiriLive", arguments: nil)
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        rtmpStream.close()
        // User has requested to finish the broadcast.
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Handle video sample buffer
            if let description = CMSampleBufferGetFormatDescription(sampleBuffer) {
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                rtmpStream.videoSettings = [
                    .width: dimensions.width,
                    .height: dimensions.height ,
                    .profileLevel: kVTProfileLevel_H264_High_AutoLevel,
                    .bitrate: 160 * 1000
                ]
                rtmpStream.captureSettings = [
                    .fps: 60
                ]
            }
            rtmpStream.appendSampleBuffer(sampleBuffer, withType: .video)
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            rtmpStream.appendSampleBuffer(sampleBuffer, withType: .audio)
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
    
    @objc
    private func rtmpErrorHandler(_ notification: Notification) {
        logger.info(notification)
        rtmpConnection.connect("rtmp://192.53.113.159:1935/RiriLive")
    }

    @objc
    private func rtmpStatusEvent(_ status: Notification) {
        let e = Event.from(status)
        logger.info(e)
        guard
            let data: ASObject = e.data as? ASObject,
            let code: String = data["code"] as? String else {
            return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            rtmpStream.publish("streamTest1")
        default:
            break
        }
    }
}
