const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.setAdminRole = functions.https.onCall(async (data, context) => {
  // Validasi autentikasi dan admin
  if (!context.auth || !context.auth.token.isAdmin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can set admin roles",
    );
  }

  // Validasi input data
  if (!data.userId || typeof data.isAdmin !== "boolean") {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "userId and isAdmin (boolean) are required",
    );
  }

  const userId = data.userId;
  const isAdmin = data.isAdmin;

  try {
    // Set custom claims
    await admin.auth().setCustomUserClaims(userId, {isAdmin});

    // Update user document
    await admin.firestore().collection("users").doc(userId).update({
      isAdmin: isAdmin,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {message: `Admin status for user ${userId} set to ${isAdmin}`};
  } catch (error) {
    console.error("Error setting admin role:", error);
    throw new functions.https.HttpsError(
        "internal",
        `Failed to set admin role: ${error.message}`,
    );
  }
});

exports.handleMidtransCallback = functions.https.onRequest(
    async (req, res) => {
      // Validasi method POST
      if (req.method !== "POST") {
        return res.status(405).json({error: "Method not allowed"});
      }

      // Destructuring dengan mapping untuk ESLint compliance
      const {
        order_id: orderId,
        transaction_status: transactionStatus,
        transaction_id: transactionId,
      } = req.body;

      // Validasi data yang diperlukan
      if (!orderId || !transactionStatus) {
        return res.status(400).json({
          error: "Missing required fields: order_id, transaction_status",
        });
      }

      console.log("Processing Midtrans callback:", {
        orderId,
        transactionStatus,
        transactionId,
      });

      try {
        // Tentukan status berdasarkan transaction_status
        let status;
        if (transactionStatus === "capture" ||
            transactionStatus === "settlement") {
          status = "success";
        } else if (transactionStatus === "deny" ||
                   transactionStatus === "cancel" ||
                   transactionStatus === "expire") {
          status = "failed";
        } else {
          status = "pending";
        }

        // Update payment document
        await admin.firestore().collection("payments").doc(orderId).update({
          transactionId: transactionId || "",
          status: status,
          transactionStatus: transactionStatus,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Ambil data payment untuk mendapatkan userId dan orderId
        const paymentDoc = await admin.firestore()
            .collection("payments")
            .doc(orderId)
            .get();

        if (!paymentDoc.exists) {
          console.error("Payment document not found:", orderId);
          return res.status(404).json({error: "Payment not found"});
        }

        const paymentData = paymentDoc.data();
        const {userId, orderId: userOrderId} = paymentData;

        if (!userId || !userOrderId) {
          console.error("Missing userId or orderId in payment data:",
              paymentData);
          return res.status(400).json({
            error: "Invalid payment data: missing userId or orderId",
          });
        }

        // Update status pesanan di koleksi user orders
        await admin.firestore()
            .collection("users")
            .doc(userId)
            .collection("orders")
            .doc(userOrderId)
            .update({
              status: status,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

        console.log("Callback processed successfully:", {
          orderId,
          status,
          userId,
          userOrderId,
        });

        res.status(200).json({
          message: "Callback processed successfully",
          orderId: orderId,
          status: status,
        });
      } catch (error) {
        console.error("Error processing Midtrans callback:", error);
        res.status(500).json({
          error: "Failed to process callback",
          message: error.message,
        });
      }
    },
);
