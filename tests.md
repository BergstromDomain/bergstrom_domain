
Access control
  Happy path — public read access
    Allows 'Gary Guest' access to event types index
    Allows 'Gary Guest' access to event type show
    Allows 'Gary Guest' access to events index
    Allows 'Gary Guest' access to event show
    Allows 'Gary Guest' access to people index
    Allows 'Gary Guest' access to person show
  Negative path — 'Gary Guest' write access is blocked
    Redirects to the 'Sign-in' page when 'Gary Guest' visits new event type
    Redirects to the 'Sign-in' page when 'Gary Guest' visits edit event type
    Redirects to the 'Sign-in' page when 'Gary Guest' visits new event
    Redirects to the 'Sign-in' page when 'Gary Guest' visits edit event
    Redirects to the 'Sign-in' page when 'Gary Guest' visits new person
    Redirects to the 'Sign-in' page when 'Gary Guest' visits edit person
  Alternative path — Authenticated write access is allowed
    Allows 'Adam Admin' to access new event type
    Allows 'Adam Admin' to access edit event type
    Allows 'Charlie Content Creator' to access new event
    Allows 'Charlie Content Creator' to access edit event
    Allows 'Charlie Content Creator' to access new person
    Allows 'Charlie Content Creator' to access edit person
    Redirects 'Charlie Content Creator' away from new event type
    Redirects 'Charlie Content Creator' away from edit event type
  Edge cases
    Stores the originally requested URL and redirects 'Charlie Content Creator' after sign-in

Forgot Password
  Happy path
    Renders the page heading
    Renders the email panel
    Renders the email field
    Renders the 'Send Reset Link' button
    Renders the 'Cancel' button
    Shows a notice after submitting a valid email
  Negative path
    Shows a notice even for an unknown email (no enumeration)
  Alternative path
    Renders the page for an already-signed-in user
  Edge cases
    Shows the helper text explaining what happens next

Reset Password
  Happy path
    Renders the page heading
    Renders the reset panel
    Renders the new password field
    Renders the confirm password field
    Renders the 'Cancel' button
    Renders the 'Reset Password' button
    Resets the password and redirects to the 'Sign In' page
  Negative path
    Shows an alert when passwords do not match
  Alternative path
    Shows an error for an invalid token
  Edge cases
    Shows an alert when the new password is blank (PENDING: Temporarily skipped with xit)

Sign In
  Happy path
    Signs in with valid credentials and redirects to root
    Signs in and redirects to the originally requested URL
    Renders the email field
    Renders the password field
    Renders the 'Forgot password?' link
    Renders the 'Cancel' button
    Renders the 'Sign In' button on the right
  Negative path
    Stays on the sign-in page with an incorrect password
    Stays on the sign-in page with an incorrect email address
    Stays on the sign-in page with blank credentials
  Alternative path
    Signs in with email address in a different case
  Edge cases
    Does not redirect an already-signed-in user visiting sign in

Sign Out
  Happy path
    Signs out a signed-in user and redirects to the 'Home' page
    Prevents accessing write actions after signing out
  Negative path
    Does not expose a sign-out route for unauthenticated users
  Alternative path
    Destroys the session record on sign out
  Edge cases
    Handles multiple sign-ins and signs out cleanly

Sign Up
  Happy path
    Renders the info panel
    Renders the first name field
    Renders the last name field
    Renders the profile image field
    Renders the email address field
    Renders the password field
    Renders the password confirmation field
    Renders the message to admin field
    Renders the 'Cancel' button
    Renders the 'Sign Up' button
    Submits a valid request and redirects to root without signing in
    Creates the user with a pending status
  Negative path
    Shows an error when first name is blank
    Shows an error when last name is blank
    Shows an error when profile image is missing
    Shows an error when email address is blank
    Shows an error when email address is already taken
    Shows an error when password is blank
    Shows an error when password confirmation does not match
  Alternative path
    Creates an account with an email address in mixed case
    Submits a valid request with an optional message to admin
  Edge cases
    Is accessible to an unauthenticated visitor

Create event type
  Happy path
    Creates an event type with all required fields
  Negative path
    Shows an error when name is missing
    Shows an error when name is a duplicate (same case)
    Shows an error when name is a duplicate (different case)
    Shows an error when description is missing
    Shows an error when icon is missing
    Shows an error when icon is not a valid Lucide icon name
    Redirects 'Gary Guest' to the 'Sign in' page
    Redirects 'Charlie Content Creator' to the event types index
  Alternative path
    Re-renders the form with entered values when validation fails
    Allows 'Sam SysAdmin' to create an event type
  Edge cases
    Shows an error when icon has surrounding whitespace

Delete event type
  Happy path
    Deletes an event type with no associated events and redirects to index
    Removes the event type from the database
  Negative path
    Does not delete an event type that has associated events
    Shows an error when deletion is prevented by associated events
    Does not show the 'Delete' button to 'Charlie Content Creator'
    Does not show the 'Delete' button to 'Gary Guest'
  Alternative path
    Allows 'Sam SysAdmin' to delete an event type
  Edge cases
    Shows the 'Delete Event Type' button to an 'Adam Admin'

