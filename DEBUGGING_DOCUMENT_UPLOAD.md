# Document Upload Debugging Guide

## What Changed
I've added comprehensive logging throughout the document upload flow to help identify exactly where the document URL is being lost.

## Steps to Test & Debug

### 1. **Enable Console Output**
   - Run your Flutter web app with: `flutter run -d chrome`
   - Open Chrome DevTools (F12) → Console tab
   - Clear all logs before starting the test

### 2. **Register a New Pharmacy Account**
   - Fill in all fields
   - **Select "Pharmacy" as role**
   - **Click "Choose Document" and pick a PDF file**
   - Watch for this confirmation: `"File selected: filename.pdf (XXX KB)"`
   - Click "Register"

### 3. **Check Console Logs (Look for these patterns)**

#### ✅ Expected Success Sequence:
```
🔵 REGISTER START: email=pharmacy@example.com, role=Pharmacy
📄 Document info - bytes: 1234567 bytes, path: null
✅ Auth user created: abc123xyz...
📤 Starting document upload...
   - documentBytes is null? false
   - documentBytes length: 1234567
   - kIsWeb: true
   - Storage path: pharmacy_documents/abc123xyz.../pharmacy_documents_1234567890.pdf
   - Uploading with bytes (length: 1234567)...
   ✅ Upload to Firebase Storage completed
✅ Download URL obtained: https://firebasetorage.googleapis.com/...
📝 Adding documentUrl to Firestore: https://firebasetorage...
💾 Saving to Firestore: users/abc123xyz...
   - Data: uid, fullName, email, phone, address, role, isApproved, createdAt, documentUrl
✅ Firestore save completed
🟢 REGISTER COMPLETE: uid=abc123xyz..., role=Pharmacy, hasDocument=true
```

#### ❌ If Something Fails, Look for:

**Problem: "documentBytes is null? true"**
- Issue: File picker didn't capture bytes on web
- Solution: Browser storage permissions might be blocking file access

**Problem: "documentBytes length: 0"**
- Issue: File was selected but is empty
- Solution: Try a different PDF file

**Problem: "⚠️ No document data provided"**
- Issue: Neither bytes nor path were passed
- Solution: File wasn't actually selected despite UI saying it was

**Problem: "❌ Error uploading document"**
- Issue: Firebase Storage upload failed
- Check: Firebase Storage security rules (likely too restrictive)
- Check: Storage quota not exceeded

**Problem: "documentUrl is null - will not be saved to Firestore"**
- Issue: Storage upload succeeded but getDownloadURL() failed
- This shouldn't happen if upload succeeded

### 4. **Verify in Firestore Console**

After successful registration:
1. Open [Firebase Console](https://console.firebase.google.com)
2. Go to Firestore Database → `users` collection
3. Find the pharmacy account you just created
4. **Check if `documentUrl` field exists and contains a URL**
   - ✅ If it has a URL starting with `https://firebasetorage...`, upload worked!
   - ❌ If field is missing or empty, something stopped it from saving

### 5. **Test Admin Panel After Document Upload**

1. Login as Admin
2. Go to "Pending Approvals"
3. You should now see the pharmacy with the blue "View Document" button (not red warning)
4. Click "View Document" to open the PDF
5. If document opens, everything is working!

## Firebase Storage Rules (for reference)

Your storage rules might need to allow pharmacy uploads. Check in Firebase Console → Storage → Rules:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow pharmacy documents upload
    match /pharmacy_documents/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Common Causes & Fixes

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "File selected" shows, then "No document attached" in admin | documentBytes is null | Check file picker web permissions |
| Upload succeeds in logs but Firestore has no documentUrl | Upload succeeds but getDownloadURL() fails | Check Storage rules |
| Error: "Platform._operatingSystem" | Using File() on web instead of bytes | Already fixed - using withData:true |
| Firebase error when uploading | Storage rules too restrictive | Allow authenticated users to upload |

## Next Steps After Debug

Once logs show successful upload and Firestore has documentUrl:
1. Admin can see the document in pending approvals
2. Admin can view the PDF by clicking button
3. Admin can approve/reject the pharmacy
4. Approved pharmacy can login

Share your console log output if you still see issues!
