const path = require('path')
const srcPath = path.join(__dirname, 'src') + path.sep
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')

const rules = widgetWebpack.getDefaultRules()
const entries = widgetWebpack.getDefaultEntries()

// cusomize entries
entries['creator.js'] = [
	srcPath + 'modules/creator.coffee',
	srcPath + 'directives/enter.coffee',
	srcPath + 'directives/focus.coffee',
	srcPath + 'controllers/creator.coffee'
]

entries['player.js'] = [
	srcPath + 'modules/player.coffee',
	srcPath + 'directives/scroll.coffee',
	srcPath + 'controllers/player.coffee'
]

// this is needed to prevent html-loader from causing issues with
// style tags in the player using angular
let customHTMLAndReplaceRule = {
	test: /\.html$/i,
	exclude: /node_modules/,
	use: [
		{
			loader: 'file-loader',
			options: { name: '[name].html' }
		},
		{
			loader: 'extract-loader'
		},
		{
			loader: 'string-replace-loader',
			options: { multiple: widgetWebpack.materiaJSReplacements }
		},
		{
			loader: 'html-loader',
			options: {
				minifyCSS: false
			}
		}
	]
}

let customRules = [
	rules.loaderDoNothingToJs,
	rules.loaderCompileCoffee,
	rules.copyImages,
	customHTMLAndReplaceRule, // <--- replaces "rules.loadHTMLAndReplaceMateriaScripts"
	rules.loadAndPrefixCSS,
	rules.loadAndPrefixSASS,
]

// options for the build
let options = {
	entries: entries,
	moduleRules: customRules
}

module.exports = widgetWebpack.getLegacyWidgetBuildConfig(options)
