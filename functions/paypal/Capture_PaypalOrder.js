const { client } = require('./paypalClient');
const checkoutNodeJssdk = require('@paypal/checkout-server-sdk');

async function capturePayPalOrder(orderId) {
  const request = new checkoutNodeJssdk.orders.OrdersCaptureRequest(orderId);
  request.requestBody({});

  const response = await client().execute(request);
  return response.result;
}

module.exports = { capturePayPalOrder };
