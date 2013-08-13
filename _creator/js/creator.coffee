Namespace('test').Creator = do ->
	_widget  = null # holds widget data
	_qset    = null # Keep tack of the current qset
	_title   = null # hold on to this instance's title
	_version = null # holds the qset version, allows you to change your widget to support old versions of your own code
	# variables to contain templates for various page elements
	_catTemplate = null
	_qTemplate = null
	_qWindowTemplate = null
	_aTemplate = null

	initNewWidget = (widget, baseUrl) ->
		_buildDisplay 'New Enigma Widget', widget

	initExistingWidget = (title, widget, qset, version, baseUrl) ->
		_buildDisplay title, widget, qset, version

	onSaveClicked = (mode = 'save') ->
		if _buildSaveData()
			Materia.CreatorCore.save _title, _qset
		else
			Materia.CreatorCore.cancelSave 'Widget not ready to save.'

	onSaveComplete = (title, widget, qset, version) ->
		_trace 'save complete!', title, widget, qset, version

	onQuestionImportComplete = (questions) ->
		_trace 'questions are here!', questions

	# Enigma does not support media
	onMediaImportComplete = (media) -> null

	_buildDisplay = (title = 'Default test Title', widget, qset, version) ->
		_version = version
		_qset    = qset
		_widget  = widget
		_title   = title

		$('#title').val _title

		#fill the template objects
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

		$('#add_category_button').click -> _addCategory()

		if _qset?
			$('#randomize').prop 'checked', _qset.options.randomize
			categories = _qset.items
			_addCategory category for category in categories

	_buildSaveData = ->
		okToSave = false
		# update our values
		_title = $('#title').val()
		_qset.options.randomize = $('#randomize').prop 'checked'
		okToSave = true if _title? && _title!= ''

		items = []
		_qset.options.randomize = $('#randomize').prop 'checked'

		categories = $('.category')

		for c in categories
			category = _process c
			items.push category

		_qset.items = items

		okToSave

	_process = (c) ->
		c = $(c)
		category = {name: '', items: []}
		category.name = c.find('textarea').val()
		items = []
		questions = c.find('.question')
		for q in questions
			question = $.data(q)
			items.push question

		category.items = items

		category

	_addCategory = (category) ->
		newCat = $(_catTemplate).clone()
		$(newCat).click () ->
			$('.active').removeClass 'active'
			$(this).addClass 'active'

		newCat.find('.add').click () ->
			numKids = $(this).parent().children().length
			unless numKids > 8
				$(this).hide() if numKids is 8
				_addQuestion $(this).parent()
		newCat.find('.delete').click ->
			$(this).parent().remove()

		if category?
			newCat.find('textarea').val(category.name)
			questions = category.items
			_addQuestion newCat, question for question in questions

		$('#question_container').append newCat

	_addQuestion = (category, question=null) ->
		#create a new question element and default its pertinent data
		newQ = _qTemplate.clone()
		$.data(newQ[0], 'questions', [{text: ''}])
		$.data(newQ[0], 'answers', [])

		newQ.find('.delete').click () ->
			addBtn = $(this).parent().siblings('.add')
			addBtn.show() if !$(addBtn).is(':visible')
			$(this).parent().remove()
		newQ.click () ->
			_changeQuestion this unless $(this).hasClass('dim')

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

	_changeQuestion = (q) ->
		$('.selected').removeClass 'selected'
		$(q).addClass 'selected'
		$('.question:not(.selected)').addClass 'dim'
		qWindow = $(_qWindowTemplate).clone()

		qWindow.find('#question_text').val $.data(q).questions[0].text
		answers = $.data(q, 'answers')

		original_question = $.data(q).questions[0].text

		_addAnswer $(qWindow).find('#add_answer'), a for a in answers

		qWindow.find('#cancel').click () ->
			#remove question with no answers, otherwise just close window
			$(q).remove() if $.data(q, 'answers').length is 0
			$('#modal').hide()
			$('.dim').removeClass 'dim'
			$(qWindow).remove()
		qWindow.find('#done').click () ->
			#validate info, save changes
			if $('#question_text').val() is ''
				alert 'You can not have a blank question!'
				return

			valid_answers = false
			new_answers = []
			changed = 0
			answer_elements = $('.answer')

			for na in answer_elements
				original = $.data na, 'original'

				text = $(na).find('.answer_text').val()
				# automatically remove empty answers instead?
				if text is ''
					alert 'You can not have a blank answer!'
					return
				value = parseInt($(na).find('.answer_value').val())
				valid_answers = true if value is 100

				feedback = $(na).find('.feedback_text').val()
				t_comp = text == original.text
				v_comp = parseInt(value) == parseInt(original.value)
				f_comp = original.feedback == feedback
				if original.id < 0 or original_question isnt qWindow.find('#question_text').val()
					changed++
				else
					changed++ unless t_comp and v_comp and f_comp

				new_answers.push({
					'id': original.id
					'text': text,
					'value': value,
					'options':{
						'feedback': feedback
					}
				})

			if not valid_answers
				alert 'You must have at least one correct answer worth 100% credit!'
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

		$(qWindow).find('#add_answer').click () ->
			_addAnswer this

		$('body').append qWindow
		$('#modal').show()

	_addAnswer = (loc, a=null) ->
		answer = $(_aTemplate).clone()
		original = {id: -1, text: '', value: 0, feedback: ''}

		# these tweens don't seem to be working yet, figure them out
		answer.click () ->
			previously_selected = $('.answer_selected')
			unless previously_selected[0] is answer[0]
				if previously_selected.find('.feedback_text').val() is ''
					previously_selected.find('.answer_feedback').slideUp()
				previously_selected.removeClass('answer_selected')
				answer.addClass('answer_selected')
				answer.find('.answer_feedback').slideDown()
		answer.find('answer_remove').click () ->
			answer.remove()

		answer.find('.answer_correct').click () ->
			if $(this).prop 'checked'
				answer.find('.answer_value').val '100%'
			else
				answer.find('.answer_value').val '0%'

		#need a function in here somewhere to make sure all numbers given are between 0 and 100
		answer.find('.answer_value').blur () ->
			value = parseInt $(this).val()
			if isNaN value
				$(this).val '0%'
			else if value > 100
				$(this).val '100%'
			else
				$(this).val value+'%'
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

	_trace = ->
		if console? && console.log?
			console.log.apply console, arguments

	#public
	initNewWidget: initNewWidget
	initExistingWidget: initExistingWidget
	onSaveClicked:onSaveClicked
	onMediaImportComplete:onMediaImportComplete
	onQuestionImportComplete:onQuestionImportComplete
	onSaveComplete:onSaveComplete