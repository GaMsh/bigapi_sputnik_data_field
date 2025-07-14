using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Attention;
using Toybox.System;
using Toybox.FitContributor;
using Toybox.Application;
using Toybox.Time;
using Toybox.Math;

class BAS_DataFieldView extends WatchUi.DataField {

    hidden var weatherData;
	var enableNotifications = false;
	var notified = false;
//	var displayPm2_5 = true;
	const TEMPERATURE_FIELD_ID = 0;
    const HUMIDITY_FIELD_ID = 1;
    const PRESSURE_FIELD_ID = 2;
    const STATION_FIELD_ID = 3;
	var displayVersion = true;
	const secondsToDisplayVersion = 14;
	var initialTime;
	var showShortLabel;

    function initialize(notifications) {
        DataField.initialize();
        weatherData = null;
        enableNotifications = notifications;
        try {
			temperatureField = createField("Temperature", TEMPERATURE_FIELD_ID, FitContributor.DATA_TYPE_SINT32,
				{:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"C"});
            humidityField = createField("Humidity", HUMIDITY_FIELD_ID, FitContributor.DATA_TYPE_SINT32,
                {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"C"});
            pressureField = createField("Pressure", PRESSURE_FIELD_ID, FitContributor.DATA_TYPE_SINT32,
                {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"mmHg"});
            stationField = createField("Station", STATION_FIELD_ID, FitContributor.DATA_TYPE_SINT32,
                {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>""});
  		} catch (ex) {
  			System.println("could not create fit file fields " + ex);
  		}
		showShortLabel = false;
  		initialTime = Time.now();
    }

