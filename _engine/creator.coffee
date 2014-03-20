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

	$scope.imported = [{"materiaType":"question","id":"28b97f3cc15dc886fa2992d28e66c723","type":"MC","created_at":1395172197,"questions":[{"text":"dfdfadfsdffd"}],"answers":[{"id":"333f2a1b27bce96aa367e923e0356bc6","text":"dfsd","value":0,"options":{"feedback":"fsdfasdfs","custom":false,"correct":false}},{"id":"96d978432820889c2e13537c65310263","text":"dfasdf","value":0,"options":{"feedback":"dfsadf","custom":false,"correct":false}}],"options":[],"assets":[]},{"materiaType":"question","id":"ac74df42c05ab67025a3551d38ff8da7","type":"MC","created_at":1395075234,"questions":[{"text":"ghg"}],"answers":[{"id":"528e856d7c2eb269fc3cf7d6251dcb2b","text":"","value":0,"options":{"feedback":"","custom":false,"correct":false}},{"id":"6994a3d49ea936901a66ee66047f5e45","text":"","value":0,"options":{"feedback":"","custom":false,"correct":false}}],"options":[],"assets":[]},{"materiaType":"question","id":"b0b74d41bd338d14214e5d40f7a9ba78","type":"MC","created_at":1395075234,"questions":[{"text":"ghgh"}],"answers":[{"id":"55803608b0b8ab98952025932858d125","text":"","value":0,"options":{"feedback":"","custom":false,"correct":false}},{"id":"258c987a800f066d48e1b51fe531cc73","text":"","value":0,"options":{"feedback":"","custom":false,"correct":false}}],"options":[],"assets":[]},{"materiaType":"question","id":"979cfc4d34f737b76b8bda40e1198e0a","type":"MC","created_at":1395075234,"questions":[{"text":"gfhfghghf"}],"answers":[{"id":"08b83e6ee6875c21104b5e5a92e7f4a1","text":"","value":0,"options":{"feedback":"","custom":false,"correct":false}},{"id":"9828753afe20b10df2fcc684dcaeb080","text":"","value":0,"options":{"feedback":"","custom":false,"correct":false}}],"options":[],"assets":[]},{"materiaType":"question","id":"cb4e063e89bdcf010aa9b49fcd6f103f","type":"MC","created_at":1395075234,"questions":[{"text":"gfhfgh"}],"answers":[{"id":"d9d0e79c9fb4b95d6221dd769b095f42","text":"","value":0,"options":{"feedback":"","custom":false,"correct":false}},{"id":"f5da7ea8718b342ea5c7e110904f8efa","text":"","value":0,"options":{"feedback":"","custom":false,"correct":false}}],"options":[],"assets":[]},{"materiaType":"question","id":"879902c1b8b35767016e2e3d063e65d0","type":"MC","created_at":1395075234,"questions":[{"text":"dsdffdsdf"}],"answers":[{"id":"40b0c15e26f1071d6187400adc58d3cd","text":"","value":0,"options":{"feedback":"","custom":false,"correct":false}},{"id":"3f348992e7c730691d11b4882252502b","text":"","value":0,"options":{"feedback":"","custom":false,"correct":false}}],"options":[],"assets":[]},{"materiaType":"question","id":"1d9c64cd763424aeb0ed92760e3e016d","type":"MC","created_at":1395075234,"questions":[{"text":"fdsfdsfsdfsd"}],"answers":[{"id":"7bbe7a0feee230300fd0b354005582c0","text":"","value":0,"options":{"feedback":"","custom":false,"correct":false}},{"id":"419ce804fbf9e6e97bafd01c6e466b50","text":"","value":0,"options":{"feedback":"","custom":false,"correct":false}}],"options":[],"assets":[]},{"materiaType":"question","id":"d821e1914f68a62586d0da048bf26b9f","type":"MC","created_at":1394745648,"questions":[{"text":"Everybody wins"}],"answers":[{"id":"b8951d3617c3088e4343dce87abe0805","text":"everyone will win","value":50,"options":{"feedback":"","custom":true,"correct":true}},{"id":"1e174b04347a8855ac0c71c105ab3875","text":"correct","options":{"feedback":"","custom":false,"correct":true},"value":100}],"options":[],"assets":[]},{"materiaType":"question","id":"d821e1914f68a62586d0da048bf26b9f","type":"MC","created_at":1394745648,"questions":[{"text":"Everybody wins"}],"answers":[{"id":"b8951d3617c3088e4343dce87abe0805","text":"everyone will win","value":50,"options":{"feedback":"","custom":true,"correct":true}},{"id":"1e174b04347a8855ac0c71c105ab3875","text":"correct","options":{"feedback":"","custom":false,"correct":true}}],"options":[],"assets":[]},{"materiaType":"question","id":"f7a9c8650ace2bd0498b5eb6628cf272","type":"MC","created_at":1394738482,"questions":[{"text":"dsdsadffds"}],"answers":[{"id":"6e815da1d88b04aa57bd6166b0eea341","text":"asdfds","value":"40","options":{"feedback":"ssdadsf","correct":2}},{"id":"db538b70c4c702adc0e5893ef8eb5af4","text":"sda","value":"30","options":{"feedback":"adssadsd","correct":true}}],"options":[],"assets":[]},{"materiaType":"question","id":"f7a9c8650ace2bd0498b5eb6628cf272","type":"MC","created_at":1394738482,"questions":[{"text":"dsdsadffds"}],"answers":[{"id":"6e815da1d88b04aa57bd6166b0eea341","text":"asdfds","value":"40","options":{"feedback":"ssdadsf","correct":true}},{"id":"db538b70c4c702adc0e5893ef8eb5af4","text":"sda","value":"30","options":{"feedback":"adssadsd"}}],"options":[],"assets":[]},{"materiaType":"question","id":"f7a9c8650ace2bd0498b5eb6628cf272","type":"MC","created_at":1394738482,"questions":[{"text":"dsdsa"}],"answers":[{"id":"6e815da1d88b04aa57bd6166b0eea341","text":"asd","value":100,"options":{"feedback":"ssda","correct":true}},{"id":"db538b70c4c702adc0e5893ef8eb5af4","text":"sda","value":0,"options":{"feedback":"adssadsd"}}],"options":[],"assets":[]},{"materiaType":"question","id":"bcebee240cb5f024bf4fdaa799fd3e32","type":"MC","created_at":1394737823,"questions":[{"text":"dxfcghjkl;kj"}],"answers":[{"id":"24596b2da797d6034997184d4e73a6ea","text":"kljhgfds","value":100,"options":{"feedback":"hgfdfghj","correct":true}},{"id":"30be8b213b0bb86a12240ba79f530e78","text":"hgfjkl","value":0,"options":{"feedback":";;ll;kkj"}}],"options":[],"assets":[]},{"materiaType":"question","id":"d48d35ebeec8e4e6e71ffec40610e142","type":"MC","created_at":1394737823,"questions":[{"text":"dfsdfsdsf"}],"answers":[{"id":"b0143370e59d78f0336ea576dbf5cf9c","text":"dffg","value":0,"options":{"feedback":"safsadf"}},{"id":"1377b6d3159d0720fc2b8d6057cded33","text":"fdsfdsas","value":0,"options":{"feedback":"dfgsfd"}}],"options":[],"assets":[]},{"materiaType":"question","id":"0f94effeb48197baf1cc562bc95eb077","type":"MC","created_at":1394736936,"questions":[{"text":"fds"}],"answers":[{"id":"233d36fcc8cd39a5149f6c13917db5a3","text":"dfsdsfdsf","value":0,"options":{"feedback":"df"}},{"id":"03992d5c8af33e410864a3cb8ff89764","text":"dsf","value":0,"options":{"feedback":"dsfdfdfs"}}],"options":[],"assets":[]},{"materiaType":"question","id":"2b38f8dafcb7dc1b6737097fc4eb8f5d","type":"MC","created_at":1394736936,"questions":[{"text":"dfsdf"}],"answers":[{"id":"10b8cb7c723eba2d6108f070e11d5a51","text":"sdfsdf","value":0,"options":{"feedback":"dsfdsf"}},{"id":"1aec4ec1309f0d4786e8e6279d2e3d1c","text":"dfs","value":0,"options":{"feedback":"sd"}}],"options":[],"assets":[]},{"materiaType":"question","id":"8aa845a10156bdd4508a953736d80bfe","type":"MC","created_at":1394736862,"questions":[{"text":"fdsfddf"}],"answers":[{"id":"95754645f5a7b9175c3f3b157e00ff3f","text":"dsf","value":0,"options":{"feedback":"dfsdsf"}},{"id":"72b5be76f309b8ca3bc9ece348abfb6a","text":"dfsdsf","value":0,"options":{"feedback":"dfs"}}],"options":[],"assets":[]},{"materiaType":"question","id":"109c0c15fc327185a1a03205bfb197f7","type":"MC","created_at":1394722191,"questions":[{"text":"sdsa"}],"answers":[{"id":"be208f57347d2b177488b4a6284f6584","text":"sds","value":0,"options":{"feedback":"dsad"}},{"id":"3b06316bc4b60c053d2c1dbeb4d2e852","text":"sda","value":0,"options":{"feedback":"sdasda"}}],"options":[],"assets":[]},{"materiaType":"question","id":"97c9a3c3fad22107edbf5479a6286876","type":"MC","created_at":1394736646,"questions":[{"text":"sdfdfs"}],"answers":[{"id":"ca1673c7e4134374bbc8e31506ff3f47","text":"dsfdfs","value":0,"options":{"feedback":"dfsd"}},{"id":"c92084b38ec9159eee06f24b9ffa4ca6","text":"dfsdsdf","value":0,"options":{"feedback":"ssddfsdf"}},{"id":"d09c9a8d2993eb04aae4683ac1b7bd00","text":"right","value":100,"options":{"feedback":"fdfdsfgd","correct":true}}],"options":[],"assets":[]},{"materiaType":"question","id":"2529900bc2065ee51be49c22fdc21164","type":"MC","created_at":1394736646,"questions":[{"text":"fdsdfs"}],"answers":[{"id":"35dbbd38f3e752b28543eb7809a93646","text":"dfsdfsdfs","value":0,"options":{"feedback":"dfs"}},{"id":"eedcd6ba43e353852d77a729f6e002ae","text":"makeup","value":100,"options":{"feedback":"dfs","correct":true}}],"options":[],"assets":[]},{"materiaType":"question","id":"973e882ee75af12f2192e4ccaec393e2","type":"MC","created_at":1394736862,"questions":[{"text":"dfsdfs"}],"answers":[{"id":"ef5c9cd957d656d13bbd7fe7ef610c12","text":"dfs","value":0,"options":{"feedback":"dsfdfs"}},{"id":"a34631a6a1c26c2ef1f7da1e3a3ec9d9","text":"dsfdf","value":0,"options":{"feedback":"fs"}}],"options":[],"assets":[]},{"materiaType":"question","id":"98fc5f7747738961746b8e24091b3736","type":"MC","created_at":1394736646,"questions":[{"text":"dsdsasd"}],"answers":[{"id":"7186a5689ebb0be9a62b8070b93d4cd9","text":"sdadsa","value":0,"options":{"feedback":"sdasdasd"}},{"id":"05e82a54c7a560460aff977f1f5b8eb7","text":"born","value":100,"options":{"feedback":"dfsdfs","correct":true}}],"options":[],"assets":[]},{"materiaType":"question","id":"a64e01c812e3b2c0c22235dbe0f60851","type":"MC","created_at":1394722191,"questions":[{"text":"dsasda"}],"answers":[{"id":"3c54fb102540fd86782e58e13b855003","text":"sdasd","value":0,"options":{"feedback":"sda"}},{"id":"a6b20d8852ae3296f59f98f81a7a34ef","text":"sd","value":0,"options":{"feedback":"sdasad"}}],"options":[],"assets":[]},{"materiaType":"question","id":"7a194f56fb8ab61653c2e9b7fa071470","type":"MC","created_at":1394722191,"questions":[{"text":"adssda"}],"answers":[{"id":"b07a0d0dbdfc77f9743aac5bdf34326e","text":"dsasad","value":0,"options":{"feedback":"sad"}},{"id":"ab1854446e2ff6555b3bcd7774ae82ee","text":"sdasadsda","value":0,"options":{"feedback":"sadsda"}}],"options":[],"assets":[]},{"materiaType":"question","id":"d62ac306bc114e43a105523f826fd71e","type":"MC","created_at":1394722066,"questions":[{"text":"fgd"}],"answers":[{"id":"542f81ab4ced674e046d3119c2affd30","text":"fgd","value":0,"options":{"feedback":"fdgfgdfgd"}},{"id":"840b1e6ba6ab1b0f4e2d5c602c5ebfd8","text":"fggdf","value":0,"options":{"feedback":"gd"}}],"options":[],"assets":[]},{"materiaType":"question","id":"8a116adf682a3a667f56c5a7f16df885","type":"MC","created_at":1394722066,"questions":[{"text":"fdgdfgfg"}],"answers":[{"id":"8813a2a78f9a5fb5c83ae89a2c0f95ad","text":"fdg","value":0,"options":{"feedback":"fgdfdg"}},{"id":"3af61e3ba18ef0d57e23452b5b9f8033","text":"fdgdfg","value":0,"options":{"feedback":"fg"}}],"options":[],"assets":[]}] 

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
	
	$scope.changeTitle = ->
		$('#backgroundcover, .title').addClass 'show'
		$('.title input[type=text]').focus()
		$('.title input[type=button]').click ->
			$('#backgroundcover, .title').removeClass 'show'

	$scope.editQuestion = (category,question,$index) ->
		if category.name and $index == 0 or category.items[$index-1].questions[0].text != ''
			$scope.curQuestion = question
			$scope.curCategory = category
			question.used = true
			setTimeout ->
				$('#question_text').focus()
			,0

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
		$scope.qset.items[$scope.curCategory.index].items[$scope.curQuestion.index] = $newQuestion(i)
		$scope.curQuestion = false
		
	$scope.addAnswer = ->
		$scope.curQuestion.answers.push $newAnswer()

	$scope.deleteAnswer = (index) ->
		$scope.curQuestion.answers.splice(index,1)

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
]

