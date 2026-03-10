import {setGlobalOptions} from "firebase-functions";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

// Configuración global para controlar costos y concurrencia.
setGlobalOptions({maxInstances: 10});

initializeApp();

const db = getFirestore();

/**
 * Retorna string con trim cuando el valor es texto; si no, retorna vacío.
 * @param {unknown} value Valor de entrada.
 * @return {string} Texto normalizado.
 */
function pickString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
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
  status?: string;
  actorName?: string;
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
      status: params.status || null,
      actorName: params.actorName || null,
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
    const postId = pickString(data["postId"]);
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
      title: "Nueva solicitud de intercambio",
      body: ${actorName} quiere realizar un intercambio contigo,
      actorUid,
      exchangeId,
      postId,
      status,
      actorName,
    });

    logger.info("Notificación de intercambio creada", {
      exchangeId,
      targetUid,
      notificationId,
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
      const notificationId = await createNotification({
        targetUid: requesterUid,
        type: "exchange_accepted",
        title: "Intercambio aceptado",
        body: ${ownerName} aceptó tu solicitud de intercambio,
        actorUid: ownerUid,
        exchangeId,
        postId,
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

    if (currentStatus === "rejected" || currentStatus === "declined") {
      const notificationId = await createNotification({
        targetUid: requesterUid,
        type: "exchange_rejected",
        title: "Intercambio rechazado",
        body: ${ownerName} rechazó tu solicitud de intercambio,
        actorUid: ownerUid,
        exchangeId,
        postId,
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

    if (currentStatus === "completed") {
      const ownerNotificationId = await createNotification({
        targetUid: ownerUid,
        type: "exchange_completed",
        title: "Intercambio completado",
        body: El intercambio con ${requesterName} fue completado,
        actorUid: requesterUid,
        exchangeId,
        postId,
        status: currentStatus,
        actorName: requesterName,
      });
      const requesterNotificationId = await createNotification({
        targetUid: requesterUid,
        type: "exchange_completed",
        title: "Intercambio completado",
        body: El intercambio con ${ownerName} fue completado,
        actorUid: ownerUid,
        exchangeId,
        postId,
        status: currentStatus,
        actorName: ownerName,
      });
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