const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.notifyNearbyUsers = functions.firestore
    .document("donations/{donationId}")
    .onCreate(async (snap, context) => {

  const data = snap.data();
  const donationLat = data.latitude;
  const donationLng = data.longitude;

  if (!donationLat || !donationLng) return null;

  const usersRef = admin.firestore().collection("users");
  const usersSnap = await usersRef.get();

  const tokens = [];

  usersSnap.forEach(doc => {
    const u = doc.data();
    if (u.latitude && u.longitude && u.fcmToken) {
      const distance = getDistance(
        donationLat, donationLng,
        u.latitude, u.longitude
      );
      if (distance <= 5) { // 5 KM radius
        tokens.push(u.fcmToken);
      }
    }
  });

  if (tokens.length === 0) return null;

  const payload = {
    notification: {
      title: "New Free Item Nearby!",
      body: `${data.title} is available near you.`,
    },
  };

  return admin.messaging().sendToDevice(tokens, payload);
});


function getDistance(lat1, lon1, lat2, lon2) {
  function toRad(x) { return x * Math.PI / 180; }

  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
    Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) *
    Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}
