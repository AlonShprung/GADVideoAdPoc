//
//  Copyright (C) 2015 Google, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import GoogleMobileAds
import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    // The view that holds the native ad.
    @IBOutlet weak var nativeAdPlaceholder: UIView!
    
    // Displays status messages about presence of video assets.
    @IBOutlet weak var videoStatusLabel: UILabel!
    
    // The refresh ad button.
    @IBOutlet weak var refreshAdButton: UIButton!
    
    // The SDK version label.
    @IBOutlet weak var versionLabel: UILabel!
    
    // Switch to indicate if video ads should start muted.
    @IBOutlet weak var startMutedSwitch: UISwitch!
    
    @IBOutlet weak var customTagTextField: UITextField!
    
    
    /// The ad loader. You must keep a strong reference to the GADAdLoader during the ad loading
    /// process.
    var adLoader: GADAdLoader!
    
    /// The native ad view that is being presented.
    var nativeAdView: UIView?
    
    /// The ad unit ID.
    let exampleAdUnitID = "/6499/example/native"
//    let adUnitID = "/175840252/fansided.com_app/fansided/video_test"
    
    var currentAdUnitID = "/6499/example/native" {
        didSet {
            refreshAd(self)
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        versionLabel.text = GADMobileAds.sharedInstance().sdkVersion
        refreshAd(nil)
        customTagTextField.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        refreshAdButton.isEnabled = true
        currentAdUnitID = textField.text ?? exampleAdUnitID
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        refreshAdButton.isEnabled = false
    }
    
    func setAdView(_ view: UIView) {
        // Remove the previous ad view.
        nativeAdView?.removeFromSuperview()
        nativeAdView = view
        nativeAdPlaceholder.addSubview(nativeAdView!)
        nativeAdView!.translatesAutoresizingMaskIntoConstraints = false
        
        // Layout constraints for positioning the native ad view to stretch the entire width and height
        // of the nativeAdPlaceholder.
        let viewDictionary = ["_nativeAdView": nativeAdView!]
        self.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[_nativeAdView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary)
        )
        self.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[_nativeAdView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary)
        )
    }
    
    // MARK: - Actions
    
    /// Refreshes the native ad.
    @IBAction func refreshAd(_ sender: AnyObject!) {
        nativeAdView?.removeFromSuperview()
        let adTypes: [GADAdLoaderAdType] = [.native]
        
        refreshAdButton.isEnabled = false
        let videoOptions = GADVideoOptions()
        videoOptions.startMuted = startMutedSwitch.isOn
        adLoader = GADAdLoader(
            adUnitID: currentAdUnitID, rootViewController: self,
            adTypes: adTypes, options: [videoOptions])
        adLoader.delegate = self
        adLoader.load(GADRequest())
        videoStatusLabel.text = ""
    }
    
    /// Updates the videoController's delegate and viewController's UI according to videoController
    /// 'hasVideoContent()' value.
    /// Some content ads will include a video asset, while others do not. Apps can use the
    /// GADVideoController's hasVideoContent property to determine if one is present, and adjust their
    /// UI accordingly.
    func updateVideoStatusLabel(hasVideoContent: Bool) {
        if hasVideoContent {
            // By acting as the delegate to the GADVideoController, this ViewController receives messages
            // about events in the video lifecycle.
            videoStatusLabel.text = "Tag: \(currentAdUnitID)\nAd contains a video asset."
        } else {
            videoStatusLabel.text = "Tag: \(currentAdUnitID)\nAd does not contain a video."
        }
    }
}

// MARK: - GADAdLoaderDelegate

extension ViewController: GADAdLoaderDelegate {
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
        videoStatusLabel.text = "Tag: \(currentAdUnitID)\nFailed: \(error.localizedDescription)"
        refreshAdButton.isEnabled = true
    }
}

// MARK: - GADNativeAdLoaderDelegate

extension ViewController: GADNativeAdLoaderDelegate {
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        print("Received native ad: \(nativeAd)")
        refreshAdButton.isEnabled = true
        // Create and place ad in view hierarchy.
        let nibView = Bundle.main.loadNibNamed("NativeAdView", owner: nil, options: nil)?.first
        let hasVideoContent = nativeAd.mediaContent.hasVideoContent
        updateVideoStatusLabel(hasVideoContent: hasVideoContent)
        guard let nativeAdView = nibView as? GADNativeAdView, hasVideoContent else {
            return
        }
        setAdView(nativeAdView)
        
        // Set ourselves as the native ad delegate to be notified of native ad events.
        nativeAd.delegate = self
        
        
        // By acting as the delegate to the GADVideoController, this ViewController receives messages
        // about events in the video lifecycle.
        nativeAd.mediaContent.videoController.delegate = self
        
        // This app uses a fixed width for the GADMediaView and changes its height to match the aspect
        // ratio of the media it displays.
        if let mediaView = nativeAdView.mediaView, nativeAd.mediaContent.aspectRatio > 0 {
            let heightConstraint = NSLayoutConstraint(
                item: mediaView,
                attribute: .height,
                relatedBy: .equal,
                toItem: mediaView,
                attribute: .width,
                multiplier: CGFloat(1 / nativeAd.mediaContent.aspectRatio),
                constant: 0
            )
            heightConstraint.isActive = true
        }
        
        // Associate the native ad view with the native ad object. This is
        // required to make the ad clickable.
        // Note: this should always be done after populating the ad views.
        nativeAdView.nativeAd = nativeAd
    }
}

// MARK: - GADVideoControllerDelegate implementation
extension ViewController: GADVideoControllerDelegate {
    
    func videoControllerDidEndVideoPlayback(_ videoController: GADVideoController) {
        videoStatusLabel.text = "Video playback has ended."
    }
}

// MARK: - GADNativeAdDelegate implementation
extension ViewController: GADNativeAdDelegate {
    
    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdWillDismissScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdDidDismissScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdWillLeaveApplication(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
}
