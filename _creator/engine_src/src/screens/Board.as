/* See the file "LICENSE.txt" for the full license governing this code. */
package screens
{
	import flash.display.Sprite;
	import nm.gameServ.common.screens.Screen;
	import cells.*;
	import nm.ui.ScrollClip;
	public class Board extends Screen
	{
		public const BOARD_PADDING:int = 10;
		public const ROW_PADDING:int   = 4;
		private var _scrollBoard:ScrollClip;
		private var _cellValueIncrement:int;
		private var _cellValueSize:int;
		private var _numRows:int;
		private var _numCols:int;
		public function Board(width:int, height:int, numRows:int, numCols:int, cellValueIncrement = 1):void
		{
				this._numRows = numRows;
				this._numCols = numCols;
				var _scrollBoard:ScrollClip = new ScrollClip(width, height, false, true);
				addChild(_scrollBoard);
				_scrollBoard.draw();
				_scrollBoard.setStyle("bgAlpha", 0);
				this._cellValueIncrement = cellValueIncrement;
				var testCell:Cell = new Cell();
				addChild(testCell)
				testCell.changeValue(_cellValueIncrement*numCols);
				_cellValueSize = testCell.resizeCellValueField();
				removeChild(testCell);
				for (var i:int; i < numRows; i++)
				{
					var newRow:CellRow = new CellRow(numCols, _cellValueIncrement, _cellValueSize);
					_scrollBoard.clip.addChild(newRow);
					newRow.y = (i * (newRow.height + ROW_PADDING)) + BOARD_PADDING;
					newRow.x = BOARD_PADDING;
				}
				var bottomPadding = new Sprite();
				bottomPadding.graphics.clear();
				bottomPadding.graphics.beginFill(0x000000, 0);
				bottomPadding.graphics.drawRect(0,0, 10, BOARD_PADDING+5);
				bottomPadding.graphics.endFill();
				_scrollBoard.clip.addChild(bottomPadding);
				bottomPadding.y = _scrollBoard.clip.height;
				_scrollBoard.redraw();
		}
	}
}