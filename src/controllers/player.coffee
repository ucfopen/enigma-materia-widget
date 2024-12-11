Enigma = angular.module 'enigmaPlayer', ['ngAria']

Enigma.controller 'enigmaPlayerCtrl', ['$scope', '$timeout', '$sce', ($scope, $timeout, $sce) ->
	$scope.title      = ''
	$scope.categories = []
	$scope.scores     = []

	$scope.totalQuestions    = 0
	$scope.answeredQuestions = []
	$scope.allAnswered       = false

	$scope.currentCategory = null
	$scope.currentQuestion = null
	$scope.currentAnswer   = null

	# these are used by the score graphics to draw percentages
	$scope.circumference = Math.PI * 100
	$scope.changingNumber = false

	$scope.percentCorrect = 0
	$scope.percentIncorrect = 0

	$scope.showTutorial = true

	$scope.instructionsOpen = false
	$scope.questionInstructionsOpen = false

	highlightedCategory = null
	highlightedQuestion = null

	# variable to check which screen the user is on (true = gameboard)
	$scope.checkTab = true
	# variable checks if on final submit for grading screen
	$scope.finalTab = false

	# force screen readers to immediately read the string value
	# keeping the scope variable for now so tests don't have to be completely rewritten
	$scope.ariaLive = ''
	forceRead = (readString) ->
		$scope.ariaLive = readString
		return unless readString
		document.getElementById('aria-live').innerHTML = readString

	# Called by Materia.Engine when your widget Engine should start the user experience.
	$scope.start = (instance, qset, version = '1') ->
		$scope.title = instance.name
		# Make an array of each category, questions, and count the questions.
		for ci, category of qset.items
			category.name = category.name.toUpperCase() if typeof(category.name) == 'string'
			category.index = ci
			$scope.categories[ci] = category
			for qi, question of category.items
				question.answers = _shuffle(question.answers) if qset.options.randomize
				question.index = qi
				$scope.totalQuestions++
				if question.options.asset
					switch question.options.asset.type
						when 'image' then question.options.asset.value = Materia.Engine.getMediaUrl(question.options.asset.id)
						when 'audio' then question.options.asset.value = Materia.Engine.getMediaUrl(question.options.asset.id)
						when 'video' then question.options.asset.value = $sce.trustAsResourceUrl(question.options.asset.id)


		$scope.$apply()

		# wait for content to render, then compute player height and pass it to the enginecore to update the height of the iframe
		$timeout ->
			h = _getPlayerHeight()
			Materia.Engine.setHeight(h)
			document.getElementById('tutorial-modal-dismiss').focus()

	_getPlayerHeight = () ->
		height = Math.ceil(parseFloat(window.getComputedStyle(document.querySelector('html')).getPropertyValue('height')))

	# randomize the order of a question's answers
	_shuffle = (a) ->
		for i in [1...a.length]
			j = Math.floor Math.random() * (a.length)
			[a[i], a[j]] = [a[j], a[i]]
		a

	# this used to focus on the text element containing the question
	# to help with accessibility this now focuses on the keyboard instructions element to help keyboard users
	focusOnQuestionText = (setTabIndex = true) ->
		# this changes the focus automatically to the active area, otherwise
		# focus remains on previous screen after question is selected
		setTimeout (-> document.getElementById('show-question-keyboard-instructions-button').focus()), 100
		if setTabIndex then $scope.setTabIndex()

	focusOnLightboxContent = ->
		setTimeout (->
			if $scope.currentQuestion.options.asset.type == 'video'
				document.getElementsByClassName('lightbox-video')[0].focus()
			if $scope.currentQuestion.options.asset.type == 'image'
				document.getElementsByClassName('lightbox-close')[0].focus()
		), 100

	$scope.dismissTutorial = ->
		$scope.showTutorial = false
		$timeout ->
			document.getElementById('show-keyboard-instructions-button').focus()

	$scope.handleWholePlayerKeyup = (e) ->
		switch e.code
			when 'KeyH'
				forceRead "Keyboard instructions: Questions are sorted into categories. " +
					"Use the Tab key to navigate through the game board to view and select questions. " +
					"Answer all questions to complete the widget. " +
					"Press the 'Q' key to automatically select the earliest unanswered question. " +
					"Press the 'S' key to hear your current score and how many unanswered questions are remaining. " +
					"Press the 'W' key to hear which question and category you currently have highlighted. " +
					"Press the 'H' key to hear these instructions again."
			when 'KeyQ' then $scope.selectEarliestUnanswered()
			when 'KeyS'
				if $scope.allAnswered
					forceRead 'All questions have been answered'
				else
					forceRead $scope.totalQuestions - $scope.answeredQuestions.length +
						' questions remaining, current score is ' +
						$scope.percentCorrect + ' out of 100 points.'
			when 'KeyW'
				unless highlightedCategory
					forceRead 'You have not highlighted a question yet, please use the Tab key to progress to the game board.'
					return
				forceRead 'Current location is question ' + (parseInt(highlightedQuestion.index, 10) + 1) + ' of ' +
					highlightedCategory.items.length + ' in category ' + (parseInt(highlightedCategory.index, 10) + 1) + ' of ' +
					$scope.categories.length + ': ' + highlightedCategory.name + '. Press Space or Enter to select this question.'



	$scope.highlightQuestion = (c, q) ->
		highlightedCategory = c
		highlightedQuestion = q

	$scope.selectEarliestUnanswered = () ->
		return if $scope.instructionsOpen or $scope.allAnswered or $scope.currentQuestion
		for c, ci in $scope.categories
			for q, qi in c.items
				if typeof q.score is 'undefined'
					$scope.selectQuestion c, q
					return

	$scope.selectQuestion = (category, question) ->
		throw Error 'A question is already selected!' if $scope.currentQuestion
		unless question.answered
			$scope.currentCategory = category
			$scope.currentQuestion = question

			focusOnQuestionText()

	# Lightbox in question pop up
	$scope.lightboxTarget = -1

	$scope.setLightboxTarget = (val) ->
		$scope.lightboxTarget = val
		if val < 0 then focusOnQuestionText(false)
		else focusOnLightboxContent()

	moveAnswer = (index) ->
		if index < 0
			index = $scope.currentQuestion.answers.length-1
		else if index >= $scope.currentQuestion.answers.length
			index = 0
		targetLi = document.getElementById('t-question-page')
			.getElementsByClassName('question-li')[index]
		targetLi.focus()

	$scope.handleAudioKeyUp = (event) ->
		event.stopPropagation()
		if event.code == 'Space' or event.code == 'Enter'
			event.preventDefault()
			if event.currentTarget.paused
				event.currentTarget.play()
			else
				event.currentTarget.pause()

	$scope.handleQuestionKeyUp = (event) ->
		switch event.code
			when 'Escape' then $scope.cancelQuestion()
			when 'KeyQ'
				forceRead 'Question: ' + $scope.currentQuestion.questions[0].text
			when 'KeyS'
				if $scope.currentAnswer
					document.getElementById('submit').focus()
				else forceRead 'You must select an answer first.'
			when 'KeyH'
				# have to do it verbose like this otherwise jest chokes on this file for some reason
				assetIndicator = ''
				if $scope.currentQuestion.options.asset
					assetIndicator = 'to the associated media, then '
				forceRead 'Use the Tab key to navigate ' + assetIndicator +
					'through answer options, then to reach the Return and Submit Final Answer buttons. ' +
					'The Up and Down arrow keys may also be used to navigate through answer options. ' +
					'Press the Enter or Space key on an answer option to select it. ' +
					'Pressing the Escape key will leave this question and allow you to select another question. ' +
					'Press the Q key to hear the question again. ' +
					'Press the S key after selecting an answer to be taken to the Submit Final Answer button automatically. ' +
					'Press the H key to hear these instructions again.'
			when 'ArrowUp' then moveAnswer($scope.currentQuestion.answers.length-1)
			when 'ArrowDown' then moveAnswer(0)
		event.stopPropagation()

	$scope.handleAnswerKeyUp = (event, index, answer) ->
		switch event.code
			when 'Enter', 'Space' then $scope.selectAnswer(answer)
			when 'ArrowUp' then moveAnswer(index - 1)
			when 'ArrowDown' then moveAnswer(index + 1)
			# allow these key events to bubble up to the question container, stop propagation for the rest
			when 'KeyQ','KeyS','KeyH','Escape' then return
		event.stopPropagation()

	# return focus to the top left corner of the gameboard, as if tabbing into it from the score indicator
	$scope.wraparound = (e) ->
		document.getElementsByClassName('question')[0].focus()

	$scope.selectAnswer = (answer) ->
		throw Error 'Select a question first!' unless $scope.currentQuestion
		$scope.currentAnswer = answer unless $scope.currentQuestion.answered
		forceRead 'Answer ' + $scope.currentAnswer.text + ' selected'

	$scope.cancelQuestion = ->
		_wasUpdated = $scope.currentQuestion.answered

		$scope.currentCategory = null
		$scope.currentQuestion = null
		$scope.currentAnswer   = null

		_updateScore() if _wasUpdated

		_gameOver() if $scope.scores.length == $scope.totalQuestions
		$scope.findQuestion()
		$scope.setTabIndex()
		# resets status div that gives answer feedback so it can't be tabbed to
		forceRead ""

	# function to find the first unanswered question in list and shift focus to it
	$scope.findQuestion = ->
		for item in document.getElementsByClassName('question')
			if item.title.includes('Unanswered')
				setTimeout (-> item.focus()), 100
				break

	$scope.submitAnswer = ->
		throw Error 'Question already answered!' if $scope.currentQuestion.answered
		check = _checkAnswer()
		if check.score != undefined
			$scope.currentQuestion.answered = true

			# the following provides feedback upon submitting an answer

			Materia.Score.submitQuestionForScoring $scope.currentQuestion.id, check.text
			$scope.scores.push check.score

			$scope.currentQuestion.score = check.score
			$scope.answeredQuestions.push $scope.currentQuestion

			if $scope.answeredQuestions.length == $scope.totalQuestions
				returnMessage = " Press the Space or Enter key to continue to the submit screen."
			else
				returnMessage = " Press the Space or Enter key to return to the game board."

			document.getElementById('return').focus()

			if check.score == 100
				forceRead check.text + " is correct!" + returnMessage
			else if check.score > 0 && check.score < 100
				forceRead check.text + " is only partially correct. " + check.correct + " is the correct answer." + returnMessage
			else
				forceRead check.text + " is incorrect. The correct answer was " + check.correct + "." + returnMessage
		else
			throw Error 'Submitted answer not in this question!'

	# changes checkTab to false when on question screen and true when on gameboard so
	# that you can't tab through the hidden screen
	$scope.setTabIndex = ->
		$scope.checkTab = !$scope.checkTab

	# displays a keyboard instructions dialog and sets inert on everything else to
	# control tab targets
	$scope.toggleInstructions = ->
		$scope.instructionsOpen = !$scope.instructionsOpen
		# wait for inert status to be removed/added properly before moving focus
		setTimeout (->
			if $scope.instructionsOpen
				document.getElementById('hide-keyboard-instructions-button').focus()
			else
				document.getElementById('show-keyboard-instructions-button').focus()
		), 100

	$scope.toggleQuestionInstructions = ->
		$scope.questionInstructionsOpen = !$scope.questionInstructionsOpen
		# wait for inert status to be removed/added properly before moving focus
		setTimeout (->
			if $scope.questionInstructionsOpen
				document.getElementById('hide-question-keyboard-instructions-button').focus()
			else
				document.getElementById('show-question-keyboard-instructions-button').focus()
		), 100

	_updateScore = ->
		total = 0
		for i in [0...$scope.scores.length]
			total += $scope.scores[i]

		$scope.percentCorrect = Math.round total / $scope.totalQuestions

		answeredPercent = $scope.scores.length / $scope.totalQuestions * 100
		$scope.percentIncorrect = answeredPercent - $scope.percentCorrect

		$scope.changingNumber = true
		$timeout ->
			$scope.changingNumber = false
		, 300

	_checkAnswer = ->
		selected = {
			score: undefined
		}
		for answer in $scope.currentQuestion.answers

			if answer.value == 100
				selected.correct = answer.text

			if answer is $scope.currentAnswer
					selected.score = parseInt answer.value, 10
					selected.text = answer.text
					selected.feedback = answer.options.feedback

		return selected

	_gameOver = ->
		$scope.allAnswered = true
		setTimeout (-> document.getElementById('end-button').focus()), 100
		$scope.finalTab = true

		# End, but don't show the score screen yet
		Materia.Engine.end no

	$scope.end = ->
		Materia.Engine.end yes

	Materia.Engine.start $scope
]
