import 'package:ola_maps/src/utilities/exceptions.dart';

enum Status { ok, zeroResults, badRequest }

Status parseStatus(String status) {
  switch (status.toLowerCase()) {
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
      return Status.badRequest;
    default:
      throw ApiException('Unknown status: $status');
  }
}