Edit event type
  Happy path
    Updates the name and regenerates the slug
    Updates the icon and shows the new icon on the show page
    Shows the edit form heading with the event type name
    Pre-populates the name field
    Pre-populates the icon field
    Shows a preview of the current icon on the edit form
  Negative path
    Shows an error when updated name is already taken
    Shows an error when icon is not a valid Lucide icon name
    Redirects 'Charlie Content Creator' to the event types index
    Redirects 'Gary Guest' to the 'Sign in' page
  Alternative path
    Old slug resolves to the record after a name change
    Re-renders the form with entered values when validation fails
    Allows 'Sam SysAdmin' to edit an event type
  Edge cases
    Shows an error when icon has surrounding whitespace
    Preserves the description when only the name is changed

List event types
  Happy path
    Displays the page title
    Displays all event types
    Displays event types in alphabetical order by name
    Renders an SVG icon for each event type
    Displays the description for each event type
    Links each event type name to its show page
  Negative path
    Displays an empty state message when no event types exist
  Alternative path
    Renders the same page regardless of authentication status
  Edge cases
    Sorts event types case-insensitively

Show event type
  Happy path
    Displays the event type name in the page title
    Renders the icon in the main panel
    Displays the event type description
    Displays the event type name in the metadata panel
    Shows a back link to the index
    Does not show the 'Edit' nor the 'Delete' buttons to 'Gary Guest'
    Is accessible by slug
  Negative path
    Returns 404 for a non-existent slug
    Does not show the 'Edit' nor the 'Delete' buttons to 'Charlie Content Creator'
    Does not show the 'Edit' nor the 'Delete' buttons to 'Uno User'
  Alternative path
    As 'Adam Admin'
      Shows the 'Edit' button
      Shows the 'Delete' button
      Shows the button divider between the 'Back' and the 'Edit' buttons
  Edge cases
    Handles an event type with a long name without breaking layout
    Shows both the 'Edit' and the 'Delete' buttons to 'Sam SysAdmin'

Create Event
  with valid attributes
    creates a new event and redirects to its page
  without an event type
    shows a validation error
  without people
    shows a validation error
  without a year
    is still valid
  with a missing title
    shows a validation error
  with a missing day
    shows a validation error
  with a duplicate title
    shows a uniqueness error
  with an image
    creates an event with an image and displays it on the show page (PENDING: Temporarily skipped with xit)

Delete Event
  deletes the event and redirects to the list
  reduces the event count by 1

Edit Event
  happy path
    displays the original title in the page heading
    pre-populates the title field
    updates the title and redirects to the show page
    updates the event type
    displays current people
  negative path
    shows a validation error when title is cleared
    redirects an unauthenticated visitor to sign in
    redirects a non-owner to the event show page
  alternative path
    preserves existing people when updating other fields
    allows updating the visibility
    allows an admin to edit any event
  edge cases
    preserves the slug history when title changes
    attaches the image and shows it on the show page (PENDING: Temporarily skipped with xit)

Event write authorization
  happy path
    allows the owner to edit their event
    allows the owner to delete their event
    allows an admin to edit any event
    allows an admin to delete any event
    allows a system_admin to edit even with a revoke override in place
    allows an app_user with a granted delete override to delete any event
  negative path
    redirects another user trying to edit the event
    does not show edit or delete links to a non-owner
    blocks an admin with a revoked delete override from deleting
    blocks a content_creator with a revoked create override from creating
  alternative path
    shows edit and delete links to the owner
    shows edit and delete links to an admin
    shows a delete button to an app_user with a granted delete override
    shows an edit link to an app_user with a granted update override
  edge cases
    redirects an unauthenticated user trying to edit
    allows a system_admin to create even with a revoked create override

Event visibility
  happy path
    shows unrestricted events to unauthenticated visitors on index
    shows unrestricted and contacts events to a confirmed contact on index
    allows a visitor to view an unrestricted event show page
    allows an authenticated user to view a contacts event show page
    allows an authenticated user to view a restricted event show page
  negative path
    redirects a visitor away from a contacts event show page
    redirects a visitor away from a restricted event show page
  alternative path
    shows the classification on the event show page for authenticated users
    shows unrestricted events to visitors even when contacts events also exist
  edge cases
    defaults to contacts classification when creating a new event
    redirects a visitor to index not sign-in when accessing a non-public event

Events By Day
  Happy Path
    When 'Gary Guest' visits 'Events by day' with no date param
      Shows today's heading
      Shows events on today's date
      Shows events from other years on the same day and month
      Does not show events from other days
      Shows the previous day navigation link
      Shows the next day navigation link
    When 'Gary Guest' visits with a specific date param
      Shows the correct heading for that date
      Shows events on that date
      Does not show events from other dates
    When 'Gary Guest' clicks the previous day link
      Navigates to the previous day
    When 'Gary Guest' clicks the next day link
      Navigates to the next day
  Negative Path
    When there are no events on the selected day
      Shows an empty state message
  Alternative Path
    When 'Uno User' is signed in
      Shows today's events while authenticated
  Edge Cases
    When an invalid date param is passed
      Falls back to today without raising an error

