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







