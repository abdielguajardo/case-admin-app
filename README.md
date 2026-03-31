# CaseAdminApp 

## 🚧 Project Status: Under Heavy Construction

> ⚠️ **Heads up! This project is currently under active development.**

Things you should know:
- 🔥 Features may be incomplete or unstable  
- 🧩 Metadata and configurations may change without notice  
- 🚀 Deployment steps might not work (yet)

## Project Contents

Salesforce DX project for administering Case Widget domain configuration in Lightning Experience.

## Project Contents

This project includes:

- custom objects for domain, config, and case type management
- Apex service logic for loading and saving Case Widget configuration
- Lightning Web Components for the admin UI
- a Lightning app, FlexiPage, and custom tab for accessing the admin experience

Main metadata:

- [`force-app/main/default/objects`](./force-app/main/default/objects)
- [`force-app/main/default/classes`](./force-app/main/default/classes)
- [`force-app/main/default/lwc`](./force-app/main/default/lwc)
- [`force-app/main/default/flexipages/CaseWidgetAdmin.flexipage-meta.xml`](./force-app/main/default/flexipages/CaseWidgetAdmin.flexipage-meta.xml)
- [`force-app/main/default/tabs/CaseWidgetAdmin.tab-meta.xml`](./force-app/main/default/tabs/CaseWidgetAdmin.tab-meta.xml)
- [`force-app/main/default/applications/CaseWidgetAdmin.app-meta.xml`](./force-app/main/default/applications/CaseWidgetAdmin.app-meta.xml)

## Prerequisites

- Salesforce CLI (`sf`)
- Node.js and npm
- access to a Salesforce org where you can deploy metadata

## Salesforce DX Project Setup

Project configuration is defined in [`sfdx-project.json`](./sfdx-project.json).

Install local dependencies:

```bash
npm install
```

## Deploy to an Org

If the target org does not already contain this metadata, deploy in dependency order:

```bash
sf project deploy start --source-dir force-app/main/default/objects
sf project deploy start --source-dir force-app/main/default/classes
sf project deploy start --source-dir force-app/main/default/lwc
sf project deploy start --source-dir force-app/main/default/flexipages
sf project deploy start --source-dir force-app/main/default/tabs
sf project deploy start --source-dir force-app/main/default/applications
sf project deploy start --source-dir force-app/main/default/permissionsets
```

After the org is aligned, you can also deploy the full package directory:

```bash
sf project deploy start --source-dir force-app/main/default
```

## Scratch Org Workflow

Scratch org definition file:

- [`config/project-scratch-def.json`](./config/project-scratch-def.json)

Example flow:

```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias case-widget-dev --set-default --duration-days 7
sf project deploy start --source-dir force-app/main/default
sf org open
```

## Assign Access

This project includes the permission set:

- [`force-app/main/default/permissionsets/CaseWidgetAdmin.permissionset-meta.xml`](./force-app/main/default/permissionsets/CaseWidgetAdmin.permissionset-meta.xml)

Assign it after deployment if needed:

```bash
sf org assign permset --name CaseWidgetAdmin
```

You can also grant access through the Salesforce UI using profiles or permission sets.

## Open the App

After deployment:

1. Open App Launcher
2. Search for `Case Widget Admin`
3. Open the app

If the app navigation does not show the expected page, verify in `App Manager` that:

- the `CaseWidgetAdmin` tab is included in navigation items
- the app is visible to the intended users

## Run Tests

Run LWC unit tests:

```bash
npm test
```

Watch mode:

```bash
npm run test:unit:watch
```

Run coverage:

```bash
npm run test:unit:coverage
```

Relevant test files:

- [`force-app/main/default/classes/CaseWidgetDomainServiceTest.cls`](./force-app/main/default/classes/CaseWidgetDomainServiceTest.cls)
- [`force-app/main/default/lwc/caseWidgetAdmin/__tests__/caseWidgetAdmin.test.js`](./force-app/main/default/lwc/caseWidgetAdmin/__tests__/caseWidgetAdmin.test.js)
- [`force-app/main/default/lwc/caseWidgetDomainForm/__tests__/caseWidgetDomainForm.test.js`](./force-app/main/default/lwc/caseWidgetDomainForm/__tests__/caseWidgetDomainForm.test.js)
- [`force-app/main/default/lwc/caseWidgetDomainList/__tests__/caseWidgetDomainList.test.js`](./force-app/main/default/lwc/caseWidgetDomainList/__tests__/caseWidgetDomainList.test.js)
- [`force-app/main/default/lwc/caseWidgetCaseTypeEditor/__tests__/caseWidgetCaseTypeEditor.test.js`](./force-app/main/default/lwc/caseWidgetCaseTypeEditor/__tests__/caseWidgetCaseTypeEditor.test.js)

## Lint and Format

Lint:

```bash
npm run lint
```

Format:

```bash
npm run prettier
```

Verify formatting:

```bash
npm run prettier:verify
```

## Notes

- The main admin UI component is [`caseWidgetAdmin`](./force-app/main/default/lwc/caseWidgetAdmin).
- Server-side logic is implemented in [`CaseWidgetDomainService.cls`](./force-app/main/default/classes/CaseWidgetDomainService.cls).
- The current Apex service does not use `WITH SECURITY_ENFORCED`. This was done to simplify admin-page access during setup and deployment. Restrict app access to trusted users.

## Troubleshooting

Common issues:

- `Invalid type` errors in Apex
  - deploy custom objects before classes
- app opens but shows generic Home
  - verify app navigation items and tab visibility in the org UI
- admin page loads but data does not render
  - verify Apex, objects, and LWC metadata all deployed successfully
- permission set deployment errors on required fields
  - adjust permission metadata or use org UI assignment for access

## API Version

This project uses source API version `66.0`.
