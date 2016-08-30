{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}

module Octane.Type.Word32 (Word32(..), fromWord32, toWord32) where

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
import qualified Data.Default.Class as Default
import qualified Data.OverloadedRecords.TH as OverloadedRecords
import qualified Data.Word as Word
import qualified GHC.Generics as Generics
import qualified Octane.Utility.Endian as Endian
import qualified Text.Printf as Printf


-- | A 32-bit unsigned integer.
newtype Word32 = Word32
    { word32Unpack :: Word.Word32
    } deriving (Eq, Generics.Generic, Num, Ord)

$(OverloadedRecords.overloadedRecord Default.def ''Word32)

-- | Little-endian.
instance Binary.Binary Word32 where
    get = do
        value <- Binary.getWord32le
        pure (Word32 value)

    put word32 = do
        let value = #unpack word32
        Binary.putWord32le value

-- | Little-endian with the bits in each byte reversed.
instance BinaryBit.BinaryBit Word32 where
    getBits _ = do
        bytes <- BinaryBit.getByteString 4
        bytes
            & LazyBytes.fromStrict
            & Endian.reverseBitsInLazyBytes
            & Binary.runGet Binary.get
            & pure

    putBits _ word32 = word32
        & Binary.put
        & Binary.runPut
        & Endian.reverseBitsInLazyBytes
        & LazyBytes.toStrict
        & BinaryBit.putByteString

instance DeepSeq.NFData Word32 where

-- | Shown as @0x01020304@.
instance Show Word32 where
    show word32 = Printf.printf "0x%08x" (#unpack word32)

-- | Encoded as a JSON number.
instance Aeson.ToJSON Word32 where
    toJSON word32 = word32
        & #unpack
        & Aeson.toJSON


-- | Converts a 'Word32' into any 'Integral' value.
fromWord32 :: (Integral a) => Word32 -> a
fromWord32 word32 = fromIntegral (#unpack word32)


-- | Converts any 'Integral' value into a 'Word32'.
toWord32 :: (Integral a) => a -> Word32
toWord32 value = Word32 (fromIntegral value)
