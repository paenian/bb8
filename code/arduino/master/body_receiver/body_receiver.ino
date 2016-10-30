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
#define DEBUG 1

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


//shutdown after 10 seconds of no signal
#define TIMEOUT 10000
unsigned long lastHeartbeat;  //this is updated every time we receive a command.


void initPins(){
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
  checkBatteryForShutdown();
  
  handleXbee();
  
  readBodyAccel();
  readHeadAccel();
  
  updateBodyMotors();
  updateHeadMotors();
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
      c = Serial.read();  //two chars left
      chars++;
      
      if(c == BODYCHAR){  //to char - we only care if it's for us
        sender = Serial.read();  //from char - record who sent the message
        chars++;
        
        c = Serial.read();  //command char - this is the last guaranteed char
        chars++;
        
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
        }
      }
    }
    
    if(chars > MAX_CHARS_TO_READ){
      return;
    }
  }
}

void readBodyCommand(){
  //figure out what the controller wants us to do :-)
}

//turn off all the pins
void Stop(){
#ifdef DEBUG
  Serial.println("Body: Stopping All Motors");
#endif
  
  for(uint8_t i = 0; i<NUMPINS; i++){
    digitalWrite(i, LOW);
  }

#ifdef DEBUG
  Serial.println("Body: Stopped All Motors");
#endif
}

void checkHeartbeat(){
  if(millis() > lastHeartbeat + TIMEOUT){
    Stop();
  }
}

//this waits for ONE character - BLOCKING
boolean waitForSerial(){
  do{
    checkHeartbeat();
  }while(Serial.available() < 1);

  //reset on each char recieved  
  lastHeartbeat = millis();
  return true;
}

//this waits for <chars> number of characters - BLOCKING - to be available on the serial bus
//while making sure we don't timeout from lack of communication.
boolean waitForSerial(uint8_t chars){
  while(Serial.available() < chars){
    waitForSerial();
  }
  return true;
}

// write servo pin
// send S or s to enter
// then pin #
// then 3 digit angle
void writeSPin()
{
  while (waitForSerial(4));	//this just waits til the digits come in

  char pin  = ASCIItoInt(Serial.read());
  int angle = ASCIItoInt(Serial.read()) * 100 +
              ASCIItoInt(Serial.read()) * 10 +
	      ASCIItoInt(Serial.read());

  angle = constrain(angle, 0, 180);

#ifdef DEBUG
  Serial.print("Body: servo ");
  Serial.print(pin);
  Serial.print(" to <");
  Serial.println(angle);
#endif

  //todo: set this up.
  //Could do a linked list of servos, or maybe an array of servo pointers
  //array of servo pointers, populated by pin number!
  //need to check if a pointer is null... I think an unset pointer is just
  //random.

  
  //first, see if it exists
  if(servoPins[pin] == 0){
    //create the servo, since it doesn't exist :-)
    servoPins[pin] = new Servo();
    servoPins[pin] -> attach(pin);

#ifdef DEBUG
  Serial.print("Body: created servo ");
  Serial.print(pin);
  Serial.print(" at memory location ");
  Serial.println(int(servoPins[pin]));
#endif
  }

  //and finally, write the angle to the servo
  servoPins[pin] -> write(angle);
}

// Write Digital Pin
// Send a 'd' or 'D' to enter.
// Then send a pin #
//   Use numbers for 0-9, and hex (a, b, c, or d) for 10-13
// Then send a value for high or low
//   Use h, H, or 1 for HIGH. Use l, L, or 0 for LOW
void writeDPin()
{
  waitForSerial(2); // Wait for pin and value to become available
  char pin = Serial.read();
  char hl = ASCIItoHL(Serial.read());

#ifdef DEBUG
  // Print a message to let the control know of our intentions:
  Serial.print("\nBody: digital ");
  Serial.print(pin);
  Serial.print(" to ");
  Serial.println((hl ? "HIGH" : "LOW"));
#endif

  pin = ASCIItoInt(pin); // Convert ASCCI to a 0-13 value
  pinMode(pin, OUTPUT); // Set pin as an OUTPUT
  digitalWrite(pin, hl); // Write pin accordingly
}

// Write Analog Pin
// Send 'w' or 'W' to enter
// Then send a pin #
//   Use numbers for 0-9, and hex (a, b, c, or d) for 10-13
//   (it's not smart enough (but it could be) to error on
//    a non-analog output pin)
// Then send a 3-digit analog value.
//   Must send all 3 digits, so use leading zeros if necessary.
void writePWMPin()
{
  waitForSerial(4); // Wait for pin and three value numbers to be received
  
  char pin = Serial.read(); // Read in the pin number
  int val = ASCIItoInt(Serial.read()) * 100; // Convert next three
  val += ASCIItoInt(Serial.read()) * 10;     // chars to a 3-digit
  val += ASCIItoInt(Serial.read());          // number.
  val = constrain(val, 0, 255); // Constrain that number.

#ifdef DEBUG
  // Print a message to let the control know of our intentions:
  Serial.print("\nBody: analog ");
  Serial.print(pin);
  Serial.print(" to ");
  Serial.println(val);
#endif

  pin = ASCIItoInt(pin); // Convert ASCCI to a 0-13 value
  pinMode(pin, OUTPUT); // Set pin as an OUTPUT
  analogWrite(pin, val); // Write pin accordingly
}

// Read Digital Pin
// Send 'r' or 'R' to enter
// Then send a digital pin # to be read
// The Arduino will print the digital reading of the pin to Serial.
void readDPin()
{
  int val = 0;

  waitForSerial(1); // Wait for pin # to be available.

  char pin = Serial.read(); // Read in the pin value

  pin = ASCIItoInt(pin); // Convert pin to 0-13 value
  pinMode(pin, INPUT); // Set as input
  
  val = digitalRead(pin);

  //send the character
  sendValue('D', val);


//print a debug message
#ifdef DEBUG
  Serial.print("\nBody: dRead ");
  Serial.print(pin);
  Serial.print(" -> ");
  Serial.println(val);
#endif
}

// Read Analog Pin
// Send 'a' or 'A' to enter
// Then send an analog pin # to be read.
// The Arduino will print the analog reading of the pin to Serial.
void readAPin()
{
  int val = 0;

  waitForSerial(1); // Wait for pin # to be available
  
  char pin = Serial.read(); // read in the pin value

  pin = ASCIItoInt(pin); // Convert pin to 0-6 value

  val = analogRead(pin);

  //send it back
  sendValue('A', val);

  //debug
#ifdef DEBUG
  Serial.print("\nBody: aRead ");
  Serial.print(pin);
  Serial.print(" -> ");
  Serial.println(val);
#endif
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

// send a value back to the controller - called in any of the read
//  functions.
void sendValue(char label, int val){
  Serial.print('$'+CONTROLCHAR);
  Serial.print(label);
  if(label == 'A'){
    Serial.print(pad(val, 4));
  }else{
    Serial.print(val);
  }
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
