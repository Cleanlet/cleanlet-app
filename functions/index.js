/* eslint-disable require-jsdoc */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require('node-fetch');
const https = require('node:https');
const path = require('path');
const csv = require('csv-parser');
const fs = require('fs');

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

function calculatePoints(jobCompletionTime, taskAverageTime, distanceFromJob) {
  const pointsPerSecond = 10; // set the base points per second
  const timeDifference = taskAverageTime - jobCompletionTime;
  const speedFactor = Math.max(timeDifference / taskAverageTime, 0);
  const bonusPoints = Math.floor(speedFactor * pointsPerSecond * jobCompletionTime);
  const sigmoidInput = distanceFromJob / 1000; // assuming distance is in meters
  const sigmoidOutput = 1 / (1 + Math.exp(-sigmoidInput + 5));
  const distancePoints = Math.floor(sigmoidOutput * pointsPerSecond * jobCompletionTime);
  const totalPoints = Math.floor(jobCompletionTime * pointsPerSecond + bonusPoints + distancePoints);
  return totalPoints;
}


exports.calculateJobPoints = functions.firestore
.document("inletCleaningJobs/{jobId}")
.onUpdate(async (change, context) => {
  const newValue = change.after.data();

  const { acceptedAt,
          startedAt,
          finishedAt,
          inletId,
          status,
          acceptedLocation,
          acceptedBy
        } = newValue;

  if (status === "cleaned") {
    console.log("hello2");
    //  get inlet location

    const inletRef = admin.firestore().collection('inlets').doc(inletId);
    const doc = await inletRef.get();
    if (!doc.exists) {
      console.log('No such document!');
    } else {
      let { 
        geoLocation,
        taskAverageTime
      } = doc.data();
      const jobCompletionTime = finishedAt - startedAt;
      //  console.log(geoLocation);
      //  taskAverageTime can be null
      if (!taskAverageTime) {
        taskAverageTime = jobCompletionTime;
      }

      const distanceFromJob = getDistanceFromLatLonInKm(
        acceptedLocation.latitude, acceptedLocation.longitude,
        geoLocation.latitude, geoLocation.longitude
      );
      //  console.log(calculatePoints(jobCompletionTime,taskAverageTime,distanceFromJob));

      const weatherRiskScore = 1;
      let jobId = context.params.jobId;
      let points = calculatePoints(jobCompletionTime,taskAverageTime,distanceFromJob) + weatherRiskScore;

      const jobRef = admin.firestore().collection('inletCleaningJobs').doc(jobId);
      const usrRef = admin.firestore().collection('users').doc(acceptedBy);
      let batch = admin.firestore().batch();
      batch.update(jobRef, {points: points, status: "finalized"});
      batch.update(usrRef, {points: admin.firestore.FieldValue.increment(points)});
      await batch.commit();
    }

    //admin.firestore().collection('inlets').doc(inletId).get().then(queryResult => {
    //    const jobCompletionTime = finishedAt - startedAt;
    //    console.log(queryResult['geoLocation']);
    //    let taskAverageTime = queryResult['taskAverageTime'];
    //    //  taskAverageTime can be null
    //    if (!taskAverageTime) {
    //      taskAverageTime = jobCompletionTime;
    //    }
    //
    //    const distanceFromJob = getDistanceFromLatLonInKm(
    //      acceptedAt[0], acceptedAt[1],
    //      queryResult['geoLocation'][0], queryResult['geoLocation'][1]);
    //    return calculatePoints(jobCompletionTime,taskAverageTime,distanceFromJob);
    //});
  }
})

  

