/*****************************************************************
Serial_Remote_Control.ino
Write your Arduino's pins (analog or digital) or read from those
pins (analog or digital) using a remote Serial.
Jim Lindblom @ SparkFun Electronics
Original Creation Date: May 7, 2014

Heavily adapted by Paul Chase, but I started from Jim's sketch :-)

This code is beerware; if you see me (or any other SparkFun 
employee) at the local, and you've found our code helpful, please 
buy us a round!

Distributed as-is; no warranty is given.
*****************************************************************/
// no software serial, body's going to need servos eventually and
//it would conflict.
#include "configuration.h"

//comment this out to turn serial debugging off.
//With it on, you can monitor the debugging with an xbee over the
//Arduino serial monitor.
//#define DEBUG 1

//the max chars should only be an issue with debugging on :-)
#define MAX_SERIAL_WAIT 250
#define MAX_CHARS_TO_READ 25


////////Battery Voltage
//batteries can't be below MIN_VOLTAGE
//that's just over 3 volts in 10 bit.
#define MIN_VOLTAGE 616

//and we check them every INTERVAL
#define BATTERY_CHECK_INTERVAL 10000

// We track battery voltage for the body, head and controller itself.
int controllerVoltage = MIN_VOLTAGE + 1;
int bodyVoltage = MIN_VOLTAGE + 1;
int headVoltage = MIN_VOLTAGE + 1;


//position variables
int bodyPot[3] = {255, 255, 255};   //this is the potentiometer reading from the controller.
                                    //The third one isn't used as yet, but it's for spinning bb8.
int bodyState[3] = {255, 255, 255}; //what the body is currently doing

uint8_t bodyDisabled = 0;

//pid settings... the head might need its own pid?  it shouldn't, though...
#define BODY_PROPORTIONAL .5
#define BODY_INTEGRAL .25
#define BODY_DIFFERENTIAL .25
#define BODY_HYSTERESIS 5
#define BODY_DEADZONE 5


//shutdown after 10 seconds of no signal
#define HEARTBEAT_TIMEOUT 10000
unsigned long lastHeartbeat;  //this is updated every time we receive a command.


void initPins(){
  pinMode(BODY_X0_DIR_PIN, OUTPUT);
  pinMode(BODY_X0_SPEED_PIN, OUTPUT);
  pinMode(BODY_X0_CURR_PIN, INPUT);

  pinMode(BODY_X1_DIR_PIN, OUTPUT);
  pinMode(BODY_X1_SPEED_PIN, OUTPUT);
  pinMode(BODY_X1_CURR_PIN, INPUT);

  pinMode(BODY_Y0_DIR_PIN, OUTPUT);
  pinMode(BODY_Y0_SPEED_PIN, OUTPUT);
  pinMode(BODY_Y0_CURR_PIN, INPUT);

  pinMode(BODY_Y1_DIR_PIN, OUTPUT);
  pinMode(BODY_Y1_SPEED_PIN, OUTPUT);
  pinMode(BODY_Y1_CURR_PIN, INPUT);
}

void setup()
{
  // Initialize Serial Software Serial port. Make sure the baud
  // rate matches your Serial setting (9600 is default).
  Serial.begin(9600);

#ifdef DEBUG
  printMenu(); // Print a helpful menu
#endif

  initPins();

  lastHeartbeat = millis();
}

void loop()
{
  //checkBatteryForShutdown();
  
  handleXbee();
  handleHeartbeat();
  
  //readBodyAccel();
  //readHeadAccel();
  
  updateBodyMotors();
  updateHeadMotors();
}

void updateHeadMotors(){
  //the head is driven by three servos :-)
}

void updateBodyMotors(){
  uint8_t motorSpeed;
  
  //proportional control :-)
  for(int i=0; i<3; i++){
    bodyState[i] += BODY_PROPORTIONAL * (bodyPot[i] - bodyState[i]);
  }
  
  //update the motors
    if((bodyState[0] > 255 + BODY_DEADZONE) || (bodyState[0] < 255 - BODY_DEADZONE)){
      #ifdef DEBUG
      Serial.println("Moving Motors");

      //print the new coordinates
      Serial.println();
      Serial.println("body: newstate: ");
      Serial.print("{ ");
      for(uint8_t i = 0; i<3; i++){
        Serial.print(bodyState[i]);
        Serial.print("\t, ");
      }
      Serial.println("}");
      
      #endif
      if(bodyState[0] > 255){
        digitalWrite(BODY_X0_DIR_PIN, LOW);
        digitalWrite(BODY_X1_DIR_PIN, LOW);
      }else{
        digitalWrite(BODY_X0_DIR_PIN, HIGH);
        digitalWrite(BODY_X1_DIR_PIN, HIGH);
      }
      
      motorSpeed = abs(bodyState[0]-255);

      #ifdef DEBUG
      Serial.print("X Speed: ");
      Serial.println(motorSpeed);
      #endif DEBUG
      
      analogWrite(BODY_X0_SPEED_PIN, motorSpeed);
      analogWrite(BODY_X1_SPEED_PIN, motorSpeed);
    }else{
      //we're in the dead zone, so kill the motor
      analogWrite(BODY_X0_SPEED_PIN, 0);
      analogWrite(BODY_X1_SPEED_PIN, 0);
    }
    
    if((bodyState[1] > 255 + BODY_DEADZONE) || (bodyState[1] < 255 - BODY_DEADZONE)){
      //Y
      if(bodyState[1] > 255){
        digitalWrite(BODY_Y0_DIR_PIN, LOW);
        digitalWrite(BODY_Y1_DIR_PIN, LOW);
      }else{
        digitalWrite(BODY_Y0_DIR_PIN, HIGH);
        digitalWrite(BODY_Y1_DIR_PIN, HIGH);
      }
      
      motorSpeed = abs(bodyState[1]-255);
      
      analogWrite(BODY_Y0_SPEED_PIN, motorSpeed);
      analogWrite(BODY_Y1_SPEED_PIN, motorSpeed);
    
      //spin
      //not implemented
    }else{
      //we're in the dead zone, so kill the motor
      analogWrite(BODY_Y0_SPEED_PIN, 0);
      analogWrite(BODY_Y1_SPEED_PIN, 0);
    }
  
}

