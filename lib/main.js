(function() {
  'use strict';
  var CND, Dba, E, HOLLERITH_CODEC, SQL, Vnr, badge, debug, echo, freeze, guy, help, info, isa, lets, name_re, rpr, type_of, types, urge, validate, validate_list_of, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'ICQL-DBA-VNR';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  types = new (require('intertype')).Intertype();

  ({isa, type_of, validate, validate_list_of} = types.export());

  // { to_width }              = require 'to-width'
  SQL = String.raw;

  ({lets, freeze} = require('letsfreezethat'));

  E = require('./errors');

  ({Dba} = require('icql-dba'));

  guy = require('guy');

  ({HOLLERITH_CODEC} = require('hollerith-codec/lib/tng'));

  ({Vnr} = require('datom/lib/vnr'));

  //===========================================================================================================
  name_re = /^[^-+:\s!?=\{\[\(<\/>\)\]\}'"]+$/u;

  //===========================================================================================================
  types.declare('vnr_constructor_cfg', {
    tests: {
      '@isa.object x': function(x) {
        return this.isa.object(x);
      },
      'x.prefix is a prefix': function(x) {
        if (!this.isa.text(x.prefix)) {
          return false;
        }
        if (x.prefix === '') {
          return true;
        }
        return /^[_a-z][_a-z0-9]*$/.test(x.prefix);
      },
      "( @type_of x.dba ) is 'dba'": function(x) {
        return (this.type_of(x.dba)) === 'dba';
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  types.defaults = {
    vnr_constructor_cfg: {
      dba: null,
      prefix: 'vnr_'
    }
  };

  //===========================================================================================================
  this.Vnr = (function(superClass) {
    class Vnr extends superClass {
      //---------------------------------------------------------------------------------------------------------
      constructor(cfg) {
        super();
        validate.vnr_constructor_cfg(this.cfg = {...types.defaults.vnr_constructor_cfg, ...cfg});
        //.......................................................................................................
        guy.props.def(this, 'dba', {
          enumerable: false,
          value: cfg.dba
        });
        delete this.cfg.dba;
        this.cfg = freeze(this.cfg);
        // @_create_db_structure()
        this._compile_sql();
        this._create_sql_functions();
        return void 0;
      }

      // #---------------------------------------------------------------------------------------------------------
      // _create_db_structure: ->
      //   { prefix } = @cfg
      //   @dba.execute SQL"""
      //     create table if not exists #{prefix}variables (
      //         key     text    not null primary key,
      //         value   json    not null default 'null' );
      //     """
      //   return null

        //---------------------------------------------------------------------------------------------------------
      _compile_sql() {
        var prefix, sql;
        prefix = this.cfg.prefix;
        sql = {
          get: SQL`select value from ${prefix}variables
  where key = $key
  limit 1;`
        };
        guy.props.def(this, 'sql', {
          enumerable: false,
          value: sql
        });
        return null;
      }

      //---------------------------------------------------------------------------------------------------------
      _create_sql_functions() {
        var prefix;
        prefix = this.cfg.prefix;
        // @f      = {}
        //   #.......................................................................................................
        //   @dba.create_function
        //     name:           prefix + 'get'
        //     call:           ( key ) => @get key
        //   #.......................................................................................................
        //   @dba.create_table_function
        //     name:           prefix + 'get_many'
        //     columns:        [ 'element', ]
        //     parameters:     [ 'key', ]
        //     rows:           ( ( key ) -> yield from @get_many key ).bind @
        //   #.......................................................................................................
        //   @dba.create_function
        //     name:           prefix + 'set'
        //     call:           ( key ) => @set key
        //   #.......................................................................................................
        return null;
      }

    };

    //---------------------------------------------------------------------------------------------------------
    Vnr.prototype.encode = HOLLERITH_CODEC.encode.bind(HOLLERITH_CODEC);

    return Vnr;

  }).call(this, Vnr);

  //###########################################################################################################
  if (module === require.main) {
    (() => {})();
  }

  // debug '^2378^', require 'datom'

}).call(this);

//# sourceMappingURL=main.js.map