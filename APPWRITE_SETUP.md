# 🚀 Appwrite Backend Setup Guide

## Prerequisites
- Appwrite instance (Cloud or Self-Hosted)
- Appwrite Console access

---

## Step 1: Create Appwrite Project

1. Go to your Appwrite Console
2. Click **Create Project**
3. Name it: `HRMS Workforce Management`
4. Copy the **Project ID** and update `lib/core/config/appwrite_config.dart`:
   ```dart
   static const String projectId = 'YOUR_PROJECT_ID';
   ```

5. Update the **endpoint** if self-hosted:
   ```dart
   static const String endpoint = 'https://your-domain.com/v1';
   ```

---

## Step 2: Create Database

Create a database named: **`hrms_database`**

### Collections to Create:

#### 1. `users` Collection
| Attribute    | Type    | Required | Notes                     |
|-------------|---------|----------|---------------------------|
| userId      | String  | Yes      | Appwrite Auth User ID     |
| email       | String  | Yes      |                           |
| role        | String  | Yes      | hr/manager/accountant/employee |
| employeeId  | String  | No       | Linked employee doc ID    |
| fcmToken    | String  | No       | Push notification token   |
| name        | String  | No       | Display name              |
| createdAt   | String  | Yes      | ISO 8601 timestamp        |

**Indexes:**
- `userId` (Key, Unique)
- `email` (Key, Unique)
- `role` (Key)

#### 2. `employees` Collection
| Attribute       | Type    | Required |
|----------------|---------|----------|
| employeeCode   | String  | Yes      |
| firstName      | String  | Yes      |
| lastName       | String  | Yes      |
| email          | String  | Yes      |
| phone          | String  | Yes      |
| employeeType   | String  | Yes      |
| department     | String  | Yes      |
| designation    | String  | Yes      |
| status         | String  | Yes      |
| joiningDate    | String  | Yes      |
| ... (all other Employee model fields as String/Boolean) |

**Indexes:**
- `employeeCode` (Key, Unique)
- `email` (Key, Unique)
- `status` (Key)
- `department` (Key)
- `employeeType` (Key)
- `name` (Fulltext) — for search

#### 3. `attendance` Collection
| Attribute     | Type    | Required |
|--------------|---------|----------|
| employeeId   | String  | Yes      |
| employeeCode | String  | Yes      |
| date         | String  | Yes      |
| status       | String  | Yes      |
| checkIn      | String  | No       |
| checkOut     | String  | No       |
| hoursWorked  | Double  | No       |
| overtimeHours| Double  | No       |
| remarks      | String  | No       |
| createdBy    | String  | No       |
| visitMode    | Boolean | No       |
| selfieUrl    | String  | No       |
| latitude     | Double  | No       |
| longitude    | Double  | No       |
| createdAt    | String  | Yes      |
| updatedAt    | String  | Yes      |

**Indexes:**
- `employeeId` (Key)
- `date` (Key)
- `status` (Key)
- `employeeId_date` (Key, composite)

#### 4. `leave_requests` Collection
| Attribute       | Type   | Required |
|----------------|--------|----------|
| employeeId     | String | Yes      |
| employeeName   | String | No       |
| employeeCode   | String | No       |
| fromDate       | String | Yes      |
| toDate         | String | Yes      |
| reason         | String | Yes      |
| status         | String | Yes      |
| approvedBy     | String | No       |
| rejectionReason| String | No       |
| createdAt      | String | Yes      |

**Indexes:**
- `employeeId` (Key)
- `status` (Key)
- `fromDate` (Key)
- `toDate` (Key)

#### 5. `notifications` Collection
| Attribute  | Type    | Required |
|-----------|---------|----------|
| userId    | String  | Yes      |
| title     | String  | Yes      |
| message   | String  | Yes      |
| isRead    | Boolean | Yes      |
| createdAt | String  | Yes      |

**Indexes:**
- `userId` (Key)
- `isRead` (Key)
- `createdAt` (Key, DESC)

---

## Step 3: Create Storage Bucket

Create a bucket named: **`visit_selfies`**
- **File Size Limit:** 10MB
- **Allowed Extensions:** jpg, jpeg, png, webp

---

## Step 4: Authentication Setup

1. Go to **Auth** → **Settings**
2. Enable **Email/Password** authentication
3. Create initial HR user:
   - Go to **Auth** → **Users** → **Create User**
   - Email: `hr@company.com`, Password: `your_password`
   - Copy the **User ID**
4. Create a document in the `users` collection:
   ```json
   {
     "userId": "<copied_user_id>",
     "email": "hr@company.com",
     "role": "hr",
     "name": "HR Admin",
     "createdAt": "2024-01-01T00:00:00.000Z"
   }
   ```

---

## Step 5: Security Rules (Permissions)

For each collection, set document-level security:

### `users` Collection
- Read: `any` (for login lookup)
- Create: `team:admin`
- Update: `user:{userId}` + `team:admin`
- Delete: `team:admin`

### `employees` Collection
- Read: `any` (authenticated users)
- Create: `team:hr`
- Update: `team:hr`
- Delete: `team:hr`

### `attendance` Collection
- Read: `any`
- Create: `team:hr` + `team:manager`
- Update: `team:hr` + `team:manager`

### `leave_requests` Collection
- Read: `any`
- Create: `any` (employees can create)
- Update: `team:hr` + `team:manager`

### `notifications` Collection
- Read: `user:{userId}`
- Create: `any`
- Update: `user:{userId}`
- Delete: `user:{userId}`

---

## Step 6: Platform Setup

### For Flutter Desktop (Windows/macOS)
1. Go to **Settings** → **Platforms**
2. Add a **Flutter** platform
3. Package name: `com.example.hr_desktop`
4. Hostname: `localhost`

### For Flutter Mobile (Android/iOS)
1. Add **Android** platform: `com.example.hrms_employee`
2. Add **iOS** platform: `com.example.hrmsEmployee`

---

## Step 7: Verify Configuration

After setup, update `lib/core/config/appwrite_config.dart` with your actual values:

```dart
static const String endpoint = 'https://cloud.appwrite.io/v1'; // or your self-hosted URL
static const String projectId = 'YOUR_ACTUAL_PROJECT_ID';
```

Then run:
```bash
flutter pub get
flutter run -d windows
```

Login with the HR account you created. You should see the Login screen → Dashboard.

---

## Architecture Overview

```
HR Desktop App ←→ Appwrite ←→ Employee Mobile App
     ↓                ↓              ↓
  Mark Attendance   Realtime      View Attendance
  Approve Leave    Database       Apply Leave
  Manage Users     Storage        Visit Mode
  Notifications    Auth           Notifications
```
