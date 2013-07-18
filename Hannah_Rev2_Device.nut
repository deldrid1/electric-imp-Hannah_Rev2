// Electric Imp - Hannah Dev Board

//TODO: Remove large blocks of commented and unused code
//TODO: Use Callibration capabilities of devices to allow setting correct temp, acceleration, color sensor, etc.
//TODO: Implement Color Sensor
//TODO: Figure out why continuous conversion doesn't work on the Temp sensor
//TODO: Do something with the accelerometer and light sensor to make them useful
//TODO: Test the Servo code is somewhat working - make it a more useful and friendly library
//TODO: Is there anything else available with the hardware that would be useful?
//TODO: Implement a useful agent with all the latest bells and whistles I can think of - (serving up a local control bootstrap page is one good thought, create Agent end points for all of the available actions, create a RESTFUL JSON API)
//TODO: Create an onchange callback method for the potentiometer (that is able to ignore noise/drift) for agents and to be used as an irq
//TODO: Ensure all class variables start with underscores
//TODO: Ensure all Camelcaseing of functions, member vars, etc. are consistent
//TODO: Ensure putting semicolons is consistent
//TODO: Implement all of the functionality in the servo class (minpulse, maxpulse, etc.)
//TODO: Implement all the Release-23 goodies here

function getConnectionReason(reason){
    if(reason == SERVER_CONNECTED)
        return "The server is connected";
    else if(reason == NO_WIFI)
        return "No Wifi";
    else if(reason == NO_IP_ADDRESS)
        return "Failed to get IP Address";
    else if(reason == NO_SERVER)
        return "Failed to connect to EI server";
    else if(reason == NOT_RESOLVED)
        return "Failed to resolve EI server";
        
    return ""
}

server.setsendtimeoutpolicy(RETURN_ON_ERROR, WAIT_TIL_SENT, 10.0);
//server.disconnect();
//imp.wakeup(10.0, server.connect(function(status){
//    server.log(getConnectionReason(status))
//}, 10.0));

onBoot <- true;
agent.send("Device_Variables", {
    onBoot = true,
    impeeID=hardware.getimpeeid(),
    MACaddr=imp.getmacaddress(),
});
/*******************************************************************************
                    HARDWARE ASSIGNMENTS/CONSTANTS
*******************************************************************************/
//Imp Hardware Constants
IOEXPANDER_INTERRUPT_PIN <- hardware.pin1;
POTENTIOMETER_PIN <- hardware.pin2;
SERVO1_PIN <- hardware.pin5;
SERVO2_PIN <- hardware.pin7;
I2C_PORT <- hardware.i2c89;

//I2C HW Constants
IOEXPANDER_I2C_ADDRESS <- 0x3E;
ACCELEROMETER_I2C_ADDRESS <- 0x1C;
RGB_LIGHT_SENSOR_I2C_ADDRESS <- 0x74;
TEMP_SENSOR_I2C_ADDRESS <- 0x4C;

//IO Expander peripherals
IO_BUTTON1_PIN <- 0;
IO_BUTTON2_PIN <- 1;
IO_HALL_SWITCH_PIN <- 2;
IO_ACCELEROMETER_INTERRUPT_PIN <- 3;
IO_TEMP_SENSOR_INTERRUPT_PIN <- 4;
IO_LED_G_PIN <- 5;
IO_LED_B_PIN <- 6;
IO_LED_R_PIN <- 7;
IO_POTENTIOMETER_ENABLE_PIN <- 8;
IO_RGB_LIGHT_SENSOR_SLEEP_PIN <- 9;
IO_SERVO_POWEREN_PIN <- 10;

/**------------------ END HARDWARE ASSIGNMENTS/CONSTANTS ------------------- **/

/*******************************************************************************
                    FIRMWARE CONSTANTS
*******************************************************************************/


/**------------------------ END FIRMWARE CONSTANTS ------------------------- **/

/*******************************************************************************
                    HELPER FUNCTIONS
*******************************************************************************/
function arrayString(arr){
    local str = ""
    for(local i = 0; i < arr.len(); i++){
		if(arr[i] == null) break;
		str = str + format("%.2X ", arr[i]);
	}
	
	return str;
}


function byteString(data, bytes){
    local str = ""
	
	for(local z=(1<<(bytes*8-1)); z>0; z = z>>1){
		if((data & z) == z) str = str + "1";
		else str = str + "0"
	}
	
	return str;
}

function byte(byteStr){
    local retVal = 0
    for(local i=0; i<byteStr.len(); i++){
        retVal = retVal || byteStr[i].tointeger() << i
    }
    return retVal;
}

function bitRead(value, bit) {
    return (((value) >> (bit)) & 0x01);
}

function Max(...) {
    local maximum = vargv[0]
    for(local i = 1; i< vargv.len(); i++) {
        if (vargv[i] > maximum) {
           maximum  = vargv[i];
        }
    }
    return maximum;
}

function Min(...) {
    local minimum = vargv[0]
    for(local i = 1; i< vargv.len(); i++) {
    	if (vargv[i] < minimum) {
           minimum  = vargv[i];
        }
    }
    return minimum;
}

function round(val, decimal){
  if (decimal)
    return math.floor((val * math.pow(10,decimal)) + 0.5) / math.pow(10,decimal)
  else
    return math.floor(val+0.5)
}

function hexToInteger(hex) {
    local result = 0;
    local shift = hex.len() * 4;
 
    // For each digit..
    for(local d=0; d<hex.len(); d++) {
        local digit;
 
        // Convert from ASCII Hex to integer
        if(hex[d] >= 0x61) {
            digit = hex[d] - 0x57;
        }
        else if(hex[d] >= 0x41) {
             digit = hex[d] - 0x37;
        }
        else {
             digit = hex[d] - 0x30;
        }     
        // Accumulate digit
        shift -= 4;
        result += digit << shift;
    }
 
    return result;
}


 /* Converts an HSV color value to RGB. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSV_color_space.
 * Assumes h, s, and v are contained in the set [0, 1] and
 * returns r, g, and b in the set [0, 255].
 *
 * @param   Number  h       The hue
 * @param   Number  s       The saturation
 * @param   Number  v       The value
 * @return  Array           The RGB representation
 */
 //Adapted from http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c which has several other examples
function hsvToRgb(h, s, v){
    local r, g, b;

    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);

    switch(i % 6){
        case 0: r = v; g = t; b = p; break;
        case 1: r = q; g = v; b = p; break;
        case 2: r = p; g = v; b = t; break;
        case 3: r = p; g = q; b = v; break;
        case 4: r = t; g = p; b = v; break;
        case 5: r = v; g = p; b = q; break;
    }
    
    //math.floor(x+.5) is the same as rounding (which squirrel doesn't have)
    //math.abs() gives us an integer instead of a float which math.floor oddly returns
    return [math.abs(math.floor(r * 255 + 0.5)), math.abs(math.floor(g * 255 + 0.5)), math.abs(math.floor(b * 255 + 0.5))];

}


 /* Converts an RGB color value to HSV. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSV_color_space.
 * Assumes r, g, and b are contained in the set [0, 255] and
 * returns h, s, and v in the set [0, 1].
 *
 * @param   Number  r       The red color value
 * @param   Number  g       The green color value
 * @param   Number  b       The blue color value
 * @return  Array           The HSV representation
 */
function rgbToHsv(r, g, b){
    r = r/255.0
    g = g/255.0
    b = b/255.0;
    local max = Max(r, g, b)
    local min = Min(r, g, b);
    local h;
    local s;
    local v = max.tofloat();

    local d = (max - min);
    s = max == 0.0 ? 0.0 : d / max;

    if(max == min){
        h = 0.0; // achromatic
    } else {
           if(max == r){
                    h = (g - b) / d + (g < b ? 6 : 0); 
           } else if(max == g){
                    h = (b - r) / d + 2; 
           } else if(max == b){ 
                    h = (r - g) / d + 4; 
           } else{
                server.log("Error in rgbToHsl")
           }
        h = h/6.0
    }

    return [h, s, v];
}
/**  --------------------------------- END HELPER FUNCTIONS --------------------------------------- **/


/******************************************************************************************************
    DATE TIME FUNCTIONS
******************************************************************************************************/
//month <- ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
//weekday <- ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

/*function TimeStamp(arg = null){    //Time Format for SEG = "2010-01-10T23:22:12"
    local currentTime = null;
    local timeStr = null;
    
    if(arg == null)
        currentTime = date(time(), 'u');
    else
        currentTime = date(arg, 'u');
        
    
    timeStr = format("%.4d-%.2d-%.2dT%.2d:%.2d:%.2d", currentTime.year, currentTime.month+1, currentTime.day,  currentTime.hour, currentTime.min, currentTime.sec);
    //TODO: Figure out how to incorporate milliseconds and microseconds into this in a consistent way? (May be difficult since they reset on boot, but since the boot takes more than a second does it really matter?)
    return  timeStr
}*/

