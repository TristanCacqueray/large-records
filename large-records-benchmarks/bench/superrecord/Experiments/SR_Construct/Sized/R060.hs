#if PROFILE_CORESIZE
{-# OPTIONS_GHC -ddump-to-file -ddump-ds-preopt -ddump-ds -ddump-simpl #-}
#endif
#if PROFILE_TIMING
{-# OPTIONS_GHC -ddump-to-file -ddump-timings #-}
#endif
{-# LANGUAGE OverloadedLabels #-}

module Experiments.SR_Construct.Sized.R060 where

import SuperRecord

import Bench.Types
import Common.RowOfSize.Row060 (Row)

record :: Rec Row
record =
      -- 00 .. 09
      rcons (#t00 := MkT 00)
    $ rcons (#t01 := MkT 01)
    $ rcons (#t02 := MkT 02)
    $ rcons (#t03 := MkT 03)
    $ rcons (#t04 := MkT 04)
    $ rcons (#t05 := MkT 05)
    $ rcons (#t06 := MkT 06)
    $ rcons (#t07 := MkT 07)
    $ rcons (#t08 := MkT 08)
    $ rcons (#t09 := MkT 09)
      -- 10 .. 19
    $ rcons (#t10 := MkT 10)
    $ rcons (#t11 := MkT 11)
    $ rcons (#t12 := MkT 12)
    $ rcons (#t13 := MkT 13)
    $ rcons (#t14 := MkT 14)
    $ rcons (#t15 := MkT 15)
    $ rcons (#t16 := MkT 16)
    $ rcons (#t17 := MkT 17)
    $ rcons (#t18 := MkT 18)
    $ rcons (#t19 := MkT 19)
      -- 20 .. 29
    $ rcons (#t20 := MkT 20)
    $ rcons (#t21 := MkT 21)
    $ rcons (#t22 := MkT 22)
    $ rcons (#t23 := MkT 23)
    $ rcons (#t24 := MkT 24)
    $ rcons (#t25 := MkT 25)
    $ rcons (#t26 := MkT 26)
    $ rcons (#t27 := MkT 27)
    $ rcons (#t28 := MkT 28)
    $ rcons (#t29 := MkT 29)
      -- 30 .. 39
    $ rcons (#t30 := MkT 30)
    $ rcons (#t31 := MkT 31)
    $ rcons (#t32 := MkT 32)
    $ rcons (#t33 := MkT 33)
    $ rcons (#t34 := MkT 34)
    $ rcons (#t35 := MkT 35)
    $ rcons (#t36 := MkT 36)
    $ rcons (#t37 := MkT 37)
    $ rcons (#t38 := MkT 38)
    $ rcons (#t39 := MkT 39)
      -- 40 .. 49
    $ rcons (#t40 := MkT 40)
    $ rcons (#t41 := MkT 41)
    $ rcons (#t42 := MkT 42)
    $ rcons (#t43 := MkT 43)
    $ rcons (#t44 := MkT 44)
    $ rcons (#t45 := MkT 45)
    $ rcons (#t46 := MkT 46)
    $ rcons (#t47 := MkT 47)
    $ rcons (#t48 := MkT 48)
    $ rcons (#t49 := MkT 49)
      -- 50 .. 59
    $ rcons (#t50 := MkT 50)
    $ rcons (#t51 := MkT 51)
    $ rcons (#t52 := MkT 52)
    $ rcons (#t53 := MkT 53)
    $ rcons (#t54 := MkT 54)
    $ rcons (#t55 := MkT 55)
    $ rcons (#t56 := MkT 56)
    $ rcons (#t57 := MkT 57)
    $ rcons (#t58 := MkT 58)
    $ rcons (#t59 := MkT 59)
    $ rnil
