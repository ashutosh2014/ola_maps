enum Status { ok, zeroResults, badRequest }

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
