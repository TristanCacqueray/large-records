{-# LANGUAGE DataKinds #-}

module Bench.EvensOfSize.Evens040 (Evens(..)) where

import Bench.Types

data Evens = Evens {
    -- 00 .. 09
    evens00 :: !(T 00)
  , evens02 :: !(T 02)
  , evens04 :: !(T 04)
  , evens06 :: !(T 06)
  , evens08 :: !(T 08)
    -- 10 .. 19
  , evens10 :: !(T 10)
  , evens12 :: !(T 12)
  , evens14 :: !(T 14)
  , evens16 :: !(T 16)
  , evens18 :: !(T 18)
    -- 20 .. 29
  , evens20 :: !(T 20)
  , evens22 :: !(T 22)
  , evens24 :: !(T 24)
  , evens26 :: !(T 26)
  , evens28 :: !(T 28)
    -- 30 .. 39
  , evens30 :: !(T 30)
  , evens32 :: !(T 32)
  , evens34 :: !(T 34)
  , evens36 :: !(T 36)
  , evens38 :: !(T 38)
  }
