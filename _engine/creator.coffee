###

Materia
It's a thing

Widget	: Enigma, Creator
Authors	: Jonathan Warner
Updated	: 5/14

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
EnigmaCreator.directive('focusMe', ($timeout, $parse) ->
	link: (scope, element, attrs) ->
		model = $parse(attrs.focusMe)
		scope.$watch model, (value) ->
			if value
				$timeout ->
					element[0].focus()
			value
)

EnigmaCreator.controller 'enigmaCreatorCtrl', ['$scope', ($scope) ->
	$scope.title = ''
	$scope.qset = {}

	$scope.curQuestion = false
	$scope.curCategory = false

	$scope.imported = []

	# forever increasing number
	zIndex = 9999

	# Public methods
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
		Materia.CreatorCore.save $scope.title, _buildSaveData()

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
				i++	if question.$used
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
		$index == 0 or $scope.qset.items[$index-1].name or $scope.qset.items[$index].name

	$scope.questionShowAdd = (category, question, $index) ->
		not question.questions[0].text and category.name and ($index == 0 or category.items[$index-1].questions[0].text)

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
		$scope.step = 1
		
		$scope.hideCover()

	$scope.editQuestion = (category,question,$index) ->
		if category.name and $index == 0 or category.items[$index-1].questions[0].text != ''
			$scope.curQuestion = question
			$scope.curCategory = category
			question.$used = true

			for answer in question.answers
				answer.options.$correct = false
				answer.options.$custom = false

				if answer.value == 100
					answer.options.$correct = true
				else if answer.value isnt 100 and answer.value isnt 0
					answer.options.$custom = true

			$scope.step = 4 if $scope.step is 3

	$scope.editComplete = ->
		for answer in $scope.curQuestion.answers
			answer.value = parseInt(answer.value,10)

			if answer.options.$custom
				if answer.value == 100 or answer.value == 0
					answer.options.$custom = false
					answer.options.$correct = if answer.value == 100 then true else false
			else
				answer.value = if answer.options.$correct then 100 else 0
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
			$custom: false
			$correct: false
	
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
		$used: 0
		$index: i

	$scope.toggleAnswer = (answer) ->
		answer.value = if answer.value is 100 then 0 else 100
		answer.options.$custom = false

	$scope.newCategory = (index,category) ->
		setTimeout ->
			$('#category_'+index).focus()
		,10
		category.isEditing = true
		$scope.step = 2 if $scope.step is 1

	$scope.updateCategory = ->
		$scope.step = 3 if $scope.step is 2

	$scope.buildScaffold = ->
		while $scope.qset.items.length < 5
			$scope.qset.items.push
				items: []
				$used: 0
		i = 0
		for category in $scope.qset.items
			category.index = i++

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

	$scope.$watch ->
		if $scope?.qset?.items?[$scope.qset.items.length-1]?.name
			$scope.qset.items.push
				items: []
				index: $scope.qset.items.length
				$used: 0
			$scope.buildScaffold()

	# Private helpers
	_initDragDrop = ->
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

			over: (event,ui) ->
				category = +this.getAttribute('data-category')
				question = +this.getAttribute('data-question')

				questionobj = $scope.qset.items[category].items[question]

				if questionobj.questions[0].text != ''
					$(ui.draggable).addClass('red').removeClass('green')
				else
					return if not $scope.questionShowAdd($scope.qset.items[category], questionobj, question)
					$(ui.draggable).addClass('green').removeClass('red')

			out: (event,ui) ->
				$(ui.draggable).removeClass('green').removeClass('red')

	_buildSaveData = ->
		qset = angular.copy $scope.qset

		i = 0
		while i < qset.items.length
			if not qset.items[i].name
				qset.items.splice(i,1)
				i--
				continue

			j = 0
			while j < qset.items[i].items.length
				if not qset.items[i].items[j].questions[0].text
					qset.items[i].items.splice(j,1)
					j--
				j++
			i++

		qset

	Materia.CreatorCore.start $scope
]

