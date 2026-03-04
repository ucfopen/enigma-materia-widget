/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Enigma = angular.module('enigmaCreator');

Enigma.controller('enigmaCreatorCtrl', ['$scope', '$timeout', '$sce', function($scope, $timeout, $sce) {
	// private constants to refer to any problems a question might have
	const _QUESTION_PROBLEM     = 'Question undefined.';
	const _CREDIT_PROBLEM       = 'Inadequate credit.';
	const _REPEAT_PROBLEM       = 'Duplicate answers.';
	const _BLANK_ANSWER_PROBLEM = 'Blank answer(s).';
	const _NO_ANSWER_PROBLEM    = 'No answers.';

	$scope.title = '';
	$scope.qset = {};

	// keep track of the question we're currently dealing with and what category it's in
	$scope.curCategory = false;
	$scope.curQuestion = false;

	// toggle for question editor sub-menu
	$scope.subMenu = false;

	// keep track of any complete questions that the mouse is hovering over
	$scope.hoverCategory = false;
	$scope.hoverQuestion = false;

	// keep track of which initial instructions need to be displayed
	$scope.step = 0;

	// controls whether the first-time tutorial appears - set true when making a new widget
	$scope.showIntroDialog = false;
	// shortcut to keep track of the title entered into the intro dialog
	$scope.introTitle;

	// used to bring up an 'edit title' dialog
	$scope.showTitleDialog = false;

	// used to store and cancel any on-screen alerts as necessary
	let _alertTimer = null;

	let _categoryTempName = '';

	// when a question is done editing, use this to display a message if it is not complete
	$scope.incompleteMessage = false;

	// used with incompleteMessage when a widget is technically valid but potentially still incomplete
	$scope.warningMessage = false;

	$scope.imported = [];

	// EngineCore Public Interface
	$scope.initNewWidget = (widget, baseUrl) => $scope.$apply(function() {
        $scope.title = 'My Enigma widget';
        $scope.qset = {
            items: [],
            options: {
                randomize: true
            }
        };
        _buildScaffold();
        return $scope.showIntroDialog = true;
    });

	$scope.initExistingWidget = function(title, widget, qset, version, baseUrl) {
		if (qset.data) {
			qset = qset.data;
		}

		// loop through each question in each category and validate all incoming questions
		let i = 0;
		while (i < qset.items.length) {
			// also sanitize category names if necessary
			if (!qset.items[i].name) { qset.items[i].name = ' '; }

			// also make sure every category has an index
			if (!qset.items[i].index) { qset.items[i].index = i; }

			var j = 0;
			while (j < qset.items[i].items.length) {
				qset.items[i].items[j] = _checkQuestion(qset.items[i].items[j]);
				j++;
			}
			i++;
		}


		if (i > 0) { $scope.step = 4; } // if this widget had some questions, assume the instructions are unnecessary

		return $scope.$apply(function() {
			$scope.title = title;
			$scope.qset = qset;
			return _buildScaffold();
		});
	};

	// set default values for the widget - 5 empty categories with 6 empty questions each
	var _buildScaffold = function() {
		// create 5 empty categories
		// start category indices at 0
		let question;
		let i = 0;
		// unless there are already categories, in which case start after the highest
		if ($scope.qset.items.length > 0) {
			i = $scope.qset.items[$scope.qset.items.length-1].index + 1;
		}

		while ($scope.qset.items.length < 5) {
			$scope.qset.items.push({
				name: '',
				items: [],
				untouched: true,
				index: i++
			});
		}

		// make sure there's at least one empty category at the end
		if (!$scope.qset.items[$scope.qset.items.length - 1].untouched) {
			$scope.qset.items.push({
				name: '',
				items: [],
				untouched: true,
				index: i++
			});
		}

		// create 6 empty questions per category
		for (var category of Array.from($scope.qset.items)) {
			i = 0;
			while (category.items.length < 6) {
				category.items.push(_newQuestion());
			}
			for (question of Array.from(category.items)) {
				question.index = i++;
			}
		}

		// go through each category
		i = 0;
		return (() => {
			const result = [];
			while (i < $scope.qset.items.length) {
			// if any categories don't have a name
				if (!$scope.qset.items[i].name) {
					// make sure none of the category's questions have any text
					var found = false;
					for (question of Array.from($scope.qset.items[i].items)) {
						if (question.questions[0].text) {
							found = true;
						}
					}

					if (!found && $scope.qset.items[i+1] && $scope.qset.items[i+1].name) {
						$scope.qset.items.splice(i,1);
						i--;
						break;
					}
				}
				result.push(i++);
			}
			return result;
		})();
	};

	$scope.importDropped = function(category, item) {
		//find the last empty question in this category
		for (var q of Array.from(category.items)) {
			if (q.untouched) {
				item.index = q.index;
				category.items[q.index] = _checkQuestion(item);
				_showProblems(item);
				return true;
			}
		}
		// if there aren't any empty questions in this category, don't take this question
		return false;
	};

	// called by the creator core after a list of questions has been selected for import
	$scope.onQuestionImportComplete = questions => $scope.$apply(() => $scope.imported = questions.concat($scope.imported));

	// get the total number of questions in the widget so Angular can put it on the page
	$scope.numQuestions = function() {
		if (($scope.qset.items == null)) {
			return 0;
		}
		let i = 0;
		for (var category of Array.from($scope.qset.items)) {
			for (var question of Array.from(category.items)) {
				if (question.complete) { i++; }
			}
		}
		return i;
	};

	$scope.categoryOpacity = function(category, index) {
		let opacity = 0.1;
		if (($scope.step === 1) && (index === 0)) {
			opacity = 1;
		}
		if (category.name || category.isEditing) {
			opacity = 1;
		}
		return opacity;
	};

	$scope.categoryShowAdd = (category, index) => !category.name && !category.isEditing &&
    ((index === 0) || !$scope.qset.items[index-1].untouched);

	$scope.categoryEnabled = (category, index) => (index === 0) || (category.name !== '') || ($scope.qset.items[index-1].name !== '');

	$scope.setTitle = function() {
		$scope.title = $scope.introTitle || $scope.title;
		return $scope.hideCover();
	};

	// responds to a number of stimuli to hide the intro screen
	$scope.hideCover = function() {
		if ($scope.step === 0) { $scope.step = 1; } // the widget has a title - bring up the instructions for adding the first category
		return $scope.showIntroDialog = ($scope.showTitleDialog = false);
	};

	$scope.newCategory = function(index, category) {
		category.isEditing = true;
		if ($scope.step === 1) { return $scope.step = 2; } // the first category has been clicked - display instructions for giving it a name
	};

	// editing a category
	$scope.editCategory = function(category) {
		category.isEditing = true;
		_categoryTempName = category.name;
		return $scope.curQuestion = false;
	};

	// done editing a category
	$scope.stopCategory = function(category) {
		// don't do anything unless the category was named properly
		if (category.name) {
			if ($scope.qset.items[$scope.qset.items.length-1].name) {
				$scope.qset.items.push({
					name: '',
					items: [],
					untouched: true,
					index: $scope.qset.items.length
				});
				_buildScaffold();
			}

			category.isEditing = false;
			category.untouched = false;
			if ($scope.step === 2) { $scope.step = 3; } // the first category has been named - display instructions for adding the first question
		} else {
			if (_hasQuestions(category)) {
				if (!$scope.deleteCategory(category)) { category.name = _categoryTempName; }
			} else {
				// delete it if it was named before, otherwise this is because we canceled naming a new category
				if (!category.untouched) { _deleteCategory(category); }
			}
		}
		category.isEditing = false;
		return _categoryTempName = '';
	};

	$scope.deleteCategory = function(category) {
		if (_hasQuestions(category)) {
			if (window.confirm("Deleting this category will also delete all of the questions it contains!\n\nAre you sure?")) {
				_deleteCategory(category);
			} else {
				return false;
			}
		} else {
			_deleteCategory(category);
		}
		return true;
	};

	var _hasQuestions = function(category) {
		for (var question of Array.from(category.items)) {
			if (!question.untouched) { return true; }
		}
		return false;
	};

	var _deleteCategory = function(category) {
		$scope.qset.items.splice(category.index, 1);
		if ($scope.qset.items[$scope.qset.items.length-1].name) {
			$scope.qset.items.push({
				items: [],
				untouched: true,
				index: $scope.qset.items.length
			});
		}
		_buildScaffold();

		let wasOnly = true;

		//reset all of the remaining categories' index properties or Angular will get confused
		let i = 0;
		while (i < $scope.qset.items.length) {
			if ($scope.qset.items[i].untouched === false) { wasOnly = false; }
			$scope.qset.items[i].index = i++;
		}

		// if they're still in tutorial mode and they haven't added a question yet, step back
		if (wasOnly && ($scope.step === 3)) { return $scope.step = 1; }
	};

	$scope.categoryReorder = function(index, forward) {
		const temp = $scope.qset.items[index];
		if (forward) {
			$scope.qset.items[index] = $scope.qset.items[index+1];
			$scope.qset.items[index].index = index;
			$scope.qset.items[index+1] = temp;
			return $scope.qset.items[index+1].index = index+1;
		} else {
			$scope.qset.items[index] = $scope.qset.items[index-1];
			$scope.qset.items[index].index = index;
			$scope.qset.items[index-1] = temp;
			return $scope.qset.items[index-1].index = index-1;
		}
	};

	// show the question add button for the given question index in the given category if:
	// the category has been named and is not being edited
	// and the question hasn't been edited from defaults
	// or if this is the first question in the category
	// or if it's not the first, and the previous question has been edited from defaults
	$scope.questionShowAdd = (category, question, index) => (category.name != null) && !category.untouched && !category.isEditing &&
    question.untouched &&
    ((index === 0) || !category.items[index-1].untouched);

	$scope.editQuestion = function(category, question, index) {
		// reset anything that may still be around from a prior completion alert
		$scope.incompleteMessage = false;
		$scope.warningMessage    = false;
		$timeout.cancel(_alertTimer);

		// make sure we can edit this question
		// the category has been named, this is the first question in the category, this or the previous question has been edited already
		if ((category.name && !category.isEditing && (index === 0)) || !category.items[index].untouched || ((index > 0) && !category.items[index-1].untouched)) {
			$scope.curQuestion = question;
			$scope.curCategory = category;

			for (var answer of Array.from(question.answers)) {
				answer.options.correct = false;
				answer.options.custom = false;

				// set the 'correct' or 'custom' flags for answers if necessary
				if (answer.value === 100) {
					answer.options.correct = true;
				} else if ((answer.value !== 100) && (answer.value !== 0)) {
					answer.options.custom = true;
				}
			}

			if ($scope.step === 3) { return $scope.step = 4; } // the first question has been added - no further instructions
		}
	};

	// Done button clicked, assign point values to valid answers and indicate question has been edited
	$scope.editComplete = function() {
		// run the current question through validation
		_checkQuestion($scope.curQuestion);

		_showProblems($scope.curQuestion);

		$scope.subMenu = false;
		$scope.curCategory = false;
		return $scope.curQuestion = false;
	};

	// delete a question; removes question from the order completely
	$scope.deleteQuestion = function() {
		// get this question's index so we can reset the index of each following question
		let i = $scope.curQuestion.index;

		// get rid of this question and put a blank one on the end of the category's stack
		$scope.qset.items[$scope.curCategory.index].items.splice($scope.curQuestion.index, 1);
		$scope.qset.items[$scope.curCategory.index].items.push(_newQuestion());

		// reset all of the questions' index properties to match the change
		while (i < $scope.qset.items[$scope.curCategory.index].items.length) {
			$scope.qset.items[$scope.curCategory.index].items[i].index = i++;
		}
		return $scope.curQuestion = false;
	};

	// change the order of questions within a category
	$scope.questionReorder = function(forward) {
		const currentIndex = $scope.curQuestion.index;
		const temp = $scope.curCategory.items[currentIndex];
		if (forward) {
			$scope.curCategory.items[currentIndex] = $scope.curCategory.items[currentIndex+1];
			$scope.curCategory.items[currentIndex].index = currentIndex;
			$scope.curCategory.items[currentIndex+1] = temp;
			return $scope.curCategory.items[currentIndex+1].index = currentIndex+1;
		} else {
			$scope.curCategory.items[currentIndex] = $scope.curCategory.items[currentIndex-1];
			$scope.curCategory.items[currentIndex].index = currentIndex;
			$scope.curCategory.items[currentIndex-1] = temp;
			return $scope.curCategory.items[currentIndex-1].index = currentIndex-1;
		}
	};

	var _newQuestion = () => ({
        type: 'MC',
        id: '',

        questions: [
            {text: ''}
        ],

        answers: [
            _newAnswer(),
            _newAnswer()
        ],

        untouched: true,
        complete: false,
        problems: [],
        index: 0,
        options: {}
    });

	$scope.addAnswer = () => $scope.curQuestion.answers.push(_newAnswer());

	$scope.deleteAnswer = index => $scope.curQuestion.answers.splice(index,1);

	var _newAnswer = () => ({
        id: '',
        text: '',
        value: 0,

        options: {
            feedback: '',
            custom: false,
            correct: false
        }
    });

	$scope.toggleCorrect = function(answer) {
		if (answer.options.correct) { return answer.value = 100; } else { return answer.value =  0; }
	};

	// called when an answer's custom value is changed - makes sure no non-numbers are present
	$scope.numbersOnly = function(answer) {
		// strip out any non-numbers and cast it to a number
		answer.value = Number(answer.value.replace(/[^\d-]/g, ''));
		// constrain it between 0 and 100
		if (~~answer.value > 100) { answer.value = 100; }
		if (~~answer.value < 0) { answer.value = 0; }
		return answer.options.correct = answer.value === 100;
	};

	// Assets

	$scope.showPopUp = function() {
		$scope.mediaPopUp = true;
		return $scope.hideVideoForm();
	};

	$scope.hidePopUp = function() {
		$scope.mediaPopUp = false;
		return $scope.hideVideoForm();
	};

	$scope.uploadAudio = function() {
		$scope.curQuestion.mediaType = "audio";
		$scope.hideVideoForm();
		return Materia.CreatorCore.showMediaImporter(["audio"]);
	};

	$scope.uploadImage = function() {
		$scope.curQuestion.mediaType = "image";
		$scope.hideVideoForm();
		return Materia.CreatorCore.showMediaImporter(["image"]);
	};

	$scope.showVideoForm = () => $scope.videoForm = true;

	$scope.hideVideoForm = function() {
		$scope.videoForm = false;
		return $scope.urlError = null;
	};

	$scope.onMediaImportComplete = function(media) {
		$scope.removeMedia();
		$scope.curQuestion.options.asset = {
			type: $scope.curQuestion.mediaType,
			value: Materia.CreatorCore.getMediaUrl(media[0].id),
			id: media[0].id,
			description: $scope.curQuestion.description
		};
		$scope.hidePopUp();
		return $scope.$apply();
	};

	$scope.removeMedia = function() {
		$scope.url = null;
		return delete $scope.curQuestion.options.asset;
	};

	$scope.formatUrl = function() {
		let embedUrl;
		try {
			embedUrl = '';
			if ($scope.inputUrl.includes('youtu')) {
				const stringMatch = $scope.inputUrl.match(/^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?$/);
				embedUrl = ('https://www.youtube.com/embed/' + stringMatch[5]) || ($scope.inputUrl.includes('/embed/') ? $scope.inputUrl : undefined);
			} else if ($scope.inputUrl.includes('vimeo')) {
				embedUrl = ('https://player.vimeo.com/video/' + $scope.inputUrl.match(/(?:vimeo)\.com.*(?:videos|video|channels|)\/([\d]+)/i)[1]) || $scope.inputUrl;
			} else {
				$scope.urlError = 'Please enter a YouTube or Vimeo URL.';
				return;
			}
		} catch (e) {
			$scope.urlError = 'Please enter a YouTube or Vimeo URL.';
			return;
		}

		$scope.hidePopUp();

		return $scope.curQuestion.options.asset = {
			type: "video",
			value: $sce.trustAsResourceUrl(embedUrl),
			id: embedUrl,
			description: ''
		};
	};

	// prepare some checks to make sure the given question is 'complete':
	var _checkQuestion = function(question) {
		// has question text
		const hasQuestion = question.questions[0].text !== '';
		// has at least one answer worth 100%
		let fullCredit = false;
		// doesn't have any repeat answers
		const repeatChecks = [];
		let hasRepeats = false;
		// or blank answers
		let blankAnswer = false;
		// and has answers at all
		const noAnswers = question.answers.length === 0;

		// old qsets set question.options as an array; it needs to be an object. Convert it if necessary.
		if (Array.isArray(question.options) && (question.options.length === 0)) { question.options = {}; }

		// store whatever problems remain in the question for later
		const problems = [];

		for (var answer of Array.from(question.answers)) {
			// make sure we interpret the given answer as a string, then remove extraneous whitespace
			answer.text += '';
			var trimmedAnswer = answer.text.trim();
			if (trimmedAnswer === '') { blankAnswer = true; }
			// keep track of each possible answer
			if (!repeatChecks[trimmedAnswer]) {
				repeatChecks[trimmedAnswer] = true; // store this word so we can look for it later
			} else {
				hasRepeats = true;
			}

			if (answer.options.correct) {
				answer.value = 100;
			} else {
				answer.value = parseInt(answer.value,10);
			}

			// make sure options are set correctly based on value
			if ((answer.value === 100) || (answer.value === 0)) {
				answer.options.custom = false;
				answer.options.correct = answer.value === 100;
			} else {
				answer.options.custom = true;
				answer.options.correct = false;
			}

			if (answer.value === 100) { fullCredit = true; }
		}

		// this question is complete if it has question text, one answer worth 100%, and no repeated answers
		const isComplete = hasQuestion && !noAnswers && fullCredit && !hasRepeats && !blankAnswer;

		// if the question is 'incomplete', keep track of any reasons why
		if (!isComplete) {
			if (!hasQuestion) {
				problems.push(_QUESTION_PROBLEM);
			}
			if (!fullCredit) {
				problems.push(_CREDIT_PROBLEM);
			}
			if (hasRepeats) {
				problems.push(_REPEAT_PROBLEM);
			}
			if (blankAnswer) {
				problems.push(_BLANK_ANSWER_PROBLEM);
			}
			if (noAnswers) {
				problems.push(_NO_ANSWER_PROBLEM);
			}
		}

		// store any problems for this question and flag it as edited
		question.complete = isComplete;
		question.problems = problems;
		question.untouched = false;

		return question;
	};

	var _showProblems = function(question) {
		// compile any problems in an array for Angular to display
		let incompleteMessage = [];

		// if the question is 'incomplete', alert reasons why
		if (!question.complete) {
			incompleteMessage = question.problems;
			incompleteMessage.unshift("Warning: this question is incomplete!");
		} else {
			// make additional checks here for any potential warnings

			// if there's only one answer for this question
			if (question.answers.length < 2) {
				incompleteMessage.push('Only one answer found.');
			}

			// specify that these are warnings, not show-stoppers
			if (incompleteMessage.length > 0) {
				$scope.warningMessage = true;
				incompleteMessage.unshift('Attention: this question may be incomplete!');
			}
		}


		// bring up a temporary alert describing any problems
		if (incompleteMessage.length > 0) {
			$scope.incompleteMessage = incompleteMessage;
			$scope.startFade = true;

			return _alertTimer = $timeout(() => $scope.killAlert()
			, 10000);
		}
	};

	// hide the alert early if the user clicks on it
	$scope.killAlert = function() {
		$scope.incompleteMessage = false;
		return $scope.warningMessage    = false;
	};

	// draw a tooltip near a question when the mouse is over it if that question is invalid
	$scope.markQuestion = function(category, question) {
		if (question.untouched) { return; }
		$scope.hoverQuestion = question;
		return $scope.hoverCategory = category;
	};

	// remove the tooltip indicating problems with a question
	$scope.unmarkQuestion = function() {
		$scope.hoverQuestion = false;
		return $scope.hoverCategory = false;
	};

	$scope.onSaveClicked = function(mode) {
		if (mode == null) { mode = 'save'; }
		const qset = _buildSaveData();
		const msg = mode === 'history' ? false : _validateQuestions(qset);
		if (msg) {
			return Materia.CreatorCore.cancelSave(msg);
		} else {
			return Materia.CreatorCore.save($scope.title, qset);
		}
	};

	var _buildSaveData = function() {
		// duplicate the model and remove angular hash keys
		const qset = angular.copy($scope.qset);

		let i = 0;
		// for each category
		while (i < qset.items.length) {
			var catUntouched = qset.items[i].untouched;
			// remove creator-specific properties; save problems for validation phase
			delete qset.items[i].untouched;
			delete qset.items[i].isEditing;

			// remove empty categories; no name, no questions, or never touched
			if ((qset.items[i] && catUntouched) || (((qset.items[i] != null ? qset.items[i].items.length : undefined) === 0) && !qset.items[i].name)) {
				qset.items.splice(i,1);
				i--;
				continue;
			}

			// for each question
			var j = 0;
			while (j < (qset.items[i] != null ? qset.items[i].items.length : undefined)) {
				var questionUntouched = qset.items[i].items[j].untouched;
				// remove creator-specific properties; save problems for validation phase
				delete qset.items[i].items[j].untouched;
				delete qset.items[i].items[j].complete;

				// remove empty questions; no name, no answers, or never touched
				if (questionUntouched || ((qset.items[i].items[j].answers.length === 0) && !qset.items[i].items[j].questions[0].text)) {
					qset.items[i].items.splice(j,1);
					j--;
				}
				j++;
			}
			i++;
		}
		return qset;
	};

	var _validateQuestions = function(qset) {
		let compiledMessage = '';

		// simplest check - are there any categories?
		if (!qset.items.length) { return 'No categories found.'; }

		let i = 0;
		while (i < qset.items.length) {
			var j = 0;
			var category = qset.items[i];
			while (j < category.items.length) {
				var question = category.items[j];
				if (question.problems.length > 0) {
					for (var problem of Array.from(question.problems)) {
						compiledMessage += "\nQuestion "+(j+1)+" in category "+category.name+": "+problem;
					}
				}
				delete qset.items[i].items[j].problems;
				j++;
			}
			i++;
		}
		if (compiledMessage) { return compiledMessage; }
		return false;
	};

	$scope.onSaveComplete = (title, widget, qset, version) => true;

	return Materia.CreatorCore.start($scope);
}
]);
