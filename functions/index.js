/* eslint-disable require-jsdoc */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const path = require("path");
const csv = require("csv-parser");
const fs = require("fs-extra");
const os = require("os");
const geofire = require("geofire-common");

admin.initializeApp();

exports.calculateJobPoints = functions.firestore
    .document("inletCleaningJobs/{jobId}")
    .onUpdate(async (change, context) => {
      const newValue = change.after.data();

      const {
        startedAt,
        finishedAt,
        inletId,
        status,
        acceptedLocation,
        acceptedBy,
      } = newValue;

      if (status === "cleaned") {
        console.log("hello2");
        //  get inlet location

        const inletRef = admin.firestore().collection("inlets").doc(inletId);
        const doc = await inletRef.get();
        if (!doc.exists) {
          console.log("No such document!");
        } else {
          let {geoLocation, taskAverageTime} = doc.data();
          const jobCompletionTime = finishedAt - startedAt;
          //  console.log(geoLocation);
          //  taskAverageTime can be null
          if (!taskAverageTime) {
            taskAverageTime = jobCompletionTime;
          }

          const distanceFromJob = getDistanceFromLatLonInKm(
              acceptedLocation.latitude,
              acceptedLocation.longitude,
              geoLocation.latitude,
              geoLocation.longitude,
          );

          const weatherRiskScore = 1;
          const jobId = context.params.jobId;
          const points =
          calculatePoints(jobCompletionTime, taskAverageTime, distanceFromJob) +
          weatherRiskScore;

          const jobRef = admin
              .firestore()
              .collection("inletCleaningJobs")
              .doc(jobId);
          const usrRef = admin.firestore().collection("users").doc(acceptedBy);
          const batch = admin.firestore().batch();
          batch.update(jobRef, {points: points, status: "finalized"});
          batch.update(usrRef, {
            points: admin.firestore.FieldValue.increment(points),
          });
          await batch.commit();
        }
      }
    });

exports.createUserDoc = functions.auth.user().onCreate((user) => {
  const {uid, email, displayName, photoURL} = user;
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
    },
);

function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of the earth in km
  const dLat = deg2rad(lat2 - lat1); // deg2rad below
  const dLon = deg2rad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(lat1)) *
      Math.cos(deg2rad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const d = R * c; // Distance in km
  return d;
}

function deg2rad(deg) {
  return deg * (Math.PI / 180);
}

function calculatePoints(jobCompletionTime, taskAverageTime, distanceFromJob) {
  const pointsPerSecond = 10; // set the base points per second
  const timeDifference = taskAverageTime - jobCompletionTime;
  const speedFactor = Math.max(timeDifference / taskAverageTime, 0);
  const bonusPoints = Math.floor(
      speedFactor * pointsPerSecond * jobCompletionTime,
  );
  const sigmoidInput = distanceFromJob / 1000; // assuming distance is in meters
  const sigmoidOutput = 1 / (1 + Math.exp(-sigmoidInput + 5));
  const distancePoints = Math.floor(
      sigmoidOutput * pointsPerSecond * jobCompletionTime,
  );
  const totalPoints = Math.floor(
      jobCompletionTime * pointsPerSecond + bonusPoints + distancePoints,
  );
  return totalPoints;
}

exports.inletStatusUpdated = functions.firestore
    .document("inlets/{inletId}")
    .onUpdate(async (change, context) => {
      const newValue = change.after.data();
      const status = newValue.status;

      if (status === "cleaningNeeded") {
        createInletCleaningJob(context.params.inletId, newValue.risk);
      //  sendPushNotifications(watching);
      }
    });

