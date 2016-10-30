/*****************************************************************
This is the Control side of a remote control using a modified
version of the XBEE remote control code.

It sends commands in response to controller input, and transmits
to both the body and the head.


This sketch has been augmented by Paul Chase to allow for multiple
receivers.  Commands must be preceeded with $ to distinguish them
from comments, then the single-character ReceiverChar.


This code is beerware; if you see me (or any other SparkFun 
employee) at the local, and you've found our code helpful, please
buy us a round!  Paul Chase would like a beer too :-)

Distributed as-is; no warranty is given.
*****************************************************************/
// SoftwareSerial is used to communicate with the Serial
//#include <SoftwareSerial.h>
// Trying it using hardware serial instead to avoid conflict with
//  the servo library.
#include "configuration.h"
#include "Adafruit_Trellis.h"
#include <Wire.h>

//comment this out to turn serial debugging off.
//With it on, you can monitor the debugging with an xbee over the
//Arduino serial monitor.
#define DEBUG 1

#define MAX_SERIAL_WAIT 250
#define MAX_CHARS_TO_READ 25

uint8_t pot_slop = 12;	//don't send a message unless the pot
			//reading is + or - this value.  Pots are 10 bit, so 1024 values.

////////Pin Defines are in the configuration.h!

////////Potentiometer Variables - these are stored as bytes, converted
// when they're read.
// 0 is full reverse, 1023 full stop, 512 full forward
int bodyPot[3] = {512, 512, 512}; //the third is actually binary here, to spin the body.
int bodyAtt[3] = {512, 512, 512}; //the current body attitude
int bodyPotZero[3] = {512, 512, 512}; //everything perfectly centered


int headPot[3] = {512, 512, 512}; //the third is angle, for turning the head; it's in tens of degrees.
int headAtt[3] = {512, 512, 512}; //the current head attitude
int headPotZero[3] = {512, 512, 512}; //perfectly centered

//the 16 button array is the trellis
Adafruit_Trellis array = Adafruit_Trellis();
Adafruit_TrellisSet trellis = Adafruit_TrellisSet(&array);
uint8_t tellis_INTPIN = 0;  //the interrupt pin - we're not going to use it, just poll instead
//also need to connect the SDA and SCL pins :-)

////////Battery Voltage
// We also track battery voltage for the body, head and controller itself.
int controllerVoltage = 0;
int bodyVoltage = 0;
int headVoltage = 0;

uint8_t headDisabled = 0;
uint8_t bodyDisabled = 0;

#define allStopLedIndex 12
#define controllerLedIndex 13
#define bodyLedIndex 14
#define headLedIndex 15

//batteries can't be below MIN_VOLTAGE
#define MIN_VOLTAGE 3
//and we check them every INTERVAL
#define BATTERY_CHECK_INTERVAL 10000

unsigned long lastBatteryCheck = millis();


void readBodyPot(uint8_t numSamples){
  int x=0;
  int y=0;

  //Spin? This isn't used yet... or maybe ever.. so we read it as 512.
  bodyPot[2] = 512;
  
  //XY movement
  for(uint8_t i=0; i<numSamples; i++){
    analogRead(CONTROL_BODY_POT_LR_APIN);
    x += analogRead(CONTROL_BODY_POT_LR_APIN);
    analogRead(CONTROL_BODY_POT_FR_APIN);
    y += analogRead(CONTROL_BODY_POT_FR_APIN);
    
#ifdef DEBUG
  Serial.println("readBodyPot: Raw");
  Serial.print("X: ");
  Serial.println(x);
  Serial.print("Y: ");
  Serial.println(y);
#endif
  }

  //cheap average
  bodyPot[0] = map(x, 0, 1023*numSamples, 1, 1023);
  bodyPot[1] = map(y, 0, 1023*numSamples, 1, 1023);

  //adjust to the true zero voltage of our pots
  bodyPot[0] = constrain(bodyPot[0] + (bodyPotZero[0] - 512), 1, 1023);
  bodyPot[1] = constrain(bodyPot[1] + (bodyPotZero[1] - 512), 1, 1023);

#ifdef DEBUG
  Serial.println("readBodyPot: Values");
  Serial.print("{ ");
  for(uint8_t i = 0; i<3; i++){
    Serial.print(bodyPot[i]);
    Serial.print("\t, ");
  }
  Serial.println("}");
#endif
}

