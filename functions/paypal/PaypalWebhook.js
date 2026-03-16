async function paypalWebhook(req, res) {
  const event = req.body;

  switch (event.event_type) {
    case "PAYMENT.CAPTURE.COMPLETED":
      console.log("Pago completado:", event.resource.id);
      break;

    case "PAYMENT.CAPTURE.DENIED":
      console.log("Pago denegado:", event.resource.id);
      break;

    case "PAYMENT.CAPTURE.REFUNDED":
      console.log("Pago reembolsado:", event.resource.id);
      break;
  }

  res.sendStatus(200);
}

module.exports = { paypalWebhook };
