﻿package { 

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
	
	public class AnalogIn extends WidgetInput { 
		
		// vars
		public var theKnob:Knob;
		// buttons
		public var connectButton:ToggleButton;
		public var smoothButton:ToggleButton;
		public var easeButton:ToggleButton;
		public var invertButton:ToggleButton;
		
		// working variables 
		private var knobRectangle:Rectangle;
		public var knobRange:int = 100;
		private var floorDefault:String = "0";

		// instances of objects on the Flash stage
		//
		// fields
		public var sInput:TextField;
		public var sCeiling:TextField;
		public var sFloor:TextField;
		//public var gRawValueConstrained:TextField;
		public var sMax:TextField;
		public var sMin:TextField;
		public var sOut:TextField;
		public var sInstanceName:TextField;
		public var sInputSource:TextField;
		//public var gPort:TextField;
		
		// buttons
		public var connect:MovieClip;
		public var smooth:MovieClip;
		public var ease:MovieClip;
		public var invert:MovieClip;
		
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
			smoothButton = new ToggleButton(smooth, this, "smooth");
			easeButton = new ToggleButton(ease, this, "ease");
			invertButton = new ToggleButton(invert, this, "invert");
						
			// PARAMETERS
			//
			
			if (controller == "accelerometer") floorDefault = "-1023";
			
			// set up the defaults for this widget's parameters
			paramsList.push(["connectButton", "off", "button"]);
			paramsList.push(["smoothButton", "off", "button"]);
			paramsList.push(["easeButton", "off", "button"]);
			paramsList.push(["invertButton", "off", "button"]);
			paramsList.push(["sMin", "0", "text"]);
			paramsList.push(["sMax", "1023", "text"]);
			paramsList.push(["sFloor", floorDefault, "text"]);
			paramsList.push(["sCeiling", "1023", "text"]);
			
			// set the name used in the parameters XML
			paramsXMLname = "AnalogInput_" + this.name;
			
			// go
			setupParams();
			
			// set up knob
			knobRectangle = new Rectangle(theLine.x,theLine.y,0,100);
			theKnob = new Knob(knob, knobRectangle, this);
			
			// put default values in text fields
			//gRawValueConstrained.text = "0";
			sInput.text = "0";
			sOut.text = "0";
			
			inputType = "analog";
	
		}
		
		override public function initControllerConnection() {
			if (controller == "make") {
				theConnection.sendData("/service/osc/reader-writer/connect " + controllerPort);
				// make sure the input port is not set up as a digital in
				//theConnection.sendData("/service/osc/reader-writer/analogin/" + controllerInputNum + "/active 0");
				//theConnection.sendData("/service/osc/reader-writer/digitalin/" + controllerInputNum + "/active 0");
				// set up the listen and polling -- /service/osc/reader-writer/nlhubconfig/listen [OSC pattern] [1 | 0] [samples per second]
				//theConnection.sendData("/service/osc/reader-writer/listen /analogin/" + controllerInputNum + "/value 1 " + String(sampleRate));

			} else if (controller == "xbee") {
				theConnection.sendData("/service/xbee/reader-writer-series-1/connect " + serialPort + " " + serialBaudXbee);
			} else if (controller == "arduino") {
				theConnection.sendData("/service/arduino/reader-writer/connect " + serialPort);
			} else if (controller == "iotnREST") {
				theConnection.sendData("/service/httpclient/reader-writer/poll /get/" + controllerIP + urlString + "/" + "99" + " 0 " + sampleRate);
			} else super.initControllerConnection();
		}
		
		override public function finishConnect() {
			if (controller == "xbee") { 
				/// service/xbee/reader-writer-series-1/poll /{/dev/cu.usbserial-A100S8YL}/4/rssi
				// /service/xbee/reader-writer-series-1/poll /{/dev/cu.usbserial-A6007WLE}/19/rssi/ 0 24
				// /service/xbee/reader-writer-series-1/poll /{/dev/cu.usbserial-A6007WLE}/19/rssi 0 24
				if (controllerInputNum == 99) { // get RSSI value instead of analogin
					theConnection.sendData("/service/xbee/reader-writer-series-1/poll /{" + hubDeviceName + "}/" + xbeeRemoteID + "/rssi");
				} else {
					theConnection.sendData("/service/xbee/reader-writer-series-1/poll /{" + hubDeviceName + "}/" + xbeeRemoteID + "/analogin/" + controllerInputNum + " 0 " + sampleRate);
				}
			} else if (controller == "arduino") {
				theConnection.sendData("/service/arduino/reader-writer/poll /{" + hubDeviceName + "}/analogin/" + controllerInputNum + " 0 " + sampleRate);
			} else if (controller == "iotnREST") {
				//
			} else if (controller == "make") {
				theConnection.sendData("/service/osc/reader-writer/listen " + " /" + controllerIP + "/analogin/" + controllerInputNum + "/value " + controllerPort);
				// make sure the output port is not set up as a digital in
				//var prefixString = "/digitalin/" + controllerInputNum + "/active 0";
				//theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + prefixString);
				theConnection.sendData("/service/osc/reader-writer/poll /{" + controllerIP + ":" + controllerPort + "}/analogin/" + controllerInputNum + "/value 0 " + String(sampleRate));
			}
			super.finishConnect();
		}
		
		public function knobMove(position:Number): void {
			var newRaw = Math.floor(position*(rawScale/knobRange));
			//trace("knob: " + position + "," + newRaw);
			processRawValue(newRaw, this);
		}
		
		override public function draw():void {
			super.draw();
			if (controller == "inputSource") {
				sInputSource.text = inputSource;
			} else if (controller == "xbee") {
				sInputSource.text = controller + " " + xbeeRemoteID + " " + controllerInputNum;
			} else if (controller == "osc" || controller == "iotnREST") {
				sInputSource.text = controller + " " + controllerInputNum + " " + urlString;
			} else if (controller == "accelerometer") {
				sInputSource.text = "accel " + controllerInputNum;
			} else if (controller == "mic") {
				sInputSource.text = controller;
			} else if (controller == "hubFeed") {
				sInputSource.text = controller + " " + hubFeedName;
			} else {
				sInputSource.text = controller + " " + controllerInputNum;
			}
			
			sInstanceName.text = this.name;
		}
		
		public function connectWidget():void {
			tryConnect();
			connectButton.setState("on");
		}
		
		public function disconnectWidget():void {
			disConnect();
			connectButton.setState("off");
		}
		
		//----------------------------------------------------------
		// parameter getter setter functions
		
		private var _easeAmount:Number = 15;		
		[Inspectable (name = "easeAmount", variable = "easeAmount", type = "Number", defaultValue = 15)]	
		public function get easeAmount():Number { return _easeAmount; }
		public function set easeAmount(value:Number):void {
			_easeAmount = value;
			//draw();
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
