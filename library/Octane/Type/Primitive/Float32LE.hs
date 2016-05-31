{-# LANGUAGE DeriveGeneric #-}

module Octane.Type.Primitive.Float32LE (Float32LE(..)) where

import qualified Control.DeepSeq as DeepSeq
import qualified Control.Newtype as Newtype
import qualified Data.Aeson as Aeson
import qualified Data.Binary as Binary
import qualified Data.Binary.IEEE754 as IEEE754
import Data.Function ((&))
import qualified GHC.Generics as Generics

-- | A 32-bit little-endian float.
newtype Float32LE = Float32LE
    { unpackFloat32LE :: Float
    } deriving (Eq,Generics.Generic,Show)

instance Binary.Binary Float32LE where
    get = do
        float <- IEEE754.getFloat32le
        float & Newtype.pack & return
    put float = do
        float & Newtype.unpack & IEEE754.putFloat32le

instance Newtype.Newtype Float32LE

instance DeepSeq.NFData Float32LE

instance Aeson.ToJSON Float32LE
