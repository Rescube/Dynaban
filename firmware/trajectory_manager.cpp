
/*************************************************************************
*  File Name	: 'trajectory_manager.cpp'
*  Author	: Remi FABRE
*  Contact      : remi.fabre@labri.fr
*  Created	: vendredi, février  6 2015
*  Licence	: http://creativecommons.org/licenses/by-nc-sa/3.0/
*
*  Notes:
*************************************************************************/

#include "trajectory_manager.h"


#define kDelta_old 3.5//5.076//4.820 -> first calibration with an empty arm
#define ke_old     0.582//0.614//0.6426
#define g      9.80665
#define m      0.270
#define L      0.12

#define STATIC_FRICTION 80
#define I0     0 //0.00353 kg.m**2 is the measured moment of inertia when empty (gear box)
#define V_ALIM 12
#define r      6
#define STAT_TO_COUL_TRANS 1300 // To be checked

static const float unitFactor = (3000*2*PI) / ((float)(V_ALIM*4096)); // == 0.3834 at 12V

static float torqueToCommand   = 3.75;//3.56; // Should be r/ke (ke ~ 1.6) = 3.75. To be used with torques expressed in [N.m * 4096 / 2*PI]
static float kv                = 1.65;//1.705;//1.462 // kv = ke + kvis
static float kstat             = STATIC_FRICTION / (torqueToCommand * unitFactor); // kstat * 1 * torqueToVolt * unitFactor should be equal to STATIC_FRICTION (min command to get the motor moving).
static float coulombMaxCommand = STATIC_FRICTION/4.567;
static float kcoul             = coulombMaxCommand / (torqueToCommand * unitFactor);

static predictiveControl pControl;

uint8 punchTicksRemaining = 0;


uint16 traj_constant_speed(uint32 pDistance, uint16 pTotalTime, uint16 pTime) {
    return ((float)pDistance/(float)pTotalTime) * pTime;
}

uint16 traj_min_jerk(uint16 pTime) {
    if (pTime > 10000) {
        return 0;
    }
    float time   = ((float)pTime)/10000.0;
    float time_3 = time*time*time;
    float time_4 = time_3*time;
    float time_5 = time_4*time;
    int32 a3     = 20480;
    int32 a4     = -30720;
    int32 a5     = 12288;

    return time_3*a3 + time_4*a4 + time_5*a5;
}

uint16 traj_min_jerk_on_speed(uint16 pTime) {
    if (pTime > 10000) {
        return 0;
    }
    float time   = ((float)pTime)/10000.0;
    float time_2 = time*time;
    float time_3 = time_2*time;
    float time_4 = time_3*time;
    int32 a3     = 20480;
    int32 a4     = -30720;
    int32 a5     = 12288;

    return time_2*a3*3 + time_3*a4*4 + time_4*a5*5;
}

void eval_powers_of_t(float * pTimePowers, uint16 pTime, uint8 pPolySize, uint16 pPrescaler) {
	if (pPolySize >= 5) {
		pTimePowers[0] = pTime/(float)pPrescaler; // t
		pTimePowers[1] = pTimePowers[0]*pTimePowers[0]; // t**2
		pTimePowers[2] = pTimePowers[1]*pTimePowers[0]; // t**3
		pTimePowers[3] = pTimePowers[2]*pTimePowers[0]; // t**4
	} else if (pPolySize == 4) {
		pTimePowers[0] = pTime/(float)pPrescaler; // t
		pTimePowers[1] = pTimePowers[0]*pTimePowers[0]; // t**2
		pTimePowers[2] = pTimePowers[1]*pTimePowers[0]; // t**3
		pTimePowers[3] = 0.0;
	} else if (pPolySize == 3) {
		pTimePowers[0] = pTime/(float)pPrescaler; // t
		pTimePowers[1] = pTimePowers[0]*pTimePowers[0]; // t**2
		pTimePowers[2] = 0.0;
		pTimePowers[3] = 0.0;
	} else if (pPolySize == 2) {
		pTimePowers[0] = pTime/(float)pPrescaler; // t
		pTimePowers[1] = 0.0;
		pTimePowers[2] = 0.0;
		pTimePowers[3] = 0.0;
	} else {
		pTimePowers[0] = 0.0;
		pTimePowers[1] = 0.0;
		pTimePowers[2] = 0.0;
		pTimePowers[3] = 0.0;
	}
}

int32 traj_eval_poly(volatile float * pPoly, float * pTimePowers) {

    return pPoly[0]
        + pTimePowers[0]*pPoly[1]
        + pTimePowers[1]*pPoly[2]
        + pTimePowers[2]*pPoly[3]
        + pTimePowers[3]*pPoly[4];
}

