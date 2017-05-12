require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
# require "pry"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, escape_html: true
end

helpers do
  def total_miles(rides)
    miles = rides.map { |_, data| data[:distance].to_f }.reduce(:+).to_s
    # "#{'%.2f' % miles}"
  end

  def total_duration(rides)
    time = rides.map { |_, data| data[:duration].to_f }.reduce(:+).to_s
    # "#{'%.2f' % time}"
  end
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

def valid_ride_id?(rides)
  rides.keys.include?(params[:id])
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
  category = params[:category]

  error_message = invalid_form_entry?(distance, duration)
  if error_message
    status 422
    session[:error] = error_message
    erb :add_ride
  else
    ride_id = next_ride_id(session[:rides])
    session[:rides][ride_id] = {
      date: date, distance: distance, duration: duration, category: category
    }
    session[:success] = "Ride has been added successfully."
    redirect "/home"
  end
end

# Edit Ride ------------------------------------
get "/rides/edit/:id" do
  @ride_id = params[:id]
  if valid_ride_id?(session[:rides])
    
    @date = session[:rides][@ride_id][:date]
    @distance = session[:rides][@ride_id][:distance]
    @duration = session[:rides][@ride_id][:duration]
    erb :edit_ride
  else
    session[:error] = "Ride with id of #{@ride_id} does not exist."
    redirect "/home"
  end
end

post "/rides/edit/:id" do
  ride_id = params[:id]
  distance = set_distance(params[:distance])
  duration = set_duration(params[:duration])
  category = params[:category]

  error_message = invalid_form_entry?(distance, duration)
  if error_message
    status 422
    session[:error] = error_message
    redirect "/rides/edit/#{ride_id}"
  else
    session[:rides][ride_id][:date] = params[:date]
    session[:rides][ride_id][:distance] = distance
    session[:rides][ride_id][:duration] = duration
    session[:rides][ride_id][:category] = params[:category]

    session[:success] = "Ride has been updated."
    redirect "/home"
  end
end

# Delete Ride ------------------------------------

post "/rides/delete/:id" do
  ride_id = params[:id]
  if session[:rides][ride_id]
    session[:rides].delete(ride_id)
    session[:success] = "Ride has been deleted."
  else
    session[:error] = "Ride with id of #{ride_id} does not exist."
  end
  redirect "/home"
end