function calcElapsedtime(lastTimeStamp, lastTimeStampMS=null, lastTimeStampUS=null, newTimeStamp=null, newTimeStampMS=null, newTimeStampUS=null){
    if(newTimeStampUS == null) newTimeStampUS=hardware.micros();
    if(newTimeStampMS == null) newTimeStampMS=hardware.millis();
    if(newTimeStamp == null) newTimeStamp=time(); 
    if(lastTimeStamp == null) lastTimeStamp = newTimeStamp;
    
    if(lastTimeStampMS == 0.0 && lastTimeStampUS == 0.0){   //We don't have any microsecond or millisecond information
        lastTimeStampMS = newTimeStampMS;
        lastTimeStampUS = newTimeStampUS;
    }
    if(lastTimeStampMS == null) lastTimeStampMS = newTimeStampMS;
    if(lastTimeStampUS == null) lastTimeStampUS = newTimeStampUS;
    
    local seconds = newTimeStamp - lastTimeStamp;
    if(seconds < 0){
        server.log(format("ERROR: Time ran backwards - newTimestamp=%s, oldTimeStamp=%s", TimeStamp(newTimeStamp), TimeStamp(m_lastTimeStamp)));
    }
    
    if(seconds > 0 && seconds < 2100 && newTimeStampUS != lastTimeStampUS) {//microsecond counter rolls over after 2^31 microseconds = 2147.483648 seconds
        seconds = (newTimeStampUS - lastTimeStampUS)/1000000.0;
    } else if(seconds < 0 && seconds > -2100 && newTimeStampUS != lastTimeStampUS) {//microsecond counter rolls over after 2^31 microseconds = 2147.483648 seconds
        seconds = (lastTimeStampUS - newTimeStampUS)/1000000.0;
    } else if(seconds > 0 && seconds < 2147400 && newTimeStampMS != lastTimeStampMS) {   //milliseconds roll over after 2147483.648 seconds or 24.855 Days
        seconds = (newTimeStampMS - lastTimeStampMS)/1000.0;
    } else if(seconds < 0 && seconds > -2147400 && newTimeStampMS != lastTimeStampMS) {   //milliseconds roll over after 2147483.648 seconds or 24.855 Days
        seconds = (lastTimeStampMS - newTimeStampMS)/1000.0;
    } else if (seconds < 0){ //Have to rely on seconds only
        seconds = -seconds
    } //else{ //Have to rely on seconds only
        //seconds = seconds
    //}

    
    return seconds;
}

function calcElapsedTimeString(lastTimeStamp, lastTimeStampMS=null, lastTimeStampUS=null, newTimeStamp=null, newTimeStampMS=null, newTimeStampUS=null){
	local secs = calcElapsedtime(lastTimeStamp, lastTimeStampMS, lastTimeStampUS, newTimeStamp, newTimeStampMS, newTimeStampUS);
	return (secs%3600) + ":" + ((secs/3600)%60) + ":" + ((secs/3600)/60.0) 
}

/**  --------------------------------- END DATE TIME FUNCTIONS --------------------------------------- **/

/******************************************************************************************************
    PERMANENT AND NONVOLATILE STORAGE
******************************************************************************************************/
//TODO: need to ensure that all the server.permanent and nonvolatile code is properly working
//server.setpermanentvalues() sets the key value pairs that are saved by the server and set whenever the imp is rebooted. This allows values to be saved and recovered across power cycles. 
//TODO: In Wi-Fi less power-up will these values be available???
serverPermanentUpdateNeeded <- false;    //This flag is used with imp.wakeup to ensure we only have one one serverpermanent update being sent to the server at a time

function updateServerPermanentTable(){  //We use the nv table as local storage and update the permanent table when enough memory is available
        if(imp.getmemoryfree() > 5000){
            serverPermanentUpdateNeeded = false;

            server.setpermanentvalues(server.permanent);
        } else {
        	imp.wakeup(0.25, updateServerPermanentTable);
        }
}

function serverPermanentUpdate(){
    if(serverPermanentUpdateNeeded == false){
        serverPermanentUpdateNeeded = true
        imp.wakeup(0.25, updateServerPermanentTable);
    }
}
/**  ------------------------- END PERMANENT AND NONVOLATILE STORAGE --------------------------- **/


/*******************************************************************************
    AGENT HANDLER CODE
*******************************************************************************/
function getRunningStatisticsTable(){
	return {					
			FreeMemory=imp.getmemoryfree(),
			SignalStrength=imp.rssi(),
			impeeID=hardware.getimpeeid(),
			MACaddr=imp.getmacaddress(),
            impOS=imp.getsoftwareversion(),
            impEnvironment=imp.environment(),
            wakeReason=hardware.wakereason(),
			Version="Hannah V1.0.0",
			BSSID=imp.getbssid(),
			bootNumber = server.permanent.BootNumber,
			onBoot = onBoot,
		}
}
function getUIDataTable(){
    // Start a single shot conversion
    TemperatureSensor.start(false); 
 
    // Wait for conversion to complete - takes approximately 38ms according to the data sheet
    while(!TemperatureSensor.isReady()) {
        imp.sleep(0.04);
    }
 
    local temp = TemperatureSensor.getFTemperature();
    local voltage = hardware.voltage();
    local rotaryPot = Potentiometer.readSmooth();
    local accelX = Accelerometer.getX();
    local accelY = Accelerometer.getY();
    local accelZ = Accelerometer.getZ();
    local rgbLEDColor = rgbLED.getLEDRGBColor();
    local servo1Angle = servo1.readPercent();
    local servo2Angle = servo2.readPercent();
    local button1State = pushButton1.read();
    local button2State = pushButton2.read();
    local hallSwitchState = hallSwitch.read();
    
    server.show(format("%3.2f Degrees F, %1.10fV, %f%%, %d Bytes", temp, voltage, rotaryPot, imp.getmemoryfree()));
    //server.log(format("%3.2f Degrees F, %1.10fV, %f%%, %d Bytes", temp, voltage, rotaryPot, imp.getmemoryfree()));
    
    //server.log(accelX + " " + accelY + " " + accelZ)
    
    return {
        "Temperature": temp,
        "VoltageSense": voltage, 
        "Potentiometer": rotaryPot,
        "Accelerometer-X": accelX,
        "Accelerometer-Y": accelY,
        "Accelerometer-Z": accelZ,
        "LED-R":rgbLEDColor[0],
        "LED-G":rgbLEDColor[1],
        "LED-B":rgbLEDColor[2],
        "Servo-1": servo1Angle,
        "Servo-2": servo2Angle,
        [pushButton1._name] =  button1State,
        [pushButton2._name] = button2State,
        [hallSwitch._name] = hallSwitchState
        "DeviceFreeMemory": imp.getmemoryfree(),
        "WIFIRSSI": imp.rssi()
    }
}

function initAgentCallbacks(){
	agent.on("GET_RUNNING_STATISTICS",function(value){
		agent.send("GET_RUNNING_STATISTICS", [getRunningStatisticsTable(), value]);
	});

	agent.on("GetUIData", function(value){
        agent.send("GET_UI_DATA", [getUIDataTable(), value]);
	})
}

/**  ------------------------- END AGENT HANDLER CODE --------------------------- **/

//All singletons are created as tables to optimize memory usage as mentioned at http://devwiki.electricimp.com/doku.php?id=writingefficientsquirrel

/*******************************************************************************
    // IO Expander Class for SX1509
*******************************************************************************/
IOExpander <- {}
    
IOExpander.I2CPort <- null;
IOExpander.I2CAddress <- null;
IOExpander.IRQPin <- null;
IOExpander.IRQ_Callbacks <- array(16);    //Array of functions to be called whenever an IO Expander interrupt is triggered
//TODO: Implement binding of native methods to improve performance

IOExpander.Init <- function(port, address, irqPin) {
    I2CPort = port;
	I2CAddress = address << 1;
    IRQPin = irqPin
    
    I2CPort.configure(CLOCK_SPEED_400_KHZ);
	IRQPin.configure(DIGITAL_IN, getIRQSources.bindenv(this));
}

// Read a byte
IOExpander.read <- function(register) {

	// Read and return data if successful
	local data = I2CPort.read(I2CAddress, format("%c", register), 1);
	if (data != null) return data[0];
	
	// Error, return -1
	server.log("I2C Read Failed");
	return -1;
}

// Write a byte
IOExpander.write <- function(register, data) {
	I2CPort.write(I2CAddress, format("%c%c", register, data));
}

// Write a bit to a register
IOExpander.writeBit <- function(register, bitn, level) {
	local value = read(register);
	value = (level == 0)?(value & ~(1<<bitn)):(value | (1<<bitn));
	write(register, value);
}

// Write a masked bit pattern
IOExpander.writeMasked <- function(register, data, mask) {
   local value = read (register);
   value = (value & ~mask) | (data & mask);
   write (register, value);
}

// Set a GPIO direction
IOExpander.setDir <- function(gpio, output){
	writeBit (gpio>=8?0x0e:0x0f, gpio&7, output?0:1);
}

// Set a GPIO level
IOExpander.setPin <- function(gpio, level){
	writeBit (gpio>=8?0x10:0x11, gpio&7, level?1:0);
}

