{-# LANGUAGE CPP              #-}
{-# LANGUAGE TypeApplications #-}

#ifdef USE_GHC_DUMP
{-# OPTIONS_GHC -fplugin GhcDump.Plugin #-}
#endif

module Test.Record.Experiments.Induction.List.LI030 where

import Data.Proxy

import Test.Record.Experiments.Induction.List
import Test.Record.Experiments.HList.HL030

requiresInstance :: ()
requiresInstance = requireEmptyClass (Proxy @ExampleFields)