exports.checkUploadedImage = functions.storage
    .object()
    .onFinalize(async (object) => {
      const fileBucket = object.bucket;

      const filePath = object.name; // File path in the bucket.
      const fileDir = path.dirname(filePath);
      const contentType = object.contentType; // File content type.
      console.log(contentType);
      if (
        fileDir == "inlet-uploads" &&
      (contentType == "application/vnd.ms-excel" || contentType == "text/csv")
      ) {
        const results = [];
        const bucket = admin.storage().bucket(fileBucket);
        const tempFilePath = path.join(os.tmpdir(), object.name);
        await fs.ensureDir(path.dirname(tempFilePath));
        await bucket.file(filePath).download({destination: tempFilePath});
        functions.logger.log("Image downloaded locally to", tempFilePath);
        fs.createReadStream(tempFilePath)
            .pipe(
                csv({
                  mapHeaders: ({header, index}) => {
                    if (index == 2) {
                      return "address";
                    } else if (index == 3) {
                      return "description";
                    } else if (index == 4) {
                      return "images";
                    } else if (index == 5) {
                      return "instructions";
                    } else {
                      return header.toLowerCase();
                    }
                  },
                }),
            )
            .on("data", (data) => results.push(data))
            .on("end", () => {
              results.forEach(async (result) => {
                const inlet = {};
                const hash = geofire.geohashForLocation([
                  parseFloat(result.latitude),
                  parseFloat(result.longitude),
                ]);
                inlet["geoHash"] = hash;
                inlet["geoLocation"] = new admin.firestore.GeoPoint(
                    parseFloat(result.latitude),
                    parseFloat(result.longitude),
                );
                inlet["address"] = result.address;
                inlet["description"] = result.description;
                inlet["images"] = result.images;
                inlet["instructions"] = result.instructions;
                admin
                    .firestore()
                    .collection("inlets")
                    .doc(hash)
                    .set(inlet, {merge: true})
                    .then((docRef) => {
                      console.log("Document written with ID: ", docRef.id);
                    });
              });
            });
      } else {
        console.log("Wrong folder or weird file");
        return null;
      }
    });

function getWeatherData(periods) {
  const today = periods[0];
  const tomorrow = periods[1];
  const tenDays = periods.slice(0, 10);

  return {today, tomorrow, tenDays};
}

function calculateRainRisk(today, tomorrow, tenDays) {
  // Calculate the rain accumulation for the next 10 days
  const rainAccumulation = tenDays.reduce((total, day) => {
    const {qpf = 0} = day;
    return total + qpf;
  }, 0);

  // Calculate the rainfall per hour for tomorrow
  const {detailedForecast} = tomorrow;
  const rainfallPerHourTomorrow = detailedForecast.match(
      /(\d+(?:\.\d+)?).+rain/,
  );

  // Calculate the probability of precipitation for the next 10 days
  const probabilityOfPrecipitation =
    tenDays.reduce((total, day) => {
      const {pop = 0} = day;
      return total + pop;
    }, 0) / 10;

  //  dry event
  //  add;

  // Calculate the risk score based on the rain accumulation,
  // rainfall per hour, and probability of precipitation
  const riskScore =
    rainAccumulation * 2 +
    rainfallPerHourTomorrow * 10 +
    probabilityOfPrecipitation * 5;
  return {
    score: riskScore,
    rainAccumulation: rainAccumulation,
    rainfallPerHourTomorrow: rainfallPerHourTomorrow,
    probabilityOfPrecipitation: probabilityOfPrecipitation,
  };
}

async function checkWeatherStatus() {
  console.log("check weather status");
  admin
      .firestore()
      .collection("inlets")
      .get()
      .then(function(querySnapshot) {
        querySnapshot.forEach(async function(doc) {
          const inletRef = admin.firestore().collection("inlets").doc(doc.id);

          const baseUrl = "https://api.weather.gov/points";
          const url = `${baseUrl}/${doc.data().geoLocation.latitude},${
            doc.data().geoLocation.longitude
          }`;
          console.log(doc.id);

          const response = await fetch(url);
          const weatherData = await response.json();
          const forecastURL = weatherData.properties.forecast;
          const forecastData = await fetch(forecastURL);
          const forecastJSON = await forecastData.json();
          const periods = forecastJSON.properties.periods;

          const {today, tomorrow, tenDays} = getWeatherData(periods);

          const risk = calculateRainRisk(today, tomorrow, tenDays);

          console.log(risk);
          await inletRef.update({risk: risk});
        });
      });
}

// eslint-disable-next-line no-unused-vars
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
        risk: risk,
      })
      .then((docRef) => {
        admin.firestore().collection("inlets").doc(inletId).update({
          jobId: docRef.id,
          status: "cleaningScheduled",
        });
      });
}


// eslint-disable-next-line no-unused-vars
// async function sendPushNotifications(watchingUsesrIds) {
//   const fcmTokens = [];
//   const payload = {
//     notification: {
//       title: "Inlet needs cleaning",
//       body: "The inlet near you needs cleaning",
//       icon: "https://placekitten.com/200/200",
//     },
//   };
//   await watchingUsesrIds.forEach((userId) => {
//     admin
//         .firestore()
//         .collection("users")
//         .doc(userId)
//         .get()
//         .then((doc) => {
//           if (doc.exists) {
//           // Todo: add fcmToken to fcmTokens array
//             console.log(doc.data());
//           }
//         });
//   });
//   if (fcmTokens.length > 0) {
//     admin.messaging().sendToDevice(fcmTokens, payload);
//   }
// }
