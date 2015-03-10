require 'colors'
{path, Promise: global.Promise} = fs = require 'nofs'
global._ = require 'lodash'
semver = require 'semver'

npm = require './npm'
util = require './util'
checkVer = require './checkVersion'

packageFile = util.cwdFilePath 'package.json'
packageBakFile = util.cwdFilePath 'package.bak.json'
modulesPath = util.cwdFilePath 'node_modules'

option = {}
globalPackage = {}

parseOpts = (opts) ->
    option = _.defaults opts,
        include: "" # array
        exclude: [] # array
        writeBack: no
        install: no
        lock: no
        all: no # w + i + l
        devDep: yes
        dep: yes
        silent: no
        backUp: no
        lockAll: false
        cache: true
        logLevel: 'error'
        cwd: process.cwd()
        warning: true

    if option.all
        _.assign opts,
            writeBack: yes
            install: yes
            lock: yes

    option.exclude = _.compact option.exclude
    option.include and option.include = _.compact option.include

    if option.silent
        console.log = -> return

parsePackage = (name, ver, type) ->
    if Array.isArray(option.include) and not (name in option.include)
        return null

    if name in option.exclude
        return null

    if type is 'g'
        declareVer = installedVer = ver
    else
        # version in package.json
        declareVer = if semver.validRange ver then ver.trim() else null
        declareVer is '' and declareVer = '*'
        return null unless declareVer

        # version installed
        try
            pack = util.readPackageFile name
            installedVer = pack.version
        catch
            installedVer = null

    {
        packageName: name
        declareVer
        installedVer
        baseVer: installedVer
        newVer: ''
        type
        needUpdate: no
        warnMsg: ''
    }

formatPackages = (obj, type) ->
    _.map obj, (version, name) ->
        pack = parsePackage name, version, type

prepare = ->
    try
        globalPackage = util.readPackageFile null
    catch e
        if e.errno and e.errno is -2
            throw new Error 'package.json Not Found!'
        else
            throw new Error 'parse package.json failed!'

    deps = []
    if option.dep
        deps = deps.concat formatPackages globalPackage.dependencies, 'S'
    if option.devDep
        deps = deps.concat formatPackages globalPackage.devDependencies, 'D'

    deps = _.compact deps

getToWrite = ({declareVer, newVer}, {lock, lockAll}) ->
    if declareVer is '*' or ''
        if lockAll then return newVer else return '*'

    first = declareVer[0]

    if semver.valid declareVer
        return newVer
    else if first[0] is '^' # Caret Ranges
        if lock then newVer else '^' + newVer
    else if first[0] is '~' # Tilde Ranges
        if lock then newVer else '~' + newVer
    else # other ranges
        if lock then newVer else '^' + newVer

npmUp = ->
    process.chdir option.cwd

    try
        deps = prepare()
    catch e
        console.error (util.errorSign + " #{e}").red
        return Promise.reject()

    Promise.promisify(npm.load)
        loglevel: option.logLevel
    .then ->
        util.logInfo 'Checking package\'s version...'
        checkVer deps, option.cache
    .then (newDeps) ->
        deps = newDeps
        util.print deps, option.warning

        toUpdate = deps.filter (dep) -> dep.needUpdate and dep.installedVer
                        .map (dep) -> "#{dep.packageName}@#{dep.newVer}"

        chain = Promise.resolve()

        if toUpdate.length is 0
            util.logSucc "Everything is new!"

        if option.writeBack
            chain = chain.then ->
                deps.forEach (dep) ->
                    toWrite = getToWrite dep, option

                    switch dep.type
                        when 'S' then globalPackage.dependencies[dep.packageName] = toWrite
                        when 'D' then globalPackage.devDependencies[dep.packageName] = toWrite

                if option.backUp
                    backFile = if _.isString option.backUp then util.cwdFilePath option.backUp else packageBakFile
                    fs.copy packageFile, backFile
            .then ->
                ['dependencies', 'devDependencies'].forEach (k) ->
                    delete globalPackage[k] if _.isEmpty globalPackage[k]
                fs.outputJSON packageFile, globalPackage, space: 2
            .then ->
                util.logSucc "package.json has been updated!"

        if option.install
            chain = chain.then ->
                util.install toUpdate

        chain

npmUpSubDir = ->
    process.chdir option.cwd

    dirs = []

    fs.eachDir '*',
        iter: (info) ->
            if info.isDir
                dirs.push info.path
    .then ->
        cwd = process.cwd()
        chain = Promise.resolve()

        dirs.forEach (odir) ->
            dir = path.join cwd, odir
            dirPack = path.join dir, 'package.json'
            if fs.fileExistsSync dirPack
                chain = chain.then ->
                    console.log '\n', odir
                    option.cwd = dir
                    npmUp()
                .catch -> return
        chain
    .then ->
        console.log 'FINISH'.green


npmUpGlobal = ->
    if option.install and not util.checkPrivilege()
        console.error (util.errorSign + " Permission Denied").red
        console.error "Please try running this command again as root/Administrator".yellow
        process.exit 1

    Promise.promisify(npm.load)
        loglevel: option.logLevel
        global: true
    .then ->
        util.logInfo 'Reading global installed packages...'
        # known issue: only the first dir will be listed in PATH
        Promise.promisify(npm.commands.ls) null, true
    .then (data) ->
        globalDep = data.dependencies or data[0].dependencies
        console.log (Object.keys(globalDep).join ' ').cyan

        deps = _.map globalDep, (val, key) ->
            parsePackage key, val.version, 'g'
        util.logInfo 'Checking package\'s version...'

        checkVer _.compact(deps), option.cache
    .then (newDeps) ->
        deps = newDeps
        util.print deps, option.warning

        toUpdate = deps.filter (dep) -> dep.needUpdate and dep.installedVer
                    .map (dep) -> "#{dep.packageName}@#{dep.newVer}"

        if toUpdate.length is 0
            util.logSucc "Everything is new!"
            return Promise.resolve()

        if option.install
            return util.install toUpdate

module.exports = (opt, type = '') ->
    parseOpts opt

    promise =
        switch type
            when 'global' then npmUpGlobal()
            when 'subDir' then npmUpSubDir()
            else npmUp()
