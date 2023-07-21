describe('Player Controller', function() {
	require('angular/angular.js');
	require('angular-mocks/angular-mocks.js');
	require('angular-aria/angular-aria.js');

	var $scope;
	var $controller;
	var $timeout;
	var widgetInfo;
	var qset;

	const originalDocument = document;

	beforeAll(() => {
		jest.useFakeTimers();
	});

	beforeEach(() => {
		jest.resetModules();
		jest.clearAllTimers();

		// placeholders to keep things running properly
		document.getElementById = jest.fn().mockReturnValue({
			focus: jest.fn()
		});
		document.getElementsByClassName = jest.fn().mockReturnValue([
			{
				focus: jest.fn(),
				title: ''
			}
		]);

		// mock materia
		global.Materia = {
			Engine: {
				start: jest.fn(),
				end: jest.fn(),
				getMediaUrl: jest.fn(asset => {
					const cleaned = asset.replace(/<%MEDIA='(.+?)'%>/g, '$1')
					return 'MEDIA_URL/' + cleaned
				}),
				setHeight: jest.fn()
			},
			Score: {
				submitQuestionForScoring: jest.fn()
			}
		};

		// load qset
		widgetInfo = require('../demo.json');
		qset = widgetInfo.qset;

		// load the required code
		angular.mock.module('enigmaPlayer');
		require('../modules/player.coffee');
		require('./player.coffee');

		// mock scope
		$scope = {
			$apply: jest.fn()
		};

		document.body.innerHTML = "<div><div id='checkAns'></div></div>";

		// initialize the angualr controller
		inject(function(_$controller_, _$timeout_){
			$timeout = _$timeout_;
			// instantiate the controller
			$controller = _$controller_('enigmaPlayerCtrl', { $scope: $scope });
		});

	});

	afterAll(() => {
		document = originalDocument
	});


	function quickAnswer({cat, item, answer} = {}) {
		$scope.selectQuestion($scope.categories[cat], $scope.categories[cat].items[item]);
		$scope.selectAnswer($scope.currentQuestion.answers[answer]);
		$scope.submitAnswer();
		$scope.cancelQuestion();
	};

	it('should start properly', function(){
		$scope.start(widgetInfo, qset.data);
		expect($scope.title).toBe('TV Show Trivia');
		//the demo widget should have three categories
		expect($scope.categories.length).toBe(3);
		expect($scope.totalQuestions).toBe(9);
		expect($scope.percentCorrect).toBe(0);
		expect($scope.percentIncorrect).toBe(0);
	});

	test('controller contains the expected images after starting', () => {
		$scope.start(widgetInfo, qset.data)
		const expectedImages = [
			'jerry_and_george.jpg',
			'bob_barker.jpg',
			'wheel_of_fortune.jpg',
		]
		const questionArray = [];
		$scope.categories.forEach(category => category.items.forEach(question => {
			if (question.options.asset)
				questionArray.push(question.options.asset.value)
		}));
		for (const index in expectedImages) {
			const fullName = 'MEDIA_URL/assets/img/demo/' + expectedImages[index]
			expect(questionArray).toContain(fullName)
		}
	})

	it('should choose a question to answer', function(){
		const mockFocus = jest.fn();
		document.getElementById = jest.fn().mockReturnValueOnce({
			focus: mockFocus
		});

		$scope.start(widgetInfo, qset.data);
		//'currentCategory' and 'currentQuestion' should be null by default
		expect($scope.currentCategory).toBe(null);
		expect($scope.currentQuestion).toBe(null);

		//selecting a question is normally accomplished by clicking it
		//each clickable square on the board knows which question it is and which category it belongs to
		//we'll have to keep track of those on our own for the purpose of testing
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);

		//make sure the category and question we specify was set as the current items
		expect($scope.currentCategory).toEqual($scope.categories[0]);
		expect($scope.currentQuestion).toEqual($scope.categories[0].items[0]);

		jest.advanceTimersByTime(100);
		expect(document.getElementById).toHaveBeenCalledWith('show-question-keyboard-instructions-button');
		expect(mockFocus).toHaveBeenCalled();
	});

	it('should not allow a question to be selected while a question is already selected', function(){
		$scope.start(widgetInfo, qset.data);
		expect(function(){
			$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);
		}).not.toThrow()

		expect(function(){
			$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);
		}).toThrow(new Error('A question is already selected!'));
	});

	it('should cancel answering a question', function(){
		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);
		expect($scope.currentCategory).toEqual($scope.categories[0]);
		expect($scope.currentQuestion).toEqual($scope.categories[0].items[0]);

		$scope.cancelQuestion();

		expect($scope.currentCategory).toBe(null);
		expect($scope.currentQuestion).toBe(null);
		expect($scope.currentAnswer).toBe(null);
	});

	it('should not allow an answer to be selected unless a question is selected', function(){
		$scope.start(widgetInfo, qset.data);
		expect($scope.currentAnswer).toBe(null);

		expect(function(){
			//selecting an answer is normally accomplished by clicking it
			$scope.selectAnswer($scope.categories[0].items[0].answers[0]);
		}).toThrow(new Error('Select a question first!'));
	});

	it('should select an answer', function(){
		$scope.start(widgetInfo, qset.data);
		//select the first question again to start
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);
		$scope.selectAnswer($scope.categories[0].items[0].answers[1]);

		expect($scope.currentAnswer.text).toBe('Arlen');
	});

	it('should score the first question correctly', function(){
		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);
		$scope.selectAnswer($scope.categories[0].items[0].answers[1]);

		expect($scope.percentCorrect).toBe(0);
		expect($scope.percentIncorrect).toBe(0);
		expect($scope.scores).toEqual([]);
		expect($scope.currentQuestion.answered).toBeUndefined();

		//this answer's value should be 30
		$scope.submitAnswer();
		expect(Materia.Score.submitQuestionForScoring).toHaveBeenCalledWith($scope.categories[0].items[0].id, 'Arlen');

		//make sure the question is now 'answered' and the selected answer's score was recorded
		expect($scope.currentQuestion.answered).toBe(true);
		expect($scope.scores).toEqual([30]);
		expect($scope.answeredQuestions).toContain($scope.categories[0].items[0]);
		//final score isn't updated until after exiting an answered question
		expect($scope.percentCorrect).toBe(0);
		expect($scope.percentIncorrect).toBe(0);
	});

	//trying to select an answer in an answered question should change nothing
	it('should not allow an answer to be selected if the current question has already been answered', function(){
		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);
		$scope.selectAnswer($scope.categories[0].items[0].answers[1]);
		$scope.submitAnswer();

		expect($scope.currentAnswer.text).toBe('Arlen');
		//this is the correct answer; 'Springfield' with a value of 100
		$scope.selectAnswer($scope.categories[0].items[0].answers[2]);
		expect($scope.currentAnswer.text).toBe('Arlen');
	});

	//this should simply change nothing
	it('should not allow a question to be answered if it has already been answered', function(){
		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);
		$scope.selectAnswer($scope.categories[0].items[0].answers[1]);
		$scope.submitAnswer();

		expect(function(){
			//selecting an answer is normally accomplished by clicking it
			$scope.submitAnswer();
		}).toThrow(new Error('Question already answered!'));
	});

	it('should update the final score after exiting an answered question', function(){
		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);
		$scope.selectAnswer($scope.categories[0].items[0].answers[1]);
		$scope.submitAnswer();
		$scope.cancelQuestion();
		//fractions will be common, so check approximate values
		expect($scope.percentIncorrect).toBeCloseTo(8.1, 1);
		expect($scope.percentCorrect).toBeCloseTo(3);

		//everything should be reset
		expect($scope.currentCategory).toBe(null);
		expect($scope.currentQuestion).toBe(null);
		expect($scope.currentAnswer).toBe(null);

		//we use a timer to animate an effect on the page, but it only changes one value
		expect($scope.changingNumber).toBe(true);
		$timeout.flush();
		expect($scope.changingNumber).toBe(false);
	});

	it('should not allow a question to be selected if it has been answered already', function(){
		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);
		$scope.selectAnswer($scope.categories[0].items[0].answers[1]);
		$scope.submitAnswer();
		$scope.cancelQuestion();

		expect($scope.currentQuestion).toBe(null);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);
		expect($scope.currentQuestion).toBe(null);
	});

	it('should not allow an answer to be submitted for the wrong question', function(){
		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);
		$scope.selectAnswer($scope.categories[0].items[0].answers[1]);
		$scope.submitAnswer();
		$scope.cancelQuestion();

		//select the second question in the first category
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[1]);

		//this shouldn't be possible - but select an answer from the previous question
		//this is technically allowed because it doesn't change anything
		$scope.selectAnswer($scope.categories[0].items[0].answers[2]);

		//submitting an answer that doesn't belong to the current question shouldn't be possible
		expect(function(){
			$scope.submitAnswer();
		}).toThrow(new Error('Submitted answer not in this question!'));
	});

	it('should score the second question correctly', function(){
		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);
		$scope.selectAnswer($scope.categories[0].items[0].answers[1]);
		$scope.submitAnswer();
		$scope.cancelQuestion();
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[1]);
		$scope.selectAnswer($scope.categories[0].items[0].answers[2]);

		//this should be the correct answer
		$scope.selectAnswer($scope.currentQuestion.answers[2]);
		expect($scope.currentAnswer.text).toBe('3,000 AD');
		$scope.submitAnswer();
		expect(Materia.Score.submitQuestionForScoring).toHaveBeenCalledWith($scope.categories[0].items[1].id, '3,000 AD');

		//make sure this question is now scored and tracked correctly
		expect($scope.currentQuestion.answered).toBe(true);
		expect($scope.scores).toEqual([30, 100]);
		expect($scope.answeredQuestions).toContain($scope.categories[0].items[1]);

		$scope.cancelQuestion();

		expect($scope.percentIncorrect).toBeCloseTo(8.2, 1);
		expect($scope.percentCorrect).toBeCloseTo(14);
	});

	//so far so good
	//do the other 7 questions a bit faster
	it('should continue scoring questions correctly', function(){
		$scope.start(widgetInfo, qset.data);
		quickAnswer({cat: 0, item: 0, answer: 1});
		quickAnswer({cat: 0, item: 1, answer: 2});

		quickAnswer({cat: 0, item: 2, answer: 0}); //100% answer
		expect($scope.percentCorrect).toBeCloseTo(26);
		expect($scope.percentIncorrect).toBeCloseTo(7.3, 1);

		quickAnswer({cat: 1, item: 0, answer: 3}); //100% answer
		expect($scope.percentCorrect).toBeCloseTo(37);
		expect($scope.percentIncorrect).toBeCloseTo(7.4, 1);

		quickAnswer({cat: 1, item: 1, answer: 2}); //0% answer
		expect($scope.percentCorrect).toBeCloseTo(37);
		expect($scope.percentIncorrect).toBeCloseTo(18.6, 1);

		quickAnswer({cat: 1, item: 2, answer: 2}); //0% answer
		expect($scope.percentCorrect).toBeCloseTo(37);
		expect($scope.percentIncorrect).toBeCloseTo(29.7, 1);

		quickAnswer({cat: 2, item: 0, answer: 2}); //100% answer
		expect($scope.percentCorrect).toBeCloseTo(48);
		expect($scope.percentIncorrect).toBeCloseTo(29.8, 1);

		quickAnswer({cat: 2, item: 1, answer: 0}); //100% answer
		expect($scope.percentCorrect).toBeCloseTo(59);
		expect($scope.percentIncorrect).toBeCloseTo(29.9, 1);
	});

	it('should soft-end the game after the last question is answered', function(){
		const mockFocus = jest.fn();
		// little bit overcomplicated - document.getElementbyId will be called
		// many times over the course of this test, we only really care to make
		// sure a single specific thing it's called for is then given focus
		document.getElementById = jest.fn(function(arg){
			if (arg === 'end-button') {
				return { focus: mockFocus }
			} else {
				return { focus: jest.fn() }
			}
		});

		$scope.start(widgetInfo, qset.data);
		quickAnswer({cat: 0, item: 0, answer: 1});
		quickAnswer({cat: 0, item: 1, answer: 2});
		quickAnswer({cat: 0, item: 2, answer: 0}); //100% answer
		quickAnswer({cat: 1, item: 0, answer: 3}); //100% answer
		quickAnswer({cat: 1, item: 1, answer: 2}); //0% answer
		quickAnswer({cat: 1, item: 2, answer: 2}); //0% answer
		quickAnswer({cat: 2, item: 0, answer: 2}); //100% answer
		quickAnswer({cat: 2, item: 1, answer: 0}); //100% answer

		quickAnswer({cat: 2, item: 2, answer: 0}); //100% answer
		expect($scope.percentCorrect).toBeCloseTo(70);
		expect($scope.percentIncorrect).toBeCloseTo(30);

		//the widget is 'ended', but there is a widget-specific score screen prior to the general score screen
		expect(Materia.Engine.end).toHaveBeenCalledWith(false);
		expect($scope.allAnswered).toBe(true);

		jest.advanceTimersByTime(100);
		expect(document.getElementById).toHaveBeenCalledWith('end-button');
		expect(mockFocus).toHaveBeenCalled();
	});

	it('should end the game properly', function(){
		//this is accomplished by clicking the 'submit for review' button
		$scope.end();
		expect(Materia.Engine.end).toHaveBeenCalledWith(true);
	});

	//everything else works - let's just make sure answer order is randomized when the option is toggled
	it('should shuffle answer order when the randomize option is on', function(){
		//this will make the output of Math.random() predictable, for the purpose of shuffling answers
		jest.spyOn(Math, 'random')
		Math.random.mockReturnValue(0)

		//change the first category's third question to only have one answer
		//this will make sure the shuffle function reacts properly to single-answer questions
		qset.data.items[0].items[2].answers.splice(0,1);

		//go through each answer and assign sequential ids
		var n = 0;
		for(var i in qset.data.items[0].items[0].answers)
		{
			qset.data.items[0].items[0].answers[i].id = ++n;
		}

		//get a list of the answer ids for the supplied question - used to see which order the answers are in
		function listOfIds(q) {
			var list = [];
			for(var i in q.answers) {
				list.push(q.answers[i].id.toString());
			}
			return list;
		}

		//check the first category's first question
		var list1 = listOfIds(qset.data.items[0].items[0]);
		qset.data.options.randomize = true;
		$scope.start(widgetInfo, qset.data);
		var list2 = listOfIds($scope.categories[0].items[0]);
		expect(list1).not.toEqual(list2);
	});

	it('should toggle keyboard instructions properly', function(){
		const hideFocus = jest.fn();
		const showFocus = jest.fn();
		// kind of magical, but
		// we're going from hidden to visible so the first focus target should be the 'hide' button
		// and then from visible to hidden the next focus target should be the 'show' button again
		document.getElementById = jest.fn().mockReturnValueOnce({
			focus: hideFocus
		}).mockReturnValueOnce({
			focus: showFocus
		});
		$scope.start(widgetInfo, qset.data);

		expect($scope.instructionsOpen).toBe(false);

		$scope.toggleInstructions();
		jest.advanceTimersByTime(100);
		expect($scope.instructionsOpen).toBe(true);
		expect(document.getElementById).toHaveBeenCalledTimes(1);
		expect(document.getElementById).toHaveBeenLastCalledWith('hide-keyboard-instructions-button');

		$scope.toggleInstructions();
		jest.advanceTimersByTime(100);
		expect($scope.instructionsOpen).toBe(false);
		expect(document.getElementById).toHaveBeenCalledTimes(2);
		expect(document.getElementById).toHaveBeenLastCalledWith('show-keyboard-instructions-button');
	})

	it('should focus on the correct element when wrapping around', function(){
		const firstFocus = jest.fn()
		const secondFocus = jest.fn()
		document.getElementsByClassName = jest.fn().mockReturnValue([
			{focus: firstFocus },
			{focus: secondFocus }
		]);

		$scope.start(widgetInfo, qset.data);
		$scope.wraparound();

		expect(firstFocus).toHaveBeenCalledTimes(1);
		expect(secondFocus).not.toHaveBeenCalled();
	});

	it('should update the aria live value when handleWholePlayerKeyup handles a press of the S key', function() {
		$scope.start(widgetInfo, qset.data);
		expect($scope.ariaLive).toBe('');

		const spoofKeyUpEvent = { code: 'KeyS' };
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent);

		// we happen to know what this will look like given the demo qset, but it's a bit magical
		expect($scope.ariaLive).toBe('9 questions remaining, current score is 0 out of 100 points.');

		// this isn't what actually happens but it doesn't really matter here
		$scope.answeredQuestions.push(1);
		$scope.answeredQuestions.push(2);
		$scope.answeredQuestions.push(3);

		$scope.percentCorrect = 28;

		$scope.handleWholePlayerKeyup(spoofKeyUpEvent);
		expect($scope.ariaLive).toBe('6 questions remaining, current score is 28 out of 100 points.');

		$scope.allAnswered = true;
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent);
		expect($scope.ariaLive).toBe('All questions have been answered');
	});

	it('should select the earliest unanswered question when handleWholePlayerKeyup handles a press of the Q key', function() {
		jest.spyOn($scope, 'selectQuestion')

		$scope.start(widgetInfo, qset.data);

		const spoofKeyUpEvent = { code: 'KeyQ' };

		// test the do-nothing cases first
		// some of these are already at their default values, we'll set them explicitly here for consistency
		$scope.instructionsOpen = true;
		$scope.allAnswered = false;
		$scope.currentQuestion = null;
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent);
		expect($scope.selectQuestion).not.toHaveBeenCalled();

		$scope.instructionsOpen = false;
		$scope.allAnswered = true;
		$scope.currentQuestion = null;
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent);
		expect($scope.selectQuestion).not.toHaveBeenCalled();

		$scope.instructionsOpen = false;
		$scope.allAnswered = false;
		$scope.currentQuestion = $scope.categories[0].items[0];
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent);
		expect($scope.selectQuestion).not.toHaveBeenCalled();

		// now make sure the first question is selected automatically
		$scope.instructionsOpen = false;
		$scope.allAnswered = false;
		$scope.currentQuestion = null;
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent);
		expect($scope.selectQuestion).toHaveBeenCalledTimes(1);
		expect($scope.selectQuestion).toHaveBeenCalledWith($scope.categories[0], $scope.categories[0].items[0]);

		$scope.selectQuestion.mockReset();

		// now set the first two questions' scores to make sure it selects the third question automatically
		$scope.instructionsOpen = false;
		$scope.allAnswered = false;
		$scope.currentQuestion = null;
		$scope.categories[0].items[0].score = '100';
		$scope.categories[0].items[1].score = '100';
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent);
		expect($scope.selectQuestion).toHaveBeenCalledTimes(1);
		expect($scope.selectQuestion).toHaveBeenCalledWith($scope.categories[0], $scope.categories[0].items[2]);
	});

	it('should change $scope.ariaLive when handleWholePlayerKeyUp handles a press of the H key', function() {
		$scope.start(widgetInfo, qset.data);
		expect($scope.ariaLive).toBe('');

		const spoofKeyUpEvent = { code: 'KeyH' };
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent);

		const expectedString = "Keyboard instructions: Questions are sorted into categories. " +
			"Use the Tab key to navigate through the game board to view and select questions. " +
			"Answer all questions to complete the widget. " +
			"Press the 'Q' key to automatically select the earliest unanswered question. " +
			"Press the 'S' key to hear your current score and how many unanswered questions are remaining. " +
			"Press the 'W' key to hear which question and category you currently have highlighted. " +
			"Press the 'H' key to hear these instructions again.";

		expect($scope.ariaLive).toBe(expectedString);
	});

	it('should indicate that a question has not been highlighted when handleWholePlayerKeyUp handles a press of the W key', function() {
		$scope.start(widgetInfo, qset.data);
		expect($scope.ariaLive).toBe('');

		const spoofKeyUpEvent = { code: 'KeyW' };
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent);

		expect($scope.ariaLive).toBe('You have not highlighted a question yet, please use the Tab key to progress to the game board.');
	});

	it('should correctly indicate the currently highlighted question when handleWholePlayerKeyUp handles a press of the W key', function() {
		$scope.start(widgetInfo, qset.data);
		expect($scope.ariaLive).toBe('');

		const targetCategory = 0;
		const targetQuestion = 1;
		// this is ordinarily only called by the angular running in the HTML
		// this should highlight the second question in the first category
		$scope.highlightQuestion($scope.categories[targetCategory], $scope.categories[targetCategory].items[targetQuestion]);

		const spoofKeyUpEvent = { code: 'KeyW' };
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent);

		const expectedString = 'Current location is question ' + (targetQuestion + 1) + ' of ' +
			$scope.categories[targetCategory].items.length +
			' in category ' + (targetCategory + 1) + ' of ' + $scope.categories.length +
			': ' + $scope.categories[targetCategory].name + '. ' +
			'Press Space or Enter to select this question.';
		expect($scope.ariaLive).toBe(expectedString);
	});

	it('should leave a question when handleQuestionKeyUp handles a press of the Escape key', function(){
		jest.spyOn($scope, 'cancelQuestion');
		$scope.start(widgetInfo, qset.data);

		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);

		const spoofKeyUpEvent = {
			code: 'Escape',
			stopPropagation: jest.fn()
		};
		$scope.handleQuestionKeyUp(spoofKeyUpEvent);

		expect($scope.cancelQuestion).toHaveBeenCalledTimes(1);
	});

	it('should change $scope.ariaLive when handleQuestionKeyUp handles a press of the Q key', function(){
		$scope.start(widgetInfo, qset.data);
		expect($scope.ariaLive).toBe('');

		$scope.currentQuestion = $scope.categories[0].items[2];

		const spoofKeyUpEvent = {
			code: 'KeyQ',
			stopPropagation: jest.fn()
		};
		$scope.handleQuestionKeyUp(spoofKeyUpEvent);

		expect($scope.ariaLive).toBe('Question: ' + $scope.categories[0].items[2].questions[0].text);
	});

	it('should indicate that an answer is not selected when handleQuestionKeyUp handles a press of the S key', function(){
		$scope.start(widgetInfo, qset.data);
		expect($scope.ariaLive).toBe('');

		$scope.currentQuestion = $scope.categories[0].items[2];

		const spoofKeyUpEvent = {
			code: 'KeyS',
			stopPropagation: jest.fn()
		};
		$scope.handleQuestionKeyUp(spoofKeyUpEvent);

		expect(document.getElementById).not.toHaveBeenCalledWith('submit');
		expect($scope.ariaLive).toBe('You must select an answer first.');
	});

	it('should focus on the Submit Final Answer button when handleQuestionKeyUp handles a press of the S key', function(){
		const mockFocus = jest.fn()
		document.getElementById = jest.fn().mockReturnValue({
			focus: mockFocus
		});

		$scope.start(widgetInfo, qset.data);
		expect($scope.ariaLive).toBe('');

		$scope.currentQuestion = $scope.categories[0].items[2];

		$scope.selectAnswer($scope.categories[0].items[2].answers[1]);

		const spoofKeyUpEvent = {
			code: 'KeyS',
			stopPropagation: jest.fn()
		};
		$scope.handleQuestionKeyUp(spoofKeyUpEvent);

		expect(mockFocus).toHaveBeenCalled();
	});

	it('should change $scope.ariaLive when handleQuestionKeyUp handles a press of the H key, no media', function(){
		$scope.start(widgetInfo, qset.data);
		expect($scope.ariaLive).toBe('');

		$scope.currentQuestion = $scope.categories[0].items[1];

		const spoofKeyUpEvent = {
			code: 'KeyH',
			stopPropagation: jest.fn()
		};
		$scope.handleQuestionKeyUp(spoofKeyUpEvent);

		const expectedString = 'Use the Tab key to navigate through answer options, then to reach the Return and Submit Final Answer buttons. ' +
			'The Up and Down arrow keys may also be used to navigate through answer options. ' +
			'Press the Enter or Space key on an answer option to select it. ' +
			'Pressing the Escape key will leave this question and allow you to select another question. ' +
			'Press the Q key to hear the question again. ' +
			'Press the S key after selecting an answer to be taken to the Submit Final Answer button automatically. ' +
			'Press the H key to hear these instructions again.';

		expect($scope.ariaLive).toBe(expectedString);
	});

	it('should change $scope.ariaLive when handleQuestionKeyUp handles a press of the H key, with media', function(){
		$scope.start(widgetInfo, qset.data);
		expect($scope.ariaLive).toBe('');

		// we happen to know this question has media, but it's a bit magical
		$scope.currentQuestion = $scope.categories[2].items[0];

		const spoofKeyUpEvent = {
			code: 'KeyH',
			stopPropagation: jest.fn()
		};
		$scope.handleQuestionKeyUp(spoofKeyUpEvent);

		const expectedString = 'Use the Tab key to navigate to the associated media, then through answer options, then to reach the Return and Submit Final Answer buttons. ' +
			'The Up and Down arrow keys may also be used to navigate through answer options. ' +
			'Press the Enter or Space key on an answer option to select it. ' +
			'Pressing the Escape key will leave this question and allow you to select another question. ' +
			'Press the Q key to hear the question again. ' +
			'Press the S key after selecting an answer to be taken to the Submit Final Answer button automatically. ' +
			'Press the H key to hear these instructions again.';

		expect($scope.ariaLive).toBe(expectedString);
	});

	it('should focus on the correct answer element when handleQuestionKeyUp handles a press of the up arrow key', function(){
		const mockShouldFocus = jest.fn()
		const mockShouldNotFocus = jest.fn()
		document.getElementById = jest.fn().mockReturnValue({
			// we happen to know the question we select will have this many answers
			// maybe make it less magical later
			getElementsByClassName: function() {
				return [
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldFocus }
				]
			}
		});

		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);

		const spoofKeyUpEvent = {
			code: 'ArrowUp',
			stopPropagation: jest.fn()
		};
		$scope.handleQuestionKeyUp(spoofKeyUpEvent);

		// the up arrow key should select the last answer, which is the only one that should call focus
		// the rest of the answer options should not have been focused
		expect(mockShouldFocus).toHaveBeenCalledTimes(1)
		expect(mockShouldNotFocus).not.toHaveBeenCalled()
	})

	it('should focus on the correct answer element when handleQuestionKeyUp handles a press of the down arrow key', function(){
		const mockShouldFocus = jest.fn()
		const mockShouldNotFocus = jest.fn()
		document.getElementById = jest.fn().mockReturnValue({
			// we happen to know the question we select will have this many answers
			// maybe make it less magical later
			getElementsByClassName: function() {
				return [
					{ focus: mockShouldFocus },
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldNotFocus }
				]
			}
		});

		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);

		const spoofKeyUpEvent = {
			code: 'ArrowDown',
			stopPropagation: jest.fn()
		};
		$scope.handleQuestionKeyUp(spoofKeyUpEvent);

		// the down arrow key should select the first answer, which is the only one that should call focus
		// the rest of the answer options should not have been focused
		expect(mockShouldFocus).toHaveBeenCalledTimes(1);
		expect(mockShouldNotFocus).not.toHaveBeenCalled();
	});

	it('should toggle question keyboard instructions properly', function(){
		const hideFocus = jest.fn();
		const showFocus = jest.fn();
		// kind of magical, but
		// we're going from hidden to visible so the first focus target should be the 'hide' button
		// and then from visible to hidden the next focus target should be the 'show' button again
		document.getElementById = jest.fn().mockReturnValueOnce({
			focus: hideFocus
		}).mockReturnValueOnce({
			focus: showFocus
		});
		$scope.start(widgetInfo, qset.data);

		expect($scope.questionInstructionsOpen).toBe(false);

		$scope.toggleQuestionInstructions();
		jest.advanceTimersByTime(100);
		expect($scope.questionInstructionsOpen).toBe(true);
		expect(document.getElementById).toHaveBeenCalledTimes(1);
		expect(document.getElementById).toHaveBeenLastCalledWith('hide-question-keyboard-instructions-button');

		$scope.toggleQuestionInstructions();
		jest.advanceTimersByTime(100);
		expect($scope.questionInstructionsOpen).toBe(false);
		expect(document.getElementById).toHaveBeenCalledTimes(2);
		expect(document.getElementById).toHaveBeenLastCalledWith('show-question-keyboard-instructions-button');
	});

	it('should select a given answer when handleAnswerKeyUp handles a press of the Enter key', function() {
		jest.spyOn($scope, 'selectAnswer')
		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);

		const mockStopPropagation = jest.fn()

		const spoofKeyUpEvent = {
			code: 'Enter',
			stopPropagation: mockStopPropagation
		};
		$scope.handleAnswerKeyUp(spoofKeyUpEvent, 0, $scope.categories[0].items[0].answers[0]);
		expect($scope.selectAnswer).toHaveBeenCalledWith($scope.categories[0].items[0].answers[0]);
		expect(mockStopPropagation).toHaveBeenCalled();
	});
	it('should select a given answer when handleAnswerKeyUp handles a press of the Space key', function() {
		jest.spyOn($scope, 'selectAnswer')
		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);

		const mockStopPropagation = jest.fn()
		const spoofKeyUpEvent = {
			code: 'Space',
			stopPropagation: mockStopPropagation
		};
		$scope.handleAnswerKeyUp(spoofKeyUpEvent, 0, $scope.categories[0].items[0].answers[0]);
		expect($scope.selectAnswer).toHaveBeenCalledWith($scope.categories[0].items[0].answers[0]);
		expect(mockStopPropagation).toHaveBeenCalled();
	});

	it('should select the final answer when handleAnswerKeyUp handles a press of the up arrow key on the first answer', function() {
		const mockShouldFocus = jest.fn()
		const mockShouldNotFocus = jest.fn()
		document.getElementById = jest.fn().mockReturnValue({
			getElementsByClassName: function() {
				return [
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldFocus }
				]
			}
		});

		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);

		const mockStopPropagation = jest.fn()
		const spoofKeyUpEvent = {
			code: 'ArrowUp',
			stopPropagation: mockStopPropagation
		};
		$scope.handleAnswerKeyUp(spoofKeyUpEvent, 0, $scope.categories[0].items[0].answers[0]);

		// pressing up at index 0 should wrap around to the final index
		expect(mockShouldFocus).toHaveBeenCalledTimes(1);
		expect(mockShouldNotFocus).not.toHaveBeenCalled();
		expect(mockStopPropagation).toHaveBeenCalled();
	});
	it('should select the next answer when handleAnswerKeyUp handles a press of the down arrow key', function() {
		const mockShouldFocus = jest.fn()
		const mockShouldNotFocus = jest.fn()
		document.getElementById = jest.fn().mockReturnValue({
			getElementsByClassName: function() {
				return [
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldFocus },
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldNotFocus }
				]
			}
		});

		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);

		const mockStopPropagation = jest.fn()
		const spoofKeyUpEvent = {
			code: 'ArrowDown',
			stopPropagation: mockStopPropagation
		};
		$scope.handleAnswerKeyUp(spoofKeyUpEvent, 0, $scope.categories[0].items[0].answers[0]);

		// pressing down at index 0 should move focus to the second answer
		expect(mockShouldFocus).toHaveBeenCalledTimes(1);
		expect(mockShouldNotFocus).not.toHaveBeenCalled();
		expect(mockStopPropagation).toHaveBeenCalled();
	});
	it('should select the previous answer when handleAnswerKeyUp handles a press of the up arrow key', function() {
		const mockShouldFocus = jest.fn()
		const mockShouldNotFocus = jest.fn()
		document.getElementById = jest.fn().mockReturnValue({
			getElementsByClassName: function() {
				return [
					{ focus: mockShouldFocus },
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldNotFocus }
				]
			}
		});

		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);

		const mockStopPropagation = jest.fn()
		const spoofKeyUpEvent = {
			code: 'ArrowUp',
			stopPropagation: mockStopPropagation
		};
		$scope.handleAnswerKeyUp(spoofKeyUpEvent, 1, $scope.categories[0].items[0].answers[0])

		// pressing up at index 1 should move focus to the first answer
		expect(mockShouldFocus).toHaveBeenCalledTimes(1);
		expect(mockShouldNotFocus).not.toHaveBeenCalled();
		expect(mockStopPropagation).toHaveBeenCalled();
	});
	it('should select the first answer when handleAnswerKeyUp handles a press of the down arrow key on the final answer', function() {
		const mockShouldFocus = jest.fn()
		const mockShouldNotFocus = jest.fn()
		document.getElementById = jest.fn().mockReturnValue({
			getElementsByClassName: function() {
				return [
					{ focus: mockShouldFocus },
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldNotFocus },
					{ focus: mockShouldNotFocus }
				]
			}
		});

		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);

		const mockStopPropagation = jest.fn()
		const spoofKeyUpEvent = {
			code: 'ArrowDown',
			stopPropagation: mockStopPropagation
		};
		$scope.handleAnswerKeyUp(spoofKeyUpEvent, $scope.categories[0].items[0].answers.length - 1, $scope.categories[0].items[0].answers[0]);

		// pressing down at the final index should wrap around to the first index
		expect(mockShouldFocus).toHaveBeenCalledTimes(1);
		expect(mockShouldNotFocus).not.toHaveBeenCalled();
		expect(mockStopPropagation).toHaveBeenCalled();
	});

	it('should allow handleAnswerKeyUp to keep bubbling a press of the Q, S, H or Escape keys', function() {
		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[0], $scope.categories[0].items[0]);

		const mockStopPropagation = jest.fn()
		const spoofKeyUpEvent = {
			code: 'KeyQ',
			stopPropagation: mockStopPropagation
		};

		$scope.handleAnswerKeyUp(spoofKeyUpEvent, 0, $scope.categories[0].items[0].answers[0]);
		expect(mockStopPropagation).not.toHaveBeenCalled();

		spoofKeyUpEvent.code = 'KeyS';
		$scope.handleAnswerKeyUp(spoofKeyUpEvent, 0, $scope.categories[0].items[0].answers[0]);
		expect(mockStopPropagation).not.toHaveBeenCalled();

		spoofKeyUpEvent.code = 'KeyH';
		$scope.handleAnswerKeyUp(spoofKeyUpEvent, 0, $scope.categories[0].items[0].answers[0]);
		expect(mockStopPropagation).not.toHaveBeenCalled();

		spoofKeyUpEvent.code = 'Escape';
		$scope.handleAnswerKeyUp(spoofKeyUpEvent, 0, $scope.categories[0].items[0].answers[0]);
		expect(mockStopPropagation).not.toHaveBeenCalled();
	});

	it('should focus the correct element when running findQuestion', function(){
		const mockShouldFocus = jest.fn();
		const mockShouldNotFocus = jest.fn();
		document.getElementsByClassName = jest.fn().mockReturnValue([
			{ title: 'q1 Answered', focus: mockShouldNotFocus },
			{ title: 'q2 Answered', focus: mockShouldNotFocus },
			{ title: 'q3 Unanswered', focus: mockShouldFocus },
			{ title: 'q4 Answered', focus: mockShouldNotFocus },
		]);
		$scope.start(widgetInfo, qset.data);

		$scope.findQuestion();

		jest.advanceTimersByTime(100);
		expect(mockShouldFocus).toHaveBeenCalledTimes(1);
		expect(mockShouldNotFocus).not.toHaveBeenCalled();
	});

	it('should set the lightbox target and call subsequent functions appropriately', function(){
		const mockFocus = jest.fn();
		document.getElementsByClassName = jest.fn().mockReturnValueOnce([
			{ focus: mockFocus }
		]);

		$scope.start(widgetInfo, qset.data);
		$scope.selectQuestion($scope.categories[2], $scope.categories[2].items[0]);

		expect($scope.lightboxTarget).toBe(-1);

		$scope.setLightboxTarget(0);
		expect($scope.lightboxTarget).toBe(0);

		jest.advanceTimersByTime(100);
		expect(document.getElementsByClassName).toHaveBeenCalledWith('lightbox-image')
		expect(mockFocus).toHaveBeenCalled();
	});

	it('should set the lightbox zoom level appropriately', function(){
		$scope.start(widgetInfo, qset.data);
		expect($scope.lightboxZoom).toBe(0);

		$scope.setLightboxZoom(-1);
		expect($scope.lightboxZoom).toBe(-1);
	});
});
