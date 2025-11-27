import { describe, it, test } from 'node:test';
import assert from 'node:assert';

describe('Basic Math Tests', () => {
  it('should add two numbers correctly', () => {
    assert.strictEqual(2 + 2, 4);
  });

  it('should multiply two numbers correctly', () => {
    assert.strictEqual(3 * 4, 12);
  });
});

test('Simple test without describe', () => {
  assert.strictEqual('hello', 'hello');
});