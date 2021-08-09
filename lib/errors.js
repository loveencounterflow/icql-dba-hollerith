(function() {
  'use strict';
  var CND, E, badge, debug, rpr;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'ICQL-DBA-VARS/ERRORS';

  debug = CND.get_logger('debug', badge);

  // warn                      = CND.get_logger 'warn',      badge
  // info                      = CND.get_logger 'info',      badge
  // urge                      = CND.get_logger 'urge',      badge
  // help                      = CND.get_logger 'help',      badge
  // whisper                   = CND.get_logger 'whisper',   badge
  // echo                      = CND.echo.bind CND
  E = require('icql-dba/lib/errors');

  // #===========================================================================================================
// class @Dtags_invalid_tagex extends E.Dba_error
//   constructor: ( ref, tagex )      -> super ref, "invalid tag expression #{rpr tagex}"

}).call(this);

//# sourceMappingURL=errors.js.map