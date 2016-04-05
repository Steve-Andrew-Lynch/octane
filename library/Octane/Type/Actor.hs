{-# LANGUAGE DeriveGeneric #-}

module Octane.Type.Actor (Actor(..)) where

import qualified Control.DeepSeq as DeepSeq
import qualified Data.Aeson.Types as Aeson
import qualified Data.Binary as Binary
import Data.Function ((&))
import qualified GHC.Generics as Generics
import qualified Octane.Type.Primitive.PCString as PCString
import qualified Octane.Type.Primitive.Word32LE as Word32LE

data Actor = Actor
    { actorName :: PCString.PCString
    , actorTag :: Word32LE.Word32LE
    } deriving (Eq,Generics.Generic,Show)

instance Binary.Binary Actor where
    get = Actor <$> Binary.get <*> Binary.get
    put actor = do
        actor & actorName & Binary.put
        actor & actorTag & Binary.put

instance DeepSeq.NFData Actor

instance Aeson.ToJSON Actor where
    toJSON = 
        Aeson.genericToJSON
            Aeson.defaultOptions
            { Aeson.fieldLabelModifier = drop 5
            }
