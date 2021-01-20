*&---------------------------------------------------------------------*
*&  Include           ZKJK_PR_CLASS_MTR_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Include          /VIRS/MM_CLASS_MTR_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form SHOW_REPORT
*&---------------------------------------------------------------------*
*& Выбор данных и отображение первого экрана
*&---------------------------------------------------------------------*
FORM show_report .
  "Выбор данных
  PERFORM select_data.
  "Проверяем, есть ли что-то в таблице классов
  IF gt_class IS INITIAL.
    "Не удалось найти ни одного класса
    MESSAGE s001(/virs/mm_class_mtr) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  "Полученные классы вывести пользователю на экран для выбора
  PERFORM show_classes.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SELECT_DATA
*&---------------------------------------------------------------------*
*& Выбор данных по ограничениям селекционного экрана
*&---------------------------------------------------------------------*
FORM select_data .

  CONSTANTS:
    lc_mask         TYPE string VALUE 'NGDO*',
    lc_sign         TYPE c VALUE 'I',
    lc_option_cp(2) TYPE c VALUE 'CP'.

  DATA:
    lv_objec   TYPE objnum,
    lv_obtab   TYPE tclo-obtab,
    lv_klart   TYPE ausp-klart,

    lt_classes TYPE zkjk_tt_classes_with_char,
    lt_matnr   TYPE zkjk_tt_objek.

  "Получение данных по номерам материала
  SELECT mara~matnr AS objek
    FROM mara
    INTO TABLE @lt_matnr
    WHERE mara~matnr IN @s_matnr
      AND mara~ersda IN @s_ersda
      AND mara~mtart IN @s_mtart.

  IF s_matnr IS NOT INITIAL AND lt_matnr IS INITIAL.
    "Номер материала не существует
    MESSAGE s007(zkjk_class_mtr) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "Добавить в фильтр классов NGDO только если в фильтр что-то добавили,
  "если фильтр был пустой, выберутся только NGDO классы
  IF s_class[] IS NOT INITIAL.
    APPEND INITIAL LINE TO s_class[] ASSIGNING FIELD-SYMBOL(<ls_s_class>).
    <ls_s_class>-sign = lc_sign.
    <ls_s_class>-option = lc_option_cp.
    <ls_s_class>-low = lc_mask.
  ENDIF.

  zkjk_cl_classiffication=>get_classes(
    EXPORTING
      itr_classtype_range = s_klart[]  " Диапазон видов класса
      iv_objek_tab        = gc_mara   " Имя таблицы БД объекта
      it_objek            = lt_matnr " Таблица идентификаторов объектов
      itr_class           = s_class[]
    IMPORTING
      et_classes          = lt_classes" Информация о классах
  ).

  LOOP AT lt_classes ASSIGNING FIELD-SYMBOL(<ls_class>).
    IF <ls_class>-class CP lc_mask.
      APPEND INITIAL LINE TO gt_class_ngdo ASSIGNING FIELD-SYMBOL(<ls_gclass>).
    ELSE.
      APPEND INITIAL LINE TO gt_class ASSIGNING <ls_gclass>.
    ENDIF.
    MOVE-CORRESPONDING <ls_class> TO <ls_gclass>.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form SHOW_CLASSES
*&---------------------------------------------------------------------*
*& Показать список классов для выбора пользователя
*&---------------------------------------------------------------------*
FORM show_classes .
  CALL SCREEN 100.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form INIT_CLASS_TABLE
