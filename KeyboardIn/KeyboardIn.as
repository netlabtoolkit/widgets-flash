package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	//import flash.utils.Timer;
	//import flash.utils.getTimer;

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
	
	public class KeyboardIn extends WidgetBase { 
	
		// vars
		
		private var lastKeyDetect:Number = -1;
		
		// buttons

		
		// instances of objects on the Flash stage
		//
		// fields
		public var input:TextField;

		public var sIn:TextField;

		public var sOut:TextField;
		
		
		// buttons
	
		// objects
		
		//public var selectAction:ComboBox;

		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);		

			// PARAMETERS
			//
			
			// set up the defaults for this widget's parameters
			//paramsList.push(["actionSelector", "max", "selector"]);
			
			// set the name used in the parameters XML
			//paramsXMLname = "Combine_" + this.name;
			
			// go
			//setupParams();
			
			// init display text fields
			input.text = "";
			sIn.text = String(0);
			sOut.text = "0";
			
			draw();

			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		}


		private function keyDownHandler(event:KeyboardEvent):void {
			
			/*
            trace("keyDownHandler: " + event.keyCode);
            trace("ctrlKey: " + event.ctrlKey);
            trace("keyLocation: " + event.keyLocation);
            trace("shiftKey: " + event.shiftKey);
            trace("altKey: " + event.altKey);
			*/
			
			processInput(event.keyCode);

 		}
		
		private function keyUpHandler(event:KeyboardEvent):void {
			var outputValue = -1;
			
			/*
            trace("keyDownHandler: " + event.keyCode);
            trace("ctrlKey: " + event.ctrlKey);
            trace("keyLocation: " + event.keyLocation);
            trace("shiftKey: " + event.shiftKey);
            trace("altKey: " + event.altKey);
			*/
			
			if (keyDetect) {
				if (event.keyCode == lastKeyDetect) {
					outputValue = 0;
					lastKeyDetect = -1;
				}
			} else {
				//
			}
			
			if (outputValue > -1) { // only output if there's a new value
				//trace("up: " + outputValue);
				sOut.text = String(outputValue);			
				stage.dispatchEvent(new NetFeedEvent(this.name, 
													 true,
													 false,
													 this,
													 outputValue));
			}

 		}
		
		private function processInput(inputValue:Number) {
			var outputValue = -1;
			
			sIn.text = String(inputValue);
			
			if (keyDetect) {
				if (inputValue == keyDetectValue) {
					outputValue = 500;
					lastKeyDetect = inputValue;
				} else {
					//outputValue = 0;
				}
				
			} else {
				outputValue = inputValue;
			}
			
			if (outputValue > -1) { // only output if there's a new value
				//trace("down: " + outputValue);
				sOut.text = String(outputValue);			
				stage.dispatchEvent(new NetFeedEvent(this.name, 
													 true,
													 false,
													 this,
													 outputValue));
			}
		}
		


		//
		
		override public function draw():void {
			if (keyDetect) input.text = "Detect: " + String(keyDetectValue);
			else input.text = "";
			super.draw();
		}
	
		//----------------------------------------------------------
		// parameter getter setter functions
		
		private var _keyDetect:Boolean = false;
		[Inspectable (name = "keyDetect", variable = "keyDetect", type = "Boolean", defaultValue = false)]
		public function get keyDetect():Boolean { return _keyDetect; }
		public function set keyDetect(value:Boolean):void {
			_keyDetect = value;
			draw();
		}

		private var _keyDetectValue:Number = 32;
		[Inspectable (name = "keyDetectValue", variable = "keyDetectValue", type = "Number", defaultValue = 32)]
		public function get keyDetectValue():Number { return _keyDetectValue; }
		public function set keyDetectValue(value:Number):void {
			_keyDetectValue = value;
		}
	}
}