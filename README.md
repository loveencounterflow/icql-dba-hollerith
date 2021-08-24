
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
    * `{ nr: 3, text: 'that\'s all', }`
  * say you want to transform that to a one-word-per-line format *in the same table*; now you have
    * `{ nr: 1, text: 'helo world', }`
    * `{ nr: ?, text: 'helo', }`
    * `{ nr: ?, text: 'world', }`
    * `{ nr: 2, text: 'fancy stuff here', }`
    * `{ nr: ?, text: 'fancy', }`
    * `{ nr: ?, text: 'stuff', }`
    * `{ nr: ?, text: 'here', }`
    * `{ nr: 3, text: 'that\'s all', }`
    * `{ nr: ?, text: 'that's', }`
    * `{ nr: ?, text: 'all', }`
  * For that to work, you'd have to (1) mark the orginal records as processed (not covered here), and (2)
    find a way to enumerate the new lines such that they are correctly ordered.
  * What's more, wouldn't it be great if the enumeration could somehow preserve the origin of each new
    record?
  * We *could* just use consecutive numbers but then we'd have to renumber all entries whenever a single
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
    * `{ vnr: [ 3,    ], text: 'that\'s all', }`
    * `{ vnr: [ 3, 1, ], text: 'that\'s', }`
    * `{ vnr: [ 3, 2, ], text: 'all', }`
  * As it stands, we can store the VNRs as JSON (that is, as texts as far as SQLite is concerned).
    However, that is not bound to give us the intended because the lexicographic sorting of
    numbers-as-texts is not numerically monotonous (`'1'` comes before `'10'` which comes before `'2'`
    etc.)
  * This is why we turn the JSON lists into Binary Large OBjects (BLOBs) that SQLite will order correctly
    out of the box.
  * We do this by adding a `vnr_blob` field:

    ```sql
    alter table myfiles
      add column vnr_blob blob generated always as ( vnr_encode( vnr ) ) virtual not null;
    ```

  * The `vnr_blob` field is generated but not stored, meaning it will be re-generated on each `select`
    that includes it. That sounds inefficient—and it would be, were it not for an index we also add:

    ```sql
    create unique index myfiles_vnr_blob_idx
      on myfiles ( vnr_encode( vnr ) );
    ```

  * issuing `select * from myfiles order by vnr_blob;` now gives us this display:

  ```
  ┌──────────────────┬───────┬────────────────────────────────────────────────────────────────────┐
  │text              │vnr    │vnr_blob                                                            │
  ├──────────────────┼───────┼────────────────────────────────────────────────────────────────────┤
  │helo world        │[1]    │<Buffer 80 00 00 01 80 00 00 00 80 00 00 00 80 00 00 00 80 00 00 00>│
  │helo              │[1,1]  │<Buffer 80 00 00 01 80 00 00 01 80 00 00 00 80 00 00 00 80 00 00 00>│
  │world             │[1,2]  │<Buffer 80 00 00 01 80 00 00 02 80 00 00 00 80 00 00 00 80 00 00 00>│
  │fancy stuff here  │[2]    │<Buffer 80 00 00 02 80 00 00 00 80 00 00 00 80 00 00 00 80 00 00 00>│
  │fancy             │[2,1]  │<Buffer 80 00 00 02 80 00 00 01 80 00 00 00 80 00 00 00 80 00 00 00>│
  │stuff             │[2,2]  │<Buffer 80 00 00 02 80 00 00 02 80 00 00 00 80 00 00 00 80 00 00 00>│
  │here              │[2,3]  │<Buffer 80 00 00 02 80 00 00 03 80 00 00 00 80 00 00 00 80 00 00 00>│
  │that's all        │[3]    │<Buffer 80 00 00 03 80 00 00 00 80 00 00 00 80 00 00 00 80 00 00 00>│
  │that's            │[3,1]  │<Buffer 80 00 00 03 80 00 00 01 80 00 00 00 80 00 00 00 80 00 00 00>│
  │all               │[3,2]  │<Buffer 80 00 00 03 80 00 00 02 80 00 00 00 80 00 00 00 80 00 00 00>│
  └──────────────────┴───────┴────────────────────────────────────────────────────────────────────┘
  ```

  * observe that all BLOBs in the above are of equal length. This is a restriction of the [`better-sqlite3`
    API](https://github.com/JoshuaWise/better-sqlite3/blob/master/docs/api.md) which sadly is missing a way
    to [define one's own collations / `cmp` functions](https://sqlite.org/c3ref/create_collation.html)



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

