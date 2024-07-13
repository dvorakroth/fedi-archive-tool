//
//  MockData.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 26.06.24.
//

import Foundation

class MockData {
    public static let posts = [
        APubActionEntry(
            id: "https://social.example.net/posts/123",
            actorId: "https://social.example.net/users/mx123",
            published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 24 * 3600)),
            action: .create(
                APubNote(
                    id: "https://social.example.net/posts/123",
                    published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 24 * 3600)),
                    url: "https://social.example.net/posts/123",
                    replyingToNoteId: nil,
                    cw: nil,
                    content: "<p>This is my first fake post!</p>",
                    sensitive: false,
                    mediaAttachments: nil,
                    pollOptions: nil
                )
            )
        ),
        APubActionEntry(
            id: "https://social.example.net/posts/124",
            actorId: "https://social.example.net/users/mx123",
            published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 24 * 3600)),
            action: .create(
                APubNote(
                    id: "https://social.example.net/posts/124",
                    published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 48 * 3600)),
                    url: "https://social.example.net/posts/124",
                    replyingToNoteId: nil,
                    cw: "second post??",
                    content: """
<h1>Another post</h1>
<p>This is my second fake post!</p>
<ol>
    <li>One fish</li>
    <li>Two fish</li>
    <li>Fish of various colors:
        <ol>
            <li>Red fish</li>
            <li>Blue fish</li>
        </ol>
    </li>
</ol>
<p>End of the post</p><p>Wait actually there's more!! I lied! I actually have a lot more to say in this second example post! So so so much more! In fact I cannot contain myself with so much to say! Amazing amounts of things to say! Incredible, unbelieveable, scarcely reasonable amounts of things to say!</p><p>...</p><p>ok bye</p>
""",
                    sensitive: false,
                    mediaAttachments: nil,
                    pollOptions: nil
                )
            )
        ),
        APubActionEntry(
            id: "https://social.example.net/posts/125",
            actorId: "https://social.example.net/users/mx123",
            published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 72 * 3600)),
            action: .create(
                APubNote(
                    id: "https://social.example.net/posts/125",
                    published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 72 * 3600)),
                    url: "https://social.example.net/posts/125",
                    replyingToNoteId: nil,
                    cw: "broken images",
                    content: "<p>Post whomst contains three images, two broken</p>",
                    sensitive: true,
                    mediaAttachments: [
                        APubDocument(mediaType: "image/png", data: actor.icon!.0, altText: "a blurry photo of a dog", blurhash: nil, focalPoint: nil, size: nil),
                        APubDocument(mediaType: "image/png", data: nil, altText: "a broken image that doesn't work", blurhash: nil, focalPoint: nil, size: nil),
                        APubDocument(mediaType: "image/png", data: nil, altText: "a broken image that doesn't work", blurhash: nil, focalPoint: nil, size: nil)
                    ],
                    pollOptions: nil
                )
            ))
    ]
    
    public static let actor = APubActor(
        id: "https://social.example.net/users/mx123",
        username: "mx123",
        name: "Mx. 123",
        bio: "The elusive Mx. 123, at your service! Here to demonstrate all manners of UI, UX, GUI, CLI, and screenshots!",
        url: "https://social.example.net/@mx123",
        created: Date(timeIntervalSince1970: TimeInterval(3600)),
        table: [
            ("Pronouns", "they/them"),
            ("Am I real?", "No, I'm just a demo for the UI designer"),
            ("No, really, am I real?", "The very definition of \"real\" in this context is irrelevant! This is just data being typed in so the UI designer has something to display")
        ],
        icon: (Data(base64Encoded: "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")!, "image/png"),
        headerImage: ("""
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="1500" height="500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <rect x="0" y="0" width="250" height="250" fill="#000"/>
    <rect x="250" y="0" width="250" height="250" fill="#fff"/>
    <rect x="500" y="0" width="250" height="250" fill="#000"/>
    <rect x="750" y="0" width="250" height="250" fill="#fff"/>
    <rect x="1000" y="0" width="250" height="250" fill="#000"/>
    <rect x="1250" y="0" width="250" height="250" fill="#fff"/>

    <rect x="0" y="250" width="250" height="250" fill="#fff"/>
    <rect x="250" y="250" width="250" height="250" fill="#000"/>
    <rect x="500" y="250" width="250" height="250" fill="#fff"/>
    <rect x="750" y="250" width="250" height="250" fill="#000"/>
    <rect x="1000" y="250" width="250" height="250" fill="#fff"/>
    <rect x="1250" y="250" width="250" height="250" fill="#000"/>
</svg>
""".data(using: .utf8)!, "image/svg+xml")
    )
}
