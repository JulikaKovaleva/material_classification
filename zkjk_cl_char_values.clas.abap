class ZKJK_CL_CHAR_VALUES definition
  public
  final
  create public .

public section.

  types:
    BEGIN OF mt_s_ausp_cache,
        objek TYPE ausp-objek,
        atinn TYPE ausp-atinn,
        klart TYPE ausp-klart,
        atwrt TYPE ausp-atwrt,
        atflv TYPE ausp-atflv,
*        atbez TYPE ausp-atbez,
      END OF mt_s_ausp_cache .
  types:
    BEGIN OF mt_s_cawnt_cache,
        atinn TYPE ausp-atinn,
        atwrt TYPE ausp-atwrt,
        atwtb TYPE cawnt-atwtb,
      END OF mt_s_cawnt_cache .

  class-data:
    mt_ausp_cache TYPE HASHED TABLE OF mt_s_ausp_cache WITH UNIQUE KEY objek atinn klart .
  class-data:
    mt_cawnt_cache TYPE HASHED TABLE OF mt_s_cawnt_cache WITH UNIQUE KEY atinn atwrt .
  class-data:
    mt_tcla_cache TYPE SORTED TABLE OF tcla WITH UNIQUE KEY klart .
  class-data MV_AUTO_CACHE type ABAP_BOOL .

  class-methods CACHE_TABLES
    importing
      !IT_CHARS type ZKJK_TT_CLASS_CHAR_SORT
      !IT_OBJECTS type ZKJK_TT_CLASSES
      !IT_MATNR type ZKJK_TT_MATNR_SORTED optional .
  class-methods READ_VALUE
    importing
      !IV_OBTAB type TABELLE
      !IV_OBJEK type AUSP-OBJEK
      !IV_ATINN type CLIKE
      !IV_KLART type AUSP-KLART
    exporting
      !EV_ATWTB type CAWNT-ATWTB
      !EV_ATFLV type AUSP-ATFLV
      !EV_ATWRT type AUSP-ATWRT
      !EV_DATUM type SY-DATUM .
  class-methods GET_MARA
    exporting
      !ET_MARA type ZKJK_TT_MARA_SORTED .
protected section.

  class-methods FLOAT_TO_DATE
    importing
      !IV_FLOAT type AUSP-ATFLV
    returning
      value(RV_DATE) type SY-DATUM .
  class-methods GET_OBJEK
    importing
      !IV_OBTAB type TABELLE
      !IV_OBJEK type AUSP-OBJEK
      !IV_KLART type AUSP-KLART
    returning
      value(RV_OBJEK) type AUSP-OBJEK
    exceptions
      NOT_FOUND .
  class-methods READ_TCLA
    importing
      !IV_KLART type TCLA-KLART
    returning
      value(RS_TCLA) type TCLA
    exceptions
      NOT_FOUND .
  class-methods READ_VALUE_CHAR
    importing
      !IV_ATINN type AUSP-ATINN
      !IV_ATWRT type AUSP-ATWRT
    returning
      value(RV_ATWTB) type CAWNT-ATWTB .
private section.

  types:
    BEGIN OF mt_s_atbez,
      atinn TYPE atinn,
      atbez TYPE atbez,
    END OF mt_s_atbez .
  types:
    BEGIN OF mt_s_fields,
      atfel TYPE atfel,
    END OF mt_s_fields .
  types:
    mt_t_fields TYPE SORTED TABLE OF mt_s_fields WITH UNIQUE KEY atfel .
  types:
    BEGIN OF mt_s_tables,
      attab TYPE attab,
      atfel TYPE mt_t_fields,
      atfel_string type string,
    END OF mt_s_tables .
  types:
    mt_t_tables TYPE SORTED TABLE OF mt_s_tables WITH UNIQUE KEY attab .

  class-data:
    mt_atbez TYPE SORTED TABLE OF mt_s_atbez WITH UNIQUE KEY atinn .
  class-data MV_USE_CACHE_ONLY type ABAP_BOOL value ABAP_FALSE ##NO_TEXT.
  class-data:
    mt_mara TYPE SORTED TABLE OF mara WITH UNIQUE KEY matnr .
  class-data MT_CHARS type ZKJK_TT_CLASS_CHAR_SORT .
  class-data MT_REF_TABLES_FIELDS type MT_T_TABLES .

  class-methods CACHE_BD_TABLES .
ENDCLASS.



CLASS ZKJK_CL_CHAR_VALUES IMPLEMENTATION.


  METHOD cache_bd_tables.

