Template.Package.helpers
  package: ->
    Packages.findOne name: Router.current().getParams().pkgname
