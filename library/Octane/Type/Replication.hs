{-# LANGUAGE DeriveGeneric #-}

module Octane.Type.Replication (Replication(..)) where

import qualified Control.DeepSeq as DeepSeq
import qualified GHC.Generics as Generics

data Replication = Replication
    { replicationActorId :: Int
    , replicationIsOpen :: Bool
    , replicationIsNew :: Maybe Bool
    } deriving (Eq,Generics.Generic,Show)

instance DeepSeq.NFData Replication
