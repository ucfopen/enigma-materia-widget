const fs = require('fs')
const path = require('path')
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')
const copy = widgetWebpack.getDefaultCopyList()

const outputPath = path.join(process.cwd(), 'build')

const customCopy = copy.concat([
	{
		from: path.join(__dirname, 'src', '_guides', 'assets'),
		to: path.join(outputPath, 'guides', 'assets'),
		toType: 'dir'
	},
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
		path.join(__dirname, 'src', '_guides', 'guideStyles.scss')
	],
	'guides/player.temp.html': [
		path.join(__dirname, 'src', '_guides', 'player.md')
	],
	'guides/creator.temp.html': [
		path.join(__dirname, 'src', '_guides', 'creator.md')
	]
}

const options = {
	copyList: customCopy,
	entries: entries
}

let buildConfig = widgetWebpack.getLegacyWidgetBuildConfig(options)
module.exports = buildConfig

// module.exports = widgetWebpack.getLegacyWidgetBuildConfig(options)
