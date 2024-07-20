todo list i guess!
==================

basic functionality
-------------------

* media files
    * DONE ~~save to db~~
    * DONE ~~display~~
    * DONE? ~~make it look non shitty~~
    * click images to embiggen/save
* poll options
    * save to db
    * display
* display announces
* search!!!
    * through all posts
    * DONE ~~through a specific actor's posts~~
    * don't search through raw HTML! on load, create some kind of html-stripped field to actually search through
    * also search through alt text of attachments
    * eventually also search through poll options
* ability to delete an actor + their posts
* DONE ~~convert the HTML into an `AttributedString` or sth idk~~
* DONE? ~~placeholder images for when media/avatar/header *was* specified, but just wasn't found in the archive?~~
* instead of "Go to Profile" and "Permalink" buttons, use the built-in share sheet
* divide actor's posts into Posts, Posts+Replies, Media, DMs
* DONE ~~title in navigation view when looking at a profile~~
* show little icon when post is a reply to something
* post privacy levels
    * figure out how the fuck this is encoded in the json
    * parse and save
    * display an icon or some shit

slightly advanced functionality
-------------------------------

* load new/updated archives in the background
    * with some sort of queue
    * whose progress is shown in the "add archive" view
    * basically the add archive view should not suck
* detail view for individual posts
    * show any replies that might be in the DB
    * show what the post might be replying to
* convert the HTML into individual SwiftUI components or something???? (that way block elements like lists and blockquotes and whatnot will be more.... believeable)
* unified view of all posts from all actors
* accessibility stuff??? idk 😬
* click on images to embiggen
    * option to zoom
    * option to save?

performance optimizations
-------------------------

* scrolling through an actor's posts is kinda choppy?
    * could it be that this would be fixed by precomputing blurhashes on load???

have to do before publishing lol
--------------------------------

* about page lol
