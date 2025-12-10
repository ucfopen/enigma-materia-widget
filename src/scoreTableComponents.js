/** @param {Array} scoreTable
 * @param {boolean} showAnswers
 * @param {HTMLElement} tbodyElement
 * @param {HTMLElement} screenReaderTbodyElement */
export function populateTable(
	scoreTable,
	showAnswers,
	tbodyElement,
	screenReaderTbodyElement
) {
	tbodyElement.innerHTML = '';
	screenReaderTbodyElement.innerHTML = '';

	for (let i = 0; i < scoreTable.length; i++) {
		const entry = scoreTable[i];
		const [questionText, userAnswer, correctAnswer] = entry.data;

		const row = document.createElement('tr');

		// Question #
		const numberCell = document.createElement('td');
		numberCell.textContent = `#${i + 1}`;
		row.appendChild(numberCell);

		// Question text
		const questionCell = document.createElement('td');
		questionCell.textContent = questionText;
		row.appendChild(questionCell);

		// User response
		const userResponseCell = document.createElement('td');
		if (!userAnswer || userAnswer.trim() === '') {
			userResponseCell.textContent = '(No answer given)';
			userResponseCell.classList.add('no-answer');
		} else {
			userResponseCell.textContent = userAnswer;
			if (entry.score === 100) {
				userResponseCell.classList.add('correct-answer'); // green
			} else {
				userResponseCell.classList.add('wrong-answer'); // red
			}
		}
		row.appendChild(userResponseCell);


		// Correct answer
		const correctAnswerCell = document.createElement('td');
		if (showAnswers || entry.score === 100) {
			correctAnswerCell.textContent = correctAnswer || '(N/A)';
		}
		else {
			correctAnswerCell.textContent = 'Hidden';
		}
		row.appendChild(correctAnswerCell);

		tbodyElement.appendChild(row);

		// Screen reader table
		const srRow = document.createElement('tr');
		srRow.innerHTML = `
			<td>${entry.score}</td>
			<td>N/A</td>
			<td>${userAnswer || '(No answer)'}</td>
			<td>${showAnswers ? correctAnswer || '(N/A)' : 'Hidden'}</td>
		`;
		screenReaderTbodyElement.appendChild(srRow);
	}
}

