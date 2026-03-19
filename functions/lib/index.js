"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.capturePayPalOrder = exports.createPayPalOrderHttp = exports.onUserSuspensionStatusChangedSyncAuth = exports.createExchangePayment = exports.onUserPresenceChangedSyncFirestore = exports.onExchangeUpdatedNotifyParticipants = exports.onExchangeCreatedNotifyTarget = void 0;
const firebase_functions_1 = require("firebase-functions");
const firestore_1 = require("firebase-functions/v2/firestore");
const database_1 = require("firebase-functions/v2/database");
const https_1 = require("firebase-functions/v2/https");
const logger = __importStar(require("firebase-functions/logger"));
const app_1 = require("firebase-admin/app");
const firestore_2 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
const node_buffer_1 = require("node:buffer");
// Configuración global para controlar costos y concurrencia.
(0, firebase_functions_1.setGlobalOptions)({ maxInstances: 10 });
(0, app_1.initializeApp)();
const db = (0, firestore_2.getFirestore)();
const auth = (0, auth_1.getAuth)();
/**
 * Retorna string con trim cuando el valor es texto; si no, retorna vacío.
 * @param {unknown} value Valor de entrada.
 * @return {string} Texto normalizado.
 */
function pickString(value) {
    return typeof value === "string" ? value.trim() : "";
}
/**
 * Convierte un valor desconocido a número decimal.
 * @param {unknown} value Valor a convertir.
 * @return {number | null} Número válido o null.
 */
