server.log("===============AGENT "+split(http.agenturl(), "/")[2]+" (v. " + imp.getsoftwareversion() + ") STARTING=========================");
server.log(http.agenturl());

/*******************************************************************************
                                  CONSTANTS
*******************************************************************************/
const DEVICE_WEBHOST = "http://www.electricimp.com";

//------------ External 3rd Party Services ---------------------//
//All these services have a free developer tier that you can register for and use.  Enter credentials below:

//TODO: need to add error handling code whenever these constants are not set...
//TODO: need to more fully implement all of these API's
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

//------------ Authentication and Authorization Control ---------------------//
//Level 0 is forbidden access
//Level 1 is Read Access
//Level 2 is Write Access
//Level 0xFFFF is Super Admin Access
AUTHORIZATION_LEVELS <- {
    //["Basic " + http.base64encode("username" + ":" + "password")] = 1,
    ["Basic " + http.base64encode("HannahImp" + ":" + "electricImp!23")] = 0xFFFF,
}

//------------ HTML Messages ---------------------//
const HTML_PREAMBLE1 = @"<!DOCTYPE html>
<html>
<head>
  <title>"
  
const HTML_PREAMBLE2 = @"</title>
  <style type=""text/css"">
    body { background-color: #fff; color: #666; text-align: center; font-family: arial, sans-serif; }
    div.dialog {
      width: 80%;
      padding: 0 4em;
      margin: 4em auto 0 auto;
      border: 1px solid #ccc;
      border-right-color: #999;
      border-bottom-color: #999;
    }
    h1 { font-size: 100%; color: #f00; line-height: 1.5em; }
  </style>
</head>

"

const HTML_BODY1 = @"<body>
  <div class=""dialog"">
    "
const HTML_BODY2 = @"  </div>
</body>
</html>"

const UNAUTHORIZED_HTML_TITLE = @"Unathorized Access (401)"
const UNAUTHORIZED_HTML_BODY = @"<h1>You do not have sufficient permissions to access the page. (HTTP Error 401)</h1>
    <p>Please check your username and password before trying again.</p>"

const FORBIDDEN_HTML_TITLE = @"Forbidden (403)"
const FORBIDDEN_HTML_BODY = @"<h1>You do not have sufficient permissions to access the page. (HTTP Error 403)</h1>
    <p>Please check your username, password, and authorization level before trying again.</p>"

const BAD_REQUEST_HTML_TITLE = @"Bad Requst (400)"
const BAD_REQUEST_HTML_BODY = @"<h1>The Request could not be satisfied. (HTTP Error 400)</h1>
    <p>Please see the reason below, check the message structure, and try again.  If the syntax is correct and the problem persists, please contact your imp developer.</p>"

const REQUEST_TIMEOUT_HTML_TITLE = @"Request Timeout (408)";
const REQUEST_TIMEOUT_HTML_BODY = @"The agent did not produce a response within the time that the server was prepared to wait. The client MAY repeat the request without modifications at any later time.";

const INTERNAL_SERVER_ERROR_HTML_TITLE = @"Internal Server Error (500)"
const INTERNAL_SERVER_ERROR_HTML_BODY = @"<h1>An Internal Server Error occurred on the imp Agent (HTTP Error 500)</h1>
    <p>Please check the message structure before trying again.  If the syntax is correct and the problem persists, please contact your imp developer.</p>"

const NOT_IMPLEMENTED_HTML_TITLE = @"Not Implemented (501)"
const NOT_IMPLEMENTED_HTML_BODY = @"<h1>The Requested Method has not been implemented (HTTP Error 501)</h1>
    <p>Please check the message structure before trying again.  If the syntax is correct and the problem persists, please contact your imp developer.</p>"

const SERVICE_UNAVAILABLE_HTML_TITLE = @"Service Unavailable (503)"
const SERVICE_UNAVAILABLE_HTML_BODY = @"<h1>The Server is unable to reach the imp at this time. (HTTP Error 503)</h1>
    <p>Most Likely the device is offline.  Please try again later.</p>"

const GATEWAY_TIMEOUT_HTML_TITLE = @"Gateway Timeout (504)"
const GATEWAY_TIMEOUT_HTML_BODY = @"<h1>The server was acting as a proxy to an imp and did not receive a timely response. (HTTP Error 504)</h1>
    <p>Most Likely the device is offline.  Please try again later.</p>"
/**--------------------------- END CONSTANTS ------------------------------- **/

/*******************************************************************************
                    HELPER FUNCTIONS
*******************************************************************************/
function round(val, decimal){
  if (decimal)
    return math.floor((val * math.pow(10,decimal)) + 0.5) / math.pow(10,decimal)
  else
    return math.floor(val+0.5)
}

function lowByte(w) {
    return w & 0xff
}

function highByte(w) {
    return w >> 8
}

function constrain(amt,low,high) {
    return ((amt)<(low)?(low):((amt)>(high)?(high):(amt)))
}
    
function radians(deg) { 
    return ((deg)*0.01745329252);
}

function degrees(rad) {
    return ((rad)*57.2957795131);
}

function bitRead(value, bit) {
    return (((value) >> (bit)) & 0x01);
}

function bitSet(value, bit) {
    return ((value) | (1 << (bit)));
}

function bitClear(value, bit) {
    return ((value) & ~(1 << (bit)))
}
    
function bitWrite(value, bit, bitvalue) {
    return (bitvalue ? bitSet(value, bit) : bitClear(value, bit))
}

function bit(b) {
    return (1 << (b))
}

function hexConvert(val, len){    //Takes a numeric hex (0x1234) or int value and returns a string len bytes long with hex values
    return format("%." + (len*2) + "X", val)
}

function map(x,in_min, in_max, out_min, out_max)
{
  return constrain((x - in_min) * (out_max+1 - out_min) / (in_max+1 - in_min) + out_min, out_min, out_max);
}

function logObject(msg){    //TODO: This function has a LONG way to go - I probably need a helper function to recursively call itself and convert all blobs with .tostring() and then jsonencode.
    if(msg.len() == 2)
        server.log(msg[0] + " = "+ http.jsonencode(msg[1]))
    else
        server.log(http.jsonencode(msg))
}

function byteString(arr){
    local str = ""
    try{
        for(local i = 0; i < arr.len(); i++){
            if(arr[i] == null) break;
        	str = str + format("%.2X ", arr[i]);
    	}
    } catch(ex){}
	return str;
}

function blobToBits(bl){
    local str = ""
    for(local i = 0; i < bl.len(); i++){
		if(bl[i] == null) break;
        for(local bit = 7; bit > 3; bit--){
            if(bitRead(bl[i], bit) == 1)
                str = str + "1"
            else
                str = str + "0"
        }
        str = str + " "
        for(local bit = 3; bit >= 0; bit--){
            if(bitRead(bl[i], bit) == 1)
                str = str + "1"
            else
                str = str + "0"
        }
        str = str + "\n"
	}
	
	return str;
}

function arrayString(arr){
	local str = ""
    if(arr == null)
        return;
        
	for(local i = 0; i < arr.len()-1; i++){
		if(arr[i] == null) break;
		str = str + format("%.2X ", arr[i]);
	}
	str = str + format("%.2X", arr[arr.len()-1]);
    
	return str
}

function strNumToInt(str){
    local retVal;
    
    if(str == null) return;
    
    try{
        if(typeof str == "string" && str.len() >= 3 && str[0] == '0' && (str[1] == 'x' || str[1] == 'X')){
            retVal = 0;
            local bitShift = 0
            local tempVal;
            for(local i=str.len()-1; i >= 2 ; i--){
                switch(str[i]){
                    case 'a':
                    case 'A':
                        tempVal = 10;
                        break;
                    case 'b':
                    case 'B':
                        tempVal = 11;
                        break;
                    case 'c':
                    case 'C':
                        tempVal = 12;
                        break;
                    case 'd':
                    case 'D':
                        tempVal = 13;
                        break;
                    case 'e':
                    case 'E':
                        tempVal = 14;
                        break;
                    case 'f':
                    case 'F':
                        tempVal = 15;
                        break;
                    case '0':
                    case '1':
                    case '2':
                    case '3':
                    case '4':
                    case '5':
                    case '6':
                    case '7':
                    case '8':
                    case '9':
                        tempVal = str[i].tointeger() - 48;
                        break;
                    default:
                        server.log("ERROR - INVALID HEX STRING")
                        return;                     
                }
                retVal += tempVal << 4*bitShift++
            }
            return retVal;
        } else {
            return str.tointeger();
        }
    } catch(ex){
        retVal = null;
        server.log(ex);
    }  
}

function TimeStamp(arg = null){    //Time Format for Xively = "2010-01-10T23:22:12Z"
    local currentTime = null;
    local timeStr = null;
    
    if(arg == null) {
        currentTime = date();
        //currentTime = date(time(), 'u');  //TODO: BUG: EI BUG: this doesn't give usecs for some reason...
    }
    else {
        currentTime = date(arg, 'u');
    }
    if("usec" in currentTime)
        timeStr = format("%.4d-%.2d-%.2dT%.2d:%.2d:%.2d.%.6dZ", currentTime.year, currentTime.month+1, currentTime.day,  currentTime.hour, currentTime.min, currentTime.sec, currentTime.usec);
    else
        timeStr = format("%.4d-%.2d-%.2dT%.2d:%.2d:%.2dZ", currentTime.year, currentTime.month+1, currentTime.day,  currentTime.hour, currentTime.min, currentTime.sec);
    return  timeStr
}

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
/**  --------------------------------- END HELPER FUNCTIONS --------------------------------------- **/    

/*******************************************************************************
    HTTP IN CODE
*******************************************************************************/
Requests <- {}; //Index = [httpRequest, httpResponse]   //TODO: A better (performance) approach may be Requests <- { [RequestType] = [ [request, response], [request2, response2] ] }
LongPollListeners <- {};    //Index = httpResponse
RequestID <- 0;

function responseTimeout(index){
    if(index in Requests){
        local req = Requests[index][0];
        local res = Requests[index][1];
        htmlResponse(GATEWAY_TIMEOUT_HTML_TITLE, GATEWAY_TIMEOUT_HTML_BODY, 504)
        foreach(headerKey, headerVal in PostHeaders){
    		res.header(headerKey, headerVal)
		}
        res.send(resCode, resStr);
        delete Requests[index];
        
        server.log(format("RequestID %d Timedout.  Request was a %s to %s%s with params %s", index, req.method, http.agenturl(), req.path, http.jsonencode(req.query)))
    }
}

function sendResponse(reqID, out_message){
        reqID = reqID.tointeger()
        if(reqID in Requests){
            local req = Requests[reqID][0]
            local res = Requests[reqID][1]
    		foreach(headerKey, headerVal in PostHeaders){
				res.header(headerKey, headerVal)
			}
			res.send(200, out_message)
            server.log("Sending Response for Request " + reqID)
			//server.log("Sending Response for RequestID="+ reqID+ " with Method=\"" + req.method + "\" to path=\""http.agenturl()+req.path+"\" with parameters="+ http.jsonencode(req.query))
			delete Requests[reqID];
        }
}

function htmlResponse(title, body, code){
    resStr = HTML_PREAMBLE1 + title + HTML_PREAMBLE2 + HTML_BODY1 + body + HTML_BODY2;
    resCode = code;
}

function htmlForbidden(authLevel, requiredLevel){
     htmlResponse(FORBIDDEN_HTML_TITLE, FORBIDDEN_HTML_BODY + "\r\n\t<p align=\"left\">Current Authorization Level = " + authLevel + ". Required Authorization Level = "+ requiredLevel + "</p>", 403)
}

function htmlUnauthorized(authLevel, requiredLevel){
    htmlResponse(FORBIDDEN_HTML_TITLE, FORBIDDEN_HTML_BODY + "\r\n\t<p align=\"left\">Current Authorization Level = " + authLevel + ". Required Authorization Level = "+ requiredLevel + "</p>", 401)
}

function htmlBadRequest(reason){
    htmlResponse(BAD_REQUEST_HTML_TITLE, BAD_REQUEST_HTML_BODY + "\r\n\t<p align=\"left\">Reason: "+reason+"</p>", 400)
}

function sendHTTPRedirect(res, location) {
    res.header("Location", location);
    res.send(303, "");
    server.log("Sending Redirect for Request " + RequestID)
}

//Authentication and Authorization helpers
function basicAuthStr(username, password){
    local str = username + ":" + password;
    return "Basic " + http.base64encode(str);   
}

function basicAuthSplit(str){
    local sp = split(str, " ");
    return split(http.base64decode(sp[1]).tostring(), ":")
}

function basicAuthPassword(str){    //TODO: These only work when the user and password have both been set
    local sp = basicAuthSplit(str)
    if(sp.len() == 2)
        return sp[1]
    else
        return "__UNKNOWN__"
}

function basicAuthUser(str){
    local sp = basicAuthSplit(str)
    if(sp.len() == 2)
        return sp[0]
    else
        return "__UNKNOWN__"
}

function checkAuthentication(authLevel, NeededLevel, setHTMLUnauthorized=true){
    if(authLevel >= NeededLevel){
        return true
    } else if(setHTMLUnauthorized) {
        htmlUnauthorized(authLevel, NeededLevel)
    }
    return false
}

//These are global so the helper functions can set them
//TODO: Properly scope these variables and pass them appropriately?
resStr <- "";
resCode <- null;

http.onrequest(function(request,res){
    resStr = "";
    resCode = null;
    local authLevel = 0;
    //TODO: Need to implement HTTP Code 400 Bad Request
    
    try{
        if("authorization" in request.headers){
            //server.log("Proccesing Message from user="+basicAuthUser(request.headers.authorization)+" with password="+basicAuthPassword(request.headers.authorization))
            if(request.headers.authorization in AUTHORIZATION_LEVELS){
                authLevel = AUTHORIZATION_LEVELS[request.headers.authorization]
                server.log("User = "+basicAuthUser(request.headers.authorization)+" Granted Authorization Level "+authLevel)
            }
        }
        
        checkAuthentication(authLevel, 0)
    
        //Get everything into the request.query table if it's an encoding in the body we understand
        if("content-type" in request.headers){  
            if(request.headers["content-type"].find("application/x-www-form-urlencoded") != null){
                local bodyURLencodedVars = http.urldecode(request.body);
                request.body = ""
                foreach(key, val in bodyURLencodedVars){
                    if(key in request.query && request.query[key] != val){
                        server.log("Duplicate Key found in URL Encoded Body and Request Query.  NOT overriding Query Val="+request.query[key]+" with Body Val="+val)
                    } else{
                        request.query[key] <- val;
                    }
                }
            } else if(request.headers["content-type"].find("application/json") != null){
                local bodyJSONVars = http.jsondecode(request.body);
                request.body = "";
                foreach(key, val in bodyJSONVars){
                    if(key in request.query && request.query[key] != val){
                        server.log("Duplicate Key found in JSON Encoded Body and Request Query.  NOT overriding Query Val="+request.query[key]+" with JSON Val="+val)
                    } else{
                        request.query[key] <- val;
                    }
                }
            }
        }
        
        //Log Request
        local logstr = "Request " + ++RequestID + " - AGENT RECEIVED HTTP " + request.method + " REQUEST - " + request.path;
        if(request.query.len() != 0) logstr += "?" + http.jsonencode(request.query)
        //foreach(key,val in request.headers){logstr += "\r\n" + key + ": " + val}
        if(request.body.len() > 0) logstr += "\r\n\r\n" + request.body
        server.log(logstr)
	
    
        if(request.method == "OPTIONS"){
            foreach(headerKey, headerVal in PostHeaders){
        		res.header(headerKey, headerVal)
    		}
    		res.send(200, "");
            server.log("Sending Response for Request " + RequestID)
            return;
        }
        
        //Handle Naked Requests -This could be used to send to your own webserver
        if(request.path == "/" || request.path == ""){
            sendHTTPRedirect(res, DEVICE_WEBHOST);  
            return;
        }
    
        if (request.path == "/xively") Xively.HttpHandler(request, resp);
        
		if(device.isconnected() == false){	//All methods under this if tree need to talk to the device
    	    htmlResponse(SERVICE_UNAVAILABLE_HTML_TITLE, SERVICE_UNAVAILABLE_HTML_BODY, 503)
        } else if(request.path == "/LongPoll"){
            LongPollListeners[RequestID] <- res;
            local id = RequestID;	//Will remain in scope for the lambda callback function passed to imp.wakeup and gets around the "bad callback for imp.wakeup: must take 0 parameters" error
            imp.wakeup(59.9, function(){
                if(id in LongPollListeners){
                    server.log("Removing LongPoll RequestID " + id);
                    local res = LongPollListeners[id];
                    foreach(headerKey, headerVal in PostHeaders){
            			res.header(headerKey, headerVal)
        			}
                    htmlResponse(REQUEST_TIMEOUT_HTML_TITLE, REQUEST_TIMEOUT_HTML_BODY, 408);
        			res.send(resCode, resStr);
                    delete LongPollListeners[id];
                } 
            })
        } 
        else if (request.path == "/Device"){
			if(request.query.Method == "GetRunningStatistics"){   //https://agent.electricimp.com/zYM6X7NeUQWG/EVSE?Method=Enable
                 Requests[RequestID] <- [request, res]
    		    device.send("GET_RUNNING_STATISTICS", RequestID);
			} else if(request.query.Method == "GetUIData"){
    		    Requests[RequestID] <- [request, res]
                device.send("GetUIData", RequestID);
			}

		} else if(request.path == "/LED"){
    	    
		}
        
        if(resStr == "" && resCode == null){
            htmlResponse(NOT_IMPLEMENTED_HTML_TITLE, format("%s\r\n\t<p align=\"left\">%s</p>\r\n\t<p align=\"left\">%s</p>\r\n\t<p align=\"left\">%s</p>\r\n\t<p align=\"left\">%s</p>", NOT_IMPLEMENTED_HTML_BODY, "Message Path: " + request.path, "Message Headers: " + http.jsonencode(request.headers), "Message Parameters: " + http.urlencode(request.query), "Message Body: " + request.body), 501 )

        }
		
	}
	catch(ex) {
		server.log(ex)
        if(RequestID in Requests && Requests[RequestID][0] == request){  //Remove the request from the queue if it exists
            delete Requests[RequestID]
        }
        htmlResponse(INTERNAL_SERVER_ERROR_HTML_TITLE, format("%s\r\n\t<p align=\"left\">%s</p>\r\n\t<p align=\"left\">%s</p>\r\n\t<p align=\"left\">%s</p>\r\n\t<p align=\"left\">%s</p>\r\n\t<p align=\"left\">%s</p>", INTERNAL_SERVER_ERROR_HTML_BODY, "Received Exception = " + ex, "Message Path: " + request.path, "Message Headers: " + http.jsonencode(request.headers), "Message Parameters: " + http.urlencode(request.query), "Message Body: " + request.body), 500 )
	}
    
    if(!(RequestID in Requests) && !(RequestID in LongPollListeners)){
        if(resCode == null){
			res.send(200, resStr);
		} else {
			res.send(resCode, resStr);
		}
        server.log("Sending Response for Request " + RequestID)
	} else {
        imp.wakeup(9.0, function(){responseTimeout(RequestID)});   
	}
});

/**  ------------------------- END HTTP IN CODE --------------------------- **/

/*******************************************************************************
    SERVER HANDLER CODE
*******************************************************************************/
server.onshutdown(function(r){
   
    if(r == SHUTDOWN_NEWSQURREL)
        r = "Shutdown requested - New Squirrel is available (ex: Depolyment)";    
    else if(r == SHUTDOWN_NEWFIRMWARE){
        r = "Shutdown requested - New imp firmware or a newer agent-server is available";    
        //TODO: Close all open connections (eg: longpolling)
    }
    else if(r == SHUTDOWN_OTHER)
        r = "Shutdown requested";    
    
    server.log(r);
    server.restart();
});
/**  ------------------------- END SERVER HANDLER CODE --------------------------- **/

/*******************************************************************************
    DEVICE HANDLER CODE
*******************************************************************************/
DeviceVariables <- {onBoot = true, onUIRequest = false, impeeID = "UNKNOWN", MACaddr = "UNKNOWN"};

//Headers to set for each outgoing message
PostHeaders <- {
    Referer = http.agenturl(),
    ["Content-Type"] = "application/json",
    ["Access-Control-Allow-Origin"] = "*",  //Need to do some more learning about CORS - which of these are required, for what requests (OPTIONS vs. GET), etc  //http://techoctave.com/c7/posts/60-simple-long-polling-example-with-javascript-and-jquery and //http://www.html5rocks.com/en/tutorials/cors/#toc-end-to-end-example
    ["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE",
    ["Access-Control-Allow-Headers"] = "Authorization, Content-Type, x-requested-with", //Not all of these are required by all browsers/versions of CORS but they don't hurt either
    //"Access-Control-Allow-Credentials": "true",
    "Access-Control-Max-Age": "2592000",//30 Days, //Max allowed Value = "2147483648" or 68 years
};

//Servers to POST to whenever an event happens
PostServers <- [
    
];


Message_ID <- 0;    //TODO: Get Permanent Value

device.onconnect(function(){
    server.log("Device Connected Received in Agent");
})

device.ondisconnect(function(){
    server.log("Device Disconnected Received in Agent");
})

/*device.onconnectionstatus(function(status){
	if(status == STATUS_OFFLINE){
		server.log("device has lost connection with the server");
	} else if(status == STATUS_SLEEPING) {
		server.log("device has told the server it is going to sleep for a period, and is not contactable");
	} else if(status == STATUS_ONLINE) {
		server.log("device has connected");
	}
});*/

function updateDeviceVariables(msg){
    server.log("----------Received Device Variables----------------");
    foreach(key,val in msg){
        local logVal = val
        if(typeof val == "table" || typeof val == "array")
            logVal = http.jsonencode(logVal);
            
        /*if(key == "wakeReason"){  //TODO: EI BUG: constants are not available in the agent
            if(val == WAKEREASON_POWER_ON)
                logVal = "Powered on cold boot";
            else if(val == WAKEREASON_SW_RESET)
                logVal = "Restarted due to a software reset";
            else if(val == WAKEREASON_TIMER)
                logVal = "Woken up after sleep time expired";
            else if(val == WAKEREASON_PIN1)
                logVal = "Woken up due to wakeup pin being active";
            else if(val == WAKEREASON_NEW_SQUIRREL)
                logVal = "Restarted due to new squirrel code being loaded";
        }*/
                
        
        server.log("["+key+"] = "+ logVal);
        DeviceVariables[key] <- val;
    }
    server.log("---------------------------------------------------");
    
    if("onBoot" in msg && "bootNumber" in msg){
        //sendMailGun("", "Imp Boot #" + msg.bootNumber , "Imp Boot " + msg.bootNumber + " occurred at " + TimeStamp(msg.bootTime) + " for impeeID="+msg.impeeID)
    } 
}

function SendRunningStatisticsResponse(msg) {
    local requestID = msg[1];
    msg = msg[0];
    updateDeviceVariables(msg);
    DeviceVariables.onUIRequest = true;
    sendResponse(requestID, http.jsonencode({Message_Type="Device.GetRunningStatistics", data=msg}))
}

function SendUIDataResponse(msg){
    local requestID = msg[1];
    msg = msg[0];
    //server.log("Sending Data to UI - " + http.jsonencode(msg))
    DeviceVariables.onUIRequest = true;
    sendResponse(requestID, http.jsonencode({Message_Type="Device.GetUIData", data=msg}))
}

function SendDataToXively(data){ 
    local timestamp = TimeStamp();
    local sendVal = {
        "version":"1.0.0",
        "datastreams" : [
            {
                "id": "AgentFreeMemory",
                "datapoints":[{"at":timestamp,"value":imp.getmemoryfree()}],
            },
        ]
    }
    foreach(key, val in data){
        sendVal.datastreams.push({
            "id":key,
            "datapoints":[{"at":timestamp,"value":val}],   //If events happen quickly (like button presses) Xively may receive out of order so we include the timestamp here - but this doesn't work because Xively only takes timestamps down to the second...
        })
    }

    send_xively(XIVELY_FEED_ID, XIVELY_API_KEY, http.jsonencode(sendVal)); 
}

function SendDataToLongPollListeners(data){
    foreach(reqID, res in LongPollListeners) {
        foreach(headerKey, headerVal in PostHeaders){
			res.header(headerKey, headerVal)
		}
        server.log("Sending LongPoll Response for Request " + reqID)
		res.send(200, data);
    }
    LongPollListeners <- {};
}

//TODO: Need to implement something similair for the Pot, Accelerometer, Temp Sensor, etc.
function ButtonPress(data){
    SendDataToLongPollListeners(http.jsonencode(data))
}

    

//Register all Device Handlers
device.on("Device_Variables", updateDeviceVariables)
device.on("GET_RUNNING_STATISTICS", SendRunningStatisticsResponse)
device.on("LogSqObj", logObject);
device.on("GET_UI_DATA", SendUIDataResponse);
device.on("Send_Xively", SendDataToXively);
device.on("ButtonPress", ButtonPress);

/**  ---------------------- END DEVICE HANDLER CODE ------------------------ **/


/*******************************************************************************
    HTTP OUT CODE
*******************************************************************************/

function Twilio_send_sms(toNumber, message) {   //TODO: This could be a class that implements all of Twilio's capabilities and can be instantiated with different phone numbers/account numbers/etc. instead of constants
    local twilio_url = format("https://api.twilio.com/2010-04-01/Accounts/%s/SMS/Messages.json", TWILIO_ACCOUNT_SID);
    local auth = basicAuthStr(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
    local body = http.urlencode({From=TWILIO_FROM_NUMBER, To=toNumber, Body=message});
    local req = http.post(twilio_url, {Authorization=auth}, body);
    req.sendasync(function(response){
        if(response.statuscode != 200){
            server.log("Twilio Send_SMS StatusCode " + response.statuscode);
            server.log(response.body);
        }
    });
}

function sendBoxCar(emailAddr, message){
    local response = http.post("https://boxcar.io/devices/providers/"+BOXCAR_PROVIDER_KEY+"/notifications", {}, "email="+emailAddr+"&notification[from_screen_name]=Imp Agent" + "&notification[message]="+message + "&notification[source_url]=http://www.electricimp.com" + "&notification[icon_url]=http://a1441.phobos.apple.com/us/r1000/062/Purple/v4/68/05/82/680582f6-ee6e-b939-7c64-fe8d2e6c3f59/iphone_logo.png").sendasync(function(response){
        if(response.statuscode != 200){
            server.log("sendBoxCar StatusCode " + response.statuscode);
            server.log(response.body);
        }
    });
}

function sendMailGun(toEmail, subject, message){
    http.post(format("https://api.mailgun.net/v2/%s/messages", MAILGUN_DOMAIN), 
    {Authorization = basicAuthStr("api", MAILGUN_AUTH_TOKEN)},
    http.urlencode({from = "Hannah imp <hannahimp@impdemo.mailgun.org>", to = toEmail, subject = subject, text = message})
    ).sendasync(function(response){
        if(response.statuscode != 200){
            server.log("MAILGUN StatusCode " + response.statuscode);
            server.log(response.body);
        }
    });
}
    
    
/*******************************************************************************
    XIVELY CLASS
*******************************************************************************/
/* Code take from beardedinventor at https://github.com/beardedinventor/electricimp/tree/master/Xively under the MIT License (MIT)
Copyright (c) 2013 electric imp, inc
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
// This is a way to make a "namespace"
Xively <- {
    FEED_ID = "FEED_ID" // Replace with your Feed ID
    API_KEY = "API_KEY" // Replace with your API Key
    triggers = []
}

/*****************************************
 * method: PUT
 * IN:
 * feed: a XivelyFeed we are pushing to
 * ApiKey: Your Xively API Key
 * OUT:
 * HttpResponse object from Xively
 * 200 and no body is success
 *****************************************/
function Xively::Put(feed, ApiKey = Xively.API_KEY){
    if (ApiKey == null) ApiKey = Xively.API_KEY;
    local url = "https://api.xively.com/v2/feeds/" + feed.FeedID + ".json";
    local headers = { "X-ApiKey" : ApiKey, "Content-Type":"application/json", "User-Agent" : "Xively-Imp-Lib/1.0" };
    local request = http.put(url, headers, feed.ToJson());

    return request.sendsync();
}
    
/*****************************************
 * method: GET
 * IN:
 * feed: a XivelyFeed we fulling from
 * ApiKey: Your Xively API Key
 * OUT:
 * An updated XivelyFeed object on success
 * null on failure
 *****************************************/
function Xively::Get(feed, ApiKey = Xively.API_KEY){
    local url = "https://api.xively.com/v2/feeds/" + feed.FeedID + ".json";
    local headers = { "X-ApiKey" : ApiKey, "User-Agent" : "xively-Imp-Lib/1.0" };
    local request = http.get(url, headers);
    local response = request.sendsync();
    if(response.statuscode != 200) {
        server.log("error sending message: " + response.body);
        return null;
    }
    
    local channel = http.jsondecode(response.body);
    for (local i = 0; i < channel.datastreams.len(); i++)
    {
        for (local j = 0; j < feed.Channels.len(); j++)
        {
            if (channel.datastreams[i].id == feed.Channels[j].id)
            {
                feed.Channels[j].current_value = channel.datastreams[i].current_value;
                break;
            }
        }
    }
    
    return feed;
}

class Xively.Feed{
    FeedID = null;
    Channels = null;
    
    constructor(feedID, channels)
    {
        this.FeedID = feedID;
        this.Channels = channels;
    }
    
    function GetFeedID() { return FeedID; }

    function ToJson()
    {
        local json = "{ \"datastreams\": [";
        for (local i = 0; i < this.Channels.len(); i++)
        {
            json += this.Channels[i].ToJson();
            if (i < this.Channels.len() - 1) json += ",";
        }
        json += "] }";
        return json;
    }
}
class Xively.Channel{
    id = null;
    current_value = null;
    
    constructor(_id)
    {
        this.id = _id;
    }
    
    function Set(value) { this.current_value = value; }
    
    function Get() { return this.current_value; }
    
    function ToJson() { return "{ \"id\" : \"" + this.id + "\", \"current_value\" : \"" + this.current_value + "\" }"; }
}

device.on("XivelyFeed", function(data) {
    local channels = [];
    for(local i = 0; i < data.Datastreams.len(); i++)
    {
        local channel = Xively.Channel(data.Datastreams[i].id);
        channel.Set(data.Datastreams[i].current_value);
        channels.push(channel);
    }
    local feed = Xively.Feed(data.FeedID, channels);
    local resp = Xively.Put(feed, Xively.API_KEY);
    server.log("Send data to Xively (FeedID: " + feed.FeedID + ") - " + resp.statuscode + " " + resp.body);
});
function Xively::On(feedID, streamID, callback) {
    if (Xively.triggers == null) Xively.triggers = [];
    // Make sure the trigger doesn't already exist
    for(local i = 0; i < triggers.len(); i++) {
        if (Xively.triggers.FeedID == feedID && Xively.triggers.StreamID = streamID)
        {
            server.log("ERROR: A trigger already exists for " + feedID + " : " + streamID);
            return;
        }
    }
    Xively.triggers.push({ FeedID = feedID, StreamID = streamID, Callback = callback });
}
function Xively::HttpHandler(request,res) {
    local responseTable = http.urldecode(request.body);
    local parsedTable = http.jsondecode(responseTable.body);
    res.send(200, "okay");
    
    local trigger = {
        FeedID = parsedTable.environment.id,
        FeedName = parsedTable.environment.title,
        StreamID = parsedTable.triggering_datastream.id,
        ThresholdValue = parsedTable.threshold_value,
        CurrentValue = parsedTable.triggering_datastream.value.value,
        TriggeredAt = parsedTable.timestamp,
        Debug = false
};
    if ("debug" in parsedTable) {
     trigger.Debug = true;
        server.log(trigger.FeedID + "(" + trigger.StreamID + ") triggered at " + trigger.TriggeredAt + ": " + trigger.CurrentValue + " / " + trigger.ThresholdValue);
    }
    
    local callback = null;
    for (local i = 0; i < Xively.triggers.len(); i++)
    {
        if (Xively.triggers[i].FeedID = trigger.FeedID && Xively.triggers[i].StreamID == trigger.StreamID)
        {
            callback = Xively.triggers[i].Callback;
            break;
        }
    }
    if (callback == null){
        server.log("Unknown trigger from Xively - to create a callback for this trigger add the following line to your agent code:");
        server.log("Xively.On(\"" + trigger.FeedID + "\", \"" + trigger.StreamID + "\", triggerCallback);");
        return;
    }
    callback(trigger);
}

/**  ------------------------- END XIVELY CLASS --------------------------- **/

//TODO: REMOVE LEGACY CODE HERE
function send_xively(feed_id, api_key, body) {  //feed_id and api_key are strings, body should be http.jsonencode()'ed first
    if(api_key == "") return
    local xively_url = "https://api.xively.com/v2/feeds/" + feed_id + ".json";
    local request = http.put(xively_url, {"X-ApiKey":api_key, "Content-Type":"application/json", "User-Agent":"Electric Imp Agent"}, body); //add headers
    local resp = request.sendasync(function(resp){
        if(resp.statuscode != 200) {
            /*
            Code    Meaning                 Action Required
            200 	OK 	Request             processed successfully.
            400 	Bad Request 	        Something is wrong with your headers or body formatting. Check your request against examples.
            401 	Not Authorized 	        Either you need to provide authentication credentials, or the credentials provided aren�t valid. Check your API key.
            403 	Forbidden 	            Xively understands your request, but refuses to fulfil it. An accompanying error message should explain why.(NOTE: in the V2 API, this is the error returned when the API rate limit is exceeded.)
            404 	Not Found 	            Either you�re requesting an invalid URI or the resource in question doesn�t exist (eg. no such feed). Check your HTTP method. See below.
            406 	Not Acceptable 	        You have most likely specified the wrong document type. Try JSON by using .json at the end of your URL.
            422 	Unprocessable Entity 	Xively was unable to create a feed because the EEML/JSON was not complete/valid (e.g. it didn�t include a �title� element). Check your body against examples.
            500 	Internal Server Error 	Something went wrong� Please post to the forum about it and we will investigate.
            503 	No server error 	    Usually occurs when there are too many requests coming into Xively - if you get this from an API request then the error message will be returned in XML in the response.
            */
            server.log(resp.statuscode + " Error sending message to Xively: "+resp.body);
        } else {
            //ret = "200 OK";
        }
    }); //send request
}
/**  ---------------------- END HTTP OUT CODE ------------------------ **/
/**  ------------------------- EOF --------------------------- **/
