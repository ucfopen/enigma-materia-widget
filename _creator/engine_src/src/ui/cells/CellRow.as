/* See the file "LICENSE.txt" for the full license governing this code. */
package ui.cells
{
	import com.sizzlepopboom.Accessible;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	public class CellRow extends Sprite
	{
		public static const CELL_PADDING:int = 6;
		public static const CELL_Y_POSITION:int = 0;
		private var _rowNumber:int;
		public var _cellValueIncrement:int;
		public var _cellValueSize:int;
		public var headerCell:HeaderCell;
		private var _cellWidth:Number;
		private var _cellHeight:Number;
		public var _cells:Array;
		public function CellRow(headerTitle:String, rowNumber:int, cells:int, cellValueIncrement:int = 1, cellValueSize:int=50, cellWidth:Number=90, cellHeight:Number=90):void
		{
			this._cellValueIncrement = cellValueIncrement;
			this._cellValueSize = cellValueSize;
			this._rowNumber = rowNumber;
			this._cellHeight = cellHeight;
			this._cellWidth = cellWidth;
			_cells = new Array;
			makeCells(cells, headerTitle);
		}
		public function makeCells(cells:int, headerText:String):void
		{
			var newCell:Cell;
			headerCell = new HeaderCell(headerText);
			addChild(headerCell);
			headerCell.y = Cell.CELL_HEIGHT/2-HeaderCell.CELL_HEIGHT/2//CELL_Y_POSITION;
			headerCell.x = 0;
			for (var i:int = 0; i< cells; i++) {
				newCell = new Cell(_rowNumber, i, _cellValueSize, _cellWidth, _cellHeight);
				newCell.addEventListener(MouseEvent.MOUSE_OVER, mouseOverCell, false, 0, true);
				newCell.addEventListener(MouseEvent.MOUSE_OUT, mouseOutCell, false, 0, true);
				newCell.x = i*(newCell.width+CELL_PADDING)+headerCell.width+CELL_PADDING;
				newCell.y = CELL_Y_POSITION;
				newCell.changeValue((i+1)*_cellValueIncrement);
				addChild(newCell);
				_cells.push(newCell);
				var cellName:String = "Question " + String(i+1) + " in category " + headerText;
				Accessible.setTab(newCell);
				Accessible.setName(newCell, cellName);
			}
			this.graphics.clear();
			this.graphics.beginFill(0x000000, 0);
			this.graphics.drawRect(0,0, width, height);
			this.graphics.endFill();
		}
		public function mouseOverCell(event:MouseEvent):void
		{
			removeEventListener(MouseEvent.MOUSE_OVER, mouseOverCell);
			headerCell.colorCell(HeaderCell.BG_COLOR_HOVER, HeaderCell.BORDER_COLOR_HOVER);
		}
		public function mouseOutCell(event:MouseEvent):void
		{
			removeEventListener(MouseEvent.MOUSE_OUT, mouseOutCell);
			headerCell.colorCell(HeaderCell.BG_COLOR, HeaderCell.BORDER_COLOR);
		}
	}
}