function pickNumber(value) {
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
function pickDateFromMillis(value) {
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
function isSuspendedStatus(value) {
    const normalized = pickString(value).toLowerCase();
    return normalized === "suspendido" || normalized === "suspended";
}
/**
 * Crea un documento de notificación para un usuario destino.
 * @param {Object} params Datos de la notificación.
 * @return {Promise<string>} Id de la notificación creada.
 */
async function createNotification(params) {
    const notificationRef = db.collection("users")
        .doc(params.targetUid)
        .collection("notifications")
        .doc();
    await notificationRef.set({
        type: params.type,
        title: params.title,
        body: params.body,
        createdAt: firestore_2.FieldValue.serverTimestamp(),
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
exports.onExchangeCreatedNotifyTarget = (0, firestore_1.onDocumentCreated)("exchanges/{exchangeId}", async (event) => {
    var _a;
    const exchangeId = event.params.exchangeId;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data) {
        logger.warn("Intercambio creado sin payload", { exchangeId });
        return;
    }
    const targetUid = pickString(data["targetUid"]) ||
        pickString(data["ownerUid"]) ||
        pickString(data["sellerUid"]);
    const actorUid = pickString(data["requesterUid"]) ||
        pickString(data["actorUid"]) ||
        pickString(data["buyerUid"]);
    const actorName = pickString(data["requesterName"]) || "Un usuario";
    const ownerName = pickString(data["ownerName"]) || "El propietario";
    const postId = pickString(data["postId"]);
    const postTitle = pickString(data["postTitle"]) || pickString(data["title"]);
    const status = pickString(data["status"]) || "requested";
    if (!targetUid) {
        logger.warn("Intercambio sin uid de usuario destino", { exchangeId, data });
        return;
    }
    if (actorUid && actorUid === targetUid) {
        logger.info("Se omite notificación a sí mismo para intercambio", { exchangeId, targetUid });
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
    let requesterNotificationId;
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
});
exports.onExchangeUpdatedNotifyParticipants = (0, firestore_1.onDocumentUpdated)("exchanges/{exchangeId}", async (event) => {
    var _a, _b;
    const exchangeId = event.params.exchangeId;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after) {
        logger.warn("Actualización de intercambio sin before/after", { exchangeId });
        return;
    }
    const previousStatus = pickString(before["status"]).toLowerCase();
    const currentStatus = pickString(after["status"]).toLowerCase();
    if (!currentStatus || previousStatus === currentStatus) {
        return;
    }
    const ownerUid = pickString(after["targetUid"]) ||
        pickString(after["ownerUid"]) ||
        pickString(after["sellerUid"]);
    const requesterUid = pickString(after["requesterUid"]) ||
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
        let ownerNotificationId;
        if (ownerUid != actorUid) {
            ownerNotificationId = await createNotification({
                targetUid: ownerUid,
                type: "exchange_completed",
                title: "Intercambio completado",
                body: `Intercambio de "${postTitle || "material"}" completado con ${requesterName}`,
                actorUid: requesterUid,
                exchangeId,
                postId,
                postTitle,
                status: currentStatus,
                actorName: requesterName,
            });
        }
        let requesterNotificationId;
        if (requesterUid != actorUid) {
            requesterNotificationId = await createNotification({
                targetUid: requesterUid,
                type: "exchange_completed",
                title: "Intercambio completado",
                body: `Intercambio de "${postTitle || "material"}" completado con ${ownerName}`,
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
});
exports.onUserPresenceChangedSyncFirestore = (0, database_1.onValueWritten)("/status/{uid}", async (event) => {
    var _a;
    const uid = pickString(event.params.uid);
    if (!uid) {
        logger.warn("Cambio de presencia sin uid", { params: event.params });
        return;
    }
    const after = event.data.after.val();
    if (!after) {
        await db.collection("users").doc(uid).set({
            isOnline: false,
            lastSeen: firestore_2.FieldValue.serverTimestamp(),
        }, { merge: true });
        logger.info("Presencia eliminada, usuario marcado offline", { uid });
        return;
    }
    const state = pickString(after["state"]).toLowerCase();
    const lastChanged = pickDateFromMillis(after["lastChanged"]);
    await db.collection("users").doc(uid).set({
        isOnline: state === "online",
        lastSeen: lastChanged !== null && lastChanged !== void 0 ? lastChanged : firestore_2.FieldValue.serverTimestamp(),
    }, { merge: true });
    logger.info("Presencia sincronizada a Firestore", {
        uid,
        state,
        lastChanged: (_a = lastChanged === null || lastChanged === void 0 ? void 0 : lastChanged.toISOString()) !== null && _a !== void 0 ? _a : null,
    });
});
exports.createExchangePayment = (0, https_1.onCall)(async (request) => {
    var _a;
    const auth = request.auth;
    const uid = (auth === null || auth === void 0 ? void 0 : auth.uid) || "";
    const exchangeId = pickString((_a = request.data) === null || _a === void 0 ? void 0 : _a.exchangeId);
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "Debes iniciar sesión para pagar.");
    }
    if (!exchangeId) {
        throw new https_1.HttpsError("invalid-argument", "exchangeId es obligatorio.");
    }
    const exchangeRef = db.collection("exchanges").doc(exchangeId);
    const exchangeSnapshot = await exchangeRef.get();
    if (!exchangeSnapshot.exists) {
        throw new https_1.HttpsError("not-found", "El intercambio no existe.");
    }
    const exchangeData = exchangeSnapshot.data() || {};
    const requesterUid = pickString(exchangeData["requesterUid"]) ||
        pickString(exchangeData["actorUid"]) ||
        pickString(exchangeData["buyerUid"]);
    const ownerUid = pickString(exchangeData["targetUid"]) ||
        pickString(exchangeData["ownerUid"]) ||
        pickString(exchangeData["sellerUid"]);
    const method = pickString(exchangeData["method"]).toLowerCase();
    const postId = pickString(exchangeData["postId"]);
    const exchangeStatus = pickString(exchangeData["status"]).toLowerCase();
    if (uid !== requesterUid && uid !== ownerUid) {
        throw new https_1.HttpsError("permission-denied", "Solo los participantes pueden iniciar el pago.");
    }
    if (!postId) {
        throw new https_1.HttpsError("failed-precondition", "El intercambio no tiene una publicación asociada.");
    }
    if (exchangeStatus !== "accepted") {
        throw new https_1.HttpsError("failed-precondition", "El intercambio debe estar aceptado para iniciar el pago.");
    }
    const postSnapshot = await db.collection("posts").doc(postId).get();
    if (!postSnapshot.exists) {
        throw new https_1.HttpsError("not-found", "La publicación asociada al intercambio no existe.");
    }
    const postData = postSnapshot.data() || {};
    const postMethod = pickString(postData["method"]).toLowerCase();
    const amount = pickNumber(postData["priceUsd"]);
    if (method !== "venta" && postMethod !== "venta") {
        throw new https_1.HttpsError("failed-precondition", "Este intercambio no requiere pago.");
    }
    if (amount === null || amount <= 0) {
        throw new https_1.HttpsError("failed-precondition", "La publicación no tiene un monto de pago válido.");
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
        createdAt: firestore_2.FieldValue.serverTimestamp(),
        updatedAt: firestore_2.FieldValue.serverTimestamp(),
    });
    await exchangeRef.set({
        paymentStatus: "pending",
        paymentId: paymentRef.id,
        updatedAt: firestore_2.FieldValue.serverTimestamp(),
    }, { merge: true });
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
exports.onUserSuspensionStatusChangedSyncAuth = (0, firestore_1.onDocumentUpdated)("users/{userId}", async (event) => {
    var _a, _b;
    const userId = event.params.userId;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!after) {
        return;
    }
    const beforeSuspended = isSuspendedStatus(before === null || before === void 0 ? void 0 : before["status"]);
    const afterSuspended = isSuspendedStatus(after["status"]);
    if (beforeSuspended === afterSuspended) {
        return;
    }
    try {
        await auth.updateUser(userId, { disabled: afterSuspended });
        if (afterSuspended) {
            await auth.revokeRefreshTokens(userId);
        }
        logger.info("Sincronizado estado de suspensión hacia Firebase Auth", {
            userId,
            disabled: afterSuspended,
        });
    }
    catch (error) {
        logger.error("No se pudo sincronizar suspensión en Firebase Auth", {
            userId,
            disabled: afterSuspended,
            error,
        });
        throw error;
    }
});
const PAYPAL_BASE_URL = "https://api-m.sandbox.paypal.com"; // Cambiar a live en producción
function summarizePayPalError(data) {
    var _a, _b, _c, _d;
    const message = pickString(data === null || data === void 0 ? void 0 : data.message);
    const description = pickString(data === null || data === void 0 ? void 0 : data.error_description);
    const issue = pickString((_b = (_a = data === null || data === void 0 ? void 0 : data.details) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.issue);
    const field = pickString((_d = (_c = data === null || data === void 0 ? void 0 : data.details) === null || _c === void 0 ? void 0 : _c[0]) === null || _d === void 0 ? void 0 : _d.field);
    const debugId = pickString(data === null || data === void 0 ? void 0 : data.debug_id);
    const name = pickString(data === null || data === void 0 ? void 0 : data.name);
    const parts = [
        name,
        message,
        description,
        issue ? `issue=${issue}` : "",
        field ? `field=${field}` : "",
        debugId ? `debug_id=${debugId}` : "",
    ];
    return parts.filter((value) => value.length > 0).join(" | ");
}
async function getPayPalAccessToken() {
    const paypalClientId = process.env.PAYPAL_CLIENT_ID || "";
    const paypalClientSecret = process.env.PAYPAL_CLIENT_SECRET || "";
    if (!paypalClientId || !paypalClientSecret) {
        throw new https_1.HttpsError("failed-precondition", "Las credenciales de PayPal no estan configuradas.");
    }
    const auth = node_buffer_1.Buffer.from(`${paypalClientId}:${paypalClientSecret}`).toString("base64");
    const response = await fetch(`${PAYPAL_BASE_URL}/v1/oauth2/token`, {
        method: "POST",
        headers: {
            Authorization: `Basic ${auth}`,
            "Content-Type": "application/x-www-form-urlencoded",
        },
        body: "grant_type=client_credentials",
    });
    const data = await response.json();
    if (!response.ok || !pickString(data === null || data === void 0 ? void 0 : data.access_token)) {
        logger.error("PayPal token error", {
            status: response.status,
            data,
        });
        throw new https_1.HttpsError("internal", `No se pudo autenticar con PayPal. ${summarizePayPalError(data)}`.trim(), {
            status: response.status,
            paypal: data,
        });
    }
    return data.access_token;
}
exports.createPayPalOrderHttp = (0, https_1.onRequest)({
    secrets: ["PAYPAL_CLIENT_ID", "PAYPAL_CLIENT_SECRET"],
}, async (req, res) => {
    var _a, _b, _c, _d, _e, _f;
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
    }
    if (req.method !== "POST") {
        res.status(405).json({ error: "Metodo no permitido." });
        return;
    }
    try {
        const amount = pickNumber((_a = req.body) === null || _a === void 0 ? void 0 : _a.amount);
        const returnUrl = pickString((_b = req.body) === null || _b === void 0 ? void 0 : _b.returnUrl);
        const cancelUrl = pickString((_c = req.body) === null || _c === void 0 ? void 0 : _c.cancelUrl);
        if (!amount || amount <= 0) {
            res.status(400).json({ error: "Monto inválido." });
            return;
        }
        if (!returnUrl || !cancelUrl) {
            res.status(400).json({
                error: "returnUrl y cancelUrl son obligatorios.",
            });
            return;
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
        if (!response.ok) {
            logger.error("PayPal order creation failed over HTTP", {
                status: response.status,
                returnUrl,
                cancelUrl,
                data,
            });
            res.status(500).json({
                error: `PayPal rechazo la creacion de la orden. ${summarizePayPalError(data)}`.trim(),
            });
            return;
        }
        logger.info("PayPal order created over HTTP", data);
        const approveUrl = pickString((_f = (_e = (_d = data === null || data === void 0 ? void 0 : data.links) === null || _d === void 0 ? void 0 : _d.find) === null || _e === void 0 ? void 0 : _e.call(_d, (link) => pickString(link === null || link === void 0 ? void 0 : link.rel) === "approve")) === null || _f === void 0 ? void 0 : _f.href);
        const orderId = pickString(data === null || data === void 0 ? void 0 : data.id);
        if (!approveUrl || !orderId) {
            logger.error("PayPal order missing approval data over HTTP", { data });
            res.status(500).json({
                error: "PayPal respondio sin el enlace de aprobacion esperado.",
            });
            return;
        }
        res.status(200).json({
            orderId,
            approveUrl,
            status: pickString(data === null || data === void 0 ? void 0 : data.status),
        });
    }
    catch (error) {
        logger.error("Unexpected createPayPalOrderHttp error", error);
        res.status(500).json({
            error: "No se pudo crear la orden de PayPal.",
        });
    }
});
exports.capturePayPalOrder = (0, https_1.onCall)({
    secrets: ["PAYPAL_CLIENT_ID", "PAYPAL_CLIENT_SECRET"],
}, async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const auth = request.auth;
    const uid = (auth === null || auth === void 0 ? void 0 : auth.uid) || "";
    const orderId = pickString((_a = request.data) === null || _a === void 0 ? void 0 : _a.orderId);
    const exchangeId = pickString((_b = request.data) === null || _b === void 0 ? void 0 : _b.exchangeId);
    if (!orderId) {
        throw new https_1.HttpsError("invalid-argument", "orderId es obligatorio.");
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
    if (!response.ok) {
        logger.error("PayPal capture failed", {
            status: response.status,
            orderId,
            exchangeId,
            data,
        });
        throw new https_1.HttpsError("internal", `PayPal rechazo la captura de la orden. ${summarizePayPalError(data)}`.trim(), {
            status: response.status,
            orderId,
            exchangeId,
            paypal: data,
        });
    }
    logger.info("PayPal order captured", data);
    if (data.status === "COMPLETED") {
        const amountValue = ((_h = (_g = (_f = (_e = (_d = (_c = data.purchase_units) === null || _c === void 0 ? void 0 : _c[0]) === null || _d === void 0 ? void 0 : _d.payments) === null || _e === void 0 ? void 0 : _e.captures) === null || _f === void 0 ? void 0 : _f[0]) === null || _g === void 0 ? void 0 : _g.amount) === null || _h === void 0 ? void 0 : _h.value) || null;
        await db.collection("paypalPayments").doc(orderId).set({
            orderId,
            status: "completed",
            amount: amountValue,
            currency: "USD",
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
        if (exchangeId) {
            const exchangeSnapshot = await db.collection("exchanges").doc(exchangeId).get();
            const exchangeData = exchangeSnapshot.data() || {};
            const ownerUid = pickString(exchangeData["targetUid"]) ||
                pickString(exchangeData["ownerUid"]) ||
                pickString(exchangeData["sellerUid"]);
            const requesterUid = pickString(exchangeData["requesterUid"]) ||
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
                updatedAt: firestore_2.FieldValue.serverTimestamp(),
                completedAt: firestore_2.FieldValue.serverTimestamp(),
            }, { merge: true });
            const completionNotifications = [];
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
//# sourceMappingURL=index.js.map