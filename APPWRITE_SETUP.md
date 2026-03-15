# 🚀 Appwrite Backend Setup Guide

## Prerequisites
- Appwrite instance (Cloud or Self-Hosted)
- Appwrite Console access

---

## Step 1: Create Appwrite Project
1. Name it: `HRMS Workforce Management`
2. Update `lib/core/config/appwrite_config.dart` with your **Project ID**.

---

## Step 2: Create Database
Create a database named: **`hrms_database`**

### Collections to Create:

#### 1. `users` Collection
- userId (String), email (String), role (String), employeeId (String?), name (String?), createdAt (String)
- **Indexes**: `userId` (Unique), `email` (Unique)

#### 2. `employees` Collection
- employeeCode, firstName, lastName, email, phone, employeeType, department, designation, status, joiningDate (All String)
- **Indexes**: `employeeCode` (Unique), `email` (Unique)

#### 3. `salary_structures` Collection
- employeeId (String, Unique)
- employeeCode (String)
- basicSalary, hra, da, conveyanceAllowance, medicalAllowance, specialAllowance, otherAllowances (Double)
- grossSalary, totalDeductions, netSalary, ctc (Double)
- pfEmployee, pfEmployer, esicEmployee, esicEmployer, professionalTax, tds, otherDeductions (Double)
- isPfApplicable, isEsicApplicable (Boolean)
- advanceBalance, loanBalance (Double)
- effectiveFrom, createdAt, updatedAt (String)
- remarks, status (String?)

#### 4. `advance_salary` Collection (CRITICAL for your error)
| Attribute           | Type   | Required |
|--------------------|--------|----------|
| employeeId         | String | Yes      |
| employeeCode       | String | Yes      |
| advanceAmount      | Double | Yes      |
| reason             | String | Yes      |
| status             | String | Yes      |
| repaidAmount       | Double | Yes      |
| pendingAmount      | Double | Yes      |
| installments       | Integer| Yes      |
| installmentsCleared| Integer| Yes      |
| requestDate        | String | Yes      |
| approvalDate       | String | No       |
| clearanceDate      | String | No       |
| remarks            | String | No       |
| approvedBy         | String | No       |
| createdBy          | String | No       |
| updatedAt          | String | Yes      |
| createdAt          | String | Yes      |

**Note**: Ensure the Collection ID is set to `advance_salary`.

#### 5. `payments` Collection (Salary Slips)
- id, employeeId, employeeCode, employeeName, status, paymentMode (String)
- month, year (Integer)
- grossSalary, totalDeductions, netSalary (Double)
- isLocked (Boolean)
- createdAt, updatedAt (String)

#### 6. `attendance` Collection
- employeeId, employeeCode, date, status (String)
- checkIn, checkOut, selfieUrl (String?)
- hoursWorked, overtimeHours, latitude, longitude (Double?)
- visitMode (Boolean)
- createdAt (String)

---

## Step 3: Troubleshooting
If you see **"Collection not found"** error:
1. Go to Appwrite Console → Database → `hrms_database`.
2. check if the Collection ID matches exactly (e.g., `advance_salary`).
3. Click "Create Collection" if it's missing.
4. Add all **Attributes** listed above with the correct types.
5. In the **Settings** tab of the collection, add **Permissions**:
   - Role: `any` or `users`
   - Permissions: `Create`, `Read`, `Update`
