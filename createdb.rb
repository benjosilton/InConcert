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
  String :fb_page
  String :email
  String :password
end

# Insert initial (seed) data
showups_table = DB.from(:showups)

showups_table.insert(artists: "The Arcadian Wild",
    date: "April 9",
    venue: "Tonic Room",
    photo: "https://photos.bandsintown.com/thumb/9697294.jpeg",
    pregame_loc: "Sushi Para II, Lincoln Park",
    pregame_time: "6:30 PM",
    pregame_desc: "BYOB all-you-can-eat sushi before some live folk? Yes please! RSVP by April 7th so we can update the reservation with the restaurant."
)

showups_table.insert(artists: "Trevor Hall & Brett Dennen",
    date: "April 23",
    venue: "Vic Theatre",
    photo: "https://img-dev.evbuc.com/https%3A%2F%2Fcdn.evbuc.com%2Fimages%2F84167535%2F313967227138%2F1%2Foriginal.20191210-205030?auto=compress&fit=clip&h=&w=650&s=9c23c6fc9d7f72f1af57731f15ec8b3f",
    pregame_loc: "Big Star Wrigleyville",
    pregame_time: "7 PM",
    pregame_desc: "Let's grab some tacos and margs before the guys take the stage. Meet at the upstairs bar."
)

puts "Success!"