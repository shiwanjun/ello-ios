//
//  StreamEmbedCell.swift
//  Ello
//
//  Created by Ryan Boyajian on 4/20/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

public class StreamEmbedCell: StreamImageCell {
    static let reuseEmbedIdentifier = "StreamEmbedCell"

    @IBOutlet weak var playIcon: UIImageView!
    public var embedUrl: NSURL?

    @IBAction override func imageTapped() {
        if let url = embedUrl {
            postNotification(externalWebNotification, value: url.URLString)
        }
    }

    public func setPlayImageIcon(icon: InterfaceImage) {
        playIcon.image = icon.normalImage
    }
}
