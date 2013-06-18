/* See the file "LICENSE.txt" for the full license governing this code. */
package ui.questionScreen
{
	import com.sizzlepopboom.Accessible;
	import flash.display.Sprite;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import Engine;
	import events.EnigmaEvents;
	import flash.events.MouseEvent;

	public class MCAnswers extends Sprite
	{

		private var _radioArray:Array;
		private var _selectedRadio:*;
		private var _focusRadio:*;
		private var _focusRadioMC:MCRadio;
		private var _reviewSelectedRadio:int;
		private var _reviewMode:Boolean;

		public function MCAnswers(answers:Array, reviewMode:Boolean=false, reviewSelectedRadio:int=-1)
		{
			this.buttonMode = true;
			this._reviewMode = reviewMode;
			this._reviewSelectedRadio = reviewSelectedRadio;
			if(answers != null) createRadioList(answers, answers.length);
			if (!_reviewMode) addEventListener(KeyboardEvent.KEY_DOWN, keyEventHandler, false, 0, true);
		}

		public function createRadioList(answers:Array, numToCreate:int):void
		{
			_radioArray = new Array();
			var newRadio:MCRadio;
			var previousRadioY:Number = 0;
			var radioWidth:int = 568;
			var answer:Object

			for (var i:int; i < numToCreate; i++)
			{
				answer = answers[i]
				if (i == _reviewSelectedRadio && _reviewMode == true)
				{
					var feedback:String
					if (answer.hasOwnProperty('options') && answer.options != null && answer.options.hasOwnProperty("feedback")) feedback = answer.options.feedback;
					else feedback = randomFeedback(Number(answer.value) == 100);

					newRadio = new MCRadio(i, radioWidth, answer.text, answer.value, true, true, feedback);
				}
				else if (_reviewMode == true)
				{
				 	newRadio = new MCRadio(i, radioWidth, answer.text, answer.value, true);
				}
				else
				{
					newRadio = new MCRadio(i, radioWidth, answer.text, answer.value);
				}

				addChild(newRadio);
				newRadio.y=previousRadioY;
				previousRadioY += newRadio.height+6;
				newRadio.x=20;

				if (!_reviewMode)
				{
					newRadio.addEventListener(MouseEvent.CLICK, radioClicked, false, 0, true);
					newRadio.addEventListener(FocusEvent.FOCUS_IN, focusInHandler, false, 0, true);
				}
				_radioArray.push(newRadio);
				Accessible.setTab(newRadio);
			}
		}

		private function randomFeedback(isGood:Boolean = false):String
		{
			return isGood ? "You answered correctly, good job!" :  "Incorrect.";
		}

		private function radioClicked(event:MouseEvent):void
		{
			for(var i:int = 0; i < _radioArray.length; i++)
			{
				if (_radioArray[i] != null)
				{
					_radioArray[i].hideInnerCircle();
					if (_radioArray[i] == event.currentTarget)
					{
						_radioArray[i].showInnerCircle();
						_selectedRadio = _radioArray[i]._radioNumber;
						dispatchEvent(new EnigmaEvents(EnigmaEvents.RADIO_CLICKED, {selected:_selectedRadio}, true));
					}
				}
			}
		}

		private function focusInHandler(event:FocusEvent):void
		{
			for(var i:int = 0; i < _radioArray.length; i++)
			{
				if (_radioArray[i] != null)
				{
					if (_radioArray[i] == event.currentTarget)
					{
						_focusRadioMC = _radioArray[i];
						_focusRadio = _radioArray[i]._radioNumber;
					}
				}
			}
		}

		private function clearInnerCircles():void
		{
			for(var i:int = 0; i < _radioArray.length; i++)
			{
				if (_radioArray[i] != null) _radioArray[i].hideInnerCircle();
			}
		}

		private function keyEventHandler(event:KeyboardEvent):void
		{
			if (event.keyCode == Keyboard.SPACE)
			{
				_selectedRadio = _focusRadio;
				clearInnerCircles();
				_focusRadioMC.showInnerCircle();
				Engine.playSound("down");
				dispatchEvent(new EnigmaEvents(EnigmaEvents.RADIO_CLICKED, {selected:_selectedRadio}, true));
			}
		}
	}
}