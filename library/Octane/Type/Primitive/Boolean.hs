{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Octane.Type.Primitive.Boolean (Boolean(..)) where

import Octane.Core

newtype Boolean = Boolean
    { getBoolean :: Bool
    } deriving (Eq, Generic, NFData, Show)

instance Binary Boolean where
    get = do
        boolean <- getWord8
        if boolean > 1
        then fail "out of bounds"
        else boolean & fromIntegral & toEnum & Boolean & return

    put (Boolean boolean) = do
        boolean & fromEnum & fromIntegral & putWord8
