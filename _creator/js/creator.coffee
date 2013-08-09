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
		$.data(newQ[0], 'question', '')
		$.data(newQ[0], 'answers', [])

		newQ.find('.delete').click () ->
			addBtn = $(this).parent().siblings('.add')
			addBtn.show() if !$(addBtn).is(':visible')
			$(this).parent().remove()
		newQ.click () ->
			_changeQuestion this unless $(this).hasClass('dim')

		if question?
			$.data(newQ[0], 'question', question.questions[0].text)
			$.data(newQ[0], 'answers', question.answers)

		$(category).find('.add').before newQ

	_changeQuestion = (q) ->
		$('.selected').removeClass 'selected'
		$(q).addClass 'selected'
		$('.question:not(.selected)').addClass 'dim'
		qWindow = $(_qWindowTemplate).clone()

		$(qWindow).find('#question_text').val $.data(q, 'question')
		answers = $.data(q, 'answers')

		_addAnswer $(qWindow).find('#add_answer'), a for a in answers

		$('#cancel').click () ->
			#remove question with no answers, otherwise just close window
			$(q).remove() if $.data(q, 'answers').length is 0
		$('#done').click () ->
			#validate info, save changes
			#validation:
			#	question text must be set
			#	all answer texts must be set
			#		automatically remove empty answers?
			#	must have at least one correct answer
			#	at least one correct answer must have 100% value
			if $('#question_text').val() is ''
				alert 'You can not have an empty question!'
				return
			new_answers = $('.answer')
			_trace 'Answers:', new_answers

			$('#modal').hide()
			$(qWindow).remove()

		$(qWindow).find('#add_answer').click () ->
			_addAnswer this

		$('body').append qWindow
		$('#modal').show()

	_addAnswer = (loc, a=null) ->
		answer = $(_aTemplate).clone()
		answer.find('.answer_feedback').hide()

		answer.focus () ->
			$(answer).find('.answer_feedback').slideDown()
		answer.blur () ->
			$(answer).find('.answer_feedback').hide()
		answer.find('answer_remove').click () ->
			answer.remove()

		if a?
			$(answer).find('.answer_text').val a.text
			value = a.value
			if parseInt(value) > 0
				$(answer).find('.answer_value').val value+'%'
				$(answer).find('.answer_correct').prop 'checked', true
			if a.options.feedback isnt ''
				$(answer).find('.feedback_text').val a.options.feedback
				$(answer).find('.answer_feedback').show()

		$(loc).before answer

	_buildSaveData = ->
		okToSave = false
		# update our values
		_title = $('#title').val()
		_qset.options.randomize = $('#randomize').prop 'checked'
		okToSave = true if _title? && _title!= ''

		okToSave

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