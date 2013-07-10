﻿package { 

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
	
	public class IfThenElse extends Widget { 
	
		// vars
		private var ruleOptions:Array;
		public var ruleSelector:ComboBoxSelector;
		public var ruleSelection:String;
		
		private var comboOptions:Array;
		public var comboSelector:ComboBoxSelector;
		public var comboSelection:String;
		
		private var trueOptions:Array;
		private var falseOptions:Array;
		
		public var trueSelector:ComboBoxSelector;
		public var trueSelection:String;

		public var falseSelector:ComboBoxSelector;
		public var falseSelection:String;

		public var ifThenResult:Boolean = false;
		public var lastIfThenResult:Boolean = false;
		public var provisionalLastIfThenResult:Boolean = false;
		
		public var waitTimerTrue:Timer;
		public var waitTimerFalse:Timer;
		public var waitTimeBlink:Timer;
		
		public var waitTimeStart:Number = 0;
		
		private var waitPending:String = "NONE";
		
		private var comboIfThen:Object;
		
		private var inputGatedTrueValue:Number = 0;
		private var inputGatedFalseValue:Number = 0;
		
		private var trueValue:Number;
		
		// buttons

		
		// instances of objects on the Flash stage
		//
		// fields
		//public var sInputSource:TextField;
		// var sCombo:TextField;
		public var sInputValue:TextField;
		public var sResult:TextField;
		public var sOperator:TextField;
		public var sResultCombo:TextField;
		public var sCompareTo:TextField;
		public var sTrueVal:TextField;
		public var sFalseVal:TextField;
		//public var sOut:TextField;	
		public var outputHighlight:MovieClip;
		// buttons

	
		// objects
		public var ruleSel:ComboBox;
		public var comboSel:ComboBox;
		public var trueSel:ComboBox;
		public var falseSel:ComboBox;

		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {

			super.setupAfterLoad(event);
			
			ruleOptions = new Array( 
				
				{label:"<", data:"<"}, 
				{label:"<=", data:"<="}, 
				{label:"==", data:"=="}, 
				{label:"~=", data:"~="}, 
				{label:">", data:">"}, 
				{label:">=", data:">="}

			);
			
			trueOptions = new Array( 
				
				{label:"set value ->", data:"NUM"}, 
				{label:"gated:" + inputGatedTrue, data:"IN1"},
				{label:"no output", data:"NONE"}

			);
			
			falseOptions = new Array( 
				
				{label:"set value ->", data:"NUM"}, 
				{label:"gated:" + inputGatedFalse, data:"IN2"}, 
				{label:"no output", data:"NONE"}

			);
			
			comboOptions = new Array( 
				
				{label:inputSource + " only", data:"ONLY"}, 
				{label:inputSource + " and " + addIfThen, data:"AND"}, 
				{label:inputSource + " or " + addIfThen, data:"OR"}, 
				{label:inputSource + " xor " + addIfThen, data:"XOR"}

			);
			
			// set up the selectors
			ruleSelector = new ComboBoxSelector(ruleSel, ruleOptions, this, "ifThenOptions");
			comboSelector = new ComboBoxSelector(comboSel, comboOptions, this, "comboOptions");
			trueSelector = new ComboBoxSelector(trueSel, trueOptions, this, "trueOptions");
			falseSelector = new ComboBoxSelector(falseSel, falseOptions, this, "falseOptions");
			
			// PARAMETERS
			//
			
			//if (inputGatedTrue != "none" || inputGatedFalse != "none") trueValue = 0;
			trueValue = 500;
			
			// set up the defaults for this widget's parameters
			paramsList.push(["ruleSelector", "~=", "selector"]);
			paramsList.push(["comboSelector", "ONLY", "selector"]);
			paramsList.push(["trueSelector", "NUM", "selector"]);
			paramsList.push(["falseSelector", "NUM", "selector"]);
			paramsList.push(["sCompareTo", "500", "text"]);
			paramsList.push(["sTrueVal", String(trueValue), "text"]);
			paramsList.push(["sFalseVal", "0", "text"]);
			
			// set the name used in the parameters XML
			paramsXMLname = "IfThenElse_" + this.name;
			
			// go
			setupParams();
			
			// init display text fields
			sInputValue.text = "0";
			sCompareTo.text = "500";
			//sOut.text = "0";
			sTrueVal.text = String(trueValue);
			sFalseVal.text = "0";
			sResult.text = "--";
			
			// set up wait timer
			if (waitTimeTrue > 0 || waitTimeFalse > 0) {
				waitTimerTrue = new Timer(Number(waitTimeTrue + 5), 1);
				waitTimerTrue.addEventListener(TimerEvent.TIMER, waitTimeDone);
				
				waitTimerFalse = new Timer(Number(waitTimeFalse + 5), 1);
				waitTimerFalse.addEventListener(TimerEvent.TIMER, waitTimeDone);
				
				waitTimeBlink = new Timer(167, 0);
				waitTimeBlink.addEventListener(TimerEvent.TIMER, waitTimeBlinkDone);
			}
			
			// get IfThen instance to work with
			if (comboSelection != "ONLY" && addIfThen != "not set") {
				comboIfThen = parseNameSpace(addIfThen, parent);
				if (comboIfThen == null) {
					// bad clip name
					trace('--->BAD NAME FOR IfThenElse instance (' + addIfThen + '): Check the spelling of the IfThenElse widget instance name');
				} else {
					stage.addEventListener(addIfThen, handleAddIfThenFeed);
				}
			}
			
			// set up the listener for the input source, and draw a line to it
			setUpInputSource();
			if (inputGatedTrue != "not set") setUpInputSourceOther(inputGatedTrue,handleInputFeedinputGatedTrue);
			if (inputGatedFalse != "not set") setUpInputSourceOther(inputGatedFalse,handleInputFeedinputGatedFalse);

	
		}
		
		public function ifThenOutput(outputValue:Number) {
			//sOut.text = String(outputValue);
			stage.dispatchEvent(new NetFeedEvent(this.name, 
												 true,
												 false,
												 this,
												 outputValue));
		}
		
		public function handleAddIfThenFeed( event:NetFeedEvent ):void {
			// picks up any changes to a cascaded ifThenElse widget
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			processInput(Number(sInputValue.text));
		}
		
		override public function handleInputFeed( event:NetFeedEvent ):void {
			processInput(event.netFeedValue);
		}
		
		public function handleInputFeedinputGatedTrue( event:NetFeedEvent ):void {			
			inputGatedTrueValue = event.netFeedValue;
			if (trueSelection == "IN1") sTrueVal.text = String(inputGatedTrueValue);
			processInput(Number(sInputValue.text));
		}
		
		public function handleInputFeedinputGatedFalse( event:NetFeedEvent ):void {			
			inputGatedFalseValue = event.netFeedValue;
			if (falseSelection == "IN2") sFalseVal.text = String(inputGatedFalseValue);
			processInput(Number(sInputValue.text));
		}
		
		public function processInput(inputValue:Number):void {

			var outputValue:Number;
			var outValue:Number;
			var compareTo:Number = Number(sCompareTo.text);
			var outputSelection:String;
			var comboResult:Boolean;
			var interimResult:Boolean;
			
			//trace("in processInput " + inputValue + waitPending);
			
			sInputValue.text = String(inputValue);
			
			ifThenResult = false;

			// define this instance true or false
			switch (ruleSelection) {
				case "<" :
					if (inputValue < compareTo) ifThenResult = true;
					break;
				case "<=" :
					if (inputValue <= compareTo) ifThenResult = true;
					break;
				case "==" :
					if (inputValue == compareTo) ifThenResult = true;
					break;
				case "~=" :
					if (inputValue >= compareTo - nearEqualRange && inputValue <= compareTo + nearEqualRange) ifThenResult = true;
					break;
				case ">=" :
					if (inputValue > compareTo) ifThenResult = true;
					break;
				case ">" :
					if (inputValue >= compareTo) ifThenResult = true;
					break;
			}
			
			interimResult = ifThenResult; 
			
			if (ifThenResult != lastIfThenResult) { // making a transition, check for wait going into this transition
				if (waitPending == "NONE") { // we're not coming out of a wait, so start a new wait
					if (waitTimeTrue > 0 && ifThenResult == true) { // wait for input value to be in the TRUE range for the waitTime milliseconds
						
						// kill any running timers
						waitTimerTrue.stop();
						waitTimerFalse.stop();
						waitTimeBlink.stop();
						
						waitTimeStart = getTimer();
						
						// start new timers
						waitTimerTrue.start();
						waitTimeBlink.start();
						
						
						//if (waitPending == "FALSE") ifThenResult = true; // we just were in a false wait
						//else ifThenResult = false;
						ifThenResult = false;
						waitPending = "TRUE";
						
						sResult.text = ""; // start the blink
					} else if (waitTimeFalse > 0 && ifThenResult == false) { // // wait for input value to be in the FALSE range for the waitTime milliseconds
						
						// kill any running timers
						waitTimerTrue.stop();
						waitTimerFalse.stop();
						waitTimeBlink.stop();
						
						waitTimeStart = getTimer();
						
						// start new timers
						waitTimerFalse.start();
						waitTimeBlink.start();
						
						//if (waitPending == "TRUE") ifThenResult = false;
						//else ifThenResult = true;
						ifThenResult = true;
						waitPending = "FALSE";
						
						sResult.text = ""; // start the blink
					} 
				} else {
					// no waitTime so do the normal status
					sResult.text = (String(ifThenResult).toUpperCase()).substr(0,1);
					waitPending = "NONE";
					waitTimerTrue.stop();
					waitTimerFalse.stop();
					waitTimeBlink.stop();
				}
			} else { // value is the same as last time
				if (waitPending == "TRUE") {
					//trace("testing for enough time " + waitTimeStart + " " + getTimer());
					// we've been waiting in the TRUE range, has it been long enough?
					if ((getTimer() - waitTimeStart) < waitTimeTrue) { // if not, invalidate the result
						ifThenResult = false; 
					} else {
						// we've been in the TRUE range long enough
						waitTimerTrue.stop();
						waitTimeBlink.stop();
						sResult.text = (String(ifThenResult).toUpperCase()).substr(0,1);
						waitPending = "NONE";
					}
				} else if (waitPending == "FALSE") {
					// we've been in the FALSE range, has it been long enough?
					if ((getTimer() - waitTimeStart) < waitTimeFalse) { // if not, invalidate the result
						ifThenResult = true; 
					} else {
						// we've been in the TRUE range long enough
						waitTimerFalse.stop();
						waitTimeBlink.stop();
						sResult.text = (String(ifThenResult).toUpperCase()).substr(0,1);
						waitPending = "NONE";
					}
				} else {
					// no waitTime so do the normal status
					sResult.text = (String(ifThenResult).toUpperCase()).substr(0,1);
				}
			}
			
			lastIfThenResult = interimResult;
			
			//sResult.text = String(ifThenResult).toUpperCase();
			
			// define the combination of this instance with a combo ifThen instance
			if (comboSelection != "ONLY" && comboIfThen != null) {
				comboResult = comboIfThen.getIfThenResult();
				//sResultCombo.text = String(comboResult).toUpperCase();
				interimResult = false;
				switch (comboSelection) {
					case "AND" :
						if (ifThenResult && comboResult) interimResult = true;
						break;
					case "OR" :
						if (ifThenResult || comboResult) interimResult = true;
						break;
					case "XOR" :
						//if (xor(ifThenResult,comboResult)) interimResult = true;
						if (ifThenResult != comboResult) interimResult = true;
						break;
				} 
				ifThenResult = interimResult;
				// fix combo display result
				sResultCombo.text = (String(comboResult).toUpperCase()).substr(0,1);
			}

			if (ifThenResult) { // true
				outputSelection = trueSelection;
				outValue = Number(sTrueVal.text);
				outputHighlight.y = 44;
			} else { // false
				outputSelection = falseSelection;
				outValue = Number(sFalseVal.text);
				outputHighlight.y = 68;
			}
			
			//trace(outputSelection);
			switch (outputSelection) {
				case "NUM" :
					outputValue = outValue;
					break;
				case "IN1" :
					outputValue = inputGatedTrueValue;
					break;
				case "IN2" :
					outputValue = inputGatedFalseValue;
					break;
				case "NONE" :
					outputValue = 0; // never sent
					break;
			}
			//trace(outputValue);
			if (outputSelection != "NONE") ifThenOutput(outputValue);
		}
		
		public function handleComboBox(selectionType:String, selector:ComboBox) { 
			if (selectionType == "ifThenOptions") {
				ruleSelection = selector.selectedItem.data; 
				//trace(ruleSelection);
			} else if (selectionType == "comboOptions") {
				comboSelection = selector.selectedItem.data; 
				if (comboSelection == "ONLY") {
					//sCombo.text = "";
					sOperator.text = "";
					sResultCombo.text = "";
				} else {
					//sCombo.text = addIfThen;
					sOperator.text = comboSelection;
					sResultCombo.text = "--";
				}
					
				//trace(comboSelection);
			} else if (selectionType == "trueOptions") {
				trueSelection = selector.selectedItem.data;
				if (trueSelection == "NONE") sTrueVal.text = "--";
				//trace(trueSelection);
			} else if (selectionType == "falseOptions") {
				falseSelection = selector.selectedItem.data; 
				if (falseSelection == "NONE") sFalseVal.text = "--";
				//trace(falseSelection);
			}

		}
		
		public function waitTimeDone(event:TimerEvent):void {
			//trace("waitTimeDone");
			processInput(Number(sInputValue.text));
			
		}
		
		public function waitTimeBlinkDone(event:TimerEvent):void {
			if (sResult.text == "") sResult.text = waitPending.substr(0,1);
			else sResult.text = "";
		}
		

		
		public function xor(lhs:Boolean, rhs:Boolean):Boolean {
	    	return !( lhs && rhs ) && ( lhs || rhs );
		}
		
		public function getIfThenResult():Boolean {
			return ifThenResult;
		}

		
		override public function draw():void {
			super.draw();
			//sInputSource.text = inputSource;
			
		}
		
		
		//----------------------------------------------------------
		// parameter getter setter functions

		private var _addIfThen:String = "not set";
		[Inspectable (name = "addIfThen", variable = "addIfThen", type = "String", defaultValue="not set")]
		public function get addIfThen():String { return _addIfThen; }
		public function set addIfThen(value:String):void {
			_addIfThen = value;
			//draw();
		}		
		
		private var _inputGatedTrue:String = "not set";
		[Inspectable (name = "inputGatedTrue", variable = "inputGatedTrue", type = "String", defaultValue="not set")]
		public function get inputGatedTrue():String { return _inputGatedTrue; }
		public function set inputGatedTrue(value:String):void {
			_inputGatedTrue = value;
			//draw();
		}		
		
		private var _inputGatedFalse:String = "not set";
		[Inspectable (name = "inputGatedFalse", variable = "inputGatedFalse", type = "String", defaultValue="not set")]
		public function get inputGatedFalse():String { return _inputGatedFalse; }
		public function set inputGatedFalse(value:String):void {
			_inputGatedFalse = value;
			//draw();
		}
		
		private var _nearEqualRange:Number = 25;
		[Inspectable (name = "nearEqualRange", variable = "nearEqualRange", type = "Number", defaultValue=25)]
		public function get nearEqualRange():Number { return _nearEqualRange; }
		public function set nearEqualRange(value:Number):void {
			_nearEqualRange = value;
			//draw();
		}
		
		private var _waitTimeTrue:Number = 0;
		[Inspectable (name = "waitTimeTrue", variable = "waitTimeTrue", type = "Number", defaultValue=0)]
		public function get waitTimeTrue():Number { return _waitTimeTrue; }
		public function set waitTimeTrue(value:Number):void {
			_waitTimeTrue = value;
			//draw();
		}
		
		private var _waitTimeFalse:Number = 0;
		[Inspectable (name = "waitTimeFalse", variable = "waitTimeFalse", type = "Number", defaultValue=0)]
		public function get waitTimeFalse():Number { return _waitTimeFalse; }
		public function set waitTimeFalse(value:Number):void {
			_waitTimeFalse = value;
			//draw();
		}
	}
}