Events By Month
  Happy Path
    When 'Gary Guest' visits 'Events by month' with no params
      Shows the current month heading
      Shows events in the current month
      Does not show events from other months
      Shows previous and next month navigation links
    When 'Gary Guest' visits with year and month params
      Shows events in the specified month
    When 'Gary Guest' clicks the previous month link
      Navigates to the previous month
    When 'Gary Guest' clicks the next month link
      Navigates to the next month
  Negative Path
    When there are no events in the selected month
      Shows an empty state message
  Alternative Path
    When 'Uno User' is signed in
      Shows the current month while authenticated
  Edge Cases
    When invalid year and month params are passed
      Falls back to the current month without raising an error
    When month 13 is passed
      Falls back to the current month without raising an error
    When navigating from December to next month
      Navigates to January
    When navigating from January to previous month
      Navigates to December

Events By Week
  Happy Path
    When 'Gary Guest' visits 'Events by week' with no date param
      Shows the current week heading
      Shows events in the current week
      Does not show events outside the current week
      Shows previous week and next week navigation links
    When 'Gary Guest' visits with a specific date param
      Shows events in the week containing that date
    When 'Gary Guest' clicks the previous week link
      Navigates to the previous week
    When 'Gary Guest' clicks the next week link
      Navigates to the next week
  Negative Path
    When there are no events in the selected week
      Shows an empty state message
  Alternative Path
    When 'Uno User' is signed in
      Shows the current week while authenticated
  Edge Cases
    When an invalid date param is passed
      Falls back to the current week without raising an error
    When the week spans December and January
      Shows events from both December and January in the same week
      Does not show events with a day outside the week's day range

List events
  happy path
    displays the page title
    displays all events
    displays events in month, day, title order
    links each title to the event show page
    displays the date for each event
    displays the event type icon for each event
    shows the event type icon as thumbnail fallback when no thumbnail exists
    displays person icons for each event
    links each person icon to their show page
    shows person name as tooltip on hover
    shows the month navigation bar
    shows the pagination placeholder
  negative path
    shows an empty state when no events exist
    shows an empty state when no events match the selected month
  alternative path
    filters events by month when month param is present
    highlights the selected month in the navigation
    highlights All when no month is selected
    filters events by event type when event_type_id param is present
    sorts filtered month events by day then title
    shows a thumbnail image when one is attached
  edge cases
    ignores an invalid month param
    displays an event with no year using short date format
    wraps person icons when an event has multiple people

Show event
  happy path
    displays the event title in the page heading
    displays the description section
    displays the event date in the metadata panel
    displays the event type in the metadata panel
    displays the visibility in the metadata panel
    displays associated people in the metadata panel
    shows the admin panel with creator information
    shows a Back to Events button
    does not show Edit or Delete to an unauthenticated visitor
    is accessible via a friendly URL
    returns 404 for a non-existent event
  negative path
    does not show Edit or Delete to a non-owner
    does not show the description section when event has none
  alternative path
    shows Edit and Delete to the event owner
    displays multiple people as a comma-separated list
    links the event type name to the event type show page
    uses singular Person label for a single attendee
    uses plural People label for multiple attendees
  edge cases
    displays just day and month when year is absent
    shows Edit and Delete to an admin for any event

Export
  Happy path
    Allows 'Charlie Content Creator' to download a CSV with default scope
    Includes people with no events as a row with blank event columns
    Includes multiple events for the same person as separate rows
  Negative path
    Redirects 'Gary Guest' to the 'Sign in' page
    Shows a disabled export form to 'Uno User'
    Shows a flash error when no scope checkboxes are checked
  Alternative path
    Exports only public data when only 'Public data' is checked
  Edge cases
    Exports a CSV with only a header row when all scoped data is empty

Left Navigation
  Static Pages
    Is not present on the 'Home' page
    Is not present on the 'About' page
    Is not present on the 'Contact' page
    Is not present on the 'Blog Posts' page
  Happy Path
    When 'Gary Guest' visits the 'Events' index
      Shows the left nav
      Shows the 'Views H2' header
      Shows the 'Event Tracker' group and link
      Shows the 'Events' group with calendar links
      Shows the 'People' group and link
      Shows the 'Event Type' group and link
      Shows the 'How To' section with 'User Guide' link
      Does not show the 'Actions' section
      Does not show the 'Import & Export' section
    When 'Uno User' is signed in and visits the 'Events' index
      Shows the left nav
      Shows the 'Views' section
      Does not show the 'Actions' section
      Does not show the 'Import & Export' section
    When 'Charlie Content Creator' is signed in and visits the 'Events' index
      Shows the 'Actions H2' header
      Shows the 'Create Event' link
      Shows the 'Create Person' link
      Does not shows the Create Event Type link
      Shows the 'Import & Export' section
    When the 'Event Types' index is visited
      Shows the left nav
      Shows the 'Views' section
  Alternative Path
    When 'Gary Guest' clicks the 'Event Tracker' link
      Navigates to the 'Event Tracker' stub page
    When 'Gary Guest' clicks the 'User Guide' link
      Navigates to the 'User Guide' stub page
    When 'Gary Guest' clicks 'Events by day'
      Navigates to the 'Events by day' page
  Edge Cases
    When 'Adam Administrator' is signed in
      Shows the 'Actions' section
      Shows the 'Import & Export' section
    When 'Sam System Admin' is signed in
      Shows the 'Actions' section
      Shows the 'Import & Export' section

