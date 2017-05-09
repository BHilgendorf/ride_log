require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
# require "pry"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, escape_html: true
end

# Distance Validation --------------------
def invalid_distance_characters?(distance)
  distance.match(/[^0-9\.]/)
end

def set_distance(distance)
  if distance == "" || distance.nil?
    "0"
  else
    distance
  end
end

# Duration Validation ------------------
def invalid_duration_format?(duration)
  !duration.match(/\d+:[0-5][0-9]/)
end

def set_duration(duration)
  if duration == "" || duration.nil?
    "00:00"
  else
    duration
  end
end

# Form Entry Validation ----------------------
def empty_distance_and_duration?(distance, duration)
  duration == "00:00" && distance == "0"
end

def invalid_form_entry?(distance, duration)
  if empty_distance_and_duration?(distance, duration)
    "You must enter a distance or a duration."
  elsif invalid_distance_characters?(distance)
    "Distance must be numeric. A decimal point is allowed."
  elsif invalid_duration_format?(duration)
    "Please enter ride time in HH:MM format."
  end
end

# -------------------------------------
def next_ride_id(rides)
  current = rides.keys.map(&:to_i).max || 0
  (current + 1).to_s
end

# Helpers ------------------------------

before do
  session[:rides] ||= {}
end

# --------------------------------------
get "/home" do
  @rides = session[:rides]
  erb :home
end

get "/rides/add" do
  erb :add_ride
end

post "/rides/add" do
  date = params[:date]
  distance = set_distance(params[:distance])
  duration = set_duration(params[:duration])

  error_message = invalid_form_entry?(distance, duration)
  if error_message
    status 422
    session[:error] = error_message
    erb :add_ride
  else
    ride_id = next_ride_id(session[:rides])
    session[:rides][ride_id] = {
      date: date, distance: distance, duration: duration
    }
    session[:success] = "Ride has been added successfully."
    redirect "/home"
  end
end

# Delete Ride ------------------------------------

post "/rides/delete/:id" do
  id = params[:id]
  if session[:rides][id]
    session[:rides].delete(id)
    session[:success] = "Ride has been deleted."
  else
    session[:error] = "Ride with id of #{id} does not exist."
  end
  redirect "/home"
end