*    DATA: lv_tabname    TYPE tabname,
*
**          ls_atfel      TYPE mt_s_atfel,
*
*          lt_key_fields TYPE uiss_t_field.
*
*    "По таблице с именами и полями таблиц пройти
*    LOOP AT mt_ref_tables_fields ASSIGNING FIELD-SYMBOL(<ls_tables>).
*      "Для таблицы получить ключевые поля
*      lv_tabname = <ls_tables>-attab.
*      CALL FUNCTION 'DD_GET_KEYFIELDS_FROM_NAMETAB'
*        TABLES
*          all_fields_tab = lv_tabname
*          key_fldnam_tab = lt_key_fields.
*
*      "Сформировать условие для селекта
*      LOOP AT lt_key_fields ASSIGNING FIELD-SYMBOL(<ls_key_fields>) .
*
*        "если вдруг, ключевых полей нет среди полей для признаков, добавляем их
*        READ TABLE <ls_tables>-atfel ASSIGNING FIELD-SYMBOL(<ls_atfel>)
*          WITH TABLE KEY atfel = <ls_key_fields>-name.
*        IF sy-subrc IS NOT INITIAL.
*          CLEAR ls_atfel.
*          ls_atfel-atfel = <ls_key_fields>-name.
*        ENDIF.
*        "Нужно определить типы ключей, для того, чтобы значение ключа выделить из строки
*        DATA(lv_comp_name) = <ls_tables>-attab && '-' && <ls_key_fields>-name.
*        DATA(lo_type_descr) = cl_abap_typedescr=>describe_by_name( lv_comp_name ).
*        "по длинне текущего ключа откусить потом кусок от идентификатора объекта
*
*      ENDLOOP.
*
*    ENDLOOP.

  ENDMETHOD.


  METHOD cache_tables.
    CONSTANTS
      lc_mafid TYPE ausp-mafid VALUE 'O'.

    TYPES:
      BEGIN OF lt_s_atfel,
        atfel TYPE atfel,
      END OF lt_s_atfel,
      lt_t_atfel TYPE SORTED TABLE OF lt_s_atfel WITH UNIQUE KEY atfel.

    DATA:
      lt_ausp_cache       TYPE TABLE OF mt_s_ausp_cache,
      lt_cawnt_cache      TYPE TABLE OF mt_s_cawnt_cache,
      lt_atbez            TYPE TABLE OF mt_s_atbez,
      lt_atfel            TYPE TABLE OF lt_t_atfel,

      ltr_atinn           TYPE RANGE OF atinn,

      ls_atbez            LIKE LINE OF mt_atbez,
      ls_ausp_cache       LIKE LINE OF lt_ausp_cache,
      ls_cawnt_cache      TYPE mt_s_cawnt_cache,
      ls_atfel            TYPE lt_s_atfel,
      ls_ref_table_fields LIKE LINE OF mt_ref_tables_fields,
      ls_fields           TYPE mt_s_fields,

      lv_atinn            TYPE atinn.

    CHECK it_objects IS NOT INITIAL.

    LOOP AT it_chars ASSIGNING FIELD-SYMBOL(<ls_chars>).
      APPEND VALUE #( sign = 'I' option = 'EQ' low = <ls_chars>-atinn ) TO ltr_atinn.
*--------------------------------------------------------------------*
      "собрать ссылочные таблицы, ссылочные поля для каждой записи
