describe('Player Controller', function() {
	require('angular/angular.js');
	require('angular-mocks/angular-mocks.js');
	require('angular-aria/angular-aria.js');

	var $scope
	var $controller
	var $timeout
	var widgetInfo
	var qset

	const originalDocument = document

	beforeAll(() => {
		jest.useFakeTimers();
	})

	beforeEach(() => {
		jest.resetModules()

		// placeholders to keep things running properly
		document.getElementById = jest.fn().mockReturnValue({
			focus: jest.fn()
		})
		document.getElementsByClassName = jest.fn().mockReturnValue([
			{
				focus: jest.fn(),
				title: ''
			}
		])

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
		}

		// load qset
		widgetInfo = require('../demo.json')
		qset = widgetInfo.qset;

		// load the required code
		angular.mock.module('enigmaPlayer')
		require('../modules/player.coffee')
		require('./player.coffee')

		// mock scope
		$scope = {
			$apply: jest.fn()
		}

		document.body.innerHTML = "<div><div id='checkAns'></div></div>"

		// initialize the angualr controller
		inject(function(_$controller_, _$timeout_){
			$timeout = _$timeout_;
			// instantiate the controller
			$controller = _$controller_('enigmaPlayerCtrl', { $scope: $scope });
		})

	})

	afterAll(() => {
		document = originalDocument
	})


	function quickAnswer({cat, item, answer} = {}) {
		$scope.selectQuestion($scope.categories[cat], $scope.categories[cat].items[item]);
		$scope.selectAnswer($scope.currentQuestion.answers[answer]);
		$scope.submitAnswer();
		$scope.cancelQuestion();
	}

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
		})
		$scope.start(widgetInfo, qset.data);

		expect($scope.instructionsOpen).toBe(false)

		$scope.toggleInstructions()
		jest.advanceTimersByTime(100);
		expect($scope.instructionsOpen).toBe(true)
		expect(document.getElementById).toHaveBeenCalledTimes(1)
		expect(document.getElementById).toHaveBeenLastCalledWith('hide-keyboard-instructions-button')

		$scope.toggleInstructions()
		jest.advanceTimersByTime(100);
		expect($scope.instructionsOpen).toBe(false)
		expect(document.getElementById).toHaveBeenCalledTimes(2)
		expect(document.getElementById).toHaveBeenLastCalledWith('show-keyboard-instructions-button')
	})

	it('should focus on the correct element when wrapping around', function(){
		const firstFocus = jest.fn()
		const secondFocus = jest.fn()
		document.getElementsByClassName = jest.fn().mockReturnValue([
			{ children: [ {focus: firstFocus }] } ,
			{ children: [ {focus: secondFocus }] }
		])

		$scope.start(widgetInfo, qset.data);
		$scope.wraparound()

		expect(firstFocus).toHaveBeenCalledTimes(1)
		expect(secondFocus).not.toHaveBeenCalled()
	})

	it('should update the aria live value when handleWholePlayerKeyup handles a press of the S key', function() {
		$scope.start(widgetInfo, qset.data);
		expect($scope.ariaLive).toBe('')

		const spoofKeyUpEvent = { code: 'KeyS' }
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent)

		// we happen to know what this will look like given the demo qset, but it's a bit magical
		expect($scope.ariaLive).toBe('9 questions remaining, current score is 0 out of 100 points.')

		// this isn't what actually happens but it doesn't really matter here
		$scope.answeredQuestions.push(1)
		$scope.answeredQuestions.push(2)
		$scope.answeredQuestions.push(3)

		$scope.percentCorrect = 28

		$scope.handleWholePlayerKeyup(spoofKeyUpEvent)
		expect($scope.ariaLive).toBe('6 questions remaining, current score is 28 out of 100 points.')

		$scope.allAnswered = true
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent)
		expect($scope.ariaLive).toBe('All questions have been answered')
	})

	it('should select the earliest unanswered question when handleWholePlayerKeyup handles a press of the Q key', function() {
		jest.spyOn($scope, 'selectQuestion')

		$scope.start(widgetInfo, qset.data);

		const spoofKeyUpEvent = { code: 'KeyQ' }

		// test the do-nothing cases first
		// some of these are already at their default values, we'll set them explicitly here for consistency
		$scope.instructionsOpen = true
		$scope.allAnswered = false
		$scope.currentQuestion = null
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent)
		expect($scope.selectQuestion).not.toHaveBeenCalled()

		$scope.instructionsOpen = false
		$scope.allAnswered = true
		$scope.currentQuestion = null
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent)
		expect($scope.selectQuestion).not.toHaveBeenCalled()

		$scope.instructionsOpen = false
		$scope.allAnswered = false
		$scope.currentQuestion = $scope.categories[0].items[0]
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent)
		expect($scope.selectQuestion).not.toHaveBeenCalled()

		// now make sure the first question is selected automatically
		$scope.instructionsOpen = false
		$scope.allAnswered = false
		$scope.currentQuestion = null
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent)
		expect($scope.selectQuestion).toHaveBeenCalledTimes(1)
		expect($scope.selectQuestion).toHaveBeenCalledWith($scope.categories[0], $scope.categories[0].items[0])

		$scope.selectQuestion.mockReset()

		// now set the first two questions' scores to make sure it selects the third question automatically
		$scope.instructionsOpen = false
		$scope.allAnswered = false
		$scope.currentQuestion = null
		$scope.categories[0].items[0].score = '100'
		$scope.categories[0].items[1].score = '100'
		$scope.handleWholePlayerKeyup(spoofKeyUpEvent)
		expect($scope.selectQuestion).toHaveBeenCalledTimes(1)
		expect($scope.selectQuestion).toHaveBeenCalledWith($scope.categories[0], $scope.categories[0].items[2])
	})
});
