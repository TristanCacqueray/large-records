module Main (main) where

import Test.Tasty

import qualified Test.Record.Generic.Sanity
import qualified Test.Record.Generic.Size.Sanity

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "Tests" [
      Test.Record.Generic.Sanity.tests
    , Test.Record.Generic.Size.Sanity.tests
    ]
