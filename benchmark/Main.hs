module Main (main) where

import qualified Criterion.Main as Criterion
import qualified OctaneBench


main :: IO ()
main = Criterion.defaultMain bench


bench :: [Criterion.Benchmark]
bench =
    [ OctaneBench.bench
    ]