*&---------------------------------------------------------------------*
*& Формирование отображения таблицы классов
*&---------------------------------------------------------------------*
FORM init_class_table .

  CONSTANTS:
    lc_class_struct TYPE tabname VALUE 'ZKJK_S_CLASSES'.

  IF go_class_alv IS INITIAL.

    "Получение объекта контейнера
    go_class_container = NEW #( container_name = gc_class_container_name ).

    "Получение объекта алв
    go_class_alv = NEW #( i_parent = go_class_container ).

    "формирвоание филдкаталога
    PERFORM form_fieldcat
      USING
        lc_class_struct
      CHANGING
        gt_class_fieldcat.
    "Вставить столбец с чекбоксом
    PERFORM insert_checkbox
      CHANGING
        gt_class_fieldcat.

    gs_class_layout-cwidth_opt = abap_true.
    gs_class_layout-sel_mode = 'D'.
    gs_class_layout-no_rowmark = abap_true.

    go_handler = NEW #( ).
    SET HANDLER go_handler->handle_toolbar FOR go_class_alv.
    SET HANDLER go_handler->user_command FOR go_class_alv.

    go_class_alv->set_table_for_first_display(
      EXPORTING
        is_layout                     = gs_class_layout
      CHANGING
        it_outtab                     = gt_class
        it_fieldcatalog               = gt_class_fieldcat
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4
      ).
    IF sy-subrc <> 0.
      "Не удалось отобразить таблицу классов
      MESSAGE e002(/virs/mm_class_mtr).
    ENDIF.

    go_class_alv->register_edit_event(
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified ).
  ELSE.
    go_class_alv->refresh_table_display( ).
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FORM_FIELDCAT
*&---------------------------------------------------------------------*
*& Формирвоание филдкаталога по имени структуры
*&---------------------------------------------------------------------*
FORM form_fieldcat
  USING
    iv_class_struct TYPE tabname
  CHANGING
    ct_fieldcat TYPE lvc_t_fcat.

  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = iv_class_struct
    CHANGING
      ct_fieldcat            = ct_fieldcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
    "Не удалось сформирвоать филдкаталог
    MESSAGE e003(/virs/mm_class_mtr).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_DETAIL
