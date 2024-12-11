Enigma = angular.module 'enigmaCreator'

Enigma.controller 'enigmaCreatorCtrl', ['$scope', '$timeout', '$sce', ($scope, $timeout, $sce) ->
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
	# shortcut to keep track of the title entered into the intro dialog
	$scope.introTitle

	# used to bring up an 'edit title' dialog
	$scope.showTitleDialog = false

	# used to store and cancel any on-screen alerts as necessary
	_alertTimer = null

	_categoryTempName = ''

	# when a question is done editing, use this to display a message if it is not complete
	$scope.incompleteMessage = false

	# used with incompleteMessage when a widget is technically valid but potentially still incomplete
	$scope.warningMessage = false

	$scope.imported = []

	# EngineCore Public Interface
	$scope.initNewWidget = (widget, baseUrl) ->
		$scope.$apply ->
			$scope.title = 'My Enigma widget'
			$scope.qset =
				items: []
				options:
					randomize: true
			_buildScaffold()
			$scope.showIntroDialog = true

	$scope.initExistingWidget = (title, widget, qset, version, baseUrl) ->
		if qset.data
			qset = qset.data

		# loop through each question in each category and validate all incoming questions
		i = 0
		while i < qset.items.length
			# also sanitize category names if necessary
			qset.items[i].name = ' ' unless qset.items[i].name

			# also make sure every category has an index
			qset.items[i].index = i unless qset.items[i].index

			j = 0
			while j < qset.items[i].items.length
				qset.items[i].items[j] = _checkQuestion qset.items[i].items[j]
				j++
			i++


		$scope.step = 4 if i > 0 # if this widget had some questions, assume the instructions are unnecessary

		$scope.$apply ->
			$scope.title = title
			$scope.qset = qset
			_buildScaffold()

	# set default values for the widget - 5 empty categories with 6 empty questions each
	_buildScaffold = ->
		# create 5 empty categories
		# start category indices at 0
		i = 0
		# unless there are already categories, in which case start after the highest
		if $scope.qset.items.length > 0
			i = $scope.qset.items[$scope.qset.items.length-1].index + 1

		while $scope.qset.items.length < 5
			$scope.qset.items.push
				name: ''
				items: []
				untouched: true
				index: i++

		# make sure there's at least one empty category at the end
		unless $scope.qset.items[$scope.qset.items.length - 1].untouched
			$scope.qset.items.push
				name: ''
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

		# go through each category
		i = 0
		while i < $scope.qset.items.length
			# if any categories don't have a name
			if not $scope.qset.items[i].name
				# make sure none of the category's questions have any text
				found = false
				for question in $scope.qset.items[i].items
					if question.questions[0].text
						found = true

				if not found and $scope.qset.items[i+1] and $scope.qset.items[i+1].name
					$scope.qset.items.splice(i,1)
					i--
					break
			i++

	$scope.importDropped = (category, item) ->
		#find the last empty question in this category
		for q in category.items
			if q.untouched
				item.index = q.index
				category.items[q.index] = _checkQuestion item
				_showProblems item
				return true
		# if there aren't any empty questions in this category, don't take this question
		false

	# called by the creator core after a list of questions has been selected for import
	$scope.onQuestionImportComplete = (questions) ->
		$scope.$apply -> $scope.imported = questions.concat $scope.imported

	# get the total number of questions in the widget so Angular can put it on the page
	$scope.numQuestions = ->
		if !$scope.qset.items?
			return 0
		i = 0
		for category in $scope.qset.items
			for question in category.items
				i++	if question.complete
		i

	$scope.categoryOpacity = (category, index) ->
		opacity = 0.1
		if $scope.step is 1 and index is 0
			opacity = 1
		if category.name or category.isEditing
			opacity = 1
		return opacity

	$scope.categoryShowAdd = (category, index) ->
		not category.name and not
		category.isEditing and
		(index == 0 or not $scope.qset.items[index-1].untouched)

	$scope.categoryEnabled = (category, index) ->
		index == 0 or category.name != '' or $scope.qset.items[index-1].name != ''

	$scope.setTitle = ->
		$scope.title = $scope.introTitle or $scope.title
		$scope.hideCover()

	# responds to a number of stimuli to hide the intro screen
	$scope.hideCover = ->
		$scope.step = 1 if $scope.step is 0 # the widget has a title - bring up the instructions for adding the first category
		$scope.showIntroDialog = $scope.showTitleDialog = false

	$scope.newCategory = (index, category) ->
		category.isEditing = true
		$scope.step = 2 if $scope.step is 1 # the first category has been clicked - display instructions for giving it a name

	# editing a category
	$scope.editCategory = (category) ->
		category.isEditing = true
		_categoryTempName = category.name
		$scope.curQuestion = false

	# done editing a category
	$scope.stopCategory = (category) ->
		# don't do anything unless the category was named properly
		if category.name
			if $scope.qset.items[$scope.qset.items.length-1].name
				$scope.qset.items.push
					name: ''
					items: []
					untouched: true
					index: $scope.qset.items.length
				_buildScaffold()

			category.isEditing = false
			category.untouched = false
			$scope.step = 3 if $scope.step is 2 # the first category has been named - display instructions for adding the first question
		else
			if _hasQuestions category
				category.name = _categoryTempName unless $scope.deleteCategory category
			else
				# delete it if it was named before, otherwise this is because we canceled naming a new category
				_deleteCategory category unless category.untouched
		category.isEditing = false
		_categoryTempName = ''

	$scope.deleteCategory = (category) ->
		if _hasQuestions category
			if window.confirm "Deleting this category will also delete all of the questions it contains!\n\nAre you sure?"
				_deleteCategory category
			else
				return false
		else
			_deleteCategory category
		true

	_hasQuestions = (category) ->
		for question in category.items
			return true unless question.untouched
		false

	_deleteCategory = (category) ->
		$scope.qset.items.splice(category.index, 1)
		if $scope.qset.items[$scope.qset.items.length-1].name
			$scope.qset.items.push
				items: []
				untouched: true
				index: $scope.qset.items.length
		_buildScaffold()

		wasOnly = true

		#reset all of the remaining categories' index properties or Angular will get confused
		i = 0
		while i < $scope.qset.items.length
			wasOnly = false if $scope.qset.items[i].untouched is false
			$scope.qset.items[i].index = i++

		# if they're still in tutorial mode and they haven't added a question yet, step back
		$scope.step = 1 if wasOnly and $scope.step is 3

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
		category.name? and not
		category.untouched and not
		category.isEditing and
		question.untouched and
		(index == 0 or !category.items[index-1].untouched)

	$scope.editQuestion = (category, question, index) ->
		# reset anything that may still be around from a prior completion alert
		$scope.incompleteMessage = false
		$scope.warningMessage    = false
		$timeout.cancel _alertTimer

		# make sure we can edit this question
		# the category has been named, this is the first question in the category, this or the previous question has been edited already
		if category.name and not category.isEditing and index == 0 or !category.items[index].untouched or (index > 0 and !category.items[index-1].untouched)
			$scope.curQuestion = question
			$scope.curCategory = category

			for answer in question.answers
				answer.options.correct = false
				answer.options.custom = false

				# set the 'correct' or 'custom' flags for answers if necessary
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
		$scope.curCategory = false
		$scope.curQuestion = false

	# delete a question; removes question from the order completely
	$scope.deleteQuestion = ->
		# get this question's index so we can reset the index of each following question
		i = $scope.curQuestion.index

		# get rid of this question and put a blank one on the end of the category's stack
		$scope.qset.items[$scope.curCategory.index].items.splice($scope.curQuestion.index, 1)
		$scope.qset.items[$scope.curCategory.index].items.push _newQuestion()

		# reset all of the questions' index properties to match the change
		while i < $scope.qset.items[$scope.curCategory.index].items.length
			$scope.qset.items[$scope.curCategory.index].items[i].index = i++
		$scope.curQuestion = false

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

	_newQuestion = ->
		type: 'MC'
		id: ''
		questions: [
			text: ''
		]
		answers: [
			_newAnswer(),
			_newAnswer()
		]
		untouched: true
		complete: false
		problems: []
		index: 0
		options: {}

	$scope.addAnswer = ->
		$scope.curQuestion.answers.push _newAnswer()

	$scope.deleteAnswer = (index) ->
		$scope.curQuestion.answers.splice(index,1)

	_newAnswer = ->
		id: ''
		text: ''
		value: 0
		options:
			feedback: ''
			custom: false
			correct: false

	$scope.toggleCorrect = (answer) ->
		if answer.options.correct then answer.value = 100 else answer.value =  0

	# called when an answer's custom value is changed - makes sure no non-numbers are present
	$scope.numbersOnly = (answer) ->
		# strip out any non-numbers and cast it to a number
		answer.value = Number answer.value.replace(/[^\d-]/g, '')
		# constrain it between 0 and 100
		answer.value = 100 if ~~answer.value > 100
		answer.value = 0 if ~~answer.value < 0
		answer.options.correct = answer.value is 100

	# Assets

	$scope.showPopUp = () ->
		$scope.mediaPopUp = true
		$scope.hideVideoForm()

	$scope.hidePopUp = () ->
		$scope.mediaPopUp = false
		$scope.hideVideoForm()

	$scope.uploadAudio = () ->
		$scope.curQuestion.mediaType = "audio"
		$scope.hideVideoForm()
		Materia.CreatorCore.showMediaImporter(["audio"])

	$scope.uploadImage = () ->
		$scope.curQuestion.mediaType = "image"
		$scope.hideVideoForm()
		Materia.CreatorCore.showMediaImporter(["image"])

	$scope.showVideoForm = () ->
		$scope.videoForm = true

	$scope.hideVideoForm = () ->
		$scope.videoForm = false
		$scope.urlError = null

	$scope.onMediaImportComplete = (media) ->
		$scope.removeMedia()
		$scope.curQuestion.options.asset =
			type: $scope.curQuestion.mediaType
			value: Materia.CreatorCore.getMediaUrl media[0].id
			id: media[0].id
			description: $scope.curQuestion.description
		$scope.hidePopUp()
		$scope.$apply()

	$scope.removeMedia = () ->
		$scope.url = null
		delete $scope.curQuestion.options.asset

	$scope.formatUrl = () ->
		try
			embedUrl = ''
			if $scope.inputUrl.includes('youtu')
				stringMatch = $scope.inputUrl.match(/^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?$/);
				embedUrl = 'https://www.youtube.com/embed/' + stringMatch[5] || ($scope.inputUrl if $scope.inputUrl.includes('/embed/'))
			else if $scope.inputUrl.includes('vimeo')
				embedUrl = 'https://player.vimeo.com/video/' + $scope.inputUrl.match(/(?:vimeo)\.com.*(?:videos|video|channels|)\/([\d]+)/i)[1] || $scope.inputUrl;
			else
				$scope.urlError = 'Please enter a YouTube or Vimeo URL.'
				return
		catch e
			$scope.urlError = 'Please enter a YouTube or Vimeo URL.'
			return

		$scope.hidePopUp()

		$scope.curQuestion.options.asset =
			type: "video"
			value: $sce.trustAsResourceUrl(embedUrl)
			id: embedUrl
			description: ''

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

		# old qsets set question.options as an array; it needs to be an object. Convert it if necessary.
		if Array.isArray(question.options) and question.options.length is 0 then question.options = {}

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

			_alertTimer = $timeout ->
				$scope.killAlert();
			, 10000

	# hide the alert early if the user clicks on it
	$scope.killAlert = ->
		$scope.incompleteMessage = false
		$scope.warningMessage    = false

	# draw a tooltip near a question when the mouse is over it if that question is invalid
	$scope.markQuestion = (category, question) ->
		return if question.untouched
		$scope.hoverQuestion = question
		$scope.hoverCategory = category

	# remove the tooltip indicating problems with a question
	$scope.unmarkQuestion = ->
		$scope.hoverQuestion = false
		$scope.hoverCategory = false

	$scope.onSaveClicked = (mode = 'save') ->
		qset = _buildSaveData()
		msg = if mode is 'history' then false else _validateQuestions qset
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
			catUntouched = qset.items[i].untouched
			# remove creator-specific properties; save problems for validation phase
			delete qset.items[i].untouched
			delete qset.items[i].isEditing

			# remove empty categories; no name, no questions, or never touched
			if qset.items[i] and catUntouched or qset.items[i]?.items.length == 0 and not qset.items[i].name
				qset.items.splice(i,1)
				i--
				continue

			# for each question
			j = 0
			while j < qset.items[i]?.items.length
				questionUntouched = qset.items[i].items[j].untouched
				# remove creator-specific properties; save problems for validation phase
				delete qset.items[i].items[j].untouched
				delete qset.items[i].items[j].complete

				# remove empty questions; no name, no answers, or never touched
				if questionUntouched or qset.items[i].items[j].answers.length == 0 and not qset.items[i].items[j].questions[0].text
					qset.items[i].items.splice(j,1)
					j--
				j++
			i++
		qset

	_validateQuestions = (qset) ->
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
