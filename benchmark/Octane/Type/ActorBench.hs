{-# LANGUAGE OverloadedStrings #-}

module Octane.Type.ActorBench (benchmarks) where

import Criterion
import qualified Data.Binary as Binary
import qualified Data.Binary.Get as Binary
import qualified Data.ByteString.Lazy as BSL
import Octane

benchmarks :: Benchmark
benchmarks = bgroup "Actor"
    [ bench "decode basic" (whnf decodeActor "\1\0\0\0\0\0\0\0\0")
    , bench "encode basic" (whnf Binary.encode (NewActor (NewPCString "") (NewInt32LE 0)))
    ]

decodeActor :: BSL.ByteString -> Either (BSL.ByteString, Binary.ByteOffset, String) (BSL.ByteString, Binary.ByteOffset, Actor)
decodeActor = Binary.decodeOrFail
