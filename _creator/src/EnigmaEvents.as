package
{
	import flash.events.Event;
	public class EnigmaEvents extends Event
	{
		public static const QUESTION_DRAG:String = "questionDrag";
		public static const QUESTION_DRAG_COMPLETE:String = "questionDragComplete";
		public static const CATEGORY_DRAG:String = "categoryDrag";
		public static const ADD_QUESTION:String = "addQuestion";
		public static const QUESTION_HIT:String = "questionHit";
		public static const CATEGORY_QUESTION_HIT:String = "categoryQuestionHit";
		public static const CATEGORY_QUESTION_MOUSE_DOWN:String = "categoryQuestionMouseDown";
		public static const FOCUS_ON_ANSWER:String = "focusOnAnswer";
		public static const FOCUS_OUT_ANSWER:String = "focusOutAnswer";
		public static const FOCUS_ON_CATEGORY_NAME:String = "focusOnCategoryName";
		public static const FOCUS_OUT_CATEGORY_NAME:String = "focusOutCategoryName";
		public static const DELETE_ANSWER_CLICKED:String = "deleteAnswerClicked";
		public static const DELETE_CATEGORY_CLICKED:String = "deleteCategoryClicked";
		public static const DELETE_QUESTION_CLICKED:String = "deleteQuestionClicked";
		public static const DELETE_QUESTION_IN_CATEGORY:String = "deleteQuestionInCategory";
		public var data:Object;
		public function EnigmaEvents(type:String, data:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.data = data;
		}
	}
}