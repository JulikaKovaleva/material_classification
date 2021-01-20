class ZKJK_CL_CLASSIFFICATION definition
  public
  final
  create public .

public section.

  class-methods GET_CLASSNUM
    importing
      !IV_OBJEK type OBJNUM
      !IV_OBTAB type BAPI1003_KEY-OBJECTTABLE
      !IV_KLART type BAPI1003_KEY-CLASSTYPE
    changing
      !CT_CLASS type TT_BAPI1003_ALLOC_LIST .
  class-methods GET_DETAIL
    importing
      !IV_CLASSTYPE type BAPI_CLASS_KEY-CLASSTYPE
      !IV_CLASSNUM type BAPI_CLASS_KEY-CLASSNUM
      !IV_OBJTABLE type TABELLE
      !IV_OBJECTKEY type OBJNUM
    exporting
      !ET_CLASSCHARACTERISTICS type TT_BAPI1003_ALLOC_VALUES_CHAR .
  class-methods GET_CLASSES
    importing
      !IT_OBJEK type ZKJK_TT_OBJEK
      !IV_OBJEK_TAB type TABELLE
      !ITR_CLASSTYPE_RANGE type ZKJK_TR_CLASSTYPE
      !ITR_CLASS type ZKJK_TR_CLASS_RANGE optional
    exporting
      !ET_CLASSES type ZKJK_TT_CLASSES_WITH_CHAR .
  class-methods GET_CHARACTERS_FOR_CLASS
    importing
      !IV_CLASS type CLINT
      !IV_KLART type KLASSENART
    exporting
      !ET_CHARACTERISTICS type ZKJK_TT_CLASS_CHAR .
PROTECTED SECTION.
  TYPES:
    BEGIN OF mts_class_detail,
      classtype	           TYPE bapi_class_key-classtype,
      classnum             TYPE bapi_class_key-classnum,
      classcharacteristics TYPE tt_bapi1003_alloc_values_char,
    END OF mts_class_detail .

  CLASS-DATA mt_class_detail_cache TYPE SORTED TABLE OF mts_class_detail
                                      WITH UNIQUE KEY classtype classnum .
private section.

  class-methods _GET_ASSIGNED_CLASSES
    importing
      !IV_CLASS type CLINT
    returning
      value(RT_CLASS) type ZKJK_TT_CLASS_LIST .
  class-methods _GET_NEXT_ASSIGNED_CLASS
    importing
      !IV_CLASS type CLINT
    returning
      value(RT_CLASS) type ZKJK_TT_CLASS_LIST .
ENDCLASS.



CLASS ZKJK_CL_CLASSIFFICATION IMPLEMENTATION.


  METHOD get_characters_for_class.

    CONSTANTS:
      lc_zero TYPE c VALUE '0',
      lc_mara TYPE tabelle VALUE 'MARA'.

    DATA:
      lv_class      TYPE clint,
      lt_asso_class TYPE TABLE OF clint,
      lt_char       TYPE tt_bapi1003_charact_r.

    CLEAR et_characteristics.

    "Находим по ассоциациям все связанные классы, признаки будем выводить по ним
    lt_asso_class = _get_assigned_classes( iv_class ).
    "Нужно еще добавить текущий класс
    APPEND iv_class TO lt_asso_class.

    "В этой системе селект из внутренней таблицы сделать нельзя
*    SELECT
*      ksml~imerk AS atinn, "Идентификатор признака
*      cabn~atnam AS atnam, "Тех.имя признака
*      cabn~atfor AS atfor, "Тип признака
*      cabn~atfel AS atfel, "Ссылочное поле для значения
*      cabn~anzst AS anzst,
*      cabn~anzdz AS anzdz,
*      cabnt~atbez AS atbez "Описание признака
*    FROM @lt_asso_class AS asso
*    JOIN ksml ON ksml~clint = asso~table_line
*    JOIN cabn ON cabn~atinn = ksml~imerk
*    LEFT JOIN cabnt ON cabnt~atinn = ksml~imerk
*                   AND cabnt~spras = @sy-langu
*    WHERE ksml~klart = @iv_klart
*    INTO TABLE @et_characteristics.

    "По старому через FAE
*--------------------------------------------------------------------*
    SELECT
      ksml~imerk AS atinn, "Идентификатор признака
      cabn~atnam AS atnam, "Тех.имя признака
      cabn~atfor AS atfor, "Тип признака
      cabn~attab AS attab, "Ссылочная таблица объектов
      cabn~atfel AS atfel, "Ссылочное поле для значения
      cabn~anzst AS anzst,
      cabn~anzdz AS anzdz,
      cabnt~atbez AS atbez "Описание признака
    FROM ksml
    JOIN cabn ON cabn~atinn = ksml~imerk
    LEFT JOIN cabnt ON cabnt~atinn = ksml~imerk
                   AND cabnt~spras = @sy-langu
      FOR ALL ENTRIES IN @lt_asso_class
    WHERE ksml~clint = @lt_asso_class-table_line
      AND ksml~klart = @iv_klart
    INTO TABLE @et_characteristics.
*--------------------------------------------------------------------*

    "Потому что у двух классов могут быть одинаковые признаки
    SORT et_characteristics BY atinn.
    DELETE ADJACENT DUPLICATES FROM et_characteristics.
  ENDMETHOD.


  METHOD get_classes.
    CONSTANTS:
      lc_mafido TYPE klmaf VALUE 'O',
      lc_name   TYPE klapos VALUE '01'. " потому что первая позиция это название, остальное это ключевые слова в транзакции

    "Выборка классов (по таблице лучше чем по диапазону,
    "если будет большое количество значений, диапазон упадет в дамп) + если таблица пустая,
    "выборку все равно делать надо

    "очистка выходных параметров
    CLEAR et_classes.

    SELECT
        kssk~objek, "номер объекта
        klah~class, "наименование класса
        klah~clint, "внутренний номер класса
        klah~klart, "вид класса
        swor~kschl  "текстовое описание класса
      FROM kssk
      JOIN klah ON klah~clint = kssk~clint
      JOIN tcla ON tcla~klart = klah~klart
      LEFT JOIN swor ON swor~clint = klah~clint
      INTO TABLE @et_classes
      FOR ALL ENTRIES IN @it_objek
      WHERE kssk~objek = @it_objek-objek
        AND kssk~klart IN @itr_classtype_range
        AND klah~class IN @itr_class
        AND tcla~obtab = @iv_objek_tab
        AND kssk~mafid = @lc_mafido
        AND swor~klpos = @lc_name
        AND swor~spras = @sy-langu.
  ENDMETHOD.


  METHOD get_classnum.
    DATA: lt_class  TYPE TABLE OF bapi1003_alloc_list,
          lt_return TYPE bapiret2_tab.

    CALL FUNCTION 'BAPI_OBJCL_GETCLASSES'
      EXPORTING
        objectkey_imp   = iv_objek "идентификатор объекта, например номер материала
        objecttable_imp = iv_obtab "Таблица объектов, например MARA
        classtype_imp   = iv_klart "Если нужно ограничение по виду класса
      TABLES
        alloclist       = lt_class "Таблица классов для объекта
        return          = lt_return.

    LOOP AT lt_return TRANSPORTING NO FIELDS WHERE type CA 'EAX'.
      RETURN.
    ENDLOOP.

    APPEND LINES OF lt_class TO ct_class.
  ENDMETHOD.


  METHOD get_detail.
    DATA: ls_cache     TYPE mts_class_detail,

          lt_return    TYPE bapiret2_tab,
          lt_values    TYPE TABLE OF bapi1003_alloc_values_curr,
          lt_valuesnum TYPE TABLE OF bapi1003_alloc_values_num.

    READ TABLE mt_class_detail_cache
      INTO ls_cache
      WITH TABLE KEY classtype = iv_classtype
                     classnum = iv_classnum.
    IF sy-subrc EQ 0.
      et_classcharacteristics = ls_cache-classcharacteristics.
      RETURN.
    ENDIF.
    CALL FUNCTION 'BAPI_OBJCL_GETDETAIL'
      EXPORTING
        objectkey       = iv_objectkey
        objecttable     = iv_objtable
        classnum        = iv_classnum
        classtype       = iv_classtype
      TABLES
        allocvalueschar = et_classcharacteristics
        allocvaluescurr = lt_values  " обязательный параметр, без него ФМ упадет
        allocvaluesnum  = lt_valuesnum " обязательный параметр, без него ФМ упадет
        return          = lt_return.

    ls_cache-classtype = iv_classtype.
    ls_cache-classnum = iv_classnum.
    ls_cache-classcharacteristics = et_classcharacteristics.
    INSERT ls_cache INTO TABLE mt_class_detail_cache.
  ENDMETHOD.


  METHOD _get_assigned_classes.

    DATA: lv_clint      TYPE clint,
          lt_clint      TYPE TABLE OF clint,
          lt_next_clint TYPE TABLE OF clint.

    "берем следующий связанный класс
    lt_next_clint = _get_next_assigned_class( iv_class ).
    LOOP AT lt_next_clint ASSIGNING FIELD-SYMBOL(<ls_next_clint>).
      "если нашли, вставляем в таблицу и ищем следующий
      APPEND <ls_next_clint> TO rt_class.
      lt_clint = _get_assigned_classes( <ls_next_clint> ).
      APPEND LINES OF lt_clint TO rt_class.
    ENDLOOP.

    SORT rt_class.
    DELETE ADJACENT DUPLICATES FROM rt_class.

  ENDMETHOD.


  METHOD _get_next_assigned_class.


*    CONSTANTS:
*      lc_mafid TYPE mafid VALUE 'K'.
*
*    DATA:
*      lv_clint TYPE clint,
*      lt_clint TYPE TABLE OF clint. ",
**      ls_asso_classes LIKE LINE OF mt_asso_classes.
*
*    CLEAR rt_class.
*
*    "Ищем сначала в буфере
*    LOOP AT mt_asso_classes ASSIGNING FIELD-SYMBOL(<ls_asso>)
*      WHERE clint = iv_class.
*      APPEND <ls_asso>-asso_clint TO rt_class.
*    ENDLOOP.
*
*    CHECK rt_class IS INITIAL.
*
*    "Ищем по структуре связанный класс
*    SELECT clint
*      FROM kssk
*      INTO TABLE rt_class
*      WHERE objek = iv_class AND
*      mafid = lc_mafid.
*    LOOP AT rt_class ASSIGNING FIELD-SYMBOL(<ls_clint>).
*      "Если нашли, добавляем в буфер и ищем связанный с новым классом
*      ls_asso_classes-clint = iv_class.
*      ls_asso_classes-asso_clint = <ls_clint>.
*      INSERT ls_asso_classes INTO TABLE mt_asso_classes.
*    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
