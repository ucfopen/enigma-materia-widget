###

Materia
It's a thing

Widget	: Enigma, Creator
Authors	: Jonathan Warner
Updated	: 3/14

###

EnigmaCreator = angular.module('enigmaCreator', [])
EnigmaCreator.directive('ngEnter', ->
    return (scope, element, attrs) ->
        element.bind("keydown keypress", (event) ->
            if(event.which == 13)
                scope.$apply ->
                    scope.$eval(attrs.ngEnter)
                event.preventDefault()
        )
)


EnigmaCreator.controller 'enigmaCreatorCtrl', ['$scope', ($scope) ->
	$scope.title = ''
	$scope.qset = {}

	$scope.curQuestion = false
	$scope.curCategory = false

	$scope.imported = []

	$scope.numQuestions = ->
		if !$scope.qset.items?
			return 0
		i = 0
		for category in $scope.qset.items
			for question in category.items
				i++	if question.used
		i
	
	$scope.categoryOpacity = (category, $index) ->
		opacity = 0.1
		if $scope.step is 1 and $index is 0
			opacity = 1
		if category.name or category.isEditing
			opacity = 1
		return opacity

	$scope.categoryShowAdd = (category, $index) ->
		not category.name and not category.isEditing and ($index == 0 or $scope.qset.items[$index-1].name)

	$scope.categoryEnabled = (category, $index) ->
		$index == 0 or $scope.qset.items[$index-1].name

	$scope.questionShowAdd = (category, question, $index) ->
		not question.questions[0].text and category.name and ($index == 0 or category.items[$index-1].questions[0].text)

	$scope.editCategory = (category) ->
		category.isEditing = true
		$scope.curQuestion = false

	$scope.stopCategory = (category) ->
		category.isEditing = false
	
	$scope.hideCover = ->
		$('#backgroundcover, .intro, .title').removeClass 'show'
	
	$scope.changeTitle = ->
		$('#backgroundcover, .title').addClass 'show'
		$('.title input[type=text]').focus()
		$('.title input[type=button]').click ->
			$('#backgroundcover, .title').removeClass 'show'
	
	$scope.setTitle = ->
		setTimeout ->
			$('#backgroundcover, .intro').removeClass 'show'
			$scope.$apply ->
				$scope.title = $('.intro input[type=text]').val() or $scope.title
				$scope.step = 1
		,1

	$scope.editQuestion = (category,question,$index) ->
		if category.name and $index == 0 or category.items[$index-1].questions[0].text != ''
			$scope.curQuestion = question
			$scope.curCategory = category
			question.used = true
			setTimeout ->
				$('#question_text').focus()
			,0

			for answer in question.answers
				answer.options.correct = false
				answer.options.custom = false

				if answer.value == 100
					answer.options.correct = true
				else if answer.value isnt 100 and answer.value isnt 0
					answer.options.custom = true

			$scope.step = 4 if $scope.step is 3

	$scope.editComplete = ->
		for answer in $scope.curQuestion.answers
			answer.value = parseInt(answer.value,10)

			if answer.options.custom
				if answer.value == 100 or answer.value == 0
					answer.options.custom = false
					answer.options.correct = if answer.value == 100 then true else false
			else
				answer.value = if answer.options.correct then 100 else 0
		$scope.curQuestion = false
		
	$scope.deleteQuestion = (i) ->
		$scope.qset.items[$scope.curCategory.index].items[$scope.curQuestion.index] = $scope.newQuestion(i)
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
		used: 0
		index: i


	$scope.toggleAnswer = (answer) ->
		answer.value = if answer.value is 100 then 0 else 100
		answer.options.custom = false

	$scope.newCategory = (index,category) ->
		$('#category_'+index).focus()
		category.isEditing = true
		$scope.step = 2 if $scope.step is 1

	$scope.updateCategory = ->
		setTimeout ->
			$scope.$apply ->
				$scope.step = 3 if $scope.step is 2
		,0

	$scope.numbersOnly = (answer) ->
		if not answer.value.match(/^[0-9]?[0-9]?$/)
			answer.value = answer.value.replace(/[^0-9]+/, '')
		if ~~answer.value > 100
			answer.value = 100
]

