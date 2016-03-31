{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}

module Octane.Type.Actor (Actor(..)) where

import Octane.Internal.Core
import Octane.Type.Primitive.PCString
import Octane.Type.Primitive.Word32LE

data Actor = Actor
    { actorName :: PCString
    , actorTag :: Word32LE
    } deriving (Eq, Generic, NFData, Show)

instance Binary Actor where
    get = Actor
        <$> get
        <*> get

    put actor = do
        actor & actorName & put
        actor & actorTag & put

instance ToJSON Actor where
    toJSON = genericToJSON defaultOptions { fieldLabelModifier = drop 5 }
