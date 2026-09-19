"""
crop_rules.py
-------------
This file contains the core logic for recommending crops.
It is kept completely separate from the web server (app.py) so that:
1. It can be tested and understood easily.
2. In the future, a Machine Learning (ML) model can easily replace or enhance this file
   without changing any of the web or mobile app code!
"""

# Agricultural Knowledge Base:
# A list of common crops and their ideal growing requirements.
CROP_DATABASE = [
    {
        "name": "Rice (Paddy)",
        "suitable_soils": ["clay", "clay loam", "alluvial", "loam"],
        "min_temp": 20,
        "max_temp": 38,
        "min_rainfall": 900,
        "max_rainfall": 3000,
        "min_humidity": 65,
        "max_humidity": 100,
        "min_ph": 5.0,
        "max_ph": 7.5,
        "seasons": ["kharif", "monsoon", "summer", "all"],
        "description": "Thrives in warm, humid weather with plenty of water and water-retaining clay soil.",
        "tips": "Requires good standing water during the vegetative stage and well-prepared clay soil."
    },
    {
        "name": "Wheat",
        "suitable_soils": ["loam", "clay loam", "alluvial", "black"],
        "min_temp": 10,
        "max_temp": 26,
        "min_rainfall": 350,
        "max_rainfall": 850,
        "min_humidity": 35,
        "max_humidity": 70,
        "min_ph": 6.0,
        "max_ph": 7.5,
        "seasons": ["rabi", "winter"],
        "description": "Best suited for cool winters with moderate rainfall and well-drained loam or alluvial soil.",
        "tips": "Ensure proper irrigation at the crown root initiation (CRI) stage for maximum yield."
    },
    {
        "name": "Cotton",
        "suitable_soils": ["black", "alluvial", "loam", "clay loam"],
        "min_temp": 20,
        "max_temp": 36,
        "min_rainfall": 500,
        "max_rainfall": 1100,
        "min_humidity": 45,
        "max_humidity": 80,
        "min_ph": 6.0,
        "max_ph": 8.0,
        "seasons": ["kharif", "summer", "all"],
        "description": "Ideal for deep black cotton soils with sunny, warm weather and moderate rainfall.",
        "tips": "Avoid waterlogging. Requires warm days and cool nights during boll development."
    },
    {
        "name": "Maize (Corn)",
        "suitable_soils": ["loam", "alluvial", "red", "sandy loam"],
        "min_temp": 18,
        "max_temp": 34,
        "min_rainfall": 500,
        "max_rainfall": 1200,
        "min_humidity": 45,
        "max_humidity": 85,
        "min_ph": 5.5,
        "max_ph": 7.5,
        "seasons": ["kharif", "rabi", "summer", "all"],
        "description": "Highly adaptable crop that grows well in well-drained fertile loamy soils.",
        "tips": "Sensitive to waterlogging; ensure good drainage and weed control in early stages."
    },
    {
        "name": "Millets (Bajra / Jowar / Ragi)",
        "suitable_soils": ["sandy", "sandy loam", "red", "loam"],
        "min_temp": 24,
        "max_temp": 40,
        "min_rainfall": 250,
        "max_rainfall": 700,
        "min_humidity": 30,
        "max_humidity": 65,
        "min_ph": 5.5,
        "max_ph": 8.0,
        "seasons": ["kharif", "summer", "zaid", "all"],
        "description": "Drought-hardy, climate-resilient crop that grows well even with low water and sandy soil.",
        "tips": "Needs minimal chemical inputs and can tolerate dry spells very well."
    },
    {
        "name": "Chickpea (Gram / Pulses)",
        "suitable_soils": ["loam", "black", "sandy loam", "alluvial"],
        "min_temp": 12,
        "max_temp": 27,
        "min_rainfall": 350,
        "max_rainfall": 750,
        "min_humidity": 35,
        "max_humidity": 65,
        "min_ph": 6.0,
        "max_ph": 7.8,
        "seasons": ["rabi", "winter"],
        "description": "Prefers cool, dry climates during growth and warm conditions during maturity.",
        "tips": "Leguminous crop that naturally fixes nitrogen in the soil, improving soil fertility."
    },
    {
        "name": "Groundnut (Peanut)",
        "suitable_soils": ["sandy loam", "sandy", "red", "loam"],
        "min_temp": 22,
        "max_temp": 34,
        "min_rainfall": 450,
        "max_rainfall": 850,
        "min_humidity": 45,
        "max_humidity": 75,
        "min_ph": 5.8,
        "max_ph": 7.2,
        "seasons": ["kharif", "summer", "zaid", "all"],
        "description": "Thrives in loose, light sandy-loam soils that allow pegs to penetrate easily.",
        "tips": "Do not grow in heavy clay soil as it makes harvesting pods difficult."
    },
    {
        "name": "Sugarcane",
        "suitable_soils": ["loam", "clay loam", "alluvial", "black"],
        "min_temp": 20,
        "max_temp": 38,
        "min_rainfall": 1000,
        "max_rainfall": 2500,
        "min_humidity": 60,
        "max_humidity": 90,
        "min_ph": 6.0,
        "max_ph": 8.2,
        "seasons": ["kharif", "annual", "all"],
        "description": "Long-duration tropical crop requiring high sunlight, warm temperatures, and ample water.",
        "tips": "Requires deep fertile soil with steady irrigation and good drainage."
    }
]


