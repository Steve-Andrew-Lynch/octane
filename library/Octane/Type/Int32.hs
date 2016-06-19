{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Octane.Type.Int32 (Int32(..), fromInt32, toInt32) where

import Data.Function ((&))

import qualified Control.DeepSeq as DeepSeq
import qualified Data.Aeson as Aeson
import qualified Data.Binary as Binary
import qualified Data.Binary.Bits as BinaryBit
import qualified Data.Binary.Bits.Get as BinaryBit
import qualified Data.Binary.Bits.Put as BinaryBit
import qualified Data.Binary.Get as Binary
import qualified Data.Binary.Put as Binary
import qualified Data.ByteString.Lazy as LazyBytes
import qualified Data.Int as Int
import qualified GHC.Generics as Generics
import qualified Octane.Utility.Endian as Endian


-- | A 32-bit signed integer.
newtype Int32 = Int32
    { unpack :: Int.Int32
    } deriving (Eq, Generics.Generic, Num, Ord)

-- | Stored in little-endian byte order.
instance Binary.Binary Int32 where
    get = do
        value <- Binary.getInt32le
        pure (Int32 value)

    put int32 = do
        let value = unpack int32
        Binary.putInt32le value

instance BinaryBit.BinaryBit Int32 where
    getBits _ = do
        bytes <- BinaryBit.getByteString 4
        bytes
            & LazyBytes.fromStrict
            & Endian.reverseBitsInBytes
            & Binary.runGet Binary.get
            & pure

    putBits _ int32 = int32
        & Binary.put
        & Binary.runPut
        & Endian.reverseBitsInBytes
        & LazyBytes.toStrict
        & BinaryBit.putByteString

instance DeepSeq.NFData Int32 where

-- | Shown as @1234@.
instance Show Int32 where
    show int32 = show (unpack int32)

instance Aeson.ToJSON Int32 where
    toJSON int32 = int32
        & unpack
        & Aeson.toJSON


-- | Converts a 'Int32' into any 'Integral' value.
--
-- >>> fromInt32 1 :: Int.Int32
-- 1
fromInt32 :: (Integral a) => Int32 -> a
fromInt32 int32 = fromIntegral (unpack int32)


-- | Converts any 'Integral' value into a 'Int32'.
--
-- >>> toInt32 (1 :: Int.Int32)
-- 1
toInt32 :: (Integral a) => a -> Int32
toInt32 value = Int32 (fromIntegral value)