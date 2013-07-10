package org.netlabtoolkit {
	
	import flash.events.*;
	import flash.display.MovieClip;
	
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

	public class NetFeedEvent extends Event {
		// A constant for the "NETFEED" event type
		public static const NETFEED:String = "netFeed_";

    	// vars
		public var widget:MovieClip;
		public var netFeedValue:Number;
    
		// Constructor
		public function NetFeedEvent (type:String,
										   bubbles:Boolean = false,
										   cancelable:Boolean = false,
										   widget:MovieClip = null,
										   netFeedValue:Number = 0) {
			// Pass constructor parameters to the superclass constructor
			super(type, bubbles, cancelable);
		  
			// Store the netFeedEvent switch's state so it can be accessed within
			// netFeedEventEvent.netFeedEvent listeners
			this.widget = widget;
			this.netFeedValue = netFeedValue;
    	}

		// Every custom event class must override clone()
		public override function clone():Event {
			return new NetFeedEvent(type, bubbles, cancelable, widget, netFeedValue);
		}
	
		// Every custom event class must override toString().
		public override function toString():String { 
			return formatToString("netFeedEvent", "type", "bubbles","cancelable", "eventPhase", "widget", "netFeedValue");
		}
	}
}