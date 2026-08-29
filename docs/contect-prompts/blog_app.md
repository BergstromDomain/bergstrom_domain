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
* TBD

## Comments
* TBD


