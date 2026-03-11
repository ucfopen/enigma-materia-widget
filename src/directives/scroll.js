const Enigma = angular.module('enigmaPlayer');

Enigma.directive('scrollUp', ['$timeout', '$parse', ($timeout, $parse) => ({
    link(scope, element, attrs) {
        const model = $parse(attrs.scrollUp);
        scope.$watch(model, function(value) {
            if (value) {
                $timeout(() => //scroll the containing page to the top of the iframe the widget is sitting in
                Materia.Engine.setVerticalScroll(0));
            }
            return value;
        });
    }
})
]);