Layout shell
  When viewing as 'Gary Guest'
    Renders the top navigation bar
    Renders the footer
  When viewing as 'Charlie Content Creator'
    Renders the top navigation bar
    Renders the footer

Top navigation bar
  When viewing as 'Gary Guest'
    Shows the 'Home' link
    Shows the 'Apps' dropdown menu
    Shows the 'Info' dropdown menu
    Shows 'Event Tracker' link in the 'Apps' dropdown menu
    Shows 'Blog Posts' link in the 'Apps' dropdown menu
    Shows 'About' link in the 'Info' dropdown menu
    Shows 'Contact' link in 'Info' dropdown menu
    Does not show the 'System Admin' dropdown menu
    Shows the 'Sign In' button
    Does not show 'User Thumbnail' dropdown menu
    Does not show 'Sign Out' link in the 'User Thumbnail' dropdown menu
    Does not show 'User Settings' link in the 'User Thumbnail' dropdown menu
  When viewing as 'Uno User'
    Shows the 'Home' link
    Shows the 'Apps' dropdown menu
    Shows the 'Info' dropdown menu
    Shows 'Event Tracker' link in the 'Apps' dropdown menu
    Shows 'Blog Posts' link in the 'Apps' dropdown menu
    Shows 'About' link in the 'Info' dropdown menu
    Shows 'Contact' link in 'Info' dropdown menu
    Does not show the 'System Admin' dropdown menu
    Does not show the 'Sign In' button
    Shows 'User Thumbnail' dropdown menu
    Shows 'Sign Out' link in the 'User Thumbnail' dropdown menu
    Shows 'User Settings' link in the 'User Thumbnail' dropdown menu
  When viewing as 'Charlie Content Creator'
    Shows the 'Home' link
    Shows the 'Apps' dropdown menu
    Shows the 'Info' dropdown menu
    Shows 'Event Tracker' link in the 'Apps' dropdown menu
    Shows 'Blog Posts' link in the 'Apps' dropdown menu
    Shows 'About' link in the 'Info' dropdown menu
    Shows 'Contact' link in 'Info' dropdown menu
    Does not show the 'System Admin' dropdown menu
    Does not show the 'Sign In' button
    Shows 'User Thumbnail' dropdown menu
    Shows 'Sign Out' link in the 'User Thumbnail' dropdown menu
    Shows 'User Settings' link in the 'User Thumbnail' dropdown menu
  When viewing as 'Adam Admin'
    Shows the 'Home' link
    Shows the 'Apps' dropdown menu
    Shows the 'Info' dropdown menu
    Shows 'Event Tracker' link in the 'Apps' dropdown menu
    Shows 'Blog Posts' link in the 'Apps' dropdown menu
    Shows 'About' link in the 'Info' dropdown menu
    Shows 'Contact' link in 'Info' dropdown menu
    Does not show the 'System Admin' dropdown menu
    Does not show the 'Sign In' button
    Shows 'User Thumbnail' dropdown menu
    Shows 'Sign Out' link in the 'User Thumbnail' dropdown menu
    Shows 'User Settings' link in the 'User Thumbnail' dropdown menu
  When viewing as 'Sam SysAdmin'
    Shows the 'Home' link
    Shows the 'Apps' dropdown menu
    Shows the 'Info' dropdown menu
    Shows 'Event Tracker' link in the 'Apps' dropdown menu
    Shows 'Blog Posts' link in the 'Apps' dropdown menu
    Shows 'About' link in the 'Info' dropdown menu
    Shows 'Contact' link in 'Info' dropdown menu
    Shows the 'System Admin' dropdown menu
    Shows 'User Management' in 'System Admin' dropdown menu
    Shows 'App Management' in 'System Admin' dropdown menu
    Does not show the 'Sign In' button
    Shows 'User Thumbnail' dropdown menu
    Shows 'Sign Out' link in the 'User Thumbnail' dropdown menu
    Shows 'User Settings' link in the 'User Thumbnail' dropdown menu
  Sign out
    Signs the user out and redirects to root

About page
  Happy path
    When 'Gary Guest' visits the 'About' page
      Renders the 'Under Construction' paragraph
    When 'Uno User' is signed in and visits the 'About' page
      Renders the 'Under Construction' paragraph

Blog Posts page
  When 'Gary Guest' visits the 'Blog Posts' page
    Renders the 'Under construction' page
  When 'Uno User' is signed in and visits the 'Blog Posts' page
    Renders the 'Under construction' page

Contact page
  Happy path
    When 'Gary Guest' visits the 'Contact' page
      Renders the 'Under Construction' paragraph
    When 'Uno User' is signed in and visits the 'Contact' page
      Renders the 'Under Construction' paragraph

