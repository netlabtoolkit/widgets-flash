package org.netlabtoolkit {
	
	import flash.system.Capabilities;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
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
	 * along with NETLab Flash Widgets.  If not, see <http://www.gnu.org/licenses/>.
	 */
	
	public class Knob extends MovieClip {
  
		private var knob:MovieClip;
		private var rectangle:Rectangle;
		private var widget:MovieClip;
		public var dragging:Boolean = false;
		
	  
		public function Knob(knob:MovieClip, rectangle:Rectangle, widget:MovieClip) {
			
			
			this.knob = knob;
			this.rectangle = rectangle;
			this.widget = widget;
			
			knob.addEventListener(MouseEvent.MOUSE_DOWN, knobDrag);
			
			
			knob.buttonMode = true;
		}
		
		private function knobDrag(event:Event): void {
			
			knob.startDrag(false,rectangle);
			//knob.addEventListener(MouseEvent.MOUSE_MOVE,knobMoving);
			knob.addEventListener(Event.ENTER_FRAME,knobMoving);
			widget.stage.addEventListener(MouseEvent.MOUSE_UP, knobStopDrag);
			dragging = true;
		}
		
		private function knobStopDrag(event:Event): void {
			
			knob.stopDrag();
			//knob.removeEventListener(MouseEvent.MOUSE_MOVE,knobMoving);
			knob.removeEventListener(Event.ENTER_FRAME,knobMoving);
			widget.stage.removeEventListener(MouseEvent.MOUSE_UP, knobStopDrag);
			dragging = false;
		}
		
		private function knobMoving(event:Event): void {
			//trace("knobmove, rect.height: " + rectangle.height + " knob.y: " + knob.y + " rect.y: " + rectangle.y)
			widget.knobMove(rectangle.height - (knob.y - rectangle.y));
		}
	}
}







