package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.errors.IOError; 
	import flash.text.TextField;
	import flash.net.URLRequest;
	import flash.utils.getDefinitionByName;
	import flash.utils.Timer;
	import flash.geom.Rectangle;

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
	
	public class DigitalOut extends WidgetOutputController { 
		
		// vars
		
		// buttons
		public var connectButton:ToggleButton;
		public var outputStateButton:ToggleButton;
		
		// working variables 
		private var lastOutputValue:int = -1;

		private var lastLevel:Number;
		
		// instances of objects on the Flash stage
		//
		// input fields
		
		// output fields
		public var sInputSource:TextField;
		public var sInputValue:TextField;
		public var sOutputPort:TextField;
		//public var sOut:TextField;
		
		// buttons
		public var connect:MovieClip;
		public var outputState:MovieClip;
		
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
			outputStateButton = new ToggleButton(outputState, this, "outputState");
			// PARAMETERS
			//
			
			// set up the defaults for this widget's parameters
			paramsList.push(["connectButton", "off", "button"]);
			//paramsList.push(["sMin", "0", "text"]);
			//paramsList.push(["sMax", "1023", "text"]);

			// set the name used in the parameters XML
			paramsXMLname = "DigitalOutput_" + this.name;
			
			// go
			setupParams();
			
			// init vars
			lastLevel = -100;
			
			// set up the listener for the input source, and draw a line to it
			setUpInputSource();
			
		}
		
		override public function handleButton(buttonType:String, buttonState:String) {
			if (buttonType == "outputState") {
				if (buttonState == "on") sendOutput(1);
				else if (buttonState =="off") sendOutput(0);
			} else super.handleButton(buttonType, buttonState);
		}
		
		public function initControllerConnection() {
		
			if (controller == "make") {
				theConnection.sendData("/service/osc/reader-writer/connect " + controllerPort);
				// make sure the output port is not set up as a PWM out
				//theConnection.sendData("/service/osc/reader-writer/pwmout/" + controllerOutputNum + "/active 0");
				// output initial value
				//sendOutput(0);
			} else if (controller == "arduino") {
				//theConnection.sendData("/service/arduino/reader-writer/nlhubconfig/connect " + serialPort + " " + serialBaudArduinoFirmata);
				theConnection.sendData("/service/arduino/reader-writer/config/connect " + serialPort);
				// output initial value
				//sendOutput(0);
			} else if (controller == "xbee") {
				theConnection.sendData("/service/xbee/reader-writer-series-1/connect " + serialPort + " " + serialBaudXbee);
				//theConnection.sendData("/service/xbee/reader-writer/nlhubconfig/connect " + serialPort + " " + serialBaudXbee);
				// output initial value
				//sendOutput(0);
			} else if (controller == "osc") {
				theConnection.sendData("/service/osc/reader-writer/nlhubconfig/connect " + controllerIP + ":" + controllerPort);
			} else if (controller == "hubFeed") {
				theConnection.sendData("/service/core/pipe/nlhubconfig/connect " + hubFeedName + " send");
			} else if (controller == "httpGet") {
				theConnection.sendData("/service/httpclient/reader-writer/get/" + controllerIP + "/arduino/mode/" + controllerOutputNum + "/output");
				hubDeviceName = "";
				super.finishConnect();
			}
		}
		
		override public function finishConnect() {
			if (controller == "make") {
				// make sure the output port is not set up as a PWM out
				var prefixString = "/pwmout/" + controllerOutputNum + "/active 0";
				theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + prefixString);
			}
			//trace("..." + this.name + " connected");
			//trace("..." + this.name + " connected to Hub device #" + hubDeviceNumber);
			super.finishConnect();
		}
		
		public function sendOutput(outputValue,port = -1) {
			if (outputValue > 0) outputValue = 1;
			else outputValue = 0;
			if (port == -1) port = controllerOutputNum;
			//trace(this.name + " " + outputValue);
			if (connectButton.text == "on" && outputValue != lastOutputValue && connectionComplete) {
				if (controller == "make") {
					// /digitalout/" + outputPt + "/value " + outputValue;
					//theConnection.sendData("/service/osc/reader-writer/digitalout/" + port + "/value " + String(outputValue));
					
					var prefixString = "/digitalout/" + controllerOutputNum + "/value " + String(outputValue);
					theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + prefixString);
				} else if (controller == "arduino") {
					theConnection.sendData("/service/arduino/reader-writer/{" + hubDeviceName + "}/digitalout/" + controllerOutputNum + " " + String(outputValue));
				} else if (controller == "xbee") {
				// /service/xbee/reader-writer/COM6/57/digitalout/0 1
					theConnection.sendData("/service/xbee/reader-writer-series-1/{" + hubDeviceName + "}/" + xbeeRemoteID + "/digitalout/" + port + " "  + String(outputValue));
				} else if (controller == "osc") {
					theConnection.sendData("/service/osc/reader-writer" + urlString + " " + String(outputValue * multiplier));
				} else if (controller == "hubFeed") {
					theConnection.sendData("/service/core/pipe/value " + String(outputValue * multiplier));
				} else if (controller == "httpGet") {
					var url = "/" + controllerIP + urlString + "/" + controllerOutputNum;
					if (connectionComplete) theConnection.sendData("/service/httpclient/reader-writer/get" + url + "/" + outputValue + " {} " + url);
				}
				lastOutputValue = outputValue;
			} else {
				// we're not ready to send output yet, so make sure we send new value (compared to lastOutputValue) out once we are ready
				lastOutputValue = -1;
			}
			if (outputValue > 0) outputStateButton.setState("on")
			else outputStateButton.setState("off")
			
		}

		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = event.netFeedValue;
			sInputValue.text = String(inputValue);
			//trace(this.name + " " + "inputfeed: " + inputValue);
			if (inputValue != lastLevel) {
				if (inputValue >= threshold) {
					//sendOutput(1);
					outputStateButton.text = "on";
				} else {
					//sendOutput(0);
					outputStateButton.text = "off";
				}
			}
			
			lastLevel = inputValue;
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
			//trace("in draw");
			sInputSource.text = inputSource;
			if (controller == "xbee") {
				sOutputPort.text = controller + " " + xbeeRemoteID + " " + controllerOutputNum;
			} if (controller == "osc") {
				sOutputPort.text = controller + " " + urlString;
			} else {
				sOutputPort.text = controller + " " + controllerOutputNum;
			}
		}
		
				
		//----------------------------------------------------------
		// parameter getter setter functions

		private var _controller:String = "arduino";
		[Inspectable (name = "controller", variable = "controller", type = "String", enumeration="arduino,httpGet,xbee,make,osc,hubFeed", defaultValue="arduino")]
		public function get controller():String { return _controller; }
		public function set controller(value:String):void {
			_controller = value;
			draw();
		}
		
		private var _xbeeRemoteID:String = "1";		
		[Inspectable (name = "xbeeRemoteID", variable = "xbeeRemoteID", type = "String", defaultValue = "1")]	
		public function get xbeeRemoteID():String { return _xbeeRemoteID; }
		public function set xbeeRemoteID(value:String):void {
			_xbeeRemoteID = value;
			//draw();
		}
		
		private var _threshold:Number = 500;
		[Inspectable (name = "threshold", variable = "threshold", type = "Number", defaultValue = 500)]
		public function get threshold():Number { return _threshold; }
		public function set threshold(value:Number):void {
			_threshold = value;
			//draw();
		}
		
		private var _controllerOutputNum:Number = 0;
		[Inspectable (name = "controllerOutputNum", variable = "controllerOutputNum", type = "Number", defaultValue = 0)]
		public function get controllerOutputNum():Number { return _controllerOutputNum; }
		public function set controllerOutputNum(value:Number):void {
			_controllerOutputNum = value;
			draw();
		}

		
		private var _urlString:String = "/arduino/digital";		
		[Inspectable (name = "urlString", variable = "urlString", type = "String", defaultValue = "/arduino/digital")]	
		public function get urlString():String { return _urlString; }
		public function set urlString(value:String):void {
			_urlString = value;
			draw();
		}
	}
}
