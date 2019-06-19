const fs = require('fs')
const path = require('path')
const HtmlWebpackPlugin = require('html-webpack-plugin')
const marked = require('meta-marked')
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')
const rules = widgetWebpack.getDefaultRules()
const copy = widgetWebpack.getDefaultCopyList()

const srcPath = path.join(process.cwd(), 'src')
const outputPath = path.join(process.cwd(), 'build')

const customCopy = copy.concat([
	{
		from: `${srcPath}/_helper-docs/assets`,
		to: `${outputPath}/guides/assets`,
		toType: 'dir'
	}
])

const entries = {
	'creator.js': [
		path.join(__dirname, 'src', 'directives/enter.coffee'),
		path.join(__dirname, 'src', 'directives/focus.coffee'),
		path.join(__dirname, 'src', 'modules/creator.coffee'),
		path.join(__dirname, 'src', 'controllers/creator.coffee')
	],
	'player.js': [
		path.join(__dirname, 'src', 'modules/player.coffee'),
		path.join(__dirname, 'src', 'directives/scroll.coffee'),
		path.join(__dirname, 'src', 'controllers/player.coffee')
	],
	'creator.css': [
		path.join(__dirname, 'src', 'creator.html'),
		path.join(__dirname, 'src', 'creator.scss')
	],
	'player.css': [
		path.join(__dirname, 'src', 'player.html'),
		path.join(__dirname, 'src', 'player.scss')
	],
	'guides/guideStyles.css': [
		path.join(__dirname, 'src', '_helper-docs', 'guideStyles.scss')
	]
}

const options = {
	copyList: customCopy,
	entries: entries
}

const generateHelperPlugin = name => {
	const file = fs.readFileSync(path.join(__dirname, 'src', '_helper-docs', name+'.md'), 'utf8')
	const content = marked(file)

	return new HtmlWebpackPlugin({
		template: path.join(__dirname, 'src', '_helper-docs', 'helperTemplate'),
		filename: path.join(outputPath, 'guides', name+'.html'),
		title: name.charAt(0).toUpperCase() + name.slice(1),
		chunks: ['guides'],
		content: content.html
	})
}

let buildConfig = widgetWebpack.getLegacyWidgetBuildConfig(options)

buildConfig.plugins.unshift(generateHelperPlugin('creator'))
buildConfig.plugins.unshift(generateHelperPlugin('player'))

module.exports = buildConfig

// module.exports = widgetWebpack.getLegacyWidgetBuildConfig(options)
