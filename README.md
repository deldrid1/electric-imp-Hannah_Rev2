Electric Imp Hannah (Rev2) Example Code
=========

This is example code for the [Electric Imp Hannah (Rev2) Developer Board].  The code is an early work in progress with the following goals:

  - Fully implement all of the hardware functionality present on Hannah
  - Implement a wide range of impOS API calls using best practices to serve as example code for more complex projects.  (includes things like persistant storage, operating without Wi-Fi to conserve battery, robust error handling, etc.)
  - Implement an Agent that can be used as a Template for connection to the best free Webservices the internet has to offer. (List of Services TBD)
  - Create a simple website that can be used as a starting point to demonstrate how to build a Web UI to monitor and control an imp-enabled device
  - Get the imp communicty involved in what I hope becomes the *ultimate* imp tutorial - common hardware with easy to follow, fully documented, useful, and understandable code, complete with a few real world use cases

Version
-

0.1_Beta

Technology
-

* [Electric Imp] - The hardware and cloud services used to connect serial devices to the internet
* [Twitter Bootstrap] - great UI boilerplate for modern web apps
* [node.js] - evented I/O for the backend (including great libraries like [Express])


Features
-

The current version of the code supports the following:
  - From the Hannah hardware perspective the I/O Expander, RGB LED, Potentiometer, Hall Switch, Push Buttons, Servo Control, some features of the Temperature Sensor, and some features of the Accelerometer are all enabled.  No features of the Light Sensor are supported.  The Potentiometer controls the brightness of the LED as well as the servo postion whenever the corresponding push button is pressed.  The push buttons and Hall Switch will also change the color of the LED.
  - Currently the Website will show that status of the push buttons and hall switch and color of the LED (which indirectly tells the Potentiometer postion).  The website also implements [CORS] and longpolling in order to be as real time as possible (although this is currently only triggered by a button press - the plan is for this to be implemented for all "events" the hardware can experience).  Eventually the website should allow for virtual control (changing the color of the LEDs, adjusting the servo postion, controlling the I/O Expanders Spare GPIO, etc.) as well as monitoring but this is not yet implemented.



Usage
-

This sample code requires your account to have access to the IDE + Agent beta. If you do not have access and would like to use the sample code, please email info@electricimp.com.

### Setting up your Imp
Simply copy and paste the Hannah_Rev2_Device.nut into the Device tab of the IDE and press Run

###Setting up your Agent
Simply copy and paste the Hannah_Rev2_Agent.nut into the Agent tab of the IDE and press Run

You will also need to enter your appropriate credentials into the External 3rd Party Services section.  Current 3rd party services and required credentials are:

    
    //Xively.com - IoT Public Cloud
    const XIVELY_FEED_ID = "";
    const XIVELY_API_KEY = "";
    
    //Boxcar.io - iOS Notifications via Provider API
    const BOXCAR_SECRET = "";
    const BOXCAR_PROVIDER_KEY = "";
    
    //twilio.com - SMS
    const TWILIO_ACCOUNT_SID = ""
    const TWILIO_AUTH_TOKEN = ""
    const TWILIO_FROM_NUMBER = ""
    
    //mailgun.com - Email   //TODO: Replace with Mandrill for more flexibility?
    const MAILGUN_DOMAIN = ""
    const MAILGUN_AUTH_TOKEN = ""
    
###Setting up the Website
The only thing you are required to do is to connect the webpage to your agent in longpoll.js:
    
    var agentBaseURL ="https://agent.electricimp.com/YOUR_AGENT_ID_HERE";
    
You can launch index.html directly and everything *should* work correctly (but may not due to browser security policies).  A nodeServer.js file is also included to be a static file webserver using [Node.js] if you are so inclined.  (For those unfamiliar with Node and wanting to jump in I recommend the [Node Version Manager] for a simple installation.  You will also need to run the command 
    npm install express 
from your working directory for 
    node nodeServer.js
to work correctly.

To Do items
--------------
I'll cheat and put documentation as the only item for now.  If anyone would like to contribute and expand the capabilities or the documentation that would be fantastic!

  [electric imp]: http://www.electricimp.com
  [node.js]: http://nodejs.org
  [Twitter Bootstrap]: http://twitter.github.com/bootstrap/
  [express]: http://expressjs.com
  [Electric Imp Hannah (Rev2) Developer Board]: http://devwiki.electricimp.com/doku.php?id=hannah
  [CORS]: http://www.html5rocks.com/en/tutorials/cors/
  [Node Version Manager]: https://github.com/creationix/nvm

    
