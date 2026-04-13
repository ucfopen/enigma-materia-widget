// Hide default system table
Materia.ScoreCore.hideResultsTable();

const cardListElement = document.getElementById('score-card-list');
const template = document.getElementById('card-template');

const start = (instance, qset, scoreTable, isPreview, qsetVersion) => {
    update(qset, scoreTable);
}

const getRenderedHeight = () => {
    return Math.ceil(parseFloat(window.getComputedStyle(document.querySelector('html')).height)) + 10;
}

const update = (qset, scoreTable) => {
    // Check if instructor hid answers
    const showAnswers = qset && qset.options ? !qset.options.hide_correct : true;

    // CLEAR OLD CARDS
    if (cardListElement) {
        cardListElement.innerHTML = '';
    }

    // BUILD NEW CARDS
    if (scoreTable && scoreTable.length > 0) {
        
        scoreTable.forEach((row, index) => {
            const questionText = row.data[0]; 
            const userResponse = row.data[1]; 
            const correctResponse = showAnswers ? row.data[2] : "Hidden"; 
            const isCorrect = row.score === 100;

            const clone = template.content.cloneNode(true);

            const questionLabel = clone.querySelector('.question-label');
            const badge = clone.querySelector('.badge');
            const qText = clone.querySelector('.question-text');
            const userBox = clone.querySelector('.user-answer-box'); 
            const userText = clone.querySelector('.user-response-text');
            const correctText = clone.querySelector('.correct-response-text');

            questionLabel.textContent = `QUESTION ${index + 1}`;
            qText.textContent = questionText || "Question text not found";
            userText.textContent = userResponse || "No answer given";
            correctText.textContent = correctResponse || "N/A";

            if (isCorrect) {
                badge.textContent = 'Correct';
                badge.classList.add('badge-correct');
                userBox.classList.add('box-correct');
            } else {
                badge.textContent = 'Incorrect';
                badge.classList.add('badge-incorrect');
                userBox.classList.add('box-incorrect');
            }

            cardListElement.appendChild(clone); 
        });
    }

    const h = getRenderedHeight();
    Materia.ScoreCore.setHeight(h);
}

Materia.ScoreCore.start({
    start: start,
    update: update,
    handleScoreDistribution: (distribution) => {},
});