/* See the file "LICENSE.txt" for the full license governing this code. */
package ui
{
	import flash.display.Sprite;
	import nm.ui.ScrollClip;
	import ui.cells.*;
	public class GameBoard extends Sprite
	{
		public const BOARD_PADDING:int = 10;
		public const ROW_PADDING:int = 4;
		private var _scrollBoard:ScrollClip;
		private var _cellValueIncrement:int;
		private var _cellValueSize:int;
		private var _numRows:int;
		private var _numCols:int;
		private var _boardWidth:Number;
		private var _boardHeight:Number;
		private var _cellWidth:Number;
		private var _cellHeight:Number;
		public var _rows:Array;
		public function GameBoard(qSet:Object, width:int, height:int, numRows:int, numCols:int, cellValueIncrement:int = 1):void
		{
				this._numRows = numRows;
				this._numCols = numCols;
				this._boardWidth = width;
				this._boardHeight = height;
				_cellWidth = (numCols > 6) ? calculateCellWidth() : 90;
				////trace("*********MAKING A SCROLLCLIP");
				var _scrollBoard:ScrollClip = new ScrollClip(_boardWidth, _boardHeight, false, true);
				addChild(_scrollBoard);
				_scrollBoard.draw();
				_scrollBoard.setStyle("bgAlpha", 0);
				this._cellValueIncrement = cellValueIncrement;
				_rows = new Array();
				//use this to determine the size of the font
				var testCell:Cell = new Cell(-1, -1, 40, _cellWidth, _cellWidth);
				addChild(testCell)
				testCell.changeValue(_cellValueIncrement*numCols);
				_cellValueSize = testCell.resizeCellValueField();
				removeChild(testCell);
				for (var i:int; i < numRows; i++) {
					var newRow:CellRow = new CellRow(qSet.items[i].name, i, numCols, _cellValueIncrement, _cellValueSize, _cellWidth, _cellWidth);
					_scrollBoard.clip.addChild(newRow);
					newRow.y = (i * (newRow.height + ROW_PADDING)) + BOARD_PADDING;
					newRow.x = BOARD_PADDING;
					_rows.push(newRow);
				}
				var bottomPadding:Sprite = new Sprite();
				bottomPadding.graphics.clear();
				bottomPadding.graphics.beginFill(0x000000, 0);
				bottomPadding.graphics.drawRect(0,0, 10, BOARD_PADDING+5);
				bottomPadding.graphics.endFill();
				_scrollBoard.clip.addChild(bottomPadding);
				bottomPadding.y = _scrollBoard.clip.height;
				_scrollBoard.redraw();
				//if (_scrollBoard.clip.height > _scrollBoard.height) {
				//	_scrollBoard.sc
				//}
		}
		private function calculateCellWidth():int
		{
			var newCellWidth:Number = (_boardWidth-HeaderCell.CELL_WIDTH-CellRow.CELL_PADDING-((CellRow.CELL_PADDING*2)*_numCols)-17)/_numCols
			return newCellWidth;
		}
	}
}