/* eslint-disable require-jsdoc */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require('node-fetch');

admin.initializeApp();

const dummylocation = {
  "lat" : "39.975",
  "lon" : "-75.087"
};

const dummyjob = {
  "completedTimestamp" : "2023-02-08 10:30:22",
  "acceptedLocation" : ["39.975", "-75.087"],
  "acceptedTimestamp" : "2023-02-08 09:30:22",
  "startedTimestamp" : "2023-02-08 10:20:18",
  "user" : "PXMzohq1sFu0VTg8OGyMqUIT1p9g",
    //  "jobsCompleted" -> fetch from user data
    //  "sameJobCompleted" -> fetch from user data
    //  "level" -> #TODO
    //  "points" -> fetch from user data
  "totalJobTime" : 600,
  "jobQuality" : 1,
  "inlet" : "5XZw9XNw8skt3SRoBFyu"
    //  "inletLat" -> fetch from inlet data
    //  "inletLon" -> fetch from inlet data
    //  "difficultyScore" -> fetch from inlet data
    //  "overrideParams" -> fetch from settings
};

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

function getDistanceFromLatLonInKm(lat1,lon1,lat2,lon2) {
  var R = 6371; // Radius of the earth in km
  var dLat = deg2rad(lat2-lat1);  // deg2rad below
  var dLon = deg2rad(lon2-lon1); 
  var a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
    Math.sin(dLon/2) * Math.sin(dLon/2)
    ; 
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
  var d = R * c; // Distance in km
  return d;
}

function deg2rad(deg) {
  return deg * (Math.PI/180)
}

exports.calculateJobPoints = functions.firestore
.document("inletCleaningJobs/{jobId}")
.onUpdate((change, context) => {
  const newValue = change.after.data();
  const status = newValue.status;

  //  1. evaluate the distance from the user to the location
  //  2. evaluate the time from the start of the job to the end of the job
  //  3. evaluate the time from job acceptance to job start (distance traveled)
  //  4. get the feet/min traveled by the user, compare that with normal walking speeds
  //  5. get the user's points
  //  6. get inlet's difficulty score

  distance = dummyjob['']

  if (status === "completed") {
    //  get inlet location
    admin.firestore().collection('inlets').doc(inletId).get("geoLocation").then(queryResult => {
      Geolocation = queryResult;
      UserLocation = acceptedLocation;
      distance = getDistanceFromLatLonInKm(Geolocation["lat"],Geolocation["lon"],UserLocation["lat"],UserLocation["lon"])
      console.log(distance + "km")
      let walkingSpeed = 4.5 //km/h
      totalTime = (distance / walkingSpeed) * 1.6;
      //  compare this time with the actual time
      actualTime = startedTimestamp - acceptedTimestamp
    });
    return response.send("pippo")
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
  admin
    .firestore()
    .collection("inlets")
    .get()
    .then(function (querySnapshot) {
      querySnapshot.forEach(function (doc) {
        fetch('https://api.weather.gov/points/' + dummylocation['lat'] + ',' + dummylocation['lon'])
          .then((response) => response.json())
          .then((data) => fetch('https://api.weather.gov/gridpoints/' + data['properties']['cwa'] + '/' + data['properties']['gridX'] + ',' + data['properties']['gridY']))
          .then((res) => res.json())
          .then((res) => {
            probabilityOfPrecipitation = res['properties']['probabilityOfPrecipitation']['values'];
            mm = res['properties']['quantitativePrecipitation']['values'];

            //  console.log(tmpjson);
            let RainDays = 0;
            //  forecast period
            let RainThreshold = 4;
            let RainPercThreshold = 30;
            let RainAccumulation = 0;
            console.log("check rain events in the next " + RainThreshold + " days");
            for(var values of probabilityOfPrecipitation) {
              //  console.log(values['value']);
              if (RainDays < RainThreshold) {
                if (values['value'] > RainPercThreshold) {
                  console.log("It is going to rain in " + RainDays + " days, with a probability of " + values['value'] + "%");
                  RainAccumulation ++;
                }
              }
              RainDays ++;
            }

            console.log("  it's going to rain for " + RainAccumulation + " days within the next " + RainThreshold + " days.")

            //  sets the inlet status to 
            if (RainAccumulation == 1) {
              //  updateInletStatus(doc.id, "rain");
            } if (RainAccumulation > 1) {
              //  updateInletStatus(doc.id, "lotsofrain");
            } else if (RainAccumulation == 0) {
              //  updateInletStatus(doc.id, "good");
            }
            
          });

        console.log(doc.id, " => ", doc.data());
        //  updateInletStatus(doc.id, "good");
      });
    });
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
