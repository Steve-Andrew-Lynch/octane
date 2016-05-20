{-# LANGUAGE DeriveGeneric #-}

module Octane.Parser where

import qualified Control.DeepSeq as DeepSeq
import qualified Control.Newtype as Newtype
import qualified Data.Binary.Bits.Get as Bits
import qualified Data.Binary.IEEE754 as IEEE754
import qualified Data.Binary.Get as Binary
import qualified Data.Bits as Bits
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BSL
import Data.Function ((&))
import qualified Data.IntMap as IntMap
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Debug.Trace as Trace
import qualified GHC.Generics as Generics
import qualified Octane.Type as Type
import qualified Text.Printf as Printf

parseFrames :: Type.Replay -> [Frame]
parseFrames replay = do
    let get = replay & extractContext & getFrames & Bits.runBitGet
        stream = replay & Type.replayStream & Newtype.unpack & BSL.fromStrict
    Binary.runGet get stream

getFrames :: Context -> Bits.BitGet [Frame]
getFrames context = do
    maybeFrame <- getMaybeFrame context
    case maybeFrame of
        Nothing -> return []
        Just frame -> do
            frames <- getFrames context
            return (frame : frames)

getMaybeFrame :: Context -> Bits.BitGet (Maybe Frame)
getMaybeFrame context = do
    timeBytes <- Bits.getByteString 4
    let time = byteStringToFloat timeBytes
    deltaBytes <- Bits.getByteString 4
    let delta = byteStringToFloat deltaBytes
    if BS.all (== 0) timeBytes && BS.all (== 0) deltaBytes
        then return Nothing
        else do
            frame <- getFrame context time delta
            return (Just frame)

getFrame :: Context -> Time -> Delta -> Bits.BitGet Frame
getFrame context time delta = do
    Trace.traceM ("Time:\t" ++ show time)
    Trace.traceM ("Delta:\t" ++ show delta)
    replications <- getReplications context
    let frame =
            Frame
            { frameTime = time
            , frameDelta = delta
            , frameReplications = replications
            }
    return frame

getReplications :: Context -> Bits.BitGet [Replication]
getReplications context = do
    (context',maybeReplication) <- getMaybeReplication context
    case maybeReplication of
        Nothing -> return []
        Just replication -> do
            replications <- getReplications context'
            return (replication : replications)

getMaybeReplication :: Context -> Bits.BitGet (Context, Maybe Replication)
getMaybeReplication context = do
    hasReplication <- Bits.getBool
    Trace.traceM ("Replication?:\t" ++ show hasReplication)
    if not hasReplication
        then return (context, Nothing)
        else do
            (newContext,replication) <- getReplication context
            return (newContext, Just replication)

getReplication :: Context -> Bits.BitGet (Context, Replication)
getReplication context = do
    actorId <- getInt maxChannels
    isOpen <- Bits.getBool
    Trace.traceM ("Actor ID:\t" ++ show actorId)
    Trace.traceM ("Open?:\t" ++ show isOpen)
    let go =
            if isOpen
                then getOpenReplication
                else getClosedReplication
    go context actorId

getOpenReplication :: Context
                   -> ActorId
                   -> Bits.BitGet (Context, Replication)
getOpenReplication context actorId = do
    isNew <- Bits.getBool
    Trace.traceM ("New?:\t" ++ show isNew)
    let go =
            if isNew
                then getNewReplication
                else getExistingReplication
    go context actorId

getNewReplication :: Context
                  -> ActorId
                  -> Bits.BitGet (Context, Replication)
getNewReplication context actorId = do
    unknownFlag <- Bits.getBool
    objectId <- getInt (2 ^ (32 :: Int))
    let objectName =
            context & contextObjectMap & IntMap.lookup objectId &
            Maybe.fromJust
    let (classId,className) =
            getClass (contextObjectMap context) objectId & Maybe.fromJust
    classInit <- getClassInit className
    Trace.traceM ("Flag:\t" ++ show unknownFlag)
    Trace.traceM ("Object ID:\t" ++ show objectId)
    Trace.traceM ("Class ID:\t" ++ show classId)
    Trace.traceM ("Object name:\t" ++ show objectName)
    Trace.traceM ("Class name:\t" ++ show className)
    Trace.traceM ("Initialization:\t" ++ show classInit)
    let thing = Thing
            { thingFlag = unknownFlag
            , thingObjectId = objectId
            , thingObjectName = objectName
            , thingClassId = classId
            , thingClassName = className
            , thingClassInit = classInit
            }
    let things = contextThings context
    let newThings = IntMap.insert actorId thing things
    let newContext = context { contextThings = newThings }
    return
        ( newContext
        , Replication
          { replicationActorId = actorId
          , replicationIsOpen = True
          , replicationIsNew = Just True
          })

getExistingReplication :: Context
                       -> ActorId
                       -> Bits.BitGet (Context, Replication)
getExistingReplication context actorId = do
    let thing = context & contextThings & IntMap.lookup actorId & Maybe.fromJust
    props <- getProps thing
    Trace.traceM ("Props:\t" ++ show props)
    return (context, Replication
        { replicationActorId = actorId
        , replicationIsOpen = True
        , replicationIsNew = Just False
        })

getClosedReplication :: Context
                     -> ActorId
                     -> Bits.BitGet (Context, Replication)
getClosedReplication context actorId = do
    let newThings = context & contextThings & IntMap.delete actorId
    let newContext = context { contextThings = newThings }
    return
        ( newContext
        , Replication
          { replicationActorId = actorId
          , replicationIsOpen = False
          , replicationIsNew = Nothing
          })

data Prop = Prop Int
    deriving (Show)

getProps :: Thing -> Bits.BitGet [Prop]
getProps thing = do
    maybeProp <- getMaybeProp thing
    case maybeProp of
        Nothing -> return []
        Just prop -> do
            props <- getProps thing
            return (prop : props)

getMaybeProp :: Thing -> Bits.BitGet (Maybe Prop)
getMaybeProp thing = do
    hasProp <- Bits.getBool
    if hasProp
    then do
        prop <- getProp thing
        return (Just prop)
    else return Nothing

getProp :: Thing -> Bits.BitGet Prop
getProp _thing = do
    -- TODO: Correctly read ID and actually read prop.
    propId <- getInt 1
    return (Prop propId)

-- | A frame in the net stream. Each frame has the time since the beginning of
-- | the match, the time since the last frame, and a list of replications.
data Frame = Frame
    { frameTime :: Float
    , frameDelta :: Float
    , frameReplications :: [Replication]
    } deriving (Eq,Generics.Generic,Show)

instance DeepSeq.NFData Frame

-- | Replication information about an actor in the net stream.
data Replication = Replication
    { replicationActorId :: Int
    , replicationIsOpen :: Bool
    , replicationIsNew :: Maybe Bool
    } deriving (Eq,Generics.Generic,Show)

instance DeepSeq.NFData Replication

data Thing = Thing
    { thingFlag :: Bool
    , thingObjectId :: Int
    , thingObjectName :: Text.Text
    , thingClassId :: Int
    , thingClassName :: Text.Text
    , thingClassInit :: ClassInit
    }

showAsHex :: BS.ByteString -> String
showAsHex bytes
    = bytes
    & BS.unpack
    & concatMap (\ byte -> Printf.printf "%02x" byte)

-- { stream id => object name }
type ObjectMap = IntMap.IntMap Text.Text

buildObjectMap :: Type.Replay -> ObjectMap
buildObjectMap replay =
    replay & Type.replayObjects & Newtype.unpack & map Newtype.unpack &
    zip [0 ..] &
    IntMap.fromAscList

-- { stream id => class name }
type ClassMap = IntMap.IntMap Text.Text

buildClassMap :: Type.Replay -> ClassMap
buildClassMap replay =
    replay & Type.replayActors & Newtype.unpack &
    map
        (\x ->
              ( x & Type.actorStreamId & Newtype.unpack & fromIntegral
              , x & Type.actorName & Newtype.unpack)) &
    IntMap.fromList

data CacheNode = CacheNode
    { cacheNodeClassId :: Int
    , cacheNodeParentCacheId :: Int
    , cacheNodeCacheId :: Int
    , cacheNodeProperties :: IntMap.IntMap Text.Text
    }

-- { class id => node }
type Cache = IntMap.IntMap CacheNode

buildCache :: Type.Replay -> Cache
buildCache replay =
    let objectMap = buildObjectMap replay
    in replay & Type.replayCacheItems & Newtype.unpack &
       map
           (\item ->
                 CacheNode
                 { cacheNodeClassId = item & Type.cacheItemClassId &
                   Newtype.unpack &
                   fromIntegral
                 , cacheNodeParentCacheId = item & Type.cacheItemParentCacheId &
                   Newtype.unpack &
                   fromIntegral
                 , cacheNodeCacheId = item & Type.cacheItemCacheId &
                   Newtype.unpack &
                   fromIntegral
                 , cacheNodeProperties = item & Type.cacheItemCacheProperties &
                   Newtype.unpack &
                   map
                       (\property ->
                             ( property & Type.cachePropertyStreamId &
                               Newtype.unpack &
                               fromIntegral
                             , property & Type.cachePropertyObjectId &
                               Newtype.unpack &
                               fromIntegral &
                               (\objectId ->
                                     IntMap.lookup objectId objectMap) &
                               Maybe.fromJust)) &
                   IntMap.fromList
                 }) &
       map
           (\node ->
                 (cacheNodeClassId node, node)) &
       IntMap.fromList

-- { class stream id => { property stream id => name } }
type ClassPropertyMap = IntMap.IntMap (IntMap.IntMap Text.Text)

getPropertyMap :: Cache -> Int -> IntMap.IntMap Text.Text
getPropertyMap cache cacheId =
    case IntMap.lookup cacheId cache of
        Nothing -> IntMap.empty
        Just node ->
            if cacheNodeParentCacheId node == 0 ||
               cacheNodeParentCacheId node == cacheId
                then cacheNodeProperties node
                else IntMap.union
                         (cacheNodeProperties node)
                         (getPropertyMap cache (cacheNodeParentCacheId node))

buildClassPropertyMap :: Type.Replay -> ClassPropertyMap
buildClassPropertyMap replay =
    let classMap = buildClassMap replay
        cacheByStreamId = buildCache replay
        cacheByCacheId =
            cacheByStreamId & IntMap.toList & map snd &
            map
                (\node ->
                      (cacheNodeCacheId node, node)) &
            IntMap.fromList
        f streamId _ m =
            case IntMap.lookup streamId cacheByStreamId of
                Nothing -> m
                Just node ->
                    IntMap.insert
                        streamId
                        (getPropertyMap cacheByCacheId (cacheNodeCacheId node))
                        m
    in IntMap.foldrWithKey f IntMap.empty classMap

getClass :: ObjectMap -> Int -> Maybe (Int, Text.Text)
getClass objectMap objectId =
    case IntMap.lookup objectId objectMap of
        Nothing -> Nothing
        Just name ->
            if name == Text.pack "TAGame.Default__PRI_TA" ||
               Text.isInfixOf (Text.pack "Archetype") name
                then getClass objectMap (objectId - 1)
                else Just (objectId, name)

data Context = Context
    { contextObjectMap :: ObjectMap
    , contextClassPropertyMap :: ClassPropertyMap
    , contextThings :: IntMap.IntMap Thing
    }

extractContext :: Type.Replay -> Context
extractContext replay =
    Context
    { contextObjectMap = buildObjectMap replay
    , contextClassPropertyMap = buildClassPropertyMap replay
    , contextThings = IntMap.empty
    }

type Time = Float

type Delta = Float

type ActorId = Int

data Vector = Vector
    { vectorX :: Int
    , vectorY :: Int
    , vectorZ :: Int
    } deriving (Show)

data ClassInit = ClassInit
    { classInitLocation :: Maybe Vector
    , classInitRotation :: Maybe Vector
    } deriving (Show)

classesWithLocation :: Set.Set Text.Text
classesWithLocation =
    [ "Engine.GameReplicationInfo"
    , "TAGame.Ball_TA"
    , "TAGame.CarComponent_Boost_TA"
    , "TAGame.CarComponent_Dodge_TA"
    , "TAGame.CarComponent_DoubleJump_TA"
    , "TAGame.CarComponent_FlipCar_TA"
    , "TAGame.CarComponent_Jump_TA"
    , "TAGame.Car_TA"
    , "TAGame.Default__CameraSettingsActor_TA"
    , "TAGame.Default__PRI_TA"
    , "TAGame.GRI_TA"
    , "TAGame.GameEvent_Season_TA"
    , "TAGame.GameEvent_SoccarPrivate_TA"
    , "TAGame.GameEvent_SoccarSplitscreen_TA"
    , "TAGame.GameEvent_Soccar_TA"
    , "TAGame.PRI_TA"
    , "TAGame.Team_Soccar_TA"
    , "TAGame.Team_TA"] &
    map Text.pack &
    Set.fromList

classesWithRotation :: Set.Set Text.Text
classesWithRotation =
    ["TAGame.Ball_TA", "TAGame.Car_Season_TA", "TAGame.Car_TA"] & map Text.pack &
    Set.fromList

maxVectorValue :: Int
maxVectorValue = 19

byteStringToFloat :: BS.ByteString -> Float
byteStringToFloat bytes = Binary.runGet
    IEEE754.getFloat32le
    (bytes & BSL.fromStrict & BSL.map Type.reverseBits)

getVector :: Bits.BitGet Vector
getVector = do
    numBits <- getInt maxVectorValue
    let bias = Bits.shiftL 1 (numBits + 1)
    let maxBits = numBits + 2
    let maxValue = 2 ^ maxBits
    dx <- getInt maxValue
    dy <- getInt maxValue
    dz <- getInt maxValue
    return
        Vector
        { vectorX = dx - bias
        , vectorY = dy - bias
        , vectorZ = dz - bias
        }

getVectorBytewise
    :: Bits.BitGet Vector
getVectorBytewise = do
    hasX <- Bits.getBool
    x <-
        if hasX
            then do
                word <- Bits.getWord8 8
                word & Type.reverseBits & fromIntegral & return
            else return 0
    hasY <- Bits.getBool
    y <-
        if hasY
            then do
                word <- Bits.getWord8 8
                word & Type.reverseBits & fromIntegral & return
            else return 0
    hasZ <- Bits.getBool
    z <-
        if hasZ
            then do
                word <- Bits.getWord8 8
                word & Type.reverseBits & fromIntegral & return
            else return 0
    return
        Vector
        { vectorX = x
        , vectorY = y
        , vectorZ = z
        }

getClassInit :: Text.Text -> Bits.BitGet ClassInit
getClassInit className = do
    location <-
        if Set.member className classesWithLocation
            then do
                vector <- getVector
                return (Just vector)
            else return Nothing
    rotation <-
        if Set.member className classesWithRotation
            then do
                vector <- getVectorBytewise
                return (Just vector)
            else return Nothing
    return
        ClassInit
        { classInitLocation = location
        , classInitRotation = rotation
        }

maxChannels
    :: (Integral a)
    => a
maxChannels = 1024

bitSize
    :: (Integral a)
    => a -> a
bitSize x = x & fromIntegral & logBase (2 :: Double) & ceiling

-- Reads an integer bitwise. The bits of the integer are backwards, so the
-- least significant bit is first. The argument is the maximum value this
-- integer can have. Bits will be read until the next bit would be greater than
-- the maximum value, or the number of bits necessary to reach the maximum
-- value has been reached, whichever comes first.
--
-- For example, if the maximum value is 4 and "11" has been read already,
-- nothing more will be read because another "1" would put the value over the
-- maximum.
getInt
    :: Int -> Bits.BitGet Int
getInt maxValue = do
    let maxBits = bitSize maxValue
        go i value = do
            let x = Bits.shiftL 1 i
            if i < maxBits && value + x <= maxValue
                then do
                    bit <- Bits.getBool
                    let newValue =
                            if bit
                                then value + x
                                else value
                    go (i + 1) newValue
                else return value
    go 0 0
