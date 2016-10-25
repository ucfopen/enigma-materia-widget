module.exports = function(config) {
	config.set({

		autoWatch: false,

		basePath: './',

		browsers: ['PhantomJS'],

		files: [
			'../../js/*.js',
			'node_modules/angular/angular.js',
			'node_modules/angular-mocks/angular-mocks.js',
			'build/demo.json',
			'build/modules/*.js',
			'build/controllers/*.js',
			'tests/*.js'
		],

		frameworks: ['jasmine'],

		plugins: [
			'karma-coverage',
			'karma-eslint',
			'karma-jasmine',
			'karma-json-fixtures-preprocessor',
			'karma-mocha-reporter',
			'karma-phantomjs-launcher'
		],

		preprocessors: {
			'build/controllers/*.js': ['coverage', 'eslint'],
			'build/demo.json': ['json_fixtures']
		},

		singleRun: true,

		//plugin-specific configurations
		eslint: {
			stopOnError: true,
			stopOnWarning: false,
			showWarnings: true,
			engine: {
				configFile: '.eslintrc.json'
			}
		},

		jsonFixturesPreprocessor: {
			variableName: '__demo__'
		},

		reporters: ['coverage', 'mocha'],

		//reporter-specific configurations

		coverageReporter: {
			check: {
				global: {
					statements: 100,
					branches:   80,
					functions:  90,
					lines:      90
				},
				each: {
					statements: 100,
					branches:   80,
					functions:  90,
					lines:      90
				}
			},
			reporters: [
				{ type: 'cobertura', subdir: '.', file: 'coverage.xml' }
			]
		}

	});
};
