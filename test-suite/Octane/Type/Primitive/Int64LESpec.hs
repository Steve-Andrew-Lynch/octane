{-# LANGUAGE OverloadedStrings #-}

module Octane.Type.Primitive.Int64LESpec (spec) where

import qualified Data.Binary as Binary
import qualified Data.Binary.Get as Binary
import qualified Data.ByteString.Lazy as BSL
import Octane
import Test.Tasty.Hspec

spec :: Spec
spec = describe "Int64LE" $ do
    it "can be decoded" $ do
        shouldBe
            (decodeInt64LE "\0\0\0\0\0\0\0\0")
            (Right ("", 8, Int64LE 0))
        shouldBe
            (decodeInt64LE "\1\0\0\0\0\0\0\0")
            (Right ("", 8, Int64LE 1))
    it "can be encoded" $ do
        shouldBe
            (Binary.encode (Int64LE 0))
            "\0\0\0\0\0\0\0\0"
        shouldBe
            (Binary.encode (Int64LE 1))
            "\1\0\0\0\0\0\0\0"

decodeInt64LE :: BSL.ByteString -> Either (BSL.ByteString, Binary.ByteOffset, String) (BSL.ByteString, Binary.ByteOffset, Int64LE)
decodeInt64LE = Binary.decodeOrFail
