client = {}

describe 'Testing framework', ->
	it 'should load widget', (done) ->
		require('./widgets.coffee') 'enigma', ->
			client = this
			done()
	, 15000

describe 'Main page', ->
	it 'should have a title', (done) ->
		client
			.getText '.header h1 span', (err, text) ->
				expect(text).toContain("TV Show Trivia")
				done()

	it 'should have three categories', (done) ->
		client
			.getText '.category .title', (err, text) ->
				expect(text).toContain("Animated TV")
			.getText '.category:nth-child(2) .title', (err, text) ->
				expect(text).toContain("Sitcoms")
			.getText '.category:nth-child(3) .title', (err, text) ->
				expect(text).toContain("Game Shows")
			.call(done)

	it 'should have nine questions', (done) ->
		client
			.execute 'return $(".question").length;', (err, result) ->
				expect(result.value).toBe(9)
			.call(done)

	it 'should show a popup when question is clicked', (done) ->
		client
			.execute "$('.question:first').click()", (err) ->
				client
					.waitFor '.question-popup.shown h1', 3000
					.getText '.question-popup.shown h1', (err, text) ->
						expect(text).toContain("QUESTION 1 IN \"ANIMATED TV\"")
					.waitFor '.question-text', 3000
					.getText '.question-text', (err, text) ->
						expect(text).toContain("The Simpsons takes place in what fictional town?")
						done()

	it 'should be able to choose C', (done) ->
		client
			.execute "$('#answer-2').click()", (err) ->
				done()

	it 'should be able to submit final answer', (done) ->
		client
			.execute "$('.menu button.submit').click()", (err) ->
				done()

	it 'should be able to close popup', (done) ->
		client
			.execute "$('.menu .return.highlight').click()", (err) ->
				done()

	it 'should be able answer all the questions', (done) ->
		i = 1
		f = ->
			client.execute "$('.question:eq(" + i + ")').click()", (err) ->
				client.execute "$('#answer-1').click()", (err) ->
					client.execute "$('.menu .submit').click()", (err) ->
						client.execute "$('.menu .return.highlight').click()", (err) ->
							i++
							if i < 10
								f()
							else
								done()
		f()

	it 'should get 33%', (done) ->
		client
			.waitFor '.notice .value', 3000
			.getText '.notice .value', (err, text) ->
				expect(text).toContain("33")
				done()

	it 'should be able to close widget', (done) ->
		client
			.execute "$('.notice button').click()", (err) ->
				done()

describe 'Score page', ->
	it 'should get a 33', (done) ->
		client.pause(2500)
		client.getTitle (err, title) ->
			expect(title).toBe('Score Results | Materia')
			client
				.waitForVisible('.overall-score, .overall_score')
				.getText '.overall-score, .overall_score', (err, text) ->
					expect(text).toBe('33%')
					client.call(done)
					client.end()



