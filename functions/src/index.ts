import {setGlobalOptions} from "firebase-functions";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {onValueWritten} from "firebase-functions/v2/database";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getAuth} from "firebase-admin/auth";
import {Buffer} from "node:buffer";

// Configuración global para controlar costos y concurrencia.
setGlobalOptions({maxInstances: 10});

initializeApp();

const db = getFirestore();
const auth = getAuth();

/**
 * Retorna string con trim cuando el valor es texto; si no, retorna vacío.
 * @param {unknown} value Valor de entrada.
 * @return {string} Texto normalizado.
 */
function pickString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

/**
 * Convierte un valor desconocido a número decimal.
 * @param {unknown} value Valor a convertir.
 * @return {number | null} Número válido o null.
 */
function pickNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === "string") {
    const parsed = Number.parseFloat(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }

  return null;
}

/**
 * Convierte un timestamp unix en milisegundos a Date válido.
 * @param {unknown} value Valor crudo.
 * @return {Date | null} Fecha válida o null.
 */
function pickDateFromMillis(value: unknown): Date | null {
  const millis = pickNumber(value);
  if (millis === null) {
    return null;
  }

  const date = new Date(millis);
  return Number.isNaN(date.getTime()) ? null : date;
}

/**
 * Normaliza estado de usuario y determina si está suspendido.
 * @param {unknown} value Estado crudo.
 * @return {boolean} True cuando representa "Suspendido/Suspended".
 */
function isSuspendedStatus(value: unknown): boolean {
  const normalized = pickString(value).toLowerCase();
  return normalized === "suspendido" || normalized === "suspended";
}

/**
 * Crea un documento de notificación para un usuario destino.
 * @param {Object} params Datos de la notificación.
 * @return {Promise<string>} Id de la notificación creada.
 */
async function createNotification(params: {
  targetUid: string;
  type: string;
  title: string;
  body: string;
  actorUid?: string;
  exchangeId: string;
  postId?: string;
  postTitle?: string;
  status?: string;
  actorName?: string;
  requestedByMe?: boolean;
}) {
  const notificationRef = db.collection("users")
    .doc(params.targetUid)
    .collection("notifications")
    .doc();

  await notificationRef.set({
    type: params.type,
    title: params.title,
    body: params.body,
    createdAt: FieldValue.serverTimestamp(),
    read: false,
    readAt: null,
    actorUid: params.actorUid || null,
    data: {
      exchangeId: params.exchangeId,
      postId: params.postId || null,
      postTitle: params.postTitle || null,
      status: params.status || null,
      actorName: params.actorName || null,
      requestedByMe: params.requestedByMe === true,
    },
  });

  return notificationRef.id;
}

export const onExchangeCreatedNotifyTarget = onDocumentCreated(
  "exchanges/{exchangeId}",
  async (event) => {
    const exchangeId = event.params.exchangeId;
    const data = event.data?.data();

    if (!data) {
      logger.warn("Intercambio creado sin payload", {exchangeId});
      return;
    }

    const targetUid =
      pickString(data["targetUid"]) ||
      pickString(data["ownerUid"]) ||
      pickString(data["sellerUid"]);
    const actorUid =
      pickString(data["requesterUid"]) ||
      pickString(data["actorUid"]) ||
      pickString(data["buyerUid"]);
    const actorName = pickString(data["requesterName"]) || "Un usuario";
    const ownerName = pickString(data["ownerName"]) || "El propietario";
    const postId = pickString(data["postId"]);
    const postTitle = pickString(data["postTitle"]) || pickString(data["title"]);
    const status = pickString(data["status"]) || "requested";

    if (!targetUid) {
      logger.warn("Intercambio sin uid de usuario destino", {exchangeId, data});
      return;
    }

    if (actorUid && actorUid === targetUid) {
      logger.info(
        "Se omite notificación a sí mismo para intercambio",
        {exchangeId, targetUid},
      );
      return;
    }

    const notificationId = await createNotification({
      targetUid,
      type: "exchange_requested",
      title: "Nueva solicitud",
      body: `${actorName} quiere intercambiar por "${postTitle || "material"}"`,
      actorUid,
      exchangeId,
      postId,
      postTitle,
      status,
      actorName,
      requestedByMe: false,
    });

    let requesterNotificationId: string | undefined;
    if (actorUid && actorUid !== targetUid) {
      requesterNotificationId = await createNotification({
        targetUid: actorUid,
        type: "exchange_requested",
        title: "Solicitud enviada",
        body: `Tu solicitud para "${postTitle || "material"}" fue enviada`,
        actorUid: targetUid,
        exchangeId,
        postId,
        postTitle,
        status,
        actorName: ownerName,
        requestedByMe: true,
      });
    }

    logger.info("Notificación de intercambio creada", {
      exchangeId,
      targetUid,
      notificationId,
      requesterNotificationId,
    });
  },
);

