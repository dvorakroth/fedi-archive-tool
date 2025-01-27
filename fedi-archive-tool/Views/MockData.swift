//
//  MockData.swift
//  fedi-archive-tool
//
//  Created by Wolfe on 26.06.24.
//

import UIKit

class MockData {
    public static let posts = Array([
        APubActionEntry(
            id: "https://social.example.net/posts/123",
            actorId: MockData.actor.id,
            published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 24 * 3600)),
            action: .create(
                APubNote(
                    id: "https://social.example.net/posts/123",
                    actorId: MockData.actor.id,
                    published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 24 * 3600)),
                    visibilityLevel: .followersOnly,
                    url: "https://social.example.net/posts/123",
                    replyingToNoteId: nil,
                    cw: nil,
                    content: "<p>This is my first fake post!</p>",
                    searchableContent: "This is my first fake post!",
                    sensitive: false,
                    mediaAttachments: nil,
                    pollOptions: nil,
                    pollEndTime: nil,
                    pollIsClosed: nil
                )
            )
        ),
        APubActionEntry(
            id: "https://social.example.net/posts/133",
            actorId: MockData.actor.id,
            published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 24 * 3600)),
            action: .create(
                APubNote(
                    id: "https://social.example.net/posts/133",
                    actorId: MockData.actor.id,
                    published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 24 * 3600)),
                    visibilityLevel: ._public,
                    url: "https://social.example.net/posts/133",
                    replyingToNoteId: nil,
                    cw: nil, //"אזהרת תוכן בעברית",
                    content: "<p>זה פוסט עם טקסט בעברית<br>יש שבירות שורה<br>כדי לבדוק רינדור<br>של ימין לשמאל</p><p>וגם שבירת פסקה<br>בשביל הכיף ככה<br>באהבה אחי, עליי!</p>",
                    searchableContent: "",
                    sensitive: false, //true,
                    mediaAttachments: nil,
                    pollOptions: nil,
                    pollEndTime: nil,
                    pollIsClosed: nil
                )
            )
        ),
        APubActionEntry(
            id: "https://social.example.net/posts/124",
            actorId: MockData.actor.id,
            published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 24 * 3600)),
            action: .create(
                APubNote(
                    id: "https://social.example.net/posts/124",
                    actorId: MockData.actor.id,
                    published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 48 * 3600)),
                    visibilityLevel: .unlisted,
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
                    searchableContent: "", // TODO
                    sensitive: false,
                    mediaAttachments: nil,
                    pollOptions: nil,
                    pollEndTime: nil,
                    pollIsClosed: nil
                )
            )
        ),
        APubActionEntry(
            id: "https://social.example.net/posts/125",
            actorId: MockData.actor.id,
            published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 72 * 3600)),
            action: .create(
                APubNote(
                    id: "https://social.example.net/posts/125",
                    actorId: MockData.actor.id,
                    published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 72 * 3600)),
                    visibilityLevel: ._public,
                    url: "https://social.example.net/posts/125",
                    replyingToNoteId: nil,
                    cw: "broken images",
                    content: "<p>Post whomst contains three images, two broken</p>",
                    searchableContent: "Post whomst contains three images, two broken",
                    sensitive: true,
                    mediaAttachments: MockData.attachments,
                    pollOptions: nil,
                    pollEndTime: nil,
                    pollIsClosed: nil
                )
            )),
        APubActionEntry(
            id: "https://social.example.net/posts/126",
            actorId: MockData.actor.id,
            published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 96 * 3600)),
            action: .create(
                APubNote(
                    id: "https://social.example.net/posts/126",
                    actorId: MockData.actor.id,
                    published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 96 * 3600)),
                    visibilityLevel: .unknown,
                    url: "https://social.example.net/posts/126",
                    replyingToNoteId: "https://social.example.net/posts/125",
                    cw: "a poll about the images",
                    content: "<p>Which image is the best?</p>",
                    searchableContent: "Which image is the best?",
                    sensitive: false,
                    mediaAttachments: nil,
                    pollOptions: MockData.poll,
                    pollEndTime: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 120 * 3600)),
                    pollIsClosed: false
                )
            )
        ),
        APubActionEntry(
            id: "https://social.example.net/posts/127",
            actorId: MockData.actor.id,
            published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 120 * 3600)),
            action: .create(
                APubNote(
                    id: "https://social.example.net/posts/127",
                    actorId: MockData.actor.id,
                    published: Date(timeIntervalSince1970: TimeInterval(integerLiteral: 120 * 3600)),
                    visibilityLevel: ._public,
                    url: "https://social.example.net/posts/127",
                    replyingToNoteId: nil,
                    cw: "warning: mentions inside!",
                    content: "<p><span class=\"h-card\" translate=\"no\"><a href=\"https://social.example.net/users/admin\" class=\"u-url mention\">@<span>admin</span></a></span> for more questions, please:</p><h1>ask <span class=\"h-card\" translate=\"no\"><a href=\"https://social.example.net/users/notadmin\" class=\"u-url mention\">@<span>notadmin</span></a></span></h1>",
                    searchableContent: "@admin for more questions, please: ask @notadmin",
                    sensitive: true,
                    mediaAttachments: nil,
                    pollOptions: nil,
                    pollEndTime: nil,
                    pollIsClosed: nil
                )
            )
        )
    ].reversed())
    
    public static let poll = [
        APubPollOption(name: "The first", numVotes: 10),
        APubPollOption(name: "The second", numVotes: 2),
        APubPollOption(name: "The third", numVotes: 3),
        APubPollOption(name: "Secret fourth option", numVotes: 53)
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
        icon: (data: NSDataAsset(name: "dog-with-glasses.png", bundle: .main)!.data, path: "INVALID", mediaType: "image/png"),
        headerImage: (NSDataAsset(name: "god-damn-highway.jpg", bundle: .main)!.data, path: "INVALID", mediaType: "image/jpeg")
    )
    
    public static let attachments = [
        APubDocument(mediaType: "image/png", path: "INVALID", data: actor.icon!.0, altText: "a blurry photo of a dog", blurhash: "WA9Z_$j[00%2%M9ZE1jsxtWBa}xt00j?~pNGM{%M-:j[M|t7WBIU", focalPoint: nil, size: nil),
        APubDocument(mediaType: "image/png", path: "INVALID", data: nil, altText: "a broken image that doesn't work", blurhash: nil, focalPoint: nil, size: nil),
        APubDocument(mediaType: "image/png", path: "INVALID", data: nil, altText: "a broken image that doesn't work", blurhash: nil, focalPoint: nil, size: nil)
    ]
}
