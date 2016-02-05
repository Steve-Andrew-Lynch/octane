module Octane.Type.PrimitiveSpec (spec) where

import qualified Octane.Type.Primitive.BooleanSpec
import qualified Octane.Type.Primitive.DictionarySpec
import qualified Octane.Type.Primitive.Float32LESpec
import qualified Octane.Type.Primitive.ListSpec
import qualified Octane.Type.Primitive.PCStringSpec
import qualified Octane.Type.Primitive.StreamSpec
import qualified Octane.Type.Primitive.Word32LESpec
import qualified Octane.Type.Primitive.Word64LESpec
import Test.Tasty.Hspec

spec :: Spec
spec = describe "Primitive" $ do
    Octane.Type.Primitive.BooleanSpec.spec
    Octane.Type.Primitive.DictionarySpec.spec
    Octane.Type.Primitive.Float32LESpec.spec
    Octane.Type.Primitive.ListSpec.spec
    Octane.Type.Primitive.PCStringSpec.spec
    Octane.Type.Primitive.StreamSpec.spec
    Octane.Type.Primitive.Word32LESpec.spec
    Octane.Type.Primitive.Word64LESpec.spec
