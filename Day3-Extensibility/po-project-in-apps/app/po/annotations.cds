using PurchaseOrderService as service from '../../srv/po-service';

// ============================================================
// PORequests — List Report
// ============================================================

annotate service.PORequests with @(
    UI.SelectionFields: [
        status,
        supplier,
        orderDate
    ],

    UI.LineItem: [
        { Value: requestNo, Label: 'Request No' },
        { Value: description, Label: 'Description' },
        { Value: supplier, Label: 'Supplier' },
        { Value: supplierName, Label: 'Supplier Name' },
        {
            Value: status,
            Label: 'Status',
            Criticality: statusCriticality,
            ![@UI.Importance]: #High
        },
        {
            Value: totalAmount,
            Label: 'Total Amount',
            ![@UI.Importance]: #High
        },
        { Value: currency, Label: 'Currency' },
        { Value: sapPONumber, Label: 'SAP PO No.' },
        {
            $Type: 'UI.DataFieldForAction',
            Action: 'PurchaseOrderService.postToSAP',
            Label: '📤 Post to SAP',
            ![@UI.Importance]: #High
        }
    ]
);

// ============================================================
// PORequests — Object Page Header
// ============================================================

annotate service.PORequests with @(
    UI.HeaderInfo: {
        TypeName: 'Purchase Order Request',
        TypeNamePlural: 'Purchase Order Requests',
        Title: { Value: requestNo },
        Description: { Value: description }
    },

    UI.HeaderFacets: [
        {
            $Type: 'UI.ReferenceFacet',
            Target: '@UI.DataPoint#Status'
        },
        {
            $Type: 'UI.ReferenceFacet',
            Target: '@UI.DataPoint#TotalAmount'
        },
        {
            $Type: 'UI.ReferenceFacet',
            Target: '@UI.DataPoint#SAPPONumber'
        }
    ],

    UI.DataPoint#Status: {
        Value: status,
        Title: 'Status',
        Criticality: statusCriticality
    },
    UI.DataPoint#TotalAmount: {
        Value: totalAmount,
        Title: 'Total Amount'
    },
    UI.DataPoint#SAPPONumber: {
        Value: sapPONumber,
        Title: 'SAP PO Number'
    }
);

// ============================================================
// PORequests — Object Page Facets (Sections)
// ============================================================

annotate service.PORequests with @(
    UI.Facets: [
        {
            $Type: 'UI.CollectionFacet',
            Label: 'General Information',
            ID: 'GeneralInfo',
            Facets: [
                {
                    $Type: 'UI.ReferenceFacet',
                    Target: '@UI.FieldGroup#General',
                    Label: 'Basic Data'
                },
                {
                    $Type: 'UI.ReferenceFacet',
                    Target: '@UI.FieldGroup#Organization',
                    Label: 'SAP Organization'
                }
            ]
        },
        {
            $Type: 'UI.ReferenceFacet',
            Target: 'items/@UI.LineItem',
            Label: 'Items'
        },
        {
            $Type: 'UI.ReferenceFacet',
            Target: '@UI.FieldGroup#SAPIntegration',
            Label: 'SAP Integration Status'
        }
    ],

    UI.FieldGroup#General: {
        Data: [
            { Value: requestNo, Label: 'Request No' },
            { Value: description, Label: 'Description' },
            { Value: supplier, Label: 'Supplier' },
            { Value: supplierName, Label: 'Supplier Name' },
            { Value: orderDate, Label: 'Order Date' },
            { Value: deliveryDate, Label: 'Delivery Date' },
            { Value: currency, Label: 'Currency' },
            { Value: totalAmount, Label: 'Total Amount' },
            { Value: notes, Label: 'Notes' }
        ]
    },

    UI.FieldGroup#Organization: {
        Data: [
            { Value: companyCode, Label: 'Company Code' },
            { Value: purchasingOrg, Label: 'Purchasing Org' },
            { Value: purchasingGroup, Label: 'Purchasing Group' }
        ]
    },

    UI.FieldGroup#SAPIntegration: {
        Data: [
            {
                Value: status,
                Label: 'Status',
                Criticality: statusCriticality
            },
            { Value: sapPONumber, Label: 'SAP PO Number' },
            { Value: sapPostMessage, Label: 'SAP Post Message' }
        ]
    }
);

// ============================================================
// PORequestItems — Line Item Table (on Object Page)
// ============================================================

annotate service.PORequestItems with @(
    UI.LineItem: [
        { Value: itemNo, Label: 'Item No' },
        { Value: materialNo, Label: 'Material No' },
        { Value: description, Label: 'Description' },
        { Value: quantity, Label: 'Quantity' },
        { Value: uom, Label: 'UoM' },
        { Value: unitPrice, Label: 'Unit Price' },
        { Value: netAmount, Label: 'Net Amount' },
        { Value: currency, Label: 'Currency' },
        { Value: plant, Label: 'Plant' },
        { Value: materialGroup, Label: 'Material Group' }
    ],

    UI.HeaderInfo: {
        TypeName: 'Item',
        TypeNamePlural: 'Items',
        Title: { Value: itemNo },
        Description: { Value: description }
    }
);
