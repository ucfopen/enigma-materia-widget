describe('ngEnter Directive', function(){
	require('angular/angular.js');
	require('angular-mocks/angular-mocks.js');

	var $scope
	var $compile
	var $timeout
	var element

	beforeEach(() => {
		jest.resetModules()

		// load the required code
		angular.mock.module('enigmaCreator')
		angular.module('dndLists', [])
		require('../modules/creator.coffee')
		require('./enter.coffee')

		// initialize the angualr controller
		inject(function(_$compile_, _$controller_, _$timeout_, _$rootScope_){
			$timeout = _$timeout_;
			$compile = _$compile_
			$scope = _$rootScope_.$new();
		})

		element = $compile(angular.element('<input ng-enter/>'))($scope);
		$scope.$digest();
	})

	function keyPress(code) {
		var e = document.createEvent('Events');
		e.initEvent('keydown', true, false);
		e.which = code;
		return e;
	}

	it('should allow non-enter keypresses to function normally', function(){
		//test with the 'a' key
		e = keyPress(65);
		spyOn(e, 'preventDefault');
		element.triggerHandler(e);
		expect(e.preventDefault).not.toHaveBeenCalled();

		//test with the 'backspace' key
		e.which = 8;
		element.triggerHandler(e);
		expect(e.preventDefault).not.toHaveBeenCalled();
	});

	it('should prevent default behavior when the enter key is pressed', function(){
		//spoof pressing the 'Enter' key on the input element
		e = keyPress(13);
		spyOn(e, 'preventDefault');
		element.triggerHandler(e);
		expect(e.preventDefault).toHaveBeenCalled();
	});

	it('should blur the element when the enter key is pressed', function(){
		spyOn(element[0], 'blur');

		e = keyPress(13);
		element.triggerHandler(e);

		expect(element[0].blur).toHaveBeenCalled();
	});
});
