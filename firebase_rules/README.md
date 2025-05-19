# Firebase Security Rules

This directory contains security rules for Firebase Realtime Database.

## How to Upload Security Rules

### Option 1: Using Firebase Console

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to "Realtime Database" in the left sidebar
4. Click on the "Rules" tab
5. Copy the contents of `database.rules.json` and paste them into the rules editor
6. Click "Publish" to apply the rules

### Option 2: Using Firebase CLI

1. Install Firebase CLI if you haven't already:
   ```
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```
   firebase login
   ```

3. Initialize Firebase in your project (if not already done):
   ```
   firebase init
   ```

4. Deploy the rules:
   ```
   firebase deploy --only database
   ```

## Security Rules Explanation

These security rules implement the following security model:

### User Data (`/Users/{userId}`)
- Users can read and write only their own data
- Responders can read civilian data but not modify it
- User type cannot be changed after creation

### Emergency Requests (`/sos/{emergencyId}`)
- Any authenticated user can read active emergencies
- Only authenticated users can create emergencies
- Only the creator or responders can update an emergency
- All emergency data must include required fields

### Active Responders (`/activeResponders/{responderId}`)
- Any authenticated user can see active responders
- Only responders can update their own status
- Location data must be valid coordinates

### Assignments (`/assigned/{responderId}`)
- Responders can read their own assignments
- Only responders or the system can create/update assignments
- Assignment data must include all required fields

## Important Notes

1. These rules assume that user roles are stored in the `UserType` field
2. The rules validate data formats to ensure consistency
3. The rules prevent unauthorized access to sensitive data
4. Connection status is readable by any authenticated user

## Testing Rules

You can test these rules using the Firebase Rules Simulator:

1. Go to the Firebase Console
2. Navigate to "Realtime Database" > "Rules"
3. Click on "Rules Playground" in the top right
4. Create test scenarios to verify the rules work as expected
