using { com.tecrise.procurement as po } from '../db/po-schema';

service PurchaseOrderService @(path: '/po') {

    entity PORequests as projection on po.PORequests
        actions {
            // Tombol "Post to SAP" — kirim PO request ke S/4HANA real
            @(
                cds.odata.bindingparameter.name: '_it',
                Common.SideEffects: {
                    TargetProperties: ['_it/status','_it/statusCriticality','_it/sapPONumber','_it/sapPostDate','_it/sapPostMessage']
                }
            )
            action postToSAP() returns {
                sapPONumber : String;
                status      : String;
                message     : String;
            };
        };

    entity PORequestItems as projection on po.PORequestItems;

    // Function: Fetch suppliers dari SAP real
    function getSAPSuppliers() returns array of {
        Supplier     : String;
        SupplierName : String;
        Country      : String;
    };

    // Function: Test koneksi SAP
    function testSAPConnection() returns {
        ok      : Boolean;
        status  : Integer;
        message : String;
    };
}
