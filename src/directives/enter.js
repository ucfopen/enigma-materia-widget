const Enigma = angular.module('enigmaCreator');

Enigma.directive('ngEnter', () => (scope, element, attrs) => element.bind("keydown keypress", function(event) {
    if (event.which === 13) {
        scope.$apply(() => scope.$eval(attrs.ngEnter));
        event.preventDefault();
        element[0].blur();
    }
}));
