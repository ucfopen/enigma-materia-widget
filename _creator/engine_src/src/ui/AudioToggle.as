/* See the file "LICENSE.txt" for the full license governing this code. */
package ui
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import events.EnigmaEvents;
	public class AudioToggle extends MovieClip
	{
		//Embeds the swf that contains the Corbel font and sets it to be bold
		[Embed( source="/assets/EnigmaAssets.swf", fontFamily="Corbel", fontWeight="Bold" )]
		private var headerFont:String;
		private var _buttonText:TextField;
		private var _buttonTextFormat:TextFormat;
		private var _width:int
		private var _height:int;
		public function AudioToggle(width:int, height:int)
		{
			this._width = width;
			this._height = height;
			////trace("This is the audio toggle");
			graphics.clear();
			graphics.beginFill(0xFFFFFF, 0);
			graphics.drawRect(0,0, _width, _height);
			graphics.endFill();
			_buttonText = new TextField();
			_buttonText.selectable = false;
			_buttonText.multiline = true;
			_buttonText.embedFonts = true;
			//_buttonTextFormat = new TextFormat("Corbel", 12, 0xFFFFFF, false);
			//_buttonText.defaultTextFormat = _buttonTextFormat;
			///_buttonText.setTextFormat(_buttonTextFormat);
			//_buttonTextFormat.align = TextFormatAlign.CENTER;
			_buttonText.wordWrap = true;
			_buttonText.autoSize = TextFieldAutoSize.CENTER;
			addChild(_buttonText);
			_buttonText.htmlText = '<FONT FACE="Corbel" SIZE="12" COLOR="#949c9f"><U>A</U>udio: </FONT><FONT FACE="Corbel" SIZE="12" COLOR="#FFFFFF">On</FONT><FONT FACE="Corbel" SIZE="12" COLOR="#949c9f"> | Off</FONT>';
			_buttonText.y = _height/2-_buttonText.height/2;
			this.addEventListener(MouseEvent.CLICK, mouseClick, false, 0, true);
		}
		public function changeState(muted:Boolean):void {
			if (muted == true) {
				_buttonText.htmlText = '<FONT FACE="Corbel" SIZE="12" COLOR="#949c9f"><U>A</U>udio: On | </FONT><FONT FACE="Corbel" SIZE="12" COLOR="#FFFFFF">Off</FONT>';
			}
			else {
				_buttonText.htmlText = '<FONT FACE="Corbel" SIZE="12" COLOR="#949c9f"><U>A</U>udio: </FONT><FONT FACE="Corbel" SIZE="12" COLOR="#FFFFFF">On</FONT><FONT FACE="Corbel" SIZE="12" COLOR="#949c9f"> | Off</FONT>';
			}
		}
		public function mouseClick(event:MouseEvent=null):void
		{
			dispatchEvent(new EnigmaEvents(EnigmaEvents.MUTE_BUTTON_CLICKED, true));
		}
	}
}