Namespace('Enigma').Creator = do ->
	$scope = {}

	_initScope = ->
		$scope = angular.element($('body')).scope()
		$scope.$watch ->
			if $scope.qset.items[$scope.qset.items.length-1].name
				$scope.qset.items.push
					items: []
					used: 0
				_buildScaffold()

	initNewWidget = (widget, baseUrl) ->
		_initScope()
		$scope.$apply ->
			$scope.title = 'New enigma widget'
			$scope.qset =
				items: []
				options:
					randomize: true
			_buildScaffold()

		#$('#backgroundcover, .intro').addClass 'show'

		_initDragDrop()

		$('.intro input[type=button]').click ->
			$('#backgroundcover, .intro').removeClass 'show'
			$scope.$apply ->
				$scope.title = $('.intro input[type=text]').val() or $scope.title
				$scope.step = 1

	initExistingWidget = (title, widget, qset, version, baseUrl) ->
		_initScope()

		$scope.$apply ->
			$scope.title = title
			$scope.qset = qset
		$scope.$apply ->
			_buildScaffold()

	_initDragDrop = () ->
		$('.importable').draggable
			start: (event,ui) ->
				this.style.zIndex = 1999999
				this.style.position = 'absolute'
				$scope.curDragging = +this.getAttribute('data-index')
			stop: (event,ui) ->
				this.style.position =
				this.style.top =
				this.style.left = ''
		$('.question').droppable
			drop: (event,ui) ->
				$(ui.draggable).css 'border', ''

				category = +this.getAttribute('data-category')
				question = +this.getAttribute('data-question')
				questionobj = $scope.qset.items[category].items[question]

				if not $scope.questionShowAdd($scope.qset.items[category], questionobj, question)
					console.log 'cant drop'
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
					console.log 'cant'
					return

				if questionobj.questions[0].text != ''
					$(ui.draggable).css 'border', 'solid 3px #f6002b'
				else
					$(ui.draggable).css 'border', 'solid 3px #71be34'

			out: (event,ui) ->
				$(ui.draggable).css 'border', ''

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
				category.items.push _newQuestion()
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
		console.log JSON.stringify(questions)
		$scope.$apply ->
			$scope.imported = questions.concat $scope.imported

	# Enigma does not support media
	onMediaImportComplete = (media) -> null

	_buildSaveData = ->
		okToSave = true

		i = 0
		while i < $scope.qset.items.length
			if not $scope.qset.items[i].name
				$scope.qset.items.splice(i,1)
				i--

			j = 0
			while j < $scope.qset.items[i].items.length
				if not $scope.qset.items[i].items[j].questions[0].text
					$scope.qset.items[i].items.splice(j,1)
					j--
				j++
			i++

		okToSave
	
	#public
	initNewWidget: initNewWidget
	initExistingWidget: initExistingWidget
	onSaveClicked: onSaveClicked
	onMediaImportComplete: onMediaImportComplete
	onQuestionImportComplete: onQuestionImportComplete
	onSaveComplete: onSaveComplete
