describe('Enigma', function() {

	var $compiler = null;
	var $scope = {};
	var element = null;

	describe('scrollUp Directive', function() {
		var $timeout = null;
		beforeEach(module('enigmaPlayer'));

		beforeEach(inject(function($compile, $rootScope, _$timeout_){
			$timeout = _$timeout_;
			$compiler = $compile;
			$scope = $rootScope.$new();
		}));

		it('should run appropriate window methods when necessary', function(){
			spyOn(window.parent, 'scrollTo');
			//this would normally return an object with a lot of useful properties - we only care about one for now
			spyOn(window.parent.document, 'getElementById').and.callFake(function(){
				return {offsetTop: 0};
			});

			//set up a one-off variable we can use to test the directive's functionality
			$scope.activate = false;

			//all this directive needs to do is call 'scrollTo' on window.parent
			//simplest test - have an element on the page using this directive that will activate when a value is 'true'
			element = $compiler(angular.element('<div scroll-up="activate"></div>'))($scope);
			$scope.$digest();

			//toggle the control variable
			$scope.activate = true;
			$scope.$digest();

			//directive has a quick timeout before it executes the action
			$timeout.flush();

			//make sure all the methods were called that should have been
			//in this case we gave it an object with an 'offsetTop' of 0
			//so it should have tried scrolling to 0, 0
			expect(window.parent.scrollTo).toHaveBeenCalledWith(0, 0);
			expect(window.parent.document.getElementById).toHaveBeenCalledWith('container');
		});
	});

	describe('focusMe Directive', function(){
		var $timeout = null;
		beforeEach(module('enigmaCreator'));

		beforeEach(inject(function($compile, $rootScope, _$timeout_){
			$timeout = _$timeout_;
			$compiler = $compile;
			$scope = $rootScope.$new();
		}));

		it('should focus given elements when appropriate', function(){
			$scope.activate = false;

			element = $compiler(angular.element('<div focus-me="activate"></div>'))($scope);
			$scope.$digest();

			spyOn(element[0], 'focus');
			$scope.activate = true;
			$scope.$digest();
			$timeout.flush();

			//make sure the element was given focus
			expect(element[0].focus).toHaveBeenCalled();
		});
	});

	describe('ngEnter Directive', function(){
		beforeEach(module('enigmaCreator'));

		beforeEach(inject(function($compile, $rootScope){
			$compiler = $compile;
			$scope = $rootScope.$new();
		}));

		beforeEach(function(){
			element = $compiler(angular.element('<input ng-enter/>'))($scope);
			$scope.$digest();
		});

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
});