export const onExchangeUpdatedNotifyParticipants = onDocumentUpdated(
  "exchanges/{exchangeId}",
  async (event) => {
    const exchangeId = event.params.exchangeId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) {
      logger.warn(
        "Actualización de intercambio sin before/after",
        {exchangeId},
      );
      return;
    }

    const previousStatus = pickString(before["status"]).toLowerCase();
    const currentStatus = pickString(after["status"]).toLowerCase();

    if (!currentStatus || previousStatus === currentStatus) {
      return;
    }

    const ownerUid =
      pickString(after["targetUid"]) ||
      pickString(after["ownerUid"]) ||
      pickString(after["sellerUid"]);
    const requesterUid =
      pickString(after["requesterUid"]) ||
      pickString(after["actorUid"]) ||
      pickString(after["buyerUid"]);
    const requesterName = pickString(after["requesterName"]) || "Un usuario";
    const ownerName = pickString(after["ownerName"]) || "El usuario";
    const postId = pickString(after["postId"]);
    const postTitle = pickString(after["postTitle"]) || pickString(after["title"]);
    const actorUidFromDoc = pickString(after["updatedBy"]);
    const actorUid = actorUidFromDoc.length > 0
      ? actorUidFromDoc
      : currentStatus === "declined"
        ? requesterUid
        : ownerUid;

    if (!ownerUid || !requesterUid) {
      logger.warn("No se pudo resolver owner/requester en actualización", {
        exchangeId,
        ownerUid,
        requesterUid,
        currentStatus,
      });
      return;
    }

    if (currentStatus === "accepted") {
      if (requesterUid === actorUid) {
        logger.info("Se omite auto-notificación de accepted", {
          exchangeId,
          requesterUid,
          actorUid,
        });
        return;
      }
      const notificationId = await createNotification({
        targetUid: requesterUid,
        type: "exchange_accepted",
        title: "Solicitud aceptada",
        body: `${ownerName} aceptó tu solicitud para "${postTitle || "material"}"`,
        actorUid: ownerUid,
        exchangeId,
        postId,
        postTitle,
        status: currentStatus,
        actorName: ownerName,
      });
      logger.info("Notificación de intercambio aceptado creada", {
        exchangeId,
        targetUid: requesterUid,
        notificationId,
      });
      return;
    }

    if (currentStatus === "rejected") {
      if (requesterUid === actorUid) {
        logger.info("Se omite auto-notificación de rejected", {
          exchangeId,
          requesterUid,
          actorUid,
        });
        return;
      }
      const notificationId = await createNotification({
        targetUid: requesterUid,
        type: "exchange_rejected",
        title: "Solicitud rechazada",
        body: `${ownerName} rechazó tu solicitud para "${postTitle || "material"}"`,
        actorUid: ownerUid,
        exchangeId,
        postId,
        postTitle,
        status: currentStatus,
        actorName: ownerName,
      });
      logger.info("Notificación de intercambio rechazado creada", {
        exchangeId,
        targetUid: requesterUid,
        notificationId,
      });
      return;
    }

    if (currentStatus === "declined") {
      if (ownerUid === actorUid) {
        logger.info("Se omite auto-notificación de declined", {
          exchangeId,
          ownerUid,
          actorUid,
        });
        return;
      }
      const notificationId = await createNotification({
        targetUid: ownerUid,
        type: "exchange_cancelled",
        title: "Solicitud cancelada",
        body: `${requesterName} canceló la solicitud para "${postTitle || "material"}"`,
        actorUid: requesterUid,
        exchangeId,
        postId,
        postTitle,
        status: currentStatus,
        actorName: requesterName,
      });
      logger.info("Notificación de solicitud cancelada creada", {
        exchangeId,
        targetUid: ownerUid,
        notificationId,
      });
      return;
    }

    if (currentStatus === "completed") {
      let ownerNotificationId: string | undefined;
      if (ownerUid != actorUid) {
        ownerNotificationId = await createNotification({
          targetUid: ownerUid,
          type: "exchange_completed",
          title: "Intercambio completado",
          body:
              `Intercambio de "${postTitle || "material"}" completado con ${requesterName}`,
          actorUid: requesterUid,
          exchangeId,
          postId,
          postTitle,
          status: currentStatus,
          actorName: requesterName,
        });
      }
      let requesterNotificationId: string | undefined;
      if (requesterUid != actorUid) {
        requesterNotificationId = await createNotification({
          targetUid: requesterUid,
          type: "exchange_completed",
          title: "Intercambio completado",
          body:
              `Intercambio de "${postTitle || "material"}" completado con ${ownerName}`,
          actorUid: ownerUid,
          exchangeId,
          postId,
          postTitle,
          status: currentStatus,
          actorName: ownerName,
        });
      }
      logger.info("Notificaciones de intercambio completado creadas", {
        exchangeId,
        ownerUid,
        requesterUid,
        ownerNotificationId,
        requesterNotificationId,
      });
    }
  },
);

