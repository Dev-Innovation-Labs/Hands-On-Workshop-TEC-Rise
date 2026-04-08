using PurchaseOrderService as service from '../../srv/po-service';

// ============================================
// PO REQUESTS — List Report
// ============================================
annotate service.PORequests with @(

    UI.SelectionFields: [
        status, supplier, orderDate
    ],

    UI.LineItem: [
        { $Type: 'UI.DataField', Value: requestNo,    Label: 'Request No',     ![@UI.Importance]: #High },
        { $Type: 'UI.DataField', Value: description,   Label: 'Description',    ![@UI.Importance]: #High },
        { $Type: 'UI.DataField', Value: supplier,      Label: 'Supplier ID' },
        { $Type: 'UI.DataField', Value: supplierName,  Label: 'Supplier Name' },
        { $Type: 'UI.DataField', Value: status,        Label: 'Status',         Criticality: statusCriticality },
        { $Type: 'UI.DataField', Value: totalAmount,   Label: 'Total Amount' },
        { $Type: 'UI.DataField', Value: currency,      Label: 'Currency' },
        { $Type: 'UI.DataField', Value: sapPONumber,   Label: 'SAP PO No' },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'PurchaseOrderService.postToSAP',
            Label : '📤 Post to SAP',
            ![@UI.Importance]: #High
        }
    ],

    UI.PresentationVariant: {
        SortOrder: [{ Property: requestNo, Descending: true }]
    }
);

// ============================================
// PO REQUESTS — Object Page Header
// ============================================
annotate service.PORequests with @(

    UI.HeaderInfo: {
        TypeName       : 'PO Request',
        TypeNamePlural : 'PO Requests',
        Title          : { $Type: 'UI.DataField', Value: requestNo },
        Description    : { $Type: 'UI.DataField', Value: description }
    },

    UI.HeaderFacets: [
        { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Status' },
        { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#TotalAmount' },
        { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#SAPPONumber' }
    ],

    UI.DataPoint #Status: {
        Value      : status,
        Title      : 'Status',
        Criticality: statusCriticality
    },

    UI.DataPoint #TotalAmount: {
        Value: totalAmount,
        Title: 'Total Amount'
    },

    UI.DataPoint #SAPPONumber: {
        Value: sapPONumber,
        Title: 'SAP PO Number'
    },

    // POST TO SAP button di Object Page header
    UI.Identification: [
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'PurchaseOrderService.postToSAP',
            Label : '📤 Post to SAP'
        }
    ]
);

// ============================================
// PO REQUESTS — Object Page Sections
// ============================================
annotate service.PORequests with @(

    UI.Facets: [
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'General Information',
            ID    : 'GeneralInfo',
            Target: '@UI.FieldGroup#GeneralInfo'
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'SAP Organization',
            ID    : 'SAPOrg',
            Target: '@UI.FieldGroup#SAPOrg'
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Items',
            ID    : 'Items',
            Target: 'items/@UI.LineItem'
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'SAP Integration Status',
            ID    : 'SAPStatus',
            Target: '@UI.FieldGroup#SAPStatus'
        }
    ],

    UI.FieldGroup #GeneralInfo: {
        Data: [
            { $Type: 'UI.DataField', Value: requestNo,    Label: 'Request No' },
            { $Type: 'UI.DataField', Value: description,   Label: 'Description' },
            { $Type: 'UI.DataField', Value: supplier,      Label: 'Supplier ID' },
            { $Type: 'UI.DataField', Value: supplierName,  Label: 'Supplier Name' },
            { $Type: 'UI.DataField', Value: orderDate,     Label: 'Order Date' },
            { $Type: 'UI.DataField', Value: deliveryDate,  Label: 'Delivery Date' },
            { $Type: 'UI.DataField', Value: currency,      Label: 'Currency' },
            { $Type: 'UI.DataField', Value: totalAmount,   Label: 'Total Amount' },
            { $Type: 'UI.DataField', Value: notes,         Label: 'Notes' }
        ]
    },

    UI.FieldGroup #SAPOrg: {
        Data: [
            { $Type: 'UI.DataField', Value: companyCode,    Label: 'Company Code' },
            { $Type: 'UI.DataField', Value: purchasingOrg,  Label: 'Purchasing Org' },
            { $Type: 'UI.DataField', Value: purchasingGroup, Label: 'Purchasing Group' }
        ]
    },

    UI.FieldGroup #SAPStatus: {
        Data: [
            { $Type: 'UI.DataField', Value: status,         Label: 'Status', Criticality: statusCriticality },
            { $Type: 'UI.DataField', Value: sapPONumber,    Label: 'SAP PO Number' },
            { $Type: 'UI.DataField', Value: sapPostDate,    Label: 'Posted at' },
            { $Type: 'UI.DataField', Value: sapPostMessage, Label: 'SAP Response' }
        ]
    }
);

// ============================================
// PO REQUEST ITEMS — Table in Object Page
// ============================================
annotate service.PORequestItems with @(
    UI.LineItem: [
        { $Type: 'UI.DataField', Value: itemNo,        Label: 'Item' },
        { $Type: 'UI.DataField', Value: materialNo,    Label: 'Material' },
        { $Type: 'UI.DataField', Value: description,    Label: 'Description' },
        { $Type: 'UI.DataField', Value: quantity,       Label: 'Qty' },
        { $Type: 'UI.DataField', Value: uom,            Label: 'UoM' },
        { $Type: 'UI.DataField', Value: unitPrice,      Label: 'Unit Price' },
        { $Type: 'UI.DataField', Value: netAmount,      Label: 'Net Amount' },
        { $Type: 'UI.DataField', Value: currency,       Label: 'Curr' },
        { $Type: 'UI.DataField', Value: plant,          Label: 'Plant' },
        { $Type: 'UI.DataField', Value: materialGroup,  Label: 'Mat. Group' }
    ],

    UI.HeaderInfo: {
        TypeName       : 'Item',
        TypeNamePlural : 'Items'
    }
);
