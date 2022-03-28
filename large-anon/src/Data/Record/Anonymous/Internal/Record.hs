{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE GADTs                 #-}
{-# LANGUAGE KindSignatures        #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NamedFieldPuns        #-}
{-# LANGUAGE PolyKinds             #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE RecordWildCards       #-}
{-# LANGUAGE RoleAnnotations       #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeApplications      #-}
{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE ViewPatterns          #-}

{-# OPTIONS_GHC -Wno-redundant-constraints #-}

-- | Full record representation
--
-- Intended for qualified import.
--
-- > import Data.Record.Anonymous.Internal.Record (Record)
-- > import qualified Data.Record.Anonymous.Internal.Record as Record
module Data.Record.Anonymous.Internal.Record (
    -- * Representation
    Record(..)
  , canonicalize
  , unsafeFromCanonical
    -- * Main API
  , Field(..)
  , empty
  , insert
  , insertA
  , get
  , set
  , merge
  , lens
  , project
  , applyDiff
    -- * Support for @typelet@
  , letRecordT
  , letInsertAs
  ) where

import Data.Bifunctor
import Data.Kind
import Data.Proxy
import Data.Record.Generic.Rep.Internal (noInlineUnsafeCo)
import GHC.Exts (Any)
import GHC.OverloadedLabels
import GHC.Records.Compat
import GHC.TypeLits
import TypeLet.UserAPI

import Data.Record.Anonymous.Internal.Canonical (Canonical)
import Data.Record.Anonymous.Internal.Diff (Diff)
import Data.Record.Anonymous.Internal.Row
import Data.Record.Anonymous.Internal.Row.FieldName (KnownHash)

import qualified Data.Record.Anonymous.Internal.Canonical     as Canon
import qualified Data.Record.Anonymous.Internal.Diff          as Diff
import qualified Data.Record.Anonymous.Internal.Row.FieldName as FieldName

{-------------------------------------------------------------------------------
  Representation
-------------------------------------------------------------------------------}

-- | Anonymous record
--
-- A @Record f xs@ has a field @n@ of type @f x@ for every @(n, x)@ in @xs@.
--
-- To access fields of the record, either use the 'HasField' instances
-- (possibly using the record-dot-preprocessor to get record-dot syntax),
-- or using the simple wrappers 'get' and 'set'. The 'HasField' instances
-- are resolved by the plugin, so be sure to use
--
-- > {-# OPTIONS_GHC -fplugin=Data.Record.Anonymous.Plugin #-}
--
-- Let's consider a few examples. After we define
--
-- > example :: Record '[ '("a", Bool) ]
-- > example = insert #a True empty
--
-- we get
--
-- >>> get #a example -- or @example.a@ if using RecordDotSyntax
-- I True
--
-- >>> get #b example
-- ...
-- ...No instance for (HasField "b" (Record...
-- ...
--
-- >>> get #a example :: I Int
-- ...
-- ...Couldn't match...Int...Bool...
-- ...
--
-- When part of the record is not known, it might not be possible to resolve a
-- 'HasField' constraint until later. For example, in
--
-- >>> (\r -> get #x r) :: Record I '[ '(f, a), '("x", b) ] -> I b
-- ...
-- ...No instance for (HasField "x" (...
-- ...
--
-- This is important, because if @f == "x"@, this would only be sound if also
-- @a == b@. We /could/ introduce a new constraint to say precisely that, but
-- it would have little benefit; instead we just leave the 'HasField' constraint
-- unresolved until we know more about the record.
data Record (f :: k -> Type) (r :: Row k) = Record {
      recordDiff  :: !(Diff f)
    , recordCanon :: !(Canonical f)
    }

type role Record nominal representational

-- | Construct canonical form of the record (i.e., apply the internal 'Diff')
--
-- This is @O(n)@, and should be done only for operations on records that are
-- @O(n)@ /anyway/, so that the cost can be absorbed.
canonicalize :: Record f r -> Canonical f
canonicalize Record{..} = Diff.apply recordDiff recordCanon

-- | Construct 'Record' from 'Canonical' representation (empty 'Diff')
--
-- This function is unsafe because we cannot verify whether the record matches
-- it's row specification @r@.
unsafeFromCanonical :: Canonical f -> Record f r
unsafeFromCanonical canon = Record {
      recordDiff  = Diff.empty
    , recordCanon = canon
    }

{-------------------------------------------------------------------------------
  Main API
-------------------------------------------------------------------------------}

-- | Proxy for a field name, with 'IsLabel' instance
--
-- The 'IsLabel' instance makes it possible to write
--
-- > #foo
--
-- to mean
--
-- > Field (Proxy @"foo")
data Field n where
  Field :: (KnownSymbol n, KnownHash n) => Proxy n -> Field n

instance (n ~ n', KnownSymbol n, KnownHash n) => IsLabel n' (Field n) where
  fromLabel = Field (Proxy @n)

-- | Empty record
empty :: Record f '[]
empty = Record Diff.empty mempty

-- | Insert new field
insert :: Field n -> f a -> Record f r -> Record f (n := a : r)
insert (Field n) x r@Record{recordDiff} = r {
      recordDiff = Diff.insert (FieldName.symbolVal n) (co x) recordDiff
    }
  where
    co :: f a -> f Any
    co = noInlineUnsafeCo

-- | Applicative insert
--
-- This is a simple wrapper around 'insert', but can be quite useful when
-- constructing records. Consider code like
--
-- > foo :: m (a, b, c)
-- > foo = (,,) <$> action1
-- >            <*> action2
-- >            <*> action3
--
-- We cannot really extend this to the world of named records, but we /can/
-- do something comparable using anonymous records:
--
-- > foo :: m (Record f '[ "x" := a, "y" := b, "z" := c ])
-- >    insertA #x action1
-- >  $ insertA #y action2
-- >  $ insertA #z action3
-- >  $ pure Anon.empty
insertA ::
     Applicative m
  => Field n -> m (f a) -> m (Record f r) -> m (Record f (n := a : r))
insertA f x r = insert f <$> x <*> r

-- | Get field from the record
--
-- This is just a wrapper around 'getField'
get :: forall n f r a.
     HasField n (Record f r) a
  => Field n -> Record f r -> a
get _ = getField @n @(Record f r)

-- | Update field in the record
--
-- This is just a wrapper around 'setField'.
set :: forall n f r a.
     HasField n (Record f r) a
  => Field n -> a -> Record f r -> Record f r
set _ = flip (setField @n @(Record f r))

-- | Merge two records
--
-- 'HasField' constraint can be resolved for merged records, subject to the same
-- condition discussed in the documentation of 'Record': since records are left
-- biased, all fields in the record must be known up to the requested field:
--
-- Simple example, completely known record:
--
-- >>> :{
--   let example :: Record I (Merge '[ '("a", Bool)] '[ '("b", Char)])
--       example = merge (insert #a (I True) empty) (insert #b (I 'a') empty)
--   in get #b example
-- :}
-- I 'a'
--
-- Slightly more sophisticated, only part of the record known:
--
-- >>> :{
--   let example :: Record I (Merge '[ '("a", Bool)] r) -> I Bool
--       example = get #a
--   in example (merge (insert #a (I True) empty) (insert #b (I 'a') empty))
-- :}
-- I True
--
-- Rejected example: first part of the record unknown:
--
-- >>> :{
--   let example :: Record I (Merge r '[ '("b", Char)]) -> I Char
--       example = get #b
--   in example (merge (insert #a (I True) empty) (insert #b (I 'a') empty))
-- :}
-- ...
-- ...No instance for (HasField "b" (...
-- ...
merge :: Record f r -> Record f r' -> Record f (Merge r r')
merge (canonicalize -> r) (canonicalize -> r') =
    unsafeFromCanonical $ r <> r'

-- | Lens from one record to another
--
-- TODO: Update docs (these are still from the old castRecord).
-- TODO: Make all doctests work agian.
--
-- Some examples of valid casts. We can cast a record to itself:
--
-- >>> castRecord example :: Record I '[ '("a", Bool) ]
-- Record {a = I True}
--
-- We can reorder fields:
--
-- >>> castRecord (insert #a (I True) $ insert #b (I 'a') $ empty) :: Record I '[ '("b", Char), '("a", Bool) ]
-- Record {b = I 'a', a = I True}
--
-- We can flatten merged records:
--
-- >>> castRecord (merge (insert #a (I True) empty) (insert #b (I 'a') empty)) :: Record I '[ '("a", Bool), '("b", Char) ]
-- Record {a = I True, b = I 'a'}
--
-- Some examples of invalid casts. We cannot change the types of the fields:
--
-- >>> castRecord example :: Record I '[ '("a", Int) ]
-- ...
-- ...Couldn't match...Bool...Int...
-- ...
--
-- We cannot drop fields:
--
-- >>> castRecord (insert #a (I True) $ insert #b (I 'a') $ empty) :: Record I '[ '("a", Bool) ]
-- ...
-- ...No instance for (Isomorphic...
-- ...
--
-- We cannot add fields:
--
-- >>> castRecord example :: Record I '[ '("a", Bool), '("b", Char) ]
-- ...
-- ...No instance for (Isomorphic...
-- ...
lens :: forall f r r'.
     Project f r r'
  => Record f r -> (Record f r', Record f r' -> Record f r)
lens = \(canonicalize -> r) ->
    bimap getter setter $
      Canon.lens (projectIndices (Proxy @f) (Proxy @r) (Proxy @r')) r
  where
    getter :: Canonical f -> Record f r'
    getter = unsafeFromCanonical

    setter :: (Canonical f -> Canonical f) -> Record f r' -> Record f r
    setter f (canonicalize -> r) = unsafeFromCanonical (f r)

-- | Project out subrecord
--
-- This is just @fst . lens@.
project :: Project f r r' => Record f r -> Record f r'
project = fst . lens

-- | Apply all pending changes to the record
--
-- Updates on a record are stored in a hash table. As this hashtable grows,
-- record field access and update will become more expensive. Applying the
-- updates, resulting in a flat vector, is an @O(n)@ operation. This will happen
-- automatically whenever another @O(n)@ operation is applied (for example,
-- mapping a function over the record). However, cccassionally it is useful to
-- explicitly apply these changes, for example after constructing a record or
-- updating a lot of fields.
applyDiff :: Record f r -> Record f r
applyDiff (canonicalize -> r) = unsafeFromCanonical r

{-------------------------------------------------------------------------------
  Support for @typelet@
-------------------------------------------------------------------------------}

-- | Introduce type variable for a row
--
-- This can be used in conjunction with 'letInsertAs':
--
-- > example :: Record I '[ "a" := Int, "b" := Char, "c" := Bool ]
-- > example = letRecordT $ \p -> castEqual $
-- >     letInsertAs p #c (I True) empty $ \xs02 ->
-- >     letInsertAs p #b (I 'X' ) xs02  $ \xs01 ->
-- >     letInsertAs p #a (I 1   ) xs01  $ \xs00 ->
-- >     castEqual xs00
letRecordT :: forall r f.
     (forall r'. Let r' r => Proxy r' -> Record f r)
  -> Record f r
letRecordT f = letT' (Proxy @r) f

-- | Insert field into a record and introduce type variable for the result
letInsertAs :: forall r r' f n a.
     Proxy r       -- ^ Type of the record we are constructing
  -> Field n       -- ^ New field to be inserted
  -> f a           -- ^ Value of the new field
  -> Record f r'   -- ^ Record constructed so far
  -> (forall r''. Let r'' (n := a : r') => Record f r'' -> Record f r)
                   -- ^ Assign type variable to new partial record, and continue
  -> Record f r
letInsertAs _ n x r = letAs' (insert n x r)



