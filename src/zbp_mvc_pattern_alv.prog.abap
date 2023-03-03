********************************************************************************
* GitHub Repository : https://www.github.com/brkcnplt
* Linkedin          : https://www.linkedin.com/in/berkcanpolat/
********************************************************************************
* Simple ALV via MVC Pattern
* Berk Can Polat - 03.03.2023
********************************************************************************
REPORT zbp_mvc_pattern_alv.


TABLES: crmd_orderadm_h.


SELECTION-SCREEN: BEGIN OF BLOCK b1.
SELECT-OPTIONS: so_objid FOR crmd_orderadm_h-object_id,
                so_date FOR crmd_orderadm_h-posting_date.
SELECTION-SCREEN: END OF BLOCK b1.



CLASS lcl_selection DEFINITION.
  PUBLIC SECTION.

    TYPES: ty_objid_range TYPE RANGE OF crmt_object_id_db,
           ty_date_range  TYPE RANGE OF crmd_orderadm_h-posting_date.


    DATA: s_objid TYPE  ty_objid_range,
          s_date  TYPE  ty_date_range.

    METHODS: get_screen IMPORTING iv_objid        TYPE ty_objid_range
                                  iv_posting_date TYPE ty_date_range.
ENDCLASS.
CLASS lcl_selection IMPLEMENTATION.

  METHOD get_screen.
    me->s_objid = iv_objid.
    me->s_date = iv_posting_date.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_fetch_data DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_orderh,
             guid         TYPE crmd_orderadm_h-guid,
             object_id    TYPE crmd_orderadm_h-object_id,
             process_type TYPE crmd_orderadm_h-process_type,
             posting_date TYPE crmd_orderadm_h-posting_date,
           END OF ty_orderh.
    DATA: lt_orderh TYPE TABLE OF ty_orderh,
          ls_orderh TYPE ty_orderh.

    TYPES: BEGIN OF ty_custh,
             guid         TYPE crmd_customer_h-guid,
             zzafld00000p TYPE crmd_customer_h-zzafld00000p,
             zzafld00000q TYPE crmd_customer_h-zzafld00000q,
           END OF ty_custh.
    DATA: lt_custh TYPE TABLE OF ty_custh,
          ls_custh TYPE ty_custh.

    TYPES: BEGIN OF ty_outtab,
             guid         TYPE crmd_orderadm_h-guid,
             object_id    TYPE crmd_orderadm_h-object_id,
             process_type TYPE crmd_orderadm_h-process_type,
             posting_date TYPE crmd_orderadm_h-posting_date,
             zzafld00000p TYPE crmd_customer_h-zzafld00000p,
             zzafld00000q TYPE crmd_customer_h-zzafld00000q,
           END OF ty_outtab.
    DATA: lt_outtab TYPE TABLE OF ty_outtab,
          ls_outtab TYPE ty_outtab.

    DATA: lr_selection TYPE REF TO lcl_selection.

    METHODS: constructor IMPORTING ir_selection TYPE REF TO lcl_selection,
      get_data,
      arrange_data.
ENDCLASS.

CLASS lcl_fetch_data IMPLEMENTATION.

  METHOD constructor.
    me->lr_selection = ir_selection.
  ENDMETHOD.

  METHOD get_data.

    SELECT guid
           object_id
           process_type
           posting_date
      FROM crmd_orderadm_h
      INTO TABLE me->lt_orderh
      WHERE object_id IN lr_selection->s_objid
      AND posting_date IN lr_selection->s_date.

    IF me->lt_orderh[] IS NOT INITIAL.
      SELECT guid
             zzafld00000p
             zzafld00000q
        FROM crmd_customer_h
        INTO TABLE me->lt_custh
        FOR ALL ENTRIES IN me->lt_orderh
        WHERE guid = me->lt_orderh-guid.
    ENDIF.

    me->arrange_data( ).

  ENDMETHOD.

  METHOD arrange_data.

    LOOP AT me->lt_orderh INTO me->ls_orderh.
      ls_outtab-guid = me->ls_orderh-guid.
      ls_outtab-object_id = me->ls_orderh-object_id.
      ls_outtab-posting_date = me->ls_orderh-posting_date.
      ls_outtab-process_type = me->ls_orderh-process_type.


      READ TABLE me->lt_custh INTO me->ls_custh WITH KEY
                                       guid = me->ls_orderh-guid.
      IF sy-subrc EQ 0.
        ls_outtab-zzafld00000p = me->ls_custh-zzafld00000p.
        ls_outtab-zzafld00000q = me->ls_custh-zzafld00000q.
      ENDIF.


      IF ls_outtab-zzafld00000p IS NOT INITIAL OR ls_outtab-zzafld00000q IS NOT INITIAL.
        APPEND ls_outtab TO lt_outtab.
        CLEAR: ls_outtab.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
**********************************************************************

CLASS lcl_display DEFINITION.
  PUBLIC SECTION.
    DATA: lr_fetch TYPE REF TO lcl_fetch_data.
    DATA: lr_alv TYPE REF TO cl_salv_table.

    METHODS: constructor IMPORTING ir_fetch TYPE REF TO lcl_fetch_data,
      display_alv.


ENDCLASS.

CLASS lcl_display IMPLEMENTATION.
  METHOD constructor.
    me->lr_fetch = ir_fetch.
  ENDMETHOD.

  METHOD display_alv.
    DATA: lx_msg TYPE REF TO cx_salv_msg.

    TRY .
        cl_salv_table=>factory( IMPORTING r_salv_table = lr_alv
                                CHANGING t_table = lr_fetch->lt_outtab ).

      CATCH cx_salv_msg INTO lx_msg  .
    ENDTRY.

    lr_alv->display( ).
  ENDMETHOD.


ENDCLASS.

START-OF-SELECTION.


  DATA(lr_selection) = NEW lcl_selection( ).
  DATA(lr_fetch_data) = NEW lcl_fetch_data( ir_selection = lr_selection  ).
  DATA(lr_display) = NEW lcl_display( ir_fetch = lr_fetch_data ).


  lr_selection->get_screen( EXPORTING iv_objid = so_objid[]
                                      iv_posting_date = so_date[] ).

  lr_fetch_data->get_data( ).

  lr_display->display_alv( ).
