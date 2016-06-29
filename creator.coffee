#TODO:
# When attempting to publish a widget compile all problems into a window alert

EnigmaCreator = angular.module 'enigmaCreator', []

EnigmaCreator.directive 'ngEnter', ->
	return (scope, element, attrs) ->
		element.bind "keydown keypress", (event) ->
			if event.which == 13
				scope.$apply ->
					scope.$eval(attrs.ngEnter)
				event.preventDefault()

EnigmaCreator.directive 'focusMe', ['$timeout', '$parse', ($timeout, $parse) ->
	link: (scope, element, attrs) ->
		model = $parse(attrs.focusMe)
		scope.$watch model, (value) ->
			if value
				$timeout ->
					element[0].focus()
			value
]

EnigmaCreator.controller 'enigmaCreatorCtrl', ['$scope', '$timeout', ($scope, $timeout) ->
	# private constants to refer to any problems a question might have
	_QUESTION_PROBLEM = 'Question undefined.'
	_CREDIT_PROBLEM   = 'Inadequate credit.'
	_REPEAT_PROBLEM   = 'Duplicate answers.'
	_ANSWER_PROBLEM   = 'Blank answer(s).'

	$scope.title = ''
	$scope.qset = {}

	# keep track of the question we're currently dealing with and what category it's in
	$scope.curQuestion = false
	$scope.curCategory = false

	# keep track of any questions that the mouse is hovering over if they have problems
	$scope.problemQuestion = false
	$scope.problemCategory = false

	# keep track of which initial instructions need to be displayed
	$scope.step = 0

	# controls whether the first-time tutorial appears - set true when making a new widget
	$scope.showIntroDialog = false

	# when a question is done editing, use this to display a message if it is not complete
	$scope.incompleteMessage = false

	$scope.imported = []

	# forever increasing number to help with dragging/dropping imported questions
	zIndex = 9999

	# EngineCore Public Interface
	$scope.initNewWidget = (widget, baseUrl) ->
		$scope.$apply ->
			$scope.title = 'My Enigma widget'
			$scope.qset =
				items: []
				options:
					randomize: true
			$scope.buildScaffold()
			$scope.showIntroDialog = true

	$scope.initExistingWidget = (title, widget, qset, version, baseUrl) ->
		if qset.data
			qset = qset.data

		$scope.$apply ->
			$scope.title = title
			$scope.qset = qset

	$scope.onSaveClicked = (mode = 'save') ->
		qset = _buildSaveData()
		msg = validateQuestions qset
		if msg
			Materia.CreatorCore.cancelSave msg
		else
			Materia.CreatorCore.save $scope.title, qset

	validateQuestions = (qset) ->
		i = 0
		while i < qset.items.length
			j = 0
			while j < qset.items[i].items.length
				hasAnswer = false
				for answer in qset.items[i].items[j].answers
					if answer.value > 0
						hasAnswer = true
				if !hasAnswer
					return "Question " + (j + 1) + " in the " + (qset.items[i].name) + " category has no correct answer"
				j++
			i++
		return false


	$scope.onSaveComplete = (title, widget, qset, version) -> true

	$scope.onQuestionImportComplete = (questions) ->
		$scope.$apply ->
			$scope.imported = questions.concat $scope.imported
		_initDragDrop()

	$scope.onMediaImportComplete = (media) -> null

	# View properties
	$scope.numQuestions = ->
		if !$scope.qset.items?
			return 0
		i = 0
		for category in $scope.qset.items
			for question in category.items
				i++	if question.questions[0].text
		i

	$scope.categoryOpacity = (category, index) ->
		opacity = 0.1
		if $scope.step is 1 and index is 0
			opacity = 1
		if category.name or category.isEditing
			opacity = 1
		return opacity

	$scope.categoryShowAdd = (category, index) ->
		not category.name and not category.isEditing and (index == 0 or $scope.qset.items[index-1].name)

	$scope.categoryEnabled = (category, index) ->
		index == 0 or $scope.qset.items[index-1].name or $scope.qset.items[index].name

	# show the question add button for the given question index in the given category
	# if the category has been named and the question hasn't been edited from defaults
	# or if this is the first question in the category
	# or if it's not the first, and the previous question has been edited from defaults
	$scope.questionShowAdd = (category, question, index) ->
		category.name? and question.untouched and (index == 0 or !category.items[index-1].untouched)

	# View actions
	$scope.editCategory = (category) ->
		category.isEditing = true
		$scope.curQuestion = false

	$scope.stopCategory = (category) ->
		category.isEditing = false
		$scope.buildScaffold()

	$scope.hideCover = ->
		$scope.showIntroDialog = $scope.showTitleDialog = false

	$scope.setTitle = ->
		$scope.title = $scope.introTitle or $scope.title
		$scope.step = 1 # the widget has a title - bring up the instructions for adding the first category

		$scope.hideCover()

	$scope.editQuestion = (category, question, index) ->
		# make sure we can edit this question
		if category.name and index == 0 or !category.items[index-1].untouched
			$scope.curQuestion = question
			$scope.curCategory = category

			for answer in question.answers
				answer.options.correct = false
				answer.options.custom = false

				if answer.value == 100
					answer.options.correct = true
				else if answer.value isnt 100 and answer.value isnt 0
					answer.options.custom = true

			$scope.step = 4 if $scope.step is 3 # the first question has been added - no further instructions

	# Done button clicked, assign point values to valid answers and indicate question has been edited
	$scope.editComplete = ->
		# prepare some checks to make sure the question is 'complete'
		# has question text
		hasQuestion = $scope.curQuestion.questions[0].text != ''
		# has at least one answer worth 100%
		fullCredit = false
		# doesn't have any repeat answers
		repeatChecks = []
		hasRepeats = false
		# has blank answers
		blankAnswer = false

		# store whatever problems remain in the question for later
		problems = []

		for answer in $scope.curQuestion.answers
			trimmedAnswer = answer.text.trim()
			if trimmedAnswer == '' then blankAnswer = true
			# keep track of each possible answer
			if not repeatChecks[trimmedAnswer]
				repeatChecks[trimmedAnswer] = true # store this word so we can look for it later
			else
				hasRepeats = true

			answer.value = parseInt(answer.value,10)

			if answer.options.custom
				if answer.value == 100 or answer.value == 0
					answer.options.custom = false
					answer.options.correct = if answer.value == 100 then true else false
			else
				answer.value = if answer.options.correct then 100 else 0

			if answer.value == 100 then fullCredit = true

		# this question is complete if it has question text, one answer worth 100%, and no repeated answers
		isComplete = hasQuestion and fullCredit and not hasRepeats

		# if the question is 'incomplete', alert reasons why
		if not isComplete
			incompleteMessage = ["Warning: this question is incomplete!"]
			if not hasQuestion
				incompleteMessage.push _QUESTION_PROBLEM
				problems.push _QUESTION_PROBLEM
			if not fullCredit
				incompleteMessage.push _CREDIT_PROBLEM
				problems.push _CREDIT_PROBLEM
			if hasRepeats
				incompleteMessage.push _REPEAT_PROBLEM
				problems.push _REPEAT_PROBLEM
			if blankAnswer
				incompleteMessage.push _ANSWER_PROBLEM
				problems.push _ANSWER_PROBLEM

			# bring up an alert describing any problems
			$scope.incompleteMessage = incompleteMessage
			$scope.startFade = true
			$timeout ->
				$scope.incompleteMessage = false
			, 5000
		else
			$scope.curQuestion.complete = true
			$scope.curQuestion.problems = []

		$scope.curQuestion.problems = problems
		$scope.curQuestion.untouched = false
		$scope.curQuestion = false

	# hide the alert early if the user clicks on it
	$scope.killAlert = ->
		$scope.incompleteMessage = false

	$scope.markProblems = (category, question) ->
		return unless not question.untouched and not question.complete
		$scope.problemQuestion = question
		$scope.problemCategory = category

	$scope.unmarkProblems = ->
		$scope.problemQuestion = false
		$scope.problemCategory = false

	# 'delete' a question; essentially sets the question in that index to the default state
	$scope.deleteQuestion = (i) ->
		$scope.qset.items[$scope.curCategory.index].items[$scope.curQuestion.index] = $scope.newQuestion(i)
		# since this deletion isn't altering the order, treat this more like setting it to defaults instead of making a whole new question
		$scope.qset.items[$scope.curCategory.index].items[$scope.curQuestion.index].untouched = false
		$scope.curQuestion = false

	$scope.addAnswer = ->
		$scope.curQuestion.answers.push $scope.newAnswer()

	$scope.deleteAnswer = (index) ->
		$scope.curQuestion.answers.splice(index,1)

	$scope.newAnswer = ->
		id: ''
		text: ''
		value: 0
		options:
			feedback: ''
			custom: false
			correct: false

	$scope.newQuestion = (i=0) ->
		type: 'MC'
		id: ''
		questions: [
			text: ''
		]
		answers: [
			$scope.newAnswer(),
			$scope.newAnswer()
		]
		untouched: true
		complete: false
		problems: []
		index: i

	$scope.toggleAnswer = (answer) ->
		answer.value = if answer.value is 100 then 0 else 100
		answer.options.custom = false

	$scope.newCategory = (index, category) ->
		setTimeout ->
			$('#category_'+index).focus()
		,10
		category.isEditing = true
		$scope.step = 2 if $scope.step is 1 # the first category has been clicked - display instructions for giving it a name

	$scope.updateCategory = ->
		$scope.step = 3 if $scope.step is 2 # the first category has been named - display instructions for adding the first question

	# set default values for the widget - 5 empty categories with 6 empty questions each
	$scope.buildScaffold = ->
		# create 6 empty categories
		i = 0
		while $scope.qset.items.length < 5
			$scope.qset.items.push
				items: []
				index: i++

		# create 6 empty questions per category
		for category in $scope.qset.items
			i = 0
			while category.items.length < 6
				category.items.push $scope.newQuestion()
			for question in category.items
				question.index = i++

		i = 0
		while i < $scope.qset.items.length
			if not $scope.qset.items[i].name
				found = false
				for question in $scope.qset.items[i].items
					if question.questions[0].text
						found = true

				if not found and $scope.qset.items[i+1] and $scope.qset.items[i+1].name
					$scope.qset.items.splice(i,1)
					i--
					break
			i++

	$scope.numbersOnly = (answer) ->
		if not answer.value.match(/^[0-9]?[0-9]?$/)
			answer.value = answer.value.replace(/[^0-9]+/, '')
		if ~~answer.value > 100
			answer.value = 100

	# Private helpers
	_initDragDrop = ->
		$('.importable').draggable
			start: (event, ui) ->
				$scope.shownImportTutorial = true
				$scope.curDragging = +this.getAttribute('data-index')
				this.style.position = 'absolute'
				this.style.zIndex = ++zIndex
				this.style.marginLeft = $(this).position().left + 'px'
				this.style.marginTop = $(this).position().top + 'px'
				this.className += ' dragging'
			stop: (event, ui) ->
				this.style.position = 'relative'
				this.style.marginTop =
				this.style.marginLeft =
				this.style.top =
				this.style.left = ''
				this.className = 'importable'
		$('.question').droppable
			drop: (event, ui) ->
				$(ui.draggable).removeClass('green').removeClass('red')

				category = +this.getAttribute('data-category')
				question = +this.getAttribute('data-question')
				questionobj = $scope.qset.items[category].items[question]

				if not $scope.questionShowAdd($scope.qset.items[category], questionobj, question)
					return

				if questionobj.questions[0].text == ''
					$scope.$apply ->
						$scope.qset.items[category].items[question] = $scope.imported[$scope.curDragging]
						$scope.imported.splice($scope.curDragging,1)
					_initDragDrop()

			over: (event, ui) ->
				category = +this.getAttribute('data-category')
				question = +this.getAttribute('data-question')

				questionobj = $scope.qset.items[category].items[question]

				if questionobj.questions[0].text != ''
					$(ui.draggable).addClass('red').removeClass('green')
				else
					return if not $scope.questionShowAdd($scope.qset.items[category], questionobj, question)
					$(ui.draggable).addClass('green').removeClass('red')

			out: (event, ui) ->
				$(ui.draggable).removeClass('green').removeClass('red')

	_buildSaveData = ->
		# duplicate the model and remove angular hash keys
		qset = angular.copy $scope.qset

		i = 0
		while i < qset.items.length
			# remove empty categories
			if not qset.items[i].name
				qset.items.splice(i,1)
				i--
				continue

			# remove empty questions
			j = 0
			while j < qset.items[i].items.length
				# remove creator-specific properties
				delete qset.items[i].items[j].untouched
				delete qset.items[i].items[j].complete
				delete qset.items[i].items[j].problems

				if not qset.items[i].items[j].questions[0].text
					qset.items[i].items.splice(j,1)
					j--
				j++
			i++

		qset

	Materia.CreatorCore.start $scope
]
