import { describe, it, test } from 'node:test';
import assert from 'node:assert';

describe('String Operations', () => {
  describe('Concatenation', () => {
    it('should concatenate two strings', () => {
      assert.strictEqual('hello' + ' ' + 'world', 'hello world');
    });

    it('should handle empty strings', () => {
      assert.strictEqual('' + 'test', 'test');
    });
  });

  describe('Length', () => {
    it('should return correct length', () => {
      assert.strictEqual('hello'.length, 5);
    });
  });
});

describe('Async Tests', () => {
  it('should handle async operations', async () => {
    const result = await Promise.resolve(42);
    assert.strictEqual(result, 42);
  });
});

test('Top level test', () => {
  assert.ok(true);
});