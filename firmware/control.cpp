#include "control.h"

static control controlStruct;


// Returns the spin direction the motor needs to follow in order to respect its limit angles
int8 choose_direction(motor * pMot);

int8 viable_direction(motor * pMot, long pDiffToGoal);

control * get_control_struct() {
    return &controlStruct;
}

void control_init() {
    controlStruct.deltaAngle = 0;
    controlStruct.deltaSpeed = 0;
    controlStruct.deltaAcceleration = 0;
    controlStruct.deltaAverageCurrent = 0;

    controlStruct.sumOfDeltas = 0;

    controlStruct.pCoef = INITIAL_P_COEF;
    controlStruct.iCoef = INITIAL_I_COEF;
    controlStruct.dCoef = INITIAL_D_COEF;
    controlStruct.speedPCoef = INITIAL_SPEED_P_COEF;
    controlStruct.accelerationPCoef = INITIAL_ACCELERATION_P_COEF;
    controlStruct.torquePCoef = INITIAL_TORQUE_P_COEF;
}


void control_reset() {
    controlStruct.deltaAngle = 0;
    controlStruct.deltaSpeed = 0;
    controlStruct.deltaAcceleration = 0;
    controlStruct.deltaAverageCurrent = 0;

    controlStruct.sumOfDeltas = 0;
}


void control_tick_PID_on_position(motor * pMot) {
    controlStruct.deltaAngle = control_angle_diff(pMot->targetAngle, pMot->angle);
    int8 direction = choose_direction(pMot);
    if ((direction != 0) && (controlStruct.deltaAngle * direction < 0)) {
            // The shortest way is not viable, we'll have to go the other way around
        controlStruct.deltaAngle = control_other_angle_diff(pMot->targetAngle, pMot->angle);
        digitalWrite(BOARD_LED_PIN, LOW);
    } else {
        digitalWrite(BOARD_LED_PIN, HIGH);
    }

    controlStruct.sumOfDeltas = controlStruct.sumOfDeltas + controlStruct.deltaAngle;
    if (controlStruct.sumOfDeltas > MAX_DELTA_SUM) {
        controlStruct.sumOfDeltas = MAX_DELTA_SUM;
    } else if (controlStruct.sumOfDeltas < -MAX_DELTA_SUM) {
        controlStruct.sumOfDeltas = -MAX_DELTA_SUM;
    }


    motor_set_command(controlStruct.deltaAngle * controlStruct.pCoef
                      + (controlStruct.sumOfDeltas * controlStruct.iCoef) / I_PRESCALE
                      + pMot->speed * controlStruct.dCoef);
}


void control_tick_P_on_position(motor * pMot) {
    controlStruct.deltaAngle = control_angle_diff(pMot->targetAngle, pMot->angle);
    int8 direction = choose_direction(pMot);
    if ((direction != 0) && (controlStruct.deltaAngle * direction < 0)) {
            // The shortest way is not viable, we'll have to go the other way around
        controlStruct.deltaAngle = control_other_angle_diff(pMot->targetAngle, pMot->angle);
    }

    motor_set_command(controlStruct.deltaAngle * controlStruct.pCoef);
}

void control_tick_predictive_command_only(motor * pMot) {
    motor_set_command(pMot->predictiveCommand);
}

void control_tick_PID_and_predictive_command(motor * pMot) {
    controlStruct.deltaAngle = control_angle_diff(pMot->targetAngle, pMot->angle);
    int8 direction = choose_direction(pMot);
    if ((direction != 0) && (controlStruct.deltaAngle * direction < 0)) {
            // The shortest way is not viable, we'll have to go the other way around
        controlStruct.deltaAngle = control_other_angle_diff(pMot->targetAngle, pMot->angle);
    }

    controlStruct.sumOfDeltas = controlStruct.sumOfDeltas + controlStruct.deltaAngle;
    if (controlStruct.sumOfDeltas > MAX_DELTA_SUM) {
        controlStruct.sumOfDeltas = MAX_DELTA_SUM;
    } else if (controlStruct.sumOfDeltas < -MAX_DELTA_SUM) {
        controlStruct.sumOfDeltas = -MAX_DELTA_SUM;
    }

    motor_set_command(controlStruct.deltaAngle * controlStruct.pCoef
                      + (controlStruct.sumOfDeltas * controlStruct.iCoef) / I_PRESCALE
                      + pMot->speed * controlStruct.dCoef
                      + pMot->predictiveCommand);

}

