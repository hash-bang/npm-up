"use strict"

request = require 'kiss-request'
{Promise} = require 'nofs'
{debug} = require './util'
url = require 'url'

request.Promise = Promise

module.exports = (name, mirror) ->
    link = url.resolve mirror, "/-/package/#{name}/dist-tags"
    debug link

    request link
    .then (data) ->
        debug data
        JSON.parse(data).latest or ''
    .catch (e) ->
        if e.code is 'TIMEOUT'
            Promise.reject new Error "Request to #{mirror} timeout. Please use an alternative registry by -m <mirror>"
        else if e.code is 'UNWANTED_STATUS_CODE'
            Promise.resolve ''
        else
            Promise.reject e
