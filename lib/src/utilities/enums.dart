/// Outcome flag used by Places and Geocode JSON envelopes.
enum Status {
  /// The request succeeded.
  ok,

  /// The request succeeded but returned no rows.
  zeroResults,

  /// The request was rejected (invalid, denied, or quota).
  badRequest,
}

/// Maps an Ola Maps `status` string to [Status]. Unknown values become [Status.ok].
Status parseStatus(String status) {
  switch (status.toLowerCase().trim()) {
    case 'ok':
    case 'success':
    case 'created':
    case 'updated':
    case 'deleted':
      return Status.ok;
    case 'zero_results':
    case 'zeroresults':
      return Status.zeroResults;
    case 'invalid_request':
    case 'bad_request':
    case 'request_denied':
    case 'over_query_limit':
    case 'unknown_error':
      return Status.badRequest;
    default:
      return Status.ok;
  }
}
