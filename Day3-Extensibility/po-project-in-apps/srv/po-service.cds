using { com.tecrise.procurement as db } from '../db/po-schema';

/**
 * PurchaseOrderService — In-App Extensibility Edition
 *
 * Endpoint yang sama dengan po-project: /po
 * Semua CRUD di-handle oleh custom ON handler → CBO OData V2
 */
service PurchaseOrderService @(path: '/po') {

    entity PORequests as projection on db.PORequests {*}
        actions {
            action postToSAP() returns {
                sapPONumber : String;
                status      : String;
                message     : String;
            };
        };

    entity PORequestItems as projection on db.PORequestItems;

    function getSAPSuppliers() returns array of {
        Supplier     : String;
        SupplierName : String;
        Country      : String;
    };

    function testSAPConnection() returns {
        ok      : Boolean;
        status  : Integer;
        message : String;
    };

    function testCBOConnection() returns {
        ok           : Boolean;
        headerCount  : Integer;
        itemCount    : Integer;
        message      : String;
    };
}
