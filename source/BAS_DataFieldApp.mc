using Toybox.Application;
using Toybox.System;
using Toybox.Time;
using Toybox.Background;
using Toybox.WatchUi;
using Toybox.FitContributor;
import Toybox.Lang;
using Toybox.Position;

var weatherData = null;
var aqiField = null;
var temperatureField = null;
var temperatureValue = null;
var humidityField = null;
var humidityValue = null;
var pressureField = null;
var pressureValue = null;
var stationField = null;
var stationValue = null;
const intervalKey = "refreshInterval";

(:background)
class BAS_DataFieldApp extends Application.AppBase {

	const myKey = "weatherData";
	const pm2_5 = "PM2.5";
	const enableNotificationsKey = "enableNotifications";
	var enableNotifications = false;
	var inBackground = false;
//	var aqiProvider = 1;
	var fieldIsDirty = true;
			
	function readKeyBool(myApp,key,thisDefault) {
	    var value = myApp.getProperty(key);
	    if(value == null || !(value instanceof Boolean)) {
	        if(value != null) {
	            value = value == "true";
	        } else {
	            value = thisDefault;
	        }
	    }
	    return value;
	}
	
	function readKeyInt(myApp,key,thisDefault) {
	    var value = myApp.getProperty(key);
		if (value == null) {
			return thisDefault;
		}
	    if (!(value instanceof Number)) {
			return value.toNumber();
	    }
	    return value;
	}
					
    function initialize() {
        AppBase.initialize();
        // read what's in storage
//        if (Application has :Storage) {
//	        weatherData = Application.Storage.getValue(myKey);
//	        if (Application has :Properties) {
//	        	enableNotifications = readKeyBool(getApp(), enableNotificationsKey, false);
//		        aqiProvider = readKeyInt(getApp(), "aqiProvider", 1);
//	        }
//        }
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    	if(!inBackground) {
    		Background.deleteTemporalEvent();
    	}
    }

    //! Return the initial view of your application here
    function getInitialView() {
    	var view;
    	
		//register for temporal events if they are supported
    	if(Toybox.System has :ServiceDelegate) {
     		Background.registerForTemporalEvent(new Time.Duration(Application.Properties.getValue(intervalKey)));
    	} else {
    		System.println("****background not available on this device****");
    	}
    	view = new BAS_DataFieldView(enableNotifications);
        return [ view, new TouchDelegate(view) ];
    }
    
    function getServiceDelegate(){
    	//only called in the background	
    	inBackground = true;
        return [new BAS_ServiceDelegate()];
    }
    
    function onBackgroundData(data_raw as Application.PersistableType) {
    	var now=System.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");
        System.println("onBackgroundData=" + data_raw + " at " + ts);
        if (data_raw != null) {
			var data = data_raw as Lang.Dictionary;

            temperatureValue = data.get("temperature");
            humidityValue = data.get("humidity");
            pressureValue = data.get("pressure");
            stationValue = data.get("station");

            weatherData = data;

//			if (data.hasKey("Temperature")) {
//				temperatureValue = data.get("Temperature");
//				weatherData = data;
//				if (temperatureField != null && temperatureValue != null && temperatureValue instanceof Toybox.Lang.Number) {
//					temperatureField.setData(temperatureValue);
//				}
//  //  		} else if (data.hasKey("error")) {
//    			if (Application.Properties.getValue("zerosForNoData") && aqiField != null) {
//    				aqiField.setData(0);
//    				fieldIsDirty = true;
//    				System.println("Recording zero for error fetching BAS");
//    			}
//    			if (weatherData == null) {
//    				weatherData = { "error" => data.get("error"), "hideError" => data.get("hideError") };
   // 			} else {
 //   				weatherData.put("error", data.get("error"));
  //  				weatherData.put("hideError", data.get("hideError"));
//				}
//			} else {
//    			if (Application.Properties.getValue("zerosForNoData") && aqiField != null) {
//    				aqiField.setData(0);
//    				fieldIsDirty = true;
//    				System.println("Recording zero for missing BAS");
//    			}
//    			if (weatherData == null) {
  //  				weatherData = { "error" => "No data available" };
//				} else {
//					weatherData.put("error", "No data available");
//				}
//			}

			if (Application has :Storage) {
				if (weatherData instanceof Dictionary) {
					Application.Storage.setValue("weatherData", weatherData);
				}
    		}
    	}
    }     

}