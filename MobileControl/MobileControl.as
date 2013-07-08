﻿package { 	import flash.display.MovieClip;	import flash.events.*;	import flash.utils.*;	import flash.text.TextField;	import flash.display.DisplayObjectContainer;	import flash.display.DisplayObject;	import org.netlabtoolkit.*;		/**	 * @author Philip van Allen, pvaj@philvanallen.com, The New Ecology of Things Lab, Art Center College of Design	 * 	 * thanks to the component example by David Barlia david@barliesque.com	 * http://studio.barliesque.com/blog/2008/12/as3-component-custom-ui/	 * which was based on earlier work	 * http://flexion.wordpress.com/2007/06/27/building-flash-cs3-components/	 * 	 */	public class MobileControl extends WidgetBase { 			// vars		private var connectDelayTimer:Timer;				// buttons						// working variables						// instances of objects on the Flash stage		//		// fields		public var ip:TextField;				// buttons				// objects		public var mainButton:MovieClip;		public var interfaceBg:MovieClip;				// inherit constructor, so we don't need to create one		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {			//super(w,h);		//} 						// functions				override public function setupAfterLoad( event:Event ): void {			super.setupAfterLoad(event);						mainButton.buttonMode = true;			ip.text = defaultIP;						if (autoConnect) {				connectDelayTimer = new Timer(2000, 1);				connectDelayTimer.addEventListener(TimerEvent.TIMER, finishConnect);				connectDelayTimer.start();				mainButton.buttonText.text = "Connecting..."			}					}				public function setShow(type:String):void {			switch (type){				case "full":					this.alpha = 1.0;					mainButton.alpha = 1.0;					interfaceBg.alpha = 1.0;					break;								case "minimal":					this.alpha = 1.0;					mainButton.alpha = 1.0;					interfaceBg.alpha = 0.0;					break;									case "defaultHide":					if (hideAll) setShow("none");					else setShow("minimal");					break;								case "none":					this.alpha = 0;					break;			}		}				public function finishConnect(event:TimerEvent) {			mainButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));			//mainButton.buttonText.text = "Connected";		}				override public function draw():void {			super.draw();			//trace("in draw");			ip.text = defaultIP;		}						//----------------------------------------------------------		// parameter getter setter functions				private var _defaultIP:String = "10.0.1.1";		[Inspectable (name = "defaultIP", variable = "defaultIP", type = "String", defaultValue="10.0.1.1")]		public function get defaultIP():String { return _defaultIP; }		public function set defaultIP(value:String):void {			_defaultIP = value;			draw();		}						private var _hideAll:Boolean = true;		[Inspectable (name = "hideAll", variable = "hideAll", type = "Boolean", defaultValue=true)]		public function get hideAll():Boolean { return _hideAll; }		public function set hideAll(value:Boolean):void {			_hideAll = value;			//draw();		}				private var _autoConnect:Boolean = false;		[Inspectable (name = "autoConnect", variable = "autoConnect", type = "Boolean", defaultValue=false)]		public function get autoConnect():Boolean { return _autoConnect; }		public function set autoConnect(value:Boolean):void {			_autoConnect = value;			//draw();		}	}}