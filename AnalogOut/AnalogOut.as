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
	
	public class AnalogOut extends WidgetOutputController { 
			
		// vars
		
		// buttons
		public var connectButton:ToggleButton;
		
		// working variables 
		public var theKnob:Knob;
		private var knobRectangle:Rectangle;
		public var knobRange:int = 100;
		private var knobScale:Number;
		
		private var outputLevelMin:Number = 0;
		private var outputLevelMax:Number = 1023;
		private var levelRange:Number = outputLevelMax - outputLevelMin;

		private var lastLevel:Number;
		
		private var lastOutputValue:Number = -1;
		
		// instances of objects on the Flash stage
		//
		// input fields

		// output fields
		public var sInputSource:TextField;
		public var sInputValue:TextField;
		public var sOutputPort:TextField;
		public var sOut:TextField;
		
		// buttons
		public var connect:MovieClip;
		
		// objects
		public var knob:MovieClip;
		public var theLine:MovieClip;
		
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
			
			// set up the buttons
			connectButton = new ToggleButton(connect, this, "connect");

			// PARAMETERS
			//
			
			// set up the defaults for this widget's parameters
			paramsList.push(["connectButton", "on", "button"]);

			// set the name used in the parameters XML
			paramsXMLname = "AnalogOut_" + this.name;
			
			// go
			setupParams();
			
			// set up knob
			knobRectangle = new Rectangle(theLine.x,theLine.y,0,100);
			theKnob = new Knob(knob, knobRectangle, this);
			knobScale = (outputLevelMax - outputLevelMin)/knobRange;
			
			// init vars
			lastLevel = -100;
			
			// set up the listener for the input source, and draw a line to it
			setUpInputSource();
		}
		
	
		public function knobMove(position:Number): void {
			var newLevel = Math.round(position*(knobScale));
			//trace("knob: " + position + "," + newRaw);
			sendOutput(newLevel);
		}
		
		public function initControllerConnection() {
		
			if (controller == "make") {
				theConnection.sendData("/service/osc/reader-writer/connect " + controllerPort);
			} else if (controller == "arduino") {
				//theConnection.sendData("/service/arduino/reader-writer/nlhubconfig/connect " + serialPort + " " + serialBaudArduinoFirmata);
				theConnection.sendData("/service/arduino/reader-writer/config/connect " + serialPort);
				// output initial value
				//sendOutput(Number(sOut.text));
			} else if (controller == "osc") {
				theConnection.sendData("/service/osc/reader-writer/connect " + controllerPort + " " + controllerIP);
			} else if (controller == "hubFeed") {
				theConnection.sendData("/service/tools/pipe/connect/" + hubFeedName);
			} else if (controller == "serial") {
				theConnection.sendData("/service/tools/serial/connect " + serialPort + " " + serialBaudArduinoFirmata);
			} else if (controller == "iotnREST") {
				hubDeviceName = "";
				super.finishConnect();
			}
		}
		
		override public function finishConnect() {
			if (controller == "serial") {
				//trace("finishconnect");
				//theConnection.sendData("/service/tools/serial/{" + hubDeviceName + "}/terminator 10");
			} else if (controller == "make") {
				// make sure the output port is not set up as a digital out
				var prefixString = "/digitalout/" + controllerOutputNum + "/active 0";
				theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + prefixString);
			}
			//trace("..." + this.name + " connected");
			//trace("..." + this.name + " connected to Hub device #" + hubDeviceNumber);
			super.finishConnect();
		}
		
		public function sendOutput(outputValue) {
			var valueType:String;
			//trace(outputValue);
			
			// if sending to osc or hubfeed, check for string of parameters vs. a number
			if ((controller == "osc" || controller == "hubFeed" || controller == "serial") && String(outputValue).indexOf(" ") >= 0) {
				// treat as a string of parameters e.g. 10 5 20 to be sent via osc or hubfeed
				//if (controller == "hubFeed") outputValue = '"' + String(outputValue) + '"';
				outputValue = String(outputValue);
				valueType = "string";
			} else {
				// treat it as a number
				outputValue = Number(outputValue);
				if (controller == "make" || controller == "arduino" || controller == "xbee") {
					// number must be rounded
					outputValue = Math.round(outputValue);
				}
				valueType = "number";
			}
			
			if (controller == "osc" || controller == "hubFeed" || controller == "serial" || controller == "iotnREST") {
				// decide if we should use the multiplier or not
				if (valueType == "number") {
					outputValue = String(Number(outputValue) * multiplier);
				} 
			} else if (controller == "arduino") {
				outputValue = Math.floor(Number(outputValue)/4); // Arduino permits a PWM range of 0-255
				outputValue = Math.min(outputValue,255);
				outputValue = Math.max(0,outputValue);
			}
			
			if (roundOutput && valueType == "number") {
				outputValue = Math.round(outputValue);
			}

			if (connectButton.text == "on" && outputValue != lastOutputValue && connectionComplete) {
				if (controller == "make") {
					var prefixString = "/pwmout/" + controllerOutputNum + "/duty " + outputValue
					theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + prefixString);
				} else if (controller == "arduino") {
					theConnection.sendData("/service/arduino/reader-writer/{" + hubDeviceName + "}/analogout/" + controllerOutputNum + " " + outputValue);
				} else if (controller == "osc") {
					theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + urlString + " " + outputValue);
				} else if (controller == "hubFeed") {
					theConnection.sendData("/service/tools/pipe/send/" + hubFeedName + " " + outputValue);
				} else if (controller == "serial") {
					theConnection.sendData("/service/tools/serial/{" + hubDeviceName + "}/write/ " + outputValue);
				} else if (controller == "iotnREST") {
					//theConnection.sendData("/service/httpclient/reader/get/" + controllerIP + "/arduino/analog/" + controllerOutputNum + "/" + outputValue);
					var url = "/" + controllerIP + urlString + "/" + controllerOutputNum;
					theConnection.sendData("/service/httpclient/reader-writer/get" + url + "/" + outputValue + " {} " + url);
				}
				lastOutputValue = outputValue;
			} else {
				// we're not ready to send output yet, so make sure we send new value (compared to lastOutputValue) out once we are ready
				lastOutputValue = -1;
			}
			
			sOut.text = String(outputValue);
		
		}

		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = event.netFeedValue;
			sInputValue.text = String(inputValue);
			
			// constrain the value to min and max
			inputValue = Math.min(inputValue,outputLevelMax);
			inputValue = Math.max(inputValue,outputLevelMin);
						
			// set the knob position
			if (theKnob.dragging == false) {
				var newY = (theLine.y + knobRange) - (inputValue*(knobRange/levelRange));
				knob.y = newY;
			}
			
			
			if (inputValue != lastLevel) {
				sendOutput(inputValue);
				lastLevel = inputValue;
				//trace("newvol " + newVol);
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
			//trace("in draw");
			sInputSource.text = inputSource;
			if (controller == "osc" || controller == "iotnREST") {
				sOutputPort.text = controller + " " + urlString;
			} else if (controller == "hubFeed") {
				sOutputPort.text = controller + " " + hubFeedName;
			} else sOutputPort.text = controller + " " + controllerOutputNum;
		}
		
				
		//----------------------------------------------------------
		// parameter getter setter functions

		private var _controller:String = "arduino";
		[Inspectable (name = "controller", variable = "controller", type = "String", enumeration="arduino,iotnREST,make,osc,serial,hubFeed", defaultValue="arduino")]
		public function get controller():String { return _controller; }
		public function set controller(value:String):void {
			_controller = value;
			draw();
		}
		
		private var _roundOutput:Boolean = true;
		[Inspectable (name = "roundOutput", variable = "roundOutput", type = "Boolean", defaultValue=true)]
		public function get roundOutput():Boolean { return _roundOutput; }
		public function set roundOutput(value:Boolean):void {
			_roundOutput = value;
			//draw();
		}
		
		private var _controllerOutputNum:Number = 0;
		[Inspectable (name = "controllerOutputNum", variable = "controllerOutputNum", type = "Number", defaultValue = 0)]
		public function get controllerOutputNum():Number { return _controllerOutputNum; }
		public function set controllerOutputNum(value:Number):void {
			_controllerOutputNum = value;
			draw();
		}
		
		
		private var _urlString:String = "/arduino/analog";		
		[Inspectable (name = "urlString", variable = "urlString", type = "String", defaultValue = "/arduino/analog")]	
		public function get urlString():String { return _urlString; }
		public function set urlString(value:String):void {
			_urlString = value;
			draw();
		}
	}
}
