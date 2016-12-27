//
//  VideoViewController.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 26.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

import Foundation
import UIKit

class VideoViewController: UIViewController {
    
    @IBOutlet weak var videoView: GVRVideoView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoView.delegate = self;
        videoView.enableFullscreenButton = true;
        videoView.enableCardboardButton = true;
        videoView.enableTouchTracking = true;

        // Load the sample 360 video, which is of type stereo-over-under.
        let videoPath: String = Bundle.main.path(forResource: "DE-AXA-One_second_away-Final_v3_short_360", ofType: "mp4")!
        videoView.load(from: URL(fileURLWithPath: videoPath), of: .mono)

    }
    override func viewWillDisappear(_ animated: Bool) {
        videoView.stop()
        videoView = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension VideoViewController: GVRVideoViewDelegate {
    func videoView(_ videoView: GVRVideoView!, didUpdatePosition position: TimeInterval) {
        if (position == videoView.duration()) {
            videoView.seek(to: 0)
        } else {
            videoView.play()
        }
        
        //https://developers.google.com/vr/ios/reference/struct_g_v_r_head_rotation
        var headRotation: GVRHeadRotation = videoView.headRotation
        headRotation.pitch = 0.0

    }
    func widgetViewDidTap(_ widgetView: GVRWidgetView!) {
    }
    func widgetView(_ widgetView: GVRWidgetView!, didLoadContent content: Any!) {
        videoView.play()
    }
    func widgetView(_ widgetView: GVRWidgetView!, didChange displayMode: GVRWidgetDisplayMode) {
        
    }
    func widgetView(_ widgetView: GVRWidgetView!, didFailToLoadContent content: Any!, withErrorMessage errorMessage: String!) {
        
    }
}
