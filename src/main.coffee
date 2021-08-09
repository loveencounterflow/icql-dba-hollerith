
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'ICQL-DBA-TAGS'
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
def                       = Object.defineProperty


#===========================================================================================================
### RegEx from https://github.com/loveencounterflow/paragate/blob/master/src/htmlish.grammar.coffee with
the additional exlusion of `+`, `-`, ':' which are used in TagExes ###
name_re = /^[^-+:\s!?=\{\[\(<\/>\)\]\}'"]+$/u

#===========================================================================================================
types.declare 'dbv_constructor_cfg', tests:
  '@isa.object x':        ( x ) -> @isa.object x
  'x.prefix is a prefix': ( x ) ->
    return false unless @isa.text x.prefix
    return true if x.prefix is ''
    return ( /^[_a-z][_a-z0-9]*$/ ).test x.prefix

#-----------------------------------------------------------------------------------------------------------
types.defaults =
  dbv_constructor_cfg:
    dba:        null
    prefix:     'v_'

#===========================================================================================================
class @Dbv

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cfg ) ->
    validate.dbv_constructor_cfg @cfg = { types.defaults.dbv_constructor_cfg..., cfg..., }
    debug '^4877^', @cfg
    #.......................................................................................................
    dba  = if @cfg.dba? then @cfg.dba else new Dba()
    def @, 'dba', { enumerable: false, value: dba, }
    delete @cfg.dba
    @cfg = freeze @cfg
    @_create_db_structure()
    @_compile_sql()
    # @_create_sql_functions()
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _create_db_structure: ->
    { prefix } = @cfg
    @dba.execute SQL"""
      create table if not exists #{prefix}variables (
          key     text    not null primary key,
          value   json    not null default 'null' );
      """
    return null

  #---------------------------------------------------------------------------------------------------------
  _compile_sql: ->
    prefix = @cfg.prefix
    sql =
      get: SQL"""
        select value from #{prefix}variables
          where key = $key
          limit 1;"""
      set: SQL"""
        insert into #{prefix}variables ( key, value )
          values ( $key, $value )
          on conflict do update set value = $value;"""
    def @, 'sql', { enumerable: false, value: sql, }
    return null

  # #---------------------------------------------------------------------------------------------------------
  # _create_sql_functions: ->
  #   prefix  = @cfg.prefix
  #   @f      = {}
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
  #   return null

  #---------------------------------------------------------------------------------------------------------
  get:        ( key ) -> JSON.parse @dba.first_value @dba.query @sql.get, { key, }
  # get_many:   ( key ) -> JSON.parse @dba.first_value @dba.query @sql.get, { key, }

  #---------------------------------------------------------------------------------------------------------
  set: ( key, value ) ->
    @dba.run @sql.set, { key, value: ( JSON.stringify value ), }
    return value



