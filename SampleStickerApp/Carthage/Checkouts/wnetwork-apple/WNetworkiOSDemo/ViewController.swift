//
//  ViewController.swift
//  WNetworkiOSDemo
//
//  Created by aramik on 7/10/16.
//
//

import UIKit
import WAssetManager


class ViewController: UIViewController {

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var connectionTypeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.


        // Add observer to monitor connection status
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.updateConnectionType(_:)) , name: WNetworkNotification.ConnectionChanged, object: nil)
       
        
    }

    func updateConnectionType(sender:NSNotification) {
        if let connection = sender.userInfo?["connectionType"] as? String {
            self.connectionTypeLabel.text = connection
        }
    }


    @IBAction func startDownload(sender:UIButton) {


       
        
       let _ = WNetworkSpeedCheck(url: "https://upload.wikimedia.org/wikipedia/commons/5/5a/Juno_space_probe.jpg", timeout: 30, completionHandler: { mbps, error in
            print(mbps)
        } )
        let mn = WNDownloader(maxConncurrent: 10)
        let dummyAssets = [
            "https://upload.wikimedia.org/wikipedia/commons/5/5a/Juno_space_probe.jpg",
            "https://fsmedia.imgix.net/86/fe/99/bc/def9/4995/aa9e/bb4f537e3d74/pluto.jpeg",
            "https://d3q6cnmfgq77qf.cloudfront.net/keyboards/kimoji/masters/-KH8Jq7giyi5QEC08klC_christmas_bikini01_emoji_1462592823925.png",
            "https://d3q6cnmfgq77qf.cloudfront.net/keyboards/kimoji/masters/-KH8Jq7pNQxFZ7YKxm8-_christmas_candycanes_emoji_1462592823934.png"
        ]
        mn.download(dummyAssets, progressHandler: { savedAssetUrl, progress in
            self.progressView.progress = Float(progress)
            }, completionHandler: {
                print("done!")
        })
    }

    @IBAction func clearAllFiles(sender:UIButton) {
        WAssetManager.sharedInstance.clearAllFilesInDocumentsDirectory()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

