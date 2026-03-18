const { client } = require('./paypalClient');
const checkoutNodeJssdk = require('@paypal/checkout-server-sdk');

async function createPayPalOrder(amount) {
  const request = new checkoutNodeJssdk.orders.OrdersCreateRequest();
  request.prefer("return=representation");

  request.requestBody({
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
      return_url: "myapp://paypal-success",
      cancel_url: "myapp://paypal-cancel",
    },
  });

  const response = await client().execute(request);
  return response.result;
}

module.exports = { createPayPalOrder };
