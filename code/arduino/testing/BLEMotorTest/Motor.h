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
  if(dir==true){
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