Event Tracker page
  Happy path
    When 'Gary Guest' visits the 'Event Tracker' page
      Renders the 'Under Construction' paragraph
    When 'Uno User' is signed in and visits the 'Event Tracker' page
      Renders the 'Under Construction' paragraph

Home page
  Happy path
    When 'Gary Guest' visits the 'Home' page
      Renders the 'Under Construction' paragraph
      Renders the 'Sign-Up' button
    When 'Uno User' is signed in and visits the 'Home' page
      Renders the 'Under Construction' paragraph
      Renders the 'Sign-Up' button

Static Pages
  'Home' page
    Renders without error
  'About' page
    Renders without error
  'Contact' page
    Renders without error

Create Person
  happy path
    creates a new person and redirects to their profile
    creates a person with an image and displays it on the show page (PENDING: Temporarily skipped with xit)
  negative path
    shows validation errors when first name is missing
    shows a duplicate name validation error
    redirects an unauthenticated visitor to sign in
  alternative path
    creates a person with only a first name
    defaults visibility to Contacts
  edge cases
    shows the original heading after a validation failure

Delete Person
  happy path
    deletes the person and redirects to the list
    reduces the person count by 1
  negative path
    does not show the delete button to a visitor
    does not show the delete button to a non-owner

Edit Person
  happy path
    displays the original full name in the page heading
    pre-populates the first name field
    updates the person's details and redirects to the show page
  negative path
    shows validation errors when first name is removed
    redirects an unauthenticated visitor to sign in
    redirects a non-owner to the person show page
  alternative path
    shows a uniqueness error when updating to a duplicate full name
    allows an admin to edit any person
    attaches the image and shows it on the show page (PENDING: Temporarily skipped with xit)
  edge cases
    preserves slug history when name changes

List People
  happy path
    when people exist
      displays all people
      links to each person's profile
      shows an Add Person link for content creators
      does not show an Add Person link for visitors
    when a person has an image
      displays their thumbnail
  negative path
    when no people exist
      shows an empty state message
  alternative path
    when a person has no image
      shows the fallback user icon
  edge cases
    lists people in case-insensitive alphabetical order by last name

Person authorization
  happy path
    allows a content creator to visit the new person page
    allows the owner to edit their person
    allows an admin to edit any person
  negative path
    redirects a visitor away from new person
    redirects a non-owner away from edit
    does not show the delete button to a non-owner
  alternative path
    allows an app user to view an unrestricted person
  edge cases
    redirects to sign in when an unauthenticated user attempts to delete

Person visibility
  happy path
    shows unrestricted people to unauthenticated visitors
    shows unrestricted and contacts people to the owner
  negative path
    hides contacts and restricted people from unauthenticated visitors
    redirects a visitor away from a restricted person's show page
  alternative path
    shows unrestricted people to an authenticated app user
    shows all people to an admin
  edge cases
    shows the classification on the show page

Show Person
  happy path
    displays the person's full name
    displays the description
    displays the main panel
    displays the metadata panel
    displays the actions panel
    is accessible via a friendly URL
  negative path
    returns 404 for a non-existent person
  alternative path
    shows edit and delete links for the owner
    does not show edit or delete links for a visitor
    shows the admin panel to the owner
    shows events panel when person has events
    hides events panel when person has no events
  edge cases
    resolves old slug after a name change

Edit User Settings
  Happy path
    Renders the 'Page Title' with the user's 'Full Name' and 'User Settings' subtitle
    Renders the 'Profile' panel
    Renders the 'Profile' image inside the 'Profile' panel
    Renders the 'First Name' field inside the 'Profile' panel
    Renders the 'Last Name' field inside the 'Profile' panel
    Renders the 'Profile Image' upload selector inside the 'Profile' panel
    Renders the 'Email Address' field inside the 'Profile' panel
    Renders the 'Preferences' panel
    Renders the 'Start Page' field inside the 'Preferences' panel
    Renders the 'Actions' panel
    Renders the 'Cancel' button inside the 'Actions' panel
    Renders the 'Update Details' button
    Navigates to the 'User Settings' page when the 'Cancel' button is clicked
    Updates 'Page Title' with the user's 'Full Name' when' First Name' and 'Last Name'
    Updates the 'Profile Image'
    Updates 'Start Page' with a new value (PENDING: Temporarily skipped with xit)
    Updates the 'Email Address' and clears the 'Email Verified' flag
  Negative path
    Redirects 'Gary Guest' to the 'Sign-In' page
    Shows an error when 'First Name' is blank
    Shows an error when 'Last Name' is blank
    Shows an error when 'Email Address' is already taken
  Alternative path
    Does not clear the 'Email Verified' flag when the 'Email Address' is unchanged
  Edge cases
    Does not save any of the changed values if the user clicks on the 'Cancel' button

