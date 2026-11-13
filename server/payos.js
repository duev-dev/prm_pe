import { createHmac } from 'node:crypto';

const BASE = 'https://api-merchant.payos.vn/v2/payment-requests';

/** PayOS signature: HMAC-SHA256 (hex) of the 5 fields in alphabetical order. */
export function sign({ amount, cancelUrl, description, orderCode, returnUrl }, checksumKey) {
  const data = `amount=${amount}&cancelUrl=${cancelUrl}&description=${description}&orderCode=${orderCode}&returnUrl=${returnUrl}`;
  return createHmac('sha256', checksumKey).update(data).digest('hex');
}

export function payosClient({ clientId, apiKey, checksumKey }) {
  const headers = { 'x-client-id': clientId, 'x-api-key': apiKey, 'content-type': 'application/json' };

  async function call(path, init = {}) {
    const res = await fetch(BASE + path, { ...init, headers });
    const body = await res.json().catch(() => ({}));
    if (body.code !== '00') throw new Error(body.desc || `PayOS HTTP ${res.status}`);
    return body.data;
  }

  return {
    create(order) {
      return call('', { method: 'POST', body: JSON.stringify({ ...order, signature: sign(order, checksumKey) }) });
    },
    get: (orderCode) => call(`/${orderCode}`),
    cancel: (orderCode) =>
      call(`/${orderCode}/cancel`, { method: 'POST', body: JSON.stringify({ cancellationReason: 'Huỷ trong app' }) }),
  };
}
