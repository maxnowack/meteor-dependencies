Meteor.publish 'package', (name) ->
  return @ready() unless name?
  check name, String

  pkg = Pkg.getByName name
  currentVersion = pkg.currentVersion()

  names = (dep.packageName for dep in currentVersion?.dependencies)
  names = _.filter names, Pkg.filterDeps
  names.push name

  [
    MeteorPackages.Packages.find(name: $in: names),
    MeteorPackages.LatestPackages.find(packageName: $in: names),
    MeteorPackages.Versions.find(packageName: $in: names)
  ]
