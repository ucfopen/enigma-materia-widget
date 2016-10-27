Enigma = angular.module 'enigmaCreator'

Enigma.controller 'enigmaCreatorCtrl', ['$scope', '$timeout', ($scope, $timeout) ->
	# private constants to refer to any problems a question might have
	_QUESTION_PROBLEM     = 'Question undefined.'
	_CREDIT_PROBLEM       = 'Inadequate credit.'
	_REPEAT_PROBLEM       = 'Duplicate answers.'
	_BLANK_ANSWER_PROBLEM = 'Blank answer(s).'
	_NO_ANSWER_PROBLEM    = 'No answers.'

	$scope.title = ''
	$scope.qset = {}

	# keep track of the question we're currently dealing with and what category it's in
	$scope.curCategory = false
	$scope.curQuestion = false

	# toggle for question editor sub-menu
	$scope.subMenu = false

	# keep track of any complete questions that the mouse is hovering over
	$scope.hoverCategory = false
	$scope.hoverQuestion = false

	# keep track of which initial instructions need to be displayed
	$scope.step = 0

	# controls whether the first-time tutorial appears - set true when making a new widget
	$scope.showIntroDialog = false

	# used to store and cancel any on-screen alerts as necessary
	alertTimer = null

	# when a question is done editing, use this to display a message if it is not complete
	$scope.incompleteMessage = false

	# used with incompleteMessage when a widget is technically valid but potentially still incomplete
	$scope.warningMessage = false

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

	$scope.setTitle = ->
		$scope.title = $scope.introTitle or $scope.title
		$scope.hideCover()

	# responds to a number of stimuli to hide the intro screen
	$scope.hideCover = ->
		$scope.step = 1 if $scope.step is 0 # the widget has a title - bring up the instructions for adding the first category
		$scope.showIntroDialog = $scope.showTitleDialog = false

	$scope.initExistingWidget = (title, widget, qset, version, baseUrl) ->
		if qset.data
			qset = qset.data

		# loop through each question in each category and validate all incoming questions
		i = 0
		while i < qset.items.length
			j = 0
			while j < qset.items[i].items.length
				qset.items[i].items[j] = _checkQuestion qset.items[i].items[j]
				j++
			i++

		$scope.step = 4 if i > 0 # if this widget had some questions, assume the instructions are unnecessary

		$scope.$apply ->
			$scope.title = title
			$scope.qset = qset
			$scope.buildScaffold()

	# prepare some checks to make sure the given question is 'complete':
	_checkQuestion = (question) ->
		# has question text
		hasQuestion = question.questions[0].text != ''
		# has at least one answer worth 100%
		fullCredit = false
		# doesn't have any repeat answers
		repeatChecks = []
		hasRepeats = false
		# or blank answers
		blankAnswer = false
		# and has answers at all
		noAnswers = question.answers.length == 0

		# store whatever problems remain in the question for later
		problems = []

		for answer in question.answers
			# make sure we interpret the given answer as a string, then remove extraneous whitespace
			answer.text += ''
			trimmedAnswer = answer.text.trim()
			if trimmedAnswer == '' then blankAnswer = true
			# keep track of each possible answer
			if not repeatChecks[trimmedAnswer]
				repeatChecks[trimmedAnswer] = true # store this word so we can look for it later
			else
				hasRepeats = true

			if answer.options.correct
				answer.value = 100
			else
				answer.value = parseInt(answer.value,10)

			# make sure options are set correctly based on value
			if answer.value is 100 or answer.value is 0
				answer.options.custom = false
				answer.options.correct = answer.value is 100
			else
				answer.options.custom = true
				answer.options.correct = false

			fullCredit = true if answer.value is 100

		# this question is complete if it has question text, one answer worth 100%, and no repeated answers
		isComplete = hasQuestion and not noAnswers and fullCredit and not hasRepeats and not blankAnswer

		# if the question is 'incomplete', keep track of any reasons why
		if not isComplete
			if not hasQuestion
				problems.push _QUESTION_PROBLEM
			if not fullCredit
				problems.push _CREDIT_PROBLEM
			if hasRepeats
				problems.push _REPEAT_PROBLEM
			if blankAnswer
				problems.push _BLANK_ANSWER_PROBLEM
			if noAnswers
				problems.push _NO_ANSWER_PROBLEM

		# store any problems for this question and flag it as edited
		question.complete = isComplete
		question.problems = problems
		question.untouched = false

		question

	_showProblems = (question) ->
		# compile any problems in an array for Angular to display
		incompleteMessage = []

		# if the question is 'incomplete', alert reasons why
		if not question.complete
			incompleteMessage = question.problems
			incompleteMessage.unshift "Warning: this question is incomplete!"
		else
			# make additional checks here for any potential warnings

			# if there's only one answer for this question
			if question.answers.length < 2
				incompleteMessage.push 'Only one answer found.'

			# specify that these are warnings, not show-stoppers
			if incompleteMessage.length > 0
				$scope.warningMessage = true
				incompleteMessage.unshift 'Attention: this question may be incomplete!'


		# bring up a temporary alert describing any problems
		if incompleteMessage.length > 0
			$scope.incompleteMessage = incompleteMessage
			$scope.startFade = true

			alertTimer = $timeout ->
				$scope.incompleteMessage = false
				$scope.warningMessage    = false
			, 10000

	$scope.onQuestionImportComplete = (questions) ->
		$scope.$apply -> $scope.imported = questions.concat $scope.imported

	# REPLACE THIS SHIT
	# https://github.com/marceljuenemann/angular-drag-and-drop-lists
	$scope.importDropped = (category, item) ->
		#find the last empty question in this category
		lastIndex = category.items.length-1
		for q in category.items
			if q.untouched
				item.index = q.index
				category.items[q.index] = _checkQuestion item
				_showProblems item
				return true
		# if there aren't any empty questions in this category, don't take this question
		false

	# get the total number of questions in the widget so Angular can put it on the page
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
		not category.name and not category.isEditing and (index == 0 or not $scope.qset.items[index-1].untouched)

	$scope.categoryEnabled = (category, index) ->
		index == 0 or $scope.qset.items[index-1].name or $scope.qset.items[index].name

	# editing a category
	$scope.editCategory = (category) ->
		category.isEditing = true
		$scope.curQuestion = false

	# done editing a category
	$scope.stopCategory = (category) ->
		# don't do anything unless the category was named properly
		if category.name
			if $scope.qset.items[$scope.qset.items.length-1].name
				$scope.qset.items.push
					items: []
					index: $scope.qset.items.length
				$scope.buildScaffold()

			category.isEditing = false
			category.untouched = false
			$scope.step = 3 if $scope.step is 2 # the first category has been named - display instructions for adding the first question
		else
		category.isEditing = false

	$scope.deleteCategory = (category) ->
		if confirm "Deleting this category will also delete all of the questions it contains!\n\nAre you sure?"
			$scope.qset.items.splice(category.index, 1)
			$scope.buildScaffold()

			#reset all of the remaining categories' index properties or Angular will get confused
			i = 0
			while i < $scope.qset.items.length
				$scope.qset.items[i].index = i++

	$scope.categoryReorder = (index, forward) ->
		temp = $scope.qset.items[index]
		if forward
			$scope.qset.items[index] = $scope.qset.items[index+1]
			$scope.qset.items[index].index = index
			$scope.qset.items[index+1] = temp
			$scope.qset.items[index+1].index = index+1
		else
			$scope.qset.items[index] = $scope.qset.items[index-1]
			$scope.qset.items[index].index = index
			$scope.qset.items[index-1] = temp
			$scope.qset.items[index-1].index = index-1

	# show the question add button for the given question index in the given category if:
	# the category has been named and is not being edited
	# and the question hasn't been edited from defaults
	# or if this is the first question in the category
	# or if it's not the first, and the previous question has been edited from defaults
	$scope.questionShowAdd = (category, question, index) ->
		category.name? and not category.isEditing and question.untouched and (index == 0 or !category.items[index-1].untouched)

	$scope.editQuestion = (category, question, index) ->
		# reset anything that may still be around from a prior completion alert
		$scope.incompleteMessage = false
		$scope.warningMessage    = false
		$timeout.cancel alertTimer

		# make sure we can edit this question
		# the category has been named, this is the first question in the category, this or the previous question has been edited already
		if category.name and not category.isEditing and index == 0 or !category.items[index].untouched or !category.items[index-1].untouched
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
		# run the current question through validation
		_checkQuestion $scope.curQuestion

		_showProblems $scope.curQuestion

		$scope.subMenu = false
		$scope.curQuestion = false

	# hide the alert early if the user clicks on it
	$scope.killAlert = ->
		$scope.incompleteMessage = false

	# draw a tooltip near a question when the mouse is over it if that question is invalid
	$scope.markQuestion = (category, question) ->
		return unless not question.untouched
		$scope.hoverQuestion = question
		$scope.hoverCategory = category

	# remove the tooltip indicating problems with a question
	$scope.unmarkQuestion = ->
		$scope.hoverQuestion = false
		$scope.hoverCategory = false

	# delete a question; removes question from the order completely
	$scope.deleteQuestion = (i) ->
		# get rid of this question and put a blank one on the end of the category's stack
		$scope.qset.items[$scope.curCategory.index].items.splice($scope.curQuestion.index, 1)
		$scope.qset.items[$scope.curCategory.index].items.push _newQuestion()

		# reset all of the questions' index properties to match the change
		while i < $scope.qset.items[$scope.curCategory.index].items.length
			$scope.qset.items[$scope.curCategory.index].items[i].index = i++
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

	# change the order of questions within a category
	$scope.questionReorder = (forward) ->
		currentIndex = $scope.curQuestion.index
		temp = $scope.curCategory.items[currentIndex]
		if forward
			$scope.curCategory.items[currentIndex] = $scope.curCategory.items[currentIndex+1]
			$scope.curCategory.items[currentIndex].index = currentIndex
			$scope.curCategory.items[currentIndex+1] = temp
			$scope.curCategory.items[currentIndex+1].index = currentIndex+1
		else
			$scope.curCategory.items[currentIndex] = $scope.curCategory.items[currentIndex-1]
			$scope.curCategory.items[currentIndex].index = currentIndex
			$scope.curCategory.items[currentIndex-1] = temp
			$scope.curCategory.items[currentIndex-1].index = currentIndex-1

	_newQuestion = (i=0) ->
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

	$scope.newCategory = (index, category) ->
		category.isEditing = true
		$scope.step = 2 if $scope.step is 1 # the first category has been clicked - display instructions for giving it a name

	# set default values for the widget - 5 empty categories with 6 empty questions each
	$scope.buildScaffold = ->
		# create 6 empty categories
		i = 0
		while $scope.qset.items.length < 5
			$scope.qset.items.push
				items: []
				untouched: true
				index: i++

		# create 6 empty questions per category
		for category in $scope.qset.items
			i = 0
			while category.items.length < 6
				category.items.push _newQuestion()
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

	# called when an answer's custom value is changed - makes sure no non-numbers are present
	$scope.numbersOnly = (answer) ->
		# if the answer's value isn't only numbers, strip out any non-numbers
		if not answer.value.match(/^[0-9]?[0-9]?$/)
			answer.value = answer.value.replace(/[^0-9]+/, '')
		# if the rounded-down value of the answer is over 100, constrain it to 100
		if ~~answer.value > 100
			answer.value = 100

	$scope.onSaveClicked = (mode = 'save') ->
		qset = _buildSaveData()
		msg = validateQuestions qset
		if msg
			Materia.CreatorCore.cancelSave msg
		else
			Materia.CreatorCore.save $scope.title, qset

	_buildSaveData = ->
		# duplicate the model and remove angular hash keys
		qset = angular.copy $scope.qset

		i = 0
		# for each category
		while i < qset.items.length
			# remove empty categories; no name, no questions, or never touched
			if qset.items[i] and qset.items[i].untouched or qset.items[i]?.items.length == 0 and not qset.items[i].name
				qset.items.splice(i,1)
				i--
				continue

			# for each question
			j = 0
			while j < qset.items[i]?.items.length
				untouched = qset.items[i].items[j].untouched
				# remove creator-specific properties; save problems for validation phase
				delete qset.items[i].items[j].untouched
				delete qset.items[i].items[j].complete

				# remove empty questions; no name, no answers, or never touched
				if untouched or qset.items[i].items[j].answers.length == 0 and not qset.items[i].items[j].questions[0].text
					qset.items[i].items.splice(j,1)
					j--
				j++
			i++
		qset

	validateQuestions = (qset) ->
		compiledMessage = ''

		# simplest check - are there any categories?
		return 'No categories found.' unless qset.items.length

		i = 0
		while i < qset.items.length
			j = 0
			category = qset.items[i]
			while j < category.items.length
				question = category.items[j]
				if question.problems.length > 0
					for problem in question.problems
						compiledMessage += "\nQuestion "+(j+1)+" in category "+category.name+": "+problem
				delete qset.items[i].items[j].problems
				j++
			i++
		if compiledMessage then return compiledMessage
		return false

	$scope.onSaveComplete = (title, widget, qset, version) -> true

	Materia.CreatorCore.start $scope
]
