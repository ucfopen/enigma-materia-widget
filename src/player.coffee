Namespace('Enigma').Engine = do ->
	_qset                   = null
	_currentCat             = null
	_currentQuestion        = null
	_$currentQuestionSquare = null
	_currentQuestionIndex   = null
	_$board                 = null
	_categories             = {}
	_questions              = {}
	_scores                 = []
	_totalQuestions         = 0
	_answeredQuestions      = 0
	_currentScore           = 0
	_finalScore             = 0
	_$remainingQuestions    = null
	_checkMark              = '''<span class="correct mark" hidden>
									<svg height="20px" width="20px" xmlns="http://www.w3.org/2000/svg" version="1.1">
										<path stroke="#4187c9" stroke-width="4" d="M 2 12 L 8 18 M 5 18 L 18 5 Z" />
									</svg>
								</span>'''
	_partialMark            = '''<span class="partial mark" hidden></span>'''
	_xMark                  = '''<span class="wrong mark" hidden>
									<svg height="20px" width="20px" xmlns="http://www.w3.org/2000/svg" version="1.1">
										<path stroke="#AC3434" stroke-width="4" d="M 4 4 L 16 16 M 16 4 L 4 16 Z" />
									</svg>
								</span>'''

	# Pie data.
	_paper  = null
	_paper2 = null
	_data   = null
	_total  = null
	_paths  = null

	# Called by Materia.Engine when your widget Engine should start the user experience.
	start = (instance, qset, version = '1') ->
		_qset = qset
		_drawBoard(instance.name)
		_paper = new Raphael('scorebox', '100%', '100%')
		_cacheVariables()
		_drawPie(_paper)
		# once everything is drawn, set the height of the player
		Materia.Engine.setHeight()

	_cacheVariables = ->
		_$remainingQuestions = $('.header .score .value')

	# Shuffle any array.
	_shuffle = (a) ->
		for i in [1...a.length]
			j = Math.floor Math.random() * (a.length)
			[a[i], a[j]] = [a[j], a[i]]
		a

	# Draw the main board.
	_drawBoard = (title) ->

		tBoard = _.template $('#t-board').html()
		_$board = $(tBoard title: title, categories:_qset.items )
		# Make an array of each category, questions, and count the questions.
		for ci, category of _qset.items
			_categories[ci] = category
			for qi, question of category.items
				question.answers = _shuffle(question.answers) if _qset.options.randomize
				_totalQuestions++
				_questions[question.id] = question

		_$board.on 'click', _onBoardQuestionClick
		$('body').append _$board

	# Changes the data displayed in the score-pie.
	_updatePieData = ->
		# If the number of remaining questions has changed, update!
		if _totalQuestions-_answeredQuestions != Number(_$remainingQuestions.html())
			setTimeout ->
				_$remainingQuestions.addClass('numberExit')
			, 600

			# Remove old number.
			setTimeout ->
				_$remainingQuestions
					.removeClass('numberExit')
					.css('transform', 'rotateX(90deg)')
					.html(_totalQuestions-_answeredQuestions)
					.addClass('numberEnter')
			, 900

			# Add new number.
			setTimeout ->
				_$remainingQuestions
					.removeClass('numberEnter')
					.css('transform', 'rotateX(0deg)')
			, 1200

		# Eliminate weird offsets for high and low numbers.
		if _totalQuestions-_answeredQuestions > 9
			_$remainingQuestions.css 'right', '28px'
		else
			_$remainingQuestions.css 'right', '44px'

	# Updates the correct/incorrect pie slices.
	_animatePie = (ms) ->
		start = 270

		percAnswered = _answeredQuestions / _totalQuestions

		correctAngle   = (_currentScore * 3.6 - 0.0001) * percAnswered
		incorrectAngle = ((100 - _currentScore) * 3.6 - 0.0001) * percAnswered

		# correct pie slice values:
		_paths[0].animate 'segment': [60, 60, 60, start, start += correctAngle], ms or 1000, 'bounce'
		_paths[0].angle = start - correctAngle / 2

		# incorrect pie slice values:
		_paths[1].animate 'segment': [60, 60, 60, start, start += incorrectAngle], ms or 1000, 'bounce'
		_paths[1].angle = start - incorrectAngle / 2

	_drawPie = (_paper_num) ->
		# Initialize the remaining question counter.
		_$remainingQuestions.html(_totalQuestions-_answeredQuestions)

		# This wil be the outer grey circle.
		_paper_num.circle(60, 60, 60).attr 'fill': '#444', 'stroke-width': 0

		# We can gather the slice's attributes into a Raphael method.
		_paper_num.customAttributes.segment = (x, y, r, a1, a2) ->
			flag = (a2 - a1) > 180

			a1 = (a1 % 360) * Math.PI / 180
			a2 = (a2 % 360) * Math.PI / 180

			'path': [['M', x, y], ['l', r*Math.cos(a1), r*Math.sin(a1)], ['A', r, r, 0, +flag, 1, x+r*Math.cos(a2), y+r*Math.sin(a2)], ['z']]

		# Set the raphael object up for an array of slices.
		_paths = _paper_num.set()

		# Give the slices their attributes and starting values.
		_fills = ['rgb(42, 240, 177)', '#AC3434']
		for i in [0..1]
			_paths.push _paper_num.path().attr
				'segment': [60, 60, 1, 270, 270]
				'fill': _fills[i]
				'stroke-width': 0

		# This will be the inner grey circle.
		_paper_num.circle(60, 60, 50).attr 'fill': '#333', 'stroke-width': 0

		# Set the slices to be ready to animate.
		_animatePie(1)
		_updatePieData()

	# When a Question on the main board is clicked...
	_onBoardQuestionClick = (e) ->
		# Set the current state.
		_$currentQuestionSquare = $(e.target)

		if !_$currentQuestionSquare.hasClass('unanswered')
			return

		_currentCat = _categories[_$currentQuestionSquare.parent('.category').data('id')]
		_currentQuestion = _questions[_$currentQuestionSquare.data('id')]
		_currentQuestionIndex = parseInt _$currentQuestionSquare.html(), 10

		# Draw the Question Page.
		tQuestion = _.template $('#t-question-page').html()
		$question = $ tQuestion
			index: _currentQuestionIndex
			id: _currentQuestion.id
			answers: _currentQuestion.answers
			category: _currentCat.name
			question: _currentQuestion.questions[0].text

		qStyle = $question[0].children[0]

		# Set up the button listeners.
		$question.on 'click', '.return', ->
			_closeQuestion()
			setTimeout ->
				_animatePie()
			, 150
			_updatePieData()

		$question.on 'click', '.submit', _submitAnswer
		$question.find('.answers input').on 'click', (e) ->
			if not $(e.target).parent().parent('li').hasClass 'selected'
				$('.button-checked').fadeOut(100)
				$(this).parent().find('.button-checked').fadeIn(100)
			$('.answers li').removeClass 'selected'
			$(e.target).parent().parent('li').addClass 'selected'
			$question.find('.button.submit').prop 'disabled', false

		# Add the current question popup to the board.
		_$board.hide()
		$('body').append $question

		# Fade in the question popup.
		setTimeout ->
			qStyle.className = 'question-popup shown'
		, 5

	# Answer submitted by user.
	_submitAnswer = ->
		$chosenRadio = $(".answers input[type='radio']:checked")
		chosenAnswer = $chosenRadio.val()
		answer = _checkAnswer _currentQuestion, chosenAnswer

		Materia.Score.submitQuestionForScoring _currentQuestion.id, answer.text
		_scores.push answer.score
		_updateScore()

		# Update the question square.
		newTitle = "#{_currentCat.name} question  ##{_currentQuestionIndex} "

		# Add a check if the user is correct.
		if answer.score == 100
			$chosenRadio.parents('li').prepend _checkMark
			$('.correct').fadeIn()
			_$currentQuestionSquare
				.addClass('correct')
				.html('&#x2714;')
				.attr('title', "#{newTitle} Correct")

		else if answer.score == 0
			$chosenRadio.parents('li').prepend _xMark
			$('.wrong').fadeIn()
			_$currentQuestionSquare
			.addClass('wrong')
			.html('X')
			.attr('title', "#{newTitle} Wrong")

		else
			$chosenRadio.parents('li').prepend _partialMark
			$('.partial').html(answer.score + '%').fadeIn()
			_$currentQuestionSquare
				.addClass('correct')
				.addClass('partial')
				.html(answer.score + '%')
				.attr('title', "#{newTitle} Correct")

		# Update the radio list and buttons.
		$(".answers input[type='radio']").prop 'disabled', true
		$('.button.submit').prop 'disabled', true
		$('.button.return').addClass 'highlight'
		$('.answers ul').addClass('answered');
		$chosenRadio.parents('li').append("<span class=\"feedback\"><strong>Feedback:</strong> #{answer.feedback}</span>") if answer.feedback?.length > 0
		_$currentQuestionSquare.removeClass('unanswered')

	# Draw the final screen that transitions to the Score Screen
	_drawFinishScreen = ->
		# End, but don't show the score screen yet
		Materia.Engine.end no
		tFinish = _.template $('#t-finish-notice').html()
		$finish = $(tFinish score: _finalScore)
		$finish.find('button').on 'click', _end
		_$board.hide();
		$('body').append $finish

		# Adjust HTML depending on user results.
		scorebox = document.getElementById('scorebox_final')
		# The user has answered something correctly.
		if _finalScore != 0
			scorebox.children[1].innerHTML = _finalScore
			# The user has full credit.
			if _finalScore is 100
				scorebox.children[1].className = 'value all-correct'
				scorebox.children[2].className = 'percent all-correct'
			# The user has partial credit.
			else
				scorebox.children[3].innerHTML = (100 - _finalScore) + '% wrong'
		# The user has answered everything incorrectly.
		else
			scorebox.children[1].innerHTML = _finalScore
			scorebox.children[1].className = 'value all-wrong'
			scorebox.children[2].className = 'percent all-wrong'

		# Draw the final score-pie.
		_paper2 = new Raphael('scorebox_final', '100%', '100%')
		_drawPie(_paper2)

	# Update the score on the main screen
	_updateScore = ->
		_answeredQuestions++

		total = 0
		for i in [0.._scores.length - 1]
			total += _scores[i]

		_currentScore = Math.round total / _answeredQuestions
		_finalScore   = Math.round total / _totalQuestions

	# Check the value of the chosen answer
	_checkAnswer = (question, answerId) ->
		for answer in question.answers
			if String(answer.id) == String(answerId)
				return {
					score: parseInt(answer.value, 10)
					text: answer.text
					feedback: answer.options.feedback
				}

		throw Error 'Submitted answer not in this question'

	# Close a Question screen to return to the main board
	_closeQuestion = ->
		$('.screen.question').remove()
		_$board.show()
		_drawFinishScreen() if _scores.length == _totalQuestions

	_end = ->
		Materia.Engine.end yes

	#public
	manualResize: true
	start: start
