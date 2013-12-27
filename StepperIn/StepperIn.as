package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import flash.geom.Rectangle;
	import flash.utils.*;
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
	
	public class StepperIn extends Widget	{ 
		
		// vars
		public var theConnection:SocketConnection;
		public var fileConnection:SocketConnectionParams;
		// working variables 
		public var rawLow:int = 0;
		public var rawHigh:int = 1023;
		public var rawScale:int = rawHigh - rawLow;
		public var lastRawValue:Number = 0;
		public var lastProcessedValue:Number = 0;
		
		
		// buttons
		public var connectButton:ToggleButton;
		public var invertButton:ToggleButton;
		public var inputButton:ToggleButton;

		// instances of objects on the Flash stage
		//
		// fields
		//public var sInstanceName:TextField;
		public var sInputSource:TextField;
		public var sPort:TextField;
		public var sOut:TextField;
		public var sMin:TextField;
		public var sMax:TextField;

		
		// buttons
		public var connect:MovieClip;
		public var invert:MovieClip;
		public var input:MovieClip;
		
		// objects

		
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
						
			// set up the buttons
			connectButton = new ToggleButton(connect, this, "connect");
			invertButton = new ToggleButton(invert, this, "invert");
			inputButton = new ToggleButton(input, this, "input");
						
			// PARAMETERS
			//
			
			// set up the defaults for this widget's parameters
			paramsList.push(["connectButton", "off", "button"]);
			paramsList.push(["invertButton", "off", "button"]);
			paramsList.push(["sMin", "0", "text"]);
			paramsList.push(["sMax", "1023", "text"]);
			
			// set the name used in the parameters XML
			paramsXMLname = "StepperInput_" + this.name;
				
			// put default values in text fields
			sOut.text = "0";
			
			// go
			setupParams();

		}
		
		public function initControllerConnection() {
			theConnection.sendData("/service/tools/serial/connect " + serialPort + " " + serialBaudArduinoFirmata);
		}
		
		override public function finishConnect() {
			theConnection.sendData("/service/tools/serial/{" + hubDeviceName + "}/listen");
			super.finishConnect();
		}		
		
		public function processData( data:String): void {
			
			var theValue;
			var argsString:String;
			var args:Array;
			var myPattern:RegExp = /\}/g; // for getting rid of }
			var myPattern2:RegExp = /\{/g; // for getting rid of {
			var dataSplit:Array;
	
			//trace("the data: " + data);
			
			data = data.replace(myPattern,""); // remove any }
			data = data.replace(myPattern2,""); // remove any {
			dataSplit = data.split(" ");
			theValue = dataSplit[1];

			//trace("theValue: " + theValue);
			if(theValue.indexOf("OK") < 0 && theValue.indexOf("FAIL") < 0) {
				if (theValue == String(stepperID)) {
					processRawValue(dataSplit[2], this);
				}
			} else if (theValue.indexOf("OK") >=0) {
				getHubDevice(data);
				finishConnect();
			} else if (theValue.indexOf("FAIL") >=0) {
				disConnect();
				failConnect(data);
			}
		}
		
		public function processRawValue(rawValue:Number, widget:MovieClip): void {
			var valueConstrained:Number;
			var rawScaleConstrained:Number;
			var processedValue:Number;
			var minMaxScale:Number;
			
			var min:Number = widget.sMin.text;
			var max:Number = widget.sMax.text;
			
			// define the scale for output range defined by the min/max user fields
			minMaxScale = max - min;
			
			// show the raw value in the display

			rawValue = Math.min(rawValue, rawHigh);
			rawValue = Math.max(rawValue, rawLow);
			
			if (rawValue <= 0) {
				rawValue = rawLow;
				if (rawValue != lastRawValue) widget.inputButton.setState("off");
			} else {
				rawValue = rawHigh;
				if (rawValue != lastRawValue) widget.inputButton.setState("on");
			}
			
			processedValue = rawValue;
			
			valueConstrained = processedValue;
			rawScaleConstrained = rawHigh - rawLow;
			
			
			// create the processed value, depending on the invert switch
			if (widget.invertButton.text == "on") {
				// invert the raw input
				//processedValue = Math.round(((valueConstrained * -1) + rawScaleConstrained) * (minMaxScale/rawScaleConstrained)) + Math.round(min);
				processedValue = (((valueConstrained * -1) + rawScaleConstrained) * (minMaxScale/rawScaleConstrained)) + Math.round(min);
			} else {
				// normal raw input
				processedValue = (valueConstrained * (minMaxScale/rawScaleConstrained)) + Math.round(min);
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
		
		public function tryConnect():void {
			if (mobileSetupComplete || deviceType != "mobile") {
				if (theConnection == null) theConnection = new SocketConnection(this.name, remotehubIP, hubPort, this);
				theConnection.openConnection();
			} else {
				thisWidget.connectButton.setState("off");
				trace("can't connect until MobileControl is set");
			}
		}
		
		public function disConnect(): void {
			if (theConnection != null) theConnection.closeConnection();
		}		
		

		public function handleButton(buttonType:String, buttonState:String) {
			if (buttonType == "input") {
				//trace("input button");
				if (buttonState == "on") {
					//fillSmoothingBuffer(rawHigh)
					processRawValue(rawHigh, this);
				} else if (buttonState =="off") {
					//fillSmoothingBuffer(rawLow)
					processRawValue(rawLow, this);
				} 
			} else if (buttonType == "connect") {
				if (buttonState == "on") tryConnect();
				else if (buttonState =="off") disConnect();
			}
		}
		
		public function connectWidget():void {
			tryConnect();
			connectButton.setState("on");
		}
		
		public function disconnectWidget():void {
			disConnect();
			connectButton.setState("off");
		}
		
		override public function draw():void {
			super.draw();
			sInputSource.text = "stepper: " + stepperID;
		}
				
		//----------------------------------------------------------
		// parameter getter setter functions
		
		private var _serialPort:String = "/dev/cu.usb*";
		[Inspectable (name = "serialPort", variable = "serialPort", type = "String", defaultValue = "/dev/cu.usb*")]
		public function get serialPort():String { return _serialPort; }
		public function set serialPort(value:String):void {
			_serialPort = value;
			//draw();
		}
		
		private var _stepperID:Number = 0;
		[Inspectable (name = "stepperID", variable = "stepperID", type = "Number", defaultValue = 0)]
		public function get stepperID():Number { return _stepperID; }
		public function set stepperID(value:Number):void {
			_stepperID = value;
			draw();
		}

	}
}
