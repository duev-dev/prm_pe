import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { sign } from './payos.js';

test('signature signs the fields in alphabetical order', () => {
  const order = { orderCode: 123, amount: 5000, description: 'PRM000123', returnUrl: 'https://x/r', cancelUrl: 'https://x/c' };
  const expected = createHmac('sha256', 'key')
    .update('amount=5000&cancelUrl=https://x/c&description=PRM000123&orderCode=123&returnUrl=https://x/r')
    .digest('hex');
  assert.equal(sign(order, 'key'), expected);
});
