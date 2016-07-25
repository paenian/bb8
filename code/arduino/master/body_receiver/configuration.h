/* This file contains global variables shared by the component sketches.
 * Mainly pin assignments, so that the sending remote control can reference
 * pins on the receivers.
 *
 *
 * BB-8 is set up as three Arduinos at present, linked by an Xbee radio bridge.
 *
 * The REMOTE contains joysticks and action buttons, and sends commands to the
 * receivers.  For the joysticks, it really will be simply turning a pin on to
 * match; the button presses will need actual commands.

 * The BODY controls the body and head motion - receiving serial data, it'll be
 *  almost entirely joystick mirroring, plus probably some LEDs for good measure.

 * The HEAD controls funny noises and blinking.

 * All three will share battery management code; the monitoring circuit varies
 *  slightly, in that the REMOTE and HEAD will have small LIPO batteries, but
 *  the body gets a monstrosity.
*/

#define CONTROLCHAR 'T'
#define BODYCHAR 'B'
#define HEADCHAR 'H'

/*
 * Desired pins
 *  Remote Pins
 *   body l/r - analog input - a2
 *   body f/r - analog input - a3
 *   body spin l - digital input - D12
 *   body spin r - digital input - D13
 *   head l/r angle - analog input - a6
 *   head f/r - analog input - a7
 *   head spin - analog input - a0
 *   battery monitor - analog input - a1

 *   keypad - I2C SCL - A5
 *   keypad - I2C SDA - A4
 *    - Could also use software I2C to free up these analog pins.

 *   software serial TX - xbee - D7 ####using hardware serial for now
 *   software serial RX - xbee - D8 ####using hardware serial for now

 *  what's left:
 *    Digital pins... but the keypad's got 16 buttons, not sure we need anything
 *    more.
*/
////// These are all INPUT pins used on the CONTROLLER
////// The BODY module has its own output pins.
#define CONTROL_BODY_POT_LR_APIN 2
#define CONTROL_BODY_POT_FR_APIN 3
#define CONTROL_BODY_SPIN_LEFT_DPIN 12
#define CONTROL_BODY_SPIN_RIGHT_DPIN 13
#define CONTROL_HEAD_POT_LR_APIN 6
#define CONTROL_HEAD_POT_FR_APIN 7
#define CONTROL_HEAD_POT_A_APIN 0
#define CONTROL_BATTERY_MONITOR_APIN 1
#define CONTROL_BATTERY_SHUTDOWN_DPIN 4


/*
*** Body Pins
 *  body l/r - PWM output - D11 - connect to servo(s)
 *  body f/r - PWM output - D10 - connect to dagu 4 motor
 *  body f/r - digital output - D12 - direction
 *  body spin l/r - PWM output - D3
 *  body spin l/r - digital output - D2
 *  Head l/r angle - pwm output - D5 - servo
 *  Head f/r angle - pwm output - D6 - servo
 *  Head spin - pwm output - D9 - continuous servo

 *  software serial TX - xbee - D7
 *  software serial RX - xbee - D8

 *  battery monitor - analog input - a1

 *  What's left:
 *   No more PWM!  Plenty of analog in, D4...
*/
#define BODY_LR_ANGLE_PIN 11
#define BODY_FR_SPEED_PIN 10
#define BODY_FR_DIR_PIN 12
#define BODY_SPIN_SPEED_PIN 3
#define BODY_SPIN_DIR_PIN 2
/*
*** Head Pins
 *  WaveShield - SPI - D11
 *  WaveShield - SPI - D12
 *  WaveShield - SPI - D13
 *  WaveShield - SD card - D10
 *  WaveShield - DAC - D2
 *  WaveShield - DAC - D3
 *  WaveShield - DAC - D4
 *  WaveShield - DAC - D5

 *  software serial TX - xbee - D7
 *  software serial Rx - xbee - D8
 *
 *  battery monitor - analog input - a1
 */