// Enable/disable a GPIO internal pull-up resistor
IOExpander.setPullUp <- function(gpio, enable) {
	writeBit (gpio>=8?0x06:0x07, gpio&7, enable);
}

// Set GPIO interrupt mask
IOExpander.setIRQMask <- function(gpio, enable) {
	writeBit (gpio>=8?0x12:0x13, gpio&7, enable);
}

// Set GPIO interrupt edges
IOExpander.setIRQEdges <- function(gpio, rising, falling) {
	local addr = 0x17 - (gpio>>2);
	local mask = 0x03 << ((gpio&3)<<1);
	local data = (2*falling + rising) << ((gpio&3)<<1);    
	writeMasked (addr, data, mask);
}

// Clear an interrupt
IOExpander.clearIRQ <- function(gpio) {
	writeBit (gpio>=8?0x18:0x19, gpio&7, 1);
}

IOExpander.setIRQCallBack <- function(pin, func){
	IRQ_Callbacks[pin] = func;
}

IOExpander.clearIRQCallBack <- function(pin){
	   IRQ_Callbacks[pin] = null;
}

IOExpander.getIRQSources <- function(){
   if(IRQPin.read() == 0){
       return;  //No need to run the code - the IRQ line has simply gone low
   }
    //0x18=RegInterruptSourceB (Pins 15->8), 1 is an interrupt and we write a 1 to clear the interrupt
	//0x19=RegInterruptSourceA (Pins 7->0), 1 is an interrupt and we write a 1 to clear the interrupt
   local sourceB = read(0x18);
   local sourceA = read(0x19);
   //server.log(format("Interrupt Source B = %s", byteString(sourceB, 1)));
   //server.log(format("Interrupt Source A = %s", byteString(sourceA, 1)));

	local irqSources = array(16);
	
	local pin = 0;

	for(local z=1; z < 256; z = z<<1){
		irqSources[pin] = ((sourceA & z) == z);
		irqSources[pin+8] = ((sourceB & z) == z);
        
        if(irqSources[pin]){
    		IRQ_Callbacks[pin]();
			clearIRQ(pin);
		}
        
        if(irqSources[pin+8]){
        	IRQ_Callbacks[pin+8]();
			clearIRQ(pin+8);
		}
        
		pin++;
	}
   return irqSources;    //Array of the IO pins and who has active interrupts
}

// Get a GPIO input pin level
IOExpander.getPin <- function(gpio) {
	//If gpio pin is greater than or equal to 8 then its staus is in the 0x10 register, else its in the 0x11 register.  Then left shift to create a mask for the particular pin and return true or false based on its value
	return (read(gpio>=8?0x10:0x11)&(1<<(gpio&7))) ? 1 : 0;
}

/**  ------------------------- END IO EXPANDER CODE --------------------------- **/

/*******************************************************************************
    Temperature Sensor Class for SA56004X
*******************************************************************************/
TemperatureSensor <- {}

TemperatureSensor.i2cPort <- null;
TemperatureSensor.i2cAddress <- null;
TemperatureSensor.irqPin <- null;   //TODO: Need to fully implement the TemperatureSensor Interrupt/Callback system
TemperatureSensor.callBack <- null;
TemperatureSensor.conversionRate <- 0x04;


TemperatureSensor.Init <- function(port, address, irq, call = null) {
    //server.log("Contructing TemperatureSensor")
    i2cPort = port;
    i2cAddress = address << 1;
    irqPin = irq;
    callBack = call;

    // Configure device for single shot, no alarms
    write(0x09, 0xD5);

    // Set default conversion rate (1Hz)
    setRate(conversionRate);
    
    // Set event handler for irq
    IOExpander.setIRQCallBack(irqPin, irqHandler.bindenv(this))
        
    // Configure pin as input, irq on both edges
    IOExpander.setDir(irqPin, 0);
    IOExpander.setPullUp(irqPin, 1);
    IOExpander.setIRQMask(irqPin, 0);
    IOExpander.setIRQEdges(irqPin, 1, 1);
    //server.log("TemperatureSensor Constructed")
}

 
TemperatureSensor.irqHandler <- function() {
    server.log("Temperature Sensor irqHandler Called");
    //TODO: Get what caused interrupt
    if (callBack != null) callBack() 

    // Clear the interrupt
    //IOExpander.clearIRQ(pin); //Taken care of by the IOExpander Class
}

// Read a byte
TemperatureSensor.read <- function(register) {
    local data = i2cPort.read(i2cAddress, format("%c", register), 1);
    if(data == null) {
        server.log("I2C Read Failure");
        return -1;
    }

    return data[0];
}

// Write a byte
TemperatureSensor.write <- function(register, data) {
    i2cPort.write(i2cAddress, format("%c%c", register, data));
}

// Set continuous conversion rate, 0 = 0.06Hz, 4 = 1Hz, 9 = 32Hz
TemperatureSensor.setRate <- function(rate){
    if(rate >= 0 && rate <= 9) {
        write(0x0a, rate);
        conversionRate = rate;
    }
    else {
        write(0x0a, 0x04);
        conversionRate = 0x04;
        server.log("Invalid conversion rate, using default 1Hz");
    }

}

// Stop continuous conversion
TemperatureSensor.stop <- function() {
    write(0x09, 0xD5);
}

// Start conversion, continuous or single shot
TemperatureSensor.start <- function(continuous = false) {
    if(continuous == true) {
        write(0x09, 0x55);
    }
    else {
        write(0x0f, 0x00);
    }
}

// Check if conversion is completed
TemperatureSensor.isReady <- function() {        
    return (read(0x02) & 0x80)?false:true;
}

// Retrieve temperature (from local sensor) in deg C
TemperatureSensor.getTemperature <- function() {
    // Get 11-bit signed temperature value in 0.125C steps
    local temp = (read(0x00) << 3) | (read(0x22) >> 5);

    if(temp & 0x400) {
        // Negative two's complement value
        return -((~temp & 0x7FF) + 1) / 8.0;
    }
    else {
        // Positive value
        return temp / 8.0;
    }
}

TemperatureSensor.getFTemperature <- function(){
    local Ctemp = this.getTemperature();
    return Ctemp*1.8+32;
}
/**  ------------------------- END TEMP SENSOR CODE --------------------------- **/


/*******************************************************************************
                   ACCELEROMETER CODE (LIS331DLTR)
*******************************************************************************/
Accelerometer <- {}

Accelerometer.i2cPort <- null;
Accelerometer.i2cAddress <- null;
Accelerometer.irqPin <- null;
Accelerometer.callBack <- null;
Accelerometer.FullScaleEnabled <- 0;

Accelerometer.Init <- function(port, address, irq, call = null){
    i2cPort = port;
    i2cAddress = address << 1;
    irqPin = irq;
    callBack = call;
    
    // Set event handler for irq
    IOExpander.setIRQCallBack(irqPin, irqHandler.bindenv(this))
        
    //TODO: Need to get all of our edges configured right so that we can clear the interrupts and not miss anything.
    // Configure pin as input, irq on rising edges
    IOExpander.setDir(irqPin, 0);
    IOExpander.setPullUp(irqPin, 1);
    IOExpander.setIRQMask(irqPin, 0);
    IOExpander.setIRQEdges(irqPin, 1, 0);
    
    //Reset Accelerometer
    write(0x21, 0x40); // CTRL_REG2 (21h)   0x40 = B01000000
    //SPI 4/3 wire
    //1=ReBoot - reset chip defaults
    //n/a
    //filter off/on
    //filter for freefall 2
    //filter for freefall 1
    //filter freq MSB
    //filter freq LSB - Hipass filter (at 400hz) 00=8hz, 01=4hz, 10=2hz, 11=1hz (lower by 4x if sample rate is 100hz)
    
    //Enable Accelerometer to sample 2g @ 400Hz on all 3 axis's
    write(0x20, 0xC7);  // CTRL_REG1 (20h)  0xC7 = B11000111
    //sample rate 100/400hz
    //power off/on
    //2g/8g
    //self test
    //self test
    //z enable
    //y enable
    //x enable

    //Enable single and double tap interrupts
    write(0x3B, 0x33);    //CLICK_THSY_X (3Bh)      THSy3 | THSy2 | THSy1 | THSy0 | THSx3 | THSx2 | THSx1 | THSx0     //From 0.5 g (0001) to 7.5 g (1111) with step of 0.5 g
    write(0x03, 0x03);    //CLCIK_THZ (3Ch)         -- -- -- -- | THSz3 | THSz2 | THSz1 | THSz0
    write(0x3D, 0xFF);    //CLICK_Timelimit (3Dh)   From 0 to 127.5 msec with step of 0.5 msec
    write(0x3E, 0x00);    //CLICK_Latency (3Eh)     From 0 to 255 msec with step of 1 msec
    write(0x3F, 0xFF);    //CLICK_Window (3Fh)      From 0 to 255 msec with step of 1 msec
    write(0x38, 0xFF);    //CLICK_CFG(38h)   //3F       - | Latch Interrupt Request (LIR) | Double_Z | Single_Z | Double_Y | Single_Y | Double_X | Single_X
    
    write(0x22, 0x07)     //CTRL_REG3 [interrupt register] (22h)  IHL | PP_OD | I2_CFG2 | I2_CFG1 | I2_CFG0 | I1_CFG2 | I1_CFG1 | I1_CFG0
    read(0x39); //Clear the interrupt
}
 
