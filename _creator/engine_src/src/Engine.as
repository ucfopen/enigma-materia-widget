/* See the file "LICENSE.txt" for the full license governing this code. */
package
{
	import com.gskinner.motion.*;
	import com.sizzlepopboom.Accessible;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.*;
	import flash.media.Sound;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Keyboard;
	import nm.gameServ.engines.EngineCore;
	import events.EnigmaEvents;
	import screens.*;
	import ui.*;
	import ui.questionScreen.*;

	public class Engine extends EngineCore
	{
		//--------------------------------------------------------------------------
		//  Variables
		//--------------------------------------------------------------------------
		public static const X_COLOR:int      = 0xCC0000;
		public static const CHECK_COLOR:int  = 0x4187c9;
		private const BG_COLOR:int           = 0x2F3944;
		private const BG_COLOR_GRADIENT1:int = 0x111F2C;
		private const BG_COLOR_GRADIENT2:int = 0x1E3148;
		private const BG_COLOR_TOPBAR:int    = 0x4d5355;
		private const ENIGMA_WIDTH:Number    = 750;
		private const ENIGMA_HEIGHT:Number   = 550;
		private var _audioToggle:AudioToggle;
		private var correctGlow:MovieClip;
		private var incorrectGlow:MovieClip;
		private var _score:Score;
		private var _gameTitle:Title;
		private var _mcRadioSelected:int;
		// Boolean set to true when you are viewing the question screen.
		private var _viewingQuestionScreen:Boolean;
		// Total number of questions.
		private var _questionCount:int;
		// Total number of questions answered.
		private var _questionsAnswered:int;
		// Current cell row selected.
		private var _boardCellRowSelected:int;
		// Current cell column selected.
		private var _boardCellColumnSelected:int;
		// Position of the cell selected. (In the qSet and in order).
		private var _boardCellColumnSelected_qSetPosition:int;
		private var _boardCellColumnSelected_Position:int;
		//The board screen.
		private var _board:ui.GameBoard;
		// The question screen.
		private var _questionScreen:ui.questionScreen.QuestionScreen;
		// Contains the strings used throughout the program
		private var _strings:Object;
		// Reference to the number of columns in the qset
		private var _numColumns:int;
		// Reference to the number of rows in the qset
		private var _numRows:int;
		//Initial box score (100)
		private var _lowestPrice:int;
		// How much score increses as you move right
		private var _priceIncrement:int;
		// Whether or not the sound should be muted
		private static var _mute:Boolean;
		// Sound used when a cell is clicked.
		private static var _down_snd:Sound;
		// Sound played when moused over a cell.
		private static var _over_snd:Sound;
		// Sound played when quesion answered correctly.
		private static var _correct_snd:Sound;
		// Sound played when quesion answered incorrectly.
		private static var _wrong_snd:Sound;
		// 2D Array to store the current scores of each cell.
		private var _scores:Array;
		// Stores the current score (percentage). Displayed at the top of the game.
		private var _curScore:Number;
		// Stores the last score from answered question.
		private var _lastIncr:Number;
		// Determines whether the order of answer radio buttons is randomized or not.
		private var _randomizeOrder:Boolean;

		//--------------------------------------------------------------------------
		//  Functions
		//--------------------------------------------------------------------------
		// Called when the EngineCore is added to the stage and everything is good to go.
		protected override function startEngine():void
		{
			super.startEngine();
			_numRows = 0;
			_numColumns = 0;
			_randomizeOrder = false;
			if(EngineCore.qSetData.hasOwnProperty('options') && EngineCore.qSetData.options != null && EngineCore.qSetData.options.hasOwnProperty('randomize'))
			{
				_randomizeOrder = EngineCore.qSetData.options.randomize;
			}
			else
			{
				_randomizeOrder = false;
			}
			var tempColumnsByPosition:int = 0;
			var tempColumnsByIter:int = 0;

			for (var i:Number = 0; i < EngineCore.qSetData.items.length; i++)
			{
				_numRows++;
				tempColumnsByPosition = 0;
				tempColumnsByIter = 0;
				for (var f:Number = 0; f < EngineCore.qSetData.items[i].items.length; f++)
				{
					//randomize the answers at the deepest possible level to avoid future complications
					if(_randomizeOrder) EngineCore.qSetData.items[i].items[f].answers = EngineCore.qSetData.items[i].items[f].answers.sort(randomSort);
					tempColumnsByIter++;
					if (EngineCore.qSetData.items[i].items[f].options != null && EngineCore.qSetData.items[i].items[f].options.position != null)
					{
						tempColumnsByPosition = Math.max(tempColumnsByPosition, Number(EngineCore.qSetData.items[i].items[f].options.position));
					}
				}
				_numColumns = Math.max(tempColumnsByIter, tempColumnsByPosition, _numColumns);
			}
			_boardCellRowSelected = _boardCellColumnSelected = 0;
			_viewingQuestionScreen = false;
			createBoard(750, 435, _numRows, _numColumns, 1);
			resetScore();
			initSounds();
			_questionsAnswered = 0;
			addEventListener(EnigmaEvents.BUTTON_CLICKED, buttonClicked, false, 0, true);
			addEventListener(EnigmaEvents.RADIO_CLICKED, radioClicked, false, 0, true);
			addEventListener(EnigmaEvents.RADIO_CLICKED, radioClicked, false, 0, true);
			addEventListener(EnigmaEvents.CELL_TAB_FOCUS, cellTabFocus, false, 0, true);
			addEventListener(KeyboardEvent.KEY_DOWN, keyEventHandler, false, 0, true);
		}

		private function randomSort(objA:Object, objB:Object):int
		{
			return Math.round(Math.random() * 2) - 1
		}

		private function createBoard(width:int, height:int, _numRows:int, _numColumns:int, cellValueIncrement:int = 1):void
		{
			drawBackground();
			drawAudioButton();
			_board = new GameBoard(EngineCore.qSetData, width, height, _numRows, _numColumns, cellValueIncrement);
			_board.addEventListener(EnigmaEvents.CELL_CLICKED, cellClicked, false, 0, true);
			addChild(_board);
			_board.x = 0;
			_board.y = 115;
			drawScore();
			drawTitle();
			startAccessibleCellTabs();
		}

		private function resetScore():void
		{
			_curScore=0;
			var i:int;
			_scores = new Array()
			for(i = 0; i <= _numRows; i++)
			{
				_scores[i] = new Array()
				for(var b:int = 0; b <= _numColumns; b++)
				{
					_scores[i][b] = {score:null, avail:1}
				}
			}
			_questionCount = 0;
			for (i = 0; i < EngineCore.qSetData.items.length; i++)
			{
				for (var f:int = 0; f < EngineCore.qSetData.items[i].items.length; f++)
				{
					_questionCount++;
				}
			}
		}

		private function initSounds():void
		{
			_mute = true;
			_audioToggle.changeState(_mute);
			_down_snd = new Sound_ButtonMouseDown();
			_over_snd = new Sound_ButtonMouseOver();
			_correct_snd = new Sound_Positive();
			_wrong_snd = new Sound_Negative();
		}

		public static function playSound(type:String):void
		{
			if(!_mute)
			{
				var snd:Sound;
				switch(type)
				{
					case "down":
						snd = _down_snd;
						break;
					case "over":
						snd = _over_snd;
						break;
					case "correct":
						snd = _correct_snd;
						break;
					case "wrong":
						snd = _wrong_snd;
						break;
				}
				snd.play(0,0);
			}
		}

		private function drawBackground():void
		{
			var background:MovieClip = new MovieClip();
		    var backgroundGradientColors:Array = [BG_COLOR_GRADIENT1, BG_COLOR_GRADIENT2];
		    var backgroundGradientFillType:String = "linear"
		    var backgroundGradientAlphas:Array = [100, 100];
		    var backgroundGradientRatios:Array = [0, 155];
		    var backgroundGradientSpreadMethod:String = "pad";
			var backgroundGradientInterpolationMethod:String = "RGB";
			var backgroundGradientFocalPointRatio:Number = 0.9;
			var backgroundGradientMatrix:Matrix = new Matrix();
			backgroundGradientMatrix.createGradientBox(this.ENIGMA_WIDTH/2, 200, Math.PI/2, 0, 0);
			background.graphics.beginGradientFill(backgroundGradientFillType, backgroundGradientColors, backgroundGradientAlphas, backgroundGradientRatios, backgroundGradientMatrix,
		    backgroundGradientSpreadMethod, backgroundGradientInterpolationMethod, backgroundGradientFocalPointRatio);
			background.graphics.moveTo(0, 0);
			background.graphics.lineTo(0, this.ENIGMA_HEIGHT);
			background.graphics.lineTo(this.ENIGMA_WIDTH, this.ENIGMA_HEIGHT);
			background.graphics.lineTo(this.ENIGMA_WIDTH, 0);
			background.graphics.lineTo(0, 0);
			background.graphics.endFill();
			addChild(background);
			var backgroundFG:MovieClip = new MovieClip();
			backgroundFG.graphics.beginFill(this.BG_COLOR);
			backgroundFG.graphics.drawRect(0,105, this.ENIGMA_WIDTH, this.ENIGMA_HEIGHT-105);
			backgroundFG.graphics.endFill();
			addChild(backgroundFG);
			var backgroundBar:MovieClip = new MovieClip();
			backgroundBar.graphics.beginFill(this.BG_COLOR_TOPBAR);
			backgroundBar.graphics.drawRect(0,90, this.ENIGMA_WIDTH, 25);
			backgroundBar.graphics.endFill();
			addChild(backgroundBar);
			var bgBarDropShadow:DropShadowFilter = new DropShadowFilter(3, 65, 0x000000, 0.3, 5, 5, 1, 3);
			backgroundBar.filters = [bgBarDropShadow];
		}

		private function drawAudioButton():void
		{
			_audioToggle = new  AudioToggle(82,25);
			addChild(_audioToggle);
			_audioToggle.x = ENIGMA_WIDTH-_audioToggle.width-5;
			_audioToggle.y = 90;
			_audioToggle.addEventListener(EnigmaEvents.MUTE_BUTTON_CLICKED, muteButtonPressed, false, 0, true);
		}

		private function muteButtonPressed(event:EnigmaEvents=null):void
		{
			_mute = !_mute
			_audioToggle.changeState(_mute);
		}

		private function drawScore():void
		{
			_score = new Score(175, 90);
			this.addChild(_score);
			_score.x = ENIGMA_WIDTH-_score.width-10;
			_score.y = 0;
			_score.setScoreValue(0);
			_score.newValue(0);
		}

		private function drawTitle():void
		{
			_gameTitle = new Title(""+inst.name);
			this.addChild(_gameTitle);
			_gameTitle.y = 100/2-_gameTitle.height/2;
			_gameTitle.x = 15;
		}

		public function getEnigmaQuestion(row:int, column:int):String
		{
			return cellData(row, column).questions[0].text;
		}

		public function getEnigmaAnswer(row:int, column:int):Array
		{
			return cellData(row, column).answers;
		}

		// Returns the question object for a given position
		private function cellData(row:int, column:int):*
		{
			// Cell data is stored in qset.items[i].items[j].items[0]
			if (EngineCore.qSetData.items[row].items[column].items != null) {
				return EngineCore.qSetData.items[row].items[column];
			}
			// Cell data is stored in qset.items[i].items[j][0]
			else if (EngineCore.qSetData.items[row].items[column][0] != null) {
				return EngineCore.qSetData.items[row].items[column][0];
			}
			// Cell data is stored in qset.items[i].items[j]
			else {
				return EngineCore.qSetData.items[row].items[column];
			}
		}

		private function cellAnsweredNumber(row:int, column:int):int
		{
			if (cellData(row, column).options != null && cellData(row, column).options.selectedAnswer != null)
			{
				return cellData(row, column).options.selectedAnswer;
			}
			else
			{
				return 0;
			}
		}

		private function cellClicked(event:EnigmaEvents):void
		{
			Engine.playSound("down");
			event.stopPropagation();
			_boardCellRowSelected = event.data.row;
			_boardCellColumnSelected = event.data.column;
			_boardCellColumnSelected_qSetPosition = event.data.qSetPosition;
			drawQuestionScreen("MC",
				event.data.row,
				event.data.column,
				event.data.answered);
		}

		private function keyEventHandler(event:KeyboardEvent):void
		{
			if (event.keyCode == Keyboard.SPACE)
			{
				if (_viewingQuestionScreen == false)
				{
					drawQuestionScreen("MC", _boardCellRowSelected, _boardCellColumnSelected);
				}
			}
			else if (event.keyCode == 83 || event.keyCode == 115)
			{
				muteButtonPressed();
			}
			else if (event.keyCode == 65 || event.keyCode == 97)
			{
				muteButtonPressed();
			}
		}

		private function buttonClicked(event:EnigmaEvents):void
		{
			event.stopPropagation();
			switch(event.data.button)
			{
				case "go back":
					destroyQuestionScreen();
					break;
				case "submit answer":
					questionAnswered();
					break;
			}
		}

		private function radioClicked(event:EnigmaEvents):void
		{
			event.stopPropagation();
			Engine.playSound("down");
			_mcRadioSelected = event.data.selected;
		}

		private function drawQuestionScreen(type:String, row:int, column:int, isAnswered:Boolean=false):void
		{
			stopAccessibleCellTabs();
			removeEventListener(KeyboardEvent.KEY_DOWN, keyEventHandler);
			_questionScreen = new QuestionScreen(EngineCore.qSetData.items[row].name,
				getEnigmaQuestion(row, column),
				getEnigmaAnswer(row, column),
				type, row, column,
				this.ENIGMA_WIDTH, this.ENIGMA_HEIGHT,
				isAnswered, cellAnsweredNumber(row, column));
			addChild(_questionScreen);
			_viewingQuestionScreen = true;
		}

		private function destroyQuestionScreen():void
		{
			removeChild(_questionScreen);
			startAccessibleCellTabs();
			_viewingQuestionScreen = false;
			_score.newValue(_curScore);
			if (_questionsAnswered == _questionCount)
			{
				showEndButton();
			}
		}

		public function stopAccessibleCellTabs():void
		{
			for(var i:int = 0; i < _numRows; i++)
			{
				for(var b:int = 0; b < _numColumns; b++)
				{
						Accessible.stopTab(_board._rows[i]._cells[b]);
				}
			}
		}

		public function startAccessibleCellTabs():void
		{
			for(var i:int = 0; i < _numRows; i++)
			{
				for(var b:int = 0; b < _numColumns; b++)
				{
					if (!_board._rows[i]._cells[b].isEmpty)
					{
						Accessible.startTab(_board._rows[i]._cells[b]);
					}
					else
					{
						Accessible.stopTab(_board._rows[i]._cells[b]);
					}
				}
			}
		}

		private function questionAnswered():void
		{
			var column:int = _boardCellColumnSelected_qSetPosition;
			var row:int = _boardCellRowSelected;
			var radio:int = _mcRadioSelected;
			var scoreObj:Object = _scores[row][column];
			_questionsAnswered++;
			destroyQuestionScreen();
			_board._rows[row]._cells[column].cellAnswered();
			var answer:String = "";
			var answerValue:Number = 0;
			if (qSetData.items[row].items[column].answers[_mcRadioSelected].hasOwnProperty("value"))
			{
				answerValue = Number(qSetData.items[row].items[column].answers[_mcRadioSelected].value);
			}
			if (qSetData.items[row].items[column].answers[_mcRadioSelected].hasOwnProperty("text"))
			{
				answer = String(qSetData.items[row].items[column].answers[_mcRadioSelected].text);
			}
			var qSetValue:Number = Number(answerValue); // qsetvalue
			qSetValue = Number(qSetValue);
			qSetData.items[row].items[column].options = {"selectedAnswer": _mcRadioSelected};
			if (qSetValue == 100)
			{
				Engine.playSound("correct");
				_board._rows[row]._cells[column].drawCheck();
			}
			else if (qSetValue ==0)
			{
				Engine.playSound("wrong");
				_board._rows[row]._cells[column].drawX();
			}
			else
			{
				_board._rows[row]._cells[column].cellPercentage(qSetValue);
			}
			// submit score to server
			scoring.submitQuestionForScoring(String(qSetData.items[row].items[column].id), answer);
			var prevScore:Number = _curScore;
			_curScore = ((prevScore+(qSetValue/(_questionCount))));
			drawQuestionScreen("MC", row, column, true);
		}

		private function showEndButton():void
		{
			var endGameBox:Sprite = new Sprite();
			endGameBox.graphics.beginFill(this.BG_COLOR_TOPBAR, 1);
			endGameBox.graphics.drawRect(ENIGMA_WIDTH-150,ENIGMA_HEIGHT-95, 155, 95);
			endGameBox.graphics.endFill();
			addChild(endGameBox);
			var endGameMessage:TextField = new TextField();
			endGameMessage.width = 140;
			endGameMessage.selectable = false;
			endGameMessage.multiline = true;
			endGameMessage.embedFonts = true;
			addChild(endGameMessage);
			endGameMessage.htmlText = '<FONT ALIGN="center" FACE="Corbel" SIZE="12" COLOR="#FFFFFF">To submit your score, click END GAME.</FONT>';
			endGameMessage.wordWrap = true;
			endGameMessage.autoSize = TextFieldAutoSize.CENTER;
			endGameMessage.y = ENIGMA_HEIGHT-90;
			endGameMessage.x = ENIGMA_WIDTH-144;
			var endGameButton:EnigmaButton = new EnigmaButton("End Game");
			endGameButton.x = ENIGMA_WIDTH - endGameButton.width - 20;
			endGameButton.y = ENIGMA_HEIGHT - endGameButton.height - 24;
			endGameButton.addEventListener(EnigmaEvents.BUTTON_CLICKED, gameEnd, false, 0, true);
			addChild(endGameButton);
			Accessible.startTab(endGameButton);
		}

		private function gameEnd(e:Event = null):void
		{
			end();
		}

		private function cellTabFocus(event:EnigmaEvents):void
		{
			Engine.playSound("over");
			_boardCellRowSelected = event.data.row;
			_boardCellColumnSelected = event.data.column;
			_boardCellColumnSelected_qSetPosition = event.data.qSetPosition;
			if (!(this.hasEventListener(KeyboardEvent.KEY_DOWN)))
			{
				addEventListener(KeyboardEvent.KEY_DOWN, keyEventHandler, false, 0, true);
			}
		}
	}
}