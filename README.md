# Sage's Wallet (by CortexFin)

Sage's Wallet is a modern, cross-platform mobile application for personal finance management, developed by CortexFin. Its goal is to provide users with powerful tools for tracking expenses, planning budgets, and achieving financial goals.

The project is built on a modern tech stack with a focus on quality, scalability, and security, featuring a full offline-first approach.

---

### ✨ Key Features

* **Multi-Wallet Management:** Create and manage multiple independent wallets.
* **Shared Access:** Invite other users to wallets with different roles (owner, editor).
* **Full Transaction CRUD:** Comprehensive management of incomes, expenses, and transfers.
* **Multi-Currency Support:** Support for multiple currencies with real-time exchange rates.
* **Budgeting:** Create budgets using various strategies, including an envelope system.
* **Financial Goals & Debt Tracking:** Tools for tracking savings and managing debts.
* **OCR & QR Code Scanning:** Automatically recognize data from receipts using the camera and QR codes.
* **Enhanced Security:** PIN code and biometric authentication to protect user data.
* **Offline-First Mode:** Full functionality with a local SQLite database, with background data synchronization.

---

### 🛠️ Tech Stack & Architecture

This project was built using modern technologies and best practices to ensure high quality and maintainability.

#### **Frontend (Mobile App)**

* **Framework:** Flutter
* **Architecture:** Clean Architecture & Repository Pattern
* **State Management:** Provider
* **Dependency Injection:** GetIt
* **Local Database:** SQLite
* **Secure Storage:** flutter_secure_storage (for auth tokens)
* **Monetization:** Google Play Billing

#### **Backend (Serverless)**

* **Platform:** **Supabase**
* **Database:** PostgreSQL
* **Authentication:** Supabase Auth
* **Cloud Logic:** Supabase Edge Functions (TypeScript) for secure server-side operations.
* **AI Services:** Google Cloud (Vertex AI Vision API) for OCR functionality.

*A note on architecture: The backend was strategically migrated from a self-hosted stack (Dart Frog, Docker) to a managed serverless architecture to dramatically increase stability, security, and reduce operational overhead.*