//TODO: there is a memory leak somewhere in this code...
Accelerometer.irqHandler <- function(clickSrc = null) {
    if(clickSrc == null)    //else we were called recursively to clear the queue of things on the Accelerometer IRQ
        clickSrc = read(0x39);    //CLICK_SRC (39h) -- | Interrupt Active (IA) | Double_Z | Single_Z | Double_Y | Single_Y | Double_X | Single_X
        //this read should clear the interrupt register on the accelerometer
    
    if (callBack == null){
        return;
    }
    
    //server.log("Accelerometer = " + byteString(clickSrc, 1))

   
    if(bitRead(clickSrc, 6)){   //Interrupt Active
        if(bitRead(clickSrc, 0)){
            callBack(1, "X") ;
        } else if(bitRead(clickSrc, 1)){
            callBack(2, "X") ;
        } else if(bitRead(clickSrc, 2)){
            callBack(1, "Y") ;
        } else if(bitRead(clickSrc, 3)){
            callBack(2, "Y") ;
        } else if(bitRead(clickSrc, 4)){
            callBack(1, "Z") ;
        } else if(bitRead(clickSrc, 5)){
            callBack(2, "Z") ;
        }
    } else{
        server.log("ACCEL IRQ Called for no reason")
    }
    
    clickSrc = read(0x39)  //If the events happen quickly, sometimes the accelerometer will set its IRQ Pin low but the register will be queued with the next event, effectively blocking new ones.  This additional reading of the IRQ Register and recursive calling fixes that
    if(clickSrc != 0) this.irqHandler(clickSrc)
    else {
        imp.wakeup(0.10, function(accel = this){
            while(accel.read(0x39) != 0){}
            IOExpander.clearIRQ(accel.irqPin);    //The accelerometer can flood the IOExpander IRQ Pin and things can get out of sync - this tries to fix that
        });
    }

}

// Read a byte
Accelerometer.read <- function(register) {
    local data = i2cPort.read(i2cAddress, format("%c", register), 1);
    if(data == null) {
        server.log("I2C Read Failure");
        return -1;
    }

    return data[0];
}

// Write a byte
Accelerometer.write <- function(register, data) {
    i2cPort.write(i2cAddress, format("%c%c", register, data));
}

//TODO: We could create an I2C singleton that takes an i2cAddress and performs all these functions instead of repeating them in each class... Not sure which design pattern is better..
// Write a masked bit pattern
Accelerometer.writeMasked <- function(register, data, mask) {
   local value = read (register);
   value = (value & ~mask) | (data & mask);
   write (register, value);
}

Accelerometer.EnableFullScale <- function() {    //Sets Sensitivity to 72mg/digit and range to +-9.2g's
    writeMasked(0x20, 0xFF, 0x20);
    FullScaleEnabled = 1;
}

Accelerometer.DisableFullScale <- function() {   //Sets Sensitivity to 18mg/digit and range to +-2.3g's
    writeMasked(0x20, 0x00, 0x20);
    FullScaleEnabled = 0;
}

Accelerometer.twosComplement <- function(val) {  //Eight bit two's compliment function.  In order to change to other word lengths, edit the two hex values
    if(val & 0x80) {
        val = -((~val & 0xFF) + 1); // Negative two's complement value
    }
    else {
        val =  val;  // Positive value
    }
    return val;
}

Accelerometer.reading2Gs <- function(val) {
   val = twosComplement(val)
   if (FullScaleEnabled == 0){   //High Sensitivity, Low Measurement Range
        val = val*0.018;
    } 
    else if (FullScaleEnabled == 1){//Low Sensitivity, High Measurement Range
        val = val*0.072;
    }
    return val;
}

//Functions return acceleration in their axes in g's
Accelerometer.getZ <- function() {  
    return reading2Gs(read(0x2d));  //
}
Accelerometer.getY <- function() {
    return reading2Gs(read(0x2b));
}
Accelerometer.getX <- function() {
    return reading2Gs(read(0x29));
}
//
//// User set points. Adjust these to your washing machine
//local timeout = 3 // the duration in minutes
//local POLL_INTERVAL = 0.5 // interval is seconds between polling the acellerometer
//local ACCEL_THRESHOLD = 50; // threshold signal for teh accelerometer
//local INTERNAL_TIMEOUT = timeout*60/POLL_INTERVAL // scale by poll interval
//
//server.log(format("Poll Interval: %f seconds", POLL_INTERVAL));
//server.log(format("Acceleration Threshold: %d", ACCEL_THRESHOLD));
//server.log(format("Timeout: %d minutes", timeout));
//server.log(format("Internal Timeout: %d", INTERNAL_TIMEOUT));
//
//// Change to a random color every 500ms
//function poll() {
//    imp.wakeup(POLL_INTERVAL, poll)
//    
//    if (running == 1) {
//        
//        local xtest = accelerometer.getX()
//        local ytest = accelerometer.getY()
//        local ztest = accelerometer.getZ()
//
//
//        local x = ((xtest + 128) % 256) - 128.0
//        local y = ((ytest + 128) % 256) - 128.0
//        local z = ((ztest + 128) % 256) - 128.0
//    
//        averageX = averageX * exponentialFactor + x * (1-exponentialFactor)
//        averageY = averageY * exponentialFactor + y * (1-exponentialFactor)
//        averageZ = averageZ * exponentialFactor + z * (1-exponentialFactor)
//    
//        local motion = math.abs(x-averageX) + math.abs(y-averageY) + math.abs(z-averageZ)
//        //server.log(format("current motion:! %d", motion));
//
//        if(motion > ACCEL_THRESHOLD && warmup > 3/(1-exponentialFactor)) {
//            server.log(format("triggered! %d", motion))
//            timer = 0
//            startTimer = 1
//        } else {
//            warmup += 1
//            if (timer > INTERNAL_TIMEOUT){
//                server.log("send sms")
//                out.set (1)
//                server.show("washing machine is done")
//                server.log("turning off timer")
//                timer = 0
//                startTimer = 0
//                running = 0
//                led.setLevels(100, 1, 1);
//            }
//        }
//        
//        if (startTimer) {
//            timer++
//            server.log(format("timer count:! %d", timer));
//        }
//    }
//}

/**  ------------------------- END ACCELEROMETER CODE --------------------------- **/

/*******************************************************************************
                   ARGB LIGHT SENSOR CODE (ADJD-S311-CR999)
*******************************************************************************/