User Settings
  Happy path
    Renders the 'Page Title' with the user's 'Full Name' and 'User Settings' subtitle
    Renders the 'Profile' panel
    Renders the 'Profile' image inside the 'Profile' panel
    Renders the 'Email Address' field inside the 'Profile' panel
    Renders the 'Unverified Email' icon inside the 'Profile' panelwhen the 'Email Address' is not verified
    Renders the 'Verified Email' icon inside the 'Profile' panel when the 'Email Address' is verified
    Renders the 'Verify Email' button inside the 'Profile' panel when the 'Email Address' is not verified
    Does not render the 'Verify Email' button inside the 'Profile' panel when the 'Email Address' is verified
    Sends a 'Verification Email' when the 'Verify Email' button is clicked
    Renders the 'Preferences' panel
    Renders the 'Start Page' field inside the 'Preferences' panel
    Renders the 'Change Password' panel
    Renders the 'Current Password' field inside the 'Change Password' panel
    Renders the 'New Password' field inside the 'Change Password' panel
    Renders the 'Password Confirmation' field inside the 'Change Password' panel
    Renders the 'Update Password' button inside the 'Change Password' panel
    Updates the 'Current Password' with the 'New Password' when the the 'New Password' and the 'Password Confirmation' match
    Renders the 'Actions' panel
    Renders the 'Back to Home' button inside the 'Actions' panel
    Renders the 'Edit Details' button inside the 'Actions' panel
    Renders the 'Delete Account' button inside the 'Actions' panel
    Navigates to the 'Home' page when the button 'Back to Home' is clicked
    Navigates to the 'Edit Settings' page when the button 'Edit Details' is clicked
    Suspends the 'User Account' and redirects to 'Home' when 'Delete Account' is confirmed
  Negative path
    Redirects 'Gary Guest' to the 'Sign-In' page
    Shows an error when the 'Current Password' is wrong
    Shows an error when 'New Password' and 'Password Confirmation' does not match
  Alternative path
    Renders the 'User Settings' page for 'Sam SysAdmin'
  Edge cases
    Returns to the 'User Settings' page if the user cancels the deletion confirmation (PENDING: Temporarily skipped with xit)

AppPermission
  database columns
    is expected to have db column named user_id of type integer of null false
    is expected to have db column named app_name of type string of null false
    is expected to have db column named can_create of type boolean of default false of null false
    is expected to have db column named can_update of type boolean of default false of null false
    is expected to have db column named can_delete of type boolean of default false of null false
  associations
    belongs to a user
  validations
    1) Happy path
      with valid attributes
        is valid
      with each valid app_name
        is valid with app_name 'event_tracker'
        is valid with app_name 'blog_posts'
        is valid with app_name 'recipes'
        is valid with app_name 'photo_albums'
    2) Negative path
      without app_name
        is invalid
      with an invalid app_name
        is invalid
      with a duplicate app_name for the same user
        is invalid
    3) Alternative path
      same app_name for different users
        is valid
    4) Edge cases
      boolean columns default to false
        can_create defaults to false
        can_update defaults to false
        can_delete defaults to false

Classifiable
  .visible_to_visitors
    returns only unrestricted events
  .visible_to_users
    happy path
      returns unrestricted events to any user
      returns contacts events to a confirmed contact of the owner
      returns contacts events to the owner
    negative path
      does not return contacts events to a stranger
      does not return restricted events to any user
    alternative path
      can be chained with other scopes
  .visible_to_admins
    returns all events

Roleable
  database columns
    is expected to have db column named role of type string of default app_user of null false
  enum
    defines app_user, content_creator, admin, and system_admin roles
    stores string values in the database
    does not define visitor as a stored role
  validations
    happy path
      role
        is valid with role app_user
        is valid with role content_creator
        is valid with role admin
        is valid with role system_admin
        defaults to app_user
    negative path
      role
        is not valid with an unrecognised role
        is not valid with a blank role
    alternative path
      role
        retains the role when other attributes are updated
    edge cases
      role
        does not raise when reassigning the same role value
  #can_administer?
    happy path
      returns true for admin
      returns true for system_admin
    negative path
      returns false for content_creator
      returns false for app_user
  #can_create_content?
    happy path
      returns true for content_creator
      returns true for admin
      returns true for system_admin
    negative path
      returns false for app_user

Contact
  database columns
    is expected to have db column named user_id of type integer of null false
    is expected to have db column named contact_id of type integer of null false
    is expected to have db column named status of type string of default pending of null false
  associations
    belongs to user
    belongs to contact as a User
  validations
    happy path
      is valid with status pending
      is valid with status confirmed
    negative path
      is not valid without a user
      is invalid without a contact
      is invalid with a duplicate user/contact pair
      is invalid with an unrecognised status
    alternative path
      is valid when bob adds alice even if alice has already added bob
    edge cases
      is invalid if a user tries to add themselves
  scopes
    .confirmed
      returns only confirmed contacts
  .confirmed_between?
    returns true when alice has confirmed bob
    returns true when bob has confirmed alice
    returns false when the relationship is only pending
    returns false when there is no relationship at all
  .confirmed_contact_ids_for
    returns the ids of confirmed contacts of the user
    includes contacts confirmed in either direction
    does not include pending contacts

EventPerson
  database columns
    is expected to have db column named event_id of type integer of null false
    is expected to have db column named person_id of type integer of null false
  associations
    is expected to belong to event required: true
    is expected to belong to person required: true

