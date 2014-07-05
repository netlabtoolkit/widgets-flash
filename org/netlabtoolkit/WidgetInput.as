package org.netlabtoolkit { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import flash.geom.Rectangle;
	import flash.utils.*;
	import flash.sensors.Accelerometer;
	import flash.events.AccelerometerEvent;
	import flash.media.Microphone;
	import org.netlabtoolkit.*;
	
	/**
	 * Part of the NETLab Flash Widgets, which is part of the NETLab Toolkit project - http://netlabtoolkit.org
	 *
	 * Copyright (c) 2006-2013 Philip van Allen <dev@philvanallen.com>
	 * 
	 * @author Philip van Allen
	 *
	 * NETLab Flash Widgets is free software: you can redistribute it and/or modify
	 * it under the terms of the GNU General Public License as published by
	 * the Free Software Foundation, either version 3 of the License, or
	 * (at your option) any later version.
	 *
	 * NETLab Flash Widgets is distributed in the hope that it will be useful,
	 * but WITHOUT ANY WARRANTY; without even the implied warranty of
	 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	 * GNU General Public License for more details.
	 *
	 * You should have received a copy of the GNU General Public License
	 * along with NETLab Flash Widgets.  If not, see <http://www.gnu.org/licenses/>.
	 */
	
	public class WidgetInput extends Widget	{ 
		
		
		// vars
		//public var hubPort:int = 51000;
		//public var hubIP:Number = 51000;
		public var theConnection:SocketConnection;
		public var fileConnection:SocketConnectionParams;
		// working variables 
		public var rawLow:int = 0;
		public var rawHigh:int = 1023;
		public var rawScale:int = rawHigh - rawLow;
		public var lastRawValue:Number = 0;
		public var lastProcessedValue:Number = 0;
		public var inputType:String; // digital or analog - set in setupAfterLoad
		
		
		public var calcScale:int;
		
		public var netFeedValue:Number;
		
		public var smoothingBuffer:Array;
		public var smoothingBufferSort:Array;
		public var smoothingTimer:Timer;
		public var smoothingTimerMsecs:Number;
		
		public var easingLastValue:Number = 0;
		
		// delay connection
		//private var connectDelayTimer:Timer;
		//private var randomDelay:int;

		
		// set up for multiInput
		private var _multiInput:Function = multiInputInternal;
		
		private var accel:Accelerometer;
		private var mic:Microphone;

		
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
			
			// set up the smoothing buffer
	
			smoothingBuffer = new Array(smoothAmount);
			fillSmoothingBuffer(0);
			
			// set up for an automated filling of the buffer if we don't receive any input from microcontroller
			// provide half the specified sample rate to keep traffic down to a reasonable amount
			smoothingTimerMsecs = Math.round(1/sampleRate * 1000 * 0.5); // set to milliseconds based on sampleRate
			smoothingTimer = new Timer(smoothingTimerMsecs, 1);
			smoothingTimer.addEventListener(TimerEvent.TIMER, smoothingFillIn);

			// if this widget gets its input from another widget instead of a microcontroller, show the graphic line to the widget
			if (controller == "inputSource") {
				setUpInputSource();
			}
			
		}
				
		public function handleButton(buttonType:String, buttonState:String) {
			
			if (buttonType == "connect") {
				if (buttonState == "on") tryConnect();
				else if (buttonState =="off") disConnect();
			}
		}
		
		public function smoothingFillIn(event:TimerEvent) {
			//trace("smoothing " + lastRawValue);
			processRawValue(lastRawValue, this);
		}
		
		override public function handleInputFeed( event:NetFeedEvent ):void {
			var inputValue = event.netFeedValue;
			
			if (thisWidget.connectButton.text == "on") processRawValue(inputValue, this);
		}
		
		// Our Accelerometer update function. 
		private function accelUpdate(e:AccelerometerEvent):void
		{
			// Trace out the accelerometer data so we can see it when debugging
			/*
			trace("Accelerometer X = " + e.accelerationX 
					+ "\n" 
					+ "Accelerometer Y = " + e.accelerationY
					+ "\n");
					*/
			
			// process the appropriate value, depending on controllerInputNum
			processData("/accel/ " + (e.accelerationX * 1000) + " " + (e.accelerationY * 1000) + " " + (e.accelerationZ * 1000));
		}
		
		private function onSampleDataReceived(event:SampleDataEvent):void {
			//trace(mic.activityLevel * 10);
			processData("/mic/ " + mic.activityLevel * 10);
		}

		
		public function tryConnect():void {
			if (mobileSetupComplete || deviceType != "mobile") {
				switch (controller) {
	
					case "accelerometer" :
						// Check for Accelerometer availability and act accordingly. 
						if(Accelerometer.isSupported) {
							// Create a new Accelerometer instance.
							accel = new Accelerometer();
							
							// Have the Accelerometer listen. This happens on every "tick".
							accel.addEventListener(AccelerometerEvent.UPDATE, accelUpdate);
						} else {
							// If there is no access to the Accelerometer
							trace("ACCELEROMETER IS NOT SUPPORTED ON THIS DEVICE");
						}
						break;
						
					case "mic" :
						if (Microphone.isSupported) {
							//Create a new Microphone
							mic = Microphone.getMicrophone();
							mic.rate = 22;
							mic.gain = 75;
							mic.setSilenceLevel(1,1500);
							mic.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleDataReceived);
						} else {
							// If there is no access to the Microphone
							trace("MICROPHONE IS NOT SUPPORTED ON THIS DEVICE");
						}
						break;
						
					case "inputSource" :
						// do nothing
						break;
						
					default :
						if (theConnection == null) theConnection = new SocketConnection(this.name, remotehubIP, hubPort, this);
						theConnection.openConnection();
						break;
				}
			} else {
				thisWidget.connectButton.setState("off");
				trace("can't connect until MobileControl is set");
			}
		}
		
		public function disConnect(): void {
			if (controller == "accelerometer") {
				if (Accelerometer.isSupported && accel != null) {
					accel.removeEventListener(AccelerometerEvent.UPDATE, accelUpdate);
					trace("turning off accel");
				}
				
			} else if (controller == "mic") {
				if (Microphone.isSupported && mic != null) {
					accel.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleDataReceived);
					trace("turning off mic");
				}
			} else {
				if (theConnection != null) theConnection.closeConnection();
			}
			isConnected = false;
		}
		
		public function initControllerConnection() {
		
			if (controller == "osc") {
				theConnection.sendData("/service/osc/reader-writer/connect " + controllerPort);
			} else if (controller == "hubFeed") {
				theConnection.sendData("/service/tools/pipe/connect/" + hubFeedName);
				//theConnection.sendData("/service/tools/pipe/value ");
			} else if (controller == "serial") {
				theConnection.sendData("/service/tools/serial/connect " + serialPort + " " + serialBaudArduinoFirmata);
			}
		}
		
				
		override public function finishConnect() {
			if (controller == "osc") {
				theConnection.sendData("/service/osc/reader-writer/listen " + " /" + controllerIP + thisWidget.urlString + " " + controllerPort);
				//theConnection.sendData("/service/osc/reader-writer/filterresponse " + urlString);
			} else if (controller == "hubFeed") {
				theConnection.sendData("service/tools/pipe/receive/" + hubFeedName);
			} else if (controller == "serial") {
				theConnection.sendData("/service/tools/serial/{" + hubDeviceName + "}/listen");
			}
			super.finishConnect();
		}
		
		public function processData( data:String): void {
			
			var theValue;
			var argsString:String;
			var args:Array;
			var dataSplit:Array;
			var quotePattern:RegExp = /\"/g; // for getting rid of quotes
			var lbracePattern:RegExp = /\}/g; // for getting rid of left brace
			var rbracePattern:RegExp = /\{/g; // for getting rid of right brace
			
			//trace("data: " + data);
			argsString = data.substr(data.indexOf(" ") + 1);
			argsString = argsString.replace(quotePattern,""); // remove any quotes
			argsString = argsString.replace(lbracePattern,""); // remove braces
			argsString = argsString.replace(rbracePattern,"");
			//trace("args: " + argsString);
			dataSplit = argsString.split(" ");			
			
			if (dataSplit[0].indexOf("FAIL") >=0) {
				disConnect();
				failConnect(data);
			} else if (dataSplit[0].indexOf("OK") >=0) {
				if (!isConnected) {
					if (controller == "arduino" || controller == "xbee" || controller == "serial") getHubDevice(data);
					else hubDeviceName = "";
					finishConnect();
				}
			} else if (controller == "iotnREST" && !isConnected) {
				hubDeviceName = "";
				theValue = dataSplit[0];
				finishConnect();
			} else {	
			
				switch (controller) {

					case "hubFeed" :
					case "osc" :
					case "accelerometer" : 
					case "serial" :
					case "iotnREST" :

						// use controllerInputNum as the argument position for the string, where the first arguement is 0
						// e.g. if the string is /acceleration/xyz 0.1 0.2 0.3 and controllerInputNum = 1, theValue will equal 0.2 for the second position
						if (dataSplit.length > controllerInputNum) theValue = dataSplit[controllerInputNum];
						else if (dataSplit.length > 0) theValue = dataSplit[0];
						else {
							theValue = 0;
							trace("NO DATA FROM DEVICE");
						}
						//trace("theValue: " + theValue);
						//if(theValue.indexOf("OK") < 0 && theValue.indexOf("FAIL") < 0) {
							if (isNaN(theValue)) {
								theValue = theValue.charCodeAt(0); // convert to the ascii value of the first char
							}
							theValue *= multiplier;
							// also make full OSC-like inputs available via code interface
							// from above example, will forward 0.1, 0.2, 0.3 as arguments
							multiInput.apply(null,dataSplit);
						//}

						break;
					case "make" :
					case "xbee" :
					case "arduino" : 
					case "mic" :
						if (isNaN(dataSplit[0])) {
							theValue = 0;
							trace("NO DATA FROM DEVICE");
						} else {
							theValue = Math.abs(dataSplit[0]);
						}
						break;
				}
			}
			
			//trace(dataSplit[0]);
			//trace(theValue);
			if (!isNaN(theValue)) {
				smoothingTimer.stop();
				processRawValue(Number(theValue), this);
			}
		}
		
		public function fillSmoothingBuffer(fill:Number): void {
			for (var i:int=0; i <  smoothingBuffer.length; i++) { // fill the buffer the passed number
				smoothingBuffer[i] = fill;
			}
		}

		
		public function processRawValue(rawValue:Number, widget:MovieClip): void {
			var valueConstrained:Number;
			var rawScaleConstrained:Number;
			var processedValue:Number;
			var minMaxScale:Number;
			var smoothingBufferSort = new Array(smoothAmount);
			
			var min:Number = widget.sMin.text;
			var max:Number = widget.sMax.text;
			
			// define the scale for output range defined by the min/max user fields
			minMaxScale = max - min;
			
			// round the raw value and constrain it to the high and low limits
			//rawValue = Math.round(rawValue);
			//rawValue = Math.min(rawValue, rawHigh);
			//rawValue = Math.max(rawValue, rawLow);
			
			
			
			// show the raw value in the display
			if (inputType == "analog") { // analog input
				var floor:Number = Number(widget.sFloor.text);
				var ceiling:Number = Number(widget.sCeiling.text);
				var rawHighDisplay = Math.max(rawHigh,ceiling);
				var rawLowDisplay = Math.min(rawLow,floor);
				var rawScaleDisplay = rawHighDisplay - rawLowDisplay;
				var rawValueCorrection = 0 - rawLowDisplay;

				rawValue = Math.min(rawValue, rawHighDisplay);
				rawValue = Math.max(rawValue, rawLowDisplay);
				widget.sInput.text = String(rawValue);
				// set the knob position to account for raw value changes coming from the sensor
				if (rawValue != lastRawValue) { // only move the thumb value indicator graphic if there is a change
					//widget.knob.y = (widget.theLine.y + widget.knobRange) - (rawValue*(widget.knobRange/rawScale));
					widget.knob.y = (widget.theLine.y + widget.knobRange) - (rawValue*(widget.knobRange/rawScaleDisplay)) - (widget.knobRange * (rawValueCorrection/rawScaleDisplay));
				}
			} else if (inputType == "digital") { // digital input
				rawValue = Math.min(rawValue, rawHigh);
				rawValue = Math.max(rawValue, rawLow);
				
				if (controller == "mic") {
					if (rawValue < 20) { // trigger off
						rawValue = rawLow;
						if (rawValue != lastRawValue) widget.inputButton.setState("off");
					} else { // trigger on
						rawValue = rawHigh;
						if (rawValue != lastRawValue) widget.inputButton.setState("on");
					}
				} else if (rawValue <= 0) {
					rawValue = rawLow;
					if (rawValue != lastRawValue) widget.inputButton.setState("off");
				} else {
					rawValue = rawHigh;
					if (rawValue != lastRawValue) widget.inputButton.setState("on");
				}
			}
			
			processedValue = rawValue;
			// do the smoothing if turned on
			if (widget.smoothButton.text == "on") {
				
				smoothingBuffer.push(Number(rawValue)); // add the new value onto the end of the array
				smoothingBuffer.shift(); // remove the oldest value from the beginning of the array
				smoothingBufferSort = smoothingBuffer.slice();
				smoothingBufferSort.sort(Array.NUMERIC);
				processedValue = smoothingBufferSort[Math.floor(smoothingBufferSort.length / 2) - 1];
				
				// old code for calculating average vs. median
				//temp = 0;
				//for (i=0; i < smoothingBuffer.length; i++) { // sum up all the values in the buffer
					//temp = temp + smoothingBuffer[i];
				//}
				//proxiAverage = Math.round(temp/smoothingBuffer.length) // get average of buffer values

				
			}
			
			if (inputType == "analog" && widget.easeButton.text == "on") {
				// do easing
				//easingLastValue += (processedValue - easingLastValue) / widget.easeAmount;
				//easingLastValue = easeOutCubic (0.5,easingLastValue,(processedValue - easingLastValue),10);
				//trace("easing last: " + easingLastValue);
				//if (easingLastValue < 0.0001) easingLastValue = 0;
				easingLastValue = easeOutExpo (0.17,easingLastValue,(processedValue - easingLastValue),widget.easeAmount);
				if (Math.abs(easingLastValue - processedValue) < 0.0001) easingLastValue = processedValue;
				processedValue = easingLastValue;
				//trace("easing: " + processedValue);
			}

			// handle ceiling/floor min/max setup
			if (inputType == "analog") { // analog input
				// constrain the raw value with the ceiling and floor, set the constrained scale
				//var floor:Number = Number(widget.sFloor.text);
				//var ceiling:Number = Number(widget.sCeiling.text);
				valueConstrained = Math.min(processedValue, ceiling);
				valueConstrained = Math.max(valueConstrained, floor);
				
				rawScaleConstrained = ceiling - floor;
				valueConstrained = valueConstrained - floor;
			} else if (inputType == "digital") { // digital input
				valueConstrained = processedValue;
				rawScaleConstrained = rawHigh - rawLow;
			}
			
			// create the processed value, depending on the invert switch
			if (widget.invertButton.text == "on") {
				// invert the raw input
				//processedValue = Math.round(((valueConstrained * -1) + rawScaleConstrained) * (minMaxScale/rawScaleConstrained)) + Math.round(min);
				processedValue = (((valueConstrained * -1) + rawScaleConstrained) * (minMaxScale/rawScaleConstrained)) + Math.round(min);
			} else {
				// normal raw input
				processedValue = (valueConstrained * (minMaxScale/rawScaleConstrained)) + Math.round(min);
			}
			

			// set up a timer to fill in values if nothing comes in
			// otherwise, the smoothing and easing won't clear out and settle correctly if the values don't change
			if(widget.smoothButton.text == "on" || widget.easeButton.text == "on") {
				//trace("start timer");
				
				smoothingTimer.stop();
				smoothingTimer.removeEventListener(TimerEvent.TIMER, smoothingFillIn);
				if (widget.easeButton.text != "on" || lastProcessedValue != processedValue) {
					smoothingTimer = new Timer(smoothingTimerMsecs, 1);
					smoothingTimer.addEventListener(TimerEvent.TIMER, smoothingFillIn);
					smoothingTimer.start(); 
				}
			}
			
			widget.sOut.text = String(Math.round(processedValue));
			
			lastRawValue = rawValue;
			lastProcessedValue = processedValue;
			
			stage.dispatchEvent(new NetFeedEvent(this.name, 
												 true,
												 false,
												 this,
												 processedValue));
		}
		
		
		private function easeOutCubic (t, b, c, d) { 
			return c * (Math.pow (t/d-1, 3) + 1) + b;
		}
		
		private function easeOutExpo(t, b, c, d):Number { 
			return c * (-Math.pow(2, -10 * t/d) + 1) + b;
		};
				
		// stuff for multiInput
		public function multiInputInternal(... args):void {
			// stub
			//trace("from analoginput: " + args);
		}
		
		// getter/setters for functions that can be replaced by user
		public function set multiInput ( newFunction:Function){
			_multiInput = newFunction;
		}
		public function get multiInput():Function {
			return _multiInput;
		}
				
				
		//----------------------------------------------------------
		// parameter getter setter functions
		
		// parameters in alphabetized order		
		private var _controller:String = "arduino";
		[Inspectable (name = "controller", variable = "controller", type = "String", enumeration="arduino,xbee,iotnREST,osc,serial,accelerometer,mic,hubFeed,make,inputSource", defaultValue="arduino")]
		public function get controller():String { return _controller; }
		public function set controller(value:String):void {
			_controller = value;
			draw();
		}
		
		private var _controllerIP:String = "127.0.0.1";		
		[Inspectable (name = "controllerIP", variable = "controllerIP", type = "String", defaultValue = "127.0.0.1")]
		public function get controllerIP():String { return _controllerIP; }
		public function set controllerIP(value:String):void {
			_controllerIP = value;
			//draw();
		}	
		
		private var _controllerPort:Number = 10000;		
		[Inspectable (name = "controllerPort", variable = "controllerPort", type = "Number", defaultValue = 10000)]
		public function get controllerPort():Number { return _controllerPort; }
		public function set controllerPort(value:Number):void {
			_controllerPort = value;
			//draw();
		}
		
		private var _multiplier:Number = 1;
		[Inspectable (name = "multiplier", variable = "multiplier", type = "Number", defaultValue = 1)]
		public function get multiplier():Number { return _multiplier; }
		public function set multiplier(value:Number):void {
			_multiplier = value;
			//draw();
		}		
		
		private var _hubFeedName:String = "feed0";		
		[Inspectable (name = "hubFeedName", variable = "hubFeedName", type = "String", defaultValue = "feed0")]	
		public function get hubFeedName():String { return _hubFeedName; }
		public function set hubFeedName(value:String):void {
			_hubFeedName = value;
			draw();
		}

		/*
		private var _remotehubIP:String = "127.0.0.1";
		[Inspectable (name = "remotehubIP", variable = "remotehubIP", type = "String", defaultValue = "127.0.0.1")]
		public function get remotehubIP():String { return _remotehubIP; }
		public function set remotehubIP(value:String):void {
			_remotehubIP = value;
			//draw();
		}	
		*/
		
		private var _serialPort:String = "/dev/cu.usb*";
		[Inspectable (name = "serialPort", variable = "serialPort", type = "String", defaultValue = "/dev/cu.usb*")]
		public function get serialPort():String { return _serialPort; }
		public function set serialPort(value:String):void {
			_serialPort = value;
			//draw();
		}		
		
		private var _sampleRate:Number = 24;
		[Inspectable (name = "sampleRate", variable = "sampleRate", type = "Number", defaultValue = 24)]
		public function get sampleRate():Number { return _sampleRate; }
		public function set sampleRate(value:Number):void {
			_sampleRate = value;
			//draw();
		}		
		
		private var _controllerInputNum:Number = 0;
		[Inspectable (name = "controllerInputNum", variable = "controllerInputNum", type = "Number", defaultValue = 0)]
		public function get controllerInputNum():Number { return _controllerInputNum; }
		public function set controllerInputNum(value:Number):void {
			_controllerInputNum = value;
			draw();
		}
		
		private var _smoothAmount:Number = 15;		
		[Inspectable (name = "smoothAmount", variable = "smoothAmount", type = "Number", defaultValue = 15)]	
		public function get smoothAmount():Number { return _smoothAmount; }
		public function set smoothAmount(value:Number):void {
			_smoothAmount = value;
			//draw();
		}	
		
		private var _xbeeRemoteID:String = "1";		
		[Inspectable (name = "xbeeRemoteID", variable = "xbeeRemoteID", type = "String", defaultValue = "1")]	
		public function get xbeeRemoteID():String { return _xbeeRemoteID; }
		public function set xbeeRemoteID(value:String):void {
			_xbeeRemoteID = value;
			//draw();
		}
		
	}
}