*      READ TABLE mt_ref_tables_fields ASSIGNING FIELD-SYMBOL(<ls_table>)
*        WITH TABLE KEY attab = <ls_chars>-attab.
*      "Если такой таблицы еще не было, добавляем ее
*      IF sy-subrc IS NOT INITIAL.
*        CLEAR ls_ref_table_fields.
*        ls_ref_table_fields-attab = <ls_chars>-attab.
*        "заодно собираем строку полей
*        ls_ref_table_fields-atfel_string = <ls_chars>-atfel.
*        "плюс сразу добавляем первое поле таблицы
*        ls_fields-atfel = <ls_chars>-atfel.
*        INSERT ls_fields INTO TABLE ls_ref_table_fields-atfel.
*        INSERT ls_ref_table_fields INTO TABLE mt_ref_tables_fields.
*      ELSE.
*        "Если такая таблица уже была, просто в существующую строку добавляем поле
*        "если такого еще не было
*        READ TABLE <ls_table>-atfel ASSIGNING FIELD-SYMBOL(<ls_field>)
*          WITH TABLE KEY atfel = <ls_chars>-atfel.
*        IF sy-subrc IS NOT INITIAL.
*          CLEAR ls_fields.
*          ls_fields-atfel = <ls_chars>-atfel.
*          INSERT ls_fields INTO TABLE <ls_table>-atfel.
*          <ls_table>-atfel_string = <ls_table>-atfel_string && `, ` && <ls_chars>-atfel.
*        ENDIF.
*      ENDIF.
*      "В итоге собралась таблица "имя таблицы - таблица полей"
*--------------------------------------------------------------------*
    ENDLOOP.

    "Сохранить признаки, чтобы потому можно было выбрать ссылочные поля
    mt_chars = it_chars.

    "Закешировали  ausp
    SELECT objek atinn klart atwrt atflv
      INTO TABLE lt_ausp_cache
      FROM ausp
      FOR ALL ENTRIES IN it_objects
      WHERE objek EQ it_objects-objek
        AND atinn IN ltr_atinn
        AND mafid EQ lc_mafid
        AND klart EQ it_objects-klart.

    LOOP AT lt_ausp_cache ASSIGNING FIELD-SYMBOL(<ls_ausp_cache>).
      ls_cawnt_cache-atinn = <ls_ausp_cache>-atinn.
      ls_cawnt_cache-atwrt = <ls_ausp_cache>-atwrt.
      COLLECT ls_cawnt_cache INTO lt_cawnt_cache.
      INSERT <ls_ausp_cache> INTO TABLE mt_ausp_cache.
    ENDLOOP.

    "Закешировать таблицу cawnt

    SELECT cawn~atinn cawn~atwrt cawnt~atwtb
      UP TO 1 ROWS
      INTO TABLE lt_cawnt_cache
      FROM cawn
      JOIN cawnt ON cawnt~atinn EQ cawn~atinn
                AND cawnt~spras EQ sy-langu
                AND cawnt~atzhl EQ cawn~atzhl
                AND cawnt~adzhl EQ cawn~adzhl
      FOR ALL ENTRIES IN lt_cawnt_cache
      WHERE cawn~atinn EQ lt_cawnt_cache-atinn
        AND cawn~atwrt EQ lt_cawnt_cache-atwrt.

    LOOP AT lt_cawnt_cache ASSIGNING FIELD-SYMBOL(<ls_cawnt>).
      INSERT <ls_cawnt> INTO TABLE mt_cawnt_cache.
    ENDLOOP.

    "mara
    IF it_matnr IS NOT INITIAL.
      SELECT *
        FROM mara
        INTO TABLE mt_mara
        FOR ALL ENTRIES IN it_matnr
        WHERE matnr = it_matnr-matnr.
    ENDIF.

