/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Enigma = angular.module('enigmaCreator');

Enigma.directive('focusMe', ['$timeout', '$parse', ($timeout, $parse) => ({
    link(scope, element, attrs) {
        const model = $parse(attrs.focusMe);
        return scope.$watch(model, function(value) {
            if (value) {
                $timeout(() => element[0].focus());
            }
            return value;
        });
    }
})
]);
