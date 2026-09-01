---
name: playwright
description: Run Playwright E2E UI tests, generate reports
tools: [Read, Edit, Write, Glob, Grep, Bash]
disableModelInvocation: false
---

# Skill: Playwright E2E Testing

## Environment Check

```bash
npx playwright --version          # verify installation
npm install @playwright/test      # install if missing
npx playwright install            # install browsers
```

## Running Tests

```bash
npx playwright test                        # run all E2E tests
npx playwright test --reporter=html        # with HTML report
```

## Writing Tests

```typescript
import { test, expect } from '@playwright/test';

test('description', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('h1')).toBeVisible();
});
```

## When to Run

- After modifying UI components
- After routing changes
- After changing forms or interactive features
- **Before every production deploy (mandatory)**

## Failure Investigation

1. Review error screenshots from `test-results/`
2. Examine traces if enabled (`--trace on`)
3. Determine root cause: code issue vs. outdated test
4. Fix accordingly

## Supported Frameworks

Works with React, Vue, Svelte, and plain HTML/CSS project structures.