void readBodyPot(){
  readBodyPot(1);
}

void initTrellis(){
  //need to put a pullup on the int pin, if we decide to use it
  trellis.begin(0x70);
  
  //do a little LED dance
  for(uint8_t i=0; i<4; i++){
    for(uint8_t j=0; j<4; j++){
      trellis.setLED(i*4+j);
      trellis.writeDisplay();
      delay(100);
    }
  }
  
  //shut them off.  Notice the different style - wondering if they're in order :-)
  for(uint8_t i=0; i<16; i++){
    trellis.clrLED(i);
    trellis.writeDisplay();
    delay(50);
  }
}

void initBodyPot(){
  pinMode(CONTROL_BODY_SPIN_LEFT_DPIN, INPUT_PULLUP);
  pinMode(CONTROL_BODY_SPIN_RIGHT_DPIN, INPUT_PULLUP);

  for(uint8_t i=1; i<3; i++)
    bodyPotZero[i] = 512;
  bodyPotZero[0] = 900;

  readBodyPot(5);

  memcpy( bodyPotZero, bodyPot, sizeof(bodyPotZero));
  memcpy( bodyAtt, bodyPot, sizeof(bodyAtt));
}

void initHeadPot(){
  for(uint8_t i=0; i<3; i++)
    headPotZero[i] = 900;

  readHeadPot(5);

  memcpy( headPotZero, headPot, sizeof(headPotZero));
  memcpy( headAtt, headPot, sizeof(headAtt));
}

void readHeadPot(){
  readHeadPot(1);
}

void readHeadPot(uint8_t numSamples){
  int x=0;
  int y=0;
  int a=0;

  for(uint8_t i=0; i<numSamples; i++){
    x += analogRead(CONTROL_HEAD_POT_LR_APIN);
    y += analogRead(CONTROL_HEAD_POT_FR_APIN);
    a += analogRead(CONTROL_HEAD_POT_A_APIN);
  }

  //cheap way to calculate the average
  headPot[0] = map(x, 0, 1023*numSamples, 1, 1023);
  headPot[1] = map(y, 0, 1023*numSamples, 1, 1023);
  headPot[2] = map(a, 0, 1023*numSamples, 1, 1023);

  //account for the zero point
  headPot[0] = constrain(headPot[0] + (headPotZero[0] - 512), 1, 1023);
  headPot[1] = constrain(headPot[1] + (headPotZero[1] - 512), 1, 1023);
  headPot[2] = constrain(headPot[2] + (headPotZero[2] - 512), 1, 1023);
}

void readButtonArray(){
  trellis.readSwitches();
}

bool arraysDifferent(int pot[], int att[]){
  #ifdef DEBUG
  Serial.println("ArraysDifferent: Values");
  Serial.print("{ ");
  for(uint8_t i = 0; i<3; i++){
    Serial.print(pot[i]);
    Serial.print("\t, ");
  }
  Serial.println("}");

    Serial.print("{ ");
  for(uint8_t i = 0; i<3; i++){
    Serial.print(att[i]);
    Serial.print("\t, ");
  }
  Serial.println("}");
  
#endif

  //first see if the controls have changed
  for(uint8_t i=0; i<2; i++){
    if((att[i] > pot[i]+pot_slop) || (att[i] < pot[i]-pot_slop)){
      return true; 
    }
  }

#ifdef DEBUG
  Serial.println("ArraysDifferent: returning false");
#endif

  return false;
}

/******** Sending and Recieving Xbee! **********/

//send an analog value to a pin
void sendPWMPin(char dest, uint8_t pin, int val){
  Serial.print('$');
  Serial.print(dest);
  Serial.print('W');
  Serial.print(InttoASCII(pin));
  Serial.print(pad(val, 3));
}

//send a digital value to a pin
void sendDPin(char dest, uint8_t pin, int val){
  Serial.print('$');
  Serial.print(dest);
  Serial.print('D');
  Serial.print(InttoASCII(pin));
  Serial.print(val);
}

//send a servo angle to a pin
void sendSPin(char dest, uint8_t pin, int val){
  Serial.print('$');
  Serial.print(dest);
  Serial.print('S');
  Serial.print(InttoASCII(pin));
  Serial.print(pad(val, 3));
}

