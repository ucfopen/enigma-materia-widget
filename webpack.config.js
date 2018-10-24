const path = require('path')
const srcPath = path.join(__dirname, 'src')
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')

const rules = widgetWebpack.getDefaultRules()
const entries = widgetWebpack.getDefaultEntries()

// cusomize the config
delete entries['creator.js']
delete entries['player.js']

entries['directives/enter.js'] = [path.join(srcPath, 'directives', 'enter.coffee')]
entries['directives/focus.js'] = [path.join(srcPath, 'directives', 'focus.coffee')]
entries['directives/scroll.js'] = [path.join(srcPath, 'directives', 'scroll.coffee')]

entries['modules/creator.js'] = [path.join(srcPath, 'modules', 'creator.coffee')]
entries['modules/player.js'] = [path.join(srcPath, 'modules', 'player.coffee')]

entries['controllers/creator.js'] = [path.join(srcPath, 'controllers', 'creator.coffee')]
entries['controllers/player.js'] = [path.join(srcPath, 'controllers', 'player.coffee')]

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
