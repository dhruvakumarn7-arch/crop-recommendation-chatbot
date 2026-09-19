# Crop Recommendation Chatbot (Learning MVP)

A beginner-friendly mobile chatbot project that collects agricultural parameters and recommends suitable crops using a **Flutter** frontend and a **Python Flask** backend.

---

## Architecture Overview

```
[ Flutter Mobile App ]
      │
      ▼  (HTTP POST /api/recommend with JSON data)
[ Flask Web Server (app.py) ]
      │
      ▼  (Input validation: pH, Temperature, Rainfall)
[ Crop Rule Engine (crop_rules.py) ]
      │
      ▼  (Scores crops & selects best matches)
[ JSON Response returned to Flutter ]
```

---

## Project Structure

```
demoantigravity/
├── backend/
│   ├── venv/                 # Python isolated environment
│   ├── app.py                # Flask REST API server
│   ├── crop_rules.py         # Rule-based crop matching logic (modular for ML later)
│   ├── requirements.txt      # Python dependencies (flask, flask-cors)
│   └── test_api.py           # Automated test script for backend
│
├── frontend/
│   ├── pubspec.yaml          # Flutter package configuration
│   ├── lib/
│   │   ├── main.dart         # Flutter app entry point & theme
│   │   ├── models/
│   │   │   ├── chat_message.dart   # Chat bubble & recommendation data model
│   │   │   └── crop_data.dart      # Agricultural input state
│   │   ├── services/
│   │   │   └── api_service.dart    # HTTP client sending data to Flask
│   │   └── screens/
│   │       └── chat_screen.dart    # Interactive chatbot UI & questions
│   └── web/
│       └── index.html        # Web entry point (allows running in Chrome)
│
└── README.md
```

---

## How to Run the Project

### 1. Run the Backend (Python + Flask)
Open your terminal in the `backend/` folder:

```powershell
cd backend
.\venv\Scripts\python.exe app.py
```
The server will start at: `http://127.0.0.1:5000`

To test the backend independently without Flutter:
```powershell
.\venv\Scripts\python.exe test_api.py
```

---

### 2. Run the Frontend (Flutter)
Once Flutter SDK is installed on your computer:

```powershell
cd frontend
flutter pub get
flutter run -d chrome
```
(Or replace `chrome` with your Android emulator / device!)
