package org.netlabtoolkit {
	
	//import flash.system.Capabilities;
	//import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.events.*;
	
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
	
	public class MomentaryButton extends MovieClip {
  
		private var _text:String;
		private var button:MovieClip;
		private var widget:MovieClip;
		private var buttonType:String;
		
	  
		public function MomentaryButton(button:MovieClip, widget:MovieClip, buttonType:String) {
			
			
			this.button = button;
			this.widget = widget;
			this.buttonType = buttonType;
			text = "off";
			
			button.addEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
			button.addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
			button.buttonMode = true;
		}
		
		private function handleMouseDown(event:Event): void {
			text = "on";
			button.addEventListener(Event.ENTER_FRAME,buttonStillDown); 
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function handleMouseUp(event:Event): void {
			text = "off";
			button.removeEventListener(Event.ENTER_FRAME,buttonStillDown); 
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function buttonStillDown(event:Event):void {
			widget.buttonStillDown(buttonType);
		}
		
		public function setState(value:String):void {
			if (value == "on") {
				_text = "on";
				button.gotoAndStop(2);
			} else { // default to off for off or any other value
				_text = "off";
				button.gotoAndStop(1);
			}
		}
		
		public function get text():String { return _text; }
		public function set text(value:String):void {
			setState(value);
			widget.handleButton(buttonType, text);
		}
	}
}







