using Toybox.System;
using Toybox.Background;
using Toybox.Communications;
using Toybox.Position;
using Toybox.Application;
import Toybox.Lang;
using Toybox.Time;

(:background)
class BAS_ServiceDelegate extends Toybox.System.ServiceDelegate {

		const minimumInterval = 5 * 60;
			
		function initialize() {
	  		ServiceDelegate.initialize();
	  	}

	function onTemporalEvent() {
    	// var now=Toybox.System.getClockTime();	
        // var ts=now.hour+":"+now.min.format("%02d");    
    	// System.println("onTemporalEvent: "+ts);
    	requestCurrentWeather();	
	}
	
	function requestCurrentWeather() {
		var position = Position.getInfo();
		if (position != null) {
			var coords = position.position;
			if (coords != null) { // && position.accuracy > Position.QUALITY_POOR
				System.println("Coordinates: " + coords.toGeoString(Position.GEO_DM) + " Accuracy: " + position.accuracy);
				var positionInDegrees = coords.toDegrees();
				if (positionInDegrees != null) {
					System.println("Latitude " + positionInDegrees[0] + " longitude " + positionInDegrees[1]);
					makeRequest(positionInDegrees[0], positionInDegrees[1]);
				}
			} else {
				System.println("Null position field or poor accuracy; accuracy is " + position.accuracy);
			}
		} else {
			System.println("Null position at " + Toybox.System.getClockTime());
		}
	}
	
   // set up the response callback function
   function onReceive(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
       var aqi = null;
       var interval = null;
       if (responseCode == 200) {
           System.println("Request Successful " + data);
           if (data.isEmpty()) {
        	   interval = minimumInterval;
    	   }	           	
           aqi = data;
       }
       else if (responseCode == 429) {
	       System.println("Rate limited, wait forty minutes");
           aqi = { "error" => responseCode, "hideError" => true };
           if (data != null && !data.isEmpty()) {  
           	 System.println(data.keys());
           	 if (data.hasKey("retryAfter")) {
           	 	interval = data.get("retryAfter");
       	 	 } else {
       	 	 	interval = 60 * 40;
   	 	 	 }
           } else {
       	   	  interval = 60 * 40;
       	   }
       }
       else {
           System.println("Response: " + responseCode + " data " + data);
           aqi = { "error" => responseCode };
           interval = minimumInterval;
       }
	   Background.registerForTemporalEvent(new Time.Duration(interval));       
       Background.exit(aqi);
   }

    function makeRequest(latitude, longitude) {
        var urlBase = "https://bigapi.ru/";
        var email = Application.Properties.getValue("email");
        if (email == null || email == "--") {
            email = "";
        }
        var params = {
            "lat" => latitude,
            "lon" => longitude,
            "device" => System.getDeviceSettings().partNumber,
            "deviceId" => System.getDeviceSettings().uniqueIdentifier,
            "email" => email
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(urlBase + "sputnik", params, options, method(:onReceive));
  }      
  
}