/*
#define CTRL 0x00
#define CONFIG 0x01
#define CAP_RED 0x06
#define CAP_GREEN 0x07
#define CAP_BLUE 0x08
#define CAP_CLEAR 0x09
#define INT_RED_LO 0xA
#define INT_RED_HI 0xB
#define INT_GREEN_LO 0xC
#define INT_GREEN_HI 0xD
#define INT_BLUE_LO 0xE
#define INT_BLUE_HI 0xF
#define INT_CLEAR_LO 0x10
#define INT_CLEAR_HI 0x11
#define DATA_RED_LO 0x40
#define DATA_RED_HI 0x41
#define DATA_GREEN_LO 0x42
#define DATA_GREEN_HI 0x43
#define DATA_BLUE_LO 0x44
#define DATA_BLUE_HI 0x45
#define DATA_CLEAR_LO 0x46
#define DATA_CLEAR_HI 0x47
#define OFFSET_RED 0x48
#define OFFSET_GREEN 0x49
#define OFFSET_BLUE 0x4A
#define OFFSET_CLEAR 0x4B
*/
//
//#include <Arduino.h>
//#include <ADJDS311.h>
//
//ADJDS311::ADJDS311(int led_pin) {
//    _led_pin = led_pin;
//}
//
//
//
//void ADJDS311::calibrate(){
//	delay(2); //wait for LED to come full brintness if used
//	calibrateColor();  // This calibrates R, G, and B int registers
//	calibrateClear();  // This calibrates the C int registers
//	calibrateCapacitors();  // This calibrates the RGB, and C cap registers
//}
//
//void ADJDS311::ledOn(){
//	digitalWrite(_led_pin, HIGH);
//}
//
//void ADJDS311::ledOff(){
//	digitalWrite(_led_pin, LOW);
//}
//
//
//void ADJDS311::init(){
//  	Serial.begin(9600);
//	Serial.print("init");
//	
//	pinMode(_led_pin, OUTPUT);  // Set the sensor's LED as output
//	
//	Wire.begin();
//	delay(1);  // Wait for ADJD reset sequence
//	
//	
//	colorCap[0] = 9;
//	colorCap[1] = 9;
//	colorCap[2] = 2;
//	colorCap[3] = 5;
//	// values must be between 0 and 15
//	
//	
//	colorInt[0] = 2048;
//	colorInt[1] = 2048;
//	colorInt[2] = 2048;
//	colorInt[3] = 2048;
//	// max value for these is 4095
// 
//	
//	// sensor gain registers, CAP_... to select number of capacitors.
//	// value must be <= 15 */
//	writeRegister(colorCap[RED] & 0xF, CAP_RED);
//	writeRegister(colorCap[GREEN] & 0xF, CAP_GREEN);
//	writeRegister(colorCap[BLUE] & 0xF, CAP_BLUE);
//	writeRegister(colorCap[CLEAR] & 0xF, CAP_CLEAR);
//	
//	//Write sensor gain registers INT_...
//	//to select integration time  value must be <= 4096
//	writeRegister((unsigned char)colorInt[RED], INT_RED_LO);
//	writeRegister((unsigned char)((colorInt[RED] & 0x1FFF) >> 8), INT_RED_HI);
//	writeRegister((unsigned char)colorInt[BLUE], INT_BLUE_LO);
//	writeRegister((unsigned char)((colorInt[BLUE] & 0x1FFF) >> 8), INT_BLUE_HI);
//	writeRegister((unsigned char)colorInt[GREEN], INT_GREEN_LO);
//	writeRegister((unsigned char)((colorInt[GREEN] & 0x1FFF) >> 8), INT_GREEN_HI);
//	writeRegister((unsigned char)colorInt[CLEAR], INT_CLEAR_LO);
//	writeRegister((unsigned char)((colorInt[CLEAR] & 0x1FFF) >> 8), INT_CLEAR_HI);
//}
//
///* calibrateClear() - This function calibrates the clear integration registers
//of the ADJD-S311.
//*/
//int ADJDS311::calibrateClear(){
//	int gainFound = 0;
//	int upperBox=4096;
//	int lowerBox = 0;
//	int half;
//	
//	while (!gainFound){
//		half = ((upperBox-lowerBox)/2)+lowerBox;
//		//no further halfing possbile
//		
//		if (half==lowerBox){
//			gainFound=1;
//		}else{
//			writeInt(INT_CLEAR_LO, half);
//			performMeasurement();
//			int halfValue = readRegisterInt(DATA_CLEAR_LO);
//		
//			if (halfValue>1000){
//				upperBox=half;
//			}else if (halfValue<1000){
//				lowerBox=half;
//			}else{
//				gainFound=1;
//			} 
//		}
//	}
//	return half;
//}
//
///* calibrateColor() - This function clalibrates the R,G, and B 
//integration registers.
//*/
//int ADJDS311::calibrateColor(){
//  int gainFound = 0;
//  int upperBox=4096;
//  int lowerBox = 0;
//  int half;
//  
//  while (!gainFound)
//  {
//    half = ((upperBox-lowerBox)/2)+lowerBox;
//    //no further halfing possbile
//    if (half==lowerBox)
//    {
//      gainFound=1;
//    }
//    else {
//      writeInt(INT_RED_LO, half);
//      writeInt(INT_GREEN_LO, half);
//      writeInt(INT_BLUE_LO, half);
//
//      performMeasurement();
//      int halfValue = 0;
//
//      halfValue=max(halfValue, readRegisterInt(DATA_RED_LO));
//      halfValue=max(halfValue, readRegisterInt(DATA_GREEN_LO));
//      halfValue=max(halfValue, readRegisterInt(DATA_BLUE_LO));
//
//      if (halfValue>1000) {
//        upperBox=half;
//      }
//      else if (halfValue<1000) {
//        lowerBox=half;
//      }
//      else {
//        gainFound=1;
//      }
//    }
//  }
//  return half;
//}
//
///* calibrateCapacitors() - This function calibrates each of the RGB and C
//capacitor registers.
//*/
//void ADJDS311::calibrateCapacitors(){
//  int  calibrationRed = 0;
//  int  calibrationBlue = 0;
//  int  calibrationGreen = 0;
//  int calibrated = 0;
//
//  //need to store detect better calibration
//  int oldDiff = 5000;
//
//  while (!calibrated){
//    // sensor gain setting (Avago app note 5330)
//    // CAPs are 4bit (higher value will result in lower output)
//    writeRegister(calibrationRed, CAP_RED);
//    writeRegister(calibrationGreen, CAP_GREEN);
//    writeRegister(calibrationBlue, CAP_BLUE);
//
//    // int colorGain = _calibrateColorGain();
//    int colorGain = readRegisterInt(INT_RED_LO);
//    writeInt(INT_RED_LO, colorGain);
//    writeInt(INT_GREEN_LO, colorGain);
//    writeInt(INT_BLUE_LO, colorGain);
//
//    int maxRead = 0;
//    int minRead = 4096;
//    int red   = 0;
//    int green = 0;
//    int blue  = 0;
//    
//    for (int i=0; i<4 ;i ++)
//    {
//      performMeasurement();
//      red   += readRegisterInt(DATA_RED_LO);
//      green += readRegisterInt(DATA_GREEN_LO);
//      blue  += readRegisterInt(DATA_BLUE_LO);
//    }
//    red   /= 4;
//    green /= 4;
//    blue  /= 4;
//
//    maxRead = max(maxRead, red);
//    maxRead = max(maxRead, green);
//    maxRead = max(maxRead, blue);
//
//    minRead = min(minRead, red);
//    minRead = min(minRead, green);
//    minRead = min(minRead, blue);
//
//    int diff = maxRead - minRead;
//
//    if (oldDiff != diff)
//    {
//      if ((maxRead==red) && (calibrationRed<15))
//        calibrationRed++;
//      else if ((maxRead == green) && (calibrationGreen<15))
//        calibrationGreen++;
//      else if ((maxRead == blue) && (calibrationBlue<15))
//        calibrationBlue++;
//    }
//    else
//      calibrated = 1;
//      
//    oldDiff=diff;
//
//    int rCal = calibrationRed;
//    int gCal = calibrationGreen;
//    int bCal = calibrationBlue;
//  }
//  
//}
//
///* writeInt() - This function writes a 12-bit value
//to the LO and HI integration registers */
//void ADJDS311::writeInt(int address, int gain){
//  if (gain < 4096) 
//  {
//    byte msb = gain >> 8;
//    byte lsb = gain;
//
//    writeRegister(lsb, address);
//    writeRegister(msb, address+1);
//  }
//}
//
///* performMeasurement() - This must be called before
//reading any of the data registers. This commands the
//ADJD-S311 to perform a measurement, and store the data
//into the data registers.*/
//void ADJDS311::performMeasurement(){  
//  writeRegister(0x01, 0x00); // start sensing
//  while(readRegister(0x00) != 0)
//    ; // waiting for a result
//}
//
//
//
//RGBC ADJDS311::read(){
//	//Read data registers and return a RGBC var
//	RGBC color = RGBC();
//	
//	performMeasurement();
//	
//	color.red = readRegisterInt(DATA_RED_LO);
//	color.green = readRegisterInt(DATA_GREEN_LO);
//	color.blue = readRegisterInt(DATA_BLUE_LO);
//	color.clear = readRegisterInt(DATA_CLEAR_LO);
//	
//	return color;
//}
//
///* getOffset() - This function performs the offset reading
//and stores the offset data into the colorOffset[] array.
//You can turn on data trimming by uncommenting out the 
//writing 0x01 to 0x01 code.
//*/
//void ADJDS311::getOffset(){
//  digitalWrite(_led_pin, LOW);  // turn LED off
//  delay(10);  // wait a tic
//  writeRegister(0x02, 0x00); // start sensing
//  while(readRegister(0x00) != 0)
//    ; // waiting for a result
//  //writeRegister(0x01, 0x01);  // set trim
//  //delay(100);
//  for (int i=0; i<4; i++)
//    colorOffset[i] = (signed char) readRegister(OFFSET_RED+i);
//  digitalWrite(_led_pin, HIGH);
//}
//
//// Write a byte of data to a specific ADJD-S311 address
//void ADJDS311::writeRegister(unsigned char data, unsigned char address){
//  Wire.beginTransmission(ADJD_S311_ADDRESS);
//  Wire.write(address);
//  Wire.write(data);
//  Wire.endTransmission();
//}
//
//// read a byte of data from ADJD-S311 address
//unsigned char ADJDS311::readRegister(unsigned char address){
//  unsigned char data;
//  
//  Wire.beginTransmission(ADJD_S311_ADDRESS);
//  Wire.write(address);
//  Wire.endTransmission();
//  
//  Wire.requestFrom(ADJD_S311_ADDRESS, 1);
//  while (!Wire.available())
//    ;  // wait till we can get data
//  
//  return Wire.read();
//}
//
//// Write two bytes of data to ADJD-S311 address and addres+1
//int ADJDS311::readRegisterInt(unsigned char address){
//  return readRegister(address) + (readRegister(address+1)<<8);
//}
/////////////////////////////////////////////////////////////////
//#include <ADJDS311.h>
//#include <Wire.h>
//
//int sensorLed_pin = 2; //LED on the ADJDS-311
//ADJDS311 colorSensor(sensorLed_pin);
//
////if using an RGB LED (Needs PWM Pins)
//int redPin = 3;
//int greenPin = 5;
//int bluePin = 6;
//
//void setup(){
//  Serial.begin(9600);
//  
//  colorSensor.init();
//  colorSensor.ledOn(); //turn LED on
//  
//  //Calibrate white 
//  //Need to hold white card in front (1-3mm) of it to calibrate from
//  colorSensor.calibrate(); 
//}
//
//void loop(){
//  RGBC color = colorSensor.read(); //read the color
//  
//  Serial.print(color.red);
//  Serial.print(" | ");
//  Serial.print(color.green);
//  Serial.print(" | ");
//  Serial.print(color.blue);
//  Serial.print(" | ");
//  Serial.println(color.clear);
//  
//  lightLED(color); //send color to the LED
//  
//  delay(200); //just here to slow down the serial output
//  
//}
//
//void lightLED(RGBC color){
//  //RGBC is an array of red/green/blue/clear readings 
//  //Take a RGBC, and try to reproduce it on an RGB LED
//  //This does not work very well as is because of how colors/our eyes work
//  
//  analogWrite(redPin, map(color.red, 0, 1024, 0, 255));
//  analogWrite(greenPin, map(color.green, 0, 1024, 0, 255));
//  analogWrite(bluePin, map(color.blue, 0, 1024, 0, 255));
//}
//http://bildr.org/2012/01/adjd-s311_arduino/
/**  ------------------------- END LIGHT SENSOR CODE --------------------------- **/


