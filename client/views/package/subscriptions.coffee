Template.Package.onCreated ->
  @autorun =>
    @subscribe 'package', Router.current().getParams().pkgname
