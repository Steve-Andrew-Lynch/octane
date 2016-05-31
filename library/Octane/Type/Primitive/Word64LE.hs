{-# LANGUAGE DeriveGeneric #-}

module Octane.Type.Primitive.Word64LE (Word64LE(..)) where

import qualified Control.DeepSeq as DeepSeq
import qualified Data.Aeson as Aeson
import qualified Data.Binary as Binary
import qualified Data.Binary.Get as Binary
import qualified Data.Binary.Put as Binary
import Data.Function ((&))
import qualified Data.Int as Int
import qualified GHC.Generics as Generics

-- | A 64-bit little-endian integer.
newtype Word64LE = Word64LE
    { unpackWord64LE :: Int.Int64
    } deriving (Eq,Generics.Generic,Show)

instance Binary.Binary Word64LE where
    get = do
        word <- Binary.getWord64le
        word & fromIntegral & Word64LE & return
    put word = do
        word & unpackWord64LE & fromIntegral & Binary.putWord64le

instance DeepSeq.NFData Word64LE

instance Aeson.ToJSON Word64LE
