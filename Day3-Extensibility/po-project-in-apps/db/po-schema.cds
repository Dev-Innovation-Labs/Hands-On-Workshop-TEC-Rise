namespace com.tecrise.procurement;

/**
 * PO Request — In-App Extensibility (CBO)
 *
 * Data disimpan di SAP S/4HANA via Custom Business Object:
 *   Header → ZZ1_WPOREQ_CDS  (OData V2)
 *   Items  → ZZ1_WPOREQI_CDS (OData V2)
 *
 * @cds.persistence.skip — tidak ada local database.
 * CAP bertindak sebagai proxy layer (field mapping + business logic + Fiori UI).
 *
 * Perbedaan dengan po-project (side-by-side):
 * ┌──────────────────────┬───────────────────────┬──────────────────────┐
 * │ Aspek                │ po-project (BTP)      │ po-project-in-apps   │
 * ├──────────────────────┼───────────────────────┼──────────────────────┤
 * │ Database             │ HANA Cloud / SQLite   │ SAP CBO (embedded)   │
 * │ DB Cost              │ ~€693/bln or trial    │ $0 (SAP license)     │
 * │ Persistence          │ cuid + managed        │ @cds.persistence.skip│
 * │ CRUD Handler         │ Default (DB)          │ Custom ON → CBO OData│
 * │ Field Mapping        │ Direct                │ CBO ↔ CAP mapping    │
 * │ Dependencies         │ @cap-js/hana, sqlite  │ Hanya @sap/cds       │
 * └──────────────────────┴───────────────────────┴──────────────────────┘
 */

@cds.persistence.skip
entity PORequests {
    key ID              : UUID;         // = CBO SAP_UUID (auto-generated oleh SAP)
    requestNo           : String(20);
    description         : String(200);
    supplier            : String(20);
    supplierName        : String(80);
    companyCode         : String(20) default '1710';
    purchasingOrg       : String(20) default '1710';
    purchasingGroup     : String(20) default '001';
    orderDate           : Date;
    deliveryDate        : Date;
    currency            : String(20) default 'USD';
    totalAmount         : Decimal(10,2) @readonly;
    notes               : String(256);
    status              : String(20) default 'D';       // D=Draft, P=Posted, E=Error
    statusCriticality   : Integer @readonly;             // virtual, computed by handler
    sapPONumber         : String(20) @readonly;
    sapPostMessage      : String(200) @readonly;
    items               : Composition of many PORequestItems on items.parent = $self;
}

@cds.persistence.skip
entity PORequestItems {
    key ID              : UUID;         // = CBO SAP_UUID
    parent              : Association to PORequests;
    requestNo           : String(20);   // FK logis ke header (CBO link via RequestNo)
    itemNo              : String(20);
    materialNo          : String(40);
    description         : String(200);
    quantity            : Decimal(10,2);
    uom                 : String(20) default 'PC';
    unitPrice           : Decimal(10,2);
    netAmount           : Decimal(10,2);
    currency            : String(20);
    plant               : String(20) default '1710';
    materialGroup       : String(20) default 'L001';
}