/*******************************************************************************
                   LED FUNCTIONS
*******************************************************************************/
const red = "\xFF\x00\x00";
const green = "\x00\xff\x00";
const blue = "\x00\x00\xff";
const orange = "\xFF\x7F\x00";
const yellow = "\xFF\xFF\x00";
const indigo = "\x66\x00\xFF";
const violet = "\x8B\x00\xFF";
const white = "\xff\xff\xff";
const off = "\x00\x00\x00\x00";
const cyan = "\x00\xff\xff";
const magenta = "\xff\x00\xff";
const gray = "\xc0\xc0\xc0";
const dimWhite = "\x0f\x0f\x0f";
colorArray <- [red, orange, yellow, green, blue, indigo, violet, white];

//Class works for RGB LED's With a real or software controllable Alpha Channel
//Can be used for Common Cathode or Common Annode LED's
class ARGBLED
{    
    _permKey = null;
    _name = null;
    
    //Permanently Stored Values
    _ledValue = null;
    _ledBlinkDelay = null;
    _ledBlinking = false;
    _rainbowIndex = 0;

    //Values passed into Constructor
    _pinA = null;
    _pinR = null;
    _pinG = null;
    _pinB = null;
    _invertVal = null;
    
    //Volatile Values
    _levelTarget = null;
    _levelStep = null;
    
    constructor(a=null,r=null,g=null,b=null, newName="", colorValInvert = null)
    {
        //base.constructor(newName, "number");
        _name = newName;
    	_pinA = a
        _pinR = r;
        _pinG = g;
        _pinB = b;
        _invertVal = colorValInvert;   //Defaults to Common Cathode or no change to color vals, change to 1.0 for common Annode
                
        _permKey = "ARGBLED - "+newName;
        /*if (!(_permKey in nv)) {
            nv[_permKey] <- {
                _ledValue = [1.0,1.0,1.0,1.0],
                _ledBlinkDelay = 1.0,
                _ledBlinking = false,
            }
            serverPermanentUpdate();
        }*/
    
        //_ledValue = nv[_permKey]._ledValue;	//alpha, red, green, blue
        //_ledBlinkDelay = nv[_permKey]._ledBlinkDelay;
        //_ledBlinking = nv[_permKey]._ledBlinking;
        
		_ledValue = [1.0,1.0,1.0,1.0];
        _ledBlinkDelay = 1.0;
        _ledBlinking = false;
		
        Init();
    }
    
    function Init(){
		// Disable pin input buffers
        IOExpander.writeBit(_pinR>7?0x00:0x01, _pinR>7?(_pinR-7):_pinR, 1);
        IOExpander.writeBit(_pinG>7?0x00:0x01, _pinG>7?(_pinG-7):_pinG, 1);
        IOExpander.writeBit(_pinB>7?0x00:0x01, _pinB>7?(_pinB-7):_pinB, 1);
 
        // Set pins as outputs
        IOExpander.writeBit(_pinR>7?0x0E:0x0F, _pinR>7?(_pinR-7):_pinR, 0);
        IOExpander.writeBit(_pinG>7?0x0E:0x0F, _pinG>7?(_pinG-7):_pinG, 0);
        IOExpander.writeBit(_pinB>7?0x0E:0x0F, _pinB>7?(_pinB-7):_pinB, 0);
 
        // Set pins open drain
        IOExpander.writeBit(_pinR>7?0x0A:0x0B, _pinR>7?(_pinR-7):_pinR, 1);
        IOExpander.writeBit(_pinG>7?0x0A:0x0B, _pinG>7?(_pinG-7):_pinG, 1);
        IOExpander.writeBit(_pinB>7?0x0A:0x0B, _pinB>7?(_pinB-7):_pinB, 1);
 
        // Enable LED drive
        IOExpander.writeBit(_pinR>7?0x20:0x21, _pinR>7?(_pinR-7):_pinR, 1);
        IOExpander.writeBit(_pinG>7?0x20:0x21, _pinG>7?(_pinG-7):_pinG, 1);
        IOExpander.writeBit(_pinB>7?0x20:0x21, _pinB>7?(_pinB-7):_pinB, 1);
 
        // Set to use internal 2MHz clock, linear fading
        IOExpander.write(0x1e, 0x50);
        IOExpander.write(0x1f, 0x10);
 
        // Initialise as Active
        setLedActive(1, 1, 1);
        IOExpander.setPin(_pinR, 0);
        IOExpander.setPin(_pinG, 0);
        IOExpander.setPin(_pinB, 0);
        
        //To use a Raw RGB LED instead of the IOExpander, uncomment all the sections that look like this and comment all the IOExpander sections like those above.
        /*if(_pinA){
			_pinA.configure(PWM_OUT, 1.0/500.0, 1.0);
			//_pinA.write(1.0);
		}
		if(_pinR){
			_pinR.configure(PWM_OUT, 1.0/500.0, 1.0);
			//_pinR.write(1.0);
		}
		if(_pinG){
			_pinG.configure(PWM_OUT, 1.0/500.0, 1.0);
			//_pinG.write(1.0);
		}
		if(_pinB){
			_pinB.configure(PWM_OUT, 1.0/500.0, 1.0);
			//_pinB.write(1.0);
		}*/
       
		turnLEDOff();
        
        if(_ledBlinking == true){
            _ledBlinking = false
            BlinkLED(true)
        }
		
        return this;
    }
    
    //Set LED enabled state. The setLed method enables or disables each color segment, or makes no change given a null parameter. This will toggle the segment between off and the current brightness level.
    //Some of the code could be simplified if this functino was used but this is a hardware feature of the IOExpander and doesn't exist for raw RGB LED Components (Same goes for the ramping/fading code)
    function setLedActive(r, g, b) {
        if(r != null) IOExpander.writeBit(_pinR>7?0x20:0x21, _pinR&7, r);
        if(g != null) IOExpander.writeBit(_pinG>7?0x20:0x21, _pinG&7, g);
        if(b != null) IOExpander.writeBit(_pinB>7?0x20:0x21, _pinB&7, b);
    }
    
        // Set red, green and blue intensity levels
    /*function setLevels(r, g, b){
        if(r != null) IOExpander.write(_pinR<4?0x2A+_pinR*3:0x36+(_pinR-4)*5, r);
        if(g != null) IOExpander.write(_pinG<4?0x2A+_pinG*3:0x36+(_pinG-4)*5, g);
        if(b != null) IOExpander.write(_pinB<4?0x2A+_pinB*3:0x36+(_pinB-4)*5, b);
    }*/

    function renderColor(turnoff = false){
            local a = _ledValue[0]
            local r = _ledValue[1]
            local g = _ledValue[2]
            local b = _ledValue[3]
                
            if(turnoff == true){
                a = 0.0
                r = 0.0
                g = 0.0
                b = 0.0
            }
            
            if(_pinA == null){//if there is no pin for alpha, we recalculate the color values we write
                local hsv = rgbToHsv(r*255.0,g*255.0,b*255.0)
                local rgb = hsvToRgb(hsv[0], hsv[1], a)
                //server.log("a = " + a + " before rgb = " + r + "," + g + "," + b + " after rgb = " + rgb[0] + "," + rgb[1] + "," + rgb[2])
                r = rgb[0]/255.0
                g = rgb[1]/255.0
                b = rgb[2]/255.0
            }
            
            if(_invertVal){
                a = _invertVal - a
                r = _invertVal - r
                g = _invertVal - g
                b = _invertVal - b
            }

			/*if(_pinA)
				_pinA.write(a);
			if(_pinR)
				_pinR.write(r);
			if(_pinG)
				_pinG.write(g);
			if(_pinB)
				_pinB.write(b);*/
            if(r != null) IOExpander.write(_pinR<4?0x2A+_pinR*3:0x36+(_pinR-4)*5, r*255.0);
            if(g != null) IOExpander.write(_pinG<4?0x2A+_pinG*3:0x36+(_pinG-4)*5, g*255.0);
            if(b != null) IOExpander.write(_pinB<4?0x2A+_pinB*3:0x36+(_pinB-4)*5, b*255.0);
    }
    
