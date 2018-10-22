Enigma = angular.module 'enigmaPlayer'

Enigma.controller 'enigmaPlayerCtrl', ['$scope', '$timeout', ($scope, $timeout) ->
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

	# Called by Materia.Engine when your widget Engine should start the user experience.
	$scope.start = (instance, qset, version = '1') ->
		$scope.title = instance.name

		# Make an array of each category, questions, and count the questions.
		for ci, category of qset.items
			category.name = category.name.toUpperCase() if typeof(category.name) == 'string'
			$scope.categories[ci] = category
			for qi, question of category.items
				question.answers = _shuffle(question.answers) if qset.options.randomize
				$scope.totalQuestions++

		$scope.$apply()

		Materia.Engine.setHeight()

	# randomize the order of a question's answers
	_shuffle = (a) ->
		for i in [1...a.length]
			j = Math.floor Math.random() * (a.length)
			[a[i], a[j]] = [a[j], a[i]]
		a

	$scope.selectQuestion = (category, question) ->
		throw Error 'A question is already selected!' if $scope.currentQuestion
		unless question.answered
			$scope.currentCategory = category
			$scope.currentQuestion = question

	$scope.selectAnswer = (answer) ->
		throw Error 'Select a question first!' unless $scope.currentQuestion
		$scope.currentAnswer = answer unless $scope.currentQuestion.answered

	$scope.cancelQuestion = ->
		_wasUpdated = $scope.currentQuestion.answered

		$scope.currentCategory = null
		$scope.currentQuestion = null
		$scope.currentAnswer   = null

		_updateScore() if _wasUpdated

		_gameOver() if $scope.scores.length == $scope.totalQuestions

	$scope.submitAnswer = ->
		throw Error 'Question already answered!' if $scope.currentQuestion.answered
		check = _checkAnswer()
		if check
			$scope.currentQuestion.answered = true

			Materia.Score.submitQuestionForScoring $scope.currentQuestion.id, check.text
			$scope.scores.push check.score

			$scope.currentQuestion.score = check.score
			$scope.answeredQuestions.push $scope.currentQuestion
		else
			throw Error 'Submitted answer not in this question!'

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
		for answer in $scope.currentQuestion.answers
			if answer is $scope.currentAnswer
				return {
					score: parseInt answer.value, 10
					text: answer.text
					feedback: answer.options.feedback
				}
		false

	_gameOver = ->
		$scope.allAnswered = true

		# End, but don't show the score screen yet
		Materia.Engine.end no

	$scope.end = ->
		Materia.Engine.end yes

	Materia.Engine.start $scope
]