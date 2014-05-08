package org.netlabtoolkit { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import flash.geom.Rectangle;
	import flash.utils.*;
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
	
	public class WidgetOutputController extends WidgetOutput { 
		
		// vars
		
		// working variables 
		
		// delay connection
		private var connectDelayTimer:Timer;
		private var randomDelay:int;
		
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
			
			//serialDeviceName = serialNameShort(serialPort);
		}
		
		//----------------------------------------------------------
		// parameter getter setter functions
		
		// parameters
		
		private var _controllerIP:String = "127.0.0.1";
		[Inspectable (name = "controllerIP", variable = "controllerIP", type = "String", defaultValue = "127.0.0.1")]
		public function get controllerIP():String { return _controllerIP; }
		public function set controllerIP(value:String):void {
			_controllerIP = value;
			//draw();
		}
		
		private var _controllerPort:Number = 10000;
		[Inspectable (name = "controllerPort", variable = "controllerPort", type = "Number", defaultValue = 10000)]
		public function get controllerPort():Number { return _controllerPort; }
		public function set controllerPort(value:Number):void {
			_controllerPort = value;
			//draw();
		}		
		
		/*
		private var _controllerOutputNum:Number = 0;
		[Inspectable (name = "controllerOutputNum", variable = "controllerOutputNum", type = "Number", defaultValue = 0)]
		public function get controllerOutputNum():Number { return _controllerOutputNum; }
		public function set controllerOutputNum(value:Number):void {
			_controllerOutputNum = value;
			draw();
		}	
		*/
		
		private var _serialPort:String = "/dev/cu.usb*";
		[Inspectable (name = "serialPort", variable = "serialPort", type = "String", defaultValue = "/dev/cu.usb*")]
		public function get serialPort():String { return _serialPort; }
		public function set serialPort(value:String):void {
			_serialPort = value;
			//draw();
		}
		
		private var _multiplier:Number = 1;
		[Inspectable (name = "multiplier", variable = "multiplier", type = "Number", defaultValue = 1)]
		public function get multiplier():Number { return _multiplier; }
		public function set multiplier(value:Number):void {
			_multiplier = value;
			//draw();
		}		
		
		private var _hubFeedName:String = "feed0";		
		[Inspectable (name = "hubFeedName", variable = "hubFeedName", type = "String", defaultValue = "feed0")]	
		public function get hubFeedName():String { return _hubFeedName; }
		public function set hubFeedName(value:String):void {
			_hubFeedName = value;
			draw();
		}
		
	}
}
