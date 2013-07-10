package org.netlabtoolkit { 

	import adobe.utils.MMExecute;
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.geom.Point;
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
	
	public class Widget extends WidgetBase	{ 
		
		
		// vars
		private var showInputSourceConnection:Boolean = false;
		private var inputSourceConnectionSprite:Sprite;
		private var inputSourceObject:Object;
		public var serialBaudArduinoFirmata:String = "57600"; // 115200 for Firmata 2.0/Arduino 16, 57600 for Firmata 2.1/Arduino 18
		public var serialBaudXbee:String = "9600";
		public var serialDeviceName:String;
		
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
		}
		
		public function setUpInputSource():Boolean {
			// make sure the inputSource is not ourselves
			inputSourceObject = parseNameSpace(inputSource, parent);
			
			if (inputSourceObject == this) {
				// notify the user and don't set up things
				trace("---> INPUTSOURCE IS SET TO THE SAME AS THIS WIDGET NAME - CHANGE TO INPUTSOURCE TO A DIFFERENT WIDGET NAME")
				return false;
			} else {
				// draw the connection to our inputSource
				enableDrawInputConnection();
	
				// set up our input feed
				stage.addEventListener(inputSource, handleInputFeed);
				return true;
			}
		}
		
		public function setUpInputSourceOther(sourceName:String, handler:Function):Boolean {
			// make sure the inputSource is not ourselves
			var inputSourceObjectOther = parseNameSpace(sourceName, parent);
			if (inputSourceObjectOther == this) {
				// notify the user and don't set up things
				trace("---> INPUTSOURCE: " + sourceName + " IS SET TO THE SAME AS THIS WIDGET NAME - CHANGE " + sourceName + " TO A DIFFERENT WIDGET NAME")
				return false;
			} else {
				// draw the connection to our inputSource
				//enableDrawInputConnection(inputSource);
				//trace("setting up handler");
				// set up our input feed
				stage.addEventListener(sourceName, handler);
				return true;
			}
		}
		
		// inputSource line drawing functions
		
		public function enableDrawInputConnection() {
			
			if (inputSourceObject != null) {
				showInputSourceConnection = true;
	
				inputSourceConnectionSprite = new Sprite();
				addChild(inputSourceConnectionSprite);
				drawInputConnection();
			} else {
				//trace("drawInputConnection: can't find object: " + inputSource);
			}
		}
		
		public function drawInputConnection () {
			if (showInputSourceConnection) {
				if (inputSourceObject != null) {
					
					var localPoint:Point = localToLocal(MovieClip(inputSourceObject),this);
					inputSourceConnectionSprite.graphics.clear()
					inputSourceConnectionSprite.graphics.lineStyle(1, 0xAAAAAA, 100);
					//trace(inputSourceObject.originalWidth + " " + scaleX);
					//inputSourceConnectionSprite.graphics.moveTo(localPoint.x + inputSourceObject.originalWidth, localPoint.y);
					inputSourceConnectionSprite.graphics.moveTo(localPoint.x + (inputSourceObject.originalWidth / scaleX), localPoint.y);
					//trace(this.name + localPoint.x + " " + inputSourceObject.width);
					inputSourceConnectionSprite.graphics.lineTo(0,0);
					
				} 
			}
		}
		
		public function serialNameShort(serialNameLong:String):String {
						
			var serialStart:int = serialNameLong.indexOf(".");
			var serialEnd:int = serialNameLong.lastIndexOf("*");
			
			if (serialStart == -1) serialStart = 0;
			else serialStart++;
			if (serialEnd == -1) serialEnd = serialNameLong.length - 1;
			
			return serialNameLong.substring(serialStart, serialEnd);
		}
		
		public function getHubDevice(connectString:String):void {
			var eol:int;
			//hubDeviceName = connectString.split(" ")[2];
			eol = connectString.split(" ")[2].indexOf("\n");
			if (eol >= 0) hubDeviceName = connectString.split(" ")[2].substring(0,eol);
			else hubDeviceName = connectString.split(" ")[2];
		}
		
		public function finishConnect() {
			if (hubDeviceName != "") trace("..." + this.name + " connected to device: " + hubDeviceName);
			else trace("..." + this.name + " connected");
		}

		public function failConnect(hubMessage) {
			trace("..." + this.name + " ERROR CONNECTING ---> IS THE DEVICE CONNECTED?\n" + hubMessage);
			thisWidget.connectButton.setState("off");
		}

		public function handleInputFeed( event:NetFeedEvent ):void {
			// stub function
		}
		
		//----------------------------------------------------------
		// component functions

		
		//----------------------------------------------------------
		// parameter getter setter functions
		
		// ----	
		private var _inputSource:String = "input0";
		[Inspectable (name = "inputSource", variable = "inputSource", type = "String", defaultValue = "input0")]
		public function get inputSource():String { return _inputSource; }
		public function set inputSource(value:String):void {
			_inputSource = value;
			drawInputConnection ()
			draw();
		}
	}
}
