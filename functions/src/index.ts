// src/index.ts
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getFirestore } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import { getStorage } from "firebase-admin/storage";

admin.initializeApp();
const db = getFirestore();
const storage = getStorage();

export const mpesaCallback = onRequest(async (req, res) => {
  logger.info("Received M-Pesa Callback", { data: req.body });

  const { Body } = req.body;
  if (!Body || !Body.stkCallback) {
    logger.error("Invalid M-Pesa callback format", { body: req.body });
    res.status(400).send("Invalid request");
    return;
  }

  const { stkCallback } = Body;
  const callbackMetadata = stkCallback.CallbackMetadata?.Item || [];
  const resultCode = stkCallback.ResultCode;
  const resultDesc = stkCallback.ResultDesc;

  let amount = 0;
  let receiptNumber = "";
  let phoneNumber = "";

  callbackMetadata.forEach((item: any) => {
    switch (item.Name) {
      case "Amount":
        amount = item.Value;
        break;
      case "MpesaReceiptNumber":
        receiptNumber = item.Value;
        break;
      case "PhoneNumber":
        phoneNumber = item.Value;
        break;
    }
  });

  if (resultCode === 0) {
    try {
      const paymentRef = await db.collection("payments").add({
        amount,
        receiptNumber,
        phoneNumber,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`Payment saved: ${receiptNumber} - KES ${amount} from ${phoneNumber}`);

      const bucket = storage.bucket();
      const file = bucket.file(`mpesa_callbacks/${paymentRef.id}.json`);
      await file.save(JSON.stringify(req.body, null, 2), {
        contentType: "application/json",
      });

      logger.info(`M-Pesa callback stored in Firebase Storage: ${paymentRef.id}.json`);
    } catch (error) {
      logger.error("Error saving payment: ", error);
      res.status(500).send("Internal Server Error");
      return;
    }
  } else {
    logger.error(`Payment failed: ${resultDesc}`, { resultCode });
  }

  res.status(200).send("Callback received successfully");
});