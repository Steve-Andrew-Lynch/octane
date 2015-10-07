{- |
    A little-endian 64-bit integer.
-}
module Octane.Types.Int64LE where

import qualified Data.Binary as Binary
import qualified Data.Binary.Get as Binary
import qualified Data.Binary.Put as Binary
import Flow ((|>))

newtype Int64LE = NewInt64LE {
    getInt64LE :: Binary.Word64
} deriving (Show)

instance Binary.Binary Int64LE where
    get = do
        word64LE <- Binary.getWord64le
        return NewInt64LE {
            getInt64LE = fromIntegral word64LE
        }

    put (NewInt64LE int64LE) = do
        int64LE |> fromIntegral |> Binary.putWord64le
