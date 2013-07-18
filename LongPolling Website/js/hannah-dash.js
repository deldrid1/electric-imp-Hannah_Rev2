function updateHannahDash(data){
	var elementIDs = [
		"Button1",
		"Button2",
		"HallSwitch"
	]
	
	for (var i=0; i< elementIDs.length; i++) {
		var elementID = elementIDs[i]
		if(data.hasOwnProperty(elementID)) {
			if(data[elementID] === 0){
				$("#"+elementID).children('.Off').addClass('active');
				$("#"+elementID).children('.On').removeClass('active');
			} else {
				$("#"+elementID).children('.On').addClass('active');
				$("#"+elementID).children('.Off').removeClass('active');
			}
			
			//$("#"+elementID).children('.On.Off').spin(false);
		}
	}

}
	
$( document ).ready(function() {  

	$('#lostCommunication').hide();
	
	$('#LED').colorpicker({
                format: 'hex'
    });
	
	$('#LED').click(function(e){
            e.preventDefault();
    });
	
	$('.colorpicker').colorpicker().on('changeColor', function(ev){
		bodyStyle.backgroundColor = ev.color.toHex();
	});

	var spinnerOpts = {
	  lines: 10, // The number of lines to draw
	  length: 4, // The length of each line
	  width: 8, // The line thickness
	  radius: 2, // The radius of the inner circle
	  corners: 1, // Corner roundness (0..1)
	  rotate: 0, // The rotation offset
	  direction: 1, // 1: clockwise, -1: counterclockwise
	  color: '#FFF', // #rgb or #rrggbb
	  speed: 1, // Rounds per second
	  trail: 64, // Afterglow percentage
	  shadow: false, // Whether to render a shadow
	  hwaccel: false, // Whether to use hardware acceleration
	  className: 'spinner', // The CSS class to assign to the spinner
	  zIndex: 2e9, // The z-index (defaults to 2000000000)
	  top: 'auto', // Top position relative to parent in px
	  left: 'auto' // Left position relative to parent in px
	};
	
	$('.btn.On').on('click', function(e) {
		e.preventDefault();
		var $this = $(this);
		console.log("On Button Clicked");
		$this.siblings().spin(false);
		$this.spin(spinnerOpts);
	});
	
	$('.btn.Off').on('click', function(e) {
		e.preventDefault();
		var $this = $(this);
		console.log("Off Button Clicked");
		console.log($this.siblings());
		$this.siblings().spin(false);
		$this.spin(spinnerOpts);
	});
});