// send a value back to the controller - called in any of the read
//  functions.
void sendValue(char sendChar, char label, int value){
  Serial.print('$'+sendChar);
  Serial.print(label);
  if(label == 'A'){
    Serial.print(pad(value, 4));
  }else{
    Serial.print(value);
  }
}

//send speed and direction in a single function
void sendSpeedDir(char dest, uint8_t speed_pin, uint8_t dir_pin, int val){
  if( val >= 512 ){
    //send the speed first
    sendPWMPin(dest, speed_pin, map(val, 512, 1024, 0, 255));

    //and then the direction
    sendDPin(dest, dir_pin, 1);
  }else{
    //speed first again
    sendPWMPin(dest, speed_pin, map(val, 0, 511, 0, 255));

    //and then the direction
    sendDPin(dest, dir_pin, 0);
  }
}

//send angle - which is 0 to 1800
void sendAngle(char dest, uint8_t pin, int val){
  sendSPin(dest, pin, map(val, 0, 1800, 0, 180));
}


/*********** NEW PROTOCOL - do not use other send functions. *******/
void sendBody(){
  //looks like $BCBX###Y###
  uint8_t x = map(bodyAtt[0], 0, 1023, 0, 255);
  uint8_t y = map(bodyAtt[1], 0, 1023, 0, 255);

  Serial.print('$');
  Serial.print(BODYCHAR);
  Serial.print(CONTROLCHAR);
  Serial.print("BX");
  Serial.print(pad(x, 3));
  Serial.print("Y");
  Serial.print(pad(y, 3));
}

void sendHead(){
  //looks like $BCHX###Y###A###
  uint8_t x = map(headAtt[0], 0, 1023, 0, 255);
  uint8_t y = map(headAtt[1], 0, 1023, 0, 255);
  uint8_t a = map(headAtt[2], 0, 1023, 0, 255);

  Serial.print('$');
  Serial.print(BODYCHAR);
  Serial.print(CONTROLCHAR);
  Serial.print("HX");
  Serial.print(pad(x, 3));
  Serial.print("Y");
  Serial.print(pad(y, 3));
  Serial.print("A");
  Serial.print(pad(y, 3));
}

void sendStop(){
  //need to send two - to the head and the body.
  //Looks like $BCSTOP and $HCSTOP
  //
  //Only the first character (S) is actually read.  The rest is for debugging.
  //If a human can read the chatter, a human can debug the chatter :-)
  
  Serial.print('$');
  Serial.print(BODYCHAR);
  Serial.print(CONTROLCHAR);
  Serial.print("STOP");

  Serial.print('$');
  Serial.print(HEADCHAR);
  Serial.print(CONTROLCHAR);
  Serial.print("STOP");
}

void sendHeartbeat(){
  //not sure what to send as a heartbeat, or how to handle it.  For now, we'll just send the current head and body positions.
  sendBody();
  sendHead();

  //the heartbeat can then be implemented entirely in the body.  The head doesn't get a heartbeat, cuz it doesn't do anything crazy.
  //like... move around.
  //The point here is that if the body loses signal, it'll stop running away eventually.
}

void sendTrellisButton(uint8_t button){
  //these go to the head
  //looks like $HP##
  Serial.print('$');
  Serial.print(HEADCHAR);
  Serial.print(CONTROLCHAR);
  Serial.print('P');
  Serial.print(pad(button, 2));
}

void requestBodyBattery(){
  Serial.print('$');
  Serial.print(BODYCHAR);
  Serial.print(CONTROLCHAR);
  Serial.print("RBATT");
}

void requestHeadBattery(){
  Serial.print('$');
  Serial.print(HEADCHAR);
  Serial.print(CONTROLCHAR);
  Serial.print("RBATT");
}

//get results from battery questions, accept commands
//right now, the battery's the only thing we care about.
//This function will consume ONE command, or MAX_CHARS_TO_READ characters before returning.
void readXbee(){
  
  //this will consume many characters - maybe too many.
  //So we set a max.
  int chars = 0;
  //WAIT for at least 4 characters to be in the buffer before doing anything!
  while((Serial.available() > 3) && (chars < MAX_CHARS_TO_READ)){
    char c = Serial.read();  //three chars left
    chars++;
    
    if(c == '$'){  //look for a command :-)
      c = Serial.read();  //two chars left
      chars++;
      
      if(c == CONTROLCHAR){  //whoa, the command might be for us!
        c = Serial.read();  //there's still one character in there.
        chars++;
        
        switch(c){
          case 'S': //stop char!
            c = Serial.read();
            if(c == BODYCHAR){
              bodyDisabled = 1;
            }
            if(c == HEADCHAR){
              headDisabled = 1;
            }
            //if it's the head, whatevs.
          return;
          
          case 'V': //returning a value to read
          return;
        }
      }
    }
    
    if(chars > MAX_CHARS_TO_READ){
      return;
    }
  }
}

