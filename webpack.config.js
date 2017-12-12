const path = require('path')

// load the reusable legacy webpack config from materia-widget-dev
let webpackConfig = require('materia-widget-development-kit/webpack-widget').getLegacyWidgetBuildConfig()

// cusomize the config
delete webpackConfig.entry['creator.js']
delete webpackConfig.entry['player.js']

webpackConfig.entry['directives/enter.js'] = [path.join(__dirname, 'src', 'directives', 'enter.coffee')]
webpackConfig.entry['directives/focus.js'] = [path.join(__dirname, 'src', 'directives', 'focus.coffee')]
webpackConfig.entry['directives/scroll.js'] = [path.join(__dirname, 'src', 'directives', 'scroll.coffee')]

webpackConfig.entry['modules/creator.js'] = [path.join(__dirname, 'src', 'modules', 'creator.coffee')]
webpackConfig.entry['modules/player.js'] = [path.join(__dirname, 'src', 'modules', 'player.coffee')]

webpackConfig.entry['controllers/creator.js'] = [path.join(__dirname, 'src', 'controllers', 'creator.coffee')]
webpackConfig.entry['controllers/player.js'] = [path.join(__dirname, 'src', 'controllers', 'player.coffee')]

module.exports = webpackConfig
