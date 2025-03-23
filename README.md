# Upcycle

<img src="https://raw.githubusercontent.com/J-Nyarangi/Upcycle/main/assets/icons/recycle_icon.png" alt="Upcycle Icon" width="200" height="200"/>

## Transform Waste Into Treasure

Upcycle is a mobile application that empowers users to reduce waste through creative upcycling. By combining AI-powered item recognition, creative project ideas, community sharing, and a marketplace for upcycled goods, Upcycle creates a complete ecosystem for sustainable creativity.

## Features

### 🔍 Scan Waste
Use your device's camera to identify reusable items that might otherwise be discarded. The AI recognition system categorizes the item and suggests potential upcycling ideas.

### 💡 Get Inspired
Receive AI-generated upcycling suggestions tailored to the items you've scanned, helping you turn waste into something valuable.

### 🛠️ Create & Share
Follow step-by-step guides to transform waste into unique creations. Document your process and share your finished projects to inspire the community.

### 🛒 Buy & Sell
List your upcycled creations in the in-app marketplace or browse items crafted by other community members. Support sustainable creativity and discover one-of-a-kind handcrafted items with secure transactions powered by M-Pesa payment integration.

## Download

[Download Upcycle APK](https://github.com/J-Nyarangi/Upcycle/releases/tag/v1.0.0)

> **Note:** If you prefer not to set up the development environment, you can simply download and install the APK file using the link above to try out the app.

## Getting Started

### Prerequisites
* Flutter SDK (2.10.0 or higher)
* Dart (2.16.0 or higher)
* Android Studio / Xcode
* Firebase account (for authentication and database)

### Installation
1. Clone the repository:
```bash
git clone https://github.com/J-Nyarangi/upcycle.git
```

2. Navigate to the project directory:
```bash
cd upcycle
```

3. Install dependencies:
```bash
flutter pub get
```

### API Key Setup
This project uses external APIs (Google Vision, Firebase) that require API keys. These keys are not included in the repository for security reasons. To run the app:

1. Create an `assets/.env` file in the project root with the following structure:
```
GOOGLE_VISION_API_KEY=your_google_vision_api_key
FIREBASE_API_KEY=your_firebase_api_key
```

2. Obtain your own API keys:
   - **Google Vision**: Enable the API in [Google Cloud Console](https://console.cloud.google.com/).
   - **Firebase**: Set up a project in [Firebase Console](https://console.firebase.google.com/).

3. Place Firebase config files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS) in their respective directories.

4. Run `flutter pub get` to ensure dependencies are installed.

5. Run the app:
```bash
flutter run
```

## Technical Implementation

### Image Recognition
Upcycle uses **Google Cloud Vision API** to analyze and identify common household waste items that can be repurposed.

### AI-Powered Suggestions
Our backend leverages GPT-based models to generate creative upcycling ideas based on identified items, user preferences, and trending projects.

### Real-time Updates
Firebase Firestore provides real-time synchronization for the community feed and marketplace listings.

## License
This project is licensed under the MIT License - see the `LICENSE.md` file for details.

## Contact
For support or inquiries, reach out to us at:
* Email: nyandukonyarangi@gmail.com

---

*Made with 💚 for a sustainable future.*
