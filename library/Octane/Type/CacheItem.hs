{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE StrictData #-}

module Octane.Type.CacheItem (CacheItem(..)) where

import Data.Function ((&))

import qualified Control.DeepSeq as DeepSeq
import qualified Data.Binary as Binary
import qualified GHC.Generics as Generics
import qualified Octane.Type.CacheProperty as CacheProperty
import qualified Octane.Type.List as List
import qualified Octane.Type.Word32 as Word32

-- $setup
-- >>> :set -XOverloadedLists


-- | An item in the class net cache map.
data CacheItem = CacheItem
    { classId :: Word32.Word32
    -- ^ The class ID.
    , parentCacheId :: Word32.Word32
    -- ^ The cache ID of the parent class.
    , cacheId :: Word32.Word32
    -- ^ The cache ID of the class.
    , properties :: List.List CacheProperty.CacheProperty
    -- ^ The properties that belong to this class.
    } deriving (Eq, Generics.Generic, Show)

-- | Fields are stored one after the other in order.
--
-- >>> Binary.decode "\x01\x00\x00\x00\x02\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00" :: CacheItem
-- CacheItem {classId = 0x00000001, parentCacheId = 0x00000002, cacheId = 0x00000003, properties = List {unpack = []}}
--
-- >>> Binary.encode (CacheItem 1 2 3 [])
-- "\SOH\NUL\NUL\NUL\STX\NUL\NUL\NUL\ETX\NUL\NUL\NUL\NUL\NUL\NUL\NUL"
instance Binary.Binary CacheItem where
    get = CacheItem
        <$> Binary.get
        <*> Binary.get
        <*> Binary.get
        <*> Binary.get

    put cacheItem = do
        cacheItem & classId & Binary.put
        cacheItem & parentCacheId & Binary.put
        cacheItem & cacheId & Binary.put
        cacheItem & properties & Binary.put

instance DeepSeq.NFData CacheItem where
