
# ICQL-DBA Plugin: VNR

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Notes (in lieu of docs)](#notes-in-lieu-of-docs)
- [To Do](#to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Notes (in lieu of docs)

* Purpose
  * Add a JSON and a BLOB column to your table (called `vnr` and `vnr_blob` by default)
  * JSON encodes lists of integer numbers called Vectorial NumbeRs (VNRs)
  * BLOB is a generated, indexed column of a binary representation (provided by [`hollerith-code`
    tng])[https://github.com/loveencounterflow/hollerith-codec/blob/master/src/tng.coffee] of the VNR
  * the binary representation can be meaningfully sorted lexicographically by SQLite
  * VNRs support scenarios where you want to transform ordered items such that a given line (item, record)
    may result in any number of result lines (items, records) *and keep the relative ordering*
    * e.g. you store lines of a textfile as
      * `{ nr: 1, text: 'helo world', }`
      * `{ nr: 2, text: 'fancy stuff here', }`
      * `{ nr: 3, text: 'that's all', }`
    * say you want to transform that to a one-word-per-line format *in the same table*; now you have
      * `{ nr: 1, text: 'helo world', }`
      * `{ nr: ?, text: 'helo', }`
      * `{ nr: ?, text: 'world', }`
      * `{ nr: 2, text: 'fancy stuff here', }`
      * `{ nr: ?, text: 'fancy', }`
      * `{ nr: ?, text: 'stuff', }`
      * `{ nr: ?, text: 'here', }`
      * `{ nr: 3, text: 'that's all', }`
      * `{ nr: ?, text: 'that's', }`
      * `{ nr: ?, text: 'all', }`
    * For that to work, you'd have to (1) mark the orginal records as processed, and (2) find a way to
      enumerate the new lines such that they are correctly order.
    * What's more, wouldn't it be great if the enumeration could somehow preserve the origin of each new
      record?
    * We *could* just using consecutive numbers but then we'd have to renumber all entries whenever a single
      record got added somewhere in the middle. One could also use floating point numbers which gets messy
      soon.
    * Instead if we converted the `nr` field to a vector of numbers, we could do the following:
      * `{ vnr: [ 1,    ], text: 'helo world', }`
      * `{ vnr: [ 1, 1, ], text: 'helo', }`
      * `{ vnr: [ 1, 2, ], text: 'world', }`
      * `{ vnr: [ 2,    ], text: 'fancy stuff here', }`
      * `{ vnr: [ 2, 1, ], text: 'fancy', }`
      * `{ vnr: [ 2, 2, ], text: 'stuff', }`
      * `{ vnr: [ 2, 3, ], text: 'here', }`
      * `{ vnr: [ 3,    ], text: 'that's all', }`
      * `{ vnr: [ 3, 1, ], text: 'that's', }`
      * `{ vnr: [ 3, 2, ], text: 'all', }`

* Links
  * [VNRs](https://github.com/loveencounterflow/datom/blob/master/src/vnr.coffee)
    * [tests](https://github.com/loveencounterflow/hengist/blob/master/dev/datom/src/vnr.test.coffee)
  * [`hollerith-codec`](https://github.com/loveencounterflow/hollerith-codec)
    * actually using the much faster, more restricted [`tng` version](https://github.com/loveencounterflow/hollerith-codec/blob/master/src/tng.coffee)
    * [tests and benchmarks](https://github.com/loveencounterflow/hengist/tree/master/dev/hollerith-codec/src)

## To Do

* [ ] documentation
  * [ ] API
  * [ ] DB structure

