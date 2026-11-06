// test/values.test.ts … JavaScript の値 ⇔ Firestore の REST の値
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { fromFields, fromValue, toFields, toValue } from '../src/values.ts';

test('書くとき：文字・整数・小数・真偽・null・日時・並び・入れ子', () => {
  assert.deepEqual(toValue('a'), { stringValue: 'a' });
  assert.deepEqual(toValue(3), { integerValue: '3' });
  assert.deepEqual(toValue(1.5), { doubleValue: 1.5 });
  assert.deepEqual(toValue(false), { booleanValue: false });
  assert.deepEqual(toValue(null), { nullValue: null });
  assert.deepEqual(toValue(undefined), { nullValue: null });
  assert.deepEqual(toValue(new Date('2026-11-06T00:00:00Z')), { timestampValue: '2026-11-06T00:00:00.000Z' });
  assert.deepEqual(toValue([]), { arrayValue: { values: [] } });
  assert.deepEqual(toFields({ a: { b: ['x'] } }), {
    a: { mapValue: { fields: { b: { arrayValue: { values: [{ stringValue: 'x' }] } } } } },
  });
});

test('異常系：関数などは書けない', () => {
  assert.throws(() => toValue(() => 1), TypeError);
  assert.throws(() => toValue(Symbol('x')), TypeError);
});

test('読むとき：整数は number、日時は ms までの ISO、空の並び・空の Map', () => {
  assert.equal(fromValue({ integerValue: '42' }), 42);
  assert.equal(fromValue({ timestampValue: '2026-11-06T07:00:00.123456Z' }), '2026-11-06T07:00:00.123Z');
  assert.deepEqual(fromValue({ arrayValue: {} }), []);
  assert.deepEqual(fromValue({ mapValue: {} }), {});
  assert.throws(() => fromValue({} as never), TypeError);
});

test('書いて読むと同じ中身（日時は文字になる）', () => {
  const data = { s: 'x', n: 1, f: 0.5, b: true, z: null, l: [1, 'a', [true]], m: { k: { deep: 'v' } } };
  assert.deepEqual(fromFields(toFields(data)), data);
});