exports.inletStatusUpdated = functions.firestore
  .document("inlets/{inletId}")
  .onUpdate((change, context) => {
    const newValue = change.after.data();
    const status = newValue.status;
    const watching = newValue.watching;

    if (status === "cleaningNeeded") {
      createInletCleaningJob(context.params.inletId, newValue.risk);
      //  sendPushNotifications(watching);
    }
  });

  exports.checkUploadedImage = functions.storage.object().onFinalize((object) => {
    const fileBucket = object.bucket; // The Storage bucket that contains the file.
const filePath = object.name; // File path in the bucket.
const fileDir = path.dirname(filePath);
console.log("uploaded in " + fileDir);
const contentType = object.contentType; // File content type.
console.log(contentType)
if (fileDir == 'inlet-uploads' && (contentType == "application/vnd.ms-excel" || contentType == "text/csv")) {
  console.log(contentType);
  console.log(filePath);
  const results = [];
  fs.createReadStream(filePath)
    .pipe(csv())
    .on('data', (data) => ResultStorage.push(data))
    .on('end', () => {
      console.log(results);
    })
  /*admin
  .firestore()
  .collection("users")
  .doc(geoUidThing)
  .set({
    email: email,
    displayName: displayName,
    photoURL: photoURL,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },{merge: true})
  .then((writeResult) => {});*/
} else {
  console.log('Wrong folder or weird file');
  return null;
}

const metageneration = object.metageneration; // Number of times metadata has been generated. New objects have a value of 1.
console.log(object);
  });

  function getWeatherData(periods) {
    const today = periods[0];
    const tomorrow = periods[1];
    const tenDays = periods.slice(0, 10);
  
    return { today, tomorrow, tenDays };
  }
  
function calculateRainRisk(today, tomorrow, tenDays) {
  // Calculate the rain accumulation for the next 10 days
  const rainAccumulation = tenDays.reduce((total, day) => {
    const { qpf = 0 } = day;
    return total + qpf;
  }, 0);

  // Calculate the rainfall per hour for tomorrow
  const { detailedForecast } = tomorrow;
  const rainfallPerHourTomorrow = detailedForecast.match(/(\d+(?:\.\d+)?).+rain/);

  // Calculate the probability of precipitation for the next 10 days
  const probabilityOfPrecipitation = tenDays.reduce((total, day) => {
    const { pop = 0 } = day;
    return total + pop;
  }, 0) / 10;

  //  dry event
  //  add;

  // Calculate the risk score based on the rain accumulation, rainfall per hour, and probability of precipitation
  const riskScore = (rainAccumulation * 2) + (rainfallPerHourTomorrow * 10) + (probabilityOfPrecipitation * 5);
  return {score:riskScore,
          rainAccumulation:rainAccumulation,
          rainfallPerHourTomorrow:rainfallPerHourTomorrow,
          probabilityOfPrecipitation:probabilityOfPrecipitation
        };
}

async function checkWeatherStatus() {
  console.log("check weather status");
  admin
    .firestore()
    .collection("inlets")
    .get()
    .then(function (querySnapshot) {
      querySnapshot.forEach(async function (doc) {
        const inletRef = admin.firestore().collection('inlets').doc(doc.id);

        const baseUrl = 'https://api.weather.gov/points';
        const url = `${baseUrl}/${doc.data().geoLocation.latitude},${doc.data().geoLocation.longitude}`;
        console.log(doc.id);
        
        const response = await fetch(url);
        const weatherData = await response.json();
        const forecastURL = weatherData.properties.forecast;
        const forecastData = await fetch(forecastURL);
        const forecastJSON = await forecastData.json();
        const periods = forecastJSON.properties.periods;
        
        const { today, tomorrow, tenDays } = getWeatherData(periods);
      
        const risk = calculateRainRisk(today, tomorrow, tenDays);

        console.log(risk);
        const res = await inletRef.update({risk: risk });
      })})     
  }

function updateInletStatus(inletId, status = null) {
  admin.firestore().collection("inlets").doc(inletId).update({
    lastChecked: admin.firestore.FieldValue.serverTimestamp(),
    status: status,
  });
}

function createInletCleaningJob(inletId, risk) {
  admin
    .firestore()
    .collection("inletCleaningJobs")
    .add({
      // TODO: figure out how to get a docRef here
      inletId: inletId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "pending",
      risk: risk
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
