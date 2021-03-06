(function() {
  'use strict';
  var CND, Dba, E, Hollerith2, SQL, acquire_methods, badge, debug, echo, freeze, guy, help, info, isa, jp, jr, lets, name_re, rpr, type_of, types, urge, validate, validate_list_of, warn, whisper,
    indexOf = [].indexOf;

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

  ({
    Hollerith: Hollerith2
  } = require('hollerith'));

  jr = JSON.stringify;

  jp = JSON.parse;

  //===========================================================================================================
  name_re = /^[^-+:\s!?=\{\[\(<\/>\)\]\}'"]+$/u;

  //===========================================================================================================
  types.declare('dhlr_constructor_cfg', {
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
      // "( @type_of x.dba ) is 'dba'":  ( x ) -> ( @type_of x.dba ) is 'dba'
      "( @isa.function x.dba ) or ( @isa.object x.dba )": function(x) {
        return (this.isa.function(x.dba)) || (this.isa.object(x.dba));
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  /* TAINT integrate typing into class so we can uses types from `icql-dba` */
  types.declare('dhlr_alter_table_cfg', {
    tests: {
      '@isa.object x': function(x) {
        return this.isa.object(x);
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  types.defaults = {
    dhlr_constructor_cfg: {
      dba: null,
      prefix: 'hlr_'
    },
    dhlr_alter_table_cfg: {
      schema: 'main',
      table_name: null,
      json_column_name: 'vnr',
      blob_column_name: 'vnr_blob'
    }
  };

  //-----------------------------------------------------------------------------------------------------------
  acquire_methods = function(source, target) {
    var descriptor, method, name, ref;
    ref = Object.getOwnPropertyDescriptors(source);
    /* TAINT check for unbound methods */
    /* TAINT `intertype.callable()` is incomplete (? no async generator function) */
    for (name in ref) {
      descriptor = ref[name];
      ({
        value: method
      } = descriptor);
      if (!isa.callable(method)) {
        continue;
      }
      target[name] = method;
    }
    return null;
  };

  //===========================================================================================================
  this.Hollerith = class Hollerith {
    /* TAINT make constructor work like that in Hollerith2 */
    //---------------------------------------------------------------------------------------------------------
    constructor(cfg) {
      /* TAINT must pass Hollerith cfg parameters to super */
      // super()
      this.hlr = new Hollerith2();
      /* NOTE for convenience we repeat constants from the associated class; without this, clients would have
         to write `hlr.hlr.constructor.C` */
      this.C = Hollerith2.C;
      /* Also for convenience, we mirror all metods from the associated class to the instance: */
      acquire_methods(this.hlr, this);
      validate.dhlr_constructor_cfg(this.cfg = {...types.defaults.dhlr_constructor_cfg, ...cfg});
      //.......................................................................................................
      guy.props.def(this, 'dba', {
        enumerable: false,
        value: cfg.dba
      });
      delete this.cfg.dba;
      this.cfg = freeze(this.cfg);
      this._compile_sql();
      this._create_sql_functions();
      return void 0;
    }

    //---------------------------------------------------------------------------------------------------------
    _compile_sql() {
      // prefix = @cfg.prefix
      // sql =
      //   f: SQL""
      // guy.props.def @, 'sql', { enumerable: false, value: sql, }
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    _create_sql_functions() {
      var prefix;
      prefix = this.cfg.prefix;
      //.......................................................................................................
      this.dba.create_function({
        name: prefix + 'advance',
        call: (vnr) => {
          return jr(this.advance(jp(vnr)));
        }
      });
      this.dba.create_function({
        name: prefix + 'recede',
        call: (vnr) => {
          return jr(this.recede(jp(vnr)));
        }
      });
      this.dba.create_function({
        name: prefix + 'encode',
        call: (vnr) => {
          return this.encode(jp(vnr));
        }
      });
      this.dba.create_function({
        name: prefix + 'cmp',
        call: (a, b) => {
          return this.cmp(jp(a), jp(b));
        }
      });
      this.dba.create_function({
        name: prefix + 'deepen',
        varargs: true,
        call: (vnr, nr = 0) => {
          return jr(this.deepen(jp(vnr), nr));
        }
      });
      this.dba.create_function({
        name: prefix + 'new_vnr',
        varargs: true,
        call: (source = null) => {
          return jr(this.new_vnr(jp(source)));
        }
      });
      //.......................................................................................................
      return null;
    }

    //=========================================================================================================

    //---------------------------------------------------------------------------------------------------------
    alter_table(cfg) {
      var blob_column_name, blob_column_name_i, blob_index_name, blob_index_name_i, column_names, index_names, json_column_name, json_column_name_i, json_index_name, json_index_name_i, prefix, schema, schema_i, table_name, table_name_i;
      /* TAINT make `unique` configurable */
      /* TAINT make `virtual`/`stored` configurable */
      /* TAINT include table name in index name */
      validate.dhlr_alter_table_cfg(cfg = {...types.defaults.dhlr_alter_table_cfg, ...cfg});
      ({schema, table_name, json_column_name, blob_column_name} = cfg);
      prefix = this.cfg.prefix;
      if (blob_column_name == null) {
        blob_column_name = json_column_name + '_blob';
      }
      blob_index_name = prefix + table_name + '_' + blob_column_name + '_idx'/* TAINT make configurable? */
      blob_index_name_i = this.dba.sql.I(blob_index_name);
      json_index_name = prefix + table_name + '_' + json_column_name + '_idx'/* TAINT make configurable? */
      json_index_name_i = this.dba.sql.I(json_index_name);
      schema_i = this.dba.sql.I(schema);
      table_name_i = this.dba.sql.I(table_name);
      json_column_name_i = this.dba.sql.I(json_column_name);
      blob_column_name_i = this.dba.sql.I(blob_column_name);
      column_names = this._get_column_names(schema_i, table_name);
      index_names = this._get_index_names(schema_i);
      if (indexOf.call(column_names, json_column_name) < 0) {
        this.dba.execute(SQL`alter table ${schema_i}.${table_name_i}
  add column ${json_column_name_i} json
  not null;`);
      }
      if (indexOf.call(column_names, blob_column_name) < 0) {
        this.dba.execute(SQL`alter table ${schema_i}.${table_name_i}
  add column ${blob_column_name_i} blob
  generated always as ( ${prefix}encode( ${json_column_name_i} ) )
  virtual not null;`);
      }
      if (indexOf.call(index_names, json_index_name) < 0) {
        this.dba.execute(SQL`create unique index ${schema_i}.${json_index_name_i}
on ${table_name_i} ( ${json_column_name_i} );`);
      }
      if (indexOf.call(index_names, blob_index_name) < 0) {
        this.dba.execute(SQL`create unique index ${schema_i}.${blob_index_name_i}
on ${table_name_i} ( ${prefix}encode( ${json_column_name_i} ) );`);
      }
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    /* TAINT implement this in dbay */
    _get_column_names(schema_i, table_name) {
      var R, row, rows;
      R = [];
      rows = this.dba.prepare(SQL`select name from ${schema_i}.pragma_table_info( $table_name );`);
      return (function() {
        var ref, results;
        ref = rows.iterate({table_name});
        results = [];
        for (row of ref) {
          results.push(row.name);
        }
        return results;
      })();
      return R;
    }

    //---------------------------------------------------------------------------------------------------------
    /* TAINT implement this in dbay */
    _get_index_names(schema_i) {
      var R, row, rows;
      R = [];
      rows = this.dba.prepare(SQL`select name from ${schema_i}.sqlite_schema where type = 'index';`);
      return (function() {
        var ref, results;
        ref = rows.iterate();
        results = [];
        for (row of ref) {
          results.push(row.name);
        }
        return results;
      })();
      return R;
    }

  };

  //###########################################################################################################
  if (module === require.main) {
    (() => {})();
  }

  // debug '^2378^', require 'datom'

}).call(this);

//# sourceMappingURL=main.js.map