Event
  database columns
    is expected to have db column named title of type string of null false
    is expected to have db column named description of type text
    is expected to have db column named day of type integer of null false
    is expected to have db column named month of type integer of null false
    is expected to have db column named year of type integer
    is expected to have db column named slug of type string
    is expected to have db column named event_type_id of type integer of null false
    is expected to have db column named user_id of type integer of null false
    is expected to have db column named classification of type string of default contacts of null false
  associations
    is expected to belong to event_type required: true
    is expected to belong to user required: true
    is expected to have many event_people dependent => destroy
    is expected to have many people through event_people
    is expected to have a has_one_attached called image
  validations
    happy path
      title
        is valid when title is unique
      day
        is valid when day is present
      month
        is valid when month is present
      classification
        is valid with classification set to contacts
        is valid with classification set to unrestricted
        is valid with classification set to restricted
        defaults to contacts
      user
        is valid when a user is present
      image type
        is valid with a JPEG image
        is valid with a PNG image
        is valid with a WebP image
      slug
        generates a slug from the title
    negative path
      is expected to validate that :title cannot be empty/falsy
      is expected to validate that :title is case-insensitively unique
      is expected to validate that :day cannot be empty/falsy
      is expected to validate that :day looks like an integer greater than or equal to 1 and less than or equal to 31
      is expected to validate that :month cannot be empty/falsy
      is expected to validate that :month looks like an integer greater than or equal to 1 and less than or equal to 12
      is expected to validate that :year looks like an integer greater than or equal to 1000 as long as it is not nil
      title
        is not valid when title is missing
        is not valid when title already exists
        is not valid when trimmed title already exists
        is not valid when title already exists in a different case
        is not valid when title with collapsed internal spaces already exists
      classification
        is not valid without a classification
        is not valid when classification is set to an unrecognised value
      user
        is not valid without a user
      day
        is not valid when day is not an integer
        is not valid when day is less than 1
        is not valid when day is greater than 31
      month
        is not valid when month is not an integer
        is not valid when month is less than 1
        is not valid when month is greater than 12
      year
        is not valid when year is not an integer
        is not valid when year is less than 1000
      image type
        is not valid with a text file as image
        is not valid with a GIF image
        is not valid with an image exceeding 5MB
    alternative path
      description
        is valid when updating description without changing the title
        is valid without a description
      classification
        retains the classification when other attributes are updated
      year
        is valid without a year
      slug
        slug is regenerated when title changes
    edge cases
      date
        is not valid when day and month do not form a valid date
        is not valid when February 29 is given without a year
        is not valid when February 29 is given for a non-leap year
        is valid when February 29 is given for a leap year
      slug
        old slug is resolvable after a title change
  #display_date
    returns day and month when year is nil
    returns full date when year is present
    returns month name not month number
  #slug
    generates a slug from the title
    regenerates the slug when the title changes
    keeps the old slug resolvable after a title change

EventType
  database columns
    is expected to have db column named name of type string of null false
    is expected to have db column named description of type text of null false
    is expected to have db column named icon of type string of null false
    is expected to have db column named slug of type string
  associations
    is expected to have many events dependent => restrict_with_error
  validations
    happy path
      is valid with all required fields
      is valid when icon is a known Lucide icon name
    negative path
      is invalid when name is blank
      is invalid when name is a duplicate (same case)
      is invalid when name is a duplicate (different case)
      is invalid when description is blank
      is invalid when icon is blank
      is invalid when icon is already taken by another record
      is invalid when icon name is not in the Lucide icon set
    alternative path
      is valid when updating description without changing name
      is valid when updating icon to a different known Lucide icon
    edge cases
      is invalid when icon is a partial match of a real icon name
      is invalid when icon has surrounding whitespace
  FriendlyId
    generates a slug from name on create
    regenerates slug when name changes
    resolves the old slug after a name change
    finds a record by its current slug
  LUCIDE_VALID_ICONS
    is a non-empty Set
    includes known Lucide icon names
    does not include made-up names
  restrict_with_error on delete
    prevents deletion when the event type has associated events
    allows deletion when the event type has no associated events