void handleHeartbeat(){
  if(millis() - lastHeartbeat > HEARTBEAT_TIMEOUT){
    //we don't need to panic, just stop BB8 from running away.
    for(uint8_t i=0; i<3; i++)
      bodyPot[i] = 255;
  }
}

//process the xbee serial
void handleXbee(){
  
  //this will consume many characters - maybe too many.
  //So we set a max.
  int chars = 0;
  char sender = BODYCHAR;  //set it to us, in case it becomes necessary
  
  //WAIT for at least 4 characters to be in the buffer before doing anything!
  while((Serial.available() > 3) && (chars < MAX_CHARS_TO_READ)){
    char c = Serial.read();  //three chars left
    chars++;
    
    if(c == '$'){  //control char    
#ifdef DEBUG
  Serial.print("BodyCommand: ");
#endif
    
      c = Serial.read();  //two chars left
      chars++;   
#ifdef DEBUG
  Serial.print(c);
#endif      
      
      if(c == BODYCHAR){  //to char - we only care if it's for us
        sender = Serial.read();  //from char - record who sent the message
        chars++;
#ifdef DEBUG
  Serial.print(c);
#endif

        c = Serial.read();  //command char - this is the last guaranteed char
        chars++;
#ifdef DEBUG
  Serial.print(c);
#endif     

        lastHeartbeat = millis();        
        
        switch(c){
          case 'S': //stop char!
            if(sender == CONTROLCHAR){
              bodyDisabled = 1;
            }
          return;
          
          case 'B': //adjust the body position
            readBodyCommand();
          return;
          
          case 'H': //move the head about
            //todo on this one is to make a head!
          return;
          
          case 'R': //request for information
            if(sender == CONTROLCHAR){
              sendInfoController();
            }
          return;
        }
      }
    }
    
    if(chars > MAX_CHARS_TO_READ){
      return;
    }
  }
}

void sendInfoController(){
  Serial.println("Body: The controller wants information.");
}

void readBodyCommand(){
  //figure out what the controller wants us to do :-)
  //So far, we've consumed the characters $BCB
  //Next is X###Y###frea

  //if there's a problem with the read, we'll just ignore the command.
  //So set a sane default
  int newPot[3] = {255, 255, 255};
  
#ifdef DEBUG
  Serial.println(" moving body");
#endif

  if(readSerialBlocking() != 'X'){
#ifdef DEBUG
  Serial.println("body: readBodyCommand: Bad format, no X");
#endif
    return;
  }
 
  //read x
  newPot[0] = readInteger(3);
  
  if(readSerialBlocking() != 'Y'){
#ifdef DEBUG
  Serial.println("body: readBodyCommand: Bad format, no Y");
#endif
    return;
  }
  
  //read y
  newPot[1] = readInteger(3);
  
  memcpy( bodyPot, newPot, sizeof(bodyPot));

#ifdef DEBUG
  Serial.println();
  Serial.println("body: newcoords: ");
  Serial.print("{ ");
  for(uint8_t i = 0; i<3; i++){
    Serial.print(newPot[i]);
    Serial.print("\t, ");
  }
  Serial.println("}");
#endif 
}

//turn off all the pins
void Stop(){
#ifdef DEBUG
  Serial.println("Body: Stopping All Motors");
#endif

  for(uint8_t i=0; i<3; i++){
    bodyPot[i] = 255;
    bodyState[i] = 255;
  }
  
  bodyDisabled = 1;  

#ifdef DEBUG
  Serial.println("Body: Stopped All Motors");
#endif
  delay(10000);
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

int readInteger(uint8_t digits){
  //todo: throw an error if we can't read the serial
  int integer = 0;
  
  #ifdef DEBUG
  Serial.print("Reading ");
  Serial.print(digits);
  Serial.print(" Digits: ");
  #endif
  
  for(uint8_t i=0; i<digits; i++){
    integer += pow(10,digits-1-i) * ASCIItoInt(readSerialBlocking());
  }

  #ifdef DEBUG
  Serial.println(integer);
  #endif
  
  return integer;
}

String pad(int number, byte len){
  String ret = "";
  int curMax = 10;
  for(byte i=1; i<len; i++){
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
  Serial.println(F("Arduino Serial Remote Control!"));
  Serial.println(F("============================"));
  Serial.println(F("Usage: "));
  Serial.println(F("w#nnn - analog WRITE pin # to nnn"));
  Serial.println(F("  e.g. w6088 - write pin 6 to 88"));
  Serial.println(F("d#v   - digital WRITE pin # to v"));
  Serial.println(F("  e.g. ddh - Write pin 13 High"));
  Serial.println(F("r#    - digital READ digital pin #"));
  Serial.println(F("  e.g. r3 - Digital read pin 3"));
  Serial.println(F("a#    - analog READ analog pin #"));
  Serial.println(F("  e.g. a0 - Read analog pin 0"));
  Serial.println();
  Serial.println(F("- Use hex values for pins 10-13"));
  Serial.println(F("- Upper or lowercase works"));
  Serial.println(F("- Use 0, l, or L to write LOW"));
  Serial.println(F("- Use 1, h, or H to write HIGH"));
  Serial.println(F("============================"));  
  Serial.println();
#endif
}
