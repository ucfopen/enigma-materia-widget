/* See the file "LICENSE.txt" for the full license governing this code. */
package screens
{
	import nm.gameServ.common.screens.Screen;
	public class MCQuestion extends Screen
	{
		private var numButtons:Number
		private var selected:Number
		public var btn_onColor:Number
		public var btn_offColor:Number
		public var rad_dotColor:Number
		public var rad_fillColor:Number
		public var rad_borderColor:Number
		public var rad_textColor:Number
		public var scrollAnswers:ScrollClip;
		public function MCQuestion()
		{
			curPage.submit.buttonMode = true;
			curPage.goBack.buttonMode = true;
			super();
			draw('MCQuestion');
		}
		private function draw(engine)
		{
			super.draw(engine)
			EventMC.init(curPage.submit);
			curPage.submit.addEventListener('ALL', this, 'button_event');
			EventMC.init(curPage.goback);
			curPage.goback.addEventListener('ALL', this, 'button_event');
			scrollAnswers = ScrollClip.create(curPage, ScrollClip, "scroll_answers", 5,  [615, 125, true]);
			scrollAnswers._y=curPage.answerbox._y;
			scrollAnswers._x=curPage.answerbox._x;
			scrollAnswers.draw();
		}
		private function button_event(eObj:Object)
		{
			switch(eObj.type)
			{
				case 'rollOut':
				case 'dragOut':
					var trans:ColorTransform = new ColorTransform()
					trans.rgb = btn_offColor
					eObj.target.fill.transform.colorTransform = trans
					break;
				case 'release':
				    if(eObj.target == curPage.submit)
				    {
						sendResult();
					}
					else
					{
						engine.showPage("board");
					}
					// no break, play down sound
				case 'press':
					engine.playSound("down");
					break;
				case 'rollOver':
					var trans:ColorTransform = new ColorTransform()
					trans.rgb = btn_onColor
					eObj.target.fill.transform.colorTransform = trans
					engine.playSound("over");
					break;
			}
		}
		private function radio_event(eObj:Object)
		{
			switch(eObj.type)
			{
				case 'release':
					selectRadio(Number(eObj.target._name.substring(11, 13)));
					// no break, play down sound
				case 'press':
					engine.playSound("down");
					break;
				case 'rollOver':
					engine.playSound("over");
					break;
			}
		}
		private function clearButtons()
		{
			for(var i=1; i<numButtons; i++)  // skip 0
			{
				scrollAnswers.clip['radioButton'+i].removeMovieClip();
			}
		}
		public function setLimit(numButtons:Number) {
			clearButtons()
			this.numButtons = numButtons
			// make colortransforms
			var dotTrans    = new ColorTransform()
			dotTrans.rgb    = rad_dotColor
			var fillTrans   = new ColorTransform()
			fillTrans.rgb   = rad_fillColor
			var borderTrans = new ColorTransform()
			borderTrans.rgb = rad_borderColor;
			// setup the first radio button
			var source:MovieClip = curPage.radioButtons.radioButton0
			colorizeRadio(source, rad_textColor, dotTrans, fillTrans, borderTrans)
			source.dot._visible = false
			EventMC.init(source);
			source.addEventListener('ALL', this, 'radio_event');
			selected = -1;
			source._visible = false;
			// set up the rest of the radio buttons
			for(var i=0; i<numButtons; i++)
			{
				var newR = scrollAnswers.clip.attachMovie("t1_mc_container", "radioButton"+i, scrollAnswers.clip.getNextHighestDepth());
				newR._y = (i*20)//source._y + (i*source._height)
				newR._x = 20
				newR._height = source._height
				newR._width = source._width
				newR.radioButton.dot._visible = false
				newR.radioButton.txtCaption.autoSize = true;
				EventMC.init(newR);
				newR.addEventListener('ALL', this, 'radio_event');
				colorizeRadio(newR, rad_textColor, dotTrans, fillTrans, borderTrans)
				newR.radioButton.txtCaption.embedFonts = true;
			}
			scrollAnswers.redraw();
		}
		private function colorizeRadio(rad:MovieClip, text:Number, dot:ColorTransform, fill:ColorTransform, border:ColorTransform)
		{
			rad.txtCaption.textColor = text
			rad.dot.transform.colorTransform = dot
			rad.bg.fill.transform.colorTransform = fill
			rad.bg.border.transform.colorTransform = border;
		}
		public function repositionRadio(i:Number)
		{
			if (i==0)
			{
				scrollAnswers.clip["radioButton"+i]._y = 0;
			}
			else
			{
				scrollAnswers.clip["radioButton"+i]._y = scrollAnswers.clip["radioButton"+(i-1)]._y+scrollAnswers.clip["radioButton"+(i-1)]._height;
			}
			scrollAnswers.redraw();
		}
		public function setRadioCaption(i:Number, label:String)
		{
			scrollAnswers.clip["radioButton"+i].radioButton.txtCaption.text = label;
		}
		private function selectRadio(clicked)
		{
			for (var i=0; i<numButtons; i++) scrollAnswers.clip["radioButton"+i].radioButton.dot._visible = false; // turn em all off
			scrollAnswers.clip["radioButton"+clicked].radioButton.dot._visible = true;
			selected = clicked;
		}
		private function validate(userAnswer:String, answers:Array):Boolean
		{
			// check for valid entry
			if(answers[userAnswer].score == 100) return true
			return false
		}
		private function sendResult()
		{
			if (selected != -1)
			{
				var valid:Boolean = engine.qSet.items[curPage.yPlace-1].items[curPage.xPlace-1].answers[selected].value == 100
				if (engine.qSet.items[curPage.yPlace-1].items[curPage.xPlace-1].answers[selected].value != undefined)
				{
					var value:Number = Number(engine.qSet.items[curPage.yPlace-1].items[curPage.xPlace-1].answers[selected].value)/100
				}
				else
				{
					var value:Number = 0;
				}
				engine.questionAnswered(curPage.xPlace, curPage.yPlace, engine.qSet.items[curPage.yPlace-1].items[curPage.xPlace-1].answers[selected].text, valid, value);
			}
		}
	}
}