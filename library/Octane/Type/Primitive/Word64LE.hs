{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Octane.Type.Primitive.Word64LE (Word64LE(..)) where

import qualified Data.Binary.Get as Binary
import qualified Data.Binary.Put as Binary
import Octane.Core

-- | A 64-bit little-endian integer.
newtype Word64LE = Word64LE
    { getWord64LE :: Word64
    } deriving (Eq, Generic, NFData, Show)

instance Binary Word64LE where
    get = do
        int <- Binary.getWord64le
        int & fromIntegral & Word64LE & return

    put (Word64LE int) = do
        int & fromIntegral & Binary.putWord64le