# Thinkmay Native Mobile Architecture

The Thinkmay mobile application (`native/mobile`) is built with Flutter and follows a strict **Clean Architecture** combined with **Domain-Driven Design (DDD)**. This isolates the core streaming protocol, business logic, and UI layer, ensuring that the complex WebRTC state doesn't tangle with presentation components.

## High-Level Tech Stack

* **State Management**: `flutter_bloc`
* **Dependency Injection**: `get_it` & `injectable` (Code-generation based)
* **Routing**: `go_router`
* **Networking & DB**: `pocketbase`, `supabase_flutter`, `dio`, `http`
* **Streaming Protocol**: `flutter_webrtc`, `web_socket_channel`
* **Data Modeling**: `freezed`, `json_serializable`, `dartz` (for functional `Either` error handling)
* **UI/UX**: `flutter_screenutil` (responsive design), `flutter_localizations` (i18n)

## Directory Structure (`lib/`)

The application is cleanly divided into architectural layers:

### 1. `presentation/` (UI Layer)
Houses everything the user interacts with.
* **`screen/`**: Top-level Flutter pages/views (e.g., `OnboardingVirtualScreen`, `Cell`).
* **`components/`**: Reusable UI widgets and atomic elements.
* **`router/`**: Centralized routing logic utilizing `go_router` (`AppRouter`). State changes trigger navigation dynamically.

### 2. `domain/` (Business Logic Layer)
The pure, dependency-free core of the app.
* **`models/`**: Abstract entities defining what data looks like across the app.
* **`use_case/`**: Business logic encapsulations. Each UseCase (e.g., login, fetch servers) takes a repository interface and returns a `dartz` `Either<Failure, Result>`.

### 3. `data/` (Data Layer)
Implements the interfaces defined in the Domain layer.
* **`network/`**: API clients, Dio interceptors, and raw PocketBase/Supabase interactions.
* **`repository/`**: Concrete implementations of domain repositories, responsible for mapping raw JSON/network data into domain models using `freezed`.
* **`storage/`**: Local persistence using `shared_preferences`.

### 4. `core/` (Protocol & Infrastructure)
Contains the heavy-lifting required for Thinkmay's cloud-gaming functionality.
* **`webrtc/`**: Wrappers for `MediaRTC`, `DataRTC`, and `MicrophoneRTC` to manage individual WebRTC connections.
* **`hid/` & `cursor/`**: Handlers for parsing touch inputs, virtual gamepads, and server-driven cursor updates into binary payloads.
* **`thinkmay_client.dart`**: The crown jewel of the core layer. This class acts as the grand orchestrator (mirroring the Web client's `Thinkmay` TypeScript class). It maintains 4 independent connections (Video, Audio, HID, Microphone), tracks deep WebRTC metrics (jitter, packet loss, decode time), handles automatic reconnect loops, and queues raw binary HID events to send over the DataChannel.

### 5. `dependency_injection/`
Uses `injectable` annotations (`@injectable`, `@lazySingleton`) to auto-generate a dependency graph (`injection.config.dart`). The `configureDependencies()` function initializes all services, blocs, and repositories upon app startup.

## Streaming Architecture (The `ThinkmayClient`)

The WebRTC streaming logic is highly decoupled from the Flutter UI. 
* **Connection Loops**: The client spins up independent asynchronous loops for Video, Audio, Data, and Mic. If any connection drops, the internal loop waits 1 second and automatically renegotiates.
* **Metrics Pipeline**: The `_handleMetrics` method constantly ingests WebRTC statistics (e.g., `framesDecoded`, `jitterBufferDelay`) and standardizes them into a highly detailed `Metric` object, ensuring the mobile app has parity with the web dashboard's network telemetry.
* **HID Queuing**: Touch and virtual gamepad events are converted into binary sequences (`EventCode`). To prevent blocking the UI thread or overwhelming the WebRTC data channel, these are added to an internal `_hidQueue` and flushed in batches asynchronously.

## Startup Flow
Located in `main.dart`, the `void main()` execution relies on early initialization:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `configureDependencies()` configures the `get_it` service locator.
3. `ensureAppLocalizationsRegistered` prepares the `intl` files.
4. `runApp(MyApp())` mounts the `MaterialApp.router` with `flutter_screenutil` defining the base mobile viewport layout (375x812).

## Summary
The Flutter app perfectly mirrors the complexity of the React Native / Next.js web application but utilizes strictly-typed, scalable mobile paradigms (`Bloc`, `DDD`, `GetIt`). The separation of `ThinkmayClient` away from the `presentation/` blocs ensures that the video streaming engine remains isolated, highly testable, and robust against UI lifecycle changes.
