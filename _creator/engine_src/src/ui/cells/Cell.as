/* See the file "LICENSE.txt" for the full license governing this code. */
package ui.cells
{
	import flash.display.CapsStyle;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import nm.gameServ.engines.EngineCore;
	import Engine;
	import events.EnigmaEvents;
	public class Cell extends Sprite
	{
		public static var CELL_WIDTH:int;
		public static var CELL_HEIGHT:int;
		private const BORDER_COLOR:int              = 0x16222A;
		private const BG_COLOR:int                  = 0xD1D7E1;
		private const BORDER_COLOR_INACTIVE:int     = 0x222a31;
		private const BG_COLOR_INACTIVE:int         = 0x2e3339;
		private const BORDER_COLOR_HOVER:int        = 0x16222A;
		private const BG_COLOR_HOVER:int            = 0xFDFFDE;
		private const BORDER_COLOR_DOWN:int         = 0x16222A;
		private const BG_COLOR_DOWN:int             = 0xD1D7E1;
		private const TEXT_COLOR:int                = 0x000000;
		private const TEXT_COLOR_INACTIVE:int       = 0x282e34;
		private const TEXT_COLOR_ANSWERED:int       = 0xbdc2cb;
		private const TEXT_COLOR_ANSWERED_HOVER:int = 0xeff0d1;
		private var vectorX:Sprite;
		private var vectorCheck:Sprite;
		private var vectorXBG:Sprite;
		private var vectorCheckBG:Sprite;
		private var _gradePercentage:TextField;
		private var _gradePercentageFormat:TextFormat;
		private var _rowNumber:int;
		private var _columnNumber:int;
		private var _value:String;
		private var _valueField:TextField;
		private var _valueFieldTextFormat:TextFormat;
		private var _width:int;
		private var _height:int;
		private var _position:int;
		private var _qSetPosition:int;
		private var _isEmpty:Boolean;
		private var _cellValueSize:int;
		private var _answered:Boolean;
		private var counter:int = 0;
		//Embeds the swf that contains the Century Gothic font and sets it to be bold
		[Embed( source="/assets/EnigmaAssets.swf", fontFamily="Century Gothic", fontWeight="Bold" )]
		private var cellFont:String;
		//Embeds the swf that contains the Corbel font and sets it to be bold
		[Embed( source="/assets/EnigmaAssets.swf", fontFamily="Corbel", fontWeight="Bold" )]
		private var headerFont2:String;
		public function Cell(rowNumber:int , columnNumber:int , cellTextSize:int=40, cellWidth:Number=90, cellHeight:Number=90)
		{
			super();
			Cell.CELL_WIDTH = cellWidth;
			Cell.CELL_HEIGHT = cellHeight;
			this.width = _width = Cell.CELL_WIDTH;
			this.height = _height = Cell.CELL_HEIGHT;
			this._rowNumber = rowNumber;
			this._columnNumber = columnNumber;
			this._cellValueSize = cellTextSize;
			this.addValue();
			this.colorCell();
			this.addEventListener(MouseEvent.MOUSE_OVER, mouseOver, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_OUT, mouseOut, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
			this.addEventListener(MouseEvent.CLICK, mouseClick, false, 0, true);
			this.addEventListener(FocusEvent.FOCUS_IN, focusInHandler, false, 0, true);
			this._answered = false;
			this.determineData();
			this.buttonMode = true;
		}
		public function addValue(value:int = 0):void
		{
			_valueField = new TextField();
			_valueField.mouseEnabled = false;
			addChild(_valueField);
			_valueField.selectable = false;
			_valueField.embedFonts = true;
			_valueFieldTextFormat = new TextFormat("Century Gothic", _cellValueSize, 0x000000, true);
			_valueField.defaultTextFormat = _valueFieldTextFormat;
			_valueField.text = ""+value;
			_valueFieldTextFormat.align = TextFormatAlign.CENTER;
			_valueField.autoSize = TextFieldAutoSize.CENTER;
			_valueField.x = (_width - _valueField.width)/2;
			_valueField.y = (_height - _valueField.height)/2;
		}
		public function changeValue(newValue:int):void
		{
			_valueField.text = ""+newValue;
		}
		public function changeStringValue(newValue:String):void
		{
			_valueField.text = ""+newValue;
		}
		public function setNewTextFormat(newTextFormat:TextFormat):void
		{
			_valueField.setTextFormat(newTextFormat);
			newTextFormat.align = TextFormatAlign.CENTER;
			_valueField.y = (_height - _valueField.height)/2;
		}
		public function resizeCellValueField():int
		{
			var tf:TextFormat;
			while(_valueField.width > (this._width-12))
			{
				tf = new TextFormat();
				tf.size = _cellValueSize--;
				_valueField.setTextFormat(tf);
				tf.align = TextFormatAlign.CENTER;
				_valueField.y = (_height - _valueField.height)/2;
			}
			return _cellValueSize;
		}
		public function colorCell(bgColor:int = BG_COLOR, borderColor:int = BORDER_COLOR, textColor:int = TEXT_COLOR):void
		{
			this.graphics.clear();
			this.graphics.lineStyle(3, borderColor);
			this.graphics.beginFill(bgColor);
			this.graphics.drawRect(0,0, _width, _height);
			this.graphics.endFill();
			_valueField.defaultTextFormat = _valueFieldTextFormat = new TextFormat("Century Gothic", _cellValueSize, textColor, true);
			_valueField.setTextFormat(_valueFieldTextFormat);
		}
		public function mouseOver(event:MouseEvent):void
		{
			if (_answered)
				colorCell(BG_COLOR_HOVER, BORDER_COLOR_HOVER, TEXT_COLOR_ANSWERED_HOVER);
			else
				colorCell(BG_COLOR_HOVER, BORDER_COLOR_HOVER);
			 Engine.playSound("over");
		}
		public function mouseOut(event:MouseEvent):void
		{
			if (_answered)
				colorCell(BG_COLOR, BORDER_COLOR, TEXT_COLOR_ANSWERED);
			else
				colorCell(BG_COLOR, BORDER_COLOR);
		}
		public function mouseDown(event:MouseEvent):void
		{
			if (_answered)
			{
				colorCell(BG_COLOR_DOWN, BORDER_COLOR_DOWN, TEXT_COLOR_ANSWERED);
			}
			else
			{
				colorCell(BG_COLOR_DOWN, BORDER_COLOR_DOWN);
			}
			Engine.playSound("down");
		}
		public function mouseUp(event:MouseEvent):void
		{
			if (_answered)
			{
				colorCell(BG_COLOR_HOVER, BORDER_COLOR_HOVER, TEXT_COLOR_ANSWERED);
			}
			colorCell(BG_COLOR_HOVER, BORDER_COLOR_HOVER);
		}
		public override function set width(value:Number):void
		{
			_width = value;
		}
		public override function set height(value:Number):void
		{
			_height = value;
		}
		public function mouseClick(event:MouseEvent):void
		{
			dispatchEvent(new EnigmaEvents(EnigmaEvents.CELL_CLICKED, {row:_rowNumber, column:_columnNumber, position: _position, qSetPosition: _qSetPosition, answered:_answered}, true));
		}
		public function focusInHandler(event:FocusEvent):void
		{
			dispatchEvent(new EnigmaEvents(EnigmaEvents.CELL_TAB_FOCUS, {row:_rowNumber, column:_columnNumber, position: _position, qSetPosition: _qSetPosition}, true));
		}
		public function cellAnswered():void
		{
			_answered = true;
			colorCell(BG_COLOR, BORDER_COLOR, TEXT_COLOR_ANSWERED);
		}
		public function cellEmpty():void
		{
			_answered = true;
			this.removeEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			this.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			this.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			this.removeEventListener(MouseEvent.CLICK, mouseClick);
			colorCell(BG_COLOR_INACTIVE, BORDER_COLOR_INACTIVE, TEXT_COLOR_INACTIVE);
		}
		public function drawX():void
		{
			vectorXBG = new Sprite();
			vectorXBG.graphics.clear();
			vectorXBG.graphics.lineStyle(3, Engine.X_COLOR, .35);
			vectorXBG.graphics.beginFill(Engine.X_COLOR, .35);
			vectorXBG.graphics.drawRect(0,0, _width, _height);
			vectorXBG.graphics.endFill();
			vectorXBG.mouseEnabled = false;
			addChild(vectorXBG);
			vectorX = new Sprite();
			vectorX.graphics.lineStyle(_width/6, Engine.X_COLOR, 1, true, LineScaleMode.NORMAL, CapsStyle.SQUARE);
			vectorX.graphics.moveTo(20,20);
			vectorX.graphics.lineTo(_width-20,_height-20);
			vectorX.graphics.moveTo(20,_height-20);
			vectorX.graphics.lineTo(_width-20,20);
			vectorX.mouseEnabled = false;
			addChild(vectorX);
		}
		public function drawCheck():void
		{
			vectorCheckBG = new Sprite();
			vectorCheckBG.graphics.clear();
			vectorCheckBG.graphics.lineStyle(3, Engine.CHECK_COLOR, .35);
			vectorCheckBG.graphics.beginFill(Engine.CHECK_COLOR, .35);
			vectorCheckBG.graphics.drawRect(0,0, _width, _height);
			vectorCheckBG.graphics.endFill();
			vectorCheckBG.mouseEnabled = false;
			addChild(vectorCheckBG);
			vectorCheck = new Sprite();
			vectorCheck.graphics.lineStyle(_width/6, Engine.CHECK_COLOR, 1, true, LineScaleMode.NORMAL, CapsStyle.SQUARE);
			vectorCheck.graphics.moveTo((_width/2.5),_height-24);
			vectorCheck.graphics.lineTo(10,_height-24);
			vectorCheck.graphics.moveTo((_width/2.5),_height-24);
			vectorCheck.graphics.lineTo((_width/2.5),10);
			vectorCheck.rotation = 45;
			vectorCheck.mouseEnabled = false;
			addChild(vectorCheck);
			vectorCheck.x = _width/2 + 12;
			vectorCheck.y = _height/2 - vectorCheck.height/2 - 12;
		}
		public function cellPercentage(percentage:Number):void
		{
			//draw percentage
			_gradePercentage = new TextField();
			_gradePercentage.mouseEnabled = false;
			addChild(_gradePercentage);
			_gradePercentage.width = _width;
			_gradePercentage.selectable = false;
			_gradePercentage.embedFonts = true;
			var percentageColor:int = percentage < .65 ? Engine.X_COLOR : Engine.CHECK_COLOR ;
			_gradePercentageFormat = new TextFormat("Corbel", _cellValueSize-3, percentageColor, true);
			_gradePercentage.defaultTextFormat = _gradePercentageFormat;
			_gradePercentage.text = ""+(percentage)+"%";
			_gradePercentageFormat.align = TextFormatAlign.CENTER;
			_gradePercentage.autoSize = TextFieldAutoSize.CENTER;
			_gradePercentage.x = (_width - _gradePercentage.width)/2;
			_gradePercentage.y = (_height - _gradePercentage.height)/2;
		}
		public function determineData():void {
			var foundMatch:Boolean = false;
			for (var i:Number = 0; i < EngineCore.qSetData.items.length; i++)
			{
				for (var f:Number = 0; f < EngineCore.qSetData.items[i].items.length; f++)
				{
					if (EngineCore.qSetData.items[i].items[f].options != null && EngineCore.qSetData.items[i].items[f].options.hasOwnProperty("index"))
					{
						if ((_columnNumber) == Number(EngineCore.qSetData.items[i].items[f].options.index-1) && (_rowNumber) == i)
						{
							_position = _columnNumber;
							_qSetPosition = f;
							foundMatch = true;
						}
					}
					else if (EngineCore.qSetData.items[i].items[f].options != null && EngineCore.qSetData.items[i].items[f].options.hasOwnProperty("position"))
					{
						if ((_columnNumber) == Number(EngineCore.qSetData.items[i].items[f].options.position) && (_rowNumber) == i)
						{
							_position = _columnNumber;
							_qSetPosition = f;
							foundMatch = true;
						}
					}
					else
					{
						_columnNumber = f
						_position = _columnNumber;
						_qSetPosition = f;
						foundMatch = true;
					}
				}
			}
			this._isEmpty = !foundMatch;
			if (this._isEmpty == true)
			{
				cellEmpty();
				this._answered = true;
			}
			else
			{
				this._answered = false;
			}
		}
		public function get isAnswered():Boolean
		{
			return	this._answered;
		}
		public function get isEmpty():Boolean
		{
			return	this._isEmpty;
		}
	}
}