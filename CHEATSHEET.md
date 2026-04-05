# 📋 SAP CAP / CDS / OData / Fiori — Quick Reference Cheatsheet

> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development | SAP Certified — BTP, ABAP, Fiori, BDC

## CDS Language

```cds
// Entity
entity Books : cuid, managed {
    title  : String(150);
    price  : Decimal(10,2);
    author : Association to Authors;
    items  : Composition of many OrderItems on items.book = $self;
}

// Service
service CatalogService @(path:'/catalog') {
    @readonly entity Books as projection on db.Books;
    action  submitOrder(id: UUID) returns String;
    function getCount() returns Integer;
}

// Annotate
annotate Books with @(
    UI.LineItem: [{ Value: title }, { Value: price }]
);
```

## CDS Built-in Types

| Type | Description |
|------|-------------|
| `UUID` | Globally unique identifier |
| `String(n)` | Variable-length string |
| `Integer` | 32-bit integer |
| `Decimal(p,s)` | Fixed-point number |
| `Boolean` | true/false |
| `Date` | YYYY-MM-DD |
| `DateTime` | Date + Time |
| `Timestamp` | High-precision timestamp |
| `LargeBinary` | BLOB (files, images) |

## CDS Annotations Quick Reference

```cds
@mandatory                     // Field required
@readonly                      // No write access
@assert.range: [1, 10]         // Value range validation
@assert.format: 'regex'        // Regex validation
@Core.MediaType: 'image/png'   // Binary media type
@odata.draft.enabled: true     // Enable draft mode
@requires: 'admin'             // Auth scope required
```

## OData Query Cheatsheet

```
# Filter
$filter=price lt 20
$filter=price ge 10 and price le 50
$filter=contains(title,'Harry')
$filter=year(createdAt) eq 2024

# Select / Expand
$select=title,price
$expand=author($select=name)
$expand=items($expand=book)

# Sort & Page
$orderby=price desc,title asc
$top=10&$skip=20

# Count
$count=true

# Search (full-text)
$search=keyword

# Aggregation (v4 only)
$apply=groupby((genre/name),aggregate(price with average as avgPrice))
```

## CAP CLI Commands

```bash
cds init <project>          # Init new CAP project
cds watch                   # Run in dev mode (auto-reload)
cds serve                   # Run production mode
cds build --production      # Build for deployment
cds deploy --to sqlite      # Deploy to SQLite
cds deploy --to hana        # Deploy to HANA
cds import <edmx-file>      # Import external OData API
cds add hana                # Add HANA support
cds add xsuaa               # Add XSUAA support
cds add mta                 # Generate mta.yaml
cds version                 # Show version info
```

## CF CLI Commands

```bash
cf login -a <api-url>       # Login to CF
cf apps                     # List apps
cf app <app-name>           # App status & details
cf logs <app-name> --recent # Recent logs
cf logs <app-name>          # Live stream logs
cf env <app-name>           # Environment variables
cf services                 # List service instances
cf create-service <svc> <plan> <name>  # Create service
cf bind-service <app> <svc>            # Bind service to app
cf push                     # Push app (with manifest.yml)
cf deploy <mtar-file>       # Deploy MTA archive
```

## MTA Build & Deploy

```bash
# Install tools
npm i -g mbt
cf install-plugin multiapps

# Build
mbt build -t ./

# Deploy
cf deploy <file>.mtar --retries 1

# Undeploy
cf undeploy <mta-id> --delete-services
```

## CAP Event Handler Patterns

```javascript
// Validation before write
this.before(['CREATE', 'UPDATE'], 'Books', req => { ... });

// Transform after read
this.after('READ', 'Books', results => { ... });

// Full control on operation
this.on('READ', 'Books', async (req, next) => {
    return next(); // call default handler
});

// Handle action
this.on('myAction', async req => {
    const { param } = req.data;
    return { result: 'ok' };
});
```

## XSUAA Scopes in CAP

```cds
// Service level
@requires: 'admin'
service AdminService { ... }

// Operation level
@(requires: 'write')
action create(...) returns ...;
```

```javascript
// In handler
const user = req.user;
user.is('admin')        // → boolean
user.id                 // → user identifier
user.tenant             // → tenant id
user.attr.MyAttr        // → custom attribute
```

## Fiori Annotations Quick Reference

```cds
// List columns
@UI.LineItem: [{ Value: field, Label: 'Label' }]

// Filter bar
@UI.SelectionFields: [field1, field2]

// Object page header
@UI.HeaderInfo: {
    TypeName: 'Entity',
    Title: { Value: nameField }
}

// Object page sections
@UI.Facets: [{
    $Type : 'UI.ReferenceFacet',
    Target: '@UI.FieldGroup#Section1'
}]

// Field group
@UI.FieldGroup #Section1: {
    Data: [{ Value: field1 }, { Value: field2 }]
}

// Value help
@Common.ValueList: {
    CollectionPath: 'Entity',
    Parameters: [{
        $Type: 'Common.ValueListParameterOut',
        LocalDataProperty: localField,
        ValueListProperty: 'ID'
    }]
}
```

---

<sub>**Workshop Material by Wahyu Amaldi** — Technical Lead SAP & Full Stack Development | SAP Certified — BTP, ABAP, Fiori, BDC</sub>
