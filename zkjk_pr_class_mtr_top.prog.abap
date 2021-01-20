*&---------------------------------------------------------------------*
*&  Include           ZKJK_PR_CLASS_MTR_TOP
*&---------------------------------------------------------------------*

CLASS lcl_event_handler DEFINITION DEFERRED.
TYPES:
  BEGIN OF gts_mara.
    INCLUDE TYPE mara.
TYPES:
  maktx   TYPE makt-maktx,
  wgbez60 TYPE t023t-wgbez60,
  ewbez   TYPE twewt-ewbez,
  mtstb   TYPE t141t-mtstb,
  mtbez   TYPE t134t-mtbez,
  END OF gts_mara,
  gtt_mara TYPE SORTED TABLE OF gts_mara WITH UNIQUE KEY matnr.

TYPES:
  BEGIN OF gts_common,
    matnr      TYPE mara-matnr,
    ersda      TYPE mara-ersda,
    maktx      TYPE makt-maktx,
    mtart      TYPE mara-mtart,
    bismt      TYPE mara-bismt,
    gewei      TYPE mara-gewei,
    matkl      TYPE mara-matkl,
    extwg      TYPE mara-extwg,
    wgbez60    TYPE t023t-wgbez60,
    ewbez      TYPE twewt-ewbez,
    mbrsh      TYPE mara-mbrsh,
    meins      TYPE mara-meins,
    mstae      TYPE mara-mstae,
    mtstb      TYPE t141t-mtstb,
    mstde      TYPE mara-mstde,
    class_kfk  TYPE klah-class,
    kschl_kfk  TYPE swor-kschl,
    atnam      TYPE atnam,
    atbez      TYPE cabnt-atbez,
    cawn       TYPE atwtb,
    atwrt      TYPE cawn-atwrt,
    class_ngdo TYPE klah-class,
    kschl_ngdo TYPE swor-kschl,
  END OF gts_common,
  gtt_common TYPE TABLE OF gts_common WITH KEY matnr.

TYPES:
  BEGIN OF gts_class,
    checkbox TYPE c.
    INCLUDE TYPE zkjk_s_classes.
TYPES:
END OF gts_class,
gtt_class TYPE TABLE OF gts_class.

CONSTANTS:
  gc_class_container_name  TYPE scrfname VALUE 'CLASS_CONTAINER',
  gc_common_container_name TYPE scrfname VALUE 'COMMON_CONTAINER',
  gc_mara                  TYPE tabelle VALUE 'MARA',
  gc_common_struct         TYPE tabname VALUE 'ZKJK_S_COMMON_ALV_CL_MTR',
  gc_klasse_d              TYPE string VALUE 'KLASSE_D',
  gc_klschl                TYPE string VALUE 'KLSCHL',
  gc_atbez                 TYPE string VALUE 'ATBEZ',
  gc_cawn                  TYPE string VALUE 'CAWN',
  gc_atwrt                 TYPE string VALUE 'ATWRT',
  gc_atwrt70               TYPE string VALUE 'ATWRT70',
  gc_class_ngdo            TYPE string VALUE 'CLASS_NGDO',
  gc_kschl_ngdo            TYPE string VALUE 'KSCHL_NGDO'.

DATA:
  gv_matnr            TYPE matnr,
  gv_ersda            TYPE mara-ersda,
  gv_mtart            TYPE mara-mtart,
  gv_klart            TYPE tcla-klart,
  gv_class            TYPE klah-class,
  gv_max_col          TYPE i,
  gv_max_ngdo         TYPE i,

  gt_mara             TYPE gtt_mara,
  gt_common           TYPE gtt_common,
  gt_class            TYPE gtt_class,
  gt_class_ngdo       TYPE gtt_class,
  gt_class_fieldcat   TYPE lvc_t_fcat,
  gt_common_fieldcat  TYPE lvc_t_fcat,

  gs_class_layout     TYPE lvc_s_layo,
  gs_common_layout    TYPE lvc_s_layo,

  go_class_alv        TYPE REF TO cl_gui_alv_grid,
  go_common_alv       TYPE REF TO cl_gui_alv_grid,
  go_class_container  TYPE REF TO cl_gui_custom_container,
  go_common_container TYPE REF TO cl_gui_custom_container,
  go_handler          TYPE REF TO lcl_event_handler,

  gr_dinamic_table    TYPE REF TO data.
