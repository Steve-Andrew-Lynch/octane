module Octane.Type.ObjectMap (ObjectMap(..)) where

import qualified Data.IntMap as IntMap
import Octane.Core
import Octane.Type.Primitive.PCString
import Octane.Type.Primitive.List

newtype ObjectMap = NewObjectMap
    { getObjectMap :: IntMap PCString
    } deriving (Show)

instance Binary ObjectMap where
    get = do
        NewList objects <- get
        objects & zip [0 ..] & IntMap.fromAscList & NewObjectMap & return

    put (NewObjectMap objects) = do
        objects & IntMap.elems & NewList & put