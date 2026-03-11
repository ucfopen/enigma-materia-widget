/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Enigma = angular.module('enigmaPlayer', ['ngAria']);

Enigma.controller('enigmaPlayerCtrl', ['$scope', '$timeout', '$sce', function($scope, $timeout, $sce) {
	$scope.title      = '';
	$scope.categories = [];
	$scope.scores     = [];

	$scope.totalQuestions    = 0;
	$scope.answeredQuestions = [];
	$scope.allAnswered       = false;

	$scope.currentCategory = null;
	$scope.currentQuestion = null;
	$scope.currentAnswer   = null;

	// these are used by the score graphics to draw percentages
	$scope.circumference = Math.PI * 100;
	$scope.changingNumber = false;

	$scope.percentCorrect = 0;
	$scope.percentIncorrect = 0;

	$scope.showTutorial = true;

	$scope.instructionsOpen = false;
	$scope.questionInstructionsOpen = false;

	let highlightedCategory = null;
	let highlightedQuestion = null;

	// variable to check which screen the user is on (true = gameboard)
	$scope.checkTab = true;
	// variable checks if on final submit for grading screen
	$scope.finalTab = false;

	// force screen readers to immediately read the string value
	// keeping the scope variable for now so tests don't have to be completely rewritten
	$scope.ariaLive = '';
	const forceRead = function(readString) {
		$scope.ariaLive = readString;
		if (!readString) { return; }
		document.getElementById('aria-live').innerHTML = readString;
	};

	// Called by Materia.Engine when your widget Engine should start the user experience.
	$scope.start = function(instance, qset, version) {
		if (version == null) { version = '1'; }
		$scope.title = instance.name;
		// Make an array of each category, questions, and count the questions.
		for (var ci in qset.items) {
			var category = qset.items[ci];
			if (typeof(category.name) === 'string') { category.name = category.name.toUpperCase(); }
			category.index = ci;
			$scope.categories[ci] = category;
			for (var qi in category.items) {
				var question = category.items[qi];
				if (qset.options.randomize) { question.answers = _shuffle(question.answers); }
				question.index = qi;
				$scope.totalQuestions++;
				if (question.options.asset) {
					switch (question.options.asset.type) {
						case 'image': question.options.asset.value = Materia.Engine.getMediaUrl(question.options.asset.id); break;
						case 'audio': question.options.asset.value = Materia.Engine.getMediaUrl(question.options.asset.id); break;
						case 'video': question.options.asset.value = $sce.trustAsResourceUrl(question.options.asset.id); break;
					}
				}
			}
		}


		$scope.$apply();

		// wait for content to render, then compute player height and pass it to the enginecore to update the height of the iframe
		$timeout(function() {
			const h = _getPlayerHeight();
			Materia.Engine.setHeight(h);
			document.getElementById('tutorial-modal-dismiss').focus();
		});
	};

	var _getPlayerHeight = function() {
		let height;
		return height = Math.ceil(parseFloat(window.getComputedStyle(document.querySelector('html')).getPropertyValue('height')));
	};

	// randomize the order of a question's answers
	var _shuffle = function(a) {
		for (let i = 1, end = a.length, asc = 1 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
			var j = Math.floor(Math.random() * (a.length));
			[a[i], a[j]] = Array.from([a[j], a[i]]);
		}
		return a;
	};

	// this used to focus on the text element containing the question
	// to help with accessibility this now focuses on the keyboard instructions element to help keyboard users
	const focusOnQuestionText = function(setTabIndex) {
		// this changes the focus automatically to the active area, otherwise
		// focus remains on previous screen after question is selected
		if (setTabIndex == null) { setTabIndex = true; }
		setTimeout((() => document.getElementById('show-question-keyboard-instructions-button').focus()), 100);
		if (setTabIndex) { $scope.setTabIndex(); }
	};

	const focusOnLightboxContent = () => setTimeout((function() {
        if ($scope.currentQuestion.options.asset.type === 'video') {
            document.getElementsByClassName('lightbox-video')[0].focus();
        }
        if ($scope.currentQuestion.options.asset.type === 'image') {
            document.getElementsByClassName('lightbox-close')[0].focus();
        }
    }), 100);

	$scope.dismissTutorial = function() {
		$scope.showTutorial = false;
		$timeout(() => document.getElementById('show-keyboard-instructions-button').focus());
	};

	$scope.handleWholePlayerKeyup = function(e) {
		switch (e.code) {
			case 'KeyH':
				forceRead("Keyboard instructions: Questions are sorted into categories. " +
					"Use the Tab key to navigate through the game board to view and select questions. " +
					"Answer all questions to complete the widget. " +
					"Press the 'Q' key to automatically select the earliest unanswered question. " +
					"Press the 'S' key to hear your current score and how many unanswered questions are remaining. " +
					"Press the 'W' key to hear which question and category you currently have highlighted. " +
					"Press the 'H' key to hear these instructions again."
				);
				break;
			case 'KeyQ': 
				$scope.selectEarliestUnanswered();
				break;
			case 'KeyS':
				if ($scope.allAnswered) {
					forceRead('All questions have been answered');
				} else {
					forceRead(($scope.totalQuestions - $scope.answeredQuestions.length) +
						' questions remaining, current score is ' +
						$scope.percentCorrect + ' out of 100 points.'
					);
				}
				break;
			case 'KeyW':
				if (!highlightedCategory) {
					forceRead('You have not highlighted a question yet, please use the Tab key to progress to the game board.');
					return;
				}
				forceRead('Current location is question ' + (parseInt(highlightedQuestion.index, 10) + 1) + ' of ' +
					highlightedCategory.items.length + ' in category ' + (parseInt(highlightedCategory.index, 10) + 1) + ' of ' +
					$scope.categories.length + ': ' + highlightedCategory.name + '. Press Space or Enter to select this question.'
				);
				break;
		}
	};



	$scope.highlightQuestion = function(c, q) {
		highlightedCategory = c;
		highlightedQuestion = q;
	};

	$scope.selectEarliestUnanswered = function() {
		if ($scope.instructionsOpen || $scope.allAnswered || $scope.currentQuestion) { return; }
		for (let ci = 0; ci < $scope.categories.length; ci++) {
			var c = $scope.categories[ci];
			for (var qi = 0; qi < c.items.length; qi++) {
				var q = c.items[qi];
				if (typeof q.score === 'undefined') {
					$scope.selectQuestion(c, q);
					return;
				}
			}
		}
	};

	$scope.selectQuestion = function(category, question) {
		if ($scope.currentQuestion) { throw Error('A question is already selected!'); }
		if (!question.answered) {
			$scope.currentCategory = category;
			$scope.currentQuestion = question;

			focusOnQuestionText();
		}
	};

	// Lightbox in question pop up
	$scope.lightboxTarget = -1;

	$scope.setLightboxTarget = function(val) {
		$scope.lightboxTarget = val;
		if (val < 0) { focusOnQuestionText(false);
		} else { focusOnLightboxContent(); }
	};

	const moveAnswer = function(index) {
		if (index < 0) {
			index = $scope.currentQuestion.answers.length-1;
		} else if (index >= $scope.currentQuestion.answers.length) {
			index = 0;
		}
		const targetLi = document.getElementById('t-question-page')
			.getElementsByClassName('question-li')[index];
		targetLi.focus();
	};

	$scope.handleAudioKeyUp = function(event) {
		event.stopPropagation();
		if ((event.code === 'Space') || (event.code === 'Enter')) {
			event.preventDefault();
			if (event.currentTarget.paused) {
				event.currentTarget.play();
			} else {
				event.currentTarget.pause();
			}
		}
	};

	$scope.handleQuestionKeyUp = function(event) {
		switch (event.code) {
			case 'Escape': $scope.cancelQuestion(); break;
			case 'KeyQ':
				forceRead('Question: ' + $scope.currentQuestion.questions[0].text);
				break;
			case 'KeyS':
				if ($scope.currentAnswer) {
					document.getElementById('submit').focus();
				} else { forceRead('You must select an answer first.'); }
				break;
			case 'KeyH':
				// have to do it verbose like this otherwise jest chokes on this file for some reason
				var assetIndicator = '';
				if ($scope.currentQuestion.options.asset) {
					assetIndicator = 'to the associated media, then ';
				}
				forceRead('Use the Tab key to navigate ' + assetIndicator +
					'through answer options, then to reach the Return and Submit Final Answer buttons. ' +
					'The Up and Down arrow keys may also be used to navigate through answer options. ' +
					'Press the Enter or Space key on an answer option to select it. ' +
					'Pressing the Escape key will leave this question and allow you to select another question. ' +
					'Press the Q key to hear the question again. ' +
					'Press the S key after selecting an answer to be taken to the Submit Final Answer button automatically. ' +
					'Press the H key to hear these instructions again.'
				);
				break;
			case 'ArrowUp': moveAnswer($scope.currentQuestion.answers.length-1); break;
			case 'ArrowDown': moveAnswer(0); break;
		}
		event.stopPropagation();
	};

	$scope.handleAnswerKeyUp = function(event, index, answer) {
		switch (event.code) {
			case 'Enter': case 'Space': $scope.selectAnswer(answer); break;
			case 'ArrowUp': moveAnswer(index - 1); break;
			case 'ArrowDown': moveAnswer(index + 1); break;
			// allow these key events to bubble up to the question container, stop propagation for the rest
			case 'KeyQ':case 'KeyS':case 'KeyH':case 'Escape': return;
		}
		event.stopPropagation();
	};

	// return focus to the top left corner of the gameboard, as if tabbing into it from the score indicator
	$scope.wraparound = e => document.getElementsByClassName('question')[0].focus();

	$scope.selectAnswer = function(answer) {
		if (!$scope.currentQuestion) { throw Error('Select a question first!'); }
		if (!$scope.currentQuestion.answered) { $scope.currentAnswer = answer; }
		forceRead('Answer ' + $scope.currentAnswer.text + ' selected');
	};

	$scope.cancelQuestion = function() {
		const _wasUpdated = $scope.currentQuestion.answered;

		$scope.currentCategory = null;
		$scope.currentQuestion = null;
		$scope.currentAnswer   = null;

		if (_wasUpdated) { _updateScore(); }

		if ($scope.scores.length === $scope.totalQuestions) { _gameOver(); }
		$scope.findQuestion();
		$scope.setTabIndex();
		// resets status div that gives answer feedback so it can't be tabbed to
		forceRead("");
	};

	// function to find the first unanswered question in list and shift focus to it
	$scope.findQuestion = () => (() => {
        const result = [];
        for (var item of Array.from(document.getElementsByClassName('question'))) {
            if (item.title.includes('Unanswered')) {
                setTimeout((() => item.focus()), 100);
                break;
            } else {
                result.push(undefined);
            }
        }
        return result;
    })();

	$scope.submitAnswer = function() {
		if ($scope.currentQuestion.answered) { throw Error('Question already answered!'); }
		const check = _checkAnswer();
		if (check.score !== undefined) {
			let returnMessage;
			$scope.currentQuestion.answered = true;

			// the following provides feedback upon submitting an answer

			Materia.Score.submitQuestionForScoring($scope.currentQuestion.id, check.text);
			$scope.scores.push(check.score);

			$scope.currentQuestion.score = check.score;
			$scope.answeredQuestions.push($scope.currentQuestion);

			if ($scope.answeredQuestions.length === $scope.totalQuestions) {
				returnMessage = " Press the Space or Enter key to continue to the submit screen.";
			} else {
				returnMessage = " Press the Space or Enter key to return to the game board.";
			}

			document.getElementById('return').focus();

			if (check.score === 100) {
				forceRead(check.text + " is correct!" + returnMessage);
			} else if ((check.score > 0) && (check.score < 100)) {
				forceRead(check.text + " is only partially correct. " + check.correct + " is the correct answer." + returnMessage);
			} else {
				forceRead(check.text + " is incorrect. The correct answer was " + check.correct + "." + returnMessage);
			}
		} else {
			throw Error('Submitted answer not in this question!');
		}
	};

	// changes checkTab to false when on question screen and true when on gameboard so
	// that you can't tab through the hidden screen
	$scope.setTabIndex = () => $scope.checkTab = !$scope.checkTab;

	// displays a keyboard instructions dialog and sets inert on everything else to
	// control tab targets
	$scope.toggleInstructions = function() {
		$scope.instructionsOpen = !$scope.instructionsOpen;
		// wait for inert status to be removed/added properly before moving focus
		setTimeout((function() {
			if ($scope.instructionsOpen) {
				document.getElementById('hide-keyboard-instructions-button').focus();
			} else {
				document.getElementById('show-keyboard-instructions-button').focus();
			}
		}), 100);
	};

	$scope.toggleQuestionInstructions = function() {
		$scope.questionInstructionsOpen = !$scope.questionInstructionsOpen;
		// wait for inert status to be removed/added properly before moving focus
		setTimeout((function() {
			if ($scope.questionInstructionsOpen) {
				document.getElementById('hide-question-keyboard-instructions-button').focus();
			} else {
				document.getElementById('show-question-keyboard-instructions-button').focus();
			}
		}), 100);
	};

	var _updateScore = function() {
		let total = 0;
		for (let i = 0, end = $scope.scores.length, asc = 0 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
			total += $scope.scores[i];
		}

		$scope.percentCorrect = Math.round(total / $scope.totalQuestions);

		const answeredPercent = ($scope.scores.length / $scope.totalQuestions) * 100;
		$scope.percentIncorrect = answeredPercent - $scope.percentCorrect;

		$scope.changingNumber = true;
		$timeout(() => $scope.changingNumber = false
		, 300);
	};

	var _checkAnswer = function() {
		const selected = {
			score: undefined
		};
		for (var answer of Array.from($scope.currentQuestion.answers)) {

			if (answer.value === 100) {
				selected.correct = answer.text;
			}

			if (answer === $scope.currentAnswer) {
					selected.score = parseInt(answer.value, 10);
					selected.text = answer.text;
					selected.feedback = answer.options.feedback;
				}
		}

		return selected;
	};

	var _gameOver = function() {
		$scope.allAnswered = true;
		setTimeout((() => document.getElementById('end-button').focus()), 100);
		$scope.finalTab = true;

		// End, but don't show the score screen yet
		Materia.Engine.end(false);
	};

	$scope.end = () => Materia.Engine.end(true);

	Materia.Engine.start($scope);
}
]);
