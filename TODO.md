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
* separate view for DMs?
* DONE ~~title in navigation view when looking at a profile~~
* DONE ~~show little icon when post is a reply to something~~
* DONE ~~post privacy levels~~
    * DONE ~~figure out how the fuck this is encoded in the json~~
    * DONE ~~parse and save~~
    * DONE ~~display an icon or some shit~~

slightly advanced functionality
-------------------------------

* import new/updated archives in the background
    * DONE ~~with some sort of queue~~
    * DONE ~~whose progress is shown in the "add archive" view~~
    * DONE ~~basically the add archive view should not suck~~
    * also do the import in a transaction so if it fails we don't get partial data in the DB
    * automatically refresh the main view when an import is done
    * let the user see details about import errors
* detail view for individual posts
    * show any replies that might be in the DB
    * show what the post might be replying to
* convert the HTML into individual SwiftUI components or something???? (that way block elements like lists and blockquotes and whatnot will be more.... believeable)
* unified view of all posts from all actors
* accessibility stuff??? idk 😬
* better UI for media tab in ActorView? (grid view like in mastodon web ui?)
* click on images to embiggen
    * option to zoom
    * option to save?
    * show alt text!
* when searching, highlight the places where the text matches
* when a post's text is hidden, still show all @mention links (and only them), like in the mastodon web ui

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
* perform deletions async so they don't stick the ui thread
* it seems like my mastodon server is actually exporting malformed `outbox.json` files right now!!! they contain two `orderedItems` properties, and Swift's JSON parser seems to just ignore the second one, so we always get an empty array for it
    ```json
    "type": "OrderedCollection",
    "totalItems": 15687,
    "orderedItems": [],
    "orderedItems": [
        {
            "id":
    ```