export const onUserPresenceChangedSyncFirestore = onValueWritten(
  "/status/{uid}",
  async (event) => {
    const uid = pickString(event.params.uid);

    if (!uid) {
      logger.warn("Cambio de presencia sin uid", {params: event.params});
      return;
    }

    const after = event.data.after.val() as Record<string, unknown> | null;

    if (!after) {
      await db.collection("users").doc(uid).set({
        isOnline: false,
        lastSeen: FieldValue.serverTimestamp(),
      }, {merge: true});

      logger.info("Presencia eliminada, usuario marcado offline", {uid});
      return;
    }

    const state = pickString(after["state"]).toLowerCase();
    const lastChanged = pickDateFromMillis(after["lastChanged"]);

    await db.collection("users").doc(uid).set({
      isOnline: state === "online",
      lastSeen: lastChanged ?? FieldValue.serverTimestamp(),
    }, {merge: true});

    logger.info("Presencia sincronizada a Firestore", {
      uid,
      state,
      lastChanged: lastChanged?.toISOString() ?? null,
    });
  },
);

export const createExchangePayment = onCall(async (request) => {
  const auth = request.auth;
  const uid = auth?.uid || "";
  const exchangeId = pickString(request.data?.exchangeId);

  if (!uid) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión para pagar.");
  }

  if (!exchangeId) {
    throw new HttpsError("invalid-argument", "exchangeId es obligatorio.");
  }

  const exchangeRef = db.collection("exchanges").doc(exchangeId);
  const exchangeSnapshot = await exchangeRef.get();
  if (!exchangeSnapshot.exists) {
    throw new HttpsError("not-found", "El intercambio no existe.");
  }

  const exchangeData = exchangeSnapshot.data() || {};
  const requesterUid =
    pickString(exchangeData["requesterUid"]) ||
    pickString(exchangeData["actorUid"]) ||
    pickString(exchangeData["buyerUid"]);
  const ownerUid =
    pickString(exchangeData["targetUid"]) ||
    pickString(exchangeData["ownerUid"]) ||
    pickString(exchangeData["sellerUid"]);
  const method = pickString(exchangeData["method"]).toLowerCase();
  const postId = pickString(exchangeData["postId"]);
  const exchangeStatus = pickString(exchangeData["status"]).toLowerCase();

  if (uid !== requesterUid && uid !== ownerUid) {
    throw new HttpsError(
      "permission-denied",
      "Solo los participantes pueden iniciar el pago.",
    );
  }

  if (!postId) {
    throw new HttpsError(
      "failed-precondition",
      "El intercambio no tiene una publicación asociada.",
    );
  }

  if (exchangeStatus !== "accepted") {
    throw new HttpsError(
      "failed-precondition",
      "El intercambio debe estar aceptado para iniciar el pago.",
    );
  }

  const postSnapshot = await db.collection("posts").doc(postId).get();
  if (!postSnapshot.exists) {
    throw new HttpsError(
      "not-found",
      "La publicación asociada al intercambio no existe.",
    );
  }

  const postData = postSnapshot.data() || {};
  const postMethod = pickString(postData["method"]).toLowerCase();
  const amount = pickNumber(postData["priceUsd"]);

  if (method !== "venta" && postMethod !== "venta") {
    throw new HttpsError(
      "failed-precondition",
      "Este intercambio no requiere pago.",
    );
  }

  if (amount === null || amount <= 0) {
    throw new HttpsError(
      "failed-precondition",
      "La publicación no tiene un monto de pago válido.",
    );
  }

  const paymentRef = db.collection("exchangePayments").doc();
  await paymentRef.set({
    id: paymentRef.id,
    exchangeId,
    postId,
    payerUid: uid,
    payeeUid: ownerUid,
    amount,
    currency: "USD",
    status: "pending",
    provider: "firebase_functions",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  await exchangeRef.set({
    paymentStatus: "pending",
    paymentId: paymentRef.id,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  logger.info("Pago de intercambio iniciado", {
    exchangeId,
    paymentId: paymentRef.id,
    payerUid: uid,
    amount,
  });

  return {
    paymentId: paymentRef.id,
    exchangeId,
    amount,
    currency: "USD",
    status: "pending",
  };
});

export const onUserSuspensionStatusChangedSyncAuth = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    const userId = event.params.userId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!after) {
      return;
    }

    const beforeSuspended = isSuspendedStatus(before?.["status"]);
    const afterSuspended = isSuspendedStatus(after["status"]);

    if (beforeSuspended === afterSuspended) {
      return;
    }

    try {
      await auth.updateUser(userId, {disabled: afterSuspended});
      if (afterSuspended) {
        await auth.revokeRefreshTokens(userId);
      }
      logger.info("Sincronizado estado de suspensión hacia Firebase Auth", {
        userId,
        disabled: afterSuspended,
      });
    } catch (error) {
      logger.error("No se pudo sincronizar suspensión en Firebase Auth", {
        userId,
        disabled: afterSuspended,
        error,
      });
      throw error;
    }
  },
);

