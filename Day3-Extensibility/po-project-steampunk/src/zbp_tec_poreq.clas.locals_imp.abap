CLASS lhc_PORequest DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PUBLIC SECTION.
    " Buffer untuk saver class — UUID request yang perlu di-post ke SAP
    CLASS-DATA gt_post_keys TYPE TABLE OF sysuuid_x16.

  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING REQUEST requested_authorizations FOR PORequest
        RESULT result,

      setRequestNo FOR DETERMINE ON MODIFY
        IMPORTING keys FOR PORequest~setRequestNo,

      validateSupplier FOR VALIDATE ON SAVE
        IMPORTING keys FOR PORequest~validateSupplier,

      validateDeliveryDate FOR VALIDATE ON SAVE
        IMPORTING keys FOR PORequest~validateDeliveryDate,

      postToSAP FOR MODIFY
        IMPORTING keys FOR ACTION PORequest~postToSAP
        RESULT result.

ENDCLASS.

CLASS lhc_PORequest IMPLEMENTATION.

  METHOD get_global_authorizations.
    " No auth check for workshop
    LOOP AT requested_authorizations ASSIGNING FIELD-SYMBOL(<auth>).
      result = VALUE #( ( %tky = <auth>-%tky
                          %create = if_abap_behv=>auth-allowed
                          %update = if_abap_behv=>auth-allowed
                          %delete = if_abap_behv=>auth-allowed ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD setRequestNo.
    " Auto-generate Request Number (REQ-YYNNNN)
    READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
      ENTITY PORequest
        FIELDS ( RequestNo )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    " Find max existing number
    SELECT MAX( request_no ) FROM ztec_poreq INTO @DATA(lv_max_no).

    DATA(lv_year) = sy-datum+2(2).
    DATA(lv_seq) = 1.

    IF lv_max_no IS NOT INITIAL.
      DATA(lv_last_seq) = CONV i( lv_max_no+5(4) ).
      lv_seq = lv_last_seq + 1.
    ENDIF.

    LOOP AT requests ASSIGNING FIELD-SYMBOL(<req>)
      WHERE RequestNo IS INITIAL.
      DATA(lv_request_no) = |REQ-{ lv_year }{ lv_seq WIDTH = 4 ALIGN = RIGHT PAD = '0' }|.

      MODIFY ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
        ENTITY PORequest
          UPDATE FIELDS ( RequestNo Status OrderDate CompanyCode PurchasingOrg PurchasingGroup Currency )
          WITH VALUE #( (
            %tky         = <req>-%tky
            RequestNo    = lv_request_no
            Status       = COND #( WHEN <req>-Status IS INITIAL THEN 'D' ELSE <req>-Status )
            OrderDate    = COND #( WHEN <req>-OrderDate IS INITIAL THEN sy-datum ELSE <req>-OrderDate )
            CompanyCode  = COND #( WHEN <req>-CompanyCode IS INITIAL THEN '1710' ELSE <req>-CompanyCode )
            PurchasingOrg  = COND #( WHEN <req>-PurchasingOrg IS INITIAL THEN '1710' ELSE <req>-PurchasingOrg )
            PurchasingGroup = COND #( WHEN <req>-PurchasingGroup IS INITIAL THEN '001' ELSE <req>-PurchasingGroup )
            Currency       = COND #( WHEN <req>-Currency IS INITIAL THEN 'USD' ELSE <req>-Currency )
          ) ).

      lv_seq = lv_seq + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateSupplier.
    READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
      ENTITY PORequest
        FIELDS ( Supplier )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    LOOP AT requests ASSIGNING FIELD-SYMBOL(<req>).
      IF <req>-Supplier IS INITIAL.
        APPEND VALUE #(
          %tky = <req>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Supplier wajib diisi' )
          %element-Supplier = if_abap_behv=>mk-on
        ) TO reported-porequest.

        APPEND VALUE #( %tky = <req>-%tky ) TO failed-porequest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDeliveryDate.
    READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
      ENTITY PORequest
        FIELDS ( OrderDate DeliveryDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    LOOP AT requests ASSIGNING FIELD-SYMBOL(<req>).
      IF <req>-DeliveryDate IS NOT INITIAL AND <req>-DeliveryDate <= <req>-OrderDate.
        APPEND VALUE #(
          %tky = <req>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Delivery Date harus setelah Order Date' )
          %element-DeliveryDate = if_abap_behv=>mk-on
        ) TO reported-porequest.

        APPEND VALUE #( %tky = <req>-%tky ) TO failed-porequest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD postToSAP.
    " Read PO Request data
    READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
      ENTITY PORequest
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    LOOP AT requests ASSIGNING FIELD-SYMBOL(<req>).
      " Check status
      IF <req>-Status = 'P'.
        APPEND VALUE #(
          %tky = <req>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |PO sudah di-post sebagai { <req>-SAPPONumber }| )
        ) TO reported-porequest.
        APPEND VALUE #( %tky = <req>-%tky ) TO failed-porequest.
        CONTINUE.
      ENDIF.

      " BAPI call dilakukan di saver class (additional save) → lihat lsc_ZR_TEC_POREQ
      " Action ini hanya buffer key + set status pending
      APPEND <req>-%tky-RequestUUID TO gt_post_keys.

      " Set status 'X' (pending post) — final status di-update oleh saver
      MODIFY ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
        ENTITY PORequest
          UPDATE FIELDS ( Status SAPPostMessage )
          WITH VALUE #( (
            %tky           = <req>-%tky
            Status         = 'X'
            SAPPostMessage = 'Posting ke SAP...'
          ) ).

      " Read back for result
      READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
        ENTITY PORequest
          ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(updated).

      result = VALUE #( FOR upd IN updated (
        %tky   = upd-%tky
        %param = upd
      ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lhc_PORequestItem DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS:
      calcNetAmount FOR DETERMINE ON MODIFY
        IMPORTING keys FOR PORequestItem~calcNetAmount,

      calcHeaderTotal FOR DETERMINE ON MODIFY
        IMPORTING keys FOR PORequestItem~calcHeaderTotal.

