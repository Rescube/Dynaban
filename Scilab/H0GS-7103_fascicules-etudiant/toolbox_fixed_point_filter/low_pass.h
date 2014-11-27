/*
* File:   band_stop.h
* Author: autogenerated
*
* Created on 
*/

#ifndef _LOW_PASS_H
  #define _LOW_PASS_H
  #define int_16_low_pass short int
  #define int_32_low_pass long int
  typedef struct {
      int nb_coeffs;
      int nb_states;
      int_16_low_pass *coeffs;
      int_32_low_pass *states;
  } s_16bits_filter_low_pass;
  typedef s_16bits_filter_low_pass *p_16bits_filter_low_pass;
  /* creator of structure p_16bits_filter_low_pass */
  extern p_16bits_filter_low_pass new_16bits_filter_low_pass(void);
  extern void destroy_16bits_filter_low_pass(p_16bits_filter_low_pass p_low_pass);
  extern int_32_low_pass one_step_16bits_filter_low_pass(int_16_low_pass en_16, p_16bits_filter_low_pass p_low_pass);
  typedef struct {
      int nb_cels;
      int nb_coeffs;
      int nb_states;
      double *coeffs;
      double *states;
  } s_real_filter_low_pass;
  typedef s_real_filter_low_pass *p_real_filter_low_pass;
  extern double one_step_real_filter_low_pass(double en, p_real_filter_low_pass f);
  extern void destroy_real_filter_low_pass(p_real_filter_low_pass f);
  extern p_real_filter_low_pass new_real_filter_low_pass(void);
#endif /* _LOW_PASS_H */
