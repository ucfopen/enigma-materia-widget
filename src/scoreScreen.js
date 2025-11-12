import { populateTable } from './scoreTableComponents.js';

Materia.ScoreCore.hideResultsTable();

const tbodyElement = document.getElementById('tbody');
const screenReaderTbodyElement = document.getElementById('screenReaderTbody');
const message = document.getElementById('message');

const start = (instance, qset, scoreTable, isPreview, qsetVersion) => {
	update(qset, scoreTable)
}

const getRenderedHeight = () => {
	return Math.ceil(parseFloat(window.getComputedStyle(document.querySelector('html')).height)) + 10
}

const update = (qset, scoreTable) => {
	console.log("qset is:", qset);
	console.log("scoreTable is:", scoreTable); // should include .data array

	const showAnswers = !qset.options?.hide_correct;
	console.log(qset.options?.hide_correct);

	populateTable(
		scoreTable,
		showAnswers,
		tbodyElement,
		screenReaderTbodyElement
	);

	const h = getRenderedHeight();
	Materia.ScoreCore.setHeight(h);
}

Materia.ScoreCore.start({
	start: start,
	update: update,
	handleScoreDistribution: (distribution) => {},
});

