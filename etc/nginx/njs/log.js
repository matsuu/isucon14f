function headersToObj(headers) {
  return headers.reduce(function (acc, header) {
    var k = header[0], v = header[1];
    if (k != "X-Request-Pattern") {
      acc[k] = acc[k] || [];
      acc[k].push(v);
    }
    return acc;
  }, {});
}

function getJsonLog(r) {
  var pattern = r.headersOut["X-Request-Pattern"] || r.uri;
  var res = {
    StartTime: r.variables['msec'],
    Latency: r.variables['request_time'],
    Protocol: r.httpVersion,
    RemoteAddr: r.variables['remote_addr'],
    Host: r.variables['host'],
    Method: r.method,
    URL: r.variables['request_uri'],
    Pattern: pattern,
    Status: r.status,
    Error: null,
    RequestSize: r.variables['request_length'],
    ResponseSize: r.variables['bytes_sent'],
    RequestHeaders: headersToObj(r.rawHeadersIn),
    ResponseHeaders: headersToObj(r.rawHeadersOut),
    SSL: {
      Cipher: r.variables['ssl_cipher'],
      Ciphers: r.variables['ssl_ciphers'],
      Curve: r.variables['ssl_curve'],
      Curves: r.variables['ssl_curves'],
      Protocol: r.variables['ssl_protocol'],
      SessionReused: r.variables['ssl_session_reused']
    }
  };
  return JSON.stringify(res);
}

export default {getJsonLog};
