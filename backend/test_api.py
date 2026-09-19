"""
test_api.py
-----------
A simple script to test our Flask API and crop recommendation engine.
This allows us to verify that the backend works completely before building the Flutter app!
"""

import json
from app import app


def run_tests():
    print("=" * 60)
    print("RUNNING CROP RECOMMENDATION BACKEND TESTS")
    print("=" * 60)

    # Use Flask's built-in test client to simulate HTTP requests
    client = app.test_client()

    # 1. Test Health Check Endpoint
    print("\n[Test 1] Checking Health Check Endpoint (GET /api/health)...")
    res = client.get("/api/health")
    print(f"Status Code: {res.status_code}")
    print(f"Response: {res.get_json()}")
    assert res.status_code == 200, "Health check failed!"
    print("[PASS] Health check passed!")

    # 2. Test Recommendation for Rice (Clay soil, High rainfall, Warm)
    print("\n[Test 2] Testing Recommendation for Rice conditions...")
    rice_input = {
        "soil_type": "Clay",
        "temperature": 28,
        "rainfall": 1200,
        "humidity": 80,
        "ph": 6.5,
        "season": "Kharif",
        "location": "Coastal Plain"
    }
    res = client.post("/api/recommend", data=json.dumps(rice_input), content_type="application/json")
    print(f"Status Code: {res.status_code}")
    data = res.get_json()
    print(f"Server Message: {data.get('message')}")
    assert res.status_code == 200, "Recommendation request failed!"
    assert len(data.get("recommendations", [])) > 0, "No crops returned!"
    top_crop = data["recommendations"][0]["crop"]
    top_score = data["recommendations"][0]["score"]
    print(f"Top Recommended Crop: {top_crop} (Score: {top_score}/100)")
    print("Reasons:", data["recommendations"][0]["reasons"])
    assert "Rice" in top_crop, f"Expected Rice to be top match, got {top_crop}"
    print("[PASS] Rice scenario passed!")

    # 3. Test Recommendation for Wheat (Loam, Cool temp, Rabi)
    print("\n[Test 3] Testing Recommendation for Wheat conditions...")
    wheat_input = {
        "soil_type": "Loam",
        "temperature": 18,
        "rainfall": 500,
        "humidity": 55,
        "ph": 6.8,
        "season": "Rabi",
        "location": "North"
    }
    res = client.post("/api/recommend", data=json.dumps(wheat_input), content_type="application/json")
    print(f"Status Code: {res.status_code}")
    data = res.get_json()
    top_crop = data["recommendations"][0]["crop"]
    print(f"Top Recommended Crop: {top_crop} (Score: {data['recommendations'][0]['score']}/100)")
    assert "Wheat" in top_crop or "Chickpea" in top_crop, f"Expected Wheat or Chickpea, got {top_crop}"
    print("[PASS] Wheat scenario passed!")

    # 4. Test Recommendation for Millets (Sandy soil, Low rainfall)
    print("\n[Test 4] Testing Recommendation for Drought/Sandy conditions...")
    millet_input = {
        "soil_type": "Sandy",
        "temperature": 32,
        "rainfall": 350,
        "humidity": 40,
        "ph": 7.0,
        "season": "Kharif"
    }
    res = client.post("/api/recommend", data=json.dumps(millet_input), content_type="application/json")
    data = res.get_json()
    top_crop = data["recommendations"][0]["crop"]
    print(f"Top Recommended Crop: {top_crop} (Score: {data['recommendations'][0]['score']}/100)")
    assert "Millets" in top_crop or "Groundnut" in top_crop, f"Expected Millets or Groundnut, got {top_crop}"
    print("[PASS] Millets scenario passed!")

    # 5. Test Input Validation (Invalid pH: 25)
    print("\n[Test 5] Testing Validation with Invalid pH (pH = 25)...")
    invalid_input = {
        "soil_type": "Clay",
        "temperature": 25,
        "rainfall": 600,
        "humidity": 60,
        "ph": 25  # Invalid pH
    }
    res = client.post("/api/recommend", data=json.dumps(invalid_input), content_type="application/json")
    print(f"Status Code: {res.status_code} (Expected 400)")
    data = res.get_json()
    print(f"Validation Error Message: {data.get('message')}")
    assert res.status_code == 400, "Validation should have failed with status 400"
    print("[PASS] Input validation passed!")

    print("\n" + "=" * 60)
    print("SUCCESS: ALL BACKEND TESTS PASSED SUCCESSFULLY!")
    print("=" * 60)


if __name__ == "__main__":
    run_tests()
