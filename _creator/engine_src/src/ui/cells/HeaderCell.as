/* See the file "LICENSE.txt" for the full license governing this code. */
package ui.cells
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	public class HeaderCell extends Sprite
	{
		public static const CELL_WIDTH:int = 115;
		public static const CELL_HEIGHT:int = 55;
		public static const BORDER_COLOR:int = 0x5D656A;
		public static const BG_COLOR:int = 0xFFFFFF;
		public static const BORDER_COLOR_HOVER:int = 0x5D656A;
		public static const BG_COLOR_HOVER:int = 0xFDFFDE;
		public static const BORDER_COLOR_DOWN:int = 0xFF00FF;
		public static const BG_COLOR_DOWN:int = 0xFF33FF;
		public static const TEXT_COLOR:int = 0x000000;
		private var _header:String;
		private var _headerField:TextField;
		private var _headerFieldTextFormat:TextFormat;
		private var _width:int;
		private var _height:int;
		private var _headerTextSize:int;
		//Embeds the swf that contains the Corbel font and sets it to be bold
		[Embed( source="/assets/EnigmaAssets.swf", fontFamily="Corbel", fontWeight="Bold" )]
		private var headerFont:String;
		public function HeaderCell(headerText:String)
		{
			super();
			this.width = _width = HeaderCell.CELL_WIDTH;
			this.height = _height = HeaderCell.CELL_HEIGHT;
			this._headerTextSize = 14;
			this._header = headerText;
			this.colorCell();
			this.addText(_header);
			//this.addEventListener(MouseEvent.MOUSE_OVER, mouseOver, false, 0, true);
			//this.addEventListener(MouseEvent.MOUSE_OUT, mouseOut, false, 0, true);
			//this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
			//this.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
		}
		public function addText(header:String):void {
			_headerField = new TextField();
			addChild(_headerField);
			_headerField.selectable = false;
			_headerField.multiline = true;
			_headerField.embedFonts = true;
			_headerFieldTextFormat = new TextFormat("Corbel", _headerTextSize, 0x000000, true);
			_headerField.defaultTextFormat = _headerFieldTextFormat;
			_headerField.text = ""+header;
			_headerFieldTextFormat.align = TextFormatAlign.CENTER;
			_headerField.wordWrap = true;
			_headerField.autoSize = TextFieldAutoSize.CENTER;
			_headerField.x = (_width - _headerField.width)/2;
			_headerField.y = (_height - _headerField.height)/2;
			resizeHeaderTextField();
			//_headerField.width = _width;
			//_headerField.autoSize = TextFieldAutoSize.CENTER;
		}
		public function changeValue(newValue:int):void
		{
			_headerField.text = ""+newValue;
		}
		public function setNewTextFormat(newTextFormat:TextFormat):void {
			_headerField.setTextFormat(newTextFormat);
			_headerField.autoSize = TextFieldAutoSize.CENTER;
			_headerField.y = (_height - _headerField.height)/2;
		}
		public function resizeHeaderTextField():int {
			var tf:TextFormat;
			while(_headerField.width > (this._width-8) || _headerField.height > (this._height-2))
			{
				tf = new TextFormat();
				tf.size = _headerTextSize--;
				tf.align = TextFormatAlign.CENTER;
				_headerField.setTextFormat(tf);
				tf.align = TextFormatAlign.CENTER;
				_headerField.y = (_height - _headerField.height)/2;
			}
			return _headerTextSize;
		}
		public function colorCell(bgColor:int = BG_COLOR, borderColor:int = BORDER_COLOR):void
		{
			//Draw Border and BG
			this.graphics.clear();
			this.graphics.lineStyle(3, borderColor);
			this.graphics.beginFill(bgColor);
			this.graphics.drawRect(0,0, _width, _height);
			this.graphics.endFill();
			//Draw Triangle
			this.graphics.lineStyle(3, borderColor);
			this.graphics.beginFill(borderColor);
			this.graphics.moveTo(_width+7, _height/2);
			this.graphics.lineTo(_width+7, _height/2);
			this.graphics.lineTo(_width, _height-.33*_height);
			this.graphics.lineTo(_width, .33*_height);
		}
		public function mouseOver(event:MouseEvent):void
		{
			colorCell(BG_COLOR_HOVER, BORDER_COLOR_HOVER);
		}
		public function mouseOut(event:MouseEvent):void
		{
			colorCell(BG_COLOR, BORDER_COLOR);
		}
		public function mouseDown(event:MouseEvent):void
		{
			colorCell(BG_COLOR_DOWN, BORDER_COLOR_DOWN);
		}
		public function mouseUp(event:MouseEvent):void
		{
			colorCell(BG_COLOR_HOVER, BORDER_COLOR_HOVER);
		}
		public override function set width(value:Number):void {
			_width = value;
		}
		public override function set height(value:Number):void {
			_height = value;
		}
	}
}