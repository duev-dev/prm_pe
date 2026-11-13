// Small PayOS proxy so the PayOS keys never ship inside the APK.
// The app asks this server for a payment link, then polls the status; the status always comes from PayOS itself.
import { createServer } from 'node:http';
import { payosClient } from './payos.js';

const { PAYOS_CLIENT_ID, PAYOS_API_KEY, PAYOS_CHECKSUM_KEY, PORT = 3000 } = process.env;
if (!PAYOS_CLIENT_ID || !PAYOS_API_KEY || !PAYOS_CHECKSUM_KEY) {
  console.error('Thiếu PAYOS_CLIENT_ID / PAYOS_API_KEY / PAYOS_CHECKSUM_KEY');
  process.exit(1);
}
const payos = payosClient({ clientId: PAYOS_CLIENT_ID, apiKey: PAYOS_API_KEY, checksumKey: PAYOS_CHECKSUM_KEY });
// Render sets RENDER_EXTERNAL_URL to the public https address of the service.
const publicUrl = process.env.RENDER_EXTERNAL_URL || `http://localhost:${PORT}`;

const send = (res, status, body, type = 'application/json; charset=utf-8') => {
  res.writeHead(status, { 'content-type': type });
  res.end(type.startsWith('application/json') ? JSON.stringify(body) : body);
};

async function readJson(req) {
  let raw = '';
  for await (const chunk of req) {
    raw += chunk;
    if (raw.length > 10_000) throw new Error('Body quá lớn');
  }
  return raw ? JSON.parse(raw) : {};
}

createServer(async (req, res) => {
  const { pathname } = new URL(req.url, publicUrl);
  try {
    if (req.method === 'GET' && pathname === '/') return send(res, 200, { ok: true });

    // PayOS redirects the browser here after paying or cancelling.
    if (req.method === 'GET' && pathname === '/return') {
      return send(
        res,
        200,
        '<meta name="viewport" content="width=device-width"><body style="font-family:sans-serif;text-align:center;padding:40px">' +
          '<h2>Đã xử lý thanh toán</h2><p>Bạn có thể đóng trang này và quay lại ứng dụng PRM Shop.</p></body>',
        'text/html; charset=utf-8',
      );
    }

    if (req.method === 'POST' && pathname === '/payments') {
      const { amount } = await readJson(req);
      if (!Number.isInteger(amount) || amount <= 0 || amount > 10_000_000_000) {
        return send(res, 400, { error: 'Số tiền không hợp lệ' });
      }
      // Unique, below Number.MAX_SAFE_INTEGER.
      const orderCode = Date.now() * 1000 + Math.floor(Math.random() * 1000);
      const link = await payos.create({
        orderCode,
        amount,
        description: `PRM${String(orderCode).slice(-6)}`, // 9-char limit for banks not linked via PayOS
        returnUrl: `${publicUrl}/return`,
        cancelUrl: `${publicUrl}/return`,
      });
      return send(res, 200, { orderCode, checkoutUrl: link.checkoutUrl, amount });
    }

    const m = pathname.match(/^\/payments\/(\d{1,16})(\/cancel)?$/);
    if (m && req.method === 'GET' && !m[2]) {
      const info = await payos.get(m[1]);
      return send(res, 200, { status: info.status, amount: info.amount, amountPaid: info.amountPaid });
    }
    if (m && req.method === 'POST' && m[2]) {
      await payos.cancel(m[1]);
      return send(res, 200, { ok: true });
    }

    send(res, 404, { error: 'Not found' });
  } catch (e) {
    console.error(req.method, pathname, e.message);
    send(res, 502, { error: e.message });
  }
}).listen(PORT, () => console.log(`PayOS server chạy ở cổng ${PORT}`));