*&---------------------------------------------------------------------*
*& Получение признаков класса
*&---------------------------------------------------------------------*
FORM get_detail .

  CONSTANTS:
    lc_spras      TYPE c VALUE 'R',
    lc_atfor_date TYPE atfor VALUE 'DATE',
    lc_atfor_num  TYPE atfor VALUE 'NUM',
    lc_comp_descr TYPE c VALUE 'D',
    lc_class_ngdo TYPE string VALUE 'CLASS_NGDO',
    lc_kschl_ngdo TYPE string VALUE 'KSCHL_NGDO',
    lc_class_kfk  TYPE string VALUE 'CLASS_KFK',
    lc_kschl_kfk  TYPE string VALUE 'KSCHL_KFK',
    lc_atnam      TYPE atnam VALUE 'ED_IZM_BAZIS'.

  TYPES:
    BEGIN OF lt_s_chars,
      atinn TYPE atinn,
      atnam TYPE atnam,
      atfor TYPE atfor,
      atbez TYPE atbez,
    END OF lt_s_chars,
    lt_t_chars TYPE TABLE OF lt_s_chars.

  TYPES:
    BEGIN OF lt_s_matnr,
      matnr TYPE matnr,
    END OF lt_s_matnr,
    lt_t_matnr TYPE TABLE OF lt_s_matnr.

  DATA:
    BEGIN OF ls_class_char,
      class TYPE klasse_d,
      klart TYPE klassenart,
      chars TYPE lt_t_chars,
    END OF ls_class_char.

  DATA:
    lt_character  TYPE tt_bapi1003_alloc_values_char,
    lt_classes    TYPE zkjk_tt_classes,
    lt_objects    TYPE zkjk_tt_classes,
    lt_chars      TYPE zkjk_tt_class_char_sort,
    lt_charact    TYPE zkjk_tt_class_char,
    lt_class_char LIKE SORTED TABLE OF ls_class_char WITH UNIQUE KEY class klart,
    lt_matnr      TYPE zkjk_tt_matnr_sorted,
    lt_mara       TYPE zkjk_tt_mara_sorted,

    ls_matnr      TYPE zkjk_s_matnr_sorted,

    lv_classtype  TYPE bapi_class_key-classtype,
    lv_classnum   TYPE bapi_class_key-classnum,
    lv_objecktkey TYPE objnum,
    lv_atinn      TYPE atinn,
    lv_atwrt      TYPE atwrt,
    lv_cawn       TYPE atwtb,
    lv_atflv      TYPE atflv,
    lv_datum      TYPE sy-datum,
    lv_comp_name  TYPE char30.

  FIELD-SYMBOLS:
    <lt_output_table> TYPE STANDARD TABLE.

  CLEAR:
    gv_max_col,
    gr_dinamic_table,
    gt_common_fieldcat,
    go_common_alv.

  "Получить список уникальных классов и объектов, выбранных пользователем
  LOOP AT gt_class ASSIGNING FIELD-SYMBOL(<ls_class>) WHERE checkbox = abap_true.
    APPEND INITIAL LINE TO lt_classes ASSIGNING FIELD-SYMBOL(<ls_classes>).
    APPEND INITIAL LINE TO lt_objects ASSIGNING FIELD-SYMBOL(<ls_objects>).
    MOVE-CORRESPONDING <ls_class> TO <ls_classes>.
    MOVE-CORRESPONDING <ls_class> TO <ls_objects>.

    READ TABLE lt_matnr ASSIGNING FIELD-SYMBOL(<ls_matnr>)
      WITH TABLE KEY matnr = <ls_class>-objek.
    IF sy-subrc IS NOT INITIAL.
      "Добавть номер маетриала
      ls_matnr-matnr = <ls_class>-objek.
      INSERT ls_matnr INTO TABLE lt_matnr.
    ENDIF.
  ENDLOOP.

  SORT lt_classes BY clint.
  DELETE ADJACENT DUPLICATES FROM lt_classes COMPARING clint.

  CHECK lt_classes IS NOT INITIAL.

  SORT lt_objects BY objek klart.
  DELETE ADJACENT DUPLICATES FROM lt_objects COMPARING objek klart.

  CHECK lt_objects IS NOT INITIAL.

  "По списку классов получить соответствие класс-признак
  LOOP AT lt_classes ASSIGNING <ls_classes>.
    zkjk_cl_classiffication=>get_characters_for_class(
      EXPORTING
        iv_klart = <ls_classes>-klart
        iv_class = <ls_classes>-clint
      IMPORTING
        et_characteristics = lt_charact ).
    IF lt_charact IS NOT INITIAL.
      CLEAR: ls_class_char.
      ls_class_char-class = <ls_classes>-class.
      ls_class_char-klart = <ls_classes>-klart.
      LOOP AT lt_charact ASSIGNING FIELD-SYMBOL(<ls_charact>).
        APPEND INITIAL LINE TO ls_class_char-chars ASSIGNING FIELD-SYMBOL(<ls_chars>).
        MOVE-CORRESPONDING <ls_charact> TO <ls_chars>.
        "Собираем уникальные признаки
        READ TABLE lt_chars TRANSPORTING NO FIELDS
          WITH TABLE KEY atinn = <ls_charact>-atinn.
        IF sy-subrc IS NOT INITIAL. "Если не нашли, вставляем
          INSERT <ls_charact> INTO TABLE lt_chars.
        ENDIF.
      ENDLOOP.
      INSERT ls_class_char INTO TABLE lt_class_char.
    ENDIF.
  ENDLOOP.

  "кешируем таблицы, чтобы потом читать из внутренних таблиц, для этого нужна таблица признаков и таблица объектов
  zkjk_cl_char_values=>cache_tables(
    EXPORTING
      it_chars = lt_chars
      it_objects = lt_objects
      it_matnr = lt_matnr
  ).

  "Получить данные по материалам
  zkjk_cl_char_values=>get_mara(
    IMPORTING
      et_mara = lt_mara
  ).
  MOVE-CORRESPONDING lt_mara TO gt_mara.

  "Сформировать динамическую таблицу
  PERFORM rebild_output_table
    USING
      lt_chars
      gv_max_ngdo
    CHANGING
      gr_dinamic_table.

  ASSIGN gr_dinamic_table->* TO <lt_output_table>.

  IF sy-subrc IS NOT INITIAL.
    "Не удалось обратиться к динамической таблице
    MESSAGE e005(/virs/mm_class_mtr).
  ENDIF.

  "Получить выбранные пользователем классы
  LOOP AT gt_class ASSIGNING <ls_class>
    WHERE checkbox = abap_true.

    "Читаем таблицы с классами NGDO, чтобы заполнить конечные поля
    READ TABLE gt_class_ngdo INTO DATA(ls_class_ngdo)
      WITH KEY objek = <ls_class>-objek.

    APPEND INITIAL LINE TO <lt_output_table> ASSIGNING FIELD-SYMBOL(<ls_common>).

    "Заполняем поля MARA
    READ TABLE gt_mara ASSIGNING FIELD-SYMBOL(<ls_mara>)
        WITH TABLE KEY matnr = <ls_class>-objek.
    IF sy-subrc IS INITIAL.
      MOVE-CORRESPONDING <ls_mara> TO <ls_common>.
    ENDIF.
    "Класс и его описание
    ASSIGN COMPONENT lc_class_ngdo OF STRUCTURE <ls_common> TO FIELD-SYMBOL(<lv_comp>).
    IF sy-subrc IS INITIAL.
      <lv_comp> = ls_class_ngdo-class.
    ENDIF.
    ASSIGN COMPONENT lc_kschl_ngdo OF STRUCTURE <ls_common> TO <lv_comp>.
    IF sy-subrc IS INITIAL.
      <lv_comp> = ls_class_ngdo-kschl.
    ENDIF.
    ASSIGN COMPONENT lc_class_kfk OF STRUCTURE <ls_common> TO <lv_comp>.
    IF sy-subrc IS INITIAL.
      <lv_comp> = <ls_class>-class.
    ENDIF.
    ASSIGN COMPONENT lc_kschl_kfk OF STRUCTURE <ls_common> TO <lv_comp>.
    IF sy-subrc IS INITIAL.
      <lv_comp> = <ls_class>-kschl.
    ENDIF.

    "Читаем строку с признаками
    READ TABLE lt_class_char ASSIGNING FIELD-SYMBOL(<ls_class_char>)
      WITH TABLE KEY class = <ls_class>-class
                     klart = <ls_class>-klart.
    IF sy-subrc IS NOT INITIAL.
      "Если у класса нет признаков, выводим информацию по классу и выходим, не доходя до признаков
      CONTINUE.
    ENDIF.


    LOOP AT <ls_class_char>-chars ASSIGNING FIELD-SYMBOL(<ls_character>).
      "Тексты найти
      CALL METHOD zkjk_cl_char_values=>read_value
        EXPORTING
          iv_obtab = gc_mara
          iv_objek = <ls_class>-objek
          iv_atinn = <ls_character>-atinn
          iv_klart = <ls_class>-klart
        IMPORTING
          ev_atflv = lv_atflv
          ev_atwrt = lv_atwrt
          ev_atwtb = lv_cawn
          ev_datum = lv_datum.
      CASE <ls_character>-atfor.
        WHEN lc_atfor_date.
          lv_atwrt = lv_datum.
        WHEN lc_atfor_num.
          lv_atwrt = lv_atflv.
      ENDCASE.
      IF lv_atwrt IS INITIAL.
        "Попробовать получить значение по ссылочной таблице
        READ TABLE lt_chars ASSIGNING FIELD-SYMBOL(<ls_chars1>)
          WITH TABLE KEY atinn = <ls_character>-atinn.
        IF sy-subrc IS INITIAL AND <ls_chars1>-atfel IS NOT INITIAL AND <ls_mara> IS ASSIGNED.
          ASSIGN COMPONENT <ls_chars1>-atfel OF STRUCTURE <ls_mara> TO FIELD-SYMBOL(<lv_dop_value>).
          IF sy-subrc IS INITIAL.
            lv_atwrt = <lv_dop_value>.
            lv_cawn = <lv_dop_value>.
          ENDIF.
        ELSE. "если поле не сможем найти в мара, переходим к следующему признаку
          CONTINUE.
        ENDIF.
      ENDIF.
      "Данные признаков
      "Если признак - ЕИ, нужно сделать преобразование, иначе будет отображаться в неправильном формате

      "Получить номер признака в таблице уникальных признаков
      READ TABLE lt_chars TRANSPORTING NO FIELDS
        WITH TABLE KEY atinn = <ls_character>-atinn.
      IF sy-subrc IS INITIAL.
        DATA(lv_index) = sy-tabix.
      ENDIF.

      "Формируем имя столбца (имя не может начинаться с цифры, поэтому индекс в конце,
      "иначе exception при формировании динамической таблицы)
      lv_comp_name = <ls_character>-atnam(10) && lv_index.
      ASSIGN COMPONENT lv_comp_name OF STRUCTURE <ls_common> TO <lv_comp>.
      IF sy-subrc IS INITIAL.
        <lv_comp> = lv_cawn.
      ENDIF.
      lv_comp_name = <ls_character>-atnam(10) && lv_index && lc_comp_descr.
      ASSIGN COMPONENT lv_comp_name OF STRUCTURE <ls_common> TO <lv_comp>.
      IF sy-subrc IS INITIAL.
        <lv_comp> = lv_atwrt.
      ENDIF.

    ENDLOOP.

    CLEAR ls_class_ngdo.
  ENDLOOP.
  "Если классов нет, но выбраны NGDO классы, то вывести их
  IF gt_class IS INITIAL.
    LOOP AT gt_class_ngdo ASSIGNING FIELD-SYMBOL(<ls_ngdo>).
      APPEND INITIAL LINE TO <lt_output_table> ASSIGNING <ls_common>.
      ASSIGN COMPONENT lc_class_ngdo OF STRUCTURE <ls_common> TO <lv_comp>.
      IF sy-subrc IS INITIAL.
        <lv_comp> = <ls_ngdo>-class.
      ENDIF.
      ASSIGN COMPONENT lc_kschl_ngdo OF STRUCTURE <ls_common> TO <lv_comp>.
      IF sy-subrc IS INITIAL.
        <lv_comp> = <ls_ngdo>-kschl.
      ENDIF.
    ENDLOOP.
  ENDIF.

  "Показать таблицу
  PERFORM show_common_table.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form INSERT_CHECKBOX
