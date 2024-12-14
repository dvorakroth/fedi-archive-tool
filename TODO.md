todo list i guess!
==================

basic functionality
-------------------

* DONE? ~~media files~~
    * DONE ~~save to db~~
    * DONE ~~display~~
    * DONE? ~~make it look non shitty~~
* DONE ~~poll options~~
    * DONE ~~save to db~~
    * DONE ~~display~~
    * DONE ~~import & save poll end time~~
    * DONE ~~display poll end time~~
* DONE ~~display announces~~
* search!!!
    * through all posts
    * DONE ~~through a specific actor's posts~~
    * DONE ~~don't search through raw HTML! on import, create some kind of html-stripped field to actually search through~~
    * DONE ~~also search through cw, poll options, and alt text of attachments~~
    * make it look non shitty
    * DONE ~~don't include announces~~
* DONE ~~ability to delete an actor + their posts~~
* DONE ~~convert the HTML into an `AttributedString` or sth idk~~
* DONE? ~~placeholder images for when media/avatar/header *was* specified, but just wasn't found in the archive?~~
* DONE? ~~instead of "Go to Profile" and "Permalink" buttons, use the built-in share sheet~~
* DONE ~~divide actor's posts into Posts, Posts+Replies, Media~~
* DONE ~~separate view for DMs?~~
* DONE ~~title in navigation view when looking at a profile~~
* DONE ~~show little icon when post is a reply to something~~
* DONE ~~post privacy levels~~
    * DONE ~~figure out how the fuck this is encoded in the json~~
    * DONE ~~parse and save~~
    * DONE ~~display an icon or some shit~~

slightly advanced functionality
-------------------------------

* DONE ~~import new/updated archives in the background~~
    * DONE ~~with some sort of queue~~
    * DONE ~~whose progress is shown in the "add archive" view~~
    * DONE ~~basically the add archive view should not suck~~
    * DONE ~~also do the import in a transaction so if it fails we don't get partial data in the DB~~
    * DONE ~~automatically refresh the main view when an import is done~~
    * DONE ~~let the user see details about import errors~~
    * DONE ~~actually show vaguely readable details in the error messages instead of just "The Operation Could Not Be Completed(tm)"~~
* detail view for individual posts
    * show any replies that might be in the DB
    * show what the post might be replying to
* DONE ~~convert the HTML into individual SwiftUI components or something???? (that way block elements like lists and blockquotes and whatnot will be more.... believeable)~~
* unified view of all posts from all actors
* accessibility stuff??? idk 😬
* better UI for media tab in ActorView? (grid view like in mastodon web ui?)
* click on images to embiggen
    * DONE ~~basic functionality~~
    * DONE ~~show the images uh, bigger~~
    * DONE ~~also work on search page~~
    * WONTFIX not worth it lol ~~show little blips counting the index of this media attachment~~
    * DONE ~~videos?????? idk~~
    * DONE ~~audio clips????????? idk2~~
    * DONE ~~option to zoom~~
    * DONE ~~disable zoom when there's no media to show~~
    * DONE ~~option to save?~~
    * DONE ~~finish implementing needlessly difficult save dialog on mac catalyst~~
    * DONE ~~save unrecognized media?~~
    * DONE ~~show alt text!~~
    * DONE ~~show alt text in a non-awful way? ("Show More")~~
    * WONTFIX apple bug ~~why isn't the text properly selectable,,,,,~~
    * DONE ~~show title ("Alt Text") on alt text sheet~~
    * zooming in on desktop? + double tap to zoom on mobile
    * DONE ~~TODO comment about deleting the temp file in ShareSheetView~~
    * DONE ~~keep original attachment filenames, for saving~~
    * DONE ~~major refactor in how attachments are stored: store actual files on the filesystem! that way AVPlayer and share sheets won't need the annoying temp files kludge~~
    * DONE ~~use the new refactored attachment import code to better utilize both AVPlayer and the share sheet, with no temp files~~
    * gap above the AVPlayer so you can see the close/alt/share buttons more clearly
* when searching, highlight the places where the text matches
* when a post's text is hidden, still show all @mention links (and only them), like in the mastodon web ui
* in actor view, use a GeometryReader to make the Posts/Posts&Replies/Media "tabs" "responsive"
* in post view, change attachment icon by attachment type(s)
* revisit whether it's still necessary to distinguish in the DB between announcing one's own post and announcing another user's post
* DONE ~~in import queue, give imports an actual progress bar circle thing~~

performance optimizations
-------------------------

* DONE? ~~scrolling through an actor's posts is kinda choppy?~~
    * DONE ~~could it be that this would be fixed by precomputing blurhashes on import???~~
    * ~~or maybe by making the post-loading thing async/in a different thread?~~
* DONE ~~when reading `actions INNER JOIN notes` from the DB, don't dump out the `notes.*` -- use it to create the APubNote~~

have to do before publishing lol
--------------------------------

* about page lol
* localization??????

bugs and workarounds
--------------------

* DONE ~~on iPad/Mac, when deleting an actor, navigate away from its ActorView if open~~
* deleting an actor makes the actor list freeze??
* on mac catalyst, in PostView, the "Show less" button doesn't work when the attachment is hidden
* on mac catalyst, because of how UIActivityViewController works, there's always a blank popover, with the actual share sheet popover next to it; find some workaround for this bullshit i guess!!! or not lol
* show RTL text properly; just,,, in general,
* perform deletions async so they don't stick the ui thread?
* deleting an actor while an import for it is ongoing causes a crash? -- maybe, add deletions to the import queue
* it seems like my mastodon server is actually exporting malformed `outbox.json` files right now!!! they contain two `orderedItems` properties, and Swift's JSON parser seems to just ignore the second one, so we always get an empty array for it
    ```json
    "type": "OrderedCollection",
    "totalItems": 15687,
    "orderedItems": [],
    "orderedItems": [
        {
            "id":
    ```