Namespace('Enigma').Creator = do ->
	$scope = {}
	
	# forever increasing number
	zIndex = 9999

	_initScope = ->
		$scope.$watch ->
			if $scope.qset.items[$scope.qset.items.length-1].name
				$scope.qset.items.push
					items: []
					used: 0
				_buildScaffold()

	initNewWidget = (widget, baseUrl) ->
		$scope = angular.element($('body')).scope()

		_initScope()

		$scope.$apply ->
			$scope.title = 'My enigma widget'
			$scope.qset =
				items: []
				options:
					randomize: true
			_buildScaffold()

		$('#backgroundcover, .intro').addClass 'show'
		$('.intro input[type=text]').focus()

	initExistingWidget = (title, widget, qset, version, baseUrl) ->
		$scope = angular.element($('body')).scope()

		if qset.data
			qset = qset.data

		$scope.$apply ->
			$scope.title = title
			$scope.qset = qset
		$scope.$apply ->
			_buildScaffold()

			_initScope()

	_initDragDrop = () ->
		$('.importable').draggable
			start: (event,ui) ->
				$scope.shownImportTutorial = true
				$scope.curDragging = +this.getAttribute('data-index')
				this.style.position = 'absolute'
				this.style.zIndex = ++zIndex
				this.style.marginLeft = $(this).position().left + 'px'
				this.style.marginTop = $(this).position().top + 'px'
				this.className += ' dragging'
			stop: (event,ui) ->
				this.style.position = 'relative'
				this.style.marginTop =
				this.style.marginLeft =
				this.style.top =
				this.style.left = ''
				this.className = 'importable'
		$('.question').droppable
			drop: (event,ui) ->
				$(ui.draggable).css 'border', ''

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

			over: (event,ui) ->
				category = +this.getAttribute('data-category')
				question = +this.getAttribute('data-question')

				questionobj = $scope.qset.items[category].items[question]

				if not $scope.questionShowAdd($scope.qset.items[category], questionobj, question)
					return

				if questionobj.questions[0].text != ''
					$(ui.draggable).css 'border', 'solid 3px #f6002b'
				else
					$(ui.draggable).css 'border', 'solid 3px #71be34'

			out: (event,ui) ->
				$(ui.draggable).css 'border', ''

	_buildScaffold = ->
		i = 0
		while i < $scope.qset.items.length
			if not $scope.qset.items[i].name
				found = false
				for question in $scope.qset.items[i].items
					if question.questions[0].text
						found = true

				if not found and $scope.qset.items[i+1] and $scope.qset.items[1+1].name
					$scope.qset.items.splice(i,1)
					i--
					break
			i++

		while $scope.qset.items.length < 5
			$scope.qset.items.push
				items: []
				used: 0
		i = 0
		for category in $scope.qset.items
			category.index = i++

		for category in $scope.qset.items
			i = 0
			while category.items.length < 6
				category.items.push $scope.newQuestion()
			for question in category.items
				question.index = i++

	onSaveClicked = (mode = 'save') ->
		if _buildSaveData()
			Materia.CreatorCore.save $scope.title, $scope.qset
		else
			Materia.CreatorCore.cancelSave 'Widget not ready to save.'
		_buildScaffold()

	onSaveComplete = (title, widget, qset, version) -> true

	onQuestionImportComplete = (questions) ->
		$scope.$apply ->
			$scope.imported = questions.concat $scope.imported
		_initDragDrop()

	# Enigma does not support media
	onMediaImportComplete = (media) -> null

	_buildSaveData = ->
		okToSave = true

		i = 0
		while i < $scope.qset.items.length
			if not $scope.qset.items[i].name
				$scope.qset.items.splice(i,1)
				i--
				continue

			j = 0
			while j < $scope.qset.items[i].items.length
				if not $scope.qset.items[i].items[j].questions[0].text
					$scope.qset.items[i].items.splice(j,1)
					j--
				j++
			i++

		# trim out our helping data
		for category in $scope.qset.items
			for question in category.items
				for answer in question.answers
					delete answer.options.custom
					delete answer.options.correct
				delete question.used
			delete category.index

		okToSave
	
	#public
	initNewWidget: initNewWidget
	initExistingWidget: initExistingWidget
	onSaveClicked: onSaveClicked
	onMediaImportComplete: onMediaImportComplete
	onQuestionImportComplete: onQuestionImportComplete
	onSaveComplete: onSaveComplete
