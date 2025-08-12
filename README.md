# 📡 Agora Broadcast Test

A Flutter project demonstrating live broadcasting using [Agora](https://www.agora.io/) SDK with secure environment variable handling via [Envied](https://pub.dev/packages/envied).

---

## 📂 Repository

[GitHub Repository](https://github.com/HijbullahMahmud/Agora-Broadcast-Flutter-.git)

---

## 🚀 Getting Started

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/HijbullahMahmud/Agora-Broadcast-Flutter-.git
cd Agora-Broadcast-Flutter-
 
---

### 2️⃣ Install Dependencies
```bash
flutter pub get



### 3️⃣ Set Up Environment Variables
This project uses Envied for secure environment variables.
The .env file is NOT committed to Git for security reasons, but an example file is provided.
Example .env.example file:

```bash
appId=YOUR_AGORA_APP_ID
channelName=YOUR_CHANNEL_NAME
token=YOUR_TEMP_TOKEN

Steps to configure:
1. Copy .env.example to .env:

```bash
cp .env.example .env

2. Open .env and replace placeholders with your actual values from the Agora Console

### 4️⃣ Generate Envied Code
After setting .env values, generate the Envied files:
```bash
flutter pub run build_runner build --delete-conflicting-outputs

5️⃣ Run the App
```bash
flutter run
