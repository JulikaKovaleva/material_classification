*&---------------------------------------------------------------------*
*&  Include           ZKJK_PR_CLASS_MTR_I01
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  DATA: lv_changed TYPE c.
  CASE sy-ucomm.
    WHEN 'SELECT'.
      PERFORM get_detail.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'CANCEL'.
      LEAVE PROGRAM.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK'.
      CLEAR gt_common.
      LEAVE TO SCREEN 0.
    WHEN 'CANCEL'.
      LEAVE PROGRAM.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.
