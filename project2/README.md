# Project 2, Fall 2010

This project was built using the Ruby on Rails framework, version 2.3.5, and
the Ruby programming language, version 1.8.7.

Ruby on Rails uses the Model View Controller design pattern.  Models are the
means through which data from your data source (typically a database) is
managed, views are the user interface (usually web pages), and controllers
contain logic for parsing user input and other things.  Rails generates a lot
of code for you when you create a new Rails application.  My code can be found
in app/, test/unit/, public/javascripts/application.js,
and public/stylesheets/common.css.  The main code of the entire Rails app lives
in app/.

Ruby on Rails usually provides methods that generate SQL statements for you.
I did not use these features but instead wrote and generated my own SQL.  This
kind of code can be found in app/models/.  I used a MySQL database for my DBMS.

I made use of HTML 5 and CSS 3 to design the user interface of this project.
I tested it in Chrome 6.0.472.63 and Firefox 3.6.10 in OS X.  Javascript is used
in the web form to make it easier to load sample data into the form fields.

Ruby on Rails has a built-in test framework.  I wrote some unit tests to test
the functionality in my models.  To run the test methods, you will need to
configure the test environment's database in config/database.yml; see
config/database.yml.example for a sample configuration.  The database referenced
in the config/database.yml file must exist and must be accessible to the user
defined in the config file.  Rails 2.3.5 and Ruby 1.8.7 should be installed.
You can then run the unit tests I've written by executing the command "rake
test" while in my project's root directory (where app/, config/, etc. are).
