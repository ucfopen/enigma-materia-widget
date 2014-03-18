###

Materia
It's a thing

Widget	: Enigma, Creator
Authors	: Jonathan Warner
Updated	: 3/14

###

EnigmaCreator = angular.module('enigmaCreator', [])

EnigmaCreator.controller 'enigmaCreatorCtrl', ['$scope', ($scope) ->
	$scope.title = ''
	$scope.qset = {}

	$scope.curQuestion = false
	$scope.curCategory = false

	$scope.numQuestions = ->
		if !$scope.qset.items?
			return 0
		i = 0
		for category in $scope.qset.items
			for question in category.items
				i++	if question.used
		i
]

Namespace('Enigma').Creator = do ->
	_scope = {}

	# reference for question answer lists
	_letters = ['A','B','C','D','E','F','G','H','I','J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']

	_initScope = ->
		_scope = angular.element($('body')).scope()
		_scope.$apply ->
			_scope.editCategory = (category) ->
				category.isEditing = true
				_scope.curQuestion = false

			_scope.stopCategory = (category) ->
				category.isEditing = false

			_scope.changeTitle = ->
				$('#backgroundcover, .title').addClass 'show'
				$('.title input[type=text]').focus()
				$('.title input[type=button]').click ->
					$('#backgroundcover, .title').removeClass 'show'

			_scope.editQuestion = (category,question,$index) ->
				if category.name and $index == 0 or category.items[$index-1].questions[0].text != ''
					_scope.curQuestion = question
					_scope.curCategory = category
					question.used = true
					setTimeout ->
						$('#question_text').focus()
					,0

					_scope.step = 4 if _scope.step is 3

			_scope.editComplete = ->
				for answer in _scope.curQuestion.answers
					answer.value = parseInt(answer.value,10)

					if answer.options.custom
						if answer.value == 100 or answer.value == 0
							answer.options.custom = false
							answer.options.correct = if answer.value == 100 then true else false
					else
						answer.value = if answer.options.correct then 100 else 0
				_scope.curQuestion = false
				
			_scope.deleteQuestion = (i) ->
				_scope.qset.items[_scope.curCategory.index].items[_scope.curQuestion.index] = _newQuestion(i)
				_scope.curQuestion = false
			_scope.addAnswer = ->
				_scope.curQuestion.answers.push _newAnswer()
			_scope.deleteAnswer = (index) ->
				_scope.curQuestion.answers.splice(index,1)
			_scope.toggleAnswer = (answer) ->
				answer.value = if answer.value is 100 then 0 else 100
				answer.options.custom = false
			_scope.newCategory = (index,category) ->
				$('#category_'+index).focus()
				category.isEditing = true
				_scope.step = 2 if _scope.step is 1
			_scope.updateCategory = ->
				setTimeout ->
					_scope.$apply ->
						_scope.step = 3 if _scope.step is 2
				,0
		_scope.$watch ->
			if _scope.qset.items[_scope.qset.items.length-1].name
				_scope.qset.items.push
					items: []
					used: 0
				_buildScaffold()

	initNewWidget = (widget, baseUrl) ->
		_initScope()
		_scope.$apply ->
			_scope.title = 'New enigma widget'
			_scope.qset =
				items: []
				options:
					randomize: true
			_buildScaffold()

		$('#backgroundcover, .intro').addClass 'show'

		$('.intro input[type=button]').click ->
			$('#backgroundcover, .intro').removeClass 'show'
			_scope.$apply ->
				_scope.title = $('.intro input[type=text]').val() or _scope.title
				_scope.step = 1

	initExistingWidget = (title, widget, qset, version, baseUrl) ->
		_initScope()

		_scope.$apply ->
			_scope.title = title
			_scope.qset = qset
		_scope.$apply ->
			_buildScaffold()


	_newAnswer = ->
		id: ''
		text: ''
		value: 0
		options:
			feedback: ''
			custom: false
			correct: false
	
	_newQuestion = (i=0) ->
		type: 'MC'
		id: ''
		questions: [
			text: ''
		]
		answers: [
			_newAnswer(),
			_newAnswer()
		]
		used: 0
		index: i

	_buildScaffold = ->
		while _scope.qset.items.length < 5
			_scope.qset.items.push
				items: []
				used: 0
		i = 0
		for category in _scope.qset.items
			category.index = i++

		for category in _scope.qset.items
			i = 0
			while category.items.length < 6
				category.items.push _newQuestion()
				console.log 'added q'
			for question in category.items
				question.index = i++
	
	onSaveClicked = (mode = 'save') ->
		if _buildSaveData()
			Materia.CreatorCore.save _scope.title, _scope.qset
		else
			Materia.CreatorCore.cancelSave 'Widget not ready to save.'
		_buildScaffold()

	onSaveComplete = (title, widget, qset, version) -> true

	onQuestionImportComplete = (questions) ->
		$('#import_area').show()
		_addQuestion $('#import_question_area')[0], question for question in questions

	# Enigma does not support media
	onMediaImportComplete = (media) -> null

	_buildSaveData = ->
		okToSave = true

		i = 0
		console.log _scope.qset
		while i < _scope.qset.items.length
			if not _scope.qset.items[i].name
				_scope.qset.items.splice(i,1)
				i--

			j = 0
			while j < _scope.qset.items[i].items.length
				if not _scope.qset.items[i].items[j].questions[0].text
					_scope.qset.items[i].items.splice(j,1)
					j--
				j++
			i++

		okToSave

	_trace = ->
		if console? && console.log?
			console.log.apply console, arguments

	#public
	initNewWidget: initNewWidget
	initExistingWidget: initExistingWidget
	onSaveClicked: onSaveClicked
	onMediaImportComplete: onMediaImportComplete
	onQuestionImportComplete: onQuestionImportComplete
	onSaveComplete: onSaveComplete
