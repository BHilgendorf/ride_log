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
def distance_is_number?(distance)
  distance.match(/[0-9\.]/)
end

def invalid_distance_entry?(distance)
  !distance_is_number?(distance)
end

def distance_empty?(distance)
  distance.nil? || distance == ""
end

def set_distance(distance)
  if distance == ""
    "0"
  elsif distance.nil?
    "0"
  else
    distance
  end
end

# Duration Validation ------------------
def valid_duration?(duration)
  duration.match(/\d{0,2}:\d{2}/)
end

def set_duration(duration)
  if duration == ""
    "00:00"
  elsif duration.nil?
    "00:00"
  else
    duration
  end
end

# -------------------------------------
def next_ride_id(rides)
  current = rides.keys.map(&:to_i).max || 0
  (current + 1).to_s
end

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
 

  if invalid_distance_entry?(distance)
    status 422
    session[:error] = "Distance must be numeric. A decimal point is allowed."
    erb :add_ride
  
  else
    ride_id = next_ride_id(session[:rides])
    session[:rides][ride_id] = {date: date, distance: distance, duration: duration}
    session[:success] = "Ride has been added successfully."
    redirect "/home"
  end

end

