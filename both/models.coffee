sortNumber = (a,b) -> a - b

UpdateStatus =
  upToDate: 100
  outdatedPatch: 20
  outdatedMinor: 10
  outdatedMajor: 0

class @Pkg extends DocumentClass.Base
  @isTransformOf MeteorPackages.Packages

  @getByName: (name) ->
    MeteorPackages.Packages.findOne name: name

  @filterDeps: (name) ->
    name.indexOf(':') > -1

  currentVersion: ->
    latest = MeteorPackages.LatestPackages.findOne {packageName: @name}, sort: lastUpdated: -1
    MeteorPackages.Versions.findOne
      packageName: @name
      version: latest?.version

  getUpdateStatus: (constraint, checked = []) ->
    if constraint?
      diff = @diffConstraint constraint
      return diff unless diff is UpdateStatus.upToDate

    currentVersion = @currentVersion()
    checked.push @name
    status = []
    for dep in currentVersion?.dependencies
      continue if dep.packageName in checked
      continue unless Pkg.filterDeps(dep.packageName)
      pkg = Pkg.getByName dep.packageName
      continue unless pkg?
      status.push pkg.getUpdateStatus dep.constraint, checked
    return status.sort(sortNumber)[0] or UpdateStatus.upToDate

  diffConstraint: (constraint) ->
    versionConstraint = PackageVersion.parseVersionConstraint(constraint)
    alternatives = versionConstraint.alternatives
    versions = alternatives.map (version) -> version.versionString
    status = versions.map (version) =>
      return unless currentVersion = @currentVersion()
      myVersion = PackageVersion.parse currentVersion.version
      version = PackageVersion.parse version
      if myVersion.major isnt version.major
        return UpdateStatus.outdatedMajor
      else if myVersion.minor isnt version.minor
        return UpdateStatus.outdatedMinor
      else if myVersion.patch isnt version.patch
        return UpdateStatus.outdatedPatch
      else
        return UpdateStatus.upToDate
    highestStatus = status.sort(sortNumber).reverse()[0]
    return highestStatus

  getDepStatus: (name) ->
    constraint = @getDepVersion(name).constraint
    dep = Pkg.getByName name
    return dep.diffConstraint constraint

  status: ->
    return {text: 'package not found', color: 'red'} unless @lastUpdated?
    updateStatus = @getUpdateStatus()
    if updateStatus is UpdateStatus.outdatedMajor
      text: 'outdated'
      color: 'orange'
    else if updateStatus is UpdateStatus.outdatedMinor
      text: 'up to date'
      color: 'yellowgreen'
    else if updateStatus is UpdateStatus.outdatedPatch
      text: 'up to date'
      color: 'green'
    else if updateStatus is UpdateStatus.upToDate
      text: 'up to date'
      color: 'brightgreen'

  dependencies: ->
    currentVersion = @currentVersion()
    return unless currentVersion?
    names = (dep.packageName for dep in currentVersion?.dependencies)
    names = _.filter names, Pkg.filterDeps
    MeteorPackages.Packages.find(name: $in: names)

  getDepVersion: (name) ->
    _.find @currentVersion()?.dependencies, (dep) -> dep.packageName is name