//simple code to block while reading the serial bus.
char readSerialBlocking(){
  unsigned long start = millis();
  
  while(Serial.available() == 0){
    if(millis()-start > MAX_SERIAL_WAIT){
#ifdef DEBUG
      Serial.println("Timeout waiting for character!");
#endif
      return -1;
    }
  }
  
  return Serial.read();
}


/*********** END NEW PROTOCOL - do not use other send functions. *******/

////////Handlers for position changes
void handleBodyPot(){
  if(!arraysDifferent(bodyPot, bodyAtt)){
    return;
  }

#ifdef DEBUG
  Serial.println("handleBodyPot: Pot Changed");
#endif

  //if any of them updated, great!  Update 'em all.
  memcpy( bodyAtt, bodyPot, sizeof(bodyAtt));

  //let the body know what's up
  sendBody();
}

void handleHeadPot(){ //xya joystick
  if(!arraysDifferent(headPot, headAtt)){
    return;
  }

#ifdef DEBUG
  Serial.println("handleHeadPot: Pot Changed");
#endif

  //if any of them updated, great!  Update 'em all.
  memcpy( headAtt, headPot, sizeof(headAtt));

  //and then send them all, for good measure - this prevents creep,
  sendHead();
}

void handleButtonArray(){ //funny noises in a big fancy grid
  //go through the button array, see which was pressed
  //these are the sound buttons :-)
  for(uint8_t i=0; i<12; i++){
    if(trellis.justPressed(i)){
      sendTrellisButton(i);
    }
  }
  
  //the other four buttons are indicators, and the kill switch.
  //check for disabled stuff, and flash the appropriate button.
  if(trellis.justPressed(allStopLedIndex)){
    sendStop();
    shutdownController(); 
  }
  
  //the other buttons can't be pressed yet, but they blink if something's dead.
  if(headDisabled == 1){
    trellis.setLED(headLedIndex);
    trellis.writeDisplay();
    delay(125);
    trellis.clrLED(headLedIndex);
    trellis.writeDisplay(); 
  }
  
  if(bodyDisabled == 1){
    trellis.setLED(bodyLedIndex);
    trellis.writeDisplay();
    delay(125);
    trellis.clrLED(bodyLedIndex);
    trellis.writeDisplay(); 
  }
  
}

void shutdownButtonArray(){
  //simply turn off all the LEDs - this is to prevent battery drain when the controller batteries are low.
  for(uint8_t i=0; i<16; i++){
    trellis.clrLED(i);
  }
  
  //here's an idea: 12 buttons, and 4 status LEDs that look like buttons :-)
  //battery for the head, body and controller - blink red if low?
  //last LED open for now :-)
}


////////BATTERY AND SHUTDOWN

//reads the controller's voltage
int checkBattery(){
  //todo: actually read the battery voltage.
  return MIN_VOLTAGE+.1;
}

// Used to safe the robot if the controller battery is low.
// The controller monitors its battery, and shuts down the body and
// head before it packs in itself.
void checkBatteryForShutdown(){

  //if the controller's low, everything has to go down with it.
  if(controllerVoltage < MIN_VOLTAGE){
    sendStop();
    shutdownButtonArray();

    //blink the right trellis thinger annoyingly
    for(uint8_t i=0; i<100; i++){
      if(i%0 == 0){
        trellis.setLED(controllerLedIndex);
      }else{
        trellis.clrLED(controllerLedIndex);
      }

      delay(50);
    }

    shutdownController();
  }

  //if the body's low, blink the body, but we don't need to do anything else
  //the body will prevent itself from moving on low batt
  if(bodyVoltage < MIN_VOLTAGE){
    bodyDisabled = 1;
  }

  //if the head is low, blink the head, but we don't need to worry any further.
  if(headVoltage < MIN_VOLTAGE){
    headDisabled = 1;
  }
  
  //if it's been a while since the last check, reread the voltages.
  //This only asks for them - they're read in the serial message handling area.
  if(millis() > lastBatteryCheck + BATTERY_CHECK_INTERVAL){
    requestBodyBattery();
    requestHeadBattery();
    lastBatteryCheck = millis();
  }
}

