﻿package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import flash.net.URLLoader;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.Timer;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent; 

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
	
	public class CloudOut extends Widget { 	
			
		// vars
		private var lastToggleValue:Number = 0;
		private var lastToggleValueDecrement:Number = 0;
		private var currentValue:Number = 0;
		
		private var headerType:URLRequestHeader;
		private var headerKey:URLRequestHeader;
		private var urlRequest:URLRequest;
		private var loader:URLLoader = new URLLoader();
		
		private var cloudTimer:Timer;
		private var theTween:Tween;
		
		private var inputCount:int = 0;
		private var inputLast:Number = NaN;
		private var inputCumulative:Number = 0;
		private var inputAverage:Number = 0;

		// buttons
		public var connectButton:ToggleButton;
		
		// working variables
		
		// instances of objects on the Flash stage
		//
		// fields
		public var sInputSource:TextField;
		public var sIn:TextField;
		public var sOut:TextField;
		public var sChannel:TextField;
		public var sDataFeed:TextField;
		public var sTimer:TextField;
		
		// buttons
		public var connect:MovieClip;
		
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
			
			
			// set up the defaults for this widget's parameters
			paramsList.push(["connectButton", "off", "button"]);
			
			// set the name used in the parameters XML
			paramsXMLname = "CloudOut_" + dataFeed + "_" + this.name;
			
			// go
			setupParams();
			
			// set up the HTTP requests depending on the service
			//trace(cloudService);
			switch (cloudService) {
					
				case "xively":
					headerType = new URLRequestHeader("Content-type", "text/csv");
					headerKey = new URLRequestHeader("X-ApiKey",apiKey);
					urlRequest = new URLRequest("http://api.xively.com/v2/feeds/" + channel + "?_method=put");
					break;
				
				case "sen.se":
					headerType = new URLRequestHeader("Content-type", "application/json");
					headerKey = new URLRequestHeader("sense_key",apiKey);
					urlRequest = new URLRequest("http://api.sen.se/events/");
					break;

				case "thingspeak":			
					headerType = new URLRequestHeader("Content-type", "application/x-www-form-urlencoded");
					headerKey = new URLRequestHeader("X-THINGSPEAKAPIKEY",apiKey);
					urlRequest = new URLRequest("https://api.thingspeak.com/update");
					break;
			}

			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = "";
			urlRequest.requestHeaders.push(headerType);
			urlRequest.requestHeaders.push(headerKey);
			
			configureURLListeners(loader);
			
			// set up the tween for showing refresh time
			theTween = new Tween(sOut, "alpha", None.easeInOut, 1.0, 0.5, sampleRate, true );
			theTween.stop();
			theTween.addEventListener(TweenEvent.MOTION_CHANGE, onTweenChange);
			
			// limit the sample rate to 1 second or more
			sampleRate = Math.max(sampleRate, 1.0);
			
			// init display text fields
			sIn.text = "0.0";
			sOut.text = "0.0";
			sTimer.text = String(sampleRate);
			
			setUpInputSource();
				
		}
		
		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue:Number = event.netFeedValue;
			
			sIn.text = inputValue.toFixed(1);
			inputLast = inputValue;
			inputCumulative += inputValue;
			inputCount++;
			inputAverage = inputCumulative / inputCount;
			
			if (feedType == "average") sOut.text = inputAverage.toFixed(1);
			else if (feedType == "last") sOut.text = inputLast.toFixed(1);

		}
		
		public function handleButton(buttonType:String, buttonState:String) {
			
			if (buttonType == "connect") {
				if (buttonState == "on") tryConnect();
				else if (buttonState =="off") disConnect();
			}
		}
		
		private function tryConnect():void {
			// start timer
			//setValue();
			startTween();
			cloudTimer = new Timer(Math.round(sampleRate * 1000), 0);
			cloudTimer.addEventListener(TimerEvent.TIMER, setValue);
			cloudTimer.start();
			
		}
		
		private function disConnect():void {
			// stop timer
			if (cloudTimer != null) {
				cloudTimer.stop();
				cloudTimer.removeEventListener(TimerEvent.TIMER, setValue);
				theTween.stop();
				sOut.alpha = 1;
				sTimer.text = String(sampleRate);
			}
		}
		
		private function resetAverage() {
			if (!isNaN(inputLast)) {
				inputCount = 1;
				inputCumulative = inputLast;
			} else {
				inputCount = 0;
				inputCumulative = 0;
				inputLast = 0;
			}
		}
		
		private function startTween():void {
			resetAverage();
			theTween.start();
			//theTween.addEventListener(TweenEvent.MOTION_CHANGE, onTweenChange);
		}
		
		private function onTweenChange(e:TweenEvent):void {
			var current:Number = ((theTween.position - 0.5) * 2) * sampleRate;
			var newVal:String = current.toFixed(1)
			if (newVal != sTimer.text) sTimer.text = newVal;
		}	
		
		public function setValue(e:TimerEvent = null):void {
			// send the http request to send a value
			
			
			switch (cloudService) {
					
				case "xively":
					// feed = "CloudOut," + lastValue;
					if (feedType == "average") urlRequest.data = dataFeed + "," + inputAverage;
					else if (feedType == "last") urlRequest.data = dataFeed + "," + inputLast;
					break;
					
				case "sen.se":
					if (feedType == "average") urlRequest.data = '{ "feed_id" : ' + dataFeed + ', "value" : "' + inputAverage + '"}';
					else if (feedType == "last") urlRequest.data = '{ "feed_id" : ' + dataFeed + ', "value" : "' + inputLast + '"}';
					break;
					
				case "thingspeak":
					// "field1=" + lastValue;
					if (feedType == "average") urlRequest.data = "field" + dataFeed + "=" + inputAverage;
					else if (feedType == "last") urlRequest.data = "field" + dataFeed + "=" + inputLast;
					break;
			}
			
			//trace(urlRequest.data);
			
			try {
				loader.load(urlRequest);
			} catch (error:Error) {
				trace("Unable to load requested document: " + error);
			}
			
			startTween();
		}
		
		private function configureURLListeners(dispatcher:IEventDispatcher):void {
			dispatcher.addEventListener(Event.COMPLETE, completeHandler);
			dispatcher.addEventListener(Event.OPEN, openHandler);
			dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		
		private function completeHandler(event:Event):void {
			//trace("completeHandler: " + event);
		}
			
		private function openHandler(event:Event):void {
			//trace("openHandler: " + event);
		}
		
		private function progressHandler(event:ProgressEvent):void {
			//trace("progressHandler loaded:" + event.bytesLoaded + " total: " + event.bytesTotal);
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			trace("securityErrorHandler: " + event);
		}
		
		private function httpStatusHandler(event:HTTPStatusEvent):void {
			//trace("httpStatusHandler: " + event);
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void {
			trace("ioErrorHandler: " + event);
		}
		
		override public function draw():void {
			super.draw();
			sInputSource.text = cloudService;
			sChannel.text = channel;
			sDataFeed.text = dataFeed;
			sTimer.text = String(Math.max(sampleRate, 1.0));
			
		}
		
		//----------------------------------------------------------
		// parameter getter setter functions
		private var _cloudService:String = "xively";
		[Inspectable (name = "cloudService", variable = "cloudService", type = "String", enumeration="xively,sen.se,thingspeak", defaultValue="xively")]
		public function get cloudService():String { return _cloudService; }
		public function set cloudService(value:String):void {
			_cloudService = value;
			draw();
		}
		
		private var _feedType:String = "last";
		[Inspectable (name = "feedType", variable = "feedType", type = "String", enumeration="last,average", defaultValue="last")]
		public function get feedType():String { return _feedType; }
		public function set feedType(value:String):void {
			_feedType = value;
			draw();
		}
		
		private var _channel:String = "none";		
		[Inspectable (name = "channel", variable = "channel", type = "String", defaultValue = "none")]	
		public function get channel():String { return _channel; }
		public function set channel(value:String):void {
			_channel = value;
			draw();
		}
		
		private var _dataFeed:String = "1";		
		[Inspectable (name = "dataFeed", variable = "dataFeed", type = "String", defaultValue = "1")]	
		public function get dataFeed():String { return _dataFeed; }
		public function set dataFeed(value:String):void {
			_dataFeed = value;
			draw();
		}
		
		private var _apiKey:String = "none";		
		[Inspectable (name = "apiKey", variable = "apiKey", type = "String", defaultValue = "none")]	
		public function get apiKey():String { return _apiKey; }
		public function set apiKey(value:String):void {
			_apiKey = value;
			draw();
		}
				
		private var _sampleRate:Number = 15;
		[Inspectable (name = "sampleRate", variable = "sampleRate", type = "Number", defaultValue = 15)]
		public function get sampleRate():Number { return _sampleRate; }
		public function set sampleRate(value:Number):void {
			_sampleRate = value;
			//draw();
		
		}
	}
}
