const path = require('path')
const srcPath = path.join(__dirname, 'src')
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')

const rules = widgetWebpack.getDefaultRules()
const entries = widgetWebpack.getDefaultEntries()

// cusomize entries
entries['creator.js'] = [
	path.join(__dirname, 'src', 'modules', 'creator.coffee'),
	path.join(__dirname, 'src', 'directives', 'enter.coffee'),
	path.join(__dirname, 'src', 'directives', 'focus.coffee'),
	path.join(__dirname, 'src', 'controllers', 'creator.coffee')
]

entries['player.js'] = [
	path.join(__dirname, 'src', 'modules', 'player.coffee'),
	path.join(__dirname, 'src', 'directives', 'scroll.coffee'),
	path.join(__dirname, 'src', 'controllers', 'player.coffee')
]

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

const ourFinalWebpackConfig = widgetWebpack.getLegacyWidgetBuildConfig(options)

module.exports = ourFinalWebpackConfig
