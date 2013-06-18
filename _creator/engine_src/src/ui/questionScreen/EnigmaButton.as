/* See the file "LICENSE.txt" for the full license governing this code. */
package ui.questionScreen
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import com.sizzlepopboom.Accessible;
	import flash.events.FocusEvent;
	import events.EnigmaEvents;
	public class EnigmaButton extends Sprite
	{
		private const BUTTON_BG_COLOR:int = 0x000000;
		private const BUTTON_BG_COLOR_HOVER:int = 0x4187c9; //0xa1d888;
		private const BUTTON_BORDER_COLOR:int = 0xFFFFFF;
		private const BUTTON_BORDER_COLOR_HOVER:int = 0xFFFFFF;
		private const BUTTON_TEXT_COLOR:int = 0xFFFFFF;
		private const BUTTON_BG_COLOR_DISABLED:int = 0x494949;
		private const BUTTON_WIDTH:int = 102;
		private const BUTTON_HEIGHT:int = 22;
		private var _text:String;
		private var _titleText:TextField;
		private var _titleTextFormat:TextFormat;
		//Embeds the swf that contains the Corbel font and sets it to be bold
		[Embed( source="/assets/EnigmaAssets.swf", fontFamily="Century Gothic", fontWeight="Bold" )]
		private var headerFont:String;
		public function EnigmaButton(displayText:String = "")
		{
			this.mouseChildren = false;
			this.buttonMode = true;
			this._text = displayText;
			this.graphics.clear();
			this.graphics.lineStyle(2, BUTTON_BORDER_COLOR);
			this.graphics.beginFill(BUTTON_BG_COLOR);
			this.graphics.drawRect(0,0, BUTTON_WIDTH, BUTTON_HEIGHT);
			this.graphics.endFill();
			_titleText = new TextField();
			addChild(_titleText);
			_titleText.selectable = false;
			_titleText.multiline = true;
			_titleText.embedFonts = true;
			_titleTextFormat = new TextFormat("Century Gothic", 12, 0xFFFFFF, true);
			_titleTextFormat.align = TextFormatAlign.CENTER;
			_titleText.defaultTextFormat = _titleTextFormat;
			_titleText.setTextFormat(_titleTextFormat);
			_titleText.autoSize = TextFieldAutoSize.CENTER;
			_titleText.text = this._text.toUpperCase();
			_titleText.wordWrap = false;
			this.addEventListener(MouseEvent.MOUSE_OVER, mouseOver, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_OUT, mouseOut, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
			this.addEventListener(MouseEvent.CLICK, mouseClick, false, 0, true);
			this.addEventListener(FocusEvent.FOCUS_IN, focusInHandler, false, 0, true);
			this.addEventListener(FocusEvent.FOCUS_OUT, focusOutHandler, false, 0, true);
		}
		public function mouseOver(event:MouseEvent):void
		{
			colorButton(BUTTON_BG_COLOR_HOVER, BUTTON_BORDER_COLOR_HOVER);
		}
		public function mouseOut(event:MouseEvent):void
		{
			colorButton(BUTTON_BG_COLOR, BUTTON_BORDER_COLOR);
		}
		public function mouseDown(event:MouseEvent):void
		{
			colorButton(BUTTON_BG_COLOR, BUTTON_BORDER_COLOR);
		}
		public function mouseUp(event:MouseEvent):void
		{
			colorButton(BUTTON_BG_COLOR_HOVER, BUTTON_BORDER_COLOR_HOVER);
		}
		public function mouseClick(event:MouseEvent=null):void
		{
			dispatchEvent(new EnigmaEvents(EnigmaEvents.BUTTON_CLICKED, {button:_text}, true));
		}
		public function colorButton(bgColor:int = BUTTON_BG_COLOR, borderColor:int = BUTTON_BORDER_COLOR):void
		{
			this.graphics.clear();
			this.graphics.lineStyle(2, borderColor);
			this.graphics.beginFill(bgColor);
			this.graphics.drawRect(0,0, BUTTON_WIDTH, BUTTON_HEIGHT);
			this.graphics.endFill();
		}
		public function disableButton():void {
			this.removeEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			this.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			this.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			this.removeEventListener(MouseEvent.CLICK, mouseClick);
			colorButton(BUTTON_BG_COLOR_DISABLED);
			Accessible.stopTab(this);
		}
		public function enableButton():void {
			this.addEventListener(MouseEvent.MOUSE_OVER, mouseOver, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_OUT, mouseOut, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
			this.addEventListener(MouseEvent.CLICK, mouseClick, false, 0, true);
			colorButton();
			Accessible.startTab(this);
		}
		public function focusInHandler(event:FocusEvent):void
		{
			colorButton(BUTTON_BG_COLOR_HOVER, BUTTON_BORDER_COLOR_HOVER);
		}
		public function focusOutHandler(event:FocusEvent):void
		{
			 colorButton();
		}
	}
}