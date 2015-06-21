UpdateStatus =
  upToDate: 100
  outdatedBuild: 20
  outdatedMinor: 10
  outdatedMajor: 0

@Packages = new Mongo.Collection 'packages'
@Versions = new Mongo.Collection 'versions'

class @Pkg extends DocumentClass.Base
  @isTransformOf Packages

  @getByName: (name) ->
    pkg = Packages.findOne name: name
    unless pkg?
      Packages.insert name: name
      pkg = Packages.findOne name: name
      syncUpdate = Meteor.wrapAsync pkg.updateAtmo, pkg
      return syncUpdate()
    return pkg

  updateAtmo: (options = {}) ->
    callback = options if typeof options is 'function'
    connection = options.connection or DDP.connect('https://atmospherejs.com')
    packages = options.packages or new Mongo.Collection 'packages', connection: connection
    versions = options.versions or new Mongo.Collection 'versions', connection: connection

    sub = connection.subscribe 'package', @name, =>
      pkg = packages.findOne name: @name
      return unless pkg
      delete pkg._id
      Packages.upsert @_id, pkg
      versions.find(packageName: @name).forEach (version) ->
        Versions.upsert version._id, version
      sub.stop()
      if callback then callback null, Packages.findOne @_id

  currentVersion: ->
    Versions.findOne
      packageName: @name
      version: @latestVersion?.version

  updateStatus: (constraint, checked = []) ->
    unless @latestVersion?
      syncUpdate = Meteor.wrapAsync @updateAtmo, this
      syncUpdate()
    if constraint?
      versionConstraint = PackageVersion.parseVersionConstraint(constraint)
      alternatives = versionConstraint.alternatives
      versions = alternatives.map (version) -> version.versionString
      status = versions.map (version) =>
        myVersion = PackageVersion.parse @latestVersion.version
        version = PackageVersion.parse version
        if myVersion.major isnt version.major
          return UpdateStatus.outdatedMajor
        else if myVersion.minor isnt version.minor
          return UpdateStatus.outdatedMinor
        else if myVersion.build isnt version.build
          return UpdateStatus.outdatedBuild
        else
          return UpdateStatus.upToDate
      highestStatus = status.sort()[0]
      return highestStatus unless highestStatus is UpdateStatus.upToDate

    currentVersion = @currentVersion()
    checked.push @name
    status = []
    for name, dep of currentVersion.metadata.dependencies
      continue if name in checked
      continue if name.indexOf(':') is -1
      pkg = Pkg.getByName name
      status.push pkg.updateStatus dep.constraint, checked
    return status.sort()[0] or UpdateStatus.upToDate

  status: ->
    return {text: 'package not found', color: 'red'} unless @lastUpdated?
    updateStatus = @updateStatus()
    if updateStatus is UpdateStatus.outdatedMajor
      text: 'outdated'
      color: 'orange'
    else if updateStatus is UpdateStatus.outdatedMinor
      text: 'up to date'
      color: 'yellow'
    else if updateStatus is UpdateStatus.outdatedBuild
      text: 'up to date'
      color: 'yellowgreen'
    else if updateStatus is UpdateStatus.upToDate
      text: 'up to date'
      color: 'brightgreen'

  dependencies: ->
    currentVersion = @currentVersion()
    names = (name for name of currentVersion?.metadata?.dependencies)
    names = _.filter names, (name) -> name.indexOf(':') > -1
    Packages.find(name: $in: names)

  getDepVersion: (name) ->
    @currentVersion()?.metadata?.dependencies[name].constraint
