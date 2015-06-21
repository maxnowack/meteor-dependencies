Router.configure
  layoutTemplate: 'MasterLayout'

Router.route '/:pkgname', name: 'package'

getSvg = (status) ->
  HTTP.get "https://img.shields.io/badge/dependencies-#{encodeURIComponent status.text}-#{status.color}.svg"

Router.route '/:pkgname.svg', ->
  pkg = Pkg.getByName @params.pkgname
  @response.setHeader 'content-type', 'image/svg+xml'
  svg = getSvg pkg.status()
  @response.end svg.content
, where: 'server'
