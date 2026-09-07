> **Archived** — historical planning prompt for Chronicle (Blog Posts), now shipped. This is a
> point-in-time snapshot of the original ask; it does not track later changes. See the code and
> specs for current behavior.

#TASK
* Plan the development of a 'Blogpost App' to be integrated into BergstromDomain
* Start by suggesting 10 names for the new app and I will choose one before we develop any code
* Outline the main development blocks for developing the app. Before startting a new development block, summarise what you know and ask me to confirm and/or answer any design questions before progressing

#APP OVERVIEW
- The app should allow users to
  * Create blogs (Draft by default)
  * Pubish blogs
  * Edit both Draft and Published blogs
  * Delete own blogs
  * Share ownership of blogs, i.e. have more than one author with edit permissions
  * Blogs could be written either 'Raw' (Markdown) or 'Formatted' (WYSIWYG)
  * Blogs could contain text, images, videos, tables, links and embedded documents
  * Blogs should contain metadata such as Author(s), Categories (multi levels), Draft/Published, Created Date, Comment Count and Like Count
  * Browsing and Filtering by Author/Categories/Date
  * Searching (Title and/or Content for words)
- Use the existing Authentication, Authorisation and Classification 
- The app should have it's own landing page and left nav bar
- Signed in users should be able to comment and like posts

#DEVELOPMENT BLOCKS
## Create a post
* Title Frame
  * Title 		String			Mandatory
  * Blog Image		Upload image		Optional
  
* Metadata Frame
  * Category		Dropdown list		Optional for create but Mandatory for publishing
  						Categrories will be created by Admins, similar to Event Types
  * Sub Category	String			Optional (Mandatory if Sub-Sub Category is used)
  * Sub-Sub Category	String			Optional (Ideas for a better name?)
  * Add Author		String			Allow the user to search for additional users to add, similar as Contact Management when adding contacts
  
* Blog Post Frame
  * Raw/Formatted	Multi tab pane		Two panes two select from

* Action Frame
  Cancel | Save | Publish
  
Data validation for Save
* Unique 'User: Title'

## Read a post
* Title Frame
  * Title 		String			Mandatory
  * Blog Image		Image			If no image, display the Category icon if selected, else leave blank
  
* Metadata Frame
  * Category/Sub Category/Sub-Sub Category	If Sub Category and Sub-Sub Category are populated
  * Author(s)		String			Comma separated list of Authors
  * Comments Count
  * Likes count
  
* Blog Post Frame
  * Formatted		Text
  * Like 		Button

* Comments 
  * List of comments 	Text
  
* Action Frame
  Back to Blogs | Edit | Publish/Unpublish | Delete	Edit, Publish/Unpublish and Delete only available on your own blogs. Publish/Unpublish depending on current status


## Publish a post
Data validation for Publish: 
* Unique 'User: Title'
* Category
* Post

## Edit a post
* After each edit, the post should be Draft
* Either of the Author's should be able to edit a post

## Delete a post
* Either of the Author's should be able to delete a post
* Deleted posts to be stored for 7 days (restorable by admins)

## CRUD Blog Category
* Similar behaviour as for Event Type
* Available for Admin and Sys Admin

## Likes
* At the bottom of a post show 5 faces
  * 'face-grinning'
  * 'face-slightly-smiling'
  * 'face-neutral'
  * 'face-slightly-frowning'
  * 'face-angry'
* The current signed in user's like status should be 'face-neutral' by default and this should be indicated by highlighting the icon (can it be bold and or diffferent color?)
* The current signed in user can change the status at any time by clicking on any of the other icons, it should highlight the selected icon and update the stats for the post
* The stats should be calculated based on the values below divide by the number of users in the system
  * 'face-grinning' 		5
  * 'face-slightly-smiling'	4
  * 'face-neutral'		3
  * 'face-slightly-frowning'	2
  * 'face-angry'		1
* In the meta data for the post, display the likes as a 1-decimal value, for example 3.2 togeter with the icon corresponding to the value using normal rounding rules, 'face-neutral'

  

