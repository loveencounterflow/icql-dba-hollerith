
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'ICQL-DBA-VNR'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
types                     = new ( require 'intertype' ).Intertype
{ isa
  type_of
  validate
  validate_list_of }      = types.export()
# { to_width }              = require 'to-width'
SQL                       = String.raw
{ lets
  freeze }                = require 'letsfreezethat'
E                         = require './errors'
{ Dba, }                  = require 'icql-dba'
guy                       = require 'guy'
{ Hollerith: Hollerith2, }            = require 'hollerith'
jr                        = JSON.stringify
jp                        = JSON.parse


#===========================================================================================================
name_re = /^[^-+:\s!?=\{\[\(<\/>\)\]\}'"]+$/u

#===========================================================================================================
types.declare 'dhlr_constructor_cfg', tests:
  '@isa.object x':                ( x ) -> @isa.object x
  'x.prefix is a prefix':         ( x ) ->
    return false unless @isa.text x.prefix
    return true if x.prefix is ''
    return ( /^[_a-z][_a-z0-9]*$/ ).test x.prefix
  # "( @type_of x.dba ) is 'dba'":  ( x ) -> ( @type_of x.dba ) is 'dba'
  "( @isa.function x.dba ) or ( @isa.object x.dba )":  ( x ) -> ( @isa.function x.dba ) or ( @isa.object x.dba )

#-----------------------------------------------------------------------------------------------------------
### TAINT integrate typing into class so we can uses types from `icql-dba` ###
types.declare 'dhlr_alter_table_cfg', tests:
  '@isa.object x':                ( x ) -> @isa.object x

#-----------------------------------------------------------------------------------------------------------
types.defaults =
  dhlr_constructor_cfg:
    dba:        null
    prefix:     'hlr_'
  dhlr_alter_table_cfg:
    schema:               'main'
    table_name:           null
    json_column_name:     'vnr'
    blob_column_name:     'vnr_blob'

#-----------------------------------------------------------------------------------------------------------
acquire_methods = ( source, target ) ->
  ### TAINT check for unbound methods ###
  ### TAINT `intertype.callable()` is incomplete (? no async generator function) ###
  for name, descriptor of Object.getOwnPropertyDescriptors source
    { value: method, } = descriptor
    continue unless isa.callable method
    target[ name ] = method
  return null


#===========================================================================================================
class @Hollerith

  ### TAINT make constructor work like that in Hollerith2 ###

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cfg ) ->
    ### TAINT must pass Hollerith cfg parameters to super ###
    # super()
    @hlr  = new Hollerith2()
    ### NOTE for convenience we repeat constants from the associated class; without this, clients would have
    to write `hlr.hlr.constructor.C` ###
    @C    = Hollerith2.C
    ### Also for convenience, we mirror all metods from the associated class to the instance: ###
    acquire_methods @hlr, @
    validate.dhlr_constructor_cfg @cfg = { types.defaults.dhlr_constructor_cfg..., cfg..., }
    #.......................................................................................................
    guy.props.def @, 'dba', { enumerable: false, value: cfg.dba, }
    delete @cfg.dba
    @cfg = freeze @cfg
    @_compile_sql()
    @_create_sql_functions()
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _compile_sql: ->
    # prefix = @cfg.prefix
    # sql =
    #   f: SQL""
    # guy.props.def @, 'sql', { enumerable: false, value: sql, }
    return null

  #---------------------------------------------------------------------------------------------------------
  _create_sql_functions: ->
    prefix  = @cfg.prefix
    #.......................................................................................................
    @dba.create_function name: prefix + 'advance',  call: ( vnr )   => jr @advance     jp vnr
    @dba.create_function name: prefix + 'recede',   call: ( vnr )   => jr @recede      jp vnr
    @dba.create_function name: prefix + 'encode',   call: ( vnr )   =>    @encode      jp vnr
    @dba.create_function name: prefix + 'cmp',      call: ( a, b )  =>    @cmp         ( jp a ), ( jp b )
    @dba.create_function name: prefix + 'deepen',  varargs: true, call: ( vnr, nr = 0   ) => jr @deepen ( jp vnr ), nr
    @dba.create_function name: prefix + 'new_vnr', varargs: true, call: ( source = null ) => jr @new_vnr jp source
    #.......................................................................................................
    return null


  #=========================================================================================================
  #
  #---------------------------------------------------------------------------------------------------------
  alter_table: ( cfg ) ->
    ### TAINT make `unique` configurable ###
    ### TAINT make `virtual`/`stored` configurable ###
    ### TAINT include table name in index name ###
    validate.dhlr_alter_table_cfg cfg = { types.defaults.dhlr_alter_table_cfg..., cfg..., }
    { schema
      table_name
      json_column_name
      blob_column_name }  = cfg
    prefix                = @cfg.prefix
    blob_column_name     ?= json_column_name + '_blob'
    blob_index_name       = prefix + table_name + '_' + blob_column_name + '_idx' ### TAINT make configurable? ###
    blob_index_name_i     = @dba.sql.I blob_index_name
    json_index_name       = prefix + table_name + '_' + json_column_name + '_idx' ### TAINT make configurable? ###
    json_index_name_i     = @dba.sql.I json_index_name
    schema_i              = @dba.sql.I schema
    table_name_i          = @dba.sql.I table_name
    json_column_name_i    = @dba.sql.I json_column_name
    blob_column_name_i    = @dba.sql.I blob_column_name
    column_names          = @_get_column_names  schema_i, table_name
    index_names           = @_get_index_names   schema_i
    unless json_column_name in column_names
      @dba.execute SQL"""
        alter table #{schema_i}.#{table_name_i}
          add column #{json_column_name_i} json
          not null;"""
    unless blob_column_name in column_names
      @dba.execute SQL"""
        alter table #{schema_i}.#{table_name_i}
          add column #{blob_column_name_i} blob
          generated always as ( #{prefix}encode( #{json_column_name_i} ) )
          virtual not null;"""
    unless json_index_name in index_names
      @dba.execute SQL"""
        create unique index #{schema_i}.#{json_index_name_i}
        on #{table_name_i} ( #{json_column_name_i} );"""
    unless blob_index_name in index_names
      @dba.execute SQL"""
        create unique index #{schema_i}.#{blob_index_name_i}
        on #{table_name_i} ( #{prefix}encode( #{json_column_name_i} ) );"""
    return null

  #---------------------------------------------------------------------------------------------------------
  ### TAINT implement this in dbay ###
  _get_column_names: ( schema_i, table_name ) ->
    R = []
    rows = @dba.prepare SQL"""
      select name from #{schema_i}.pragma_table_info( $table_name );"""
    return ( row.name for row from rows.iterate { table_name, } )
    return R

  #---------------------------------------------------------------------------------------------------------
  ### TAINT implement this in dbay ###
  _get_index_names: ( schema_i ) ->
    R = []
    rows = @dba.prepare SQL"""
      select name from #{schema_i}.sqlite_schema where type = 'index';"""
    return ( row.name for row from rows.iterate() )
    return R


############################################################################################################
if module is require.main then do =>
  # debug '^2378^', require 'datom'








