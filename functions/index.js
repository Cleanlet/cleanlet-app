/* eslint-disable require-jsdoc */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.createUserDoc = functions.auth.user().onCreate((user) => {
  const { uid, email, displayName, photoURL } = user;
  admin
    .firestore()
    .collection("users")
    .doc(uid)
    .set({
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    })
    .then((writeResult) => {});
});

exports.checkWeatherStatusPubSub = functions.pubsub
  .schedule("every 1 minutes")
  .onRun((context) => {
    console.log("This will be run every 5 minutes!");
    checkWeatherStatus();
    return null;
  });

exports.triggerWeatherStatus = functions.https.onRequest(
  (request, response) => {
    console.log("manually trigger weather check");
    checkWeatherStatus();
    return response.send("manually trigger weather check");
  }
);

exports.calculateJobPoints = functions.firestore
.document("inletCleaningJobs/{jobId}")
.onUpdate((change, context) => {
  const newValue = change.after.data();
  const status = newValue.status;

  if (status === "completed") {
      //calculate points here
      console.log("completed job")
  }
});

exports.inletStatusUpdated = functions.firestore
  .document("inlets/{inletId}")
  .onUpdate((change, context) => {
    const newValue = change.after.data();
    const status = newValue.status;
    const watching = newValue.watching;

    if (status === "cleaningNeeded") {
      createInletCleaningJob(context.params.inletId);
      sendPushNotifications(watching);
    }
  });

  exports.checkUploadedImage = functions.storage.object().onFinalize((object) => {
    console.log("checking something")
    console.log(object.name)
  });

function checkWeatherStatus() {
  console.log("check weather status");
  fetch('https://api.weather.gov/points/39.9526,-75.1652')
  .then((response) => response.json())
  .then((data) => console.log(data));
}

function updateInletStatus(inletId, status = null) {
  admin.firestore().collection("inlets").doc(inletId).update({
    lastChecked: admin.firestore.FieldValue.serverTimestamp(),
    status: status,
  });
}

function createInletCleaningJob(inletId) {
  admin
    .firestore()
    .collection("inletCleaningJobs")
    .add({
      // TODO: figure out how to get a docRef here
      inletId: inletId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "pending",
    })
    .then(() => {
      admin.firestore().collection("inlets").doc(inletId).update({
        status: "cleaningScheduled",
      });
    });
}

async function sendPushNotifications(watchingUsesrIds) {
  const fcmTokens = [];
  const payload = {
    notification: {
      title: "Inlet needs cleaning",
      body: "The inlet near you needs cleaning",
      icon: "https://placekitten.com/200/200",
    },
  };
  await watchingUsesrIds.forEach((userId) => {
    admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get()
        .then((doc) => {
            if (doc.exists) {
                //Todo: add fcmToken to fcmTokens array
                console.log(doc.data())
            }
        })
  });
  if (fcmTokens.length > 0) {
    admin.messaging().sendToDevice(fcmTokens, payload);
  }
}
