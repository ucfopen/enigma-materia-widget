describe('scrollUp Directive', function() {
	require('angular/angular.js');
	require('angular-mocks/angular-mocks.js');

	var $scope
	var $compile
	var $timeout

	beforeEach(() => {
		jest.resetModules()

		// mock materia
		global.Materia = {
			Engine: {
				setVerticalScroll: jest.fn()
			}
		}

		// load the required code
		angular.mock.module('enigmaPlayer')
		require('../modules/player.coffee')
		require('./scroll.coffee')

		// initialize the angualr controller
		inject(function(_$compile_, _$controller_, _$timeout_, _$rootScope_){
			$timeout = _$timeout_;
			$compile = _$compile_
			$scope = _$rootScope_.$new();
		})
	})

	it('should run appropriate window methods when necessary', function(){
		//set up a one-off variable we can use to test the directive's functionality
		$scope.activate = false;

		//all this directive needs to do is call 'scrollTo' on window.parent
		//simplest test - have an element on the page using this directive that will activate when a value is 'true'
		element = $compile(angular.element('<div scroll-up="activate"></div>'))($scope);
		$scope.$digest();

		//toggle the control variable
		$scope.activate = true;
		$scope.$digest();

		//directive has a quick timeout before it executes the action
		$timeout.flush();

		//make sure all the methods were called that should have been
		//in this case we gave it an object with an 'offsetTop' of 0
		//so it should have tried scrolling to 0, 0
		expect(Materia.Engine.setVerticalScroll).toHaveBeenCalledWith(0);
	});
});
