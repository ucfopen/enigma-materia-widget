describe('Creator Controller', function() {
	require('angular/angular.js');
	require('angular-mocks/angular-mocks.js');

	var $scope
	var $controller
	var $timeout
	var widgetInfo
	var qset

	beforeEach(() => {
		jest.resetModules()

		// mock materia
		global.Materia = {
			CreatorCore: {
				start: jest.fn(),
				alert: jest.fn(),
				cancelSave: jest.fn(),
				save: jest.fn().mockImplementation((title, qset) => {
					//the creator core calls this on the creator when saving is successful
					$scope.onSaveComplete();
					return {title: title, qset: qset};
				})
			}
		}

		// load qset
		widgetInfo = require('../demo.json')
		qset = widgetInfo.qset;

		// load the required code
		angular.mock.module('enigmaCreator')
		angular.module('dndLists', [])
		require('../modules/creator.coffee')
		require('./creator.coffee')

		// mock scope
		$scope = {
			$apply: jest.fn().mockImplementation(fn => {fn()})
		}

		// initialize the angualr controller
		inject(function(_$controller_, _$timeout_){
			$timeout = _$timeout_;
			// instantiate the controller
			$controller = _$controller_('enigmaCreatorCtrl', { $scope: $scope });
		})
	})

	function quickValue(ans, val, exp) {
		ans.value = val;
		$scope.numbersOnly(ans);
		expect(ans.value).toBe(exp);
		if(val < 100) expect(ans.options.correct).toBe(false);
	}

	var quickCategory = function(index, name) {
		$scope.newCategory(index, $scope.qset.items[index]);
		$scope.qset.items[index].name = name;
		$scope.stopCategory($scope.qset.items[index]);
	};

	var quickQuestion = function(catIndex, qIndex, text) {
		$scope.editQuestion($scope.qset.items[catIndex], $scope.qset.items[catIndex].items[qIndex], qIndex);
		$scope.curQuestion.questions[0].text = text;
		$scope.curQuestion.answers[0].text = text+'Answer1';
		$scope.curQuestion.answers[0].value = 100;
		$scope.curQuestion.answers[1].text = text+'Answer2';
		$scope.editComplete();
	};

	it('should edit a new widget', function(){
		//this method is normally called by Angular any time something happens on the page
		//it'll actually run before the qset has been loaded
		expect($scope.numQuestions()).toBe(0);

		$scope.initNewWidget(widgetInfo);
		//time to check default values; first the title
		expect($scope.title).toBe('My Enigma widget');
		//next make sure there are six categories and that they each have six blank questions in them
		expect($scope.qset.items.length).toBe(5);
		for(var i = 0; i < 5; i++)
		{
			expect($scope.qset.items[i].items.length).toBe(6);
			for(var j = 0; j < 5; j++)
			{
				expect($scope.qset.items[i].items[j].untouched).toBe(true);
				expect($scope.qset.items[i].items[j].questions[0].text).toBe('');
				expect($scope.qset.items[i].items[j].complete).toBe(false);
				//and each new question should have two blank answers
				expect($scope.qset.items[i].items[j].answers.length).toBe(2);
				for(var k = 0; k < 2; k++)
				{
					expect($scope.qset.items[i].items[j].answers[k].text).toBe('');
					expect($scope.qset.items[i].items[j].answers[k].value).toBe(0);
				}
			}
		}
		//the intro dialog should be displaying
		expect($scope.showIntroDialog).toBe(true);
		expect($scope.step).toBe(0);
		//there should be zero valid questions
		expect($scope.numQuestions()).toBe(0);
	});

	it('should set the title from the intro dialog', function(){
		$scope.initNewWidget(widgetInfo);
		// end setup

		$scope.introTitle = 'Test';
		//this method should only be runnable from the intro dialog
		$scope.setTitle();
		expect($scope.title).toBe('Test');
		//the intro dialog should no longer be displaying
		expect($scope.showIntroDialog).toBe(false);
		expect($scope.step).toBe(1);
	});

	//normally 'introTitle' is only usable once, from the intro dialog
	it('should not allow a non-string title from the intro dialog', function(){
		$scope.initNewWidget(widgetInfo);
		// end setup

		$scope.introTitle = 'Test';
		$scope.setTitle();
		expect($scope.title).toBe('Test');

		$scope.introTitle = null;
		$scope.setTitle();
		expect($scope.title).toBe('Test');
	});

	//again; normally the intro dialogue should only come up once, when making new widgets
	it('should close the intro dialog when the background is clicked', function(){
		$scope.initNewWidget(widgetInfo);
		// end setup

		//we can pretend we're still on the 'intro title' step by resetting some variables
		$scope.step = 0;
		$scope.showIntroDialog = true;

		//clicking the darkened background when a dialog window is up will dismiss it
		//in the case of the intro screen, it will also advance to the next step in the tutorial
		$scope.hideCover();
		expect($scope.showIntroDialog).toBe(false);
		expect($scope.step).toBe(1);
	});

	it('should set opacity for each default category properly', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		// end setup

		//category opacity is set according to whether the category has been edited/has questions or not
		//0.1 for untouched categories and 1 for categories with a name/questions
		//1 for the first category if the tutorial is on the 'create first category' step

		//this method is called by Angular for each category on the page
		//we can pretend by supplying an index and category object for the five default categories
		expect($scope.categoryOpacity($scope.qset.items[0], 0)).toBe(1);
		expect($scope.categoryOpacity($scope.qset.items[1], 1)).toBe(0.1);
		expect($scope.categoryOpacity($scope.qset.items[2], 2)).toBe(0.1);
		expect($scope.categoryOpacity($scope.qset.items[3], 3)).toBe(0.1);
		expect($scope.categoryOpacity($scope.qset.items[4], 4)).toBe(0.1);
	});

	it('should determine whether the category add button is shown', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		// end setup

		//the add button for a category is shown if that category is the topmost unedited category in the list

		//this method is called by Angular for each category on the page
		//we can pretend by supplying an index and category object for the five default categories
		expect($scope.categoryShowAdd($scope.qset.items[0], 0)).toBe(true);
		expect($scope.categoryShowAdd($scope.qset.items[1], 1)).toBe(false);
		expect($scope.categoryShowAdd($scope.qset.items[2], 2)).toBe(false);
		expect($scope.categoryShowAdd($scope.qset.items[3], 3)).toBe(false);
		expect($scope.categoryShowAdd($scope.qset.items[4], 4)).toBe(false);
	});

	it('should determine whether a category is "enabled"', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		// end setup

		//a category is 'disabled' and thus won't react to any inputs unless it is the topmost unedited category in the list,
		//or has been named

		//this method is called by Angular for each category on the page
		//we can pretend by supplying an index and category object for the five default categories
		expect($scope.categoryEnabled($scope.qset.items[0], 0)).toBe(true);
		expect($scope.categoryEnabled($scope.qset.items[1], 1)).toBe(false);
		expect($scope.categoryEnabled($scope.qset.items[2], 2)).toBe(false);
		expect($scope.categoryEnabled($scope.qset.items[3], 3)).toBe(false);
		expect($scope.categoryEnabled($scope.qset.items[4], 4)).toBe(false);
	});

	it('should determine whether the question add button is shown', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		// end setup

		//the add button for a question is shown if that question's category is enabled,
		//and that question is the rightmost unedited question in the category

		//this method is called by Angular for each question in each category on the page
		//we can pretend by supplying a category/question/index for the six default questions in the first category
		expect($scope.questionShowAdd($scope.qset.items[0], $scope.qset.items[0].items[0], 0)).toBe(false);
		expect($scope.questionShowAdd($scope.qset.items[0], $scope.qset.items[0].items[1], 1)).toBe(false);
		expect($scope.questionShowAdd($scope.qset.items[0], $scope.qset.items[0].items[2], 2)).toBe(false);
		expect($scope.questionShowAdd($scope.qset.items[0], $scope.qset.items[0].items[3], 3)).toBe(false);
		expect($scope.questionShowAdd($scope.qset.items[0], $scope.qset.items[0].items[4], 4)).toBe(false);
		expect($scope.questionShowAdd($scope.qset.items[0], $scope.qset.items[0].items[5], 5)).toBe(false);

		//check the first question of the second category just to make sure
		expect($scope.questionShowAdd($scope.qset.items[1], $scope.qset.items[1].items[0], 0)).toBe(false);
	});

	it('should make a new category', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		// end setup

		//this is normally accomplished by clicking an element on the page
		//angular keeps track of the index of that item in the list, but we can do so manually
		$scope.newCategory(0, $scope.qset.items[0]);

		expect($scope.qset.items[0].isEditing).toBe(true);
		//since this was the first new category, we were still in the tutorial
		expect($scope.step).toBe(2);
	});

	it('should do nothing if the category currently being edited was not given a name', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		// end setup

		$scope.stopCategory($scope.qset.items[0]);
		//we didn't give the category a name - so aside from no longer editing the category, nothing should change
		expect($scope.qset.items[0].isEditing).toBe(false);
		expect($scope.qset.items[0].untouched).toBe(true);
		expect($scope.step).toBe(2);
	});

	it('should name the first category properly', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		// end setup

		$scope.newCategory(0, $scope.qset.items[0]);

		$scope.qset.items[0].name = 'Test';
		//it has a name this time, so the tutorial should advance properly
		$scope.stopCategory($scope.qset.items[0]);
		expect($scope.qset.items[0].isEditing).toBe(false);
		expect($scope.qset.items[0].untouched).toBe(false);
		expect($scope.step).toBe(3);
	});

	//if the 'add first question' step has not been completed and the only category has been deleted,
	//revert the tutorial to the 'create first category' step
	it('should revert to the "create first category" step if appropriate', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		// end setup

		//deletion only occurs after a confirmation dialog; assume true this time
		$scope.deleteCategory($scope.qset.items[0]);
		expect($scope.step).toBe(1);

		//now remake that first category
		$scope.newCategory(0, $scope.qset.items[0]);

		$scope.qset.items[0].name = 'Test';
		//it has a name this time, so the tutorial should advance properly
		$scope.stopCategory($scope.qset.items[0]);
		expect($scope.qset.items[0].isEditing).toBe(false);
		expect($scope.qset.items[0].untouched).toBe(false);
		expect($scope.step).toBe(3);
	});

	it('should correctly enable, set opacity, display buttons for the second category after the first has been named', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		// end setup

		//now that the first category is named, it should still be fully opaque
		expect($scope.categoryOpacity($scope.qset.items[0], 0)).toBe(1);
		//but not show its 'add' button'
		expect($scope.categoryShowAdd($scope.qset.items[0], 0)).toBe(false);

		//now that the second category is the earliest untouched category, it should display its 'add' button
		expect($scope.categoryShowAdd($scope.qset.items[1], 1)).toBe(true);
		//and be enabled
		expect($scope.categoryEnabled($scope.qset.items[1], 1)).toBe(true);
	});

	it('should also show the add button for the first question in the first category', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		// end setup

		expect($scope.questionShowAdd($scope.qset.items[0], $scope.qset.items[0].items[0], 0)).toBe(true);

		//just to make sure - second question in first category should still be false
		expect($scope.questionShowAdd($scope.qset.items[0], $scope.qset.items[0].items[1], 1)).toBe(false);
	});

	it('should not allow template questions in unnamed categories to be edited', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		// end setup

		expect($scope.curCategory).toBe(false);
		expect($scope.curQuestion).toBe(false);

		//this method is called by clicking an editable question on the board
		//if that question is not editable, it should simply do nothing
		//since we haven't edited the first question yet, trying to edit the second question shouldn't do anything
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[1], 1);
		expect($scope.curCategory).toBe(false);
		expect($scope.curQuestion).toBe(false);

		//same story for the first question in the second category
		$scope.editQuestion($scope.qset.items[1], $scope.qset.items[0].items[0], 0);
		expect($scope.curCategory).toBe(false);
		expect($scope.curQuestion).toBe(false);
	});

	it('should edit the first question', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		// end setup

		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		expect($scope.curCategory).toEqual($scope.qset.items[0]);
		expect($scope.curQuestion).toEqual($scope.qset.items[0].items[0]);
	});

	it('should point out all problems with an unfinished question', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		// end setup

		//this method runs when the 'Done' button is clicked on the question edit window
		//any problems with the question should be displayed on the screen
		//these problems will exist in an array that we can check, luckily
		$scope.editComplete();
		expect($scope.curCategory).toBe(false);
		expect($scope.curQuestion).toBe(false);

		//there should be no warnings this time, only errors
		expect($scope.warningMessage).toBe(false);

		//every error should be there, along with the general 'incomplete question' error
		expect($scope.incompleteMessage).toContain('Warning: this question is incomplete!');
		expect($scope.incompleteMessage).toContain('Question undefined.');
		expect($scope.incompleteMessage).toContain('Inadequate credit.');
		expect($scope.incompleteMessage).toContain('Duplicate answers.');
		expect($scope.incompleteMessage).toContain('Blank answer(s).');

		//questions come with two blank answers by default, so this shouldn't be a problem yet
		expect($scope.incompleteMessage).not.toContain('No answers.');

		//since the question isn't valid, we should still be showing zero valid questions
		expect($scope.numQuestions()).toBe(0);
	});

	it('should remove the error message after time has elapsed', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		// end setup

		//the error message is on a timer so that it's cleared out once the page element finishes fading out
		$timeout.flush();
		expect($scope.incompleteMessage).toBe(false);
		expect($scope.warningMessage).toBe(false);
	});

	it('should no longer point out the "Question undefined" error', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		// end setup

		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);

		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();

		expect($scope.qset.items[0].items[0].questions[0].text).toBe('Test');

		//everything but the 'Question undefined' message should still be present
		expect($scope.incompleteMessage).toContain('Warning: this question is incomplete!');
		expect($scope.incompleteMessage).not.toContain('Question undefined.');
		expect($scope.incompleteMessage).toContain('Inadequate credit.');
		expect($scope.incompleteMessage).toContain('Duplicate answers.');
		expect($scope.incompleteMessage).toContain('Blank answer(s).');
		expect($scope.incompleteMessage).not.toContain('No answers.');
	});

	it('should remove the error message early', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		// end setup

		expect($scope.incompleteMessage).toContain('Warning: this question is incomplete!');
		//normally this method is called once the ten second error message timer elapses
		//it's also called if the error message element on the page is clicked prior to the timer elapsing
		$scope.killAlert();
		expect($scope.incompleteMessage).toBe(false);
		expect($scope.warningMessage).toBe(false);
	});

	it('should delete answers', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		// end setup

		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);

		expect($scope.curQuestion.answers.length).toBe(2);

		//this method runs when the 'X' button next to an answer in the question edit window is clicked
		//quick bonus test - this should do nothing, since the question only has 2 answers in it
		$scope.deleteAnswer(2);

		expect($scope.curQuestion.answers.length).toBe(2);

		$scope.deleteAnswer(1);
		expect($scope.curQuestion.answers.length).toBe(1);

		$scope.deleteAnswer(0);
		expect($scope.curQuestion.answers.length).toBe(0);
	});

	it('should no longer point out the "Duplicate answers" error', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		// end setup

		$scope.editComplete();

		//since we no longer have two answers with the same text, the 'duplicate answers' problem should no longer appear
		expect($scope.incompleteMessage).toContain('Warning: this question is incomplete!');
		expect($scope.incompleteMessage).not.toContain('Question undefined.');
		expect($scope.incompleteMessage).toContain('Inadequate credit.');
		expect($scope.incompleteMessage).not.toContain('Duplicate answers.');

		//bonus - no blank answers, because no answers
		expect($scope.incompleteMessage).not.toContain('Blank answer(s).');
		expect($scope.incompleteMessage).toContain('No answers.');
	});

	it('should add an answer', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		// end setup

		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);

		//should still have no answers
		expect($scope.curQuestion.answers.length).toBe(0);

		//this method is normally called when a button is clicked on the page
		$scope.addAnswer();
	});

	it('should no longer point out the "No answers" error', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		// end setup

		$scope.editComplete();

		expect($scope.incompleteMessage).toContain('Warning: this question is incomplete!');
		expect($scope.incompleteMessage).not.toContain('Question undefined.');
		expect($scope.incompleteMessage).toContain('Inadequate credit.');
		expect($scope.incompleteMessage).not.toContain('Duplicate answers.');
		expect($scope.incompleteMessage).not.toContain('No answers.');

		//we added a question but didn't do anything to it - should get this one again
		expect($scope.incompleteMessage).toContain('Blank answer(s).');
		$timeout.flush();
	});

	it('should only allow numeric values between 0 and 100 for answer credit values', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		// end setup

		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);

		//this method is normally called every single time an answer's value is changed
		//we can approximate it by changing the answer's value and calling the method manually
		//we're only really interested in making sure any non-numbers are filtered out
		//since this method should run every time a character changes, most of these should be impossible anyway
		quickValue($scope.curQuestion.answers[0], 'Invalid', 0);
		quickValue($scope.curQuestion.answers[0], '0wrong', 0);
		quickValue($scope.curQuestion.answers[0], '3arr0wrong', 30);
		quickValue($scope.curQuestion.answers[0], '', 0);

		//make sure it handles valid input correctly
		quickValue($scope.curQuestion.answers[0], '3', 3);
		quickValue($scope.curQuestion.answers[0], '30', 30);

		//make sure it constrains values between 0 and 100
		quickValue($scope.curQuestion.answers[0], '300', 100);
		quickValue($scope.curQuestion.answers[0], '-200', 0);
	});

	it('should still point out the "Inadequate credit" error', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		// end setup

		//until a question has at least one answer worth 100%, it does not have adequate credit
		//let's make sure that error message is still in the list even with partial credit answers
		quickValue($scope.curQuestion.answers[0], '30', 30);
		$scope.editComplete();

		//since we no longer have two answers with the same text, the 'duplicate answers' problem should no longer appear
		expect($scope.incompleteMessage).toContain('Inadequate credit.');
	});

	it('should flag answers as "custom" properly when editing a question', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		// end setup

		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		expect($scope.curQuestion.answers[0].options.custom).toBe(true);
		expect($scope.curQuestion.answers[0].options.correct).toBe(false);
	});

	it('should no longer point out the "Inadequate credit" error', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		// end setup

		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();

		//since we now have at least one answer worth full credit, the 'inadequate credit' problem should no longer appear
		expect($scope.incompleteMessage).toContain('Warning: this question is incomplete!');
		expect($scope.incompleteMessage).not.toContain('Question undefined.');
		expect($scope.incompleteMessage).not.toContain('Inadequate credit.');
		expect($scope.incompleteMessage).not.toContain('Duplicate answers.');
		expect($scope.incompleteMessage).not.toContain('No answers.');
		expect($scope.incompleteMessage).toContain('Blank answer(s).');
	});

	it('should flag answers as "correct" properly when editing a question', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		// end setup

		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		expect($scope.curQuestion.answers[0].options.correct).toBe(true);
		expect($scope.curQuestion.answers[0].options.custom).toBe(false);
	});

	it('should set answer value correctly when toggling between correct and wrong', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '100', 100);

		expect($scope.curQuestion.answers[0].value).toBe(100);
		//this is normally attached to an input in the frontend thanks to ngModel
		//changing to to 'false' by hand here simulates the automatic change that facilitates
		$scope.curQuestion.answers[0].options.correct = false;
		$scope.toggleCorrect($scope.curQuestion.answers[0]);

		expect($scope.curQuestion.answers[0].value).toBe(0);
	});

	it('should no longer point out the "Blank answer" error', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		// end setup

		$scope.curQuestion.answers[0].text = 'Answer1';

		$scope.editComplete();

		//this question should be mostly valid now, so we shouldn't have any error messages
		expect($scope.incompleteMessage).not.toContain('Warning: this question is incomplete!');
		expect($scope.incompleteMessage).not.toContain('Question undefined.');
		expect($scope.incompleteMessage).not.toContain('Inadequate credit.');
		expect($scope.incompleteMessage).not.toContain('Duplicate answers.');
		expect($scope.incompleteMessage).not.toContain('Blank answer(s).');
	});

	it('should point out warnings for potentially unfinished questions', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		// end setup

		//since we just finished editing the last question, the incomplete message should still be set
		//however, since these aren't 'errors', they should be counted as warnings
		expect($scope.warningMessage).toBe(true);
		expect($scope.incompleteMessage).toContain('Attention: this question may be incomplete!');

		//for now, only one warning message is possible - having only a single answer
		expect($scope.incompleteMessage).toContain('Only one answer found.');

		//the question is technically valid however, so make sure that's recognized
		expect($scope.numQuestions()).toBe(1);
	});

	it('should point out no warnings or errors', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		// end setup

		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();

		//make sure to at least give the answer some text, or we'll get the Blank Answer error again
		$scope.curQuestion.answers[1].text = 'Answer2';

		$scope.editComplete();

		expect($scope.incompleteMessage).toBe(false);
		expect($scope.warningMessage).toBe(false);
	});

	it('should warn before deleting a category with questions in it', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		// end setup

		var before = $scope.qset.items[0];
		spyOn(window, 'confirm').and.returnValue(false);
		$scope.deleteCategory($scope.qset.items[0]);

		//nothing should have happened, so the first category should be the same
		expect(before).toEqual($scope.qset.items[0]);

		//make sure the correct message was sent to the confirmation window
		expect(window.confirm).toHaveBeenCalledWith("Deleting this category will also delete all of the questions it contains!\n\nAre you sure?");
	});

	it('should delete a category after confirmation', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		// end setup

		//this time, let's assume we cancel the action before deleting the category
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)

		var before = $scope.qset.items[0];

		$scope.deleteCategory($scope.qset.items[0]);

		//the new first category should not be the old first category
		expect(before).not.toEqual($scope.qset.items[0]);

		//also we should be back to zero questions
		expect($scope.numQuestions()).toBe(0);
	});


	it('should add another category', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		// end setup

		//we deleted the only category, so every category should be untouched now
		for(var i = 0; i < $scope.qset.items.length; i++)
		{
			expect($scope.qset.items[i].untouched).toBe(true);
		}

		//this method is normally called by clicking a button on the page
		//we can approximate it by keeping track of which index we're adding a category at
		quickCategory(0, 'Cat1');
		expect($scope.qset.items[0].untouched).toBe(false);
		expect($scope.qset.items[0].name).toBe('Cat1');
	});

	it('should react properly when editing the 5th default category', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		// end setup

		//by default, Enigma widgets have five blank categories
		//every time the second to last category is named, another should be added to the end of the list
		//this allows users to make as many categories as necessary
		expect($scope.qset.items.length).toBe(5);

		//start by editing the other four
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');

		expect($scope.categoryShowAdd($scope.qset.items[0], 0)).toBe(false);
		expect($scope.categoryShowAdd($scope.qset.items[1], 1)).toBe(false);
		expect($scope.categoryShowAdd($scope.qset.items[2], 2)).toBe(false);
		expect($scope.categoryShowAdd($scope.qset.items[3], 3)).toBe(false);
		expect($scope.categoryShowAdd($scope.qset.items[4], 4)).toBe(false);
		expect($scope.categoryShowAdd($scope.qset.items[5], 5)).toBe(true);
		expect($scope.categoryEnabled($scope.qset.items[5], 5)).toBe(true);

		//make sure there's a 6th category
		expect($scope.qset.items.length).toBe(6);
		expect($scope.qset.items[5].untouched).toBe(true);
	});

	it('should rearrange categories', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		// end setup

		//this method is normally called by clicking an element on the page attached to any category
		//shift the first category down
		$scope.categoryReorder(0, true);
		expect($scope.qset.items[0].name).toBe('Cat2');
		expect($scope.qset.items[1].name).toBe('Cat1');

		//shift the fifth category up
		$scope.categoryReorder(4, false);
		expect($scope.qset.items[3].name).toBe('Cat5');
		expect($scope.qset.items[4].name).toBe('Cat4');
	});

	it('should edit the name of a category', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		// end setup

		//this method is normally called by clicking a category label
		$scope.editCategory($scope.qset.items[0]);

		expect($scope.qset.items[0].name).toBe('Cat1');

		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);

		expect($scope.qset.items[0].name).toBe('NewCat1');
	});

	it('should not allow a category to have no name if it has questions in it', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		// end setup

		//trying to rename a category to an empty string is interpreted as 'delete this category'
		//if the category has questions in it, the standard deletion warning will come up
		//in this case, assume we're going to cancel
		window.confirm.mockReturnValueOnce(false)

		//first let's add a valid question to the first category
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Question';
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.curQuestion.answers[0].value = 100;
		$scope.curQuestion.answers[1].text = 'Answer2';
		$scope.editComplete();

		//try setting the name to an empty string
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = '';
		$scope.stopCategory($scope.qset.items[0]);

		//the name shouldn't have changed from what we set it to before
		expect($scope.qset.items[0].name).toBe('NewCat1');
	});

	it('should delete an empty category when unsetting its name', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		// end setup

		var before = $scope.qset.items[1];
		$scope.editCategory($scope.qset.items[1]);
		$scope.qset.items[1].name = '';
		$scope.stopCategory($scope.qset.items[1]);

		expect($scope.qset.items[1]).not.toEqual(before);
	});

	it('should delete a non-empty category when unsetting its name after confirmation', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		// end setup

		//as before, a confirmation window will come up before deletion
		//this time, assume we're going to confirm
		spyOn(window, 'confirm').and.returnValue(true);
		var before = $scope.qset.items[0];

		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = '';
		$scope.stopCategory($scope.qset.items[0]);

		expect($scope.qset.items[0]).not.toEqual(before);
	});

	it('should rearrange questions', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		// end setup

		//make a few questions first
		quickQuestion(0, 0, 'Question1');
		quickQuestion(0, 1, 'Question2');
		quickQuestion(0, 2, 'Question3');

		//just to make sure
		expect($scope.numQuestions()).toBe(3);

		//let's shift the first question forward
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		expect($scope.curQuestion.index).toBe(0);

		//this method is normally called by clicking an arrow in the edit question interface
		$scope.questionReorder(true);

		expect($scope.curQuestion.index).toBe(1);
		//again
		$scope.questionReorder(true);
		expect($scope.curQuestion.index).toBe(2);

		//just to be sure
		expect($scope.qset.items[0].items[0].questions[0].text).toBe('Question2');

		$scope.editComplete();

		//shift the second question backward
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[1], 1);
		expect($scope.curQuestion.index).toBe(1);

		$scope.questionReorder(false);
		expect($scope.curQuestion.index).toBe(0);

		expect($scope.qset.items[0].items[1].questions[0].text).toBe('Question2');
	});

	it('should delete questions', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		quickQuestion(0, 0, 'Question1');
		quickQuestion(0, 1, 'Question2');
		quickQuestion(0, 2, 'Question3');
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.questionReorder(true);
		$scope.questionReorder(true);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[1], 1);
		$scope.questionReorder(false);
		// end setup

		//after all the shifting we did before, the old third question should now be the first question
		expect($scope.qset.items[0].items[0].questions[0].text).toBe('Question3');

		//this method is normally called by clicking a button in the edit question interface
		$scope.deleteQuestion();

		//the new first question should now be the old second question
		expect($scope.qset.items[0].items[0].questions[0].text).toBe('Question2');
	});

	it('should not "mark" questions that have not been touched', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		quickQuestion(0, 0, 'Question1');
		quickQuestion(0, 1, 'Question2');
		quickQuestion(0, 2, 'Question3');
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.questionReorder(true);
		$scope.questionReorder(true);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[1], 1);
		$scope.questionReorder(false);
		$scope.deleteQuestion();
		// end setup

		//these two variables keep track of which question is being hovered over, in which category
		expect($scope.hoverQuestion).toBe(false);
		expect($scope.hoverCategory).toBe(false);

		//this method is normally called by hovering the mouse cursor over a question on the page
		//if the question hovered over has not been edited yet, it should do nothing
		//the first category should only have two questions now, so hovering over the third should do nothing
		$scope.markQuestion($scope.qset.items[0], $scope.qset.items[0].items[2]);

		expect($scope.hoverQuestion).toBe(false);
		expect($scope.hoverCategory).toBe(false);
	});

	it('should mark questions that have been edited', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		quickQuestion(0, 0, 'Question1');
		quickQuestion(0, 1, 'Question2');
		quickQuestion(0, 2, 'Question3');
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.questionReorder(true);
		$scope.questionReorder(true);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[1], 1);
		$scope.questionReorder(false);
		$scope.deleteQuestion();
		// end setup

		expect($scope.hoverQuestion).toBe(false);
		expect($scope.hoverCategory).toBe(false);

		$scope.markQuestion($scope.qset.items[0], $scope.qset.items[0].items[0]);

		//the variables keeping track of which category/question we're hovering over should change accordingly
		expect($scope.hoverQuestion).toEqual($scope.qset.items[0].items[0]);
		expect($scope.hoverCategory).toEqual($scope.qset.items[0]);
	});

	it('should unmark questions', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		quickQuestion(0, 0, 'Question1');
		quickQuestion(0, 1, 'Question2');
		quickQuestion(0, 2, 'Question3');
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.questionReorder(true);
		$scope.questionReorder(true);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[1], 1);
		$scope.questionReorder(false);
		$scope.deleteQuestion();
		$scope.markQuestion($scope.qset.items[0], $scope.qset.items[0].items[0]);
		// end setup

		//the 'marked' question should be the same as the last test
		expect($scope.hoverQuestion).toEqual($scope.qset.items[0].items[0]);
		expect($scope.hoverCategory).toEqual($scope.qset.items[0]);

		//this method is normally called when the mouse cursor is no longer over a question that it was previously over
		$scope.unmarkQuestion();

		//no question should be marked any more
		expect($scope.hoverQuestion).toBe(false);
		expect($scope.hoverCategory).toBe(false);
	});

	it('should import questions', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		quickQuestion(0, 0, 'Question1');
		quickQuestion(0, 1, 'Question2');
		quickQuestion(0, 2, 'Question3');
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.questionReorder(true);
		$scope.questionReorder(true);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[1], 1);
		$scope.questionReorder(false);
		$scope.deleteQuestion();
		$scope.markQuestion($scope.qset.items[0], $scope.qset.items[0].items[0]);
		// end setup

		//this method is normally called by the parent creator page
		//the creator page passes in a list of questions that have been chosen for import

		//for the sake of simplicity, import the first three questions from the demo widget
		$scope.onQuestionImportComplete(qset.data.items[0].items);

		//the list of imported questions should match what we just gave it
		expect($scope.imported).toEqual(qset.data.items[0].items);
	});

	it('should import more questions', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		quickQuestion(0, 0, 'Question1');
		quickQuestion(0, 1, 'Question2');
		quickQuestion(0, 2, 'Question3');
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.questionReorder(true);
		$scope.questionReorder(true);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[1], 1);
		$scope.questionReorder(false);
		$scope.deleteQuestion();
		$scope.markQuestion($scope.qset.items[0], $scope.qset.items[0].items[0]);
		$scope.onQuestionImportComplete(qset.data.items[0].items);
		// end setup

		//we should also be able to import questions more than once and grow the list
		$scope.onQuestionImportComplete([qset.data.items[1].items[0], qset.data.items[1].items[1]]);

		//make sure the imported list of questions has everything we've given it so far
		expect($scope.imported).toContain(qset.data.items[0].items[0]);
		expect($scope.imported).toContain(qset.data.items[0].items[1]);
		expect($scope.imported).toContain(qset.data.items[0].items[2]);
		expect($scope.imported).toContain(qset.data.items[1].items[0]);
		expect($scope.imported).toContain(qset.data.items[1].items[1]);
	});

	it('should add imported questions to categories as desired', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		quickQuestion(0, 0, 'Question1');
		quickQuestion(0, 1, 'Question2');
		quickQuestion(0, 2, 'Question3');
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.questionReorder(true);
		$scope.questionReorder(true);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[1], 1);
		$scope.questionReorder(false);
		$scope.deleteQuestion();
		$scope.markQuestion($scope.qset.items[0], $scope.qset.items[0].items[0]);
		$scope.onQuestionImportComplete(qset.data.items[0].items);
		$scope.onQuestionImportComplete([qset.data.items[1].items[0], qset.data.items[1].items[1]]);
		// end setup

		var before = $scope.imported[0];

		//the angular drag and drop library handles most of this process
		//this method is normally called when a dragged import question is dropped on a category
		//for now let's try adding the first imported question to the first category
		var importStat = $scope.importDropped($scope.qset.items[0], $scope.imported[0]);

		//the importDropped method will return true or false if the import action was successful
		//normally the drag and drop library would use this, removing the item from the source list on true
		expect(importStat).toBe(true);
		//there were already two questions, the one we imported should become the third
		expect($scope.qset.items[0].items[2]).toEqual($scope.imported[0]);

		if(importStat) {
			//since the drag and drop library isn't available, remove the imported item from the source list manually
			$scope.imported.splice(0, 1);
		}
	});

	it('should not add imported questions to full categories', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		quickQuestion(0, 0, 'Question1');
		quickQuestion(0, 1, 'Question2');
		quickQuestion(0, 2, 'Question3');
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.questionReorder(true);
		$scope.questionReorder(true);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[1], 1);
		$scope.questionReorder(false);
		$scope.deleteQuestion();
		$scope.markQuestion($scope.qset.items[0], $scope.qset.items[0].items[0]);
		$scope.onQuestionImportComplete(qset.data.items[0].items);
		$scope.onQuestionImportComplete([qset.data.items[1].items[0], qset.data.items[1].items[1]]);
		$scope.importDropped($scope.qset.items[0], $scope.imported[0]);
		$scope.imported.splice(0, 1);
		// end setup

		//first, fill the rest of the category with questions
		quickQuestion(0, 3, 'Question1');
		quickQuestion(0, 4, 'Question1');
		quickQuestion(0, 5, 'Question1');

		//this should do nothing, and return false
		var importStat = $scope.importDropped($scope.qset.items[0], $scope.imported[0]);

		expect(importStat).toBe(false);

		//this is normally accomplished via a button click on the page
		$scope.imported = [];
	});

	it('should not save if any questions are invalid', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		quickQuestion(0, 0, 'Question1');
		quickQuestion(0, 1, 'Question2');
		quickQuestion(0, 2, 'Question3');
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.questionReorder(true);
		$scope.questionReorder(true);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[1], 1);
		$scope.questionReorder(false);
		$scope.deleteQuestion();
		$scope.markQuestion($scope.qset.items[0], $scope.qset.items[0].items[0]);
		$scope.onQuestionImportComplete(qset.data.items[0].items);
		$scope.onQuestionImportComplete([qset.data.items[1].items[0], qset.data.items[1].items[1]]);
		$scope.importDropped($scope.qset.items[0], $scope.imported[0]);
		$scope.imported.splice(0, 1);
		quickQuestion(0, 3, 'Question1');
		quickQuestion(0, 4, 'Question1');
		quickQuestion(0, 5, 'Question1');
		$scope.importDropped($scope.qset.items[0], $scope.imported[0]);
		$scope.imported = [];
		// end setup

		//every question should be valid for now, so add an incomplete one to the second category
		$scope.editQuestion($scope.qset.items[1], $scope.qset.items[1].items[0], 0);
		$scope.editComplete();

		//providing the argument is unnecessary, as the creator core will do it
		//but it covers another branch
		$scope.onSaveClicked('save');

		//if there are any problems, a message will be generated and sent when the save is canceled
		//all problems will be listed for all invalid questions
		expect(Materia.CreatorCore.cancelSave).toHaveBeenCalledWith("\n"+
		"Question 1 in category Cat2: Warning: this question is incomplete!\n"+
		"Question 1 in category Cat2: Question undefined.\n"+
		"Question 1 in category Cat2: Inadequate credit.\n"+
		"Question 1 in category Cat2: Duplicate answers.\n"+
		"Question 1 in category Cat2: Blank answer(s).");
	});

	it('should save when all questions are valid', function(){
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.stopCategory($scope.qset.items[0]);
		$scope.newCategory(0, $scope.qset.items[0]);
		$scope.qset.items[0].name = 'Test';
		$scope.stopCategory($scope.qset.items[0]);
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.questions[0].text = 'Test';
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.deleteAnswer(2);
		$scope.deleteAnswer(1);
		$scope.deleteAnswer(0);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.addAnswer();
		quickValue($scope.curQuestion.answers[0], '30', 30);
		quickValue($scope.curQuestion.answers[0], '100', 100);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.curQuestion.answers[0].text = 'Answer1';
		$scope.editComplete();
		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[0]);
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');
		$scope.editCategory($scope.qset.items[0]);
		$scope.qset.items[0].name = 'NewCat1';
		$scope.stopCategory($scope.qset.items[0]);
		quickQuestion(0, 0, 'Question1');
		quickQuestion(0, 1, 'Question2');
		quickQuestion(0, 2, 'Question3');
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[0], 0);
		$scope.questionReorder(true);
		$scope.questionReorder(true);
		$scope.editComplete();
		$scope.editQuestion($scope.qset.items[0], $scope.qset.items[0].items[1], 1);
		$scope.questionReorder(false);
		$scope.deleteQuestion();
		$scope.markQuestion($scope.qset.items[0], $scope.qset.items[0].items[0]);
		$scope.onQuestionImportComplete(qset.data.items[0].items);
		$scope.onQuestionImportComplete([qset.data.items[1].items[0], qset.data.items[1].items[1]]);
		$scope.importDropped($scope.qset.items[0], $scope.imported[0]);
		$scope.imported.splice(0, 1);
		quickQuestion(0, 3, 'Question1');
		quickQuestion(0, 4, 'Question1');
		quickQuestion(0, 5, 'Question1');
		$scope.importDropped($scope.qset.items[0], $scope.imported[0]);
		$scope.imported = [];
		$scope.editQuestion($scope.qset.items[1], $scope.qset.items[1].items[0], 0);
		$scope.editComplete();
		$scope.onSaveClicked('save');
		// end setup

		//let's just delete the only invalid question
		$scope.editQuestion($scope.qset.items[1], $scope.qset.items[1].items[0], 0);
		$scope.deleteQuestion();

		$scope.onSaveClicked();
		expect(Materia.CreatorCore.save).toHaveBeenCalled();
	});

	it('should not save if there are no categories', function(){
		$scope.initNewWidget(widgetInfo);

		//not that this should ever happen, but...
		$scope.qset.items = []

		$scope.onSaveClicked();
		expect(Materia.CreatorCore.cancelSave).toHaveBeenCalledWith('No categories found.');
	});

	it('should edit an existing widget', function(){
		//clone the qset and pass that clone into the controller
		//this will prevent the qset from being mangled for upcoming player tests
		$scope.initExistingWidget(widgetInfo.name, widgetInfo, qset);

		expect($scope.title).toBe('TV Show Trivia');
		expect($scope.numQuestions()).toBe(9);

		//since this qset has categories and questions in it, skip the tutorial
		expect($scope.step).toBe(4);

		//only three categories, make sure they're in the right order
		expect($scope.qset.items[0].name).toBe('Animated TV');
		expect($scope.qset.items[1].name).toBe('Sitcoms');
		expect($scope.qset.items[2].name).toBe('Game Shows');

		//spot check a few questions
		//second question in the first category
		expect($scope.qset.items[0].items[1].questions[0].text).toBe('Futurama takes place in the year?');
		expect($scope.qset.items[0].items[1].answers[0].value).toBe(0);
		expect($scope.qset.items[0].items[1].answers[2].value).toBe(100);
		expect($scope.qset.items[0].items[1].answers[2].options.correct).toBe(true);

		//first question in the second category
		expect($scope.qset.items[1].items[0].questions[0].text).toBe('The characters Ross, Monica, and Chandler come from what TV show?');
		expect($scope.qset.items[1].items[0].answers[1].value).toBe(0);
		expect($scope.qset.items[1].items[0].answers[3].value).toBe(100);
		expect($scope.qset.items[1].items[0].answers[3].options.correct).toBe(true);

		//third question in the third category
		//yeah, the demo has a newline at the end of this question
		expect($scope.qset.items[2].items[2].questions[0].text).toBe("Wheel of Fortune began airing in what year?\n");
		expect($scope.qset.items[2].items[2].answers[0].value).toBe(100);
		expect($scope.qset.items[2].items[2].answers[0].options.correct).toBe(true);
		expect($scope.qset.items[2].items[2].answers[1].value).toBe(0);
	});

	it('should react properly to a qset with no categories', function(){
		//first - react properly to qsets with no categories
		var existing = {};
		angular.copy(qset, existing);
		existing.data.items = [];

		$scope.initExistingWidget(widgetInfo.name, widgetInfo, existing);

		//it should keep the title from the incoming qset
		expect($scope.title).toBe('TV Show Trivia');

		//then start the tutorial, since there's basically nothing else there
		expect($scope.step).toBe(0);
		expect($scope.numQuestions()).toBe(0);
	});

	//not that this should even be possible, but...
	it('should make sure scaffolded categories have no questions', function() {
		$scope.initNewWidget(widgetInfo);
		$scope.hideCover()
		quickCategory(0, 'Cat1');
		quickCategory(1, 'Cat2');
		quickCategory(2, 'Cat3');
		quickCategory(3, 'Cat4');
		quickCategory(4, 'Cat5');

		//unnamed categories ahead of named categories should be removed
		$scope.qset.items[0].name = ''

		jest.spyOn(window, 'confirm')
		window.confirm.mockReturnValueOnce(true)
		$scope.deleteCategory($scope.qset.items[4]);

		expect($scope.qset.items[0].name).toBe('Cat2');

		//...unless they have questions in them
		$scope.qset.items[1].name = ''
		$scope.qset.items[1].items[0].questions[0].text = 'text'

		$scope.deleteCategory($scope.qset.items[3]);

		expect($scope.qset.items[1].name).toBe('');
	});

	//by default an Enigma widget will have 5 empty categories
	//if an existing widget has fewer, it will add empties to get to 5
	//if it has 5 or more, it should add an empty to the end
	it('should react properly to a qset with more than 5 categories', function(){
		var existing = {};
		angular.copy(qset, existing);

		var len = 8;
		for(var i = existing.data.items.length; i < len; i++)
		{
			existing.data.items.push({
				name: '',
				items: [],
				untouched: true,
				index: i
			});
			// pretend we've gone through and made a bunch of empty categories before
			existing.data.items[i].name = 'cat'+i;
			existing.data.items[i].items = [];
			existing.data.items[i].untouched = false;
		}

		$scope.initExistingWidget(widgetInfo.name, widgetInfo, existing);
		expect($scope.qset.items.length).toBe(len+1);
		expect($scope.qset.items[len].items.length).toBe(6);
	});

	//this shouldn't be possible currently, but old qsets may exist in this state
	//if a category is unnamed, the creator checks to see if it has questions
	//if so, it is allowed
	//...actually - not any more; empty categories are allowed now and dealt with differently
	it('should react properly if a category has questions but no name', function(){
		var existing = {};
		angular.copy(qset, existing);

		//unset the name of the first category
		existing.data.items[0].name = '';

		$scope.initExistingWidget(widgetInfo.name, widgetInfo, existing);

		//expected behavior is for all category names to be non-empty
		//empty names will automatically be changed to a single space
		expect($scope.qset.items[0].name).toBe(' ');
		expect($scope.numQuestions()).toBe(9);
	});

	//Enigma qsets should be generated such that the 'data' property contains the categories
	//if for some reason the qset structure is different, accept it anyway
	it('should handle weird qset formats', function(){
		var existing = {};
		angular.copy(qset, existing);

		existing = existing.data;

		$scope.initExistingWidget(widgetInfo.name, widgetInfo, existing);

		expect($scope.qset.items[0].name).toBe('Animated TV');
		expect($scope.qset.items[1].name).toBe('Sitcoms');
		expect($scope.qset.items[2].name).toBe('Game Shows');

		expect($scope.numQuestions()).toBe(9);
	});

	it('should make sure all categories are indexed properly', function(){
		$scope.initExistingWidget(widgetInfo.name, widgetInfo, qset);
		expect($scope.qset.items[0].index).toBe(0);
		expect($scope.qset.items[1].index).toBe(1);
		expect($scope.qset.items[2].index).toBe(2);
	});
});