Person
  database columns
    is expected to have db column named first_name of type string of null false
    is expected to have db column named middle_name of type string
    is expected to have db column named last_name of type string
    is expected to have db column named description of type text
    is expected to have db column named slug of type string
    is expected to have db column named user_id of type integer of null false
    is expected to have db column named classification of type string of default contacts of null false
  associations
    is expected to belong to user required: true
    is expected to have many event_people dependent => destroy
    is expected to have many events through event_people
    is expected to have a has_one_attached called image
  validations
    happy path
      name
        is valid when full name is unique
      classification
        is valid with classification set to contacts
        is valid with classification set to unrestricted
        is valid with classification set to restricted
        defaults to contacts
      user
        is valid when a user is present
      image type
        is valid with a JPEG image
        is valid with a PNG image
        is valid with a WebP image
    negative path
      is expected to validate that :first_name cannot be empty/falsy
      name
        is not valid when first name is missing
        is not valid when full name already exists
        treats nil middle name the same as blank
        treats nil last name the same as blank
      classification
        is not valid without a classification
        is not valid when classification is set to an unrecognised value
      user
        is not valid without a user
      image type
        is not valid with a text file as image
        is not valid with a GIF image
        is not valid with an image exceeding 5MB
    alternative path
      name
        is valid with only a first name
        is valid with first name and middle name only
        is valid with first name and last name only
        is valid with first, middle, and last name
      description
        is valid when updating description without changing the name
      classification
        retains the classification when other attributes are updated
      slug
        slug is regenerated when full name changes
    edge cases
      name
        is not valid when full name collides despite different middle and last name positions
        is not valid when full name already exists in a different case
        is not valid when first name differs only in case
      slug
        old slug is resolvable after a name change
  #full_name
    returns first and last name when no middle name
    returns first, middle, and last name when all present
    returns first, middle, and last name for all band members
    returns only first name when middle and last are blank
    strips extra whitespace when middle name is blank
  #slug
    generates a slug from full_name
    regenerates the slug when the name changes
    keeps the old slug resolvable after a name change

Policy
  #can_read?
    unrestricted content
      returns true for visitors (nil user)
      returns true for any authenticated user
    contacts content
      returns false for visitors
      returns false for a user who is not a confirmed contact
      returns true for the owner
      returns true for a confirmed contact of the owner
      returns true for an admin
    restricted content
      returns false for visitors
      returns false for an app_user who is not the owner
      returns true for the owner
      returns true for an admin
  #can_create?
    with no record (app symbol passed)
      returns false for a nil user
      returns false for an app_user
      returns true for a content_creator
      returns true for an admin
      returns true for a system_admin
    with an AppPermission override
      returns true for an app_user when override grants can_create
      returns false for a content_creator when override revokes can_create
      ignores overrides for system_admin — always true
  #can_update?
    role defaults, no override
      returns false for a nil user
      returns false for an app_user
      returns true for the content_creator who owns the record
      returns false for a content_creator who does not own the record
      returns true for an admin regardless of ownership
      returns true for a system_admin regardless of ownership
      returns false for a content_creator when resource is a symbol (no record)
    with an AppPermission override
      returns true for an app_user when override grants can_update on own record
      returns false for an admin when override revokes can_update
      ignores overrides for system_admin — always true
  #can_delete?
    role defaults, no override
      returns false for a nil user
      returns false for an app_user
      returns true for the content_creator who owns the record
      returns false for a content_creator who does not own the record
      returns true for an admin regardless of ownership
      returns true for a system_admin regardless of ownership
    with an AppPermission override
      returns true for a content_creator when override grants can_delete on another's record
      returns false for an admin when override revokes can_delete
      ignores overrides for system_admin — always true

User
  database columns
    is expected to have db column named email_address of type string of null false
    is expected to have db column named password_digest of type string of null false
    is expected to have db column named role of type string of default app_user of null false
    is expected to have db column named created_at of type datetime of null false
    is expected to have db column named updated_at of type datetime of null false
  associations
    is expected to have many sessions dependent => destroy
    is expected to have many contacts dependent => destroy
    is expected to have many contact_users through contacts source => contact
  Roleable concern
    includes the Roleable concern
    defaults to app_user

ExportService
  #generate_csv
    Happy path
      Returns a string
      Includes the header row
      Includes one row per person+event combination
      Generates multiple rows for a person with multiple events
      Includes a person with no events as a row with blank event columns
      Orders rows by last name then first name
    Negative path
      Returns only a header row when no matching data exists
      Does not include another user's private data

Pending: (Failures listed here are expected and do not affect your suite's status)

  1) Reset Password Edge cases Shows an alert when the new password is blank
     # Temporarily skipped with xit
     # ./spec/features/auth/reset_password_spec.rb:67

  2) Create Event with an image creates an event with an image and displays it on the show page
     # Temporarily skipped with xit
     # ./spec/features/events/create_event_spec.rb:131

  3) Edit Event edge cases attaches the image and shows it on the show page
     # Temporarily skipped with xit
     # ./spec/features/events/edit_event_spec.rb:126

  4) Create Person happy path creates a person with an image and displays it on the show page
     # Temporarily skipped with xit
     # ./spec/features/people/create_person_spec.rb:25

  5) Edit Person alternative path attaches the image and shows it on the show page
     # Temporarily skipped with xit
     # ./spec/features/people/edit_person_spec.rb:81

  6) Edit User Settings Happy path Updates 'Start Page' with a new value
     # Temporarily skipped with xit
     # ./spec/features/settings/edit_settings_spec.rb:119

  7) User Settings Edge cases Returns to the 'User Settings' page if the user cancels the deletion confirmation
     # Temporarily skipped with xit
     # ./spec/features/settings/show_settings_spec.rb:227

Finished in 47.9 seconds (files took 2.12 seconds to load)
774 examples, 0 failures, 7 pending

Coverage report generated for RSpec to /home/nik/src/rails/bergstrom_domain/coverage.
Line Coverage: 94.11% (543 / 577)
