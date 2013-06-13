# ajaxTransport exists in jQuery 1.5+, XDomainRequest is an IE8 artifact
if not jQuery.support.cors and jQuery.ajaxTransport and window.XDomainRequest?
  jQuery.ajaxTransport 'text json', (options, userOptions, jqXHR) ->
    sameDomain = (new RegExp "^#{location.protocol}", 'i').test options.url
    isGetOrPost = /^get|post$/i.test options.type
    isHttpOrHttps = /^https?:/i.test options.url

    return unless options.crossDomain and
      options.async and isGetOrPost and isHttpOrHttps # XDR-imposed constraints

    xdr = null
    userType = userOptions.dataType?.toLowerCase() or ''
    send: (headers, complete) ->
      xdr = new XDomainRequest()
      xdr.timeout = userOptions.timeout  if typeof userOptions.timeout is 'number'
      xdr.ontimeout = ->
        complete 500, 'timeout'

      xdr.onload = ->
        raw = xdr.responseText
        type = xdr.contentType
        allResponseHeaders = """Content-Length: #{ raw.length }\r
                                Content-Type: #{ type }"""
        status =
          code: 200
          message: 'success'

        responses = text: raw
        if userType is 'json' or userType isnt 'text' and /\/json/i.test type
          try
            responses.json = jQuery.parseJSON raw
          catch e
            status.code = 500
            status.message = 'Error JSON parsing XDomainRequest response'
          finally
            complete status.code, status.message, responses, allResponseHeaders

      # set an empty handler for 'onprogress' so requests don't get aborted
      xdr.onprogress = ->

      xdr.onerror = ->
        complete 500, 'error',
          text: xdr.responseText

      postData = userOptions.data or ''
      postData = jQuery.param postData if typeof postData is 'object'
      xdr.open options.type, options.url
      xdr.send postData

    abort: ->
      xdr?.abort()
