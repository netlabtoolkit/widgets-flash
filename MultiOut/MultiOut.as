package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.errors.IOError; 
	import flash.text.TextField;
	import fl.controls.ComboBox;
	import fl.data.DataProvider;
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
	
	public class MultiOut extends WidgetOutputController { 
			
		// vars
		
		// buttons
		public var connectButton:ToggleButton;
		
		// working variables 
		public var theKnob:Knob;
		private var knobRectangle:Rectangle;
		public var knobRange:int = 100;
		private var levelRange:Number = 1023;
		private var knobScale:Number = levelRange/knobRange;
		
		
		//private var lastLevel:Number;
		
		private var lastOutputValue:String = "";
		
		private var lastIn:Array;
		
		// selector
		private var selectKnobParam:Array;
		private var knobParamSelection:Number = 0;
		public var actionSelector:ComboBoxSelector;
		
		// instances of objects on the Flash stage
		//
		// input fields

		public var input0:TextField;
		public var input1:TextField;
		public var input2:TextField;
		public var input3:TextField;
		public var input4:TextField;
		
		public var value0:TextField;
		public var value1:TextField;
		public var value2:TextField;
		public var value3:TextField;
		public var value4:TextField;
		
		public var valueArray:Array;
		
		// output fields
		
		public var out:TextField;
		public var outputDevice:TextField;
		
		// buttons
		public var connect:MovieClip;
		
		// objects
		public var knob:MovieClip;
		public var theLine:MovieClip;
		
		public var knobParam:ComboBox;
		
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
			
			// set up the buttons
			connectButton = new ToggleButton(connect, this, "connect");
			
			selectKnobParam = new Array( 
				{label:"Fader 0", data:0}, 
				{label:"Fader 1", data:1},
				{label:"Fader 2", data:2},
				{label:"Fader 3", data:3},
				{label:"Fader 4", data:4}
			);
			
			// set up the selector
			actionSelector = new ComboBoxSelector(knobParam, selectKnobParam, this, "knobParam");
			

			// PARAMETERS
			//
			
			// set up the defaults for this widget's parameters
			//paramsList.push(["actionSelector", "0", "selector"]);
			paramsList.push(["connectButton", "on", "button"]);
			paramsList.push(["value0", "0", "text"]);
			paramsList.push(["value1", "0", "text"]);
			paramsList.push(["value2", "0", "text"]);
			paramsList.push(["value3", "0", "text"]);
			paramsList.push(["value4", "0", "text"]);
			

			// PARAMETERS
			//

			// set the name used in the parameters XML
			paramsXMLname = "MultiOut_" + this.name;
			
			// go
			setupParams();
			
			// set up knob
			knobRectangle = new Rectangle(theLine.x,theLine.y,0,100);
			theKnob = new Knob(knob, knobRectangle, this);
			
			// init vars
			
			// set up all the extra input sources
			if (inputSource1 != "none") setUpInputSourceOther(inputSource1,handleInputFeed);
			if (inputSource2 != "none") setUpInputSourceOther(inputSource2,handleInputFeed);
			if (inputSource3 != "none") setUpInputSourceOther(inputSource3,handleInputFeed);
			if (inputSource4 != "none") setUpInputSourceOther(inputSource4,handleInputFeed);
			
			// set up the listener for the input source, and draw a line to it
			setUpInputSource();
		}
		
		override public function parametersDone(): void {
			valueArray = new Array(value0,value1,value2,value3,value4)
			//trace(valueArray[0].text);
			lastIn = new Array(value0.text,value1.text,value2.text,value3.text,value4.text);
		}
		
	
		public function knobMove(position:Number): void {
			var newLevel = Math.round(position*(knobScale));
			//trace("knob: " + knobParamSelection + " " + position + "," + newLevel);
			valueArray[knobParamSelection].text = newLevel;
			sendOutput();
		}
		
		public function initControllerConnection() {
		
			if (controller == "osc") {
				theConnection.sendData("/service/osc/reader-writer/connect " + controllerPort + " " + controllerIP);
			} else if (controller == "hubFeed") {
				theConnection.sendData("/service/tools/pipe/connect/" + hubFeedName);
			} else if (controller == "serial") {
				theConnection.sendData("/service/tools/serial/connect " + serialPort + " " + serialBaudArduinoFirmata);
			}
		}
		
		override public function finishConnect() {
			super.finishConnect();
		}
		
		public function sendOutput() {

			var outputArray:Array = new Array();
			var outputString:String = "";
			
			for (var i=0;i<numParameters;i++) {
				outputArray[i] = Number(valueArray[i].text) * multiplier;
				if (roundOutput) outputArray[i] = Math.round(outputArray[i]);
				if (i != 0) outputString += " ";
				outputString += String(outputArray[i]);
			}

			out.text = outputString;
			
			if (controller != "osc") outputString = "{" + outputString + "}";
			//trace("got " + outputString + " " + lastOutputValue);
			if (connectButton.text == "on" && connectionComplete) {
				if (outputString != lastOutputValue) {
					//trace("sent " + outputString + " " + lastOutputValue);
					if (controller == "osc") {
						theConnection.sendData("/service/osc/reader-writer/" + controllerIP + ":" + controllerPort + oscString + " " + outputString);
					} else if (controller == "hubFeed") {
						theConnection.sendData("/service/tools/pipe/send/" + hubFeedName + " " + outputString);
					} else if (controller == "serial") {
						theConnection.sendData("/service/tools/serial/{" + hubDeviceName + "}/write/ " + outputString);
					}

				}
				lastOutputValue = outputString;
			} else {
				// we're not ready to send output yet, so make sure we send new value (compared to lastOutputValue) out once we are ready
				lastOutputValue = "";
			}
		}

		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			var inputValue = event.netFeedValue;	
			var inputSender = event.type;
			var sendOutputChange = false;
			var inputSourceNum = -1;
			
			switch (inputSender) {
					
				case inputSource :
					if (inputValue != lastIn[0]) {
						inputSourceNum = 0;
					}
					break;
				
				case inputSource1 :
					if (inputValue != lastIn[1]) {
						inputSourceNum = 1;
					}
					break;
					
				case inputSource2 :
					if (inputValue != lastIn[2]) {
						inputSourceNum = 2;
					}
					break;
					
				case inputSource3 :
					if (inputValue != lastIn[3]) {
						inputSourceNum = 3;
					}
					break;
				
				case inputSource4 :
					if (inputValue != lastIn[4]) {
						inputSourceNum = 4;
					}
			}
			
			if (inputSourceNum != -1) {
				sendOutputChange = true;
				lastIn[inputSourceNum] = inputValue;
				valueArray[inputSourceNum].text = inputValue;
			}
			
						
			// set the knob position
			if (theKnob.dragging == false) {
				if (knobParamSelection == inputSourceNum) {
					var newY = (theLine.y + knobRange) - (inputValue*(knobRange/levelRange));
					knob.y = newY;
				}
			}
			
			
			if (sendOutputChange && inputSourceNum < numParameters) {
				sendOutput();
				//lastLevel = inputValue;
			}
		}
		
		public function handleComboBox(selectionType:String, selector:ComboBox) { 
			//trace("got property change");
			knobParamSelection = selector.selectedItem.data; 
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
			//sInputSource.text = inputSource;
			
			input0.text = inputSource;
			input1.text = inputSource1;
			input2.text = inputSource2;
			input3.text = inputSource3;
			input4.text = inputSource4;
			
			if (controller == "osc") {
				outputDevice.text = controller + " " + oscString;
			} else if (controller == "hubFeed") {
				outputDevice.text = controller + " " + hubFeedName;
			} else {
				outputDevice.text = controller;
			}
		}
		
				
		//----------------------------------------------------------
		// parameter getter setter functions

		private var _controller:String = "serial";
		[Inspectable (name = "controller", variable = "controller", type = "String", enumeration="serial,osc,hubFeed", defaultValue="serial")]
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
		
		private var _numParameters:Number = 2;
		[Inspectable (name = "numParameters", variable = "numParameters", type = "Number", enumeration="2,3,4,5", defaultValue = 2)]
		public function get numParameters():Number { return _numParameters; }
		public function set numParameters(value:Number):void {
			_numParameters = value;
			draw();
		}	
		
		private var _inputSource1:String = "none";
		[Inspectable (name = "inputSource1", variable = "inputSource1", type = "String", defaultValue="none")]
		public function get inputSource1():String { return _inputSource1; }
		public function set inputSource1(value:String):void {
			_inputSource1 = value;
			draw();
		}

		private var _inputSource2:String = "none";
		[Inspectable (name = "inputSource2", variable = "inputSource2", type = "String", defaultValue="none")]
		public function get inputSource2():String { return _inputSource2; }
		public function set inputSource2(value:String):void {
			_inputSource2 = value;
			draw();
		}
		
		private var _inputSource3:String = "none";
		[Inspectable (name = "inputSource3", variable = "inputSource3", type = "String", defaultValue="none")]
		public function get inputSource3():String { return _inputSource3; }
		public function set inputSource3(value:String):void {
			_inputSource3 = value;
			draw();
		}
		
		private var _inputSource4:String = "none";
		[Inspectable (name = "inputSource4", variable = "inputSource4", type = "String", defaultValue="none")]
		public function get inputSource4():String { return _inputSource4; }
		public function set inputSource4(value:String):void {
			_inputSource4 = value;
			draw();
		}
	}
}
