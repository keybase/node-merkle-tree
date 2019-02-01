## 1.0.5 (2019-02-01)

- Use Buffer.allow, not (new Buffer)

## 1.0.4 (2018-11-16)

- Recompile with modern ICS (it was quite ancient previously)

## 1.0.3 (2018-11-15)

- Passback root from fullbuild

## 1.0.2 (2018-11-15)

- Passback prev root also

## 1.0.1 (2018-11-14)

- Also pass txinfo through full tree rebuilds

## 1.0.0 (2018-11-14)

- Pass in txinfo to lookup_root too; it's optional, it will only be filled
  in on an upsert.

## 0.0.14 (2015-02-13)

Bugfixes:

   - proper errors if unimplemented

## 0.0.13 (2014-10-13)

Bugfixes:

  - bugs in comments

Refactor:

  - can access the prefix-computation code with only a config, no tree
    needeed.

## 0.0.12 (2014-06-20)

Bugfixes:

  - Don't fixate on a runtime

## 0.0.11 (2014-06-19)

Features:

  - Still include the prev_root on a full rebuild

## 0.0.10 (2014-06-19)

Features:

  - Embed the previous root in the current rootblock.

## 0.0.9 (2014-06-04)

Features:

  - Upgrade to ICS v1.7.1-c


## 0.0.8 (2014-05-23)

Features

   - Allow sigs of roots to chain; expose the previous root
