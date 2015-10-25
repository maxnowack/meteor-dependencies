Template.Package.helpers
  package: ->
    MeteorPackages.Packages.findOne name: Router.current().getParams().pkgname
