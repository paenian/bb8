#include <CurieIMU.h>
#include <MadgwickAHRS.h>



class Motor{
public:
  Motor(int pwmPin, int dirPin, int currPin);
  Motor(int pwmPin, int dirPin, int currPin, int encAPin, int encBPin);
  void begin();
  void stop();
  void setSpeed(int speed);
  void setDirection(bool dir);
  int getCurrent();
  float getDistance(); //unsupported
  int getSpeed();
  long int getTicks();

private:
  int _pwmPin;
  int _dirPin;
  int _currPin;
  int _encAPin;
  int _encBPin;
  float _distance;
  int _speed;
  long int _ticks;
  //Encoder enc;  Don't support the encoders yet.
};

Motor::Motor(int pwmPin, int dirPin, int currPin){
  _pwmPin = pwmPin;
  _dirPin = dirPin;
  _currPin = currPin;

  _encAPin = -1;
  _encBPin = -1;
  _distance = 0;
  _speed = 0;
}

Motor::Motor(int pwmPin, int dirPin, int currPin, int encAPin, int encBPin){
  _pwmPin = pwmPin;
  _dirPin = dirPin;
  _currPin = currPin;
  
  _encAPin = encAPin;
  _encBPin = encBPin;
  _distance = 0;
  _speed = 0;
}

void Motor::begin(){
  pinMode(_pwmPin, OUTPUT);
  pinMode(_dirPin, OUTPUT);
  pinMode(_currPin, INPUT);
}

void Motor::stop(){
    setSpeed(0);
}

void Motor::setSpeed(int speed){
  speed = constrain(speed, 0, 255);
  
  analogWrite(_pwmPin, speed);
  _speed=speed;
}

void Motor::setDirection(bool dir)
{
  if(dir){
    digitalWrite(_dirPin, LOW);
    digitalWrite(13, LOW);
  }else{
    digitalWrite(_dirPin, HIGH);
    digitalWrite(13, HIGH);
  }
}

int Motor::getCurrent(){
  return analogRead(_currPin);
}

float Motor::getDistance(){
  //not implementing the encoders.
  return 0;
}

int Motor::getSpeed(){
  return _speed;
}

long int Motor::getTicks(){
  //not implementing the encoders
  return 0;
}




Madgwick filter; // initialise Madgwick object
int ax, ay, az;
int gx, gy, gz;
float yaw;
float pitch;
float roll;
int factor = 1200; // variable by which to divide gyroscope values, used to control sensitivity
// note that an increased baud rate requires an increase in value of factor

int calibrateOffsets = 1; // int to determine whether calibration takes place or not

Motor motor = Motor(6, 7, A0);

void setup() {
  // initialize Serial communication
  Serial.begin(9600);

  // initialize device
  CurieIMU.begin();
  
  if (calibrateOffsets == 1) {
    // use the code below to calibrate accel/gyro offset values
    Serial.println("Internal sensor offsets BEFORE calibration...");
    Serial.print(CurieIMU.getAccelerometerOffset(X_AXIS)); Serial.print("\t");
    Serial.print(CurieIMU.getAccelerometerOffset(Y_AXIS)); Serial.print("\t");
    Serial.print(CurieIMU.getAccelerometerOffset(Z_AXIS)); Serial.print("\t");
    Serial.print(CurieIMU.getGyroOffset(X_AXIS)); Serial.print("\t");
    Serial.print(CurieIMU.getGyroOffset(Y_AXIS)); Serial.print("\t");
    Serial.print(CurieIMU.getGyroOffset(Z_AXIS)); Serial.print("\t");
    Serial.println("");

    // To manually configure offset compensation values, use the following methods instead of the autoCalibrate...() methods below
    //    CurieIMU.setGyroOffset(X_AXIS, 220);
    //    CurieIMU.setGyroOffset(Y_AXIS, 76);
    //    CurieIMU.setGyroOffset(Z_AXIS, -85);
    //    CurieIMU.setAccelerometerOffset(X_AXIS, -76);
    //    CurieIMU.setAccelerometerOffset(Y_AXIS, -235);
    //    CurieIMU.setAccelerometerOffset(Z_AXIS, 168);

    //IMU device must be resting in a horizontal position for the following calibration procedure to work correctly!

    Serial.print("Starting Gyroscope calibration...");
    CurieIMU.autoCalibrateGyroOffset();
    Serial.println(" Done");
    Serial.print("Starting Acceleration calibration...");
    CurieIMU.autoCalibrateAccelerometerOffset(X_AXIS, 0);
    CurieIMU.autoCalibrateAccelerometerOffset(Y_AXIS, 0);
    CurieIMU.autoCalibrateAccelerometerOffset(Z_AXIS, 1);
    Serial.println(" Done");

    Serial.println("Internal sensor offsets AFTER calibration...");
    Serial.print(CurieIMU.getAccelerometerOffset(X_AXIS)); Serial.print("\t");
    Serial.print(CurieIMU.getAccelerometerOffset(Y_AXIS)); Serial.print("\t");
    Serial.print(CurieIMU.getAccelerometerOffset(Z_AXIS)); Serial.print("\t");
    Serial.print(CurieIMU.getAccelerometerOffset(X_AXIS)); Serial.print("\t");
    Serial.print(CurieIMU.getAccelerometerOffset(Y_AXIS)); Serial.print("\t");
    Serial.print(CurieIMU.getAccelerometerOffset(Z_AXIS)); Serial.print("\t");
    Serial.println("");
  }

  //initialize the motor
  motor.begin();
  pinMode(13, OUTPUT);
}

void loop() {
  // read raw accel/gyro measurements from device
  CurieIMU.readMotionSensor(ax, ay, az, gx, gy, gz); 

  // use function from MagdwickAHRS.h to return quaternions
  filter.updateIMU(gx / factor, gy / factor, gz / factor, ax, ay, az);

  // functions to find yaw roll and pitch from quaternions
  yaw = filter.getYaw();
  roll = filter.getRoll();
  pitch = filter.getPitch();

  delay(50);
  motor.setDirection(true);
  motor.setSpeed(255);
  delay(5000);
  motor.stop();
  delay(500);
  motor.setDirection(false);
  motor.setSpeed(255);
  delay(5000);
  motor.stop();
  delay(500);
  
  // print gyro and accel values for debugging only, comment out when running Processing
  /*
  Serial.print(ax); Serial.print("\t");
  Serial.print(ay); Serial.print("\t");
  Serial.print(az); Serial.print("\t");
  Serial.print(gx); Serial.print("\t");
  Serial.print(gy); Serial.print("\t");
  Serial.print(gz); Serial.print("\t");
  Serial.println("");
  */

  if (Serial.available() > 0) {
    int val = Serial.read();
    if (val == 's') { // if incoming serial is "s"
      Serial.print(yaw);
      Serial.print(","); // print comma so values can be parsed
      Serial.print(pitch);
      Serial.print(","); // print comma so values can be parsed
      Serial.println(roll);
    }
  }
}