void control_tick_P_on_speed(motor * pMot) {
    controlStruct.deltaSpeed = pMot->targetSpeed - pMot->speed;

    motor_set_command(controlStruct.deltaSpeed * INITIAL_SPEED_P_COEF);
}

/*Desactivated because it does not work well.
 *This control loop approach is simplistic and the precision on the speed control loop forces a gigantic delay of 128ms. -> Needs to be worked on.*/
void control_tick_P_on_acceleration(motor * pMot) {

    /*controlStruct.deltaAcceleration = pMot->targetAcceleration - pMot->acceleration;

      motor_set_command(controlStruct.deltaAcceleration * INITIAL_ACCELERATION_P_COEF);*/
}

void control_tick_P_on_torque(motor * pMot) {
    controlStruct.deltaAverageCurrent = pMot->targetCurrent - pMot->averageCurrent;

    // /!\ the -1 conspiracy continues
    long command = - controlStruct.deltaAverageCurrent * INITIAL_TORQUE_P_COEF;

    motor_set_command(command);
}

/**
 * Returns the signed difference between 2 angles
 */
long control_angle_diff(long a, long b) {
    long diff = a - b;
    if (diff > (MAX_ANGLE+1)/2) {
        return diff - MAX_ANGLE;
    }
    if (diff < -(MAX_ANGLE+1)/2) {
        return diff + MAX_ANGLE;
    }

    return diff;
}

/**
 * Returns the other angle between 2 angles (the bigger one, aka the one that is bigger than MAX_ANGLE/2)
 */
long control_other_angle_diff(long a, long b) {
    long diff = a - b;
    if (diff > 0 && diff < (MAX_ANGLE+1)/2) {
        return diff - MAX_ANGLE;
    }
    if (diff < 0 && diff > -(MAX_ANGLE+1)/2) {
        return diff + MAX_ANGLE;
    }

    return diff;
}
// TO DO : there is a bug when the goal angle is 180° away from the present angle. The problem desapears in the free wheel mode. Also when the dead zone is too short, inertia makes it impossible for the motor to stop before going through it, the behaviour that comes after is strange -> to be investigated
int8 choose_direction(motor * pMot) {

    if (pMot->posAngleLimit == pMot->negAngleLimit) {
            // Wheel mode
        return 0;
    }

    if (motor_is_valid_angle(pMot->angle) == false) {
        return 0;
    }

    if (pMot->targetAngle == pMot->posAngleLimit) {
        return 1;
    }
    if (pMot->targetAngle == pMot->negAngleLimit) {
        return -1;
    }

    long diff = control_angle_diff(pMot->targetAngle, pMot->angle);
    if (diff == 0) {
        return 0;
    } else {
        return viable_direction(pMot, diff);
    }
}


int8 viable_direction(motor * pMot, long pDiffToGoal) {
    long diffToLimit = 0;

    if (pDiffToGoal > 0) {
            // We are spining positively
        diffToLimit = control_angle_diff(pMot->posAngleLimit, pMot->angle);
        if (diffToLimit < 0) {
            diffToLimit = control_other_angle_diff(pMot->posAngleLimit, pMot->angle);
        }

            // Would we get to the limit before the goal?
        if (pDiffToGoal <= diffToLimit) {
            return 1;
        } else {
            return -1;
        }
    } else {
            // We're spinning negatively
        diffToLimit = control_angle_diff(pMot->negAngleLimit, pMot->angle);
        if (diffToLimit > 0) {
            diffToLimit = control_other_angle_diff(pMot->negAngleLimit, pMot->angle);
        }

            // Would we get to the limit before the goal?
        if (pDiffToGoal >= diffToLimit) {
            return -1;
        } else {
            return 1;
        }
    }
}


#if BOARD_HAVE_SERIALUSB
void control_print() {
    SerialUSB.println("***Control :");
    SerialUSB.print("deltaAngle : ");
    SerialUSB.println(controlStruct.deltaAngle);
}
#else
void control_print() {
    Serial1.println();
    Serial1.println("***Control :");
    Serial1.print("deltaAngle : ");
    Serial1.println(controlStruct.deltaAngle);
    Serial1.print("sumOfDeltas : ");
    Serial1.println(controlStruct.sumOfDeltas);
    Serial1.print("deltaAverageCurrent : ");
    Serial1.println(controlStruct.deltaAverageCurrent);
}
#endif