	const sizeToShowLongLabel = 320;
	const sizeToShowTemp = 280;

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
		var width = dc.getWidth();
		if (width < sizeToShowLongLabel) {
			showShortLabel = true;
		} else {
			showShortLabel = false;
		}
        var obscurityFlags = DataField.getObscurityFlags();
		var screenShape = System.getDeviceSettings().screenShape;
        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.TopLeftLayout(dc));

        // Top right quadrant so we'll use the top right layout
        } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.TopRightLayout(dc));

        // Bottom left quadrant so we'll use the bottom left layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.BottomLeftLayout(dc));

        // Bottom right quadrant so we'll use the bottom right layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.BottomRightLayout(dc));
        // Use the generic, centered layout
		}
		else if (screenShape == System.SCREEN_SHAPE_ROUND) {
			View.setLayout(Rez.Layouts.MainRoundLayout(dc));
        } else if (screenShape == System.SCREEN_SHAPE_RECTANGLE) {
			if (width > sizeToShowTemp) {
			View.setLayout(Rez.Layouts.WiderLayout(dc));
			} else {
	            View.setLayout(Rez.Layouts.MainLayout(dc));
			}
        }
		var label = View.findDrawableById("label") as WatchUi.Text;
		var pressure = View.findDrawableById("pressure") as WatchUi.Text;
		if (pressure != null) {
			pressure.setText("Pressure");
		}
        return;
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
    	weatherData = weatherData;
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
    	dc.clear();
        var label = View.findDrawableById("label") as WatchUi.Text;

        // Set the background color
		var background = View.findDrawableById("Background") as WatchUi.Text;
        background.setColor(getBackgroundColor());

		var temperatureDrawable = View.findDrawableById("temperature") as WatchUi.Text;
        var humidity = View.findDrawableById("humidity") as WatchUi.Text;
		humidity.setVisible(true);
        var pressure = View.findDrawableById("pressure") as WatchUi.Text;
        pressure.setVisible(true);
		var errorDrawable = View.findDrawableById("errorValue") as WatchUi.Text;
		if (errorDrawable != null && errorDrawable has :setVisible) {
			errorDrawable.setVisible(false);
		}

        var currentWeather = null;
        label.setText(showShortLabel ? Rez.Strings.shortLabel : Rez.Strings.label);
        if (weatherData != null) {
        	humidityValue = weatherData.get("humidity");
			if (currentWeather instanceof Lang.Number) {
	        	humidity.setText(Math.round(currentWeather).toString().substring(0, 4));
			}
    	} else {
			if (weatherData != null && weatherData.get("error") != null) {
				background.setColor(Graphics.COLOR_RED);
				humidity.setColor(Graphics.COLOR_WHITE);
				humidity.setText(weatherData.get("error").toString().substring(0, 4));
			} else {
				if (errorDrawable != null) {
					humidity.setVisible(false);
					errorDrawable.setText("N/A 1");
					errorDrawable.setVisible(true);
				} else {
					humidity.setText("N/A 2");
				}
			}
		}
		if (getBackgroundColor() == Graphics.COLOR_WHITE) {
			if (temperatureDrawable != null) {
				temperatureDrawable.setColor(Graphics.COLOR_BLACK);
			}
		}
		if (currentWeather != null && getBackgroundColor() == Graphics.COLOR_WHITE) {
			if (weatherData != null && weatherData.hasKey("error")) {
				if (weatherData.hasKey("hideError")) {
					humidity.setColor(Graphics.COLOR_LT_GRAY);
					if (temperatureDrawable != null) {
						temperatureDrawable.setColor(Graphics.COLOR_LT_GRAY);
					}
				} else {
					background.setColor(Graphics.COLOR_RED);
					humidity.setColor(Graphics.COLOR_WHITE);
					humidity.setText(weatherData.get("error").toString().substring(0, 4));
				}
				notified = false;
			}
			else if (currentWeather < 51) {
				humidity.setColor(Graphics.COLOR_DK_GREEN);
				notified = false;
			}
			else if (currentWeather < 101) {
				humidity.setColor(Graphics.COLOR_YELLOW);
				notified = false;
			}
			else if (currentWeather < 151) {
				humidity.setColor(Graphics.COLOR_ORANGE);
				notified = false;
			}
			else if (currentWeather < 201) {
				humidity.setColor(Graphics.COLOR_DK_RED);
				if (Attention has :playTone && enableNotifications && !notified) {
					Attention.playTone(Attention.TONE_CANARY);
					notified = true;
				}
			}
			else {
				humidity.setColor(Graphics.COLOR_PURPLE);
				if (Attention has :playTone && enableNotifications && !notified) {
					Attention.playTone(Attention.TONE_CANARY);
					notified = true;
				}
			}
            label.setColor(Graphics.COLOR_BLACK);
		}
        else if (currentWeather != null && getBackgroundColor() == Graphics.COLOR_BLACK) {
            humidity.setColor(Graphics.COLOR_WHITE);
			if (weatherData != null && weatherData.hasKey("error")) {
				if (weatherData.hasKey("hideError")) {
					humidity.setColor(Graphics.COLOR_LT_GRAY);
					if (temperatureDrawable != null) {
						temperatureDrawable.setColor(Graphics.COLOR_LT_GRAY);
					}
				} else {
					background.setColor(Graphics.COLOR_RED);
					humidity.setColor(Graphics.COLOR_WHITE);
					humidity.setText(weatherData.get("error").toString().substring(0, 4));
				}
				notified = false;
			}
			else if (currentWeather < 51) {
				humidity.setColor(0x00FD00/*Graphics.COLOR_GREEN*/);
				notified = false;
			}
			else if (currentWeather < 101) {
				humidity.setColor(0xFFFF00);
				notified = false;
			}
			else if (currentWeather < 151) {
				humidity.setColor(Graphics.COLOR_ORANGE);
				notified = false;
			}
			else if (currentWeather < 201) {
				humidity.setColor(Graphics.COLOR_RED);
				if (Attention has :playTone && enableNotifications && !notified) {
					Attention.playTone(Attention.TONE_CANARY);
					notified = true;
				}
			}
			else {
				humidity.setColor(Graphics.COLOR_PURPLE);
				if (Attention has :playTone && enableNotifications && !notified) {
					Attention.playTone(Attention.TONE_CANARY);
					notified = true;
				}
			}
            label.setColor(Graphics.COLOR_WHITE);
        } else {
        	if (getBackgroundColor() == Graphics.COLOR_BLACK) {
	            humidity.setColor(Graphics.COLOR_WHITE);
				if (errorDrawable != null && errorDrawable instanceof WatchUi.Text) {
					errorDrawable.setColor(Graphics.COLOR_WHITE);
				}
	            label.setColor(Graphics.COLOR_WHITE);
        	} else {
	            humidity.setColor(Graphics.COLOR_BLACK);
				errorDrawable.setColor(Graphics.COLOR_BLACK);
	            label.setColor(Graphics.COLOR_BLACK);
            }
        }
		if (weatherData != null && weatherData.hasKey("url")) {
			var indicator = View.findDrawableById("indicator") as WatchUi.Text;
//			switch(weatherData.get("url")) {
//			case 1:
//				indicator.setText("AirNow");
//				indicator.setColor(Graphics.COLOR_DK_GRAY);
//				break;
//			case 2:
//				indicator.setText("Purple");
//				indicator.setColor(Graphics.COLOR_PURPLE);
//				break;
//			case 3:
				indicator.setColor(Graphics.COLOR_DK_GRAY);
				indicator.setText(weatherData.get("url"));
//				break;
//			}
		}
		if (temperatureDrawable != null && temperatureValue != null) {
//			var mySettings = System.getDeviceSettings();
			var workingTemperature = Math.round(temperatureValue);
//			if (mySettings.temperatureUnits == System.UNIT_METRIC)
//			{
//				workingTemperature = Math.round((((temperatureValue - 32) * 5) / 9));
//			}
			temperatureDrawable.setText(workingTemperature.toString());
		}
		var version = View.findDrawableById("version") as WatchUi.Text;
        if (me.displayVersion) {
        	var now = Time.now();
        	version.setText(Rez.Strings.Version);
        	me.displayVersion = now.subtract(initialTime).value() < secondsToDisplayVersion;
    	} else {
        	version.setBackgroundColor(Graphics.COLOR_TRANSPARENT);
        	version.setText("");
		}

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
