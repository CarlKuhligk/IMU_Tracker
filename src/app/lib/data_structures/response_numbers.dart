class ResponseType {
  final int responseNumber;
  final String responseString;

  ResponseType(this.responseNumber, this.responseString);
}

final responseList = {
  'deviceRegistered': ResponseType(10, 'DEVICE REGISTERED'),
  'missingApiKey': ResponseType(19, 'MISSING API KEY'),
  'invalidApiKey': ResponseType(20, 'INVALID API KEY'),
  'deviceAlreadyRegistered': ResponseType(21, 'DEVICE ALREADY REGISTERED'),
  'missingType': ResponseType(30, 'MISSING TYPE'),
  'missingData': ResponseType(31, 'MISSING DATA'),
  'unknownDataType': ResponseType(32, 'UNKNOWN DATA TYPE'),
  'validApiKey': ResponseType(34, 'VALID API KEY'),
};
