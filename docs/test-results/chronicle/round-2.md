#Chromicles Test Observations part 2

##Browse Blog Posts
* Rename the page and the link in the left navbar to 'Browse Blog Posts'
* Move 'Chronicle (4)' to the browsing tree below allowing user to navigate up again after viewing a category
* Eager loading detected
  user: nik
  AVOID eager loading detected
  BlogPost => [:authors, :blog_post_authors, :blog_category]
  Remove from your query: .includes([:authors, :blog_post_authors, :blog_category])
  Call stack
  /home/nik/src/rails/bergstrom_domain/app/models/blog_post.rb:107:in 'BlogPost#like_score'
* Update the table to be a list of "blog cards" ordered by created date
  * Card Row-1: Blog Thumbnail + Blog Title - H2 Link to the actual post
  * Card Row-2: Author (bold): Niklas Bergstrom | Created (bold): 31-Aug-2026 | Likes (bold): Icon +3.3
  * Card Row-3: Add the first 200 characters from the post as a teaser

##Filter Blog Posts
* Rename the page and the link in the left navbar to 'Filter Blog Posts'
* Update the 'Blog Title' column to display 'Blog Thumbnail + Blog Title'
* Add a column 'Summary' after the 'Blog Title' column, include first 200 characters
* Remove the 'Comments' column from the table
* Add a column 'Published' showing either the icon 'book-checked' for Published or the icon 'book-dashed' for Draft
* Eager loading detected
  user: nik
  USE eager loading detected
  BlogPost => [:likes]
  Add to your query: .includes([:likes])
  Call stack
  /home/nik/src/rails/bergstrom_domain/app/controllers/blog_posts_controller.rb:53:in 'BlogPostsController#filter'
