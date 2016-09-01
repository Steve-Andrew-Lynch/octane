{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE StrictData #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}

module Octane.Type.Property
  ( Property(..)
  , ArrayProperty(..)
  , module Octane.Type.Property.BoolProperty
  , module Octane.Type.Property.ByteProperty
  , module Octane.Type.Property.FloatProperty
  , module Octane.Type.Property.IntProperty
  , module Octane.Type.Property.NameProperty
  , module Octane.Type.Property.QWordProperty
  , module Octane.Type.Property.StrProperty
  ) where

import Data.Aeson ((.=))
import Data.Function ((&))
import Octane.Type.Property.BoolProperty
import Octane.Type.Property.ByteProperty
import Octane.Type.Property.FloatProperty
import Octane.Type.Property.IntProperty
import Octane.Type.Property.NameProperty
import Octane.Type.Property.QWordProperty
import Octane.Type.Property.StrProperty

import qualified Control.DeepSeq as DeepSeq
import qualified Data.Aeson as Aeson
import qualified Data.Binary as Binary
import qualified Data.Default.Class as Default
import qualified Data.OverloadedRecords.TH as OverloadedRecords
import qualified GHC.Generics as Generics
import qualified Octane.Type.Dictionary as Dictionary
import qualified Octane.Type.List as List
import qualified Octane.Type.Text as Text
import qualified Octane.Type.Word64 as Word64

data ArrayProperty = ArrayProperty
  { arrayPropertySize :: Word64.Word64
  , arrayPropertyContent :: List.List (Dictionary.Dictionary Property)
  } deriving (Eq, Generics.Generic, Show)

instance Binary.Binary ArrayProperty where
  get = do
    size <- Binary.get
    content <- Binary.get
    pure (ArrayProperty size content)
  put array = do
    array & #size & Binary.put
    array & #content & Binary.put

instance DeepSeq.NFData ArrayProperty

instance Aeson.ToJSON ArrayProperty where
  toJSON array =
    Aeson.object
      [ "Type" .= ("Array" :: Text.Text)
      , "Size" .= #size array
      , "Value" .= #content array
      ]

-- | A metadata property. All properties have a size, but only some actually
-- use it. The value stored in the property can be an array, a boolean, and
-- so on.
data Property
  = PropertyArray ArrayProperty
  | PropertyBool BoolProperty
  | PropertyByte ByteProperty
  | PropertyFloat FloatProperty
  | PropertyInt IntProperty
  | PropertyName NameProperty
  | PropertyQWord QWordProperty
  | PropertyStr StrProperty
  deriving (Eq, Generics.Generic, Show)

$(OverloadedRecords.overloadedRecords Default.def [''ArrayProperty])

-- | Stored with the size first, then the value.
instance Binary.Binary Property where
  get = do
    kind <- Binary.get
    case kind of
      _
        | kind == arrayProperty -> do
          array <- Binary.get
          pure (PropertyArray array)
      _
        | kind == boolProperty -> do
          bool <- Binary.get
          pure (PropertyBool bool)
      _
        | kind == byteProperty -> do
          byte <- Binary.get
          pure (PropertyByte byte)
      _
        | kind == floatProperty -> do
          float <- Binary.get
          pure (PropertyFloat float)
      _
        | kind == intProperty -> do
          int <- Binary.get
          pure (PropertyInt int)
      _
        | kind == nameProperty -> do
          name <- Binary.get
          pure (PropertyName name)
      _
        | kind == qWordProperty -> do
          qWord <- Binary.get
          pure (PropertyQWord qWord)
      _
        | kind == strProperty -> do
          str <- Binary.get
          pure (PropertyStr str)
      _ -> fail ("unknown property type " ++ show (#unpack kind))
  put property =
    case property of
      PropertyArray array -> do
        Binary.put arrayProperty
        Binary.put array
      PropertyBool bool -> do
        Binary.put boolProperty
        Binary.put bool
      PropertyByte byte -> do
        Binary.put byteProperty
        Binary.put byte
      PropertyFloat float -> do
        Binary.put floatProperty
        Binary.put float
      PropertyInt int -> do
        Binary.put intProperty
        Binary.put int
      PropertyName name -> do
        Binary.put nameProperty
        Binary.put name
      PropertyQWord qWord -> do
        Binary.put qWordProperty
        Binary.put qWord
      PropertyStr str -> do
        Binary.put strProperty
        Binary.put str

instance DeepSeq.NFData Property

instance Aeson.ToJSON Property where
  toJSON property =
    case property of
      PropertyArray array -> Aeson.toJSON array
      PropertyBool bool -> Aeson.toJSON bool
      PropertyByte byte -> Aeson.toJSON byte
      PropertyFloat float -> Aeson.toJSON float
      PropertyInt int -> Aeson.toJSON int
      PropertyName name -> Aeson.toJSON name
      PropertyQWord qWord -> Aeson.toJSON qWord
      PropertyStr x -> Aeson.toJSON x

arrayProperty :: Text.Text
arrayProperty = "ArrayProperty"

boolProperty :: Text.Text
boolProperty = "BoolProperty"

byteProperty :: Text.Text
byteProperty = "ByteProperty"

floatProperty :: Text.Text
floatProperty = "FloatProperty"

intProperty :: Text.Text
intProperty = "IntProperty"

nameProperty :: Text.Text
nameProperty = "NameProperty"

qWordProperty :: Text.Text
qWordProperty = "QWordProperty"

strProperty :: Text.Text
strProperty = "StrProperty"