int32 traj_eval_poly_derivate(volatile float * pPoly, float * pTimePowers) {
    return pPoly[1]
        + pTimePowers[0]*2*pPoly[2]
        + pTimePowers[1]*3*pPoly[3]
        + pTimePowers[2]*4*pPoly[4];
}

/*
 * a modulo b with a handling of the negative values that matches our needs
 */
uint32 traj_magic_modulo(int32 a, uint32 b) {
    if (a > 0) {
        return a%b;
    } else {
        uint32 div = a/b;
        a = a + (abs(div)+1)*b;
        return a%b;
    }
}


void predictive_control_init() {
    pControl.estimatedSpeed = 1;
    pControl.previousCommand = 0;
}

/**
 * The formula used here is u(t) = unitFactor*[kv * v + torqueToCommand*(outputTorque + accelTorque + frictionTorque)]
 *
 * Where :
 * -> unitFactor*kv*v(t) is the command needed to mantain the current speed (kv = ke + kvis, where kvis is the viscous constant)
 * -> unitFactor*torqueToCommand*torque is the command that will make the motor create 'torque' (expressed in N.m*4096/2*PI) during dt
 * -> frictionTorque compensates the static and the coulomb friction
 * -> outputTorque is the actual torque that could be measured outside the motor
 * -> accelTorque  = I * a(t) is the torque needed to create an acceleration of a(t) during dt, provided that 'outputTorque' is
 * either null or absorbed by the environment (which is typically the case when it's used as a weight compensation)
 * -> I = I0 + pIAdded (I0 is the moment of inertia of the gearbox)
 * -> a(t) = (pVGoal - v)/dt
 */
void predictive_control_tick(motor * pMot, int32 pVGoal, uint32 pDt, float pOutputTorque, float pIAdded) {
    int32 v = pControl.estimatedSpeed;//pMot->speed;//pControl.estimatedSpeed;

    int8 signV = sign(v);
        // Hack for anti-gravity arm :
        /* The issue here is that our initial model states that the static friction depends on the sign of the current speed
         * which is true as long as the speed is not null.
         * When the speed is null, the static friction will oppose itself to the torque applied on the motor.
         **/
    // signV = pMot->signOfSpeed; // 1;

    float beta = exp(-abs( v / ((float)STAT_TO_COUL_TRANS) ));
    float accelTorque = ((float)(pVGoal - v) * (I0 + pIAdded) * 10000)/((float)pDt); // dt is in 1/10 of a ms
    float frictionTorque = signV * (beta * kstat + (1 - beta) * kcoul);

    int32 u = unitFactor *
        (kv * v + torqueToCommand * (accelTorque + frictionTorque + pOutputTorque));

    if (u > MAX_COMMAND) {
        u = MAX_COMMAND;
    }
    if (u < -MAX_COMMAND) {
        u = -MAX_COMMAND;
    }
    pMot->predictiveCommand = u;
    pControl.estimatedSpeed = pVGoal; /* Would be better if we could get the real-life speed from time to time to update this value.
                                       * This is no easy task since getting the speed from a derivate of the position comes with the
                                       * tradeoff delay VS accuracy.
                                       */
}

/**
 * The formula used here is u(t) = unitFactor*[kv * v + torqueToCommand*(outputTorque + accelTorque + frictionTorque)]
 *
 * Where :
 * -> unitFactor*kv*v(t) is the command needed to mantain the current speed (kv = ke + kvis, where kvis is the viscous constant)
 * -> unitFactor*torqueToCommand*torque is the command that will make the motor create 'torque' (expressed in N.m*4096/2*PI) during dt
 * -> frictionTorque compensates the static and the coulomb friction
 * -> outputTorque is the actual torque that could be measured outside the motor
 * -> accelTorque  = I * a(t) is the torque needed to create an acceleration of a(t) during dt, provided that 'outputTorque' is
 * either null or absorbed by the environment (which is typically the case when it's used as a weight compensation)
 * -> I = I0 + pIAdded (I0 is the moment of inertia of the gearbox)
 * -> a(t) = (pVGoal - v)/dt
 */
