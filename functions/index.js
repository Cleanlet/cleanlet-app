const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const path = require("path");
const csv = require("csv-parser");
const fs = require("fs-extra");
const os = require("os");
const geofire = require("geofire-common");
const {initializeApp} = require("firebase-admin/app");
const moment = require("moment-timezone");
const { stringify } = require("csv-stringify/sync");
const archiver = require("archiver");
const ObjectsToCsv = require('objects-to-csv');


const app = initializeApp();

// admin.initializeApp();

exports.calculateJobPoints = functions.firestore
    .document("inletCleaningJobs/{jobId}")
    .onUpdate(async (change, context) => {
      const newValue = change.after.data();

      const {
        // startedAt,
        finishedAt,
        inletId,
        status,
        // acceptedLocation,
        acceptedBy,
        createdAt,
      } = newValue;

      if (status === "cleaned") {
        console.log("hello2");
        //  get inlet location

        const inletRef = admin.firestore().collection("inlets").doc(inletId);
        const doc = await inletRef.get();

        if (!doc.exists) {
          console.log("No such document!");
        } else {
          // taskAverageTime is left over from previous discussion for calculating difficulty of cleaning a specific inlet, in the future it can be calculated by the existing jobs in the db. Update in docs
          // let {geoLocation, taskAverageTime} = doc.data();
          // const jobCompletionTime = finishedAt - startedAt;
          // //  console.log(geoLocation);
          // //  taskAverageTime can be null
          // if (!taskAverageTime) {
          //   taskAverageTime = jobCompletionTime;
          // }

          // const distanceFromJob = getDistanceFromLatLonInKm(
          //     acceptedLocation.latitude,
          //     acceptedLocation.longitude,
          //     geoLocation.latitude,
          //     geoLocation.longitude,
          // );

          // const weatherRiskScore = 1;
          const jobId = context.params.jobId;
          // const points =
          // calculatePoints(jobCompletionTime, taskAverageTime, distanceFromJob) +
          // weatherRiskScore;
          const points = caluclatePointsV2(finishedAt, createdAt);

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

/**
 * [getDistanceFromLatLonInKm description]
 *
 * @param   {[type]}  lat1  [lat1 description]
 * @param   {[type]}  lon1  [lon1 description]
 * @param   {[type]}  lat2  [lat2 description]
 * @param   {[type]}  lon2  [lon2 description]
 *
 * @return  {[type]}        [return description]
 */
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

/**
 * [deg2rad description]
 *
 * @param   {[type]}  deg  [deg description]
 *
 * @return  {[type]}       [return description]
 */
function deg2rad(deg) {
  return deg * (Math.PI / 180);
}

/**
 * [calculatePoints description]
 *
 * @param   {[type]}  jobCompletionTime  [jobCompletionTime description]
 * @param   {[type]}  taskAverageTime    [taskAverageTime description]
 * @param   {[type]}  distanceFromJob    [distanceFromJob description]
 *
 * @return  {[type]}                     [return description]
 */
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

/**
 * [caluclatePointsV2 description]
 *
 * @param   {[type]}  jobCompletionTime  [jobCompletionTime description]
 * @param   {[type]}  jobCreationTime    [jobCreationTime description]
 *
 * @return  {[type]}                     [return description]
 */
function caluclatePointsV2(jobCompletionTime, jobCreationTime) {
  const createdAtDate = jobCreationTime.toDate();
  const finishedAtDate = jobCompletionTime.toDate();
  const timeDifference = finishedAtDate.getTime() - createdAtDate.getTime();

  if (timeDifference <= 24 * 60 * 60 * 1000) {
    return 2;
  }
  else {
    return 1;
  }
}

exports.inletStatusUpdated = functions.firestore
    .document("inlets/{inletId}")
    .onUpdate(async (change, context) => {
      const newValue = change.after.data();
      const oldValue = change.before.data();

      const lastNotificationAndCleaningJobCreated = newValue.lastNotificationAndCleaningJobCreated;
      const now = admin.firestore.Timestamp.now();

      // If lastNotificationAndCleaningJobCreated does not exist or if 48 hours have passed since its value
      if (!lastNotificationAndCleaningJobCreated || now.toDate().getTime() - lastNotificationAndCleaningJobCreated.toDate().getTime() >= 48 * 60 * 60 * 1000) {
      // Check if risk value has changed
        if (oldValue.risk !== newValue.risk && newValue.risk > 35) {
          console.log("Risk value has changed from the old one and is greater than 35");
        // Create cleaning job
          createInletCleaningJob(context.params.inletId, newValue.risk);

          if (newValue.subscribed) {
            newValue.subscribed.forEach((subscriber) => {
              console.log(`Sending push notification to: ${subscriber}`);
            });
          }

          let tokens = [];
          for (const userId of newValue.subscribed) {
            const user = await admin.firestore().collection("users").doc(userId).get();
            if (user.exists) {
              const userTokens = user.data().tokens;
              if (Array.isArray(userTokens)) {
                console.log(`Adding ${userId} tokens to token array`);
                tokens = [...tokens, ...userTokens];
              } else {
                console.log(`User ${userId}'s tokens are not an array (may be null or some other type).`);
              }
            } else {
              console.log(`User ${userId} does not exist.`);
            }
          }

          console.log("FCM Tokens: ", tokens);

          const payload = {
            notification: {
              title: "Inlet Cleaning Needed",
              body: "An Inlet you volunteered for needs cleaning",
            },
          };

          if (tokens.length > 0) {
            console.log("Sending push notifications...");
            
            let messageResponse = await admin.messaging().sendToDevice(tokens, payload);
            console.log("Response from Cloud Messaging:");
            messageResponse.results.forEach((res) => {
              if (res.error) {
                console.log(res.error.message);
              }
              else {
                console.log("Message sent successfully");
              }
            });
            console.log("Push notifications sent");
          } else {
            console.log("Tokens array is empty. No notifications will be sent.");
          }

          // Update lastNotificationAndCleaningJobCreated in inlet document
          const inletRef = admin.firestore().collection("inlets").doc(context.params.inletId);
          
          await inletRef.update({lastNotificationAndCleaningJobCreated: now});

          console.log("Updated Inlet with the lastNotificationAndCleaningJobCreated");
        }
      } else {
        console.log("Less than 48 hours have passed since the last run. Doing nothing.");
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

exports.testPushNotifications = functions.https.onRequest(async (req, res) => {
  const userId = req.query.user;
  const user = await admin.firestore().collection("users").doc(userId).get();
  
  console.log(`Testing push notification for user id: ${userId}`);

  const tokens = user.data().tokens;

  const payload = {
    notification: {
      title: "Cleanlet Test",
      body: "If you are receiving this message, it is a test.",
    },
  };

  if (tokens.length > 0) {
    console.log("User has push tokens");
    let messageResponse = await admin.messaging().sendToDevice(tokens, payload);

    messageResponse.results.forEach((res) => {
      if (res.error) {
        console.log(res.error.message);
      }
    });

    // console.log("Response from Cloud Messaging:");
    // console.log(messageResponse);
    console.log("Test Push Notification Sent");
  } else {
    console.log("Tokens array is empty. No notifications will be sent.");
  }

  res.status(200).send("Test Complete");
});


exports.exportCSVData = functions.https.onRequest(async (req, res) => {
  const db = admin.firestore();

  try {
    const archive = archiver("zip");

    res.setHeader("Content-Type", "application/zip");
    res.setHeader("Content-Disposition", "attachment; filename=cleanlet-data.zip");

    archive.pipe(res);

    const inletSnapshots = await db.collection("inlets").get();
    const inletData = [];

    if (!inletSnapshots.empty) {
      inletSnapshots.forEach((doc) => {
        const data = doc.data();
        inletData.push({
          id: doc.id,
          nickName: data.nickName,
          risk: data.risk,
          latitude: data.geoLocation.latitude,
          longitude: data.geoLocation.longitude,
          status: data.status,
          createdAt: data.createdAt ? data.createdAt.toDate()
              .toLocaleDateString("en-US", {
                month: "short",
                day: "numeric",
                year: "numeric",
                hour: "numeric",
                minute: "numeric",
                hour12: true,
              }) : "",
        });
      });

      const inletCSV = new ObjectsToCsv(inletData);
      archive.append(await inletCSV.toString(), {name: "inlets.csv"});
    }

    const inletCleaningJobSnapshots = await db.collection("inletCleaningJobs").get();
    const inletCleaningJobData = [];

    if (!inletCleaningJobSnapshots.empty) {
      inletCleaningJobSnapshots.forEach((doc) => {
        const data = doc.data();
        inletCleaningJobData.push({
          id: doc.id,
          inletId: data.inletId,
          risk: data.risk,
          points: data.points ? data.points : 0,
          status: data.status,
          createdAt: data.createdAt ? data.createdAt.toDate()
              .toLocaleDateString("en-US", {
                month: "short",
                day: "numeric",
                year: "numeric",
                hour: "numeric",
                minute: "numeric",
                hour12: true,
              }) : "",
        });
      });

      const jobsCSV = new ObjectsToCsv(inletCleaningJobData);
      archive.append(await jobsCSV.toString(), {name: "inletCleaningJobs.csv"});
    }

    const userSnapshots = await db.collection("users").get();
    const usersData = [];

    if (!userSnapshots.empty) {
      for (const doc of userSnapshots.docs) {
        const data = doc.data();
        const inlets = [];
        let subscribed = "";

        const inletsWatchedSnapshot = await db.collection("inlets").where('subscribed','array-contains', doc.id).get();

        if (!inletsWatchedSnapshot.empty) {
          inletsWatchedSnapshot.forEach((doc) => {
            inlets.push(doc.id);
          });

          subscribed = inlets.join("|");
        }

        usersData.push({
          id: doc.id,
          displayName: data.displayName,
          email: data.email,
          points: data.points,
          inlets: subscribed,
          createdAt: data.createdAt ? data.createdAt.toDate()
              .toLocaleDateString("en-US", {
                month: "short",
                day: "numeric",
                year: "numeric",
                hour: "numeric",
                minute: "numeric",
                hour12: true,
              }) : "",
        });
      }

      const usersDataCSV = new ObjectsToCsv(usersData);
      archive.append(await usersDataCSV.toString(), {name: "users.csv"});
    }

    archive.finalize();

    // res.status(200).send({
    //   inlets: inletData,
    //   jobs: inletCleaningJobData,
    // });
  } catch (error) {
    console.error("Error fetching data or generating CSV", error);
    res.status(500).send("Internal Server Error");
  }
});

// function getWeatherData(periods) {
//   const today = periods[0];
//   const tomorrow = periods[1];
//   const tenDays = periods.slice(0, 10);

//   return {today, tomorrow, tenDays};
// }

// function calculateRainRisk(today, tomorrow, tenDays) {
//   // Calculate the rain accumulation for the next 10 days
//   const rainAccumulation = tenDays.reduce((total, day) => {
//     const {qpf = 0} = day;
//     return total + qpf;
//   }, 0);

//   // Calculate the rainfall per hour for tomorrow
//   const {detailedForecast} = tomorrow;
//   const rainfallPerHourTomorrow = detailedForecast.match(
//       /(\d+(?:\.\d+)?).+rain/,
//   );

//   // Calculate the probability of precipitation for the next 10 days
//   const probabilityOfPrecipitation =
//     tenDays.reduce((total, day) => {
//       const {pop = 0} = day;
//       return total + pop;
//     }, 0) / 10;

//   //  dry event
//   //  add;

//   // Calculate the risk score based on the rain accumulation,
//   // rainfall per hour, and probability of precipitation
//   const riskScore =
//     rainAccumulation * 2 +
//     rainfallPerHourTomorrow * 10 +
//     probabilityOfPrecipitation * 5;
//   return {
//     score: riskScore,
//     rainAccumulation: rainAccumulation,
//     rainfallPerHourTomorrow: rainfallPerHourTomorrow,
//     probabilityOfPrecipitation: probabilityOfPrecipitation,
//   };
// }

/**
 * [async description]
 *
 * @return  {[type]}  [return description]
 */
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
          console.log(`Checking weather status for: ${doc.id}`);

          // const response = await fetch(url);
          // const weatherData = await response.json();
          // const forecastURL = weatherData.properties.forecast;
          // const forecastData = await fetch(forecastURL);
          // const forecastJSON = await forecastData.json();
          // const periods = forecastJSON.properties.periods;

          const query = await fetch(url);
          const getwd = await query.json();
          const urlo = getwd.id;
          const query2 = await fetch(urlo);
          const getwd2 = await query2.json();
          const forecastURL = getwd2.properties.forecast;
          const forecastData = await fetch(forecastURL);
          const forecastJSON = await forecastData.json();
          const periods = forecastJSON.properties.periods;
          const nextPeriod = periods[0];
          const risk = nextPeriod.probabilityOfPrecipitation;
          console.log(`${doc.id} has a risk score of: ${risk.value}`);

          // console.log(JSON.stringify(getwd2.properties))
          // const risk_r = getwd2.properties.probabilityOfPrecipitation.values;
          // const risk = risk_r[0].value;

          // const {today, tomorrow, tenDays} = getWeatherData(periods);

          //  const risk = calculateRainRisk(today, tomorrow, tenDays);

          // console.log(risk);
          console.log(`Updating ${doc.id} risk score to ${risk.value}`);
          await inletRef.update({risk: risk.value});
        });
      });
}

// eslint-disable-next-line no-unused-vars
// function updateInletStatus(inletId, status = null) {
//   admin.firestore().collection("inlets").doc(inletId).update({
//     lastChecked: admin.firestore.FieldValue.serverTimestamp(),
//     status: status,
//   });
// }

/**
 * [createInletCleaningJob description]
 *
 * @param   {[type]}  inletId  [inletId description]
 * @param   {[type]}  risk     [risk description]
 *
 */
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
