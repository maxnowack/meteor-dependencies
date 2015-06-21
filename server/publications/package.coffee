Meteor.publish 'package', (name) ->
  return @ready() unless name?
  check name, String

  pkg = Pkg.getByName name
  currentVersion = pkg.currentVersion()

  names = (packageName for packageName of currentVersion?.metadata?.dependencies)
  names = _.filter names, (packageName) -> packageName.indexOf(':') > -1
  names.push name

  [
    Packages.find(name: $in: names),
    Versions.find(_id: currentVersion._id)
  ]