void predictive_control_anti_gravity_tick(motor * pMot, int32 pVGoal, uint32 pDt, float pOutputTorque, float pIAdded) {
	int32 v = pMot->speed;//(pMot->averageSpeed);//pControl.estimatedSpeed;

    pVGoal = v;

    int8 signV = sign(v);
        // Hack for anti-gravity/friction arm :
        /* The issue here is that our initial model states that the static friction depends on the sign of the current speed
         * which is true as long as the speed is not null.
         * When the speed is null, the static friction will oppose itself to the torque applied on the motor.
         **/
    signV = pMot->signOfSpeed;
    if (signV == 1) {
        digitalWrite(BOARD_LED_PIN, HIGH);
    } else if (signV == -1) {
        digitalWrite(BOARD_LED_PIN, LOW);
    } else {
        // digitalWrite(BOARD_LED_PIN, LOW);
    }
        // Un-comment this to emulate an old windows loading a program (quite funny actually)
    // if (pMot->averageCurrent > 0) {
    //     signV = 1;
    //     digitalWrite(BOARD_LED_PIN, LOW);
    // } else if (pMot->averageCurrent < 0) {
    //     signV = -1;
    //     digitalWrite(BOARD_LED_PIN, LOW);
    // } else {
    //     signV = 0;
    //     digitalWrite(BOARD_LED_PIN, HIGH);
    // }

    float beta = exp(-abs( v / ((float)STAT_TO_COUL_TRANS) ));
    float accelTorque = 0;
    float frictionTorque = signV * (beta * kstat + (1 - beta) * kcoul);

    int32 u = unitFactor *
        (kv * v + torqueToCommand * (accelTorque + frictionTorque + pOutputTorque));

    if (u > MAX_COMMAND) {
        u = MAX_COMMAND;
    }
    if (u < -MAX_COMMAND) {
        u = -MAX_COMMAND;
    }
    pMot->predictiveCommand = u;
    pControl.estimatedSpeed = pVGoal;
}

void predictive_control_compliant_kind_of(motor * pMot, uint32 pDt) {
    int32 v = pMot->speed;
    int32 vGoal = v;

    // Hack for anti-gravity/friction arm :
        /* The issue here is that our initial model states that the static friction depends on the sign of the current speed
         * which is true as long as the speed is not null.
         * When the speed is null, the static friction will oppose itself to the torque applied on the motor.
         **/
    int8 signV = pMot->signOfSpeed;

    float beta = exp(-abs( v / ((float)STAT_TO_COUL_TRANS) ));
    float frictionTorque = signV * (beta * kstat + (1 - beta) * kcoul);

    int32 u = unitFactor *
        (kv * v + torqueToCommand * (frictionTorque));

    if (u > MAX_COMMAND) {
        u = MAX_COMMAND;
    }
    if (u < -MAX_COMMAND) {
        u = -MAX_COMMAND;
    }
    pMot->predictiveCommand = u;
    pControl.estimatedSpeed = vGoal;
}

/**
 * The formula used here is u(t) = ke*v(t)  + (vGoal - v(t))*kDelta
 * Where kDelta = (I*r)/(dt*ke) ~= 4.820
 * and ke ~=0.6426
 */
void predictive_control_tick_simple(motor * pMot, int32 pVGoal) {
    int32 v = pControl.estimatedSpeed;
    int32 punchValue = 350;

    if (punchTicksRemaining > 0) {
            // We are in punch mode
        punchTicksRemaining--;
        pMot->predictiveCommand = sign(pVGoal) * punchValue;
        if (punchTicksRemaining == 0) {
            pControl.estimatedSpeed = 40;
        }
        return;
    }

    if (abs(v) < 40 && abs(v) < abs(pVGoal)) {
            // We assume that the actual speed is 0. The time the motor needs to start moving depends on the command.
            // The idea is to minimize that time. The motor needs ~6.1 ms to start moving when the command is at its maximum
        punchTicksRemaining = 1;
        pMot->predictiveCommand = (sign(pVGoal) * punchValue);
        pControl.estimatedSpeed = 0;
        return;

    }

        // Normal case
//    float angleRad = (pMot->angle * (float)PI) / 2048.0;
//    float weightCompensation = cos(angleRad) * 140.0;//235.0;
        // int32 u = kDelta * (float)(pVGoal - v) + ke * (float)v;
        // int32 u = kDelta * (float)(pVGoal - v + acceleration_from_weight_calib(pMot->angle)) + ke * (float)v;
    int32 u = kDelta_old * (float)(pVGoal - v)
        + ke_old * (float)v
        + static_friction(v);

        // + weightCompensation
        // + static_friction(v)
        // + viscous_friction(v);
        // int32 u = kDelta * (float)(acceleration_from_weight_calib(pMot->angle));

        // int32 u = kDelta * ((float)(pVGoal - v) + acceleration_from_weight(pMot->angle, L)) + ke * (float)v;
    if (u > MAX_COMMAND) {
        u = MAX_COMMAND;
    }
    if (u < -MAX_COMMAND) {
        u = -MAX_COMMAND;
    }
    pMot->predictiveCommand = u;
    pControl.estimatedSpeed = pVGoal; 	/* Would be better if we could get the real-life speed from time to time to update this value.
     	 	 	 	 	 	 	 	 	 * This is no easy task since getting the speed from a derivate of the position comes with the
										 * tradeoff delay VS accuracy.
										 */

}


int8 sign(int32 pInput) {
    if (pInput > 0) {
        return 1;
    } else if (pInput < 0) {
        return -1;
    } else {
        return 0;
    }
}
