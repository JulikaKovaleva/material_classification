*&---------------------------------------------------------------------*
*&  Include           ZKJK_PR_CLASS_MTR_C01
*&---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS:
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,
      user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.
  METHOD handle_toolbar.
    INSERT INITIAL LINE INTO e_object->mt_toolbar ASSIGNING FIELD-SYMBOL(<ls_toolbar>) INDEX 1.
    <ls_toolbar>-function = 'SELECT_ALL'.
    <ls_toolbar>-butn_type = 0.
    <ls_toolbar>-text = 'Выделить все'.
    "Удалить кнопки редактирования таблицы
    DELETE e_object->mt_toolbar
      WHERE function = '&&SEP02'
        OR function = '&LOCAL&APPEND'
        OR function = '&LOCAL&INSERT_ROW'
        OR function = '&LOCAL&DELETE_ROW'
        OR function = '&LOCAL&COPY_ROW'.
  ENDMETHOD.
  METHOD user_command.
    CASE e_ucomm.
      WHEN 'SELECT_ALL'.
        PERFORM select_all.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
