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
	
	public class ServoOut extends WidgetOutputController { 
	
		// vars
		
		// buttons
		public var connectButton:ToggleButton;
		//public var servoSpeedSetButton:ToggleButton;
		public var rotateLeftButton:MomentaryButton;
		public var rotateRightButton:MomentaryButton;
		
		// working variables 		
		private var lastLevel:Number;
		private var lastMakePosition:Number;
		private var makeServoRangeMult:Number = (450 + 1300) / 180;
		private var makeServoOffset:Number = -450;
		
		// instances of objects on the Flash stage
		//
		// input fields

		// output fields
		public var sInputSource:TextField;
		public var sInput:TextField;
		public var sOutputPort:TextField;
		public var sOut:TextField;
		
		// buttons
		public var connect:MovieClip;
		//public var servoSpeedSet:MovieClip;
		public var rotateLeft:MovieClip;
		public var rotateRight:MovieClip;
		
		// objects
		public var servoDisplay:MovieClip;
		
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
			
			// set up the buttons
			connectButton = new ToggleButton(connect, this, "connect");
			//servoSpeedSetButton = new ToggleButton(servoSpeedSet, this, "servoSpeedSet");
			rotateLeftButton = new MomentaryButton(rotateLeft, this, "rotateLeft");
			rotateRightButton = new MomentaryButton(rotateRight, this, "rotateRight");

			// PARAMETERS
			//
			
			// set up the defaults for this widget's parameters
			paramsList.push(["connectButton", "off", "button"]);
			//paramsList.push(["servoSpeedSetButton", "off", "button"]);

			
			// set the name used in the parameters XML
			paramsXMLname = "ServoOutput_" + this.name;
			
			// go
			setupParams();
			
			// init vars
			lastLevel = -1;
			lastMakePosition = -1;
			servoDisplayRotate(Number(sOut.text));
			
			// set up the listener for the input source, and draw a line to it
			setUpInputSource();
			
		}
		
		public function initControllerConnection() {
		
			if (controller == "make") {
				//theConnection.sendData("/service/osc/reader-writer/nlhubconfig/connect " + controllerIP + ":" + controllerPort);
				theConnection.sendData("/service/osc/reader-writer/connect " + controllerPort);
				// set the servo port speed initially
				if (servoSpeedSet) {
					theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + "/servo/" + controllerOutputNum + "/speed " + servoSpeed);
				} else {
					theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + "/servo/" + controllerOutputNum + "/speed 1023");
				}
				// output initial value
				//sendOutput(Number(sOut.text));
			} else if (controller == "arduino") {
				theConnection.sendData("/service/arduino/reader-writer/connect " + serialPort);
			} else if (controller == "httpGet") {
				//theConnection.sendData("/service/httpclient/reader/get/" + controllerIP + "/arduino/servo/" + controllerOutputNum + "/" + 0);
				hubDeviceName = "";
				super.finishConnect();
			}
		}
		
		override public function finishConnect() {
			if (controller == "make") {
				//
			} else if (controller == "arduino") {
				//service/arduino/[servicename]/[serial-port]/servo/[pin]/config [minpulse] [maxpulse] [angle]
				theConnection.sendData("/service/arduino/reader-writer/{" + hubDeviceName + "}/servo/" + controllerOutputNum + "/config 544 2400 90");
			} else if (controller == "httpGet") {
				
			}
			super.finishConnect();
		}
		
		override public function handleButton(buttonType:String, buttonState:String) {
			if (buttonType == "servoSpeedSet") {
				if (connectButton.text == "on") {
					if (buttonState == "on") {
						if (controller == "make") theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + "/servo/" + controllerOutputNum + "/speed " + servoSpeed);
						//theConnection.sendData("/service/osc/reader-writer/servo/" + controllerOutputNum + "/speed " + servoSpeed);
					} else if (buttonState == "off") {
						if (controller == "make") theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + "/servo/" + controllerOutputNum + "/speed 1023");
						//if (controller == "make") theConnection.sendData("/service/osc/reader-writer/servo/" + controllerOutputNum + "/speed 1023");
					}
				}
			} else super.handleButton(buttonType, buttonState);
		}
		
		public function buttonStillDown(buttonType:String):void {
			var newAngle:Number = Number(sOut.text);
			if (buttonType == "rotateLeft") {
				newAngle--;
				newAngle = Math.max(0, newAngle);
			} else if (buttonType == "rotateRight") {
				newAngle++;
				newAngle = Math.min(180, newAngle);
			}
			
			sendOutput(newAngle);
		}
				
				
		
		function sendOutput(outputValue) {
			//outputValue = Math.round(outputValue);
			//trace(outputValue);
			if (connectButton.text == "on") {
				if (controller == "make") {
					// var prefixString = "/servo/" + (__outputPort) + "/position " + makePosition;
					var makePosition = Math.floor(outputValue * makeServoRangeMult) + makeServoOffset;
					//trace(makePosition);
					if (makePosition != lastMakePosition) {
						theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + "/servo/" + controllerOutputNum + "/position " + makePosition);
					}
					lastMakePosition = makePosition;
				} else if (controller == "arduino") {
					if (connectionComplete) theConnection.sendData("/service/arduino/reader-writer/{" + hubDeviceName + "}/servo/" + controllerOutputNum + "/angle " + outputValue);
				} else if (controller == "httpGet") {
					var url = "/" + controllerIP + urlString + "/" + controllerOutputNum;
					if (connectionComplete) theConnection.sendData("/service/httpclient/reader-writer/get" + url + "/" + outputValue + " {} " + url);
				}
			} 
			sOut.text = String(outputValue);
			servoDisplayRotate(outputValue);
		
		}
		

		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = Math.round(event.netFeedValue);
			sInput.text = String(inputValue);
			inputValue = Math.round(Math.min(inputValue,180));
			
			if (inputValue != lastLevel) {
				sendOutput(inputValue);
				lastLevel = inputValue;
			}
		}
		
		private function servoDisplayRotate(theAngle:Number):void {
			servoDisplay.degreeDisplay.sDegrees.text = theAngle;
			servoDisplay.rotation = theAngle + 180;
			servoDisplay.degreeDisplay.rotation = servoDisplay.rotation * -1;
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
			sOutputPort.text = controller + " " + controllerOutputNum;
		}
		
				
		//----------------------------------------------------------
		// parameter getter setter functions

		private var _controller:String = "arduino";
		[Inspectable (name = "controller", variable = "controller", type = "String", enumeration="arduino,httpGet,make", defaultValue="arduino")]
		public function get controller():String { return _controller; }
		public function set controller(value:String):void {
			_controller = value;
			draw();
		}


		private var _servoSpeed:Number = 5;
		[Inspectable (name = "servoSpeed", variable = "servoSpeed", type = "Number", defaultValue = 5)]
		public function get servoSpeed():Number { return _servoSpeed; }
		public function set servoSpeed(value:Number):void {
			_servoSpeed = value;
			//draw();
		}
		
		private var _servoSpeedSet:Boolean = false;
		[Inspectable (name = "servoSpeedSet", variable = "servoSpeedSet", type = "Boolean", defaultValue = false)]
		public function get servoSpeedSet():Boolean { return _servoSpeedSet; }
		public function set servoSpeedSet(value:Boolean):void {
			_servoSpeedSet = value;
			//draw();
		}
		
		private var _controllerOutputNum:Number = 0;
		[Inspectable (name = "controllerOutputNum", variable = "controllerOutputNum", type = "Number", defaultValue = 0)]
		public function get controllerOutputNum():Number { return _controllerOutputNum; }
		public function set controllerOutputNum(value:Number):void {
			_controllerOutputNum = value;
			draw();
		}
		
		private var _urlString:String = "/arduino/servo";		
		[Inspectable (name = "urlString", variable = "urlString", type = "String", defaultValue = "/arduino/servo")]	
		public function get urlString():String { return _urlString; }
		public function set urlString(value:String):void {
			_urlString = value;
			draw();
		}
	}
}