    function turnLEDOff(){
		renderColor(true)
    }
    
    function turnLEDOn(){
        if(_ledValue[0] == 0 && _ledValue[1] == 0 && _ledValue[2] == 0 && _ledValue[3] == 0){
            _ledValue = [1.0, 1.0, 1.0, 1.0];
        }
		
        renderColor();
    }

    function BlinkLEDOn(){
        if(!_ledBlinking)
            return
            
        turnLEDOn();
        BlinkLED();
    }
    
    function BlinkLEDOff(){
        if(!_ledBlinking)
            return
            
        turnLEDOff();
    }
    
    function BlinkLED(startBlinking = false){
        if((_ledBlinking == true && startBlinking == false) || (_ledBlinking == false && startBlinking == true)){
            if(startBlinking == true){
                _ledBlinking = true;
				//nv[_permKey]._ledBlinking = _ledBlinking;
				//serverPermanentUpdate();
                turnLEDOn();
            }
            
            imp.wakeup(_ledBlinkDelay/2.0, BlinkLEDOff.bindenv(this));
            imp.wakeup(_ledBlinkDelay, BlinkLEDOn.bindenv(this))
        }
    }
    
    function StopBlinking(){
        _ledBlinking = false;
		//nv[_permKey]._ledBlinking = _ledBlinking;
		//serverPermanentUpdate();
    }
	
	function setBlinkDelay(delay){
		_ledBlinkDelay = delay
		//nv[_permKey]._ledBlinkDelay = _ledBlinkDelay;
		//serverPermanentUpdate();
	}

    function setLEDRGB(r,g,b, bRenderColor = true){
        if(r > 1.0 || g > 1.0 || b > 1.0 || r < 0.0 || g < 0.0 || b < 0.0){
            server.log("ERROR - bad value in setLEDRGB")
            return;
        }
        
        _ledValue = [_ledValue[0], r,g,b];
        //if(_ledValue[0] == 0.0 && bRenderColor) _ledValue[0] = 1.0
		//nv[_permKey]._ledValue = _ledValue;
		//serverPermanentUpdate();
        
		if(bRenderColor){
			renderColor();
		}
    }
	
	function setLEDAlpha(level, bRenderColor = true){
		if(level > 1.0 || level < 0.0){
            server.log("ERROR - bad value in setLEDAlpha = " + level)
            return;
        }
		_ledValue[0] = level;
		//nv[_permKey]._ledValue = _ledValue;
		//serverPermanentUpdate();
		
		if(bRenderColor){
            renderColor();
		}
	}
    
    function setLEDColor(color){
		if(color.len() == 3){
            //setLEDAlpha(1.0);
            setLEDRGB(color[0]/255.0, color[1]/255.0, color[2]/255.0);
		} else if(color.len() == 4){
    	    setLEDAlpha(color[0]/255.0);
            setLEDRGB(color[1]/255.0, color[2]/255.0, color[3]/255.0);
		} else {
    	    server.log("INVALID COLOR IN setLEDColor.  Length = " + color.len())   
		}
    }
    
    function getLEDColor(){
        return [_ledValue[0]*255.0, _ledValue[1]*255.0, _ledValue[2]*255.0, _ledValue[3]*255.0];
    }
    
    function getLEDRGBColor(){
        local hsv = rgbToHsv(_ledValue[1]*255.0,_ledValue[2]*255.0,_ledValue[3]*255.0)
        return hsvToRgb(hsv[0], hsv[1], _ledValue[0])
    }
    
    function rampLevel(level, secs = 0.5){
        local alreadyRamping = _levelTarget==null?false:true
        _levelTarget = level;
        _levelStep = (level - _ledValue[0])/(secs/0.01);
        
        if(!alreadyRamping) rampLevelHelper()
    }
    
    function rampLevelHelper(){
        if(_ledValue[0] + _levelStep > 1.0)
            setLEDAlpha(1.0)
        else if(_ledValue[0] + _levelStep < 0.0)
            setLEDAlpha(0.0)
        else
            setLEDAlpha(_ledValue[0] + _levelStep)
        
        if(_levelTarget != _ledValue[0] && ( (_levelStep < 0 && _levelTarget < _ledValue[0]) || (_levelStep > 0 && _levelTarget > _ledValue[0]) ) ){
            imp.wakeup(0.01, rampLevelHelper.bindenv(this))
        } else{
            setLEDAlpha(_levelTarget)    
            _levelTarget = null;
            _levelStep = null;
        }
        
    }
    
    function rainbowIncrement(){
        _rainbowIndex = (++_rainbowIndex >= colorArray.len()) ? 0 : _rainbowIndex
        this.setLEDColor(colorArray[_rainbowIndex])
    }
    
    function rainbowDecrement(){
        _rainbowIndex = (--_rainbowIndex < 0) ? colorArray.len()-1 : _rainbowIndex
        this.setLEDColor(colorArray[_rainbowIndex])
    }
}
/**  --------------------------------- END  LED FUNCTIONS --------------------------------------- **/

/*******************************************************************************
    PUSHBUTTON CODE
*******************************************************************************/
// PushButton Class for Hannah
class PushButton
{
    // IO _pin assignment
    _pin = null;
    _name = null;
    _callBack = null;
    _lastState = -1;    // Store the last state so we know when we've changed
    _debounceActive = false; //None of the debounce code is really needed on Hannah (the pushbuttons are nice and clean or the IOExpander is making life good) but its nice to have for other aplications
 
    //_pin is an integer of the _pin number on the IOExpander
    //call is a function(state) where state is a 0 or 1 equal to the state of the pushbutton (1 is pressed down)
    constructor(btnpin, name = null, call = null) {
        //server.log("Contructing PushButton")
 
        // Save assignments
        _pin = btnpin;
        _callBack = call;
        _name = (name==null)?"Button"+_pin : name
 
        // Set event handler for irq
        IOExpander.setIRQCallBack(_pin, irqHandler.bindenv(this))
 
        // Configure _pin as input, irq on both edges
        IOExpander.setDir(_pin, 0);
        IOExpander.setPullUp(_pin,1)
        IOExpander.setIRQMask(_pin, 0);
        IOExpander.setIRQEdges(_pin, 1, 1);
        
        check_state();  //Init the _lastState var
        
       //server.log("PushButton Constructed")
    }
    
    function read(){
        return _lastState;
    }

    // This function is called whenever the IO Expander detects a change
    function irqHandler() {
        if (!_debounceActive) {                            
            local data = check_state();
            local state = data[0];
            local changed = data[1];
     
            //server.log(format("Push Button %d = %d", _pin, state));
            if (_callBack != null && changed == true) _callBack(state) 
            if(changed == true) agent.send("ButtonPress", {[this._name] = state})
            // Clear the interrupt
            //IOExpander.clearIRQ(_pin); //Taken care of by the IOExpander Class
            
            // Ignore bounces                             
            _debounceActive = true;                       
            imp.wakeup(0.00001, debounce.bindenv(this));  
        }                                                 
    }
    
    function readState() {
        local state = IOExpander.getPin(_pin)?0:1;
        //server.log(format("debug %d", state));
        return state;
    }
    
    // Debounce code: ignore transitions after event
    function debounce() {
        _debounceActive = false; // We can take notice of transitions from now onward
        local last = _lastState;
        local data = check_state()
        
        if (data[1] == true && _callBack != null) _callBack(data[0]);
    }
     
    function check_state() {
        local s = readState();
        local changed = false;
        
        if (s != _lastState) { // Has the state changed? //TODO: Should this be returned?
            _lastState = s;
            changed = true;
        }
        return [s, changed];
    }
}




/**  ------------------------- END PUSHBUTTON CODE --------------------------- **/

/*******************************************************************************
    POTENTIOMETER CODE
*******************************************************************************/
Potentiometer <- {};

Potentiometer.pin <- null;
Potentiometer.max <- 65500; //Knock out the dead zones on the ends so we get nice clean 0 and 100 percentages
Potentiometer.min <- 256; 
Potentiometer.range <- (Potentiometer.max-Potentiometer.min)*1.0;
Potentiometer.lastReading <- 0;
Potentiometer.pushDelta <- 300;
Potentiometer.lastPushedReading <-100000;   //TODO: Implement
Potentiometer.callBack <- null;
Potentiometer.isPolling <- false;

Potentiometer.Init <- function(ppin, enablePin, pollFunc = null) {
    pin = ppin;
    
    //Enable the Potentiometer Power
    IOExpander.setPin(enablePin, 0);
    IOExpander.setDir(enablePin, 1);
    
    //Config the imp pin to read values
    pin.configure(ANALOG_IN);
    
    if(callBack != null) {
        callBack = pollFunc.bindenv(this);
        startPolling();
    }
}

