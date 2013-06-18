/* See the file "LICENSE.txt" for the full license governing this code. */
package ui.questionScreen
{
	import flash.display.CapsStyle;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import Engine;
	public class MCRadio extends Sprite
	{
		private var _width:Number;
		private var _answer:TextField;
		private var _answerText:String;
		private var _valueNum:Number;
		private var _answerTextFormat:TextFormat;
		private const BORDER_COLOR:int = 0x000000;
		private const BG_COLOR:int = 0xFFFFFF;
		private const ANSWER_TEXT_COLOR:int = 0x343434;
		private var _innerCircle:Sprite;
		private var _outerCircle:Sprite;
		private var _indentRadio:Boolean;
		private var _feedbackText:String;
		private var _startSelected:Boolean;
		public var _radioNumber:int;
		private var _gradePercentage:TextField;
		private var _gradePercentageFormat:TextFormat;
		public static const RADIO_DIAMETER:int = 14;
		private var vectorX:Sprite;
		private var vectorCheck:Sprite;
		//Embeds the swf that contains the Corbel font and sets it to be bold
		[Embed( source="/assets/EnigmaAssets.swf", fontFamily="Corbel", fontWeight="Bold" )]
		private var headerFont:String;
		//Embeds the swf that contains the Corbel font and sets it to be bold
		[Embed( source="/assets/EnigmaAssets.swf", fontFamily="Century Gothic", fontWeight="Bold" )]
		private var headerFont2:String;
		public var id:int;
		public function MCRadio(radioNumber:int, width:Number, text:String, value:String, indentRadio:Boolean=false, startSelected:Boolean=false, feedbackText:String=null)
		{
			this._width = width;
			this._answerText = text;
			this._valueNum = Number(value);
			this._startSelected = startSelected;
			this._feedbackText = feedbackText;
			this._indentRadio = indentRadio;
			this.drawRadio();
			this.drawText();
			this.hideInnerCircle();
			this._radioNumber = radioNumber;
			if (_startSelected) {
				showInnerCircle();
			}
			//this.addEventListener(MouseEvent.CLICK, radioClicked, false, 0, true);
		}
		private function drawRadio():void
		{
			_outerCircle = new Sprite();
			_outerCircle.graphics.clear();
			_outerCircle.graphics.lineStyle(2, BORDER_COLOR);
			_outerCircle.graphics.beginFill(BG_COLOR);
			_outerCircle.graphics.drawCircle(0,0, RADIO_DIAMETER/2);
			_outerCircle.graphics.endFill();
			addChild(_outerCircle);
			_outerCircle.y += 10;
			_innerCircle = new Sprite();
			_innerCircle.graphics.clear();
			_innerCircle.graphics.lineStyle(2, BORDER_COLOR);
			_innerCircle.graphics.beginFill(BORDER_COLOR);
			_innerCircle.graphics.drawCircle(0,0, RADIO_DIAMETER/5);
			addChild(_innerCircle);
			_innerCircle.y += 10;
			if (_indentRadio) {
				_innerCircle.x += 24;
				_outerCircle.x += 24;
				if (_startSelected) {
					if (_valueNum == 100) drawCheck();
					else if (_valueNum > 0 && _valueNum < 100) drawPercentage(_valueNum);
					else drawX();
				}
				else {
					if (_valueNum == 100) drawCheck();
				}
			}
		}
		private function drawText():void
		{
			_answer = new TextField();
			_answer.mouseEnabled = false;
			_answer.width = _width - _outerCircle.width-_outerCircle.x;
			_answer.x = _outerCircle.width-3+_outerCircle.x;
			_answer.y = 0;
			//_answer.height = 60;
			_answer.selectable = false;
			_answer.multiline = true;
			_answer.embedFonts = true;
			_answerTextFormat = new TextFormat("Corbel", 14, ANSWER_TEXT_COLOR, false);
			//_answer.border = true;
			if (_feedbackText != null) {
				_answer.text = _answerText+"\n"+_feedbackText; //_answerText+"\nFeedback: "+_feedbackText;
			}
			else {
				_answer.text = _answerText;
			}
			_answer.defaultTextFormat = _answerTextFormat;
			_answerTextFormat.align = TextFormatAlign.LEFT;
			_answer.wordWrap = true;
			_answer.autoSize = TextFieldAutoSize.LEFT;
			_answer.setTextFormat(_answerTextFormat);
			addChild(_answer);
		}
		public function drawX():void {
			vectorX = new Sprite();
			vectorX.graphics.lineStyle(4, Engine.X_COLOR, 1, true, LineScaleMode.NORMAL, CapsStyle.SQUARE);
			vectorX.graphics.moveTo(0,0);
			vectorX.graphics.lineTo(12, 12);
			vectorX.graphics.moveTo(0,12);
			vectorX.graphics.lineTo(12,0);
			vectorX.y = 5;
			vectorX.x = -9;
			addChild(vectorX);
		}
		public function drawCheck():void {
			vectorCheck = new Sprite();
			vectorCheck.graphics.lineStyle(4, Engine.CHECK_COLOR, 1, true, LineScaleMode.NORMAL, CapsStyle.SQUARE);
			vectorCheck.graphics.moveTo(0,14);
			vectorCheck.graphics.lineTo(5,14);
			vectorCheck.graphics.moveTo(5,14);
			vectorCheck.graphics.lineTo(5,0);
			vectorCheck.rotation = 45;
			addChild(vectorCheck);
		}
		public function drawPercentage(percentage:Number):void {
			_gradePercentage = new TextField();
			addChild(_gradePercentage);
			_gradePercentage.width = 35;
			_gradePercentage.height = 18;
 			_gradePercentage.x = -19;
			_gradePercentage.selectable = false;
			_gradePercentage.embedFonts = true;
			var percentageColor:int;
			if (percentage < .65)
			{
				percentageColor = Engine.X_COLOR;
			}
			else
			{
				percentageColor = Engine.CHECK_COLOR;
			}
			_gradePercentageFormat = new TextFormat("Century Gothic",14, percentageColor, true);
			_gradePercentageFormat.align = TextFormatAlign.LEFT;
			_gradePercentage.defaultTextFormat = _gradePercentageFormat;
			_gradePercentage.text = ""+(percentage)+"%";
		}
		public function showInnerCircle():void
		{
			_innerCircle.alpha = 1;
		}
		public function hideInnerCircle():void
		{
			_innerCircle.alpha = 0;
		}
	}
}