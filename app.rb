# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"
require "sinatra/cookies"                                                             #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "bcrypt"                                                                      #
require "twilio-ruby"                                                                 #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

showups_table = DB.from(:showups)
rsvps_table = DB.from(:rsvps)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

# homepage and list of showups (aka "index")
get "/" do
    puts "params: #{params}"

    @showups = showups_table.all.to_a
    pp @showups

    view "showups"
end

# showup details (aka "show")
get "/showups/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @showup = showups_table.where(id: params[:id]).to_a[0]
    pp @showup

    @rsvps = rsvps_table.where(showup_id: @showup[:id]).to_a
    @going_count = rsvps_table.where(showup_id: @showup[:id], going: true).count

    view "showup"
end

# receive the submitted showup creation form (aka "create showup")
post "/showups/create" do
    puts "params: #{params}"

    # if user isn't logged in, take them to login page
    if @current_user
        showups_table.insert(
            artists: params["artists"],
            date: params["date"],
            venue: params["venue"],
            photo: params["photo"],
            pregame_loc: params["pregame_loc"],
            pregame_time: params["pregame_time"],
            pregame_desc: params["pregame_desc"]
        )
    else
        redirect "/logins/new"
    end
end

# display the rsvp form (aka "new")
get "/showups/:id/rsvps/new" do
    puts "params: #{params}"

    @showup = showups_table.where(id: params[:id]).to_a[0]
    view "new_rsvp"
end

# receive the submitted rsvp form (aka "create")
post "/showups/:id/rsvps/create" do
    puts "params: #{params}"

    # first find the showup that rsvp'ing for
    @showup = showups_table.where(id: params[:id]).to_a[0]
    # next we want to insert a row in the rsvps table with the rsvp form data
    rsvps_table.insert(
        showup_id: @showup[:id],
        user_id: session["user_id"],
        going: params["going"]
    )

    redirect "/showups/#{@showup[:id]}"
end

# display the rsvp form (aka "edit")
get "/rsvps/:id/edit" do
    puts "params: #{params}"

    @rsvp = rsvps_table.where(id: params["id"]).to_a[0]
    @showup = showups_table.where(id: @rsvp[:showup_id]).to_a[0]
    view "edit_rsvp"
end

# receive the submitted rsvp form (aka "update")
post "/rsvps/:id/update" do
    puts "params: #{params}"

    # find the rsvp to update
    @rsvp = rsvps_table.where(id: params["id"]).to_a[0]
    # find the rsvp's showup
    @showup = showups_table.where(id: @rsvp[:showup_id]).to_a[0]

    if @current_user && @current_user[:id] == @rsvp[:id]
        rsvps_table.where(id: params["id"]).update(
            going: params["going"],
        )

        redirect "/showups/#{@showup[:id]}"
    else
        view "error"
    end
end

# delete the rsvp (aka "destroy")
get "/rsvps/:id/destroy" do
    puts "params: #{params}"

    rsvp = rsvps_table.where(id: params["id"]).to_a[0]
    @showup = showups_table.where(id: rsvp[:showup_id]).to_a[0]

    rsvps_table.where(id: params["id"]).delete

    redirect "/showups/#{@showup[:id]}"
end

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip!
    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "error"
    else
        users_table.insert(
            name: params["name"],
            email: params["email"],
            fb_page: params["fb_page"],
            password: BCrypt::Password.create(params["password"])
        )

        redirect "/logins/new"
    end
end

# display the login form (aka "new")
get "/logins/new" do
    @user = users_table.where(email: params["email"]).to_a[0]
        view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            redirect "/"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    redirect "/logins/new"
end
