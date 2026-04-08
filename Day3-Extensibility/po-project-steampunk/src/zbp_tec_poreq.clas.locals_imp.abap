CLASS lhc_PORequest DEFINITION INHERITING FROM cl_abap_behavior_handler.

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

      " TODO: Call MM_PUR_PO_MAINT_V2_SRV or BAPI_PO_CREATE1
      " For workshop, simulate success:
      DATA(lv_po_number) = |45000{ sy-datum+4(4) }|.
      DATA(lv_message) = |PO { lv_po_number } berhasil dibuat via RAP (Embedded Steampunk)|.

      " Update status
      MODIFY ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
        ENTITY PORequest
          UPDATE FIELDS ( Status SAPPONumber SAPPostMessage )
          WITH VALUE #( (
            %tky           = <req>-%tky
            Status         = 'P'
            SAPPONumber    = lv_po_number
            SAPPostMessage = lv_message
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
