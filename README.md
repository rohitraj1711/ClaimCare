# ClaimCare - Insurance Claim Management System

A production-grade Flutter Web application with Firebase backend for managing hospital insurance claims with full lifecycle workflows, financial calculations, and strict business rule enforcement.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

## 🏥 Overview

ClaimCare is a healthcare-focused insurance claim management system designed for hospital and insurance administrators. It provides:

- Complete claim lifecycle management (Draft → Submitted → Approved/Rejected → Settlement)
- Financial calculations with strict business rule enforcement
- Real-time updates using Firestore streams
- Audit trail for all claim actions
- Role-based access control ready structure

## 🛠 Tech Stack

### Frontend
- **Flutter** (latest stable) - Cross-platform UI framework
- **Riverpod** - State management
- **GoRouter** - Declarative routing
- **Google Fonts** - Typography
- **Responsive Framework** - Adaptive layouts

### Backend (Firebase)
- **Firebase Authentication** - Email/Password auth
- **Cloud Firestore** - NoSQL database
- **Cloud Functions** - Business logic enforcement
- **Firebase Hosting** - Web deployment

## 📁 Project Architecture

```
lib/
├── core/
│   ├── theme/           # App theme, colors, text styles
│   ├── constants/       # App constants, colors, status enums
│   ├── utils/           # Formatters, validators, helpers
│   └── widgets/         # Reusable UI components
│
├── features/
│   ├── auth/            # Login, authentication
│   ├── dashboard/       # Dashboard, summary cards
│   ├── claims/          # Claim form, details, actions
│   └── bills/           # Bill management
│
├── services/            # Firebase services
├── repositories/        # Data access layer
├── models/              # Data models
└── main.dart

firebase/
├── firestore.rules      # Security rules
├── firestore.indexes.json
└── functions/
    └── src/
        ├── index.ts
        ├── claim.functions.ts
        └── validators.ts
```

## 🗄 Firestore Data Model

### Collection: `claims`
| Field | Type | Description |
|-------|------|-------------|
| id | string | Document ID |
| patientName | string | Patient's full name |
| policyNumber | string | Insurance policy number |
| hospitalName | string | Hospital name |
| admissionDate | timestamp | Date of admission |
| dischargeDate | timestamp | Date of discharge (optional) |
| status | string | DRAFT, SUBMITTED, APPROVED, REJECTED, PARTIALLY_SETTLED |
| totalBillAmount | number | Sum of all bills |
| approvedAmount | number | Amount approved by insurer |
| advancePaid | number | Advance paid by patient |
| settledAmount | number | Amount settled so far |
| pendingAmount | number | approvedAmount - settledAmount |
| rejectionReason | string | Reason if rejected |
| createdAt | timestamp | Creation timestamp |
| updatedAt | timestamp | Last update timestamp |

### Subcollection: `claims/{claimId}/bills`
| Field | Type | Description |
|-------|------|-------------|
| id | string | Bill ID |
| type | string | ROOM, MEDICINE, SURGERY, DIAGNOSTIC |
| amount | number | Bill amount |
| description | string | Optional description |
| createdAt | timestamp | Creation timestamp |

### Subcollection: `claims/{claimId}/audit_logs`
| Field | Type | Description |
|-------|------|-------------|
| action | string | Action performed |
| timestamp | timestamp | When action occurred |
| performedBy | string | User ID |
| performedByEmail | string | User email |
| details | string | Additional details |

## 🔐 Security Rules

The Firestore security rules enforce:

1. **Authentication Required** - All reads/writes require authentication
2. **Protected Fields** - Status, approvedAmount, settledAmount cannot be modified directly by clients
3. **Draft-Only Edits** - Claims can only be edited in DRAFT status
4. **Cloud Functions Only** - Status transitions and financial updates go through Cloud Functions

## ☁️ Cloud Functions

| Function | Description |
|----------|-------------|
| `submitClaim` | Transitions claim from DRAFT to SUBMITTED |
| `approveClaim` | Approves claim with specified amount |
| `rejectClaim` | Rejects claim with reason |
| `settleClaim` | Processes partial or full settlement |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Node.js 18+ (for Cloud Functions)
- Firebase CLI
- A Firebase project

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd hospital_management

# Install Flutter dependencies
flutter pub get
```

### 2. Firebase Setup

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (select existing project)
firebase init

# Select:
# - Firestore
# - Functions
# - Hosting
```

### 3. Configure Firebase for Flutter

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure your Flutter app
flutterfire configure

# This will generate/update lib/firebase_options.dart
```

### 4. Deploy Firestore Rules and Functions

```bash
# Navigate to functions directory
cd firebase/functions

# Install npm dependencies
npm install

# Build TypeScript
npm run build

# Deploy (from project root)
cd ../..
firebase deploy --only firestore:rules,firestore:indexes,functions
```

### 5. Run the Application

```bash
# Run on web
flutter run -d chrome

# Run on web with specific port
flutter run -d chrome --web-port=8080
```

## 📱 Screens

### Login
- Email/password authentication
- Password reset functionality

### Dashboard
- Summary cards (Total Claims, Approved, Settled, Pending)
- Claims list with filtering and search
- Quick actions

### Create/Edit Claim
- Patient information form
- Hospital details
- Treatment dates
- Advance payment

### Claim Details (Tabbed)
- **Overview**: Patient & hospital info
- **Bills**: Add/edit/delete bills
- **Financial**: Summary with calculations
- **History**: Audit trail

## 📊 Status Workflow

```
    ┌─────────┐
    │  DRAFT  │
    └────┬────┘
         │ Submit
         ▼
    ┌───────────┐
    │ SUBMITTED │
    └─────┬─────┘
          │
    ┌─────┴─────┐
    ▼           ▼
┌────────┐  ┌──────────┐
│APPROVED│  │ REJECTED │
└────┬───┘  └──────────┘
     │ Settle
     ▼
┌──────────────────┐
│PARTIALLY_SETTLED │
└──────────────────┘
```

## 🎨 Design System

### Colors
- **Primary**: Blue (#2563EB) - Trust, reliability
- **Secondary**: Green (#059669) - Success, health
- **Status Colors**:
  - Draft: Grey (#6B7280)
  - Submitted: Blue (#3B82F6)
  - Approved: Green (#10B981)
  - Rejected: Red (#EF4444)
  - Partially Settled: Orange (#F59E0B)

### Typography
- Primary Font: Inter (Google Fonts)
- Clear hierarchy for financial data

## 🧪 Sample Data

To populate sample data, you can use the Firebase console or create a script:

```typescript
// Example claim document
{
  patientName: "John Doe",
  policyNumber: "POL-2024-001234",
  hospitalName: "City General Hospital",
  admissionDate: Timestamp.now(),
  status: "DRAFT",
  totalBillAmount: 0,
  approvedAmount: 0,
  advancePaid: 5000,
  settledAmount: 0,
  pendingAmount: 0,
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now()
}
```

## 🌐 Deployment

### Firebase Hosting

```bash
# Build for web
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### Environment Configuration

Create environment-specific configurations:

```dart
// lib/config/env_config.dart
class EnvConfig {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION');
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5001',
  );
}
```

Build with environment variables:
```bash
flutter build web --dart-define=PRODUCTION=true
```

## 📝 License

This project is for educational/demonstration purposes.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

Built with ❤️ for healthcare workflow management
