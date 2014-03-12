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


	$scope.range = (n) -> [0...n]
]

Namespace('Enigma').Creator = do ->
	_qset    = null # Keep tack of the current qset
	_title   = null # hold on to this instance's title

	_scope = {}

	# reference for question answer lists
	_letters = ['A','B','C','D','E','F','G','H','I','J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']

	initNewWidget = (widget, baseUrl) ->
		_scope = angular.element($('body')).scope()
		_scope.$apply ->
			_scope.title = 'New enigma widget'
			_scope.qset =
				items: [
					{items: [
						5,4,3,2
					]},
					{items: [
						5,4,3,2
					]}
				]
				options:
					randomize: true

		#$('#backgroundcover, .intro').addClass 'show'

		$('.intro input[type=button]').click ->
			$('#backgroundcover, .intro').removeClass 'show'
			_title = $('.intro input[type=text]').val()
			

	initExistingWidget = (title, widget, qset, version, baseUrl) -> _buildDisplay title, widget, qset, version

	onSaveClicked = (mode = 'save') ->
		if _buildSaveData()
			Materia.CreatorCore.save _title, _qset
		else
			Materia.CreatorCore.cancelSave 'Widget not ready to save.'

	onSaveComplete = (title, widget, qset, version) -> true

	onQuestionImportComplete = (questions) ->
		$('#import_area').show()
		_addQuestion $('#import_question_area')[0], question for question in questions

	# Enigma does not support media
	onMediaImportComplete = (media) -> null

	_buildDisplay = (title = 'Default test Title', widget, qset, version) ->
		_version = version
		_qset    = qset
		_title   = title

		$('#title').val _title

		# enable the category/question area so that categories can be drag-sorted
		$('#question_container').sortable {
			containment: 'parent',
			distance: 5,
			helper: 'clone',
			items: '.category'
		}
		$('#question_container').droppable()
		$('#question_container').droppable 'enable'

		# fill the template objects
		unless _catTemplate
			_catTemplate = $('.template.category')
			$('.template.category').remove()
			_catTemplate.removeClass('template')
		unless _qTemplate
			_qTemplate = $('.template.question')
			$('.template.question').remove()
			_qTemplate.removeClass('template')
		unless _qWindowTemplate
			_qWindowTemplate = $('.template.question_window')
			$('.template.question_window').remove()
			_qWindowTemplate.removeClass('template')
		unless _aTemplate
			_aTemplate = $('.template.answer')
			$('.template.answer').remove()
			_aTemplate.removeClass('template')

		$('#add_category_button').click ->
			# remove tutorial steps if creating a new widget
			if $('.step1').length > 0
				$('.step1').remove()
				tutorial2 = $('<div class=\'tutorial step2\'>'+_helper2+'</div>')
				$('body').append tutorial2
			_addCategory()

		$('#import_hide').click -> $('#import_area').hide()

		if _help
			tutorial1 = $('<div class=\'tutorial step1\'>'+_helper1+'</div>')
			$('body').append tutorial1

		if _qset?
			$('#randomize').prop 'checked', _qset.options.randomize
			categories = _qset.items
			_addCategory category for category in categories

	_buildSaveData = ->
		okToSave = false

		# create new qset object if we don't already have one, set default values regardless
		if !_qset?
			_qset = {}
		_qset.options = {}
		_qset.assets = []
		_qset.rand = false
		_qset.name = ''

		# update our values
		_title = $('#title').val()
		_qset.options.randomize = $('#randomize').prop 'checked'
		okToSave = true if _title? && _title!= ''

		items = []
		_qset.options.randomize = $('#randomize').prop 'checked'

		categories = $('.category')

		cid = 0
		for c in categories
			category = _process c
			category.assets = []
			category.options = {cid: cid++}
			items.push category

		_qset.items = items
		okToSave

	# get each category's data from the appropriate page elements
	_process = (c) ->
		c = $(c)
		category = {name: '', items: []}
		category.name = c.find('textarea').val()
		items = []
		questions = c.find('.question')
		for q in questions
			question = $.data q
			delete question['uiDraggable']
			items.push question

		category.items = items
		category

	_addCategory = (category) ->
		newCat = $(_catTemplate).clone()
		newCat.click () ->
			$('.active').removeClass 'active'
			$(this).addClass 'active'
		# select the category's text when the text area is focused
		newCat.find('textarea').focus () -> this.select()

		newCat.find('.add').click () ->
			# remove tutorial steps if creating a new widget
			if $('.step2').length > 0
				$('.step2').remove()
				tutorial3 = $('<div class=\'tutorial step3\'>'+_helper3+'</div>')
				$('body').append tutorial3
			# only add another question if there are less than six already
			numQs = newCat.find('.question').length
			unless numQs > 5
				if numQs is 5
					$(this).hide()
					newCat.droppable 'disable'
				_addQuestion newCat

		newCat.find('.delete').click -> newCat.remove()

		newCat.droppable {
			hoverClass: 'drop_target',
			drop: (event, ui) ->
				numQs = newCat.find('.question').length
				unless numQs > 5
					if numQs is 5
						newCat.find('.add').hide()
						newCat.droppable 'disable'
					# re-enable question adding on the dropped question's original category
					unless ui.draggable.closest('#import_question_area').length > 0
						ui.draggable.siblings('.add').show()
						ui.draggable.parent().droppable 'enable'
					newCat.find('.add').before ui.draggable
				else
					newCat.find('.add').hide()
				newCat.find('.add_line').remove()
			over: (event, ui) ->
				unless ui.draggable.hasClass '.category' or $(this).parent().children().length > 8
					newCat.find('.add').before $('<div class="add_line"></div>')
			out: (event, ui) -> newCat.find('.add_line').remove()
		}
		newCat.droppable 'enable'

		if category?
			newCat.find('textarea').val(category.name)
			questions = category.items
			_addQuestion newCat, question for question in questions

		$('#question_container').append newCat
		$('#question_container').sortable 'refresh'
		newCat.find('textarea').focus()

	_addQuestion = (category, question=null) ->
		# create a new question element and default its pertinent data
		newQ = _qTemplate.clone()
		$.data(newQ[0], 'questions', [{text: ''}])
		$.data(newQ[0], 'answers', [])
		$.data(newQ[0], 'assets', [])
		$.data(newQ[0], 'id', '')
		$.data(newQ[0], 'type', 'MC')

		newQ.find('.delete').click () ->
			addBtn = $(this).parent().siblings('.add')
			if !addBtn.is(':visible')
				addBtn.show()
				addBtn.parent().droppable 'enable'
			$(this).parent().remove()
		newQ.click () ->
			_changeQuestion this unless $(this).hasClass('dim') or $(this).closest('#import_question_area').length > 0 or $(this).hasClass('dragging')
		newQ.draggable {
			distance: 5,
			revert: 'invalid',
			helper: 'clone',
			appendTo: 'body',
			opacity: 0.75,
			start: (event, ui) -> newQ.addClass('dragging')
			stop: (event, ui) -> newQ.removeClass('dragging')
		}

		$(category).find('.add').before newQ

		if question?
			fit_text = question.questions[0].text
			if fit_text.length > 20
				fit_text = fit_text.substring(0, 17) + '...'
			newQ.find('.question_text').text fit_text
			$.data(newQ[0], 'questions', [{text: question.questions[0].text}])
			$.data(newQ[0], 'answers', question.answers)
		else
			$(newQ).click()

	# open the question edit window, populate it with info based on the clicked question's data
	_changeQuestion = (q) ->
		$('.selected').removeClass 'selected'
		$(q).addClass 'selected'
		$('.question:not(.selected)').addClass 'dim'
		qWindow = $(_qWindowTemplate).clone()

		qWindow.find('#question_text').val $.data(q).questions[0].text
		answers = $.data(q, 'answers')

		# store the original question data so we can check it for any changes later
		original_question = $.data(q).questions[0].text

		_addAnswer $(qWindow).find('#add_answer'), a for a in answers

		qWindow.find('#cancel').click () ->
			# remove question with no answers, otherwise just close window
			$(q).remove() if $.data(q, 'answers').length is 0
			$('#modal').hide()
			$('.dim').removeClass 'dim'
			$(qWindow).remove()
		qWindow.find('#done').click () ->
			# validate info, save changes
			if $('#question_text').val() is ''
				Materia.CreatorCore.alert 'Blank Question', 'You can not have a blank question!'
				return

			valid_answers = false
			new_answers = []
			changed = 0
			answer_elements = $('.answer')

			# check all answers for any changes and to make sure we can save at all
			for na in answer_elements
				original = $.data na, 'original'

				text = $(na).find('.answer_text').val()
				if text is ''
					Materia.CreatorCore.alert 'Blank Answer', 'You can not have a blank answer!'
					return
				value = parseInt($(na).find('.answer_value').val())
				valid_answers = true if value is 100

				feedback = $(na).find('.feedback_text').val()
				t_comp = text == original.text
				v_comp = parseInt(value) == parseInt(original.value)
				f_comp = original.feedback == feedback
				if original.id is '' or original_question isnt qWindow.find('#question_text').val()
					changed++
				else
					changed++ unless t_comp and v_comp and f_comp

				new_answers.push({
					'id': original.id
					'text': text,
					'value': value,
					'options':{
						'feedback': feedback,
						'letter': $(na).find('.letter').text
					}
				})

			if not valid_answers
				Materia.CreatorCore.alert 'No Correct Answer', 'You must have at least one correct answer worth 100% credit!'
				return
			$.data(q, 'questions', [{text:$('#question_text').val()}])
			if changed > 0
				$.data(q, 'answers', new_answers)
				fit_text = $('#question_text').val()
				if fit_text.length > 20
					fit_text = fit_text.substring(0, 17) + '...'
				$(q).find('.question_text').text fit_text

			$('#modal').hide()
			$('.dim').removeClass 'dim'
			$(qWindow).remove()
			if $('.step3').length > 0
				$('.step3').remove()

		qWindow.find('#add_answer').click () ->
			if $('.answer').length is _letters.length
				Materia.CreatorCore.alert 'Maximum Answers', 'You already have the maximum number of answers for this question!'
			else
				_addAnswer this
				_resetLetters()
		qWindow.find('#add_answer').keyup () ->
			$(this).click() if event.which is 13 or event.which is 32

		$('body').append qWindow
		qWindow.find('#question_text').focus()
		$('#modal').show()
		_resetLetters()

	_addAnswer = (loc, a=null) ->
		answer = $(_aTemplate).clone()
		original = {id: '', text: '', value: 0, feedback: ''}

		answer.find('.answer_remove').click () ->
			answer.remove()
			$('#add_answer').show()
			_resetLetters()

		answer.find('.answer_correct').click () ->
			if $(this).prop 'checked'
				answer.find('.answer_value').val '100%'
			else
				answer.find('.answer_value').val '0%'

		# constrain all typed values to 0 or 100, then add a % to the end
		answer.find('.answer_value').blur () ->
			value = parseInt $(this).val()
			if isNaN value
				$(this).val '0%'
			else if value > 100
				$(this).val '100%'
			else
				$(this).val value+'%'
		# spoof an unfocus, then reclick when pressing enter
		answer.find('.answer_value').keyup () ->
			if event.which is 13
				this.blur()
				this.focus()

		if a?
			original.id = a.id
			$(answer).find('.answer_text').val a.text
			original.text = a.text
			value = a.value
			original.value = a.value
			if parseInt(value) > 0
				$(answer).find('.answer_value').val value+'%'
				$(answer).find('.answer_correct').prop 'checked', true
			if a.options.feedback isnt ''
				original.feedback = a.options.feedback
				$(answer).find('.feedback_text').val a.options.feedback
				$(answer).find('.answer_feedback').show()

		$.data(answer[0], 'original', original)
		$(loc).before answer
		answer.find('.answer_text').focus()

	# change each answer's letter based on how many there are
	_resetLetters = ->
		num_answers = $('.answer').length
		if num_answers is _letters.length
			$('#add_answer').hide()

		answers = $('.answer')
		for answer, i in answers
			$(answer).find('.letter').text _letters[i]

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