## Comments
* Signed in users can create a comment on a blog post
* Comments should have
  * Author thumbnail + Author full name + Created date 'dd-MMM-yyyy'
  * Comment
  * Actions (only visible to signed in users): Reply | Edit (only visible for the author of the comment) | Delete (only visible for the author of the comment)
* Comment count should be updated as: 1 comment in 1 thread
* All new comments should be on added on top, i.e. the oldest comments at the bottom
* Any reply to an existen comment should be indented and placed under the comment for which the reply is made
* 	Comment count should be updated as: 2 comments in 1 thread
* When deleting the top level comment, all replies will be deleted as well

## Browsing
* Rename 'Category/Sub Category/Sub-Sub Category' to 'Category/Subject/Topic'
* Replace the blog post index page with 'browsing' ('filtering' to be added later) to show a tree together with number of posts per Category
  * Clicking on a Category should naviagate down and show the Subjects within that Category together with the number of posts per Subject
  * Clicking on a Subject should naviagate down and show the Topics within that Subject and the number of posts per Topic
  * Clicking on a Topic should list the blogs for that topic
  
###Example - Top level
Chronicle (10)
├── Food (5)
├── Technology (5)

###Example - Clicking on Technology
Chronicle (10)
├── Technology (5)
│   ├── Network (1)
│   ├── Software Development (4)

###Example - Clicking on Software Development
Chronicle (10)
├── Technology (5)
│   ├── Software Development (4)
│   │   ├── Java (1)
│   │   ├── Ruby On Rails (3)

###Example - Clicking on Ruby On Rails
Chronicle >> Technology >> Software Development >> Ruby On Rails	Clickable 'URL' where each block takes you back to previous browsing view
Table withe the following columns
Blog Title | Author Icon + Full Name | Created | Comments | Smiles

Blog Title to be a link to the blog post
Created - Date in format 'dd-MMM-yyyy'
Comments - Integer number of comments
Smiles - Smile icon + 1-decimal number as previously calculated


## Filtering
* Add a blog post 'filtering' page
* Probably overkill for this app but I believe I will use it for future apps so I will implement this now, a toggle switch between 'Basic' and 'SQL' 
  * Basic - The user can select values from one or several dropdowns to narrow down the list of blog posts listed
  * Filter drop-downs
    * Category - Include every Category + 'All Categories' (default value)
    * Subject - Include every Subject + 'All Subjects' (default value)
    * Topic - Include every Topic + 'All Topic' (default value)
    * Author - Include every Author + 'All Topic' (default value)
    * Created - Today, This Week, This Month, This Year, Anytime
  * SQL - A basic text field allowing the user to write simple SQL (allowing more complex searching similar to Jira's JQL)
  * The result table for either search method to include the following columns and the user should be able to sort the result by either of them
      * Category
      * Subject
      * Topic 
      * Blog Title 		Link to the actual blog
      * Author (showing Author Icon + Full Name
      * Created
      * Comments
      * Smiles
## Left Navbar
Last piece of the app, the left navigation bar. Similar to Event Tracker
* VIEWS				H1
  * Chronicle			H2
    * Chronicle			Clickable link to Chronicle landing page (Same as selecting Apps >> Chronicle)
  * Posts
    * Browse Posts		Clickable link
    * Filter Posts		Clickable link
  * My Posts			H2
    * My Published Posts	Clickable link - Should take the user to Filtered Post where author = Current user and Published = True
    * My Unpublished Posts	Clickable link - Should take the user to Filtered Post where author = Current user and Published = False
  * Categories			H2
    * Blog Categories		Clickable link
* ACTIONS			H1 - Only visible for signed in users
  * Create A Post		Clickable link
  * Create A Blog Category	Clickable link
* EXPORTS			H1 - Only visible for signed in users
  * Download Blog Posts		Clickable link - Possibility to download posts as PDF (more or less Print from the browser) as well as CSV with the actual post in markdown format
* HOW TO			H1
  * User Guide			Clickable link - The user guide is not yet developed
    






  