def score_crop(crop: dict, user_data: dict) -> tuple[int, list[str]]:
    """
    Calculates a match score (0 - 100) for a crop based on user's agricultural inputs.
    Returns:
        score (int): Score out of 100
        reasons (list of str): List of factors that matched well
    """
    score = 0
    reasons = []

    # 1. Soil Type Match (Weight: 25 points)
    user_soil = str(user_data.get("soil_type", "")).strip().lower()
    if any(soil in user_soil or user_soil in soil for soil in crop["suitable_soils"]):
        score += 25
        reasons.append(f"Soil type matches well ({user_data.get('soil_type')})")
    elif "loam" in user_soil:
        # Loam is generally versatile for many crops
        score += 15
        reasons.append(f"Soil ({user_data.get('soil_type')}) is fairly adaptable")

    # 2. Temperature Match (Weight: 20 points)
    temp = float(user_data.get("temperature", 0))
    if crop["min_temp"] <= temp <= crop["max_temp"]:
        score += 20
        reasons.append(f"Temperature ({temp}°C) is in ideal range ({crop['min_temp']} - {crop['max_temp']}°C)")
    elif abs(temp - crop["min_temp"]) <= 3 or abs(temp - crop["max_temp"]) <= 3:
        score += 10
        reasons.append(f"Temperature ({temp}°C) is acceptable with slight care")

    # 3. Rainfall Match (Weight: 20 points)
    rainfall = float(user_data.get("rainfall", 0))
    if crop["min_rainfall"] <= rainfall <= crop["max_rainfall"]:
        score += 20
        reasons.append(f"Rainfall ({rainfall} mm) matches requirement ({crop['min_rainfall']} - {crop['max_rainfall']} mm)")
    elif abs(rainfall - crop["min_rainfall"]) <= 200 or abs(rainfall - crop["max_rainfall"]) <= 200:
        score += 10
        reasons.append(f"Rainfall ({rainfall} mm) can work with irrigation/drainage")

    # 4. Soil pH Match (Weight: 15 points)
    ph = float(user_data.get("ph", 6.5))
    if crop["min_ph"] <= ph <= crop["max_ph"]:
        score += 15
        reasons.append(f"Soil pH ({ph}) is optimal ({crop['min_ph']} - {crop['max_ph']})")
    elif abs(ph - crop["min_ph"]) <= 0.5 or abs(ph - crop["max_ph"]) <= 0.5:
        score += 8
        reasons.append(f"Soil pH ({ph}) is acceptable")

    # 5. Humidity Match (Weight: 10 points)
    humidity = float(user_data.get("humidity", 50))
    if crop["min_humidity"] <= humidity <= crop["max_humidity"]:
        score += 10
        reasons.append(f"Humidity ({humidity}%) is suitable")
    elif abs(humidity - crop["min_humidity"]) <= 15 or abs(humidity - crop["max_humidity"]) <= 15:
        score += 5

    # 6. Season Match (Weight: 10 points)
    user_season = str(user_data.get("season", "")).strip().lower()
    if not user_season or "all" in crop["seasons"] or any(s in user_season for s in crop["seasons"]):
        score += 10
        if user_season:
            reasons.append(f"Season ({user_data.get('season')}) matches crop cycle")

    return score, reasons


def get_recommendations(user_data: dict) -> dict:
    """
    Main function called by the API.
    Takes user input dictionary and returns recommendations list and summary.
    """
    scored_crops = []

    for crop in CROP_DATABASE:
        score, reasons = score_crop(crop, user_data)
        if score >= 45:  # Only recommend crops with a reasonable match score
            scored_crops.append({
                "crop": crop["name"],
                "score": score,
                "suitability": "Highly Recommended" if score >= 75 else "Moderately Recommended",
                "description": crop["description"],
                "tips": crop["tips"],
                "reasons": reasons
            })

    # Sort descending by score so best matches appear first
    scored_crops.sort(key=lambda x: x["score"], reverse=True)

    # If no crops met the threshold, provide helpful advice
    if not scored_crops:
        return {
            "status": "warning",
            "message": "No standard crops strongly matched your exact inputs. Please review the environmental values.",
            "recommendations": []
        }

    return {
        "status": "success",
        "message": f"Found {len(scored_crops)} suitable crop(s) based on your inputs.",
        "recommendations": scored_crops[:4]  # Return top 4 best matches
    }
