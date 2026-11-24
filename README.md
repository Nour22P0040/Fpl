# fplhub_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Lab: Firebase (Firestore + Realtime Database)

**(a) Why is presence in Realtime Database and profiles in Firestore?**
Presence is a tiny value that changes all the time and has to flip to offline even when the phone loses signal or crashes; Realtime Database has `onDisconnect()` for this, so the server writes "offline" for us. Profiles are slow-changing records we want to sort and query (`orderBy('name')`), which is what Firestore collections are built for.

**(b) Which rule stops manager A from editing manager B's profile, and what if it were missing?**
The line `request.auth.uid == userId` in `firestore.rules` only lets you write the document whose id is your own uid. Without it, any signed-in manager could overwrite (or create) someone else's profile — change their name, email, phone or team.

**(c) How does the chat rule keep a third manager out of a conversation?**
The chat id is built from the two members' uids, and the rule `request.auth.uid in chatId.split('_')` only lets a signed-in user read or write messages in a chat whose id contains their own uid, so a third manager is denied every read and every new message there.
