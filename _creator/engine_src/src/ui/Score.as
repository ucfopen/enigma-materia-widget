/* See the file "LICENSE.txt" for the full license governing this code. */
package ui
{
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.Timer;
	import flash.text.TextFieldAutoSize;	;
	public class Score extends Sprite
	{
		private var _scoreText:TextField;
		private var _score:int;
		private var _updatedScore:int;
		private var _countTimer:Timer;
		private var _scoreTextFormat:TextFormat;
		private var _width:Number;
		private var _height:Number;
		private var _scoreValueSize:Number;
		//Embeds the swf that contains the Century Gothic font and sets it to be bold
		[Embed( source="/assets/EnigmaAssets.swf", fontFamily="Century Gothic", fontWeight="Bold" )]
		private var cellFont:String;
		public function Score(width:Number, height:Number)
		{
			this._width = width;
			this._height = height;
			graphics.clear();
			graphics.beginFill(0x000000, 0);
			graphics.drawRect(0,0, _width, _height);
			graphics.endFill();
			_score = 0;
			_scoreText = new TextField();
			_scoreText.width = _width;
			_scoreText.height = _height;
			_scoreText.embedFonts = true;
			_scoreText.selectable = false;
			_scoreText.text = _score+"%";
			_scoreTextFormat = new TextFormat("Century Gothic", 200, 0xFFFFFF, true);
			_scoreText.autoSize = TextFieldAutoSize.CENTER;
			_scoreText.defaultTextFormat = _scoreTextFormat;
			addChild(_scoreText);
			resizeScoreText();
		}
		public function newValue(newValue:int):void
		{
			_updatedScore = newValue;
			_countTimer = new Timer(7);
			_countTimer.addEventListener(TimerEvent.TIMER, updateScoreValue);
			_countTimer.start();
		}
		private function updateScoreValue(event:TimerEvent):void
		{
			_scoreText.text = _score+"%";
			if (_scoreText.width > (this._width)) {
				resizeScoreText();
			}
			if (_updatedScore > _score)
			{
				_score++;
			}
			else if (_updatedScore < _score)
			{
				_score--;
			}
			else
			{
				_countTimer.removeEventListener(TimerEvent.TIMER, updateScoreValue);
			}
		}
		public function setScoreValue(newValue:int):void
		{
			_score = newValue;
			_updatedScore = newValue;
		}
		public function resizeScoreText():void
		{
			var tf:TextFormat;
			_scoreValueSize = 100;
			////trace(""+_scoreText.height+" "+_height);
			while(_scoreText.width > this._width || _scoreText.height > (this._height) )
			{
				tf = new TextFormat();
				tf.size = _scoreValueSize--;
				_scoreText.setTextFormat(tf);
				tf.align = TextFormatAlign.CENTER;
				_scoreText.y = (_height - _scoreText.height)/2;
			}
			////trace(""+_scoreValueSize);
		}
	}
}