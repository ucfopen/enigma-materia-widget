/* See the file "LICENSE.txt" for the full license governing this code. */
package events
{
	import flash.events.Event;
	/**
	* ...
	* @author DefaultUser (Tools -> Custom Arguments...)
	*/
	public class EnigmaEvents extends Event
	{
		public static const CELL_CLICKED:String = "cellClicked";
		public static const BUTTON_CLICKED:String = "buttonClicked";
		public static const RADIO_CLICKED:String = "radioClicked";
		public static const OPENED_QUESTION_SCREEN:String = "openedQuestionScreen";
		public static const CLOSED_QUESTION_SCREEN:String = "closedQuestionScreen";
		public static const CELL_TAB_FOCUS:String = "cellTabFocus";
		public static const MUTE_BUTTON_CLICKED:String = "muteButtonClicked";
		public var data:Object;
		public function EnigmaEvents(type:String, data:Object = null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.data = data;
			super(type, bubbles, cancelable);
		}
		public override function clone():Event
		{
			return new EnigmaEvents(type, data, bubbles, cancelable);
		}
		public override function toString():String
		{
			return formatToString("EnigmaEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
	}
}