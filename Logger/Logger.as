package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	//import fl.controls.ComboBox; 
	//import fl.data.DataProvider;
	//import fl.transitions.*;
	//import fl.transitions.easing.*;
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
	
	public class Logger extends Widget { 
	
		// vars
		private var _insertInput:Function = insertInputInternal;
		private var _outputValue:Number = 0;
		
		private var startTime:Number = 0;
		private var recordPlayState:String = "stopped";
		private var dataArray:Array;
		private var theTimer:Timer;
		private var playbackIndex:Number = 0;
		private var lastRecordValue:Number;
		private var linefeed:String = "\n";
		private var dataFilePath:FilePath;
		private var xmlSocket = new XMLSocket();
		private var hubIP:String = "localhost";
		
		private var myTextLoader:URLLoader = new URLLoader();

		// buttons
		public var recordButton:ToggleButton;
		public var playbackButton:ToggleButton;

		
		// instances of objects on the Flash stage
		//
		// fields
		public var sInputSource:TextField;
		public var sInputValue:TextField;
		public var sOut:TextField;
		
		
		// buttons
		public var recordBut:MovieClip;
		public var playbackBut:MovieClip;
	
		// objects

		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
			
			dataFilePath = new FilePath(MovieClip(this));
			// record playback init
			recordButton = new ToggleButton(recordBut, this, "record");
			playbackButton = new ToggleButton(playbackBut, this, "playback");
			
			recordBut.stop();
			
			// set up for file writing
			xmlSocket.addEventListener( Event.CONNECT, onConnect );
			
			
			//xmlSocket.addEventListener( Event.CLOSE, onClose );
			
			// init display text fields
			sInputValue.text = "0";
			sOut.text = "0";
			
			// set up the listener for the input source, and draw a line to it
			setUpInputSource();
	
		}
		
		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue:Number = event.netFeedValue;

			
			if (playbackTrigger) {
				sInputValue.text = String(inputValue);
				if (recordPlayState == "stopped" && inputValue >= 500) {
					playbackButton.setState("on");
					startPlay();
				}
				if (recordPlayState == "playing" && inputValue < 500 && playbackLoop) {
					playbackButton.setState("off");
					stopPlay();
				}
			} else if (recordPlayState != "playing") {
				sInputValue.text = String(inputValue);
				insertInput(inputValue, this.name);
			}
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
		
		// code for record/playback data
		
		public function handleButton(buttonType:String, buttonState:String) {
			if (buttonType == "record") {
				if (buttonState == "on") startRecord();
				else if (buttonState =="off") stopRecord();
			} else if (buttonType == "playback") {
				if (buttonState == "on") startPlay();
				else if (buttonState =="off") stopPlay();
			}
		}
		
		public function startRecord() {
			if (recordPlayState == "playing") {
				playbackButton.setState("off");
				stopPlay();
			}
			
			recordButton.setState("on");
			recordPlayState = "recording";
			trace("Recording started...");
			
			startTime = getTimer();
			dataArray = new Array();
			lastRecordValue = NaN;
			
			theTimer = new Timer(recordSampleRate, 0);
			theTimer.addEventListener(TimerEvent.TIMER, recordLog);
			theTimer.start();
		}
		
		public function stopRecord() {
			if (recordPlayState == "recording") {
				theTimer.removeEventListener(TimerEvent.TIMER, recordLog);
				//trace(dataArray);
				recordPlayState = "stopped";
				trace("Recording ended");
				recordButton.setState("off");
				// set up for saving the data
				if (xmlSocket.connected) xmlSocket.close();
				xmlSocket.connect( hubIP, hubPort );
			}
		}
		
		private function recordLog(event:TimerEvent) {
			var relativeTime = getTimer() - startTime;
			var currentDateTime = new Date();
			if (recordSparse) {
				if (lastRecordValue != outputValue) {
					//dataArray.push([outputValue,relativeTime,currentDateTime.toLocaleString()]);
					dataArray.push([outputValue,relativeTime,formattedDateTime()]);
					lastRecordValue = outputValue;
				}
			} else dataArray.push([outputValue,relativeTime,formattedDateTime()]); //dataArray.push([outputValue,relativeTime,currentDateTime.toLocaleString()]);
		}
		
		public function startPlay() {
			if (recordPlayState == "recording") {
				stopRecord();
				recordButton.setState("off");
			}
			if (recordPlayState == "playing") {
				stopPlay();
				playbackButton.setState("off");
			}
			playbackButton.setState("on");
			recordPlayState = "playing";
			//trace("Loading data file...");
			readFile(dataFile);
		}
		
		private function startPlayFinish() {
			
			var firstPlayTime;
			trace("Playback started...");
			
			if (playFromFirstTime) {
				startTime = getTimer() - dataArray[0][1];
				firstPlayTime = 1;
			} else {
				startTime = getTimer();
				firstPlayTime = speedCompensate(dataArray[0][1]);
			}
			playbackIndex = 0;
			//trace(dataArray[0][0]);
			theTimer = new Timer(firstPlayTime, 1);
			theTimer.addEventListener(TimerEvent.TIMER, playLog);
			theTimer.start();
			
		}
		
		public function stopPlay() {
			if (recordPlayState == "playing") {
				theTimer.removeEventListener(TimerEvent.TIMER, playLog);
				trace("Play ended");
				recordPlayState = "stopped"
				playbackButton.setState("off");
			}
		}

		private function playLog(event:TimerEvent) {
			var nextTime = 0;
			//insertOutput(dataArray[playbackIndex][0]);
			insertInput(dataArray[playbackIndex][0], this.name);
				
			playbackIndex++;
			//trace(playbackIndex);
			if (playbackIndex >= dataArray.length) {
				if (playbackLoop) { // reset position to zero
					if (playFromFirstTime) startTime = getTimer() - dataArray[0][1];
					else startTime = getTimer();
					playbackIndex = 0;
					//trace("restart loop");
				} else { // stop playback
					playbackButton.setState("off");
					stopPlay();
					return;
				}
			}
			var relativeTime = getTimer() - startTime;
			while (nextTime == 0) {
				nextTime = Math.round(Math.max(speedCompensate(dataArray[playbackIndex][1]) - relativeTime, 0));
				if (nextTime == 0) {
					playbackIndex++;
					if (playbackIndex >= dataArray.length) {
						if (playbackLoop) { // reset position to zero
							if (playFromFirstTime) startTime = getTimer() - dataArray[0][1];
							else startTime = getTimer();
							relativeTime = 0;
							playbackIndex = 0;
							//trace("restart loop");
						} else { // stop playback
							playbackButton.setState("off");
							stopPlay();
							return;
						}
					}
				}
			}
			//trace(dataArray[playbackIndex][1] + " " + nextTime);
			theTimer.removeEventListener(TimerEvent.TIMER, playLog);
			theTimer = new Timer(nextTime, 1);
			theTimer.addEventListener(TimerEvent.TIMER, playLog);
			theTimer.start();
		}
		
		private function speedCompensate(milliseconds:Number) {
			return Math.round(milliseconds / playbackSpeedX);
		}
			
		// save data to file on completion of record and Hub connection
		private function onConnect( event:Event ):void {
			var dataText:String = "";

			xmlSocket.send('/service/tools/file-io/base "' + dataFilePath.currentDir + '"' + "\n");
			xmlSocket.send('/service/tools/file-io/filename ' + dataFile + "\n");

			for (var i:int=0;i<dataArray.length;i++) {
				dataText = dataArray[i][0] + "," + dataArray[i][1] + "," + dataArray[i][2] + "," + this.name;
				if (i==0) xmlSocket.send('/service/tools/file-io/put {' + dataText + '}' + "\n");
				else xmlSocket.send('/service/tools/file-io/append {' + dataText + '}' + "\n");
				//trace(dataText);
			}
			//xmlSocket.close();
		}
		
		//  functions to handle loading of data for playback
		public function readFile (fileName:String): void {
			myTextLoader.addEventListener(Event.COMPLETE, onFileLoaded);
			myTextLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOError)
			myTextLoader.load(new URLRequest(fileName));
		}
		
		private function onFileLoaded(e:Event):void {
			var dataPoints:Array = new Array();
			dataPoints = (e.target.data).split(linefeed);
			trace("Insert (" + this.name + ") loaded " + dataPoints.length + " data points from " + dataFile);
			var startPoint = dataPoints[0].split(",");
			var endPoint = dataPoints[dataPoints.length - 1].split(",")
			trace("Data/time range: " + startPoint[2] + " to " + endPoint[2]);
			dataArray = new Array();
			for (var i:int = 0; i<dataPoints.length; i++) {
				dataArray.push(dataPoints[i].split(","));
			}
			
			startPlayFinish();
		}
		
		public function onIOError(evt:IOErrorEvent) {
        	trace("Playback error loading data file: "+evt.text);
    	}
		
		private function formattedDateTime():String {
			var dt = new Date();
			var dateTime:String = dt.getFullYear() + "-" + pad((dt.getMonth()+1)) + "-" + pad(dt.getDate()) + " " + pad(dt.getHours()) + ":" + pad(dt.getMinutes()) + ":" + pad(dt.getSeconds()) + ":" + pad(dt.getMilliseconds(),3);
			//trace(dateTime);
			return dateTime;
		}
		
		/**
		* This function will pad the left or right side of any variable passed in
		* elem [AS object]
		* padChar: String
		* finalLength: Number
		* dir: String
		*
		* return String
		*/
		private function pad(elem, finalLength=2, padChar="0", dir="l")
		{
		  //make sure the direction is in lowercase
		  dir = dir.toLowerCase();
		
		  //store the elem length
		  var elemLen = elem.toString().length;
		
		  //check the length for escape clause
		  if(elemLen >= finalLength)
		  {
			return elem;
		  }
		
		  //pad the value
		  switch(dir)
		  {
			default:
			case 'l':
			  return pad(padChar + elem, padChar, finalLength, dir);
			  break;
			case 'r':
			  return pad(elem + padChar, padChar, finalLength, dir);
			  break;
		  }
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
		
		private var _recordSampleRate:Number = 24;
		[Inspectable (name = "recordSampleRate", variable = "recordSampleRate", type = "Number", defaultValue=24)]
		public function get recordSampleRate():Number { return _recordSampleRate; }
		public function set recordSampleRate(value:Number):void {
			_recordSampleRate = value;
			//draw();
		}		
		
		private var _recordSparse:Boolean = true;
		[Inspectable (name = "recordSparse", variable = "recordSparse", type = "Boolean", defaultValue=true)]
		public function get recordSparse():Boolean { return _recordSparse; }
		public function set recordSparse(value:Boolean):void {
			_recordSparse = value;
			//draw();
		}	
		
		private var _playFromFirstTime:Boolean = true;
		[Inspectable (name = "playFromFirstTime", variable = "playFromFirstTime", type = "Boolean", defaultValue=true)]
		public function get playFromFirstTime():Boolean { return _playFromFirstTime; }
		public function set playFromFirstTime(value:Boolean):void {
			_playFromFirstTime = value;
			//draw();
		}	
		
		private var _playbackSpeedX:Number = 1;
		[Inspectable (name = "playbackSpeedX", variable = "playbackSpeedX", type = "Number", defaultValue=1)]
		public function get playbackSpeedX():Number { return _playbackSpeedX; }
		public function set playbackSpeedX(value:Number):void {
			_playbackSpeedX = value;
			//draw();
		}		

		private var _dataFile:String = "datafile.csv";
		[Inspectable (name = "dataFile", variable = "dataFile", type = "String", defaultValue="datafile.csv")]
		public function get dataFile():String { return _dataFile; }
		public function set dataFile(value:String):void {
			_dataFile = value;
			//draw();
		}		
		
		private var _playbackTrigger:Boolean = false;
		[Inspectable (name = "playbackTrigger", variable = "playbackTrigger", type = "Boolean", defaultValue=false)]
		public function get playbackTrigger():Boolean { return _playbackTrigger; }
		public function set playbackTrigger(value:Boolean):void {
			_playbackTrigger = value;
			//draw();
		}
		
		private var _playbackLoop:Boolean = true;
		[Inspectable (name = "playbackLoop", variable = "playbackLoop", type = "Boolean", defaultValue=true)]
		public function get playbackLoop():Boolean { return _playbackLoop; }
		public function set playbackLoop(value:Boolean):void {
			_playbackLoop = value;
			//draw();
		}		
	}
}