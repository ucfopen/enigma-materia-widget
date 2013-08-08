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
			_trace _qset
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
		newQ = _qTemplate.clone()
		newQ.find('.delete').click () ->
			addBtn = $(this).parent().siblings('.add')
			addBtn.show() if !$(addBtn).is(':visible')
			$(this).parent().remove()
		newQ.click () ->
			_changeQuestion this unless $(this).hasClass('dim')

		if question?
			_trace 'QUESTION: ', question
			$.data(newQ[0], 'question', question.questions[0].text)
			$.data(newQ[0], 'answers', question.answers)

		$(category).find('.add').before newQ

	_changeQuestion = (q) ->
		_trace q
		_trace $.data(q)
		$('.selected').removeClass 'selected'
		$(q).addClass 'selected'
		$('.question:not(.selected)').addClass 'dim'
		qWindow = $(_qWindowTemplate).clone()

		$(qWindow).find('button').click () ->
			if $(this).val() is 'cancel'
				#remove question with no answers, otherwise just close window
				$(q).remove()
			else
				#validate info, save changes

			$('#modal').hide()
			$(qWindow).remove()

		$('body').append qWindow
		$('#modal').show()

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