*&---------------------------------------------------------------------*
*& Вставка в филдкаталог столбца с чекбоксом
*&---------------------------------------------------------------------*
FORM insert_checkbox
  CHANGING
    ct_fieldcat TYPE lvc_t_fcat.

  "Добавить первый столбец
  APPEND INITIAL LINE TO ct_fieldcat ASSIGNING FIELD-SYMBOL(<ls_fieldcat>).
  <ls_fieldcat>-fieldname = 'CHECKBOX'.
  <ls_fieldcat>-tabname = '1'.
  <ls_fieldcat>-checkbox = abap_true.
  <ls_fieldcat>-edit = abap_true.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form SHOW_COMMON_TABLE
*&---------------------------------------------------------------------*
*& Показать итоговую таблицу признаков
*&---------------------------------------------------------------------*
FORM show_common_table .
  CALL SCREEN 200.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form INIT_COMMON_TABLE
*&---------------------------------------------------------------------*
*& Инициализация объектов для отображения итоговой таблицы
*&---------------------------------------------------------------------*
FORM init_common_table .
  CONSTANTS:
    lc_common_struct TYPE tabname VALUE 'ZKJK_S_COMMON_ALV_CL_MTR'.

  FIELD-SYMBOLS:
    <lt_common> TYPE STANDARD TABLE.

  IF go_common_alv IS INITIAL.

    "Получение объекта контейнера
    go_common_container = NEW #( container_name = gc_common_container_name ).

    "Получение объекта алв
    go_common_alv = NEW #( i_parent = go_common_container ).

    ASSIGN gr_dinamic_table->* TO <lt_common>.

    gs_common_layout-cwidth_opt = abap_true.
    gs_common_layout-zebra = abap_true.

    go_common_alv->set_table_for_first_display(
      EXPORTING
        is_layout                     = gs_common_layout
      CHANGING
        it_outtab                     = <lt_common>
        it_fieldcatalog               = gt_common_fieldcat
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4
      ).
    IF sy-subrc <> 0.
      "Не удалось отобразить таблицу классов
      MESSAGE e002(/virs/mm_class_mtr).
    ENDIF.

  ELSE.
    ASSIGN gr_dinamic_table->* TO <lt_common>.
    go_common_alv->refresh_table_display( ).
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form REBILD_OUTPUT_TABLE
*&---------------------------------------------------------------------*
*& Переформирвоать выходную таблицу, строки в столбцы(каждый признак - отдельные три столбца)
*&---------------------------------------------------------------------*
FORM rebild_output_table
  USING
    it_chars TYPE zkjk_tt_class_char_sort
    iv_max_ngdo TYPE i
  CHANGING
    cr_dinamic_table TYPE REF TO data.

  CONSTANTS:
    lc_c             TYPE c VALUE 'C'.

  DATA:
    lt_comp TYPE cl_abap_structdescr=>component_table.

  "Сформировать каталог полей, с основой из таблицы + мах количество признаков
  PERFORM create_dinamic_fieldcat
    USING
      it_chars
      iv_max_ngdo
    CHANGING
      gt_common_fieldcat
      lt_comp.

  "По филдкаталогу сформирвоать динамическую таблицу

  "По сформированному каталогу полей сформировать динамическую структуру
  TRY.
      DATA(lo_struct) = cl_abap_structdescr=>create( lt_comp ).
    CATCH cx_sy_struct_creation.
      MESSAGE e006(/virs/mm_class_mtr).
  ENDTRY.
  "Создать таблицу по структуре
  TRY.
      DATA(lo_table) = cl_abap_tabledescr=>create( lo_struct ).
    CATCH cx_sy_table_creation.
      MESSAGE e006(/virs/mm_class_mtr).
  ENDTRY.

  "Создание ссылочной переменной
  IF lo_table IS NOT BOUND.
    MESSAGE e006(/virs/mm_class_mtr).
  ENDIF.
  CREATE DATA cr_dinamic_table TYPE HANDLE lo_table.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_DINAMIC_FIELDCAT
