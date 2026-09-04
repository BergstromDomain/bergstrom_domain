#Chromicles Test Observations

##General layout issues (not caused by this app)
Might have to review styles and layouts once I have a few more apps
* Top navbar alignment
  * Each drop-down (Apps, Info, System Admin) left of the page center should be left aligned with the drop-down title
* Top navbar should stand out more - Larger font and/or brighter color
* Left navbar should stand out more - Larger font and/or brighter color
* Need to implement nicer toast messages throughout the app, will save that for later


##Chronicle landing page
* I need to add an app image

##Routing
* Landing page http://localhost:3000/chronicle
* All the underlying paths are http://localhost:3000/blog-posts
* Should the routes file be update?
* I have been postponing prefixing with user's namespace, will probably wait a bit longer with that
* Is it worth adding /components/subject[If applicable]/topic[if applicable] as part of the URL?


##Create A Post
* Renema the left navbar link to "Create A Blog Post" for consistency
* The small create form looks a bit silly and forces the user to scroll even for oneliner posts, update the page to use the whole frame like the show page
* The size of the text box changes when swapping between Raw and Formatted. Fix the size when swapping between the two


##Show A Post
* Move the post image so that it sits together with the title on the top
* Move the meta data block above the actual post
* Color the smiles Dark-Green, Green, Yellow, Orange, Red
  * Both when selecting and for the overall score
* Images pasted in the formatted post field are saved but not displayed in on the show page
* Add support for syntax highlighting 

##Comments
* Expand the reply comment box to be full screen
* Add time of the comment, "31-Aug-2026 19:45", i.e. 24-hour time
* Use Brisbane time for now (or is the data already stored in UTC in the database?)
  * A possible future enhancement would be to display in local time based on the user
* Update comments to be rich text and support images (no need for markdown support)
* Add icons infront of the actions 'message-circle-reply', 'pencil', 'thrash-2'

##Edit A Post
* Move the post image so that it sits together with the title on the top
* Move the meta data block above the actual post
* Color the smiles Dark-Green, Green, Yellow, Orange, Red
  * Both when selecting and for the overall score
  
##Publish/Unpublish A Post
* It's confusing for the user when the post is getting unpublished
  * Add " - [icon: 'book-dashed'] DRAFT" after the title for unpublished posts (and remove it when publishing)
  
##Filter
* The actual filter takes up way to much space, change the layout and put all filters on one (or two) rows
* Add a 'Clear Filter' button which should reset all filters

##Download
* This whole section is not good, please remove the EXPORT from the left navbar
* I will add this later once I have created several real posts and get a better feel for it

