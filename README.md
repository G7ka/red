# Penguin App 🐧

Welcome to the Penguin App repository! This is a Flutter project using Supabase for the backend.

## 🚀 Getting Started for Collaborators

If you've been invited to work on this project, follow these steps to get your local environment set up:

### 1. Prerequisites
Ensure you have the following installed on your machine:
* [Git](https://git-scm.com/)
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Ensure you run `flutter doctor` to verify your setup)
* An IDE like [VS Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio)

### 2. Clone the Repository
Open your terminal and clone the repository to your local machine:
```bash
git clone https://github.com/G7ka/red.git
cd red
```

### 3. Install Dependencies
Once inside the project directory, fetch all the required Flutter packages:
```bash
flutter pub get
```

### 4. Backend & API Keys
You **do not** need to manually configure `.env` files for the database to run locally! The Supabase initialization is currently handled directly inside `lib/main.dart`.

### 5. Run the App
Connect a physical device or start an emulator, then run:
```bash
flutter run
```

---

## 🛠 Project Structure
* `lib/screens/` - Contains all the UI pages (Home, Anonymous, Chats, Settings).
* `lib/services/` - Contains backend logic, state management, matching algorithms, and Supabase database interactions.
* `lib/models/` - Data structures and models.
* `lib/main.dart` - Entry point of the application.

Happy coding! 🎉
