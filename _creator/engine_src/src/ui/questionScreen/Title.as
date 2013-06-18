/* See the file "LICENSE.txt" for the full license governing this code. */
package ui.questionScreen
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.AntiAliasType;
	public class Title extends Sprite
	{
		private var _title:String;
		private var _titleText:TextField;
		private var _titleTextFormat:TextFormat;
		private var _width:int;
		private var _height:int;
		//Embeds the swf that contains the Corbel font and sets it to be bold
		[Embed( source="/assets/EnigmaAssets.swf", fontFamily="Corbel", fontWeight="Bold" )]
		private var headerFont:String;
		public function Title(title:String)
		{
			this._title = title;
			_titleText = new TextField();
			addChild(_titleText);
			this.width = _width = 500;
			this.height = _height = 45;
			_titleText.selectable = false;
			_titleText.multiline = true;
			_titleText.embedFonts = true;
			_titleTextFormat = new TextFormat("Corbel", 25, 0xFFFFFF, true);
			_titleText.defaultTextFormat = _titleTextFormat;
			_titleText.text = this._title; //"Course Administration Online Computer Dell Homo Sapien Christmas Lady Black Mambazo"
			_titleTextFormat.align = TextFormatAlign.CENTER;
			_titleText.wordWrap = true;
			_titleText.autoSize = TextFieldAutoSize.CENTER;
			_titleText.width = _width;
			_titleText.height = _height;
		}
		public override function set width(value:Number):void {
			_width = value;
		}
		public override function set height(value:Number):void {
			_height = value;
		}
	}
}