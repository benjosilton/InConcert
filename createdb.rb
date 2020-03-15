# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
#######################################################################################

# Database schema - this should reflect your domain model

# New domain model - adds users
DB.create_table! :showups do
  primary_key :id
  String :artists
  String :date
  String :venue
  String :photo
  String :pregame_loc
  String :pregame_time
  String :pregame_desc, text: true
end
DB.create_table! :rsvps do
  primary_key :id
  foreign_key :user_id
  foreign_key :showup_id
  Boolean :going
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
showups_table = DB.from(:showups)

showups_table.insert(title: "Bacon Burger Taco Fest", 
                    description: "Here we go again bacon burger taco fans, another Bacon Burger Taco Fest is here!",
                    date: "June 21",
                    location: "Kellogg Global Hub")

showups_table.insert(title: "Kaleapolooza", 
                    description: "If you're into nutrition and vitamins and stuff, this is the event for you.",
                    date: "July 4",
                    location: "Nowhere")

puts "Success!"