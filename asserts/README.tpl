npm-up
======

A lightweight tool to check the latest version of dependent npm packages for a project and do whatever you want.

[![NPM version](https://badge.fury.io/js/npm-up.svg)](http://badge.fury.io/js/npm-up)
[![Deps Up to Date](https://david-dm.org/dracupid/npm-up.svg?style=flat)](https://david-dm.org/dracupid/npm-up)
[![Build Status](https://travis-ci.org/dracupid/npm-up.svg)](https://travis-ci.org/dracupid/npm-up)
[![Build status](https://ci.appveyor.com/api/projects/status/github/dracupid/npm-up?svg=true)](https://ci.appveyor.com/project/dracupid/npm-up)

## Installation
```bash
npm i npm-up -g
```

## Usage
1. Run `npm-up [options]` in a project directory with a `package.json` file. For example: `npm-up -iw`. <br/>
If no options are configured, it will only check the latest version and do nothing but display.

2. Run `npm-up -g` to check globally install npm packages.

3. Run `npm-up -A` to check all projects in sub directories.

#### commands:
<%
function format(str){
    return str.replace(/\n\n/g, '').replace(/\n    /g, '\n').replace('    ', '')
}
%>
```
<%= format(help[2])%>
```

#### Options:
```
<%= format(help[3])%>
```

## Version Pattern
Fully support semantic version. Eg:
```
*
^1.5.4
~2.3
0.9.7
0.5.0-alpha1
'' //regard as *
```

Notice that **ranges** version may be overridden by Caret Ranges(^) when written back, and will be updated only when the latest version is greater than all the versions possible in the range.
```
>= 1.0.0 <= 1.5.4   // Version Range
1.2 - 2.3.4         // Hyphen Ranges
1.x                 // X-Ranges
```
- However, the semantic meaning of the prefix and suffix may somehow **ignored**, because **I just want the latest version**.
- If the version declared in the `package.json` is not recognizable, the corresponding package will be **excluded**.
- More info: https://docs.npmjs.com/misc/semver

## Rules
0. Take 3 versions into consideration for one package:
    - Version declared in `package.json`.
    - Version of the package installed.
    - The latest version of the package.

0. If a package is not installed, only `package.json` will be updated, and the package itself won't be installed.

0. If the version is `*` in `package.json`, it will not be overwritten, even when the flag `lock` is set. If you really want to change a `*` version, use `--lock-all` flag.

0. The prefix `^ ~` of the version will be preserved when written back, unless flag `lock` is set.

0. If the version installed is not the same as the version declared in `package.json`, there comes a warning.

5. Installed version is preferred.