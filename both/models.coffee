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
      version: @latestVersion.version

  outdated: (constraint, checked = []) ->
    unless @latestVersion?
      syncUpdate = Meteor.wrapAsync @updateAtmo, this
      syncUpdate()
      console.log @name
    if constraint?
      alternatives = PackageVersion.parseVersionConstraint(constraint).alternatives
      versions = alternatives.map (version) -> version.versionString
      uptodate = false
      versions.forEach (version) =>
        myVersion = PackageVersion.parse @latestVersion.version
        version = PackageVersion.parse version
        uptodate = true if myVersion.major is version.major
      return true unless uptodate

    currentVersion = @currentVersion()
    checked.push @name
    for name, dep of currentVersion.metadata.dependencies
      continue if name in checked
      continue unless name.indexOf(':') > -1
      console.log @name, name
      pkg = Pkg.getByName name
      return true if pkg.outdated dep.constraint, checked
    return false

  status: ->
    return {text: 'package not found', color: 'red'} unless @lastUpdated?
    if @outdated()
      text: 'outdated'
      color: 'orange'
    else
      text: 'up to date'
      color: 'brightgreen'
