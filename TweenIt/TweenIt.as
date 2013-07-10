﻿package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import fl.controls.ComboBox; 
	import fl.data.DataProvider;
	import fl.transitions.*;
	import fl.transitions.easing.*;
	import flash.utils.Timer;
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
	
	public class TweenIt extends Widget { 
			
		// vars
		private var easingMethods:Array;
		private var easingMethod:String;
		public var easingMethodSelector:ComboBoxSelector;
		
		private var easingInOuts:Array;
		private var easingInOut:String;
		public var easingInOutSelector:ComboBoxSelector;
		
		private var easingModes:Array;
		private var easingMode:String;
		public var easingModeSelector:ComboBoxSelector;
		
		// buttons
		
		
		// working variables
		private var lastInputValue:Number = -1000;
		private var theTween:Tween;
		private var _tweenValue:Number;
		private var delayTimer:Timer;
		
		
		// instances of objects on the Flash stage
		//
		// fields
		public var sInputSource:TextField;
		public var sInputValue:TextField;
		public var sThreshold:TextField;
		public var sStart:TextField;
		public var sSeconds:TextField;
		public var sEnd:TextField;
		public var sClipName:TextField;
		public var sOut:TextField;
		
		
		// buttons

		
		// objects
		public var sEasingMethod:ComboBox;
		public var sEasingInOut:ComboBox;
		public var sEasingMode:ComboBox;

		
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
			
			// EASING METHODS SELECTOR
			easingMethods = new Array( 
				{label:"back", data:"Back"}, 
				{label:"bounce", data:"Bounce"}, 
				{label:"elastic", data:"Elastic"}, 
				{label:"regular", data:"Regular"}, 
				{label:"strong", data:"Strong"}, 
				{label:"linear", data:"None"}
			);
			
			// set up the selector
			easingMethodSelector = new ComboBoxSelector(sEasingMethod, easingMethods, this, "easingMethod");
			
			// EASING INOUTS SELECTOR
			easingInOuts = new Array( 
				{label:"in", data:"easeIn"}, 
				{label:"out", data:"easeOut"}, 
				{label:"inOut", data:"easeInOut"}
			);
			
			// set up the selector
			easingInOutSelector = new ComboBoxSelector(sEasingInOut, easingInOuts, this, "easingInOut");
			
			// EASING MODES SELECTOR
			easingModes = new Array( 
				{label:"none", data:"none"}, 
				{label:"return", data:"return"}, 
				{label:"yoyo", data:"yoyo"},
				{label:"loop", data:"loop"},
				{label:"yoloop", data:"yoyoloop"}
			);
			
			// set up the selector
			easingModeSelector = new ComboBoxSelector(sEasingMode, easingModes, this, "easingMode");
			
			// PARAMETERS
			//
			// set up the defaults for this widget's parameters
			paramsList.push(["easingMethodSelector", "Regular", "selector"]);
			paramsList.push(["easingInOutSelector", "easeOut", "selector"]);
			paramsList.push(["easingModeSelector", "return", "selector"]);
			paramsList.push(["sThreshold", "500", "text"]);
			paramsList.push(["sStart", "0", "text"]);
			paramsList.push(["sSeconds", "1.0", "text"]);
			paramsList.push(["sEnd", "500", "text"]);
			
			// set up the defaults for this widget's parameters
			
			// set the name used in the parameters XML
			paramsXMLname = "Tween_" + this.name;
			
			// init display text fields
			sInputValue.text = "0";
			sOut.text = "0.0";
			
			// go
			setupParams();
			
			// set up the listener for the input source, and draw a line to it
			setUpInputSource();
		}

		
		public function handleComboBox(selectionType:String, selector:ComboBox) { 
			//trace("got property change");
			if (selectionType == "easingMethod") easingMethod = selector.selectedItem.data; 
			else if (selectionType == "easingInOut") easingInOut = selector.selectedItem.data;
			else if (selectionType == "easingMode") easingMode = selector.selectedItem.data;
			destroyTween();
		}
		
		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue:Number = event.netFeedValue;
			var threshold:Number = Number(sThreshold.text);
			var tweenFunction:Function;
			var newTime:Number;
			
			switch (easingMethod) {
				
				
				case "Back" :
					tweenFunction = Back[easingInOut];
					break;
				case "Bounce" :
					tweenFunction = Bounce[easingInOut];
					break;
				case "Elastic" :
					tweenFunction = Elastic[easingInOut];
					break;
				case "Regular" :
					tweenFunction = Regular[easingInOut];
					break;
				case "Strong" :
					tweenFunction = Strong[easingInOut];
					break;
				case "None" :
					tweenFunction = None[easingInOut];
					break;
				default:
					tweenFunction = None[easingInOut];
								
			}
			
			sInputValue.text = String(inputValue);
			
			
			
			// check for passing threshold
			if (inputValue >= threshold && lastInputValue < threshold) {

				// kick off tween
				if (theTween == null) {
					theTween = new Tween(this, "tweenValue", tweenFunction, Number(sStart.text), Number(sEnd.text), Number(sSeconds.text), true );
					theTween.addEventListener(TweenEvent.MOTION_FINISH, handleTweenFinish);
					if (easingMode == "loop") theTween.looping = true;
					if (fps > 0) theTween.FPS = fps;
					//theTween.stop();
				} else if (easingMode != "return" && easingMode != "none") {
					theTween.resume();
				} else if (easingMode == "return" && theTween.isPlaying == true) {
					newTime = Number(sSeconds.text)/(theTween.duration/theTween.time);
					//trace("newTime: " + newTime);
					theTween.continueTo(Number(sEnd.text),newTime)
				}
			} else if (inputValue < threshold && lastInputValue >= threshold) {
				if (easingMode == "return") {
																		// this theTween.time works only works right if in full transit
					if (theTween != null && theTween.isPlaying == true) {
						newTime = Number(sSeconds.text)/(theTween.duration/theTween.time);
						//trace("newTime: " + newTime);
						theTween.continueTo(Number(sStart.text),newTime);
					} else { 
						destroyTween();
						theTween = new Tween(this, "tweenValue", tweenFunction, Number(sEnd.text), Number(sStart.text), Number(sSeconds.text), true );
						theTween.addEventListener(TweenEvent.MOTION_FINISH, handleTweenFinish);
						if (fps > 0) theTween.FPS = fps;
					}
				} else if (theTween != null && easingMode != "none" && theTween.isPlaying == true) {
					theTween.stop();
				}
			}
			
			lastInputValue = inputValue;
			
		}
		
		private function handleTweenFinish(event:TweenEvent):void {
			if (easingMode == "yoyo") {
				if (theTween.position == Number(sEnd.text)) theTween.yoyo();
				else destroyTween();
			}
			else if (easingMode == "yoyoloop") theTween.yoyo();
			else destroyTween();
		}
		
		private function destroyTween():void {
			if (theTween != null) {
				theTween.removeEventListener(TweenEvent.MOTION_FINISH, handleTweenFinish);
				theTween = null;
			}
		}
		
		public function processTweenValue(theTweenValue) {
			sOut.text = String(theTweenValue.toFixed(1));
			stage.dispatchEvent(new NetFeedEvent(this.name, 
												 true,
												 false,
												 this,
												 theTweenValue));
		}
		
		override public function draw():void {
			super.draw();
			sInputSource.text = inputSource;
			
		}
		
		// tweenValue getter setter
		public function get tweenValue():Number { return _tweenValue; }
		public function set tweenValue(value:Number):void {
			_tweenValue = value;
			processTweenValue(value);
		}
		
		
		//----------------------------------------------------------
		// parameter getter setter functions
		
		// parameters in alphabetized order		
	
		private var _fps:Number = 0;
		[Inspectable (name = "fps", variable = "fps", type = "Number", defaultValue = 0)]
		public function get fps():Number { return _fps; }
		public function set fps(value:Number):void {
			_fps = value;
			draw();
		}
	}
}
