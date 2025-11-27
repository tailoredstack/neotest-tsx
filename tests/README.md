# Test Files for neotest-tsx

This directory contains example test files that can be used to test the neotest-tsx adapter.

## Test Files

- `basic.test.ts` - Simple tests with basic assertions
- `advanced.test.ts` - More complex tests with nested describes and async tests
- `example.spec.ts` - Tests using the .spec.ts naming convention

## Running Tests

To run these tests manually with tsx:

```bash
# Install dependencies
npm install

# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run a specific test file
npx tsx tests/basic.test.ts
```

## Testing the Adapter

These test files are designed to verify that the neotest-tsx adapter correctly:

1. **Discovers test files** - Files ending in `.test.ts`, `.spec.ts`, etc.
2. **Parses test structure** - `describe` blocks, `it`/`test` cases, nested structures
3. **Runs tests** - Executes the test files using tsx
4. **Handles different patterns** - Various naming conventions and test structures

## Test Structure Examples

The test files demonstrate:

- Basic synchronous tests
- Async tests with promises
- Nested `describe` blocks
- Different file naming patterns (`.test.ts`, `.spec.ts`)
- Top-level `test()` calls vs `describe()` + `it()` patterns