{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE StrictData #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}

module Octane.Type.Value.FlaggedIntValue
  ( FlaggedIntValue(..)
  ) where

import Data.Aeson ((.=))

import qualified Data.Aeson as Aeson
import qualified Data.Default.Class as Default
import qualified Data.OverloadedRecords.TH as OverloadedRecords
import qualified Data.Text as StrictText
import qualified Octane.Type.Boolean as Boolean
import qualified Octane.Type.Int32 as Int32

data FlaggedIntValue = FlaggedIntValue
  { flaggedIntValueFlag :: Boolean.Boolean
  , flaggedIntValueInt :: Int32.Int32
  } deriving (Eq, Show)

$(OverloadedRecords.overloadedRecord Default.def ''FlaggedIntValue)

instance Aeson.ToJSON FlaggedIntValue where
  toJSON x =
    Aeson.object
      [ "Type" .= ("FlaggedInt" :: StrictText.Text)
      , "Value" .= Aeson.object ["Flag" .= #flag x, "Int" .= #int x]
      ]
