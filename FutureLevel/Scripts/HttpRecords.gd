extends Control  # or any other relevant node type for your UI

# Pre-configured webhook/API endpoint
var api_url: String = "https://www.osccct.org/NeverFearLeaderBoard"  # Replace with your endpoint URL

# Reference to the HTTPRequest node (if placed in the scene)
onready var http_request: HTTPRequest = $HTTPRequest

# Example function to retrieve player's best time (in seconds)
func get_player_best_time() -> float:
	# Replace this with your actual code to retrieve the best time
	return 123.45

# Called when the submit button is pressed
func _on_submit_button_pressed():
	var best_time = get_player_best_time()
	
	# Create a dictionary with the data to send
	var payload = {
		"player_id": "example_player_id",  # Optionally add an ID or other player info
		"best_time": best_time
		
	}
	
	# Convert the dictionary to a JSON string
	var json_payload = JSON.print(payload)
	
	# Set HTTP headers – for JSON use application/json
	var headers = ["Content-Type: application/json"]
	
	# Send the POST request; note the "true" parameter for SSL verification if needed
	var error = http_request.request(api_url, headers, true, HTTPClient.METHOD_POST, json_payload)
	
	if error != OK:
		print("Error sending request: ", error)

# Callback function for when the HTTPRequest completes
func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	if response_code == 200:
		print("Best time submitted successfully!")
	else:
		print("Failed to submit best time. Response code: ", response_code)
