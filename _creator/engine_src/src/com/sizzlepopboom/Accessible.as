//created by Charles Brandt
//www.sizzlepopboom.com
//animateinexile.blogspot.com
//this class available as open source under the GNUv3 license
package com.sizzlepopboom{
	import flash.display.*;
	public class Accessible {
		import flash.accessibility.*;
		import flash.utils.Dictionary;
		import flash.events.KeyboardEvent;
		import flash.events.Event;
		//initially it is undefined so you need to use detectScreenReader to get a usable value
		public static  var reader:Boolean= false;
		private static  var tabArray:Dictionary=new Dictionary;
		//sets tabIndex and increments itself by 5 with each new tabIndex
		private static  var tabSlot:uint=5;
		private static  var startedDetection:Boolean = false;
		//this allows you to access stage
		private static  var flashDoc:*;
		public function Accessible() {
		}
		//****************************************************************************************************
		//This section for keyboard accessibility options
		//****************************************************************************************************
		//If you are changing a tab, check if the old tab is in the dictionary, if it is remove it.
		public static function setTab(item:InteractiveObject, tabNumber:int = -1):void {
			var numIndex:int=tabNumber;
			//handle negative numbers
			if (numIndex>=-1) {
				//if no number is set, use a default
				if (numIndex==-1) {
					numIndex=tabSlot;
					tabSlot+= 5;
				}
				//see if anything is using that tabIndex
				//if not...
				if (tabArray[numIndex] == undefined) {
					item.tabIndex=numIndex;
					tabArray[numIndex]=item;
					//if somthing already occupies that slot
				} else {
					//move the occupant to the next highest slot
					var tabIncrement:*=numIndex;
					var newResident:*=item;
					var oldResident:InteractiveObject;
					while (tabArray[tabIncrement] != undefined) {
						//save and replace the old resident
						oldResident=tabArray[tabIncrement];
						newResident.tabIndex = tabIncrement;
						//update the old item so it will be correct when it is replaced
						oldResident.tabIndex = tabIncrement+1;
						tabArray[tabIncrement]=newResident;
						//make the old resident new for the next slot
						newResident=oldResident;
						tabIncrement++;
					}
					//once it finds an empty slot, place the last item in its new slot
					tabArray[tabIncrement]=newResident;
				}
			} else {
				////trace("The tabIndex for "+item.name+" needs to be a positive number; no index was set.");
			}
		}
		//retrieve the item's current tabIndex; retrieves a -1 is the tabIndex has not been set
		public static function getTab(item:InteractiveObject):int {
			var tabNum:int = item.tabIndex;
			return item.tabIndex;
		}
		//stop tabbing on any object enabled with this class or through the Accessibility panel
		public static function stopTab(item:InteractiveObject):void {
			if (tabArray[item.tabIndex] != null) {
				tabArray[item.tabIndex].tabEnabled=false;
			} else {
				item.tabEnabled=false;
			}
		}
		//start tabbing on an object
		public static function startTab(item:InteractiveObject):void {
			if (tabArray[item.tabIndex] != null) {
				tabArray[item.tabIndex].tabEnabled=true;
			} else {
				item.tabEnabled=true;
			}
		}
		//displays a list of all objects that have tabIndexes assigned through the Accessible class
		public static function showTabList():void{
		}
		//****************************************************************************************************
		//This section for screen reader accessibility options
		//****************************************************************************************************
		//see if a screen reader is running and communicating with Flash
		//Note: it may take the screen reader a short time to show as active,
		//so it's better to test for it on a keyPress to give it time to show up
		//
		public static function detectScreenReader(flashLocation:*):void {
			if (!startedDetection) {
				startedDetection = true;
				flashDoc = flashLocation.stage;
				flashDoc.addEventListener(KeyboardEvent.KEY_DOWN,getReaderStatus);
			}
		}
		//you can listen for a "READER_ACTIVE" event if you want quick notification of screen reader usage
		//EX: someObject.addEventListener.("READER_ACTIVE", someFunction);
		private static function getReaderStatus(event:Event = null):void {
			if (Accessibility.active) {
				reader = true;
				flashDoc.removeEventListener(KeyboardEvent.KEY_DOWN,getReaderStatus);
				flashDoc.dispatchEvent(new Event("READER_ACTIVE",true));
			}else{
				reader = false;
			}
		}
		//returns a boolean of whether as screen reader is detected at the time it is called
		public static function testScreenReader():Boolean {
			getReaderStatus();
			return reader;
		}
		//set the altName of an item
		public static function setName(item:InteractiveObject,altName:String):void {
			var accProps:AccessibilityProperties=new AccessibilityProperties();
			accProps.name=altName;
			item.accessibilityProperties=accProps;
			updateAccessibility();
		}
		//show what screenreader will see as this item's name
		public static function getName(item:InteractiveObject):String {
			try {
				return item.accessibilityProperties.name;
			} catch (err:Error) {
			}
			finally{
				return undefined;
			}
		}
		//set the altDescription of an item
		public static function setDescrip(item:InteractiveObject,altDescrip:String):void {
			var accProps:AccessibilityProperties=new AccessibilityProperties();
			accProps.description=altDescrip;
			item.accessibilityProperties=accProps;
			updateAccessibility();
		}
		//show what screenreader will see as this item's description
		public static function getDescrip(item:InteractiveObject):String {
			try {
				return item.accessibilityProperties.description;
			} catch (err:Error) {
			}
			finally{
				return undefined;
			}
		}
		//set the shortcut keys for an object
		public static function setShortcut(item:InteractiveObject,shortCut:String):void {
			var accProps:AccessibilityProperties=new AccessibilityProperties;
			accProps.shortcut=shortCut;
			item.accessibilityProperties=accProps;
			updateAccessibility();
		}
		//get the shortcut keys for an object
		public static function getShortcut(item:InteractiveObject):String {
			try {
				return item.accessibilityProperties.shortcut;
			} catch (err:Error) {
			}
			finally{
				return undefined;
			}
		}
		//useful for looking up keycodes during development
		public static function keytrace(flashLocation:*):void {
			flashDoc = flashLocation.stage;
			flashDoc.addEventListener(KeyboardEvent.KEY_DOWN,keyPressed);
		}
		//trace the keycode of a pressed button
		private static function keyPressed(e:KeyboardEvent):void {
			////trace(e.keyCode+" was the keycode of the pressed button.");
		}
		//remove any html tags from text so the tags will not be read by the screen reader
		//capitalize and lone "a" or "i"s so the screen reader will pronounce them correctly
		public static function makeReaderFriendly(htmlText:String):String {
			var parseText:String = stripTags(htmlText);
			//Capitalize all " a " and " i " for screenreader correctness
			parseText = parseText.replace(/\sa\s/," A ");
			parseText = parseText.replace(/\si\s/," I ");
			return parseText;
		}
		//strip out any tags and return result
		public static function stripTags(htmlText:String):String{
			return htmlText.replace(/<.*?>/g,"");
		}
		//****************************************************************************************************
		//update the changes recently made to accessibility, updates occur only if a screen reader is detected
		private static function updateAccessibility():void {
			try {
				Accessibility.updateProperties();
			} catch (err:Error) {
				////trace("Screen reader not detected.",err);
			}
		}
	}
}