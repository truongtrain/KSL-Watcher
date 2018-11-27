CS4540 - Homework 7 - AJAX

In this assignment, you'll work with AJAX to make your web app feel more responsive.  Learning goals:

* Write javascript functions that call methods in your Rails backend.
* Reinforce the way Rails will route requests based on a request type and path to a particular controller and method.
* Understand how adding '.js' to a path on the Rails server will trigger a javascript response instead of html.
* Build Rails methods that receive AJAX calls and return javascript code that updates a portion of the page.
* Understand how callbacks work within javascript.
* Use the session object in Rails to 'remember' component settings.


Task 1:  Refactor the code to support multiple statuses for listings.

In the prior assignment, we used a field called reviewed_at to determine whether or not a listing had been reviewed by the user.  This let us determine when a listing was "new" and display a message on the home screen showing how many new listings were available to the user.  

In this assignment, we're going to do something you'll often do in developing an app like this...change your mind.  Our prior design doesn't support the notion of a user "watching" a listing because it's of interest to them.  This leads to three kinds of listings:  those that are new (unreviewed or not-yet-seen), watched (user wants to keep an eye on them), or ignored (been reviewed and are not considered interesting).  A listing can be in any one of these states but not in more than one.  How do we model that in our database?  We could create another model/table called Statuses and then set a belongs_to/has_many 1:M relationship between Listing and Status, but that's probably overkill for this.  Instead, let's use an enumerated type field.

You've seen enumerated types in programming languages, but we need to have this work with a database backend.  Rail's ORM, ActiveRecord, makes this easy. First, we need to create an integer column in the database table.  Then, we declare the enumerated type in Rails model -- it looks like an array.  ActiveRecord handles mapping each item in the array to an index and storing that index in the database field.  (see https://api.rubyonrails.org and do a search for 'enum')  The format for this declaration is 

    enum <attribute_name>: [list of possible values as strings or symbols]

Subtask 1.1:  Create a new migration to a field called 'status' of type integer to the listings table, and run the migrations.  The code to add a new column (within the migration's change method) should look like this:

    add_column :listings, :status, :integer, default: 0

Note:  If we weren't using sqlite, I'd have you modify the reviewed_at column to be our status column, but sqlite doesn't support column modification.  To make things easy, we'll just add a new column, leaving the reviewed_at column in the table.  This is not good practice but it's not worth jumping through the sqlite hoops at this point.

Subtask 1.2:  Add the declaration of the enumerated values for the new status attribute to the Listing model.  Use :not_yet_seen, :ignore, and :watch as the possible values.  

    enum status: [:not_yet_seen, :ignore, :watch]

You can place this anywhere in the model but a good practice is to put it after the association declarations (e.g. has_many) and any named scopes but before regular method definitions.

Note that I've added some additional functionality to the Listing model.  You'll see a by_ids scope that takes an array of IDs and returns just those that match.  You'll also see a class method mass_set_status that will apply a status change to a collection of listings.  We'll be using that method in a just a bit.


Task 2:  Add status AJAX filtering to the listings index page.

First, take a look at the the contents of the /app/views/listings folder.  Notice that there a bunch of partial view templates (those whose filename begins with an underscore) and several .js.erb files.  The partials are used to help structure the page so Rails can supply javascript that will update portions of the page.  Look through index.html.erb and make sure you understand how it uses partials to render the entire page.  It's quite likely I'll ask you to explain something like it on the final exam.  

There's one wrinkle in there.  The rendering of the mass_edit_buttons and filter_buttons is done by calling a helper function.  Within views, helper functions are used to abstract a chunk of logic away from the view itself, and they can be found in the /app/controllers/helpers folder.  Within that folder, you'll find one helper module for every view/resource.  Any methods defined in the view's helper module are available to all of that view's templates.  In this case, you want to open /app/controllers/helpers/listings_helper.rb to see the methods I've defined to make the view templates themselves more readable and less verbose.  

Now look at the _filter_buttons.html.erb file.  You'll see that it first calls show_selection_options which is one of the methods defined in listings_helper.rb.  It generates the html to display a button for each of the possible listing statuses plus a button for "All".  Then, it defines some javascript.  Within that javascript, it binds a function to the click event on each button.  Then, it defines the function to make a POST to an endpoint on the Rails server, '/listings/set_filter.js'.  As part of that $.post call, the javascript supplies some data with:  
    { show_filter: $(event.target).attr('data-filter') }
That will set show_filter to the attribute value of 'data-filter' that is part of each button's definition.  If you look at line 54 of the listings_helper.rb file, you'll see that each button gets its data-filter attribute set to the name of the filter (which comes from Listing.statuses).


Open the config/routes.rb file and notice this line:  
    post '/listings/set_filter', to: 'listings#set_filter'
This defines that a POST request made to /listings/set_filter will be directed to the set_filter method of the listings controller.  Now let's look at that method.  

Open /app/controllers/listings_controller.rb and find the set_filter method.  It first verifies the passed in parameter is legitimate, and if so, it saves the requested filter to the session object so it 'sticks', i.e. it will stay across page reloads until the user changes it.  Second, it calls a method that will collect the correct listings and stuff them in @listings.  Finally, it checks the requested format and signals Rails to render the set_filter.js.erb file.

The contents of the set_filter.js.erb file are javascript, not Ruby.  That said, you can embed Ruby within your javascript using the same ERB notation you use in html.erb files, <%=, <%, and %>.  See the notes in this file for additional details on what you need to do here.

Subtask 2.1:  Your task is to modify this file to replace the body of the listings table with the records stored in @listings.  Note that the body of the listings table is rendered by the partial, _listing_table_body.html.erb, and it expects the listings objects to be in a variable named 'listings'.  

Subtask 2.2:  You also need to add code here to replace the filter buttons with a new rendering of such buttons (because the rendering will set a CSS class on the selected button to highlight it).


Task 3:  Add mass-editing to the listings index page.

Subtask 3.1:  To improve the user experience, we want to support a user being able to check a selection of listings and then move them all to a particular status at once. I've provided code to add the checkboxes to the table, add the mass edit buttons, and your task is to write code to have to trigger the mass edit when one of those buttons is clicked.

See the app/views/listings/index.html.erb file for additional details.

Subtask 3.2:  When a mass edit button is clicked, it will need to direct its POST request to an endpoint (path) on the Rails server.  The controller that needs to handle this request is the listings controller and the method required is mass_edit.  You need to add a route to the config/routes.rb file to defines this mapping so the ajax request will be properly routed.



Extra:

* Disable the mass edit buttons if no listings have been checked.  Enable as soon as one of the listings is checked.
* It doesn't make sense to have a mass edit button available for the currently selected (filtered by) status (unless it's All).  Disable the mass edit button that matches the newly selected filter when that filter button is clicked.  Reenable when a different filter is selected.  When the All filter is selected, all mass edit buttons should be enabled.
* Add a progress bar on the home index page that updates every second after the 'Run Searches on KSL' button is pressed.  Calculate progress by how many searches have been executed over the total number of searches.  Progress bar should go away after the job is complete.