*--------------------------------------------------------------------*
*    "Закешировать таблицы объектов
*    "Для реализованной задачи таблица будет одна, но в теории может быть много
*    "Пока для одной
*    IF lines( mt_ref_tables_fields ) = 1.
**      cache_bd_table( ).
*    ELSE.
*      cache_bd_tables( ).
*    ENDIF.
*--------------------------------------------------------------------*
  ENDMETHOD.


  METHOD float_to_date.
    DATA:
     lv_atwrt TYPE ausp-atwrt.

    CALL FUNCTION 'CTCV_CONVERT_FLOAT_TO_DATE'
      EXPORTING
        float = iv_float
      IMPORTING
        date  = lv_atwrt.

    rv_date = lv_atwrt.

  ENDMETHOD.


  METHOD get_mara.
    et_mara = mt_mara.
  ENDMETHOD.


  METHOD get_objek.
    DATA ls_tcla TYPE tcla.

    CALL METHOD read_tcla
      EXPORTING
        iv_klart = iv_klart
      RECEIVING
        rs_tcla  = ls_tcla
      EXCEPTIONS
        OTHERS   = 4.
    IF sy-subrc <> 0.
      RAISE not_found.
    ENDIF.

    IF ls_tcla-aeblgzuord EQ space OR
       ls_tcla-multobj    EQ space.
      rv_objek = iv_objek.
      RETURN.
    ENDIF.

    SELECT SINGLE cuobj
      INTO rv_objek
      FROM inob
      WHERE obtab EQ iv_obtab
        AND objek EQ iv_objek  ##WARN_OK
        AND klart EQ iv_klart.
    IF sy-subrc <> 0.
      RAISE not_found.
    ENDIF.
  ENDMETHOD.


  METHOD read_tcla.

    READ TABLE mt_tcla_cache INTO rs_tcla WITH TABLE KEY klart = iv_klart.
    CHECK sy-subrc NE 0.
    SELECT SINGLE *
      INTO rs_tcla
      FROM tcla
      WHERE klart EQ iv_klart.
    IF sy-subrc EQ 0.
      INSERT rs_tcla INTO TABLE mt_tcla_cache.
    ELSE.
      RAISE not_found.
    ENDIF.

  ENDMETHOD.


  METHOD read_value.
    DATA lv_atinn TYPE ausp-atinn.
    DATA lv_objek TYPE ausp-objek.
    DATA ls_cache LIKE LINE OF mt_ausp_cache.
    FIELD-SYMBOLS <ls_cache> LIKE LINE OF mt_ausp_cache.

    IF iv_atinn CO '0123456789'.
      lv_atinn = iv_atinn.
    ELSE.
      CALL FUNCTION 'CONVERSION_EXIT_ATINN_INPUT'
        EXPORTING
          input  = iv_atinn
        IMPORTING
          output = lv_atinn.
    ENDIF.
    READ TABLE mt_ausp_cache ASSIGNING <ls_cache>
      WITH TABLE KEY objek = iv_objek
                     atinn = lv_atinn
                     klart = iv_klart.
    IF sy-subrc EQ 0.
      ev_atwrt = <ls_cache>-atwrt.
      ev_atflv = <ls_cache>-atflv.
      IF ev_atwtb IS REQUESTED.
        ev_atwtb = read_value_char( iv_atinn = lv_atinn iv_atwrt = ev_atwrt ).
      ENDIF.
      IF ev_datum IS REQUESTED.
        ev_datum = float_to_date( ev_atflv ).
      ENDIF.
      RETURN.
    ENDIF.

    CHECK mv_use_cache_only EQ abap_false.

    DO 1 TIMES.
      CALL METHOD get_objek
        EXPORTING
          iv_obtab = iv_obtab
          iv_objek = iv_objek
          iv_klart = iv_klart
        RECEIVING
          rv_objek = lv_objek
        EXCEPTIONS
          OTHERS   = 4.
      CHECK sy-subrc EQ 0.

      SELECT SINGLE atwrt atflv ##WARN_OK
        INTO (ev_atwrt, ev_atflv)
        FROM ausp
        WHERE objek EQ lv_objek
          AND atinn EQ lv_atinn
          AND klart EQ iv_klart.
      IF sy-subrc <> 0.
        CLEAR: ev_atwrt, ev_atflv.
        CONTINUE.
      ENDIF.
    ENDDO.

    IF ev_atwtb IS REQUESTED.
      ev_atwtb = read_value_char( iv_atinn = lv_atinn iv_atwrt = ev_atwrt ).
    ENDIF.
    IF ev_datum IS REQUESTED.
      ev_datum = float_to_date( ev_atflv ).
    ENDIF.

    "Если выходное значение не прочиталось, оно может храниться в ссылочной таблице
    IF ev_atwtb IS INITIAL AND ev_datum IS INITIAL AND ev_atflv IS INITIAL.
      "определить ссылочное поле
      READ TABLE mt_chars ASSIGNING FIELD-SYMBOL(<ls_chars>)
        WITH TABLE KEY atinn = lv_atinn.
      IF sy-subrc IS INITIAL AND <ls_chars>-atfel IS NOT INITIAL.
        "читаем нужное поле для объекта
        READ TABLE mt_mara ASSIGNING FIELD-SYMBOL(<ls_mara>)
          WITH TABLE KEY matnr = iv_objek.
        IF sy-subrc IS INITIAL.
          ASSIGN COMPONENT <ls_chars>-atfel OF STRUCTURE <ls_mara> TO FIELD-SYMBOL(<lv_comp>).
          IF sy-subrc IS INITIAL.
            ev_atwtb = <lv_comp>.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    IF mv_auto_cache EQ abap_true.
      ls_cache-objek = iv_objek.
      ls_cache-atinn = lv_atinn.
      ls_cache-klart = iv_klart.
      ls_cache-atwrt = ev_atwrt.
      ls_cache-atflv = ev_atflv.
      INSERT ls_cache INTO TABLE mt_ausp_cache.
    ENDIF.
  ENDMETHOD.


  METHOD read_value_char.
    DATA ls_cache LIKE LINE OF mt_cawnt_cache.
    FIELD-SYMBOLS <ls_cache> LIKE LINE OF mt_cawnt_cache.

    READ TABLE mt_cawnt_cache ASSIGNING <ls_cache> WITH TABLE KEY atinn = iv_atinn
                                                                  atwrt = iv_atwrt.
    IF sy-subrc EQ 0.
      rv_atwtb = <ls_cache>-atwtb.
      RETURN.
    ENDIF.

    SELECT cawnt~atwtb
      UP TO 1 ROWS
      INTO rv_atwtb
      FROM cawn
      JOIN cawnt ON cawnt~atinn EQ cawn~atinn
                AND cawnt~spras EQ sy-langu
                AND cawnt~atzhl EQ cawn~atzhl
                AND cawnt~adzhl EQ cawn~adzhl
      WHERE cawn~atinn EQ iv_atinn
        AND cawn~atwrt EQ iv_atwrt.
    ENDSELECT.
    IF sy-subrc <> 0.
      rv_atwtb = iv_atwrt.
    ENDIF.

    ls_cache-atinn = iv_atinn.
    ls_cache-atwrt = iv_atwrt.
    ls_cache-atwtb = rv_atwtb.
    INSERT ls_cache INTO TABLE mt_cawnt_cache.
  ENDMETHOD.
ENDCLASS.
