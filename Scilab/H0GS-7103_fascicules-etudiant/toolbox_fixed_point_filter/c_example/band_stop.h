/*
* File:   band_stop.h
* Author: autogenerated
*
* Created on
*/

#ifndef _BAND_STOP_H
  #define _BAND_STOP_H
  #define int_16_band_stop short int
  #define int_32_band_stop long int
  typedef struct {
      int nb_coeffs;
      int nb_states;
      int_16_band_stop *coeffs;
      int_32_band_stop *states;
  } s_16bits_filter_band_stop;
  typedef s_16bits_filter_band_stop *p_16bits_filter_band_stop;
  /* creator of structure p_16bits_filter_band_stop */
  extern p_16bits_filter_band_stop new_16bits_filter_band_stop(void);
  extern void destroy_16bits_filter_band_stop(p_16bits_filter_band_stop p_band_stop);
  extern int_32_band_stop one_step_16bits_filter_band_stop(int_16_band_stop en_16, p_16bits_filter_band_stop p_band_stop);
  typedef struct {
      int nb_cels;
      int nb_coeffs;
      int nb_states;
      double *coeffs;
      double *states;
  } s_real_filter_band_stop;
  typedef s_real_filter_band_stop *p_real_filter_band_stop;
  extern double one_step_real_filter_band_stop(double en, p_real_filter_band_stop f);
  extern void destroy_real_filter_band_stop(p_real_filter_band_stop f);
  extern p_real_filter_band_stop new_real_filter_band_stop(void);
#endif /* _BAND_STOP_H */
