{-# LANGUAGE CPP             #-}
{-# LANGUAGE TemplateHaskell #-}

#if PROFILE_GEN_CODE
{-# OPTIONS_GHC -fplugin=GhcDump.Plugin #-}
#endif

module Test.Record.Generic.Size.After.HK080 where

import Data.Record.Generic.TH

import Test.Record.Generic.Size.Infra

largeRecord defaultLazyOptions (higherKindedRecordOfSize 80)
