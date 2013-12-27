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
	
	public class StepperOut extends WidgetOutput { 

		// vars
		
		// buttons
		public var connectButton:ToggleButton;
		public var sendMessageButton:ToggleButton;
		
		// working variables 
		private var timerButtonOff:Timer;
		private var lastInput:Number = -1;
		//private var notePlaying:Boolean = false;
		private var lastOutputValue:String = "none";
		
		// instances of objects on the Flash stage
		//
		// input fields
		public var stepperID:TextField;
		public var stepperPosition:TextField;
		public var stepperSpeed:TextField;

		// output fields
		public var sInputSource:TextField;
		public var sInput:TextField;
		
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
			paramsList.push(["stepperID", "0", "text"]);
			paramsList.push(["stepperPosition", "100", "text"]);
			paramsList.push(["stepperSpeed", "200", "text"]);
			
			// set the name used in the parameters XML
			paramsXMLname = "StepperOut_" + this.name;
			
			// go
			setupParams();
			
			// init vars
			timerButtonOff = new Timer(500, 1);
			timerButtonOff.addEventListener(TimerEvent.TIMER, sendMessageOff);
			
			setUpInputSource();
			setUpInputSourceOther(inputStepperPos, stepperPosHandler);

		}
				
		public function initControllerConnection() {

			theConnection.sendData("/service/tools/serial/connect " + serialPort + " " + serialBaudArduinoFirmata);
		}
		
		override public function handleButton(buttonType:String, buttonState:String) {
			if (buttonType == "sendMessage") {
				if (buttonState == "on") {
					moveStepper();
					//notePlaying = true;
					timerButtonOff.start();
				} 
			} else super.handleButton(buttonType, buttonState);
		}
		
		private function stepperPosHandler( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = event.netFeedValue;
			inputValue = Math.round(inputValue);
			stepperPosition.text = String(inputValue);
			if (continuousPosition) moveStepper();
		}
		
		private function sendMessageOff(e:TimerEvent):void {
			sendMessageButton.text = "off";
			
			//if (notePlaying) {
			//	noteOff();
			//	notePlaying = false;
			//}
		}

		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = Math.round(event.netFeedValue);
			
			if (inputValue >= threshold && lastInput < threshold) {
				moveStepper();
				
				//notePlaying = true;
			} else if (inputValue < threshold && lastInput >= threshold) {
				//if (notePlaying) {
					//noteOff();
					//notePlaying = false;
				//}
			}
			
			sInput.text = String(inputValue);
			lastInput = inputValue;

		}
		
		public function moveStepper(id:Number = -1, position:Number = -1, speed:Number = -1, accelerationIn:Number = -1) {
			if (id != -1) stepperID.text = String(id);
			if (position != -1) stepperPosition.text = String(position);
			if (speed != -1) stepperSpeed.text = String(speed);
			if (accelerationIn == -1) accelerationIn = acceleration;
				
			var stepperMessage = "{" + stepperID.text + " " + stepperPosition.text + " " + stepperSpeed.text + " " + accelerationIn + "}";
			
			sendMessageButton.setState("on");
			timerButtonOff.start();
			if (connectButton.text == "on" && stepperMessage != lastOutputValue && connectionComplete) {
				theConnection.sendData("/service/tools/serial/{" + hubDeviceName + "}/write/ " + stepperMessage);
				lastOutputValue = stepperMessage;
			} else {
				// we're not ready to send output yet, so make sure we send new value (compared to lastOutputValue) out once we are ready
				lastOutputValue = "none";
			}
		}
		

		public function stopStepper(id:Number = -1, speed:Number = -1, accelerationIn:Number = -1) {
			if (id == -1) id = Number(stepperID.text);
			if (speed == -1) speed = Number(stepperSpeed.text);
			if (accelerationIn == -1) accelerationIn = acceleration;
				
			var stepperMessage = "{" + id + " " + 0 + " " + speed + " " + accelerationIn + "}";
			
			sendMessageButton.setState("on");
			timerButtonOff.start();
			if (connectButton.text == "on" && stepperMessage != lastOutputValue && connectionComplete) {
				theConnection.sendData("/service/tools/serial/{" + hubDeviceName + "}/write/ " + stepperMessage);
				lastOutputValue = stepperMessage;
			} else {
				// we're not ready to send output yet, so make sure we send new value (compared to lastOutputValue) out once we are ready
				lastOutputValue = "none";
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
		
		private var _threshold:Number = 500;
		[Inspectable (name = "threshold", variable = "threshold", type = "Number", defaultValue = 500)]
		public function get threshold():Number { return _threshold; }
		public function set threshold(value:Number):void {
			_threshold = value;
			//draw();
		}	
		
		private var _acceleration:Number = 300;
		[Inspectable (name = "acceleration", variable = "acceleration", type = "Number", defaultValue = 300)]
		public function get acceleration():Number { return _acceleration; }
		public function set acceleration(value:Number):void {
			_acceleration = value;
			//draw();
		}	

		private var _inputStepperPos:String = "stepperPos";
		[Inspectable (name = "inputStepperPos", variable = "inputStepperPos", type = "String", defaultValue = "stepperPos")]
		public function get inputStepperPos():String { return _inputStepperPos; }
		public function set inputStepperPos(value:String):void {
			_inputStepperPos = value;
			//draw();
		}		

		private var _continuousPosition:Boolean = true;
		[Inspectable (name = "continuousPosition", variable = "continuousPosition", type = "Boolean", defaultValue = true)]
		public function get continuousPosition():Boolean { return _continuousPosition; }
		public function set continuousPosition(value:Boolean):void {
			_continuousPosition = value;
			//draw();
		}
		
		private var _serialPort:String = "/dev/cu.usb*";
		[Inspectable (name = "serialPort", variable = "serialPort", type = "String", defaultValue = "/dev/cu.usb*")]
		public function get serialPort():String { return _serialPort; }
		public function set serialPort(value:String):void {
			_serialPort = value;
			//draw();
		}
	}
}