ENDCLASS.

CLASS lhc_PORequestItem IMPLEMENTATION.

  METHOD calcNetAmount.
    READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
      ENTITY PORequestItem
        FIELDS ( Quantity UnitPrice )
        WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
      DATA(lv_net) = <item>-Quantity * <item>-UnitPrice.

      MODIFY ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
        ENTITY PORequestItem
          UPDATE FIELDS ( NetAmount )
          WITH VALUE #( (
            %tky      = <item>-%tky
            NetAmount = lv_net
          ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD calcHeaderTotal.
    " Get parent keys
    READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
      ENTITY PORequestItem
        BY \_PORequest
        FIELDS ( RequestUUID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(parents).

    " For each parent, recalculate total
    LOOP AT parents ASSIGNING FIELD-SYMBOL(<parent>).
      READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
        ENTITY PORequest BY \_Items
          FIELDS ( NetAmount )
          WITH VALUE #( ( %tky = <parent>-%tky ) )
        RESULT DATA(all_items).

      DATA(lv_total) = REDUCE decfloat34(
        INIT sum = CONV decfloat34( 0 )
        FOR item IN all_items
        NEXT sum = sum + item-NetAmount ).

      MODIFY ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
        ENTITY PORequest
          UPDATE FIELDS ( TotalAmount )
          WITH VALUE #( (
            %tky        = <parent>-%tky
            TotalAmount = lv_total
          ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lsc_ZR_TEC_POREQ DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_ZR_TEC_POREQ IMPLEMENTATION.

  METHOD save_modified.
    " Additional Save: Process pending postToSAP requests
    " Dipanggil SETELAH managed framework save data ke DB.
    " Di sini boleh CALL FUNCTION + BAPI_TRANSACTION_COMMIT.
    LOOP AT lhc_PORequest=>gt_post_keys INTO DATA(lv_uuid).

      " Read request header dari DB (sudah di-save oleh managed framework)
      SELECT SINGLE * FROM ztec_poreq
        WHERE request_uuid = @lv_uuid
        INTO @DATA(ls_req).
      IF sy-subrc <> 0. CONTINUE. ENDIF.

      " Read items
      SELECT * FROM ztec_poreqi
        WHERE request_uuid = @lv_uuid
        INTO TABLE @DATA(lt_items).

      " Build BAPI Header
      DATA(ls_header) = VALUE bapimepoheader(
        comp_code  = ls_req-company_code
        doc_type   = 'NB'
        vendor     = ls_req-supplier
        purch_org  = ls_req-purchasing_org
        pur_group  = ls_req-purchasing_group
        currency   = ls_req-currency
        doc_date   = ls_req-order_date
      ).
      DATA(ls_headerx) = VALUE bapimepoheaderx(
        comp_code  = abap_true
        doc_type   = abap_true
        vendor     = abap_true
        purch_org  = abap_true
        pur_group  = abap_true
        currency   = abap_true
        doc_date   = abap_true
      ).

      " Build BAPI Items
      DATA lt_po_items TYPE TABLE OF bapimepoitem.
      DATA lt_po_itemsx TYPE TABLE OF bapimepoitemx.
      DATA lv_item_no TYPE n LENGTH 5 VALUE '00000'.

      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<item>).
        lv_item_no += 10.
        APPEND VALUE bapimepoitem(
          po_item    = lv_item_no
          material   = <item>-material_no
          short_text = <item>-description
          quantity   = <item>-quantity
          po_unit    = <item>-uom
          net_price  = <item>-unit_price
          plant      = <item>-plant
          matl_group = <item>-material_group
        ) TO lt_po_items.
        APPEND VALUE bapimepoitemx(
          po_item    = lv_item_no
          po_itemx   = abap_true
          material   = abap_true
          short_text = abap_true
          quantity   = abap_true
          po_unit    = abap_true
          net_price  = abap_true
          plant      = abap_true
          matl_group = abap_true
        ) TO lt_po_itemsx.
      ENDLOOP.

      " Call BAPI_PO_CREATE1
      DATA lv_po_number TYPE bapimepoheader-po_number.
      DATA lt_return TYPE TABLE OF bapiret2.

      CALL FUNCTION 'BAPI_PO_CREATE1'
        EXPORTING
          poheader         = ls_header
          poheaderx        = ls_headerx
        IMPORTING
          exppurchaseorder = lv_po_number
        TABLES
          poitem           = lt_po_items
          poitemx          = lt_po_itemsx
          return           = lt_return.

      " Check Result
      DATA lv_has_error TYPE abap_bool VALUE abap_false.
      DATA lv_messages TYPE string.
      LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<ret>) WHERE type = 'E' OR type = 'A'.
        lv_has_error = abap_true.
        lv_messages = |{ lv_messages } { <ret>-message }|.
      ENDLOOP.

      IF lv_has_error = abap_true.
        " BAPI gagal → status Error
        UPDATE ztec_poreq SET
          status           = 'E',
          sap_post_message = @lv_messages
          WHERE request_uuid = @lv_uuid.
      ELSE.
        " BAPI sukses → commit + status Posted
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING wait = abap_true.

        UPDATE ztec_poreq SET
          status           = 'P',
          sap_po_number    = @lv_po_number,
          sap_post_message = @( |PO { lv_po_number } berhasil dibuat via BAPI (Embedded Steampunk)| )
          WHERE request_uuid = @lv_uuid.
      ENDIF.

    ENDLOOP.

    " Clear buffer
    CLEAR lhc_PORequest=>gt_post_keys.
  ENDMETHOD.

ENDCLASS.
