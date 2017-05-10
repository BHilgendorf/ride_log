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

  def sample_ride
    {"rack.session" => {rides: {"555" => {date: "2000-01-01", distance: "20", duration: "01:00"}}}}
  end


# Test Home page --------------------------------
  def test_home_page
    get "/home"

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<h2>Ride History</h2>")
  end

# Test distance entry-----------------------
  def test_invalid_character_for_distance
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
    assert_includes(last_response.body, "100.5")
    assert_includes(last_response.body, "2000-01-01")
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
    assert_includes(last_response.body, "2001-05-05")
    assert_includes(last_response.body, "2:15")
  end

  def test_valid_duration_format_2
    post "/rides/add", {date: "2007-07-14", duration: "12:30", distance: "100"}

    assert_equal(302, last_response.status)
    success_message = "Ride has been added successfully."
    assert_equal(success_message, session[:success])

    get "/home"
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<h2>Ride History</h2>")
    assert_includes(last_response.body, "12:30")
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
    refute_includes(last_response.body, "0")
    refute_includes(last_response.body, "00:00")
  end

  # Test Edit Ride ---------------------------------------------
  def test_get_edit_invalid_ride_id
    get "/rides/edit/7845"

    error_message = "Ride with id of 7845 does not exist."
    assert_equal(error_message, session[:error])
    assert_equal(302, last_response.status)
  end

  def test_get_edit_valid_ride_id
    post "/rides/add", {}, sample_ride

    get "/rides/edit/555"
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "2000-01-01")
    assert_includes(last_response.body, "20")
  end

  def test_post_edit_with_empty_distance_valid_duration
    post "/rides/add/555", {}, sample_ride

    post "/rides/edit/555", {date: "2001-01-01", distance: "", duration: "03:12"}
    assert_equal("0", session[:rides]["555"][:distance])
    assert_equal("03:12", session[:rides]["555"][:duration])
    assert_equal(302, last_response.status)
    assert_equal("Ride has been updated.", session[:success])

    get "/home"
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "0")
    assert_includes(last_response.body, "03:12")
  end

  def test_post_edit_empty_duration_valid_distance
    post "/rides/add/555", {}, sample_ride

    post "/rides/edit/555", {date: "2001-01-01", distance: "8", duration: ""}
    assert_equal("8", session[:rides]["555"][:distance])
    assert_equal("00:00", session[:rides]["555"][:duration])
    assert_equal(302, last_response.status)
    assert_equal("Ride has been updated.", session[:success])

    get "/home"
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "8")
    assert_includes(last_response.body, "00:00")
  end

  def test_post_edit_valid_distance_empty_duration
    post "/rides/add/555", {}, sample_ride

    post "/rides/edit/555",{date: "2001-01-01", distance: "26.20", duration: "02:12"}
    assert_equal("26.20", session[:rides]["555"][:distance])
    assert_equal("02:12", session[:rides]["555"][:duration])
    assert_equal("Ride has been updated.", session[:success])

    get "/home"
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "26.20")
    assert_includes(last_response.body, "02:12")
  end

  def test_post_edit_valid_distance_and_duration
    post "/rides/add/555", {}, sample_ride

    post "/rides/edit/555", {date: "2001-01-01", distance: "44", duration: "02:45"}
    assert_equal("44", session[:rides]["555"][:distance])
    assert_equal("02:45", session[:rides]["555"][:duration])
    assert_equal(302, last_response.status)
    assert_equal("Ride has been updated.", session[:success])

    get "/home"
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "44")
    assert_includes(last_response.body, "02:45")
  end

  # Test Deleting Rides -------------------------------------
  def test_delete_invalid_id
    post "/rides/delete/4251"

    assert_equal(302, last_response.status)
    assert_equal("Ride with id of 4251 does not exist.", session[:error])
  end

  def test_delete_successful
    post "/rides/delete/555", {}, sample_ride

    assert_equal(302, last_response.status)
    success_message = "Ride has been deleted."
    assert_equal(success_message, session[:success])
    refute_equal(sample_ride, session[:rides])
  end
end









