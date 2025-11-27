import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('Failing Tests', () => {
  it('should fail intentionally', () => {
    assert.strictEqual(2 + 2, 5, 'This test is designed to fail');
  });

  it('should pass', () => {
    assert.ok(true);
  });
});