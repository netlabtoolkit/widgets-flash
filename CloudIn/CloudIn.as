﻿package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
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
	 * along with NETLab Glash Widgets.  If not, see <http://www.gnu.org/licenses/>.
	 */
	
	public class CloudIn extends WidgetBase { 
	
		// parameters in alphabetized order		
			
		// vars
		private var headerType:URLRequestHeader;
		private var headerKey:URLRequestHeader;
		private var urlRequest:URLRequest;
		private var loader:URLLoader = new URLLoader();
		
		private var cloudTimer:Timer;
		private var theTween:Tween;

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
			paramsXMLname = "CloudIn_" + dataFeed + "_" + this.name;
			
			// go
			setupParams();
			
			// set up the HTTP requests depending on the service
			//trace(cloudService);
			switch (cloudService) {
					
				case "xively":
					headerType = new URLRequestHeader("Content-type", "text/csv");
					headerKey = new URLRequestHeader("X-ApiKey",apiKey);
					urlRequest = new URLRequest("http://api.xively.com/v2/feeds/" + channel + ".csv?datastreams=" + dataFeed);
					break;
									
				case "sen.se":
					headerType = new URLRequestHeader("Content-type", "application/json");
					headerKey = new URLRequestHeader("sense_key",apiKey);
					urlRequest = new URLRequest("http://api.sen.se/feeds/" + dataFeed + "/last_event/");
					break;

				case "thingspeak":
					headerType = new URLRequestHeader("Content-type", "application/x-www-form-urlencoded");
					headerKey = new URLRequestHeader("X-THINGSPEAKAPIKEY",apiKey);
					urlRequest = new URLRequest("http://api.thingspeak.com/channels/" + channel + "/field/" + dataFeed + "/last.csv");
					break;
			}

			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = "";
			//urlRequest.authenticate = true;
			urlRequest.requestHeaders.push(headerType);
			urlRequest.requestHeaders.push(headerKey);
			
			configureURLListeners(loader);
			
			// set up the tween for showing refresh time
			theTween = new Tween(sOut, "alpha", None.easeInOut, 1.0, 0.5, sampleRate, true );
			theTween.stop();
			
			// limit the sample rate to 1 second or more
			sampleRate = Math.max(sampleRate, 1.0);
			
			// init display text fields
			sIn.text = "0.0";
			sOut.text = "0.0";
			sTimer.text = String(sampleRate);
				
		}
		

		
		public function handleButton(buttonType:String, buttonState:String) {
			
			if (buttonType == "connect") {
				if (buttonState == "on") tryConnect();
				else if (buttonState =="off") disConnect();
			}
		}
		
		private function tryConnect():void {
			// start timer
			getLastValue();
			cloudTimer = new Timer(Math.round(sampleRate * 1000), 0);
			cloudTimer.addEventListener(TimerEvent.TIMER, getLastValue);
			cloudTimer.start();
			
		}
		
		private function disConnect():void {
			// stop timer
			if (cloudTimer != null) {
				cloudTimer.stop();
				cloudTimer.removeEventListener(TimerEvent.TIMER, getLastValue);
				theTween.stop();
				sOut.alpha = 1;
				sTimer.text = String(sampleRate);
			}
		}
		
		private function startTween():void {
			theTween.start();
			theTween.addEventListener(TweenEvent.MOTION_CHANGE, onTweenChange);
		}
		
		private function onTweenChange(e:TweenEvent):void {
			var current:Number = ((theTween.position - 0.5) * 2) * sampleRate;
			var newVal:String = current.toFixed(1)
			if (newVal != sTimer.text) sTimer.text = newVal;
		}	
		
		public function getLastValue(e:TimerEvent = null):void {
			// send the http request to get a value
			
			try {
				loader.load(urlRequest);
			} catch (error:Error) {
				trace("Unable to load requested document: " + error);
			}
		}
		
		private function dispatchNetEvent(currentValue:Number):void {
			sIn.text = currentValue.toFixed(1);
			sOut.text = currentValue.toFixed(1);
			startTween();
			
			stage.dispatchEvent(new NetFeedEvent(this.name, 
												 true,
												 false,
												 this,
												 currentValue));
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
			var loader:URLLoader = URLLoader(event.target);
			var theValue:String;
			
			var valueIndexStart:int;
			var valueIndexEnd:int;
			var searchStr:String;
			var csvArray:Array;
			
			//trace("completeHandler: " + loader.data);		
			
			switch (cloudService) {
				case "sen.se":
					searchStr = '"value": "';
					valueIndexStart = loader.data.indexOf(searchStr); // find the searchStr in the XML
					valueIndexEnd = loader.data.indexOf('"',valueIndexStart + searchStr.length); // look for the next quote
					theValue = loader.data.substring(valueIndexStart + searchStr.length,valueIndexEnd); // get the value between quotes
					break;
					
				case "xively":
					csvArray = loader.data.split('\n'); // get the lines of data into array
					csvArray = csvArray[0].split(','); // split the first line by comma
					theValue = csvArray[2]; // get the third item
					break;
					
				case "thingspeak":
					csvArray = loader.data.split('\n'); // get the lines of data into array
					csvArray = csvArray[1].split(','); // split the second line by comma
					theValue = csvArray[2]; // get the third item
					break;
			}
			
			dispatchNetEvent(Number(theValue));

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
			startTween();
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
		[Inspectable (name = "cloudService", variable = "cloudService", type = "String", enumeration="xively,thingspeak,sen.se", defaultValue="xively")]
		public function get cloudService():String { return _cloudService; }
		public function set cloudService(value:String):void {
			_cloudService = value;
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
