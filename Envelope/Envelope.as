package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
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
	 * along with NETLab Glash Widgets.  If not, see <http://www.gnu.org/licenses/>.
	 */
	
	public class Envelope extends Widget { 
	
		// vars
		private var _insertInput:Function = insertInputInternal;
		private var _outputValue:Number = 0;
		
		private var envelope:EnvelopeObj;
		
		private var outputLevelMin:Number = 0;
		private var outputLevelMax:Number = 1023;
		private var levelRange:Number = outputLevelMax - outputLevelMin;

		private var lastLevel:Number;
		
		// instances of objects on the Flash stage
		//
		// input fields
		public var sMinLevel:TextField;
		public var sMaxLevel:TextField;
		public var sFadeInStart:TextField;
		public var sFadeInEnd:TextField;
		public var sFadeOutStart:TextField;
		public var sFadeOutEnd:TextField;

		// output fields
		public var sInputSource:TextField;
		public var sInputValue:TextField;
		public var sOut:TextField;
		
		
		// buttons
	
		// objects

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
			paramsList.push(["sMinLevel", "0", "text"]);
			paramsList.push(["sMaxLevel", "1023", "text"]);
			paramsList.push(["sFadeInStart", "1", "text"]);
			paramsList.push(["sFadeInEnd", "400", "text"]);
			paramsList.push(["sFadeOutStart", "800", "text"]);
			paramsList.push(["sFadeOutEnd", "1023", "text"]);
			
			// set the name used in the parameters XML
			paramsXMLname = "Envelope_" + this.name;
			
			// go
			setupParams();
			
			
			// init display text fields
			sInputValue.text = "0";
			sOut.text = "0";
			
			// set up the listener for the input source, and draw a line to it
			setUpInputSource();
	
		}
		
		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue:Number = event.netFeedValue;

			sInputValue.text = String(inputValue);
			var newLevel = envelope.envelopeLevel(inputValue);
			insertInput(Math.round(newLevel), this.name);
		}
		
		private function envelopeChanged (event:Event):void {
			envelope.minLevel = Number(sMinLevel.text);
			envelope.maxLevel = Number(sMaxLevel.text);
			envelope.fadeInStart = Number(sFadeInStart.text);
			envelope.fadeInEnd = Number(sFadeInEnd.text);
			envelope.fadeOutStart = Number(sFadeOutStart.text);
			envelope.fadeOutEnd = Number(sFadeOutEnd.text);
		}
		
		override public function parametersDone(): void {
			// set up envelope and watch all the envelope fields
			envelope = new EnvelopeObj(Number(sMinLevel.text), Number(sMaxLevel.text), Number(sFadeInStart.text), Number(sFadeInEnd.text), Number(sFadeOutStart.text), Number(sFadeOutEnd.text)); 
			sMinLevel.addEventListener(Event.CHANGE, envelopeChanged);
			sMaxLevel.addEventListener(Event.CHANGE, envelopeChanged);
			sFadeInStart.addEventListener(Event.CHANGE, envelopeChanged);
			sFadeInEnd.addEventListener(Event.CHANGE, envelopeChanged);
			sFadeOutStart.addEventListener(Event.CHANGE, envelopeChanged);
			sFadeOutEnd.addEventListener(Event.CHANGE, envelopeChanged);
		}
		
		public function insertInputInternal(inputValue:Number, id:String):void {
			
			insertOutput(inputValue);
		}
		
		public function insertOutput(outputValue:Number) {
			sOut.text = String(outputValue);
			_outputValue = outputValue;
			stage.dispatchEvent(new NetFeedEvent(this.name, 
												 true,
												 false,
												 this,
												 outputValue));
		}
		


		//
		
		override public function draw():void {
			super.draw();
			sInputSource.text = inputSource;
			
		}
		
		// getter/setters for functions that can be replaced by user
		public function set insertInput ( newFunction:Function){
			_insertInput = newFunction;
		}
		public function get insertInput():Function {
			return _insertInput;
		}
		
		public function set outputValue ( theValue:Number){
			_outputValue = theValue;
			insertOutput(_outputValue);
		}
		public function get outputValue():Number {
			return _outputValue;
		}
		
		//----------------------------------------------------------
		// parameter getter setter functions
		
	}
}