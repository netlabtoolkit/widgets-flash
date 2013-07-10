package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import fl.controls.ComboBox; 
	import fl.data.DataProvider;
	import fl.transitions.*;
	import fl.transitions.easing.*;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.net.XMLSocket;
	import flash.net.URLLoader;
    import flash.net.URLRequest;
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
	
	public class Combine extends Widget { 
	
		// vars
		private var combineActions:Array;
		private var theAction:String;
		public var actionSelector:ComboBoxSelector;
		
		private var lastIn0:Number = 0;
		private var lastIn1:Number = 0;
		private var lastIn2:Number = 0;
		private var lastIn3:Number = 0;
		private var lastIn:Number = 0;
		
		private var prevIn0:Number = 0;
		private var prevChange:Number = 0;
		
		// buttons

		
		// instances of objects on the Flash stage
		//
		// fields
		public var input0:TextField;
		public var input1:TextField;
		public var input2:TextField;
		public var input3:TextField;
		public var sIn0:TextField;
		public var sIn1:TextField;
		public var sIn2:TextField;
		public var sIn3:TextField;
		public var sOut:TextField;
		
		
		// buttons
	
		// objects
		
		public var selectAction:ComboBox;

		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
			
			combineActions = new Array( 
				
				{label:"max", data:"max"}, 
				{label:"min", data:"min"},
				{label:"all", data:"all"},
				{label:"-", data:"-"},
				{label:"+", data:"+"},
				{label:"*", data:"*"}, 
				{label:"/", data:"/"},
				{label:"avg", data:"avg"},
				{label:"change", data:"change"}
				
			);
			
			// set up the selector
			actionSelector = new ComboBoxSelector(selectAction, combineActions, this, "combineAction");
			

			// PARAMETERS
			//
			
			// set up the defaults for this widget's parameters
			paramsList.push(["actionSelector", "max", "selector"]);
			
			// set the name used in the parameters XML
			paramsXMLname = "Combine_" + this.name;
			
			// go
			setupParams();
			
			// init display text fields
			sIn0.text = String(lastIn0);
			sIn1.text = String(lastIn1);
			sIn2.text = String(lastIn2);
			sIn3.text = String(lastIn3);
			sOut.text = "0";
			
			
			if (inputSource1 != "none") setUpInputSourceOther(inputSource1,handleInputFeedOther);
			if (inputSource2 != "none") setUpInputSourceOther(inputSource2,handleInputFeedOther);
			if (inputSource3 != "none") setUpInputSourceOther(inputSource3,handleInputFeedOther);			
			// set up the listener for the input source, and draw a line to it
			setUpInputSource();

	
		}
		
		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			processInput(event.netFeedValue,event.type);


		}
		
		public function handleInputFeedOther( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			processInput(event.netFeedValue,event.type);


		}
		
		private function processInput(inputValue:Number, inputSender) {
			switch (inputSender) {
					
				case inputSource :
					lastIn0 = inputValue;
					sIn0.text = String(inputValue);
					break;
				
				case inputSource1 :
					lastIn1 = inputValue;
					sIn1.text = String(inputValue);
					break;
					
				case inputSource2 :
					lastIn2 = inputValue;
					sIn2.text = String(inputValue);
					break;
					
				case inputSource3 :
					lastIn3 = inputValue;
					sIn3.text = String(inputValue);
					break;
			}
			
			lastIn = inputValue;
			combineInputs()
		}
		
		private function combineInputs():void {
			
			var outputValue:Number;
				
			switch (theAction) {
				
				case "max" :
					outputValue = lastIn0;
					if (inputSource1 != "none" && lastIn1 > outputValue) outputValue = lastIn1;
					if (inputSource2 != "none" && lastIn2 > outputValue) outputValue = lastIn2;
					if (inputSource3 != "none" && lastIn3 > outputValue) outputValue = lastIn3;
					
					break;
				
				case "min" :
				
					outputValue = lastIn0;
					if (inputSource1 != "none" && lastIn1 < outputValue) outputValue = lastIn1;
					if (inputSource2 != "none" && lastIn2 < outputValue) outputValue = lastIn2;
					if (inputSource3 != "none" && lastIn3 < outputValue) outputValue = lastIn3;
					
					break;
					
				case "all" :
				
					outputValue = lastIn;
					
					break;
					
				case "-" :
					outputValue = lastIn0;
					if (inputSource1 != "none") outputValue = outputValue - lastIn1;
					if (inputSource2 != "none") outputValue = outputValue - lastIn2;
					if (inputSource3 != "none") outputValue = outputValue - lastIn3;
					
					break;
					
				case "+" :
					outputValue = lastIn0;
					if (inputSource1 != "none") outputValue = outputValue + lastIn1;
					if (inputSource2 != "none") outputValue = outputValue + lastIn2;
					if (inputSource3 != "none") outputValue = outputValue + lastIn3;
					break;
					
				case "*" :
					outputValue = lastIn0;
					if (inputSource1 != "none") outputValue = outputValue * lastIn1;
					if (inputSource2 != "none") outputValue = outputValue * lastIn2;
					if (inputSource3 != "none") outputValue = outputValue * lastIn3;
					break;

				case "/" :
					outputValue = lastIn0;
					if (inputSource1 != "none") outputValue = outputValue / lastIn1;
					if (inputSource2 != "none") outputValue = outputValue / lastIn2;
					if (inputSource3 != "none") outputValue = outputValue / lastIn3;
					break;
					
				case "avg" :
					var avgCount:int = 1;
					outputValue = lastIn0;
					if (inputSource1 != "none") {
						outputValue = outputValue + lastIn1;
						avgCount++;
					}
					if (inputSource2 != "none") {
						outputValue = outputValue + lastIn2;
						avgCount++;
					}
					if (inputSource3 != "none") {
						outputValue = outputValue + lastIn3;
						avgCount++;
					}
					
					outputValue = outputValue / avgCount;
					break;
					
				case "change" :
					
					outputValue = lastIn0 - prevIn0;
					if (outputValue > 0 && outputValue > changeMax) outputValue = prevChange;
					else if (outputValue < 0 && outputValue < (changeMax * -1)) outputValue = prevChange;
					prevChange = outputValue;
					prevIn0 = lastIn0;
					
					break;
			}
			
			if (absoluteValue) outputValue = Math.abs(outputValue);
			
			sOut.text = String(outputValue);			
			stage.dispatchEvent(new NetFeedEvent(this.name, 
												 true,
												 false,
												 this,
												 outputValue));


		}
		
		public function handleComboBox(selectionType:String, selector:ComboBox) { 
			//trace("got property change");
			theAction = selector.selectedItem.data; 
		}

		//
		
		override public function draw():void {
			super.draw();
			
			input0.text = inputSource;
			input1.text = inputSource1;
			input2.text = inputSource2;
			input3.text = inputSource3;
			
			
		}
	
		//----------------------------------------------------------
		// parameter getter setter functions
		
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
		
		private var _absoluteValue:Boolean = false;
		[Inspectable (name = "absoluteValue", variable = "absoluteValue", type = "Boolean", defaultValue=false)]
		public function get absoluteValue():Boolean { return _absoluteValue; }
		public function set absoluteValue(value:Boolean):void {
			_absoluteValue = value;
			//draw();
		}	

		private var _changeMax:Number = 500;
		[Inspectable (name = "changeMax", variable = "changeMax", type = "Number", defaultValue = 500)]
		public function get changeMax():Number { return _changeMax; }
		public function set changeMax(value:Number):void {
			_changeMax = value;
		}
	}
}