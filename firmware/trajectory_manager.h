/*************************************************************************
*  File Name	: 'trajectory_manager.h'
*  Author	    : Remi FABRE
*  Contact      : remi.fabre@labri.fr
*  Created	    : vendredi, février  6 2015
*  Licence	    : http://creativecommons.org/licenses/by-nc-sa/3.0/
*
*  Notes:
*************************************************************************/

#include <wirish/wirish.h>
#include "motor.h"
#if !defined(TRAJECTORY_MANAGER_H)
#define TRAJECTORY_MANAGER_H

struct predictiveControl {
    int16 estimatedSpeed;
    int16 previousCommand;
};

uint16 traj_constant_speed(uint16 pDistance, uint16 pTotalTime, uint16 pTime);
uint16 traj_min_jerk(uint16 pTime);
uint16 traj_min_jerk_on_speed(uint16 pTime);
uint16 traj_eval_poly(volatile float * pPoly, unsigned char pPolySize, uint16 pDuration, uint16 pTime);
uint16 traj_eval_poly_derivate(volatile float * pPoly, unsigned char pPolySize, uint16 pDuration, uint16 pTime);
/*
 * a modulo b with a handling of the negative values that matches our needs
 */
uint16 traj_magic_modulo(uint16 a, uint16 b);
void predictive_control_init();
void predictive_control_tick(motor * pMot, int16 pVGoal, uint16 pDt, float pOutputTorque, float pIAdded);
void predictive_control_anti_gravity_tick(motor * pMot, int16 pVGoal, uint16 pDt, float pOutputTorque, float pIAdded);
void predictive_control_compliant_kind_of(motor * pMot, uint16 pDt);
void predictive_control_tick_simple(motor * pMot, int16 pVGoal);
float acceleration_from_weight(uint16 angle, float l);
float acceleration_from_weight_calib(uint16 angle);
int16 static_friction(int16 v);
float viscous_friction(int16 v);
int8 sign(int16 pInput);


#endif
