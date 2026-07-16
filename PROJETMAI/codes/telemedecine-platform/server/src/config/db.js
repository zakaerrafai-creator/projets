const mongoose = require("mongoose");

async function connectDb() {
  const uri = process.env.MONGO_URI;

  if (!uri) {
    throw new Error("MONGO_URI manquant dans les variables d'environnement");
  }

  await mongoose.connect(uri);
  console.log("MongoDB connecte");
}

module.exports = connectDb;
