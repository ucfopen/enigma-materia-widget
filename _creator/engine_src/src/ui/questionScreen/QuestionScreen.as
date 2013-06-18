/* See the file "LICENSE.txt" for the full license governing this code. */
package ui.questionScreen
{
	import com.sizzlepopboom.Accessible;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Keyboard;
	import events.EnigmaEvents;
	import nm.ui.ScrollClip;
	public class QuestionScreen extends Sprite
	{
		private const BORDER_COLOR:int = 0xFFFFFF;
		private const BG_COLOR:int = 0x3d4958;
		private const MASK_BG_COLOR:int = 0x1c2229;
		private const INNER_BORDER_COLOR:int = 0x697393;
		private const INNER_BG_COLOR:int = 0xFFFFFF;
		private const INNER_RADIO_BORDER_COLOR:int = 0xFFFFFF;
		private const INNER_RADIO_BG_COLOR:int = 0xeff0f2;
		private const ANSWER_TEXT_COLOR:int = 0x343434;
		private var _row:int;
		private var _column:int;
		private var _width:Number;
		private var _height:Number;
		private var _questionTitle:String;
		private var _questionText:TextField;
		private var _questionTextFormat:TextFormat;
		private var _question:String;
		private var _titleText:TextField;
		private var _titleTextFormat:TextFormat;
		private var _mcAnswers:MCAnswers;
		private var _answers:Array;
		private var _scrollAnswers:ScrollClip;
		private var _scrollQuestion:ScrollClip;
		private var _titleTextSize:int;
		private var _submitButton:EnigmaButton;
		private var _cancelButton:EnigmaButton;
		private var _selectedButton:String;
		private var _reviewSelectedRadio:int;
		private var _reviewMode:Boolean;
		//Embeds the swf that contains the Corbel font and sets it to be bold
		[Embed( source="/assets/EnigmaAssets.swf", fontFamily="Corbel", fontWeight="Bold" )]
		private var headerFont:String;
		//Embeds the swf that contains the Corbel font and sets it to be bold
		[Embed( source="/assets/EnigmaAssets.swf", fontFamily="Century Gothic", fontWeight="Bold" )]
		private var headerFont2:String;
		public function QuestionScreen(categoryTitle:String,  question:String, answers:Array,type:String, row:int, column:int, width:Number, height:Number, reviewMode:Boolean=false, reviewSelectedRadio:int=-1)
		{
			this._row                 = row;
			this._column              = column;
			this._width               = width;
			this._height              = height;
			this._reviewMode          = reviewMode;
			this._reviewSelectedRadio = reviewSelectedRadio;
			_titleTextSize            = 28;
			_questionTitle            = _reviewMode ? "reviewing question "+(column+1)+' in "'+categoryTitle+'"' : "question "+(column+1)+' in "'+categoryTitle+'"';
			_question                 = question;
			this._answers             = answers;
			switch(type)
			{
				case "MC":
					drawMCQuestionScreen();
					break;
			}
			addEventListener(EnigmaEvents.RADIO_CLICKED, radioClicked, false, 0, true);
			addEventListener(KeyboardEvent.KEY_DOWN, keyEventHandler, false, 0, true);
		}
		private function radioClicked(event:Event):void
		{
			_submitButton.enableButton();
		}
		private function drawMCQuestionScreen():void
		{
			this.graphics.clear();
			this.graphics.beginFill(this.MASK_BG_COLOR, .70);
			this.graphics.drawRect(0,0, _width, _height);
			this.graphics.endFill();
			this.graphics.lineStyle(3, this.BORDER_COLOR);
			this.graphics.beginFill(this.BG_COLOR, .95);
			this.graphics.drawRect(12,12, _width-24, _height-24);
			this.graphics.endFill();
			this.graphics.lineStyle(3, this.INNER_BORDER_COLOR);
			this.graphics.beginFill(this.INNER_BG_COLOR);
			this.graphics.drawRect(70, 103, 612, 241);
			this.graphics.endFill();
			this.graphics.lineStyle(3, this.INNER_RADIO_BORDER_COLOR);
			this.graphics.beginFill(this.INNER_RADIO_BG_COLOR);
			this.graphics.drawRect(70, 355, 612, 123);
			this.graphics.endFill();
			_scrollQuestion = new ScrollClip(602, 236, false, true);
			_scrollQuestion.draw();
			addChild(_scrollQuestion);
			_scrollQuestion.x = 78;
			_scrollQuestion.y = 106;
			_questionText                   = new TextField();
			_questionText.width             = 590;
			_questionText.x                 = _questionText.y = 0;
			_questionText.text              = _question;
			_questionText.selectable        = false;
			_questionText.multiline         = true;
			_questionText.embedFonts        = true;
			_questionTextFormat             = new TextFormat("Corbel", 16, ANSWER_TEXT_COLOR, false);
			_questionText.defaultTextFormat = _questionTextFormat;
			_questionText.setTextFormat(_questionTextFormat);
			_questionTextFormat.align       = TextFormatAlign.CENTER;
			_questionText.wordWrap          = true;
			_questionText.autoSize          = TextFieldAutoSize.CENTER;
			_scrollQuestion.clip.addChild(_questionText);
			_scrollQuestion.redraw();
			_scrollAnswers = new ScrollClip(608, 119, false, true);
			addChild(_scrollAnswers);
			_scrollAnswers.draw();
			_scrollAnswers.setStyle("bgAlpha", 0);
			_scrollAnswers.x = 72;
			_scrollAnswers.y = 357;
			_mcAnswers = new MCAnswers(_answers, _reviewMode, _reviewSelectedRadio);
			_scrollAnswers.clip.addChild(_mcAnswers);
			_mcAnswers.y = 5;
			var bottomPadding:Sprite = new Sprite();
			bottomPadding.graphics.clear();
			bottomPadding.graphics.beginFill(0x000000, 0);
			bottomPadding.graphics.drawRect(0,0, 10, 5);
			bottomPadding.graphics.endFill();
			_scrollAnswers.clip.addChild(bottomPadding);
			bottomPadding.y = _mcAnswers.height+_mcAnswers.y;
			_scrollAnswers.redraw();
			_titleText = new TextField();
			addChild(_titleText);
			_titleText.width = 609;
			_titleText.height = 76;
			_titleText.x = 71;
			_titleText.selectable = false;
			_titleText.multiline = true;
			_titleText.embedFonts = true;
			_titleTextFormat = new TextFormat("Century Gothic", _titleTextSize, 0xFFFFFF, true);
			_titleText.defaultTextFormat = _titleTextFormat;
			_titleText.text = _questionTitle.toUpperCase();
			_titleTextFormat.align = TextFormatAlign.CENTER;
			_titleText.wordWrap = true;
			_titleText.autoSize = TextFieldAutoSize.CENTER;
			_titleText.y = _scrollQuestion.y-_titleText.height-10;
			if (_titleText.height > 87)
			{
				resizeTitleTextField();
			}
			_submitButton = new EnigmaButton("submit answer");
			addChild(_submitButton);
			_submitButton.y = _scrollAnswers.y+_scrollAnswers.height+15;
			_submitButton.x = _scrollAnswers.x+_scrollAnswers.width-_submitButton.width+5;
			_submitButton.disableButton();
			_submitButton.addEventListener(FocusEvent.FOCUS_IN, focusInHandler, false, 0, true);
			_submitButton.addEventListener(FocusEvent.FOCUS_OUT, focusOutHandler, false, 0, true);
			_cancelButton = new EnigmaButton("go back");
			addChild(_cancelButton);
			_cancelButton.y = _scrollAnswers.y+_scrollAnswers.height+15;
			_cancelButton.x = _scrollAnswers.x+_scrollAnswers.width-_cancelButton.width-_submitButton.width-3;
			_cancelButton.addEventListener(FocusEvent.FOCUS_IN, focusInHandler, false, 0, true);
			_cancelButton.addEventListener(FocusEvent.FOCUS_OUT, focusOutHandler, false, 0, true);
			Accessible.setTab(_cancelButton);
			Accessible.setTab(_submitButton);
			if (_reviewMode)
			{
				Accessible.stopTab(_submitButton);
				_cancelButton.x = _submitButton.x;
				_submitButton.visible = false;
			}
		}
		public function resizeTitleTextField():void
		{
			var tf:TextFormat;
			while(_titleText.height > 87)
			{
				tf = new TextFormat();
				tf.size = _titleTextSize--;
				tf.align = TextFormatAlign.LEFT;
				_titleText.setTextFormat(tf);
				tf.align = TextFormatAlign.LEFT;
				_titleText.y = _scrollQuestion.y-_titleText.height-10;//= (_height - _titleText.height)/2;
			}
		}
		private function keyEventHandler(event:KeyboardEvent):void
		{
			if (event.keyCode == Keyboard.SPACE)
			{
				if (_selectedButton == "submit")
				{
					_submitButton.mouseClick();
				}
				else if (_selectedButton == "cancel")
				{
					_cancelButton.mouseClick();
				}
			}
		}
		public function focusInHandler(event:FocusEvent):void
		{
			_selectedButton = event.currentTarget == _submitButton ? 'submit' : 'cancel';
		}
		public function focusOutHandler(event:FocusEvent):void
		{
			_selectedButton = "";
		}
	}
}