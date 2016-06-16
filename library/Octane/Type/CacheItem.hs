{-# LANGUAGE DeriveGeneric #-}

module Octane.Type.CacheItem (CacheItem(..)) where

import qualified Control.DeepSeq as DeepSeq
import qualified Data.Aeson as Aeson
import qualified Data.Binary as Binary
import Data.Function ((&))
import qualified GHC.Generics as Generics
import qualified Octane.Json as Json
import qualified Octane.Type.CacheProperty as CacheProperty
import qualified Octane.Type.Primitive.List as List
import qualified Octane.Type.Primitive.Int32 as Int32

-- | An item in the class net cache map.
data CacheItem = CacheItem
    { cacheItemClassId :: !Int32.Int32
    , cacheItemParentCacheId :: !Int32.Int32
    , cacheItemCacheId :: !Int32.Int32
    , cacheItemCacheProperties :: !(List.List CacheProperty.CacheProperty)
    } deriving (Eq,Generics.Generic,Show)

instance Binary.Binary CacheItem where
    get = CacheItem <$> Binary.get <*> Binary.get <*> Binary.get <*> Binary.get
    put cacheItem = do
        cacheItem & cacheItemClassId & Binary.put
        cacheItem & cacheItemParentCacheId & Binary.put
        cacheItem & cacheItemCacheId & Binary.put
        cacheItem & cacheItemCacheProperties & Binary.put

instance DeepSeq.NFData CacheItem

instance Aeson.ToJSON CacheItem where
    toJSON = Aeson.genericToJSON (Json.toJsonOptions "CacheItem")
