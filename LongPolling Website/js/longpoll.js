  function make_base_auth(user, password) {
	var tok = user + ':' + password;
	var hashStr = btoa(tok);
	return "Basic " + hashStr;
}
	
//CONSTANTS 	//TODO: These should be a field to be entered on the website...
var agentBaseURL ="https://agent.electricimp.com/YOUR_AGENT_ID_HERE";
var basicAuthStr = make_base_auth("HannahImp", "electricImp123");
	
// Make sure the document is ready to be handled  
$( document ).ready(function() {  

	/**
	 * Protect window.console method calls, e.g. console is not defined on IE
	 * unless dev tools are open, and IE doesn't define console.debug
	 */
	(function() {
	  if (!window.console) {
		window.console = {};
	  }
	  // union of Chrome, FF, IE, and Safari console methods
	  var m = [
		"log", "info", "warn", "error", "debug", "trace", "dir", "group",
		"groupCollapsed", "groupEnd", "time", "timeEnd", "profile", "profileEnd",
		"dirxml", "assert", "count", "markTimeline", "timeStamp", "clear"
	  ];
	  // define undefined methods as noops to prevent errors
	  for (var i = 0; i < m.length; i++) {
		if (!window.console[m[i]]) {
		  window.console[m[i]] = function() {};
		}    
	  } 
	})();
	

	function ajaxError(xhr, status, errThrown) {
		if(xhr.status == 0){
			return;
		}
		ErrorCount++
		console.log("Ajax " + status + " Error - " + ErrorCount);
	}

	//Uses Closure to get the Running Statistics when the page first loads
	(function getRunningStatistics(){
		$.ajax({ 
			url: agentBaseURL + "/Device", 
			method: 'GET',
			data: {
				"Method": "GetRunningStatistics"
			},
			timeout: 10000,
			dataType: "json", 
			xhrFields: {
				withCredentials: false
			},
			headers: {
				'Authorization': basicAuthStr
			},
			success: function(message, status, xhr){
				if(xhr.status != 200){
					ErrorCount++
					return;
				}
				ErrorCount = 0;
				console.log("Device Running Statistics:")
				console.log(message);
			}, 
			error: ajaxError,
		});
	})();
	
	var ErrorCount = 0;
	(function poll(){
		//We send two requests with every poll - One to get/sync the current state and another to setup a longpoll request for any push updates
		//A good Long polling example is at http://techoctave.com/c7/posts/60-simple-long-polling-example-with-javascript-and-jquery
		if(ErrorCount >= 3){
			ErrorCount = 0;
			console.log("Resetting Error Count and Delaying next Poll Call for 5 seconds");
			setTimeout(poll, 5000);
			return;
		}
		
		$.ajax({ 
			url: agentBaseURL + "/Device", 
			method: 'GET',
			data: {
				"Method": "GetUIData"
			},
			timeout: 10000,
			dataType: "json", 
			xhrFields: {
				withCredentials: false
			},
			headers: {
				'Authorization': basicAuthStr
			},
			success: function(message, status, xhr){
				if(xhr.status != 200){
					ErrorCount++
					return;
				}
				ErrorCount = 0;	//Only want successive Errors to count as strikes
				console.log(message);
				$('#mainText').css('background-color', 'rgb('+message.data['LED-R']+','+message.data['LED-G']+','+message.data['LED-B']+')');
				updateHannahDash(message.data);
			}, 
			error: ajaxError,
		});
		
		$.ajax({ 
			url: agentBaseURL + "/LongPoll", 
			method: 'GET',
			data: {},
			timeout: 60000,
			dataType: "json", 
			xhrFields: {
				withCredentials: false
			},
			headers: {
				'Authorization': basicAuthStr
			},
			success: function(message, status, xhr){
				if(xhr.status != 200){
					ErrorCount++
					return;
				}
				ErrorCount = 0;
				console.log("Received Longpoll Data");
				console.log(message);
				updateHannahDash(message);
			}, 
			error: ajaxError,
			complete: poll, 
		});
		
	})();
});  