*&---------------------------------------------------------------------*
*& Формирвоание каталога полей динамической таблицы со столбцами-признаками
*&---------------------------------------------------------------------*
FORM create_dinamic_fieldcat
  USING
    it_chars TYPE zkjk_tt_class_char_sort
    iv_max_ngdo TYPE i
  CHANGING
    ct_common_fieldcat TYPE lvc_t_fcat
    ct_comp TYPE cl_abap_structdescr=>component_table.

  CONSTANTS:
    lc_c          TYPE c VALUE 'C',
    lc_ngdo       TYPE string VALUE 'NGDO',
    lc_tabname    TYPE lvc_tname VALUE '1',
    lc_comp_descr TYPE c VALUE 'D',
    lc_atnam      TYPE atnam VALUE 'ED_IZM_BAZIS',
    lc_convexit   TYPE convexit VALUE 'CUNIT'.

  DATA:
    lo_elem_descr TYPE REF TO cl_abap_elemdescr,

    lv_len        TYPE i,
    lv_dec        TYPE i.

  PERFORM form_fieldcat
    USING
      gc_common_struct
    CHANGING
      ct_common_fieldcat.

  "Сформировать филдкаталог для динамической таблицы
  LOOP AT ct_common_fieldcat ASSIGNING FIELD-SYMBOL(<ls_fcat>).
    APPEND INITIAL LINE TO ct_comp ASSIGNING FIELD-SYMBOL(<ls_comp>).
    <ls_comp>-name = <ls_fcat>-fieldname.
    <ls_comp>-type ?= cl_abap_typedescr=>describe_by_name( <ls_fcat>-domname ).
    CASE TYPE OF <ls_comp>-type.
      WHEN TYPE cl_abap_structdescr INTO DATA(lo_struct).
        <ls_comp>-type ?= cl_abap_typedescr=>describe_by_name( gc_klasse_d ).
    ENDCASE.
  ENDLOOP.

  DATA(lv_col_pos) = lines( ct_common_fieldcat ).

  LOOP AT it_chars ASSIGNING FIELD-SYMBOL(<ls_char>).
    DATA(lv_index) = sy-tabix.

    lv_len = <ls_char>-anzst.
    lv_dec = <ls_char>-anzdz.

    TRY.
        CASE <ls_char>-atfor.
          WHEN 'CHAR'.
            CALL METHOD cl_abap_elemdescr=>get_c
              EXPORTING
                p_length = lv_len
              RECEIVING
                p_result = lo_elem_descr.
          WHEN 'CURR'.
            CALL METHOD cl_abap_elemdescr=>get_p
              EXPORTING
                p_length   = lv_len
                p_decimals = lv_dec
              RECEIVING
                p_result   = lo_elem_descr.
          WHEN 'DATE'.
            CALL METHOD cl_abap_elemdescr=>get_d
              RECEIVING
                p_result = lo_elem_descr.
          WHEN 'NUM' .
            CALL METHOD cl_abap_elemdescr=>get_p
              EXPORTING
                p_length   = lv_len
                p_decimals = lv_dec
              RECEIVING
                p_result   = lo_elem_descr.
          WHEN 'TIME'.
            CALL METHOD cl_abap_elemdescr=>get_t
              RECEIVING
                p_result = lo_elem_descr.
          WHEN 'UDEF'.
            CALL METHOD cl_abap_elemdescr=>get_c
              EXPORTING
                p_length = lv_len
              RECEIVING
                p_result = lo_elem_descr.
          WHEN OTHERS.
            CONTINUE.
        ENDCASE.
      CATCH cx_parameter_invalid_range  .
      CATCH cx_sy_create_data_error.
        CONTINUE.
    ENDTRY.
    APPEND INITIAL LINE TO ct_comp ASSIGNING <ls_comp>.
    <ls_comp>-name = <ls_char>-atnam(10) && lv_index. "номер в конце, иначе в динамической таблице exception
    <ls_comp>-type = lo_elem_descr.

    lv_col_pos = lv_col_pos + 1.
    APPEND INITIAL LINE TO ct_common_fieldcat ASSIGNING FIELD-SYMBOL(<ls_com_fcat>).
    CASE <ls_char>-atfor.
      WHEN 'CHAR'.
      WHEN 'CURR'.
        <ls_com_fcat>-ref_table = 'BKPF'.
        <ls_com_fcat>-ref_field = 'WAERS'.
      WHEN 'DATE'.
        <ls_com_fcat>-ref_table = 'SYST'.
        <ls_com_fcat>-ref_field = 'DATUM'.
      WHEN 'NUM' .
      WHEN 'TIME'.
        <ls_com_fcat>-ref_table = 'SYST'.
        <ls_com_fcat>-ref_field = 'UZEIT'.
      WHEN 'UDEF'.
      WHEN OTHERS.
        CONTINUE.
    ENDCASE.

    <ls_com_fcat>-tabname = lc_tabname.
    <ls_com_fcat>-fieldname = <ls_char>-atnam(10) && lv_index.
    <ls_com_fcat>-inttype = lo_elem_descr->type_kind.
    <ls_com_fcat>-col_pos = lv_col_pos.
    <ls_com_fcat>-seltext = <ls_char>-atbez.
    <ls_com_fcat>-reptext = <ls_com_fcat>-seltext.
    <ls_com_fcat>-scrtext_l = <ls_com_fcat>-seltext.
    <ls_com_fcat>-scrtext_m = <ls_com_fcat>-seltext.
    <ls_com_fcat>-scrtext_s = <ls_com_fcat>-seltext.

    "Для единицы измерения добавить подпрограмму преобразовани
    IF <ls_char>-atnam = lc_atnam.
      <ls_com_fcat>-convexit = lc_convexit.
    ENDIF.


    lv_col_pos = lv_col_pos + 1.
    APPEND INITIAL LINE TO ct_common_fieldcat ASSIGNING <ls_com_fcat>.
    <ls_com_fcat>-tabname = lc_tabname.
    <ls_com_fcat>-fieldname = <ls_char>-atnam(10) && lv_index && lc_comp_descr.
    <ls_com_fcat>-inttype = lc_c.
    <ls_com_fcat>-col_pos = lv_col_pos.
    <ls_com_fcat>-seltext = 'Описание'(002).
    <ls_com_fcat>-reptext = <ls_com_fcat>-seltext.
    <ls_com_fcat>-scrtext_l = <ls_com_fcat>-seltext.
    <ls_com_fcat>-scrtext_m = <ls_com_fcat>-seltext.
    <ls_com_fcat>-scrtext_s = <ls_com_fcat>-seltext.

    APPEND INITIAL LINE TO ct_comp ASSIGNING <ls_comp>.
    <ls_comp>-name = <ls_char>-atnam(10) && lv_index && lc_comp_descr. "номер в конце, иначе в динамической таблице exception
    <ls_comp>-type ?= cl_abap_typedescr=>describe_by_name( gc_atwrt70 ).

  ENDLOOP.

  "После максимального признака надо добавить класс нгдо и его признаки
  lv_col_pos = lv_col_pos + 1.
  APPEND INITIAL LINE TO ct_common_fieldcat ASSIGNING <ls_com_fcat>.
  <ls_com_fcat>-tabname = lc_tabname.
  <ls_com_fcat>-fieldname = gc_class_ngdo.
  <ls_com_fcat>-inttype = lc_c.
  <ls_com_fcat>-col_pos = lv_col_pos.
  <ls_com_fcat>-seltext = 'Класс НГДО'(004).
  <ls_com_fcat>-reptext = <ls_com_fcat>-seltext.
  <ls_com_fcat>-scrtext_l = <ls_com_fcat>-seltext.
  <ls_com_fcat>-scrtext_m = <ls_com_fcat>-seltext.
  <ls_com_fcat>-scrtext_s = <ls_com_fcat>-seltext.

  APPEND INITIAL LINE TO ct_comp ASSIGNING <ls_comp>.
  <ls_comp>-name = gc_class_ngdo.
  <ls_comp>-type ?= cl_abap_typedescr=>describe_by_name( gc_klasse_d ).

  lv_col_pos = lv_col_pos + 1.
  APPEND INITIAL LINE TO ct_common_fieldcat ASSIGNING <ls_com_fcat>.
  <ls_com_fcat>-tabname = lc_tabname.
  <ls_com_fcat>-fieldname = gc_kschl_ngdo.
  <ls_com_fcat>-inttype = lc_c.
  <ls_com_fcat>-col_pos = lv_col_pos.
  <ls_com_fcat>-seltext = 'Название'(005).
  <ls_com_fcat>-reptext = <ls_com_fcat>-seltext.
  <ls_com_fcat>-scrtext_l = <ls_com_fcat>-seltext.
  <ls_com_fcat>-scrtext_m = <ls_com_fcat>-seltext.
  <ls_com_fcat>-scrtext_s = <ls_com_fcat>-seltext.

  APPEND INITIAL LINE TO ct_comp ASSIGNING <ls_comp>.
  <ls_comp>-name = gc_kschl_ngdo.
  <ls_comp>-type ?= cl_abap_typedescr=>describe_by_name( gc_klschl ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form SELECT_ALL
*&---------------------------------------------------------------------*
*& Выбор всех отображенных классов на экране
*&---------------------------------------------------------------------*
FORM select_all .

  DATA: lt_filter TYPE lvc_t_fidx,

        lt_class  LIKE gt_class.

  go_class_alv->get_filtered_entries(
    IMPORTING
      et_filtered_entries = lt_filter
  ).

  LOOP AT gt_class ASSIGNING FIELD-SYMBOL(<ls_class>).
    DATA(lv_index) = sy-tabix.
    READ TABLE lt_filter TRANSPORTING NO FIELDS
      WITH TABLE KEY table_line = lv_index.
    "Если номера строки не нашли в фильтруемой таблице, значит она выводится на экране
    IF sy-subrc IS NOT INITIAL.
      <ls_class>-checkbox = abap_true.
    ENDIF.
  ENDLOOP.
  go_class_alv->refresh_table_display( ).

ENDFORM.
