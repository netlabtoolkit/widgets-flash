package org.netlabtoolkit {
	
	import flash.system.Capabilities;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import fl.controls.ComboBox; 
	import fl.data.DataProvider;

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
	
	public class ComboBoxSelector extends MovieClip {
  
		private var _text:String;
		private var box:ComboBox;
		private var selections:Array;
		private var widget:MovieClip;
		private var selectionType:String;
		
	  
		public function ComboBoxSelector(box:ComboBox, selections:Array, widget:MovieClip, selectionType:String) {
		//public function ComboBoxSelector(widget:MovieClip, selectionType:String) {
			
			
			this.box = box;
			this.selections = selections;
			this.widget = widget;
			this.selectionType = selectionType;
			//text = "0";
			
			//aCb.dropdownWidth = 210; 
			//selectProperty.width = 75;  
			//aCb.move(150, 50); 
			//aCb.prompt = "San Francisco Area Universities"; 
			box.dataProvider = new DataProvider(selections); 
			//text = "height";
			box.addEventListener(Event.CHANGE, changeSelection);
		}
		
		private function changeSelection(event:Event): void {
			//trace("changeSelection");
			text = String(ComboBox(event.target).selectedItem.data);
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function searchPropertiesArray(assocArray:Array, search:String): int {
			for (var i:int = 0;i<assocArray.length;i++) {
				if (assocArray[i]["data"] == search) return i;
			}
			return -1;
		}
		
		public function get text():String { return _text; }
		public function set text(value:String):void {
			//trace("setting text: " + value);
			_text = value;
			//if (box.selectedItem.data != value) 
			box.selectedIndex = searchPropertiesArray(selections, value);
			widget.handleComboBox(selectionType, box);
		}
	}
}







