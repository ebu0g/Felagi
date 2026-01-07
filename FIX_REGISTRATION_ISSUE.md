# Registration Issue - Root Cause & Fix

## The Problem You're Experiencing

1. **Register as Pharmacy** → Appears to fail silently
2. **Try same email again** → "Email is in use" (Auth user exists)
3. **Try to login** → "User profile not found" (Firestore user missing)

## Root Cause

When you register as **Pharmacy**:
- ✅ Firebase Auth user IS being created
- ❌ Firestore user profile is NOT being created
- ❌ Auth user deletion is probably failing too

This happens because:
1. Registration logic creates Auth user first
2. Then tries to upload document
3. If upload fails (or document is missing), it tries to delete the Auth user
4. But the deletion might fail, leaving the Auth user orphaned
5. Firestore user is never created, so login fails

## What Was Fixed

### 1. **Mandatory Document Check for Pharmacy** (auth_controller.dart)
Added an upfront check that immediately stops registration if Pharmacy doesn't have a document:
```dart
if (role == 'Pharmacy') {
  if (documentBytes == null || documentBytes!.isEmpty) {
    // Delete auth user first
    // Throw clear error
  }
}
```

### 2. **Better Logging During Auth Deletion**
Now logs if auth user deletion succeeds or fails:
```
❌ Auth user deletion failed: <reason>
✅ Auth user deleted successfully
```

### 3. **Improved Error Display** (register_screen.dart)
- Errors now show in red
- Display for 5 seconds instead of default 2 seconds
- Added safety check `if (!mounted) return`

## How to Test the Fix

### Test Case 1: Register Pharmacy WITHOUT Document (Should Fail Clearly)
1. Fill in all fields
2. Select "Pharmacy" role
3. **DON'T pick a document**
4. Click Register
5. **Expected**: Red error message: "Pharmacy registration requires a valid PDF document."
6. Check console: Should see `❌ Pharmacy requires document but documentBytes is empty`

### Test Case 2: Register Pharmacy WITH Document (Should Succeed)
1. Fill in all fields
2. Select "Pharmacy" role
3. **Pick a PDF file** - verify you see "File selected: xxx.pdf (YYY KB)"
4. Click Register
5. **Expected**: "Registration successful!" and redirect to login
6. Check console logs for:
```
🔵 REGISTER START: email=..., role=Pharmacy
📄 Document info - bytes: XXXXXX bytes
✅ Auth user created: ...
📤 Starting document upload...
   - Uploading with bytes (length: XXXXXX)...
   ✅ Upload to Firebase Storage completed
✅ Download URL obtained: https://firebasetorage...
📝 Adding documentUrl to Firestore: https://firebasetorage...
💾 Saving to Firestore: users/...
✅ Firestore save completed
🟢 REGISTER COMPLETE: uid=..., role=Pharmacy, hasDocument=true
```

### Test Case 3: Login After Successful Registration
1. After successful Pharmacy registration
2. Go to Login screen
3. Enter same email and password
4. **Expected**: Should either:
   - ✅ Show "Your pharmacy is pending approval. Please wait for admin approval." (correct, Pharmacy needs admin approval)
   - ✅ Show admin panel if you also approved it

5. **NOT**: "User profile not found"

## If You Still See "User Profile Not Found"

It means Firestore save is failing. Check:

1. **Firebase Firestore Security Rules** - Do they allow writes?
   - Go to Firebase Console → Firestore → Rules
   - Check if authenticated users can write to `users` collection

2. **Check Browser Console (F12)**
   - Look for any Firebase error messages
   - Share the full console output

3. **Check Firebase Storage Rules** - Are they too restrictive?
   - Try temporarily allowing all authenticated users:
   ```
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

## Console Log Markers to Watch

| Marker | Status | What It Means |
|--------|--------|---------------|
| 🔵 REGISTER START | Info | Registration process started |
| ✅ Auth user created | Success | Firebase Auth user made |
| ❌ Pharmacy requires document | Error | Pharmacy without document (expected to fail) |
| 📤 Starting document upload | Info | About to upload to Storage |
| ✅ Upload to Firebase Storage completed | Success | File uploaded to Storage |
| ✅ Download URL obtained | Success | Can access file from URL |
| 💾 Saving to Firestore | Info | About to create user profile |
| ✅ Firestore save completed | Success | User profile created |
| 🟢 REGISTER COMPLETE | Success | Everything done! |
| ⚠️  Auth user deletion failed | Warning | Couldn't clean up failed registration |

## Next Steps

1. **Test registration with a PDF file**
2. **Share the console logs** if still failing
3. **Check Firestore** to see if user document was created with `documentUrl` field
4. **Check Firebase Storage** to see if PDF file was uploaded to `pharmacy_documents/` folder

Once registration works, the full workflow is:
1. Pharmacy registers with PDF → gets "pending approval" message
2. Admin sees pharmacy in "Pending Approvals" with View Document button
3. Admin clicks View Document to review PDF
4. Admin clicks Approve or Reject
5. Approved pharmacy can login
6. Rejected pharmacy registration is deleted
