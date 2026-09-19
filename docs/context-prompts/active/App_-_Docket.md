#TASK
* Plan the development of 'Docket', a ToDo app to be integrated into BergstromDomain
* Outline the main development blocks for developing the app. Before starting a new development block, summarise what you know and ask me to confirm and/or answer any design questions before progressing
* Follow previously TDD methodology with clear tests, keeping the test coverage above 95%

#APP OVERVIEW
- The app should allow users to
  * Create one or several todo lists
  * Share ownership of todo lists, i.e. have more than one owner with edit permissions
  * List todo lists where the user is the owner (either sole owner or shared owner)
  * Edit todo list where the user is the owner (either sole owner or shared owner)
  * Delete todo list where the user is the owner (either sole owner or shared owner)
  * CRUD items in available todo lists
  * Todo list should contain metadata such as Owner(s), Categories (multi levels), Status, Due dates
  * Filtering by Author/Categories/Date
- Use the existing Authentication, Authorisation and Classification 
- The app should have it's own landing page and left nav bar


#DEVELOPMENT BLOCKS
## Create a todo list
* Title Frame
  * Title 		String			Mandatory
  * Description		Text			Mandatory
  * Todo list Image	Upload image		Optional
  
* Metadata Frame
  * Category		Dropdown list		Mandatory
  						Categories will be created by Admins, similar to Event Types
  * Sub Category	String			Optional (Mandatory if Sub-Sub Category is used)
  * Sub-Sub Category	String			Optional (Please suggest a better namefor this field)
  * Add Owner		String			Allow the user to search for additional users to add, similar as Contact Management when adding contacts
  
* Action Frame
  Cancel | Save


## Read a post
* Title Frame
  * Title 		String			Mandatory
  * Todo Image		Image			If no image, display the Category icon
  
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



## Edit a post
* After each edit, the post should be Draft
* Either of the Author's should be able to edit a post

## Delete a ToDo list
* Either of the Owner's should be able to delete a todo list
* Deleted todo list to be stored for 30 days (restorable by admins). Same functionality as for blog posts

## CRUD ToDo Category
* Similar behaviour as for Event Type
* Available for Admin and Sys Admin