void shutdownController(){
  //turn all LEDs off
  shutdownButtonArray();
  
  //disconnect the battery so it doesn't get too low
  delay(10000);
}

// ASCIItoHL
// Helper function to turn an ASCII value into either HIGH or LOW
int ASCIItoHL(char c)
{
  // If received 0, byte value 0, L, or l: return LOW
  // If received 1, byte value 1, H, or h: return HIGH
  if ((c == '0') || (c == 0) || (c == 'L') || (c == 'l'))
    return LOW;
  else if ((c == '1') || (c == 1) || (c == 'H') || (c == 'h'))
    return HIGH;
  else
    return -1;
}

// ASCIItoInt
// Helper function to turn an ASCII hex value into a 0-15 byte val
int ASCIItoInt(char c)
{
  if ((c >= '0') && (c <= '9'))
    return c - 0x30; // Minus 0x30
  else if ((c >= 'A') && (c <= 'F'))
    return c - 0x37; // Minus 0x41 plus 0x0A
  else if ((c >= 'a') && (c <= 'f'))
    return c - 0x57; // Minus 0x61 plus 0x0A
  else
    return -1;
}

//todo: test this function :-)
char InttoASCII(int i){
  if((i >= 0) && (i <= 9)){
    return (char)(i+0x30);
  }
  else if ((i >= 10) && (i <= 15))
    return (char)(i + 0x37); // Minus 0x41 plus 0x0A
  else
    return -1;  
}

String pad(int number, byte length){
  String ret = "";
  int curMax = 10;
  for(byte i=1; i<length; i++){
    if(number < curMax)
      ret += "0";

    curMax *= 10;
  }

  return ret + number;
}

// printMenu
// A big ol' string of Serial prints that print a usage menu over
// to the other Serial.
void printMenu()
{
#ifdef DEBUG
  // Everything is "F()"'d -- which stores the strings in flash.
  // That'll free up SRAM for more importanat stuff.
  Serial.println();
  Serial.println(F("Arduino Serial BB8 Control!"));
  Serial.println(F("============================"));
  Serial.println(F("Usage: "));
  Serial.println(F("Command format is $, TO_CHAR, FROM_CHAR, COMMAND*"));
  Serial.println(F("All numbers are fixed length, zero padded"));
  Serial.println();
  Serial.println(F("$BCBX127Y127        -> to Body from Controller Body motion X127 Y127"));
  Serial.println(F("$BCHX***Y***A***    -> Move head - note X, Y and Angle of Rotation."));
  Serial.println(F("$BCSTOP             -> Full stop to the body"));
  Serial.println(F("$HCSTOP             -> Full stop to the head"));
  Serial.println(F("$BCRBATT            -> Have the body send us its battery voltage"));
  Serial.println(F("$CBVB***            -> Here's that voltage you wanted, controlleer"));
  Serial.println(F("$HCP02              -> Play sound effect 02 - goes from 00 to 11"));
  Serial.println(F("  e.g. a0 - Read analog pin 0"));
  Serial.println();
  Serial.println(F("============================"));  
  Serial.println();
#endif
}

void setup()
{
  // Initialize Serial Software Serial port. Make sure the baud
  // rate matches your Serial setting (9600 is default).
  Serial.begin(9600); 

  //initialize the trellis
  initTrellis();

  //Initialize the potentiometers
  //body pot: two axes
  initBodyPot();

  //head pot: three axes
  initHeadPot();

#ifdef DEBUG
  printMenu(); // Print a helpful menu
#endif
}

void loop()
{
#ifdef DEBUG
  Serial.println("Loop Start"); // Print a helpful menu
#endif
  //check the battery voltage - shutdown if it's too low.
  checkBatteryForShutdown();

  //read the xbee radio in
  readXbee();

  //read all of our sensors
  readBodyPot();
  readHeadPot();
  readButtonArray();

  //send messages from our sensors
  handleBodyPot(); //this also handles the spin buttons
  handleHeadPot(); //xya joystick
  handleButtonArray();  //funny noises in a big fancy grid
  

#ifdef DEBUG
  Serial.println("Loop End - pause 3 sec");
  delay(3000); //for debugging - to reduce the number of commands sent.
#endif
}
