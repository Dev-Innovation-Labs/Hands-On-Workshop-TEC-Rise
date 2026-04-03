using CatalogService as service from '../../srv/catalog-service';

// ============================================================
// BOOKS — List Report & Object Page Annotations
// ============================================================

// ---- TAB FILTER BAR ----
annotate service.Books with @UI.SelectionFields: [
    price,
    stock,
    author_ID
];

// ---- LIST REPORT TABLE COLUMNS ----
annotate service.Books with @UI.LineItem: [
    {
        $Type : 'UI.DataField',
        Value : title,
        Label : 'Title'
    },
    {
        $Type : 'UI.DataField',
        Value : authorName,
        Label : 'Author'
    },
    {
        $Type : 'UI.DataField',
        Value : price,
        Label : 'Price'
    },
    {
        $Type : 'UI.DataField',
        Value : currency_code,
        Label : 'Currency'
    },
    {
        $Type       : 'UI.DataField',
        Value       : stock,
        Label       : 'Stock',
        Criticality : stockCriticality
    }
];

// ---- OBJECT PAGE HEADER ----
annotate service.Books with @UI.HeaderInfo: {
    TypeName       : 'Book',
    TypeNamePlural : 'Books',
    Title          : { $Type: 'UI.DataField', Value: title },
    Description    : { $Type: 'UI.DataField', Value: authorName }
};

// ---- OBJECT PAGE SECTIONS ----
annotate service.Books with @UI.Facets: [
    {
        $Type  : 'UI.ReferenceFacet',
        ID     : 'GeneralInfo',
        Label  : 'General Information',
        Target : '@UI.FieldGroup#GeneralInfo'
    },
    {
        $Type  : 'UI.ReferenceFacet',
        ID     : 'Description',
        Label  : 'Description',
        Target : '@UI.FieldGroup#Description'
    }
];

annotate service.Books with @UI.FieldGroup #GeneralInfo: {
    Label : 'General Information',
    Data  : [
        { $Type: 'UI.DataField', Value: title,       Label: 'Title'    },
        { $Type: 'UI.DataField', Value: authorName,  Label: 'Author'   },
        { $Type: 'UI.DataField', Value: price,       Label: 'Price'    },
        { $Type: 'UI.DataField', Value: stock,       Label: 'Stock'    }
    ]
};

annotate service.Books with @UI.FieldGroup #Description: {
    Label : 'Description',
    Data  : [
        { $Type: 'UI.DataField', Value: descr, Label: 'Description' }
    ]
};

// ---- FIELD LABELS ----
annotate service.Books with {
    title       @Common.Label: 'Title';
    authorName  @Common.Label: 'Author';
    price       @Common.Label: 'Price';
    stock       @Common.Label: 'Stock';
    descr       @Common.Label: 'Description';
}
