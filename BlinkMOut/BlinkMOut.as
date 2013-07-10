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
	 * along with NETLab Glash Widgets.  If not, see <http://www.gnu.org/licenses/>.
	 */
	
	public class BlinkMOut extends WidgetOutput { 

		// vars
		
		// buttons
		public var connectButton:ToggleButton;
		
		// working variables 
		public var theKnob:Knob;
		private var knobRectangle:Rectangle;
		public var knobRange:int = 100;
		private var knobScale:Number;
		
		private var outputLevelMin:Number = 0;
		private var outputLevelMax:Number = 255;
		private var levelRange:Number = outputLevelMax - outputLevelMin;

		private var lastLevel:Number;
		
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
			paramsList.push(["connectButton", "off", "button"]);

			// set the name used in the parameters XML
			paramsXMLname = "BlinkMOutput_" + this.name;
			
			// go
			setupParams();
			
			// set up knob
			knobRectangle = new Rectangle(theLine.x,theLine.y,0,100);
			theKnob = new Knob(knob, knobRectangle, this);
			knobScale = (outputLevelMax - outputLevelMin)/knobRange;
			
			// init vars
			lastLevel = initialBrightness;
			
			if (inputSourceRed != "none") setUpInputSourceOther(inputSourceRed,setRedValue);
			if (inputSourceGreen != "none") setUpInputSourceOther(inputSourceGreen,setGreenValue);
			if (inputSourceBlue != "none") setUpInputSourceOther(inputSourceBlue,setBlueValue);
			
			setUpInputSource();

		}
		
	
		public function knobMove(position:Number): void {
			var newLevel = position*(knobScale);
			//trace("knob: " + position + "," + newRaw);
			sendOutput(newLevel);
			sInputValue.text = String(Math.round(newLevel));
		}
		
		public function initControllerConnection() {
			theConnection.sendData("/service/linkm/reader-writer/connect");
		}
		
		override public function finishConnect() {
			theConnection.sendData("/service/linkm/reader-writer/setfadespeed " + String(blinkMAddress) + " " + String(fadeSpeed));
			// output initial value
			super.finishConnect();
			sendOutput(initialBrightness);
			setKnob(initialBrightness);
			sInputValue.text = String(Math.round(initialBrightness));
		}
		
		public function sendOutput(outputValue) {
			sendBlinkM(outputValue);
		}
		
		public function sendBlinkM(outputValue:Number, customBlinkMAddress:Number = 0, customRGB:String = " ") {
			var scaleFactor:Number = outputLevelMax / outputValue;
			
			if (customRGB != " ") redGreenBlue = customRGB; // use the rgb value passed in
			var rgbValues = redGreenBlue.split(","); // separate the values
			
			// keep the values in range
			var redScaled:int = Math.max(Math.min(Number(rgbValues[0]),255),0);
			var greenScaled:int = Math.max(Math.min(Number(rgbValues[1]),255),0);
			var blueScaled:int = Math.max(Math.min(Number(rgbValues[2]),255),0);
			
			if (customRGB != " ") redGreenBlue = String(redScaled) + "," + String(greenScaled) + "," + String(blueScaled);
			
			// scale values
			redScaled = redScaled/scaleFactor;
			greenScaled = greenScaled/scaleFactor;
			blueScaled = blueScaled/scaleFactor;
			
			customBlinkMAddress = Math.round(customBlinkMAddress);
			if (customBlinkMAddress > 0 && customBlinkMAddress <= 512) blinkMAddress = customBlinkMAddress;
			if (connectButton.text == "on" && connectionComplete) {
				theConnection.sendData("/service/linkm/reader-writer/fadetorgb " + String(blinkMAddress) + " " + String(redScaled) + " " + String(greenScaled) + " " + String(blueScaled));
				lastLevel = outputValue;
			} else {
				lastLevel = outputValue;
			}
			sOut.text = String(redScaled) + "," + String(greenScaled) + "," + String(blueScaled);
		}
		

		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = event.netFeedValue;
			sInputValue.text = String(inputValue);
			
			// constrain the value to min and max
			inputValue = Math.min(inputValue,outputLevelMax);
			inputValue = Math.max(inputValue,outputLevelMin);
			
			// set the knob position to reflect the input values
			setKnob(inputValue);
			
			if (inputValue != lastLevel) {
				sendOutput(inputValue);
			}
		}
		
		private function setKnob(newLevel):void {
			if (theKnob.dragging == false) {
				var newY = (theLine.y + knobRange) - (newLevel*(knobRange/levelRange));
				knob.y = newY;
			}
		}
		
		private function setRedValue( event:NetFeedEvent):void {
			var inputValue = event.netFeedValue;
			setRGBValue(inputValue,0);
		}
		private function setGreenValue( event:NetFeedEvent):void {
			var inputValue = event.netFeedValue;
			setRGBValue(inputValue,1);
		}
		private function setBlueValue( event:NetFeedEvent):void {
			var inputValue = event.netFeedValue;
			setRGBValue(inputValue,2);
		}
		
		private function setRGBValue(inputValue:String,color:int):void {
			var rgbValues = redGreenBlue.split(",");
			
			rgbValues[color] = inputValue;
			redGreenBlue = rgbValues[0] + "," + rgbValues[1] + "," + rgbValues[2]; 
			sendOutput(lastLevel);
		}
		
		override public function parametersDone(): void {
			// set up envelope and watch all the envelope fields
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
			sInputSource.text = inputSource;
			sOutputPort.text = "BlinkM " + blinkMAddress;
		}
		
				
		//----------------------------------------------------------
		// parameter getter setter functions

		private var _blinkMAddress:Number = 9;
		[Inspectable (name = "blinkMAddress", variable = "blinkMAddress", type = "Number", defaultValue = 9)]
		public function get blinkMAddress():Number { return _blinkMAddress; }
		public function set blinkMAddress(value:Number):void {
			_blinkMAddress = value;
			draw();
		}
		
		private var _fadeSpeed:Number = 255;
		[Inspectable (name = "fadeSpeed", variable = "fadeSpeed", type = "Number", defaultValue = 255)]
		public function get fadeSpeed():Number { return _fadeSpeed; }
		public function set fadeSpeed(value:Number):void {
			_fadeSpeed = value;
			draw();
		}	
		
		private var _redGreenBlue:String = "255,0,0";
		[Inspectable (name = "redGreenBlue", variable = "redGreenBlue", type = "String", defaultValue = "255,0,0")]
		public function get redGreenBlue():String { return _redGreenBlue; }
		public function set redGreenBlue(value:String):void {
			var whitespace:RegExp = /(\t|\n|\s{2,})/g; 
			_redGreenBlue = value.replace(whitespace, "");
			//_redGreenBlue = value;
			draw();
		}
		
		private var _inputSourceRed:String = "none";
		[Inspectable (name = "inputSourceRed", variable = "inputSourceRed", type = "String", defaultValue = "none")]
		public function get inputSourceRed():String { return _inputSourceRed; }
		public function set inputSourceRed(value:String):void {
			_inputSourceRed = value;
			draw();
		}	
		
		private var _inputSourceGreen:String = "none";
		[Inspectable (name = "inputSourceGreen", variable = "inputSourceGreen", type = "String", defaultValue = "none")]
		public function get inputSourceGreen():String { return _inputSourceGreen; }
		public function set inputSourceGreen(value:String):void {
			_inputSourceGreen = value;
			draw();
		}	
		
		private var _inputSourceBlue:String = "none";
		[Inspectable (name = "inputSourceBlue", variable = "inputSourceBlue", type = "String", defaultValue = "none")]
		public function get inputSourceBlue():String { return _inputSourceBlue; }
		public function set inputSourceBlue(value:String):void {
			_inputSourceBlue = value;
			draw();
		}	
		
		private var _initialBrightness:Number = 255;
		[Inspectable (name = "initialBrightness", variable = "initialBrightness", type = "Number", defaultValue = 255)]
		public function get initialBrightness():Number { return _initialBrightness; }
		public function set initialBrightness(value:Number):void {
			_initialBrightness = value;
			draw();
		}	
	}
}
