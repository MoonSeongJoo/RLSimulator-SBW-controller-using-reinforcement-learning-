/* VS API functions in a VS Solver DLL. Listed more or less how they appear in the VS API
   reference manual.

  Log:
  July 22, 2015. M. Sayers. Removed enums and deftype; just simple C types used for prototypes.
  */

  
// simple run function (chapter 2)
int  vs_run(const char *simfile);

// extending VS Math Models with MATLAB or VB (chapter 4)
int  vs_statement (const char *key, const char *buffer, int stopError);
void vs_copy_export_vars (double  *export);
void vs_copy_import_vars (double  *import);
void vs_copy_io (double  *imports, double  *exports);
int  vs_integrate_io (double  t, double  *imports, double  *exports);
int  vs_integrate_IO (double  t, double  *imports, double  *exports);
void vs_read_configuration (const char *simfile, int *n_import,
                        int *n_export, double  *tstart, double  *tstop,
                        double  *tstep);
void vs_scale_import_vars (void);
void vs_terminate_run (double  t);

// utility functions: conditons (chapter 5)
int    vs_during_event (void);
int    vs_error_occurred (void);
double vs_get_tstep (void);
int    vs_opt_pause(void);

// utility functions: messages (chapter 5)
void  vs_clear_error_message (void); 
void  vs_clear_output_message (void);
char *vs_get_echofile_name (void);
char *vs_get_endfile_name (void);
char *vs_get_erdfile_name (void);
char *vs_get_error_message (void);
char *vs_get_infile_name (void);
char *vs_get_logfile_name (void);
char *vs_get_output_message (void);
char *vs_get_simfile_name (void);
char *vs_get_version_model (void);
char *vs_get_version_product (void);
char *vs_get_version_vs (void);
void  vs_printf (const char *format);
void  vs_printf_error (const char *format);

// more detailed control of run (chapter 6)
int    vs_bar_graph_update (int *);
void   vs_free_all (void);
void   vs_initialize (double  t, int, int);
int    vs_integrate (double  *t, int);
int    vs_integrate_io_2 (double  t, double  *imports, double  *exports, int);
double vs_setdef_and_read (const char *simfile, int, int);
int    vs_stop_run (void);
void   vs_terminate (double  t, void *);

// functions for interacting with the VS math model (chapter 7)
int     vs_define_import (char *keyword, char *desc, double  *real, char *);
int     vs_define_indexed_parameter_array (char *keyword);
int     vs_define_output (char *shortname, char *longname, double  *real, char *);
int     vs_define_parameter (char *keyword, char *desc, double  *, char *);
int     vs_define_parameter_int (char *keyword, char *desc, int *);
void    vs_define_units (char *desc, double  gain);
int     vs_define_variable (char *keyword, char *desc, double  *);    
int     vs_get_sym_attribute (int id, int type, void **att);
int     vs_get_var_id (char *keyword, int *type);
double *vs_get_var_ptr (char *keyword);                                        
int    *vs_get_var_ptr_int (char *keyword);
int     vs_have_keyword_in_database (char *keyword);
double  vs_import_result (int id, double  native);
void    vs_install_calc_func (char *name, void *func); // obsolete
int     vs_install_keyword_alias (char *existing, char *alias);
void    vs_install_symbolic_func (char *name, void *func, int n_args);
void    vs_read_next_line (char *buffer, int n);
void    vs_set_stop_run (double  stop_gt_0, const char *format);
int     vs_set_sym_attribute (int id, int type, const void *att);
int     vs_set_sym_int (int id, int dataType, int value);
int     vs_set_sym_real (int id, int dataType, double  value);
void    vs_set_units (char *var_keyword, char *units_keyword);
char   *vs_string_copy_internal (char **target, char *source);
void    vs_write_f_to_echo_file (char *key, double  , char *doc);
void    vs_write_header_to_echo_file (char *buffer);
void    vs_write_i_to_echo_file (char *key, int , char *doc);
void    vs_write_to_echo_file (const char *buffer);
void    vs_write_to_logfile (int level, const char *format);

// 3D road properties (chapter 7)
void   vs_get_dzds_dzdl (double  s, double  l, double  *dzds, double  *dzdl);
void   vs_get_dzds_dzdl_i (double  s, double  l, double  *dzds,
                           double  *dzdl, double  inst);
void   vs_get_road_contact (double  y, double  x, int inst, double  *z,
                            double  *dzdy, double  *dzdx, double  *mu);
void   vs_get_road_contact_sl (double  s, double  l, int inst, double  *z,
                               double  *dzds, double  *dzdl, double  *mu);
void   vs_get_road_start_stop (double  *start, double  *stop);
void   vs_get_road_xyz (double  s, double  l, double  *x, double  *y, double  *z);
double vs_road_curv_i (double  s, double  inst);
double vs_road_l (double  x, double  y);
double vs_road_l_i (double  x, double  y, double  inst);
double vs_road_pitch_sl_i (double  s, double  l, double  yaw, double  inst);
double vs_road_roll_sl_i (double  s, double  l, double  yaw, double  inst);
double vs_road_s (double  x, double  y);
double vs_road_s_i (double  x, double  y, double  inst);
double vs_road_x (double  s);
double vs_road_x_i (double  sy, double  inst);
double vs_road_x_sl_i (double  s, double  l, double  inst);
double vs_road_y (double  s);
double vs_road_y_i (double  sy, double  inst);
double vs_road_y_sl_i (double  s, double  l, double  inst);
double vs_road_yaw (double  sta, double  direction);
double vs_road_yaw_i (double  sta, double  directiony, double  inst);
double vs_road_z (double  x, double  y);
double vs_road_z_i (double  x, double  yy, double  inst);
double vs_road_z_sl_i (double  s, double  l, double  inst);
double vs_s_loop (double  s);
double vs_target_l (double  s);
double vs_target_heading (double  s);

// moving objects and sensors (chapter 7)
int  vs_define_moving_objects (int n);
int  vs_define_sensors (int n);
void vs_free_sensors_and_objects (void);

// functions to get number of export variables for sensors in Simulink
int vs_get_n_export_sensor (int *max_connections);
int vs_get_sensor_connections (double *connect);

// configurable table functions (chapter 7)
int    vs_define_table (char *root, int ntab, int ninst);
double vs_table_calc (int index, double xcol, double x, int itab, int inst);
int    vs_table_index (char *name);
int    vs_table_ntab (int index);
int    vs_table_ninst (int index);

// saving and restoring the model state (chapter 8)
void   vs_free_saved_states (void);
int    vs_get_request_to_restore (void);
int    vs_get_request_to_save (void);
double vs_get_saved_state_time (double t);
double vs_restore_state (void);
void   vs_save_state (void);
void   vs_set_request_to_restore (double  t);
void   vs_start_save_timer (double  t);
void   vs_stop_save_timer (void);

// managing arrays to support restarts (chapter 8)
void vs_copy_all_state_vars_from_array (double  *array);
void vs_copy_all_state_vars_to_array (double  *array);
void vs_copy_differential_state_vars_from_array (double  *array);
void vs_copy_differential_state_vars_to_array (double  *array);
void vs_copy_extra_state_vars_from_array (double  *array);
void vs_copy_extra_state_vars_to_array (double  *array);
int  vs_get_export_names(char **expNames);
int  vs_get_import_names(char **impNames);
int  vs_n_derivatives (void);
int  vs_n_extra_state_variables (void);

// necessary but undocumented
int  vs_get_lat_pos_of_edge (int edge, double  s, int opt_road, double  *l);
void vs_scale_export_vars (void);
