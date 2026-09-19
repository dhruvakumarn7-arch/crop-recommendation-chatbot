"""
app.py
------
Main Flask backend application.
This file creates the HTTP server and defines the API endpoints that our Flutter app connects to.
"""

from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
from crop_rules import get_recommendations

# Initialize the Flask application
app = Flask(__name__)

# Enable CORS (Cross-Origin Resource Sharing)
# This allows mobile apps and web browsers from other addresses/ports to communicate with our API
CORS(app)


@app.route("/", methods=["GET"])
def home():
    """
    Serves the live interactive chatbot interface in the browser.
    """
    return render_template("index.html")


@app.route("/api/health", methods=["GET"])
def health_check():
    """
    Health check endpoint to test if the server is alive and reachable.
    Usage: Open http://127.0.0.1:5000/api/health in your browser.
    """
    return jsonify({
        "status": "healthy",
        "message": "Crop Recommendation API is running smoothly!"
    }), 200


def validate_crop_inputs(data: dict) -> tuple[bool, str]:
    """
    Validates the incoming user data.
    Ensures required fields are present and have sensible agricultural numbers.
    Returns:
        (is_valid, error_message)
    """
    if not isinstance(data, dict):
        return False, "Request body must be a valid JSON object."

    # Required fields
    required_fields = ["soil_type", "temperature", "rainfall", "humidity", "ph"]
    for field in required_fields:
        if field not in data or data[field] is None or str(data[field]).strip() == "":
            return False, f"Missing required field: '{field}'."

    # Soil type check
    soil = str(data.get("soil_type", "")).strip()
    if len(soil) < 2:
        return False, "Please enter a valid soil type (e.g., Clay, Sandy, Loamy, Black, Red)."

    # Validate Temperature (-10°C to 60°C)
    try:
        temp = float(data["temperature"])
        if temp < -10 or temp > 60:
            return False, "Temperature should be between -10°C and 60°C."
    except (ValueError, TypeError):
        return False, "Temperature must be a valid number in °C."

    # Validate Rainfall (0 mm to 5000 mm)
    try:
        rainfall = float(data["rainfall"])
        if rainfall < 0 or rainfall > 5000:
            return False, "Rainfall must be between 0 mm and 5000 mm."
    except (ValueError, TypeError):
        return False, "Rainfall must be a valid number in mm."

    # Validate Humidity (0% to 100%)
    try:
        humidity = float(data["humidity"])
        if humidity < 0 or humidity > 100:
            return False, "Humidity must be between 0% and 100%."
    except (ValueError, TypeError):
        return False, "Humidity must be a valid percentage between 0 and 100."

    # Validate Soil pH (0 to 14, standard pH scale)
    try:
        ph = float(data["ph"])
        if ph < 0 or ph > 14:
            return False, "Soil pH must be between 0 and 14 (7 is neutral)."
    except (ValueError, TypeError):
        return False, "Soil pH must be a valid number between 0 and 14."

    return True, ""


@app.route("/api/recommend", methods=["POST"])
def recommend():
    """
    Main recommendation endpoint.
    Receives agricultural data from Flutter app and returns recommended crops.
    """
    # 1. Read JSON data sent in the request body
    data = request.get_json(silent=True)
    if data is None:
        return jsonify({
            "status": "error",
            "message": "Invalid request. Please send a JSON payload."
        }), 400

    # 2. Validate input fields and ranges
    is_valid, error_msg = validate_crop_inputs(data)
    if not is_valid:
        return jsonify({
            "status": "error",
            "message": error_msg
        }), 400

    # 3. Compute recommendations using our rule-based engine
    try:
        result = get_recommendations(data)
        return jsonify(result), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"An unexpected error occurred while calculating recommendations: {str(e)}"
        }), 500


if __name__ == "__main__":
    # Run development server on port 5000, listening on all network interfaces (0.0.0.0)
    # so emulators and mobile devices can connect to it.
    print("Starting Crop Recommendation Server on http://0.0.0.0:5000 ...")
    app.run(host="0.0.0.0", port=5000, debug=True)
