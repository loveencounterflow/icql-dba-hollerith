
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
{ HOLLERITH_CODEC, }      = require 'hollerith-codec/lib/tng'
{ Vnr, }                  = require 'datom/lib/vnr'


#===========================================================================================================
name_re = /^[^-+:\s!?=\{\[\(<\/>\)\]\}'"]+$/u

#===========================================================================================================
types.declare 'vnr_constructor_cfg', tests:
  '@isa.object x':                ( x ) -> @isa.object x
  'x.prefix is a prefix':         ( x ) ->
    return false unless @isa.text x.prefix
    return true if x.prefix is ''
    return ( /^[_a-z][_a-z0-9]*$/ ).test x.prefix
  "( @type_of x.dba ) is 'dba'":  ( x ) -> ( @type_of x.dba ) is 'dba'

#-----------------------------------------------------------------------------------------------------------
types.defaults =
  vnr_constructor_cfg:
    dba:        null
    prefix:     'vnr_'

#===========================================================================================================
class @Vnr extends Vnr

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cfg ) ->
    super()
    validate.vnr_constructor_cfg @cfg = { types.defaults.vnr_constructor_cfg..., cfg..., }
    #.......................................................................................................
    guy.props.def @, 'dba', { enumerable: false, value: cfg.dba, }
    delete @cfg.dba
    @cfg = freeze @cfg
    # @_create_db_structure()
    @_compile_sql()
    @_create_sql_functions()
    return undefined

  # #---------------------------------------------------------------------------------------------------------
  # _create_db_structure: ->
  #   { prefix } = @cfg
  #   @dba.execute SQL"""
  #     create table if not exists #{prefix}variables (
  #         key     text    not null primary key,
  #         value   json    not null default 'null' );
  #     """
  #   return null

  #---------------------------------------------------------------------------------------------------------
  _compile_sql: ->
    prefix = @cfg.prefix
    sql =
      get: SQL"""
        select value from #{prefix}variables
          where key = $key
          limit 1;"""
    guy.props.def @, 'sql', { enumerable: false, value: sql, }
    return null

  #---------------------------------------------------------------------------------------------------------
  _create_sql_functions: ->
    prefix  = @cfg.prefix
    # @f      = {}
  #   #.......................................................................................................
  #   @dba.create_function
  #     name:           prefix + 'get'
  #     call:           ( key ) => @get key
  #   #.......................................................................................................
  #   @dba.create_table_function
  #     name:           prefix + 'get_many'
  #     columns:        [ 'element', ]
  #     parameters:     [ 'key', ]
  #     rows:           ( ( key ) -> yield from @get_many key ).bind @
  #   #.......................................................................................................
  #   @dba.create_function
  #     name:           prefix + 'set'
  #     call:           ( key ) => @set key
  #   #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  encode: HOLLERITH_CODEC.encode.bind HOLLERITH_CODEC


############################################################################################################
if module is require.main then do =>
  # debug '^2378^', require 'datom'