//TODO: Can we do some sort of self calibration and store in server.permanent?
/*Potentiometer.calculateRange <- function() {
    this.range = (this.max-this.min)*1.0;
}*/

Potentiometer.read <- function() {
    local reading = this.pin.read();
    
    if (reading < this.min) {
        //this.min = reading;
        //this.calculateRange();
        reading = this.min;
    }
    if (reading > this.max) {
        //this.max = reading; 
        //this.calculateRange();
        reading = this.max;
    }
    lastReading = reading;
    //server.log(format("Potentiometer Reading = %d", reading))
    return reading;
}

Potentiometer.readSmooth <- function(){ //Returns a smoothed percentage - Currently provides 0-100 in integer steps
        
    //filteredValue = x * rawValue + (1-x)*lastFilteredValue; Uses a weighted Average to smooth the input
    local lReading = lastReading    //Need this otherwise this.read will steal it away from us
    local reading = this.read();
    
    local weightedAverage = (0.25 * reading) + ((0.75)*lReading);
    lastReading = weightedAverage;
    
    local percentage = round(((weightedAverage-this.min)/this.range)*100.0, 0);
    percentage<0.0?0.0:percentage;
    percentage>100.0?100.0:percentage;
    
    return percentage;  
}

Potentiometer.startPolling <- function(callFunc = -1){
    if(callFunc != -1) this.callBack = callFunc.bindenv(this)
    isPolling = true;
    poll();
}

Potentiometer.stopPolling <- function(){
    isPolling = false;
}

Potentiometer.poll <- function(){
    if(this.isPolling == true && this.callBack != null){
        this.callBack();
        imp.wakeup(0.00001, this.poll.bindenv(this))
    }
}
/**  ------------------------- END POTENTIOMETER CODE --------------------------- **/

/*******************************************************************************
    SERVO CODE
*******************************************************************************/

// Configure hardware
 
// the servo used in this example have ~170 degrees of range. Each servo has three pins: power, ground, and pulse in
// The width of the pulse determines the position of the servo
// The servo expects a pulse every 20 to 30 ms
// 0.8 ms pulse -> fully counterclockwise
// 2.6 ms pulse -> fully clockwise
//Sparkfun Small Servo https://www.sparkfun.com/products/9065 isn't specified but seems to be up to a maximum of 0.5ms to 2.5ms
class Servo
{
    _pin = null;
    _pinEnable = null;
    _minPulse = null; 
    _maxPulse = null;
    _maxAngle = 180.0
    _angle = null;
    
    constructor(pin, enablePin){
        _pin = pin;
        _pinEnable = enablePin
        
        // servo enable
        IOExpander.setPin(enablePin, 1);
        IOExpander.setDir(enablePin, 1);
        
        // set up PWM at a period of 20 ms, and initialize the duty cycle to the halfway point  //TODO: the initialize point should probably be passed into the constructor and/or remembered
        _angle = 0.5*_maxAngle;
        _pin.configure(PWM_OUT, 0.02, 0.0425);
    }
 
    function set(value) {
        if(value <0.0 || value > 1.0){
            server.log("ERROR: Bad Value to Servo.set = " + value);
            return;
        }
        _angle = value*_maxAngle;
        _pin.write(0.04 + (value * 0.09));
    }
    
    function write(angle) {
        this.set(angle/_maxAngle)
    }
    
    function read() {
        return _angle;
    }
    
    function readPercent() {
        return (_angle/_maxAngle)*100.0;
    }
}

/**  ------------------------- END SERVO CODE --------------------------- **/

/*******************************************************************************
    IMP CODE BASE
*******************************************************************************/

loopCounter <- 0;
function loop(){ 
	loopCounter++
	server.log("Loop - " + loopCounter + " FREE MEM = " + imp.getmemoryfree() + " Signal Strength = " + imp.rssi())
	imp.wakeup(15.0, loop.bindenv(this))
}


// Capture and log a temperature reading every 3s
function capture()
{
    agent.send("Send_Xively", getUIDataTable());
    
    imp.wakeup(3.0, capture); // Set timer for the next capture
}

function configParamsChanged(){
    server.log("CONFIG PARAMS CHANGED");
}

//Imp Configuration
imp.configure ("Hannah", [], [], {}, configParamsChanged);

////
//imp.enableblinkup(true);    //TODO: BUG: Fixes release-14 timing bugs for  sleep(), wakeup(), hardware.millis(), and micros() -- but not that of time()

bootState <- 0
function impBoot(){
	if(bootState == 0){
        collectgarbage();
		bootState++;
		imp.wakeup(0.000001, impBoot);
        return;
        
	} else if(bootState < 6) {
		if(imp.getmemoryfree() < 5000){	//Wait for messages in the queue to be sent.  Our final running RAM should be >7000 by experimentation
            imp.wakeup(0.000001, impBoot);
			return;
		}

		if(bootState == 1){    //Initialize Server Permanent
			//server.log("Create ServerPerm")
			if ("BootNumber" in server.permanent) {
                server.permanent.BootNumber++;
                serverPermanentUpdate();
            } else {
                server.setpermanentvalues( {BootNumber = 1} );	//Initialize the server.permanent table and set to updateto update
            }
            
            collectgarbage();
			
		} else if(bootState == 2){	//Instantiate Classes
            //server.log("Construct Classes")
            IOExpander.Init(I2C_PORT, IOEXPANDER_I2C_ADDRESS, IOEXPANDER_INTERRUPT_PIN);
            TemperatureSensor.Init(I2C_PORT, TEMP_SENSOR_I2C_ADDRESS, IO_TEMP_SENSOR_INTERRUPT_PIN);
            Accelerometer.Init(I2C_PORT, ACCELEROMETER_I2C_ADDRESS, IO_ACCELEROMETER_INTERRUPT_PIN, function(taps, axis){
                //server.log(format("Accelerometer IRQ = %s-Axis with %d taps", axis, taps));   //TODO: Contact EI about why this inserts ZTRAP instead of Z
                server.log("Accelerometer IRQ = " + axis + "-Axis with " + taps + " taps");
            })
            
            Potentiometer.Init(POTENTIOMETER_PIN, IO_POTENTIOMETER_ENABLE_PIN);
            rgbLED <- ARGBLED(null, IO_LED_R_PIN, IO_LED_G_PIN, IO_LED_B_PIN);
            servo1 <- Servo(SERVO1_PIN, IO_SERVO_POWEREN_PIN);
            servo2 <- Servo(SERVO2_PIN, IO_SERVO_POWEREN_PIN);
            pushButton1 <- PushButton(IO_BUTTON1_PIN, "Button1", function(state){ 
                server.log(this._name+ " = " +state); 
                if(state == 1){
                    rgbLED.rainbowIncrement()
                } else {

                }
                
                 agent.send("Send_Xively", {[this._name] = state});
            });
            pushButton2 <- PushButton(IO_BUTTON2_PIN, "Button2", function(state){ 
                server.log(this._name+ " = " +state); 
                if(state == 1){
                    rgbLED.rainbowDecrement()
                } else {

                }
                
                 agent.send("Send_Xively", {[this._name] = state});
            });
            hallSwitch <- PushButton(IO_HALL_SWITCH_PIN, "HallSwitch", function(state){ 
                server.log(this._name + " = " + state); 
                if(state == 1) {
                    server.log(byteString(Accelerometer.read(0x39), 1))
                    rgbLED.setLEDColor(orange);
                } else {
                    rgbLED.setLEDColor(green);
                }

                agent.send("Send_Xively", {[this._name] = state});
            });
			collectgarbage();
            
		} else if(bootState == 3){	//Instantiate Agent
			//server.log("Init Agents")
            initAgentCallbacks();
			delete getroottable().initAgentCallbacks;
            collectgarbage();
			
		} else if(bootState == 4){	//Initialze Classes
			//server.log("Init Classes")
            collectgarbage();
		
		} else if(bootState == 5){	//Start Loops
			//server.log("Start Loops")
            capture();
            Potentiometer.startPolling(function(){ 
                local reading = this.readSmooth();
                rgbLED.setLEDAlpha(reading/100.0); 
                
                if(pushButton1.read() == 1){
                    if(hallSwitch.read() == 1){
                        servo1.set(this.read()/0xFFFF.tofloat())
                    } else {
                        servo1.set(reading/100.0)
                    }
                    
                }
                
                if(pushButton2.read() == 1){
                    if(hallSwitch.read() == 1){    //This gives more steps to set the servo but with more jitter
                        servo2.set(this.read()/0xFFFF.tofloat())
                    } else {
                        servo2.set(reading/100.0)
                    }
                }
             });
            collectgarbage();
		}
		bootState++;
		imp.wakeup(0.000001, impBoot);
        return;
	}
	onBoot = false;
	agent.send("Device_Variables", getRunningStatisticsTable());
					
	onBoot = false;
    delete getroottable().impBoot;
    collectgarbage();
}
impBoot();
/**  ------------------------------ EOF ------------------------------------- **/