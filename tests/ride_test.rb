ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../ride"

class RideTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def session
    last_request.env["rack.session"]
  end


# Test Home page --------------------------------
  def test_home_page
    get "/home"

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<h2>Ride History</h2>")
  end

# Test distance entry-----------------------
  def test_invalid_character_for_distnace
    post "/rides/add", {distance: "invalid"}

    assert_equal(422, last_response.status)
    error_message = "Distance must be numeric. A decimal point is allowed."
    assert_includes(last_response.body, error_message)
  end

  def test_valid_distance_entry_no_decimal
    post "/rides/add", {date: "2017-06-09", distance: "12"}

    assert_equal(302, last_response.status)
    success_message = "Ride has been added successfully."
    assert_equal(success_message, session[:success])

    get "/home"
    assert_includes(last_response.body, "<h2>Ride History</h2>")

  end

  def test_valid_distance_entry_decimal
    post "/rides/add", {date: "2000-01-01", distance: "100.5"}
    assert_equal(302, last_response.status)
    success_message = "Ride has been added successfully."
    assert_equal(success_message, session[:success])

    get "/home"
    assert_includes(last_response.body, "<h2>Ride History</h2>")
  end


  # Test Duration entry --------------------------------
  def test_invalid_characters_for_duration
    post "/rides/add", {date: "2010-05-05", duration: "wrong"}

    assert_equal(422, last_response.status)
    error_message = "Please enter ride time in HH:MM format."
    assert_includes(last_response.body, error_message)

    get "/home"
    assert_includes(last_response.body, "<h2>Ride History</h2>")
  end

  def test_invalid_duration_format_2
    post "/rides/add", {date: "2001-05-05", duration: "3:87"}
    
    assert_equal(422, last_response.status)
    error_message = "Please enter ride time in HH:MM format."
    assert_includes(last_response.body, error_message)

    get "/home"
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<h2>Ride History</h2>")
  end

  def test_valid_duration_format
    post "/rides/add", {date: "2001-05-05", duration: "2:15"}

    assert_equal(302, last_response.status)
    success_message = "Ride has been added successfully."
    assert_equal(success_message, session[:success])

    get "/home"
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<h2>Ride History</h2>")
  end

  def test_valid_duration_format_2
    post "/rides/add", {date: "2007-07-14", duration: "12:30", distance: "100"}

    assert_equal(302, last_response.status)
    success_message = "Ride has been added successfully."
    assert_equal(success_message, session[:success])

    get "/home"
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<h2>Ride History</h2>")
  end


  # Test empty distance and duration -------------------------------
  def test_empty_distance_and_duration
    post "/rides/add", {date: "2010-05-05", distance: "0", duration: "00:00"}

    assert_equal(422, last_response.status)
    error_message = "You must enter a distance or a duration."
    assert_includes(last_response.body, error_message)

    get "/home"
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<h2>Ride History</h2>")
  end
end