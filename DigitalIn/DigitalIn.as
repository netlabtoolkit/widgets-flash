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
	
	public class DigitalIn extends WidgetInput { 
		
		// vars
		
		
		// buttons
		public var connectButton:ToggleButton;
		public var smoothButton:ToggleButton;
		public var easeButton:ToggleButton;
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
		public var smooth:MovieClip;
		public var ease:MovieClip;
		
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
			smoothButton = new ToggleButton(smooth, this, "smooth");
			easeButton = new ToggleButton(ease, this, "ease");
			ease.visible = false;
			invertButton = new ToggleButton(invert, this, "invert");
			inputButton = new ToggleButton(input, this, "input");
						
			// PARAMETERS
			//
			
			// set up the defaults for this widget's parameters
			paramsList.push(["connectButton", "off", "button"]);
			paramsList.push(["smoothButton", "off", "button"]);
			paramsList.push(["invertButton", "off", "button"]);
			paramsList.push(["sMin", "0", "text"]);
			paramsList.push(["sMax", "1023", "text"]);
			
			// set the name used in the parameters XML
			paramsXMLname = "DigitalInput_" + this.name;
				
			// put default values in text fields
			sOut.text = "0";
			
			inputType = "digital";			
			// go
			setupParams();

		}
		
		override public function initControllerConnection() {
			if (controller == "make") {
				theConnection.sendData("/service/osc/reader-writer/connect " + controllerPort);
			} else if (controller == "xbee") {
				theConnection.sendData("/service/xbee/reader-writer-series-1/connect " + serialPort + " " + serialBaudXbee);
				//theConnection.sendData("/service/xbee/reader-writer/nlhubconfig/connect " + serialPort + " " + serialBaudXbee);
				//theConnection.sendData("/service/xbee/reader-writer/" + xbeeRemoteID + "/digitalin/" + controllerInputNum + "/value");
			} else if (controller == "arduino") {
				theConnection.sendData("/service/arduino/reader-writer/config/connect " + serialPort);
			} else if (controller == "iotnREST") {
				theConnection.sendData("/service/httpclient/reader-writer/get/" + controllerIP + "/arduino/mode/" + controllerInputNum + "/input");
				theConnection.sendData("/service/httpclient/reader-writer/poll /get/" + controllerIP + urlString + "/" + controllerInputNum + " 0 " + sampleRate);
			} else {
				super.initControllerConnection();
			}
		}
		
		override public function finishConnect() {
			if (controller == "xbee") { 
				theConnection.sendData("/service/xbee/reader-writer-series-1/poll /{" + hubDeviceName + "}/" + xbeeRemoteID + "/digitalin/" + controllerInputNum + " 0 " + sampleRate);
				//theConnection.sendData("/service/xbee/reader-writer-series-1/{" + hubDeviceName + "}/" + xbeeRemoteID + "/digitalin/" + controllerInputNum);
			} else if (controller == "arduino") {
				theConnection.sendData("/service/arduino/reader-writer/poll /{" + hubDeviceName + "}/digitalin/" + controllerInputNum + " 0 " + sampleRate);

			} else if (controller == "make") {
				theConnection.sendData("/service/osc/reader-writer/listen " + " /" + controllerIP + "/digitalin/" + controllerInputNum + "/value " + controllerPort);
				// make sure the output port is not set up as an analog in
				var prefixString = "/analogin/" + controllerInputNum + "/active 0";
				theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + prefixString);
				prefixString = "/digitalin/" + controllerInputNum + "/active 1";
				theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + prefixString);
				theConnection.sendData("/service/osc/reader-writer/poll /{" + controllerIP + ":" + controllerPort + "}/digitalin/" + controllerInputNum + "/value 0 " + String(sampleRate));
			}
			super.finishConnect();
		}
		
		override public function handleButton(buttonType:String, buttonState:String) {
			if (buttonType == "input") {
				//trace("input button");
				if (buttonState == "on") {
					//fillSmoothingBuffer(rawHigh)
					processRawValue(rawHigh, this);
				} else if (buttonState =="off") {
					//fillSmoothingBuffer(rawLow)
					processRawValue(rawLow, this);
				}
			} else super.handleButton(buttonType, buttonState);
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
			if (controller == "inputSource") {
				sInputSource.text = inputSource;
			} else if (controller == "xbee") {
				sInputSource.text = controller + " " + xbeeRemoteID + " " + controllerInputNum;
			} else if (controller == "osc" || controller == "iotnREST") {
				sInputSource.text = controller + " " + urlString;
			} else if (controller == "accelerometer") {
				sInputSource.text = "accel " + controllerInputNum;
			} else if (controller == "mic") {
				sInputSource.text = controller;
			} else {
				sInputSource.text = controller + " " + controllerInputNum;
			}
			
			//sInstanceName.text = this.name;
		}
				
		//----------------------------------------------------------
		// parameter getter setter functions

		
		
		private var _urlString:String = "/arduino/digital";		
		[Inspectable (name = "urlString", variable = "urlString", type = "String", defaultValue = "/arduino/digital")]	
		public function get urlString():String { return _urlString; }
		public function set urlString(value:String):void {
			_urlString = value;
			draw();
		}
	}
}
