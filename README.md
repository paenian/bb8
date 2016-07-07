# bb8
Trying to make a printed BB8 that's strong, fast and accurate.

## Shell
I want a full spherical shell, that is strong, printable, and provides easy access to the innards.  

The new plan is to print endcaps, then use a thermoformer to create petals connecting them.  I'll also create printable petals, so that I can make a thermoformed mold with some details.  I'll probably end up printing all 6 shells, then making molds.

The hamster is now integrated into the shell, as it's an axle-drive bot; current 

## Old shell
- Old design is a rombicuboctahedron, which has 18 square faces and 8 triangular faces.  
- Each square face, when oriented for printing, fits in a 180x180x180mm cube.
- The parts print on their edge - so there's no need for support material.
- This shell is inordinately heavy, and the magnetic triangle joints are not strong enough.
- No longer developing this, in favor of the axle-drive bot.

The parts are joined by screws on the center of their face, with washers at the corners biscuit-joint style.  

### Old Hamster
For the hamster, I plan to make an omniwheel robot.  I have no experience with robot building.  

Right now I don't have any plans for the head.  


I'll be using an Arduino 101: https://www.arduino.cc/en/Main/ArduinoBoard101
- because I think that the internal IMU and faster processor will make my bb8 more realistic.  Existing designs seem too wobbly.
  - I will probably need another accelerometer for the head, when I get there.

First step is to hook that up to a Rover 5 Motor Controller:
- https://github.com/sparkfun/Rover5_Motor_Driver_Board
- http://smile.amazon.com/Motor-Controller-Channel-4-5A-4-5-12V/dp/B00B88F2A6

Motors:
- https://www.pololu.com/product/1163

Paul

