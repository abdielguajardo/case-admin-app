# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Salesforce DX project** using API version 66.0. It contains Lightning Web Components (LWC), Apex classes/triggers, and related Salesforce metadata. All source lives under `force-app/main/default/`.

## Commands

```bash
# Lint (ESLint on Aura/LWC JS)
npm run lint

# Format (Prettier on Apex, HTML, JS, CSS, JSON, XML, YAML)
npm run prettier

# Verify formatting without changing files
npm run prettier:verify

# Run unit tests (Jest for LWC)
npm test

# Run a single test file
npx jest path/to/component/__tests__/component.test.js

# Run tests in watch mode
npm run test:unit:watch

# Run tests with coverage
npm run test:unit:coverage
```

Salesforce CLI commands for org management:
```bash
# Create a scratch org
sf org create scratch -f config/project-scratch-def.json -a <alias>

# Push source to scratch org
sf project deploy start

# Pull changes from scratch org
sf project retrieve start

# Run anonymous Apex
sf apex run -f scripts/apex/hello.apex
```

## Architecture

### Directory Structure

```
force-app/main/default/
├── lwc/           # Lightning Web Components (UI components)
├── aura/          # Aura components (legacy)
├── classes/       # Apex classes (server-side logic)
├── triggers/      # Apex triggers (object event handlers)
├── objects/       # Custom object/field metadata
├── layouts/       # Page layouts
├── flexipages/    # Lightning pages
├── applications/  # Lightning app configs
├── permissionsets/
├── tabs/
└── staticresources/
scripts/
├── apex/          # Anonymous Apex scripts
└── soql/          # SOQL queries for data exploration
config/
└── project-scratch-def.json  # Scratch org definition (Developer Edition)
```

### LWC Component Structure

Each LWC component under `lwc/<componentName>/` contains:
- `<componentName>.html` — template
- `<componentName>.js` — controller
- `<componentName>.js-meta.xml` — metadata (targets, API version)
- `<componentName>.css` — styles (optional)
- `__tests__/<componentName>.test.js` — Jest unit tests

### Tooling

- **ESLint** (`eslint.config.js`): Uses `@salesforce/eslint-config-lwc/recommended` for LWC and `@salesforce/eslint-plugin-aura` for Aura.
- **Jest** (`jest.config.js`): Extends `@salesforce/sfdx-lwc-jest` preset. Tests live in `__tests__/` subdirectories within each component.
- **Prettier** (`.prettierrc`): Configured for Apex, XML, LWC HTML, JS, CSS, JSON, YAML.
- **Husky + lint-staged**: Pre-commit hook runs Prettier, ESLint, and Jest on staged files.
- **`.forceignore`**: Excludes `package.xml`, `node_modules/`, `__tests__/`, and story files from Salesforce push/pull.

### Scratch Org

Defined in `config/project-scratch-def.json` as a Developer Edition org named "tuto company" with Lightning Experience enabled.