const PAYPAL_BASE_URL = "https://api-m.sandbox.paypal.com"; // Cambiar a live en producción

async function getPayPalAccessToken(): Promise<string> {
  const paypalClientId = process.env.PAYPAL_CLIENT_ID || "";
  const paypalClientSecret = process.env.PAYPAL_CLIENT_SECRET || "";

  if (!paypalClientId || !paypalClientSecret) {
    throw new HttpsError(
      "failed-precondition",
      "Las credenciales de PayPal no estan configuradas.",
    );
  }

  const auth = Buffer.from(`${paypalClientId}:${paypalClientSecret}`).toString("base64");

  const response = await fetch(`${PAYPAL_BASE_URL}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });

  const data = await response.json();
  return data.access_token;
}

export const createPayPalOrder = onCall({
  secrets: ["PAYPAL_CLIENT_ID", "PAYPAL_CLIENT_SECRET"],
}, async (request) => {
  const amount = pickNumber(request.data?.amount);
  const returnUrl = pickString(request.data?.returnUrl);
  const cancelUrl = pickString(request.data?.cancelUrl);

  if (!amount || amount <= 0) {
    throw new HttpsError("invalid-argument", "Monto inválido.");
  }

  if (!returnUrl || !cancelUrl) {
    throw new HttpsError("invalid-argument", "returnUrl y cancelUrl son obligatorios.");
  }

  const accessToken = await getPayPalAccessToken();

  const response = await fetch(`${PAYPAL_BASE_URL}/v2/checkout/orders`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      intent: "CAPTURE",
      purchase_units: [
        {
          amount: {
            currency_code: "USD",
            value: amount.toString(),
          },
        },
      ],
      application_context: {
        return_url: returnUrl,
        cancel_url: cancelUrl,
        user_action: "PAY_NOW",
      },
    }),
  });

  const data = await response.json();

  logger.info("PayPal order created", data);

  return data;
});

export const capturePayPalOrder = onCall({
  secrets: ["PAYPAL_CLIENT_ID", "PAYPAL_CLIENT_SECRET"],
}, async (request) => {
  const auth = request.auth;
  const uid = auth?.uid || "";
  const orderId = pickString(request.data?.orderId);
  const exchangeId = pickString(request.data?.exchangeId);

  if (!orderId) {
    throw new HttpsError("invalid-argument", "orderId es obligatorio.");
  }

  const accessToken = await getPayPalAccessToken();

  const response = await fetch(`${PAYPAL_BASE_URL}/v2/checkout/orders/${orderId}/capture`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
  });

  const data = await response.json();

  logger.info("PayPal order captured", data);

  if (data.status === "COMPLETED") {
    const amountValue = data.purchase_units?.[0]?.payments?.captures?.[0]?.amount?.value || null;
    await db.collection("paypalPayments").doc(orderId).set({
      orderId,
      status: "completed",
      amount: amountValue,
      currency: "USD",
      createdAt: FieldValue.serverTimestamp(),
    });

    if (exchangeId) {
      const exchangeSnapshot = await db.collection("exchanges").doc(exchangeId).get();
      const exchangeData = exchangeSnapshot.data() || {};
      const ownerUid =
        pickString(exchangeData["targetUid"]) ||
        pickString(exchangeData["ownerUid"]) ||
        pickString(exchangeData["sellerUid"]);
      const requesterUid =
        pickString(exchangeData["requesterUid"]) ||
        pickString(exchangeData["actorUid"]) ||
        pickString(exchangeData["buyerUid"]);
      const ownerName = pickString(exchangeData["ownerName"]) || "El usuario";
      const requesterName = pickString(exchangeData["requesterName"]) || "Un usuario";
      const postId = pickString(exchangeData["postId"]);
      const postTitle = pickString(exchangeData["postTitle"]) || pickString(exchangeData["title"]);

      await db.collection("exchanges").doc(exchangeId).set({
        status: "completed",
        paymentStatus: "completed",
        paymentProvider: "paypal",
        paypalOrderId: orderId,
        paypalAmount: amountValue,
        updatedBy: uid || null,
        updatedAt: FieldValue.serverTimestamp(),
        completedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

      const completionNotifications: Promise<string>[] = [];
      if (ownerUid) {
        completionNotifications.push(createNotification({
          targetUid: ownerUid,
          type: "exchange_completed",
          title: "Intercambio completado",
          body: `Intercambio de "${postTitle || "material"}" completado con ${requesterName}`,
          actorUid: requesterUid || undefined,
          exchangeId,
          postId,
          postTitle,
          status: "completed",
          actorName: requesterName,
        }));
      }
      if (requesterUid) {
        completionNotifications.push(createNotification({
          targetUid: requesterUid,
          type: "exchange_completed",
          title: "Intercambio completado",
          body: `Intercambio de "${postTitle || "material"}" completado con ${ownerName}`,
          actorUid: ownerUid || undefined,
          exchangeId,
          postId,
          postTitle,
          status: "completed",
          actorName: ownerName,
        }));
      }
      await Promise.all(completionNotifications);
    }
  }

  return data;
});
