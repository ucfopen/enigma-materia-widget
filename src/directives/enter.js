/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Enigma = angular.module('enigmaCreator');

Enigma.directive('ngEnter', () => (scope, element, attrs) => element.bind("keydown keypress", function(event) {
    if (event.which === 13) {
        scope.$apply(() => scope.$eval(attrs.ngEnter));
        event.preventDefault();
        return element[0].blur();
    }
}));