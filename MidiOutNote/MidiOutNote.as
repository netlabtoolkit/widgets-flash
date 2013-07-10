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
	 * along with NETLab Flash Widgets.  If not, see <http://www.gnu.org/licenses/>.
	 */
	
	public class MidiOutNote extends WidgetOutput { 

		// vars
		
		// buttons
		public var connectButton:ToggleButton;
		public var sendMessageButton:ToggleButton;
		
		// working variables 
		private var oscMsg:String = "/service/osc/reader-writer/mediacontrol/midiout/note/data";
		private var timerButtonOff:Timer;
		private var lastInput:Number = -1;
		private var notePlaying:Boolean = false;
		private var lastNoteNum:Number = -1;
		
		// instances of objects on the Flash stage
		//
		// input fields
		public var sMidiChannel:TextField;
		public var sMidiNote:TextField;
		public var sMidiVelocity:TextField;

		// output fields
		public var sInputSource:TextField;
		public var sInput:TextField;
		public var sOut:TextField;
		
		// buttons
		public var connect:MovieClip;
		public var sendMessage:MovieClip;
		
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
			sendMessageButton = new ToggleButton(sendMessage, this, "sendMessage");
			// PARAMETERS
			//
			
			// set up the defaults for this widget's parameters
			paramsList.push(["connectButton", "off", "button"]);
			paramsList.push(["sMidiChannel", "1", "text"]);
			paramsList.push(["sMidiNote", "64", "text"]);
			paramsList.push(["sMidiVelocity", "127", "text"]);
			
			// set the name used in the parameters XML
			paramsXMLname = "MidiOutputNote_" + this.name;
			
			// go
			setupParams();
			
			// init vars
			timerButtonOff = new Timer(500, 1);
			timerButtonOff.addEventListener(TimerEvent.TIMER, sendMessageOff);
			
			setUpInputSource();
			setUpInputSourceOther(inputNoteNum, noteNumHandler);

		}
				
		public function initControllerConnection() {
			theConnection.sendData("/service/osc/reader-writer/connect " + mediaControlPort + " " + mediaControlIP);
			//theConnection.sendData("/service/osc/reader-writer/nlhubconfig/connect " + mediaControlIP + ":" + mediaControlPort + " " + String(mediaControlPort + 1));
		}
		
		override public function handleButton(buttonType:String, buttonState:String) {
			if (buttonType == "sendMessage") {
				if (buttonState == "on") {
					noteOn();
					notePlaying = true;
					timerButtonOff.start();
				} 
			} else super.handleButton(buttonType, buttonState);
		}
		
		private function noteNumHandler( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = event.netFeedValue;
			
			inputValue = Math.round(inputValue);
			inputValue = Math.min(inputValue, 127);
			inputValue = Math.max(inputValue, 0);
			
			sMidiNote.text = String(inputValue);
			if (inputNotePlay && inputValue != lastNoteNum) {
				noteOn();
				//notePlaying = true;
				//timerButtonOff.start();
			}
			lastNoteNum = inputValue;
		}
		
		private function sendMessageOff(e:TimerEvent):void{
			sendMessageButton.text = "off";
			if (notePlaying) {
				noteOff();
				notePlaying = false;
			}
		}

		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = Math.round(event.netFeedValue);
			
			if (inputValue >= threshold && lastInput < threshold) {
				noteOn();
				//notePlaying = true;
			} else if (inputValue < threshold && lastInput >= threshold) {
				//if (notePlaying) {
					noteOff();
					notePlaying = false;
				//}
			}
			
			sInput.text = String(inputValue);
			lastInput = inputValue;

		}
		
		public function noteOn(midiNote:Number = -1, midiVelocity:Number = -1, midiChannel:Number = -1) {
			if (midiChannel != -1) sMidiChannel.text = String(midiChannel);
			if (midiNote != -1) sMidiNote.text = String(midiNote);
			if (midiVelocity != -1) sMidiVelocity.text = String(midiVelocity);
			sendMessageButton.setState("on");
			
			if (connectButton.text == "on" && connectionComplete) { // send midi if we are connected to OSC device
				// "/service/osc/reader-writer/mediacontrol/midiout/note/data"
				theConnection.sendData("/service/osc/reader-writer/" + mediaControlIP + ":" + mediaControlPort + "/mediacontrol/midiout/note/data " + sMidiNote.text + " " + sMidiVelocity.text + " " + sMidiChannel.text);
				//theConnection.sendData(oscMsg + " "+ sMidiNote.text + " " + sMidiVelocity.text + " " + sMidiChannel.text);
			}		
		}
		
		public function noteOff(midiNote:Number = -1, midiChannel:Number = -1) {
			
			if (midiChannel != -1) sMidiChannel.text = String(midiChannel);
			if (midiNote != -1) sMidiNote.text = String(midiNote);
			sendMessageButton.setState("off");

			if (connectButton.text == "on" && connectionComplete) { // send midi if we are connected to OSC device
				theConnection.sendData("/service/osc/reader-writer/" + mediaControlIP + ":" + mediaControlPort + "/mediacontrol/midiout/note/data " + sMidiNote.text + " 0 " + sMidiChannel.text);
				//theConnection.sendData(oscMsg + " " + sMidiNote.text + " " + 0 + " " + sMidiChannel.text);
			}
			
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
		}
		
				
		//----------------------------------------------------------
		// parameter getter setter functions
		
		private var _mediaControlIP:String = "127.0.0.1";
		[Inspectable (name = "mediaControlIP", variable = "mediaControlIP", type = "String", defaultValue = "127.0.0.1")]
		public function get mediaControlIP():String { return _mediaControlIP; }
		public function set mediaControlIP(value:String):void {
			_mediaControlIP = value;
			//draw();
		}		

		private var _mediaControlPort:Number = 51010;
		[Inspectable (name = "mediaControlPort", variable = "mediaControlPort", type = "Number", defaultValue = 51010)]
		public function get mediaControlPort():Number { return _mediaControlPort; }
		public function set mediaControlPort(value:Number):void {
			_mediaControlPort = value;
			//draw();
		}		

		private var _threshold:Number = 500;
		[Inspectable (name = "threshold", variable = "threshold", type = "Number", defaultValue = 500)]
		public function get threshold():Number { return _threshold; }
		public function set threshold(value:Number):void {
			_threshold = value;
			//draw();
		}		

		private var _inputNoteNum:String = "inputNoteNum";
		[Inspectable (name = "inputNoteNum", variable = "inputNoteNum", type = "String", defaultValue = "inputNoteNum")]
		public function get inputNoteNum():String { return _inputNoteNum; }
		public function set inputNoteNum(value:String):void {
			_inputNoteNum = value;
			//draw();
		}		

		private var _inputNotePlay:Boolean = true;
		[Inspectable (name = "inputNotePlay", variable = "inputNotePlay", type = "Boolean", defaultValue = true)]
		public function get inputNotePlay():Boolean { return _inputNotePlay; }
		public function set inputNotePlay(value:Boolean):void {
			_inputNotePlay = value;
			//draw();
		}
	}
}
