{-# LANGUAGE DeriveGeneric #-}

module Octane.Parser where

import Data.Function ((&))

import qualified Control.DeepSeq as DeepSeq
import qualified Control.Newtype as Newtype
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.Types as Aeson
import qualified Data.Binary.Bits.Get as Bits
import qualified Data.Binary.IEEE754 as IEEE754
import qualified Data.Binary.Get as Binary
import qualified Data.Bits as Bits
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BSL
import qualified Data.Int as Int
import qualified Data.IntMap.Strict as IntMap
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.Text.Encoding as Encoding
import qualified Data.Word as Word
import qualified GHC.Generics as Generics
import qualified Octane.Data as Data
import qualified Octane.Parser.ClassPropertyMap as CPM
import qualified Octane.Type as Type
import qualified Text.Printf as Printf

parseFrames :: Type.Replay -> [Frame]
parseFrames replay = let
    numFrames = replay
        & Type.replayProperties
        & Newtype.unpack
        & Map.lookup ("NumFrames" & Text.pack & Newtype.pack)
        & (\ property -> case property of
            Just (Type.IntProperty _ x) -> x & Newtype.unpack & fromIntegral
            _ -> 0)
    get = replay & extractContext & getFrames numFrames & Bits.runBitGet
    stream = replay & Type.replayStream & Newtype.unpack & BSL.fromStrict
    (_context, frames) = Binary.runGet get stream
    in frames

getFrames :: Int -> Context -> Bits.BitGet (Context, [Frame])
getFrames numFrames context = do
    if numFrames < 1
    then return (context, [])
    else do
        isEmpty <- Bits.isEmpty
        if isEmpty
        then return (context, [])
        else do
            maybeFrame <- getMaybeFrame context
            case maybeFrame of
                Nothing -> return (context, [])
                Just (newContext, frame) -> do
                    (newerContext, frames) <- getFrames (numFrames - 1) newContext
                    return (newerContext, (frame : frames))

getMaybeFrame :: Context -> Bits.BitGet (Maybe (Context, Frame))
getMaybeFrame context = do
    time <- getFloat32
    delta <- getFloat32
    if time == 0 && delta == 0
    then return Nothing
    else if time < 0.001 || delta < 0.001
    then error ("parsing previous frame probably failed. time: " ++ show time ++ ", delta: " ++ show delta)
    else do
        (newContext, frame) <- getFrame context time delta
        return (Just (newContext, frame))

getFrame :: Context -> Time -> Delta -> Bits.BitGet (Context, Frame)
getFrame context time delta = do
    (newContext, replications) <- getReplications context
    let frame =
            Frame
            { frameTime = time
            , frameDelta = delta
            , frameReplications = replications
            }
    return (newContext, frame)

getReplications :: Context -> Bits.BitGet (Context, [Replication])
getReplications context = do
    maybeReplication <- getMaybeReplication context
    case maybeReplication of
        Nothing -> return (context, [])
        Just (newContext, replication) -> do
            (newerContext, replications) <- getReplications newContext
            return (newerContext, replication : replications)

getMaybeReplication :: Context -> Bits.BitGet (Maybe (Context, Replication))
getMaybeReplication context = do
    hasReplication <- Bits.getBool
    if not hasReplication
        then return Nothing
        else do
            (newContext,replication) <- getReplication context
            return (Just (newContext, replication))

getReplication :: Context -> Bits.BitGet (Context, Replication)
getReplication context = do
    actorId <- getActorId
    isOpen <- Bits.getBool
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
    if unknownFlag
        then error "the unknown flag in a new replication is true! what does it mean?"
        else return ()
    objectId <- getInt32
    let objectName = case context & contextObjectMap & IntMap.lookup objectId of
            Nothing -> error ("could not find object name for id " ++ show objectId)
            Just x -> x
    let (classId,className) = case CPM.getClass (contextObjectMap context) Data.objectToClass (contextClassMap context) objectId of
            Nothing -> error ("could not find class for object id " ++ show objectId)
            Just x -> x
    classInit <- getClassInit className
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
          { replicationObjectName = objectName
          , replicationClassName = className
          , replicationState = RSOpening
          , replicationInitialization = Just classInit
          , replicationProperties = Map.empty
          })

getExistingReplication :: Context
                       -> ActorId
                       -> Bits.BitGet (Context, Replication)
getExistingReplication context actorId = do
    let thing = case context & contextThings & IntMap.lookup actorId of
            Nothing -> error ("could not find thing for actor id " ++ show actorId)
            Just x -> x
    props <- getProps context thing
    return (context, Replication
        { replicationObjectName = thingObjectName thing
        , replicationClassName = thingClassName thing
        , replicationState = RSExisting
        , replicationInitialization = Nothing
        , replicationProperties = props
        })

getClosedReplication :: Context
                     -> ActorId
                     -> Bits.BitGet (Context, Replication)
getClosedReplication context actorId = do
    let thing = case context & contextThings & IntMap.lookup actorId of
            Nothing -> error ("could not find thing for actor id " ++ show actorId)
            Just x -> x
    let newThings = context & contextThings & IntMap.delete actorId
    let newContext = context { contextThings = newThings }
    return
        ( newContext
        , Replication
          { replicationObjectName = thingObjectName thing
          , replicationClassName = thingClassName thing
          , replicationState = RSClosing
          , replicationInitialization = Nothing
          , replicationProperties = Map.empty
          })

getProps :: Context -> Thing -> Bits.BitGet (Map.Map Text.Text PropValue)
getProps context thing = do
    maybeProp <- getMaybeProp context thing
    case maybeProp of
        Nothing -> return Map.empty
        Just prop -> do
            let k = propName prop
            let v = propValue prop
            let m = Map.singleton k v
            props <- getProps context thing
            return (Map.union m props)

getMaybeProp :: Context -> Thing -> Bits.BitGet (Maybe Prop)
getMaybeProp context thing = do
    hasProp <- Bits.getBool
    if hasProp
    then do
        prop <- getProp context thing
        return (Just prop)
    else return Nothing

getProp :: Context -> Thing -> Bits.BitGet Prop
getProp context thing = do
    let classId = thing & thingClassId
    let props = case context & contextClassPropertyMap & IntMap.lookup classId of
            Nothing -> error ("could not find property map for class id " ++ show classId)
            Just x -> x
    let maxId = props & IntMap.keys & (0 :) & maximum
    pid <- getInt maxId
    let name = case props & IntMap.lookup pid of
            Nothing -> error ("could not find property name for property id " ++ show pid)
            Just x -> x
    value <- getPropValue name
    return (Prop { propName = name, propValue = value })

getPropValue :: Text.Text -> Bits.BitGet PropValue
getPropValue name = case Text.unpack name of
    "TAGame.PRI_TA:PartyLeader" -> do
        -- Even though this is just a unique ID property, it must be handled
        -- specially because it sometimes doesn't have the remote or local
        -- IDs.
        systemId <- getSystemId
        if systemId == 0
            then do
                let remoteId = SplitscreenId Nothing
                let localId = Nothing
                return (PUniqueId systemId remoteId localId)
            else do
                remoteId <- getRemoteId systemId
                localId <- getLocalId
                return (PUniqueId systemId remoteId localId)
    _ | Set.member name Data.rigidBodyStateProperties -> do
        flag <- Bits.getBool
        position <- getVector
        rotation <- getFloatVector
        x <- if flag then return Nothing else fmap Just getVector
        y <- if flag then return Nothing else fmap Just getVector
        return (PRigidBodyState flag position rotation x y)
    _ | Set.member name Data.flaggedIntProperties -> do
        flag <- Bits.getBool
        int <- getInt32
        return (PFlaggedInt flag (fromIntegral int))
    _ | Set.member name Data.stringProperties -> do
        string <- getString
        return (PString string)
    _ | Set.member name Data.booleanProperties -> do
        bool <- Bits.getBool
        return (PBoolean bool)
    _ | Set.member name Data.qWordProperties -> do
        x <- getInt32
        y <- getInt32
        return (PQWord x y)
    _ | Set.member name Data.intProperties -> do
        int <- getInt32
        return (PInt int)
    _ | Set.member name Data.byteProperties -> do
        int <- getInt8
        return (PByte int)
    _ | Set.member name Data.camSettingsProperties -> do
        fov <- getFloat32
        height <- getFloat32
        pitch <- getFloat32
        dist <- getFloat32
        stiff <- getFloat32
        swiv <- getFloat32
        return (PCamSettings fov height pitch dist stiff swiv)
    _ | Set.member name Data.locationProperties -> do
        vector <- getVector
        return (PLocation vector)
    _ | Set.member name Data.floatProperties -> do
        float <- getFloat32
        return (PFloat float)
    _ | Set.member name Data.uniqueIdProperties -> do
        (systemId, remoteId, localId) <- getUniqueId
        return (PUniqueId systemId remoteId localId)
    _ | Set.member name Data.reservationProperties -> do
        -- I think this is the connection order. The first player to connect
        -- gets number 0, and it goes up from there. The maximum is 7, which
        -- would be a full 4x4 game.
        number <- getInt7
        (systemId, remoteId, localId) <- getUniqueId
        playerName <- if systemId == 0 then return Nothing else do
            string <- getString
            return (Just string)
        -- No idea what these two flags are. Might be for bots?
        a <- Bits.getBool
        b <- Bits.getBool
        return (PReservation number systemId remoteId localId playerName a b)
    _ | Set.member name Data.loadoutOnlineProperties -> do
        version <- getInt32
        x <- getInt32
        y <- getInt32
        z <- if version >= 12
            then do
                value <- getInt8
                return (Just value)
            else return Nothing
        return (PLoadoutOnline version x y z)
    _ | Set.member name Data.loadoutProperties -> do
        version <- getInt8
        a <- getInt32
        b <- getInt32
        c <- getInt32
        d <- getInt32
        e <- getInt32
        f <- getInt32
        g <- getInt32
        h <- if version > 10
            then do
                value <- getInt32
                return (Just value)
            else return Nothing
        return (PLoadout version a b c d e f g h)
    _ | Set.member name Data.teamPaintProperties -> do
        team <- getInt8
        teamColor <- getInt8
        customColor <- getInt8
        teamFinish <- getInt32
        customFinish <- getInt32
        return (PTeamPaint team teamColor customColor teamFinish customFinish)
    _ | Set.member name Data.pickupProperties -> do
        instigator <- Bits.getBool
        instigatorId <- if instigator then fmap Just getInt32 else return Nothing
        pickedUp <- Bits.getBool
        return (PPickup instigator instigatorId pickedUp)
    _ | Set.member name Data.enumProperties -> do
        x <- Bits.getWord16be 10
        y <- if x == 1023
            then Bits.getBool
            else error ("unexpected enum value " ++ show x)
        return (PEnum x y)
    _ | Set.member name Data.explosionProperties -> do
        noGoal <- Bits.getBool
        a <- if noGoal then return Nothing else fmap Just getInt32
        b <- getVector
        return (PExplosion noGoal a b)
    _ | Set.member name Data.musicStingerProperties -> do
        flag <- Bits.getBool
        cue <- getInt32
        trigger <- getInt8
        return (PMusicStinger flag cue trigger)
    _ | Set.member name Data.demolishProperties -> do
        atkFlag <- Bits.getBool
        atk <- getInt32
        vicFlag <- Bits.getBool
        vic <- getInt32
        vec1 <- getVector
        vec2 <- getVector
        return (PDemolish atkFlag atk vicFlag vic vec1 vec2)
    _ | Set.member name Data.privateMatchSettingsProperties -> do
        mutators <- getString
        joinableBy <- getInt32
        maxPlayers <- getInt32
        gameName <- getString
        password <- getString
        flag <- Bits.getBool
        return (PPrivateMatchSettings mutators joinableBy maxPlayers gameName password flag)
    _ | Set.member name Data.relativeRotationProperties -> do
        vector <- getFloatVector
        return (PRelativeRotation vector)
    _ | Set.member name Data.gameModeProperties -> do
        x <- Bits.getWord8 2
        if x == 2
            then return (PGameMode x)
            else error ("unexpected game mode value " ++ show x)
    _ -> fail ("don't know how to read property " ++ show name)

getFloat32 :: Bits.BitGet Float
getFloat32 = do
    bytes <- Bits.getByteString 4
    bytes & byteStringToFloat & return

getString :: Bits.BitGet Text.Text
getString = do
    rawSize <- getInt32
    rawText <- if rawSize < 0
        then do
            let size = -2 * rawSize
            bytes <- Bits.getByteString size
            bytes & BS.map Type.reverseBits & Encoding.decodeUtf16LE & return
        else do
            bytes <- Bits.getByteString rawSize
            bytes & BS.map Type.reverseBits & Encoding.decodeLatin1 & return
    rawText & Text.dropEnd 1 & return

getUniqueId :: Bits.BitGet (SystemId, RemoteId, LocalId)
getUniqueId = do
    systemId <- getSystemId
    remoteId <- getRemoteId systemId
    localId <- getLocalId
    return (systemId, remoteId, localId)

getSystemId :: Bits.BitGet SystemId
getSystemId = do
    byte <- Bits.getWord8 8
    byte & Type.reverseBits & return

getRemoteId :: SystemId -> Bits.BitGet RemoteId
getRemoteId systemId = case systemId of
    0 -> do
        remoteId <- Bits.getByteString 3
        if BS.all (\ byte -> byte == 0) remoteId
            then 0 & Just & SplitscreenId & return
            else error ("unexpected splitscreen id " ++ show remoteId)
    1 -> do
        bytes <- Bits.getByteString 8
        let remoteId = Binary.runGet
                Binary.getWord64le
                (bytes & BS.map Type.reverseBits & BSL.fromStrict)
        remoteId & SteamId & return
    2 -> do
        bytes <- Bits.getByteString 32
        let remoteId = bytes
                & BS.map Type.reverseBits
                & BS.unpack
                & concatMap (\ b -> Printf.printf "%02x" b)
                & Text.pack
        remoteId & PlayStationId & return
    4 -> do
        bytes <- Bits.getByteString 8
        let remoteId = Binary.runGet
                Binary.getWord64le
                (bytes & BS.map Type.reverseBits & BSL.fromStrict)
        remoteId & XboxId & return
    _ -> error ("unknown system id " ++ show systemId)

getLocalId :: Bits.BitGet LocalId
getLocalId = do
    localId <- Bits.getWord8 8
    localId & Just & return

toJsonOptions :: String -> Aeson.Options
toJsonOptions name = Aeson.defaultOptions
    { Aeson.fieldLabelModifier = Aeson.camelTo2 '_' . drop (length name)
    }

type SystemId = Word.Word8

-- This is the number associated with a splitscreen player. So the first player
-- is 0, the second is 1, and so on.
-- - 0 "Someone"
-- - 1 "Someone (1)"
type LocalId = Maybe Word.Word8

data RemoteId
    = SteamId !Word.Word64
    | PlayStationId !Text.Text
    | SplitscreenId !(Maybe Int)
    | XboxId !Word.Word64
    deriving (Eq, Generics.Generic, Show)

instance DeepSeq.NFData RemoteId
instance Aeson.ToJSON RemoteId

data Prop = Prop
    { propName :: !Text.Text
    , propValue :: !PropValue
    } deriving (Eq, Generics.Generic, Show)

instance DeepSeq.NFData Prop
instance Aeson.ToJSON Prop where
    toJSON = Aeson.genericToJSON (toJsonOptions "Prop")

data PropValue
    = PBoolean !Bool
    | PByte !Int
    | PCamSettings !Float !Float !Float !Float !Float !Float
    | PDemolish !Bool !Int !Bool !Int !(Vector Int) !(Vector Int)
    | PEnum !Word.Word16 !Bool
    | PExplosion !Bool !(Maybe Int) !(Vector Int)
    | PFlaggedInt !Bool !Int
    | PFloat !Float
    | PGameMode !Word.Word8
    | PInt !Int
    | PLoadout !Int !Int !Int !Int !Int !Int !Int !Int !(Maybe Int)
    | PLoadoutOnline !Int !Int !Int !(Maybe Int)
    | PLocation !(Vector Int)
    | PMusicStinger !Bool !Int !Int
    | PPickup !Bool !(Maybe Int) !Bool
    | PPrivateMatchSettings !Text.Text !Int !Int !Text.Text !Text.Text !Bool
    | PQWord !Int !Int
    | PRelativeRotation !(Vector Float)
    | PReservation !Int !SystemId !RemoteId !LocalId !(Maybe Text.Text) !Bool !Bool
    | PRigidBodyState !Bool !(Vector Int) !(Vector Float) !(Maybe (Vector Int)) !(Maybe (Vector Int))
    | PString !Text.Text
    | PTeamPaint !Int !Int !Int !Int !Int
    | PUniqueId !SystemId !RemoteId !LocalId
    deriving (Eq, Generics.Generic, Show)

instance DeepSeq.NFData PropValue
instance Aeson.ToJSON PropValue where
    toJSON = Aeson.genericToJSON (toJsonOptions "PropValue")

-- | A frame in the net stream. Each frame has the time since the beginning of
-- the match, the time since the last frame, and a list of replications.
data Frame = Frame
    { frameTime :: !Float
    , frameDelta :: !Float
    , frameReplications :: ![Replication]
    } deriving (Eq,Generics.Generic,Show)

instance DeepSeq.NFData Frame
instance Aeson.ToJSON Frame where
    toJSON = Aeson.genericToJSON (toJsonOptions "Frame")

data ReplicationState
    = RSOpening
    | RSExisting
    | RSClosing
    deriving (Eq, Generics.Generic, Show)

instance DeepSeq.NFData ReplicationState
instance Aeson.ToJSON ReplicationState where
    toJSON rs = Aeson.toJSON (case rs of
        RSOpening -> "opening"
        RSExisting -> "existing"
        RSClosing -> "closing")

-- | Replication information about an actor in the net stream.
data Replication = Replication
    { replicationObjectName :: !Text.Text
    , replicationClassName :: !Text.Text
    , replicationState :: !ReplicationState
    , replicationInitialization :: !(Maybe ClassInit)
    , replicationProperties :: !(Map.Map Text.Text PropValue)
    } deriving (Eq,Generics.Generic,Show)

instance DeepSeq.NFData Replication
instance Aeson.ToJSON Replication where
    toJSON = Aeson.genericToJSON (toJsonOptions "Replication")

data Thing = Thing
    { thingFlag :: !Bool
    , thingObjectId :: !Int
    , thingObjectName :: !Text.Text
    , thingClassId :: !Int
    , thingClassName :: !Text.Text
    , thingClassInit :: !ClassInit
    } deriving (Show)

type Time = Float

type Delta = Float

type ActorId = Int

data Vector a = Vector
    { vectorX :: !a
    , vectorY :: !a
    , vectorZ :: !a
    } deriving (Eq, Generics.Generic, Show)

instance (DeepSeq.NFData a) => DeepSeq.NFData (Vector a)
instance (Aeson.ToJSON a) => Aeson.ToJSON (Vector a) where
    toJSON vector = Aeson.toJSON
        [ vectorX vector
        , vectorY vector
        , vectorZ vector
        ]

data ClassInit = ClassInit
    { classInitLocation :: !(Maybe (Vector Int))
    , classInitRotation :: !(Maybe (Vector Int))
    } deriving (Eq, Generics.Generic, Show)

instance DeepSeq.NFData ClassInit
instance Aeson.ToJSON ClassInit where
    toJSON = Aeson.genericToJSON (toJsonOptions "ClassInit")

-- { class stream id => { property stream id => name } }
type ClassPropertyMap = IntMap.IntMap (IntMap.IntMap Text.Text)

-- { stream id => object name }
type ObjectMap = IntMap.IntMap Text.Text

-- { class name => class id }
type ClassMap = Map.Map Text.Text Int

data Context = Context
    { contextObjectMap :: !ObjectMap
    , contextClassPropertyMap :: !ClassPropertyMap
    , contextThings :: !(IntMap.IntMap Thing)
    , contextClassMap :: !ClassMap
    } deriving (Show)

extractContext :: Type.Replay -> Context
extractContext replay =
    Context
    { contextObjectMap = CPM.getPropertyMap replay
    , contextClassPropertyMap = CPM.getClassPropertyMap replay
    , contextThings = IntMap.empty
    , contextClassMap = CPM.getActorMap replay
    }

byteStringToFloat :: BS.ByteString -> Float
byteStringToFloat bytes = Binary.runGet
    IEEE754.getFloat32le
    (bytes & BSL.fromStrict & BSL.map Type.reverseBits)

getVector :: Bits.BitGet (Vector Int)
getVector = do
    numBits <- getNumVectorBits
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
    :: Bits.BitGet (Vector Int)
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

getFloatVector :: Bits.BitGet (Vector Float)
getFloatVector = do
    let maxValue = 1
    let numBits = 16
    x <- getFloat maxValue numBits
    y <- getFloat maxValue numBits
    z <- getFloat maxValue numBits
    return Vector { vectorX = x, vectorY = y, vectorZ = z }

getFloat :: Int -> Int -> Bits.BitGet Float
getFloat maxValue numBits = do
    let maxBitValue = (Bits.shiftL 1 (numBits - 1)) - 1
    let bias = Bits.shiftL 1 (numBits - 1)
    let serIntMax = Bits.shiftL 1 numBits
    delta <- getInt serIntMax
    let unscaledValue = delta - bias
    if maxValue > maxBitValue
    then do
        let invScale = fromIntegral maxValue / fromIntegral maxBitValue
        return (fromIntegral unscaledValue * invScale)
    else do
        let scale = fromIntegral maxBitValue / fromIntegral maxValue
        let invScale = 1.0 / scale
        return (fromIntegral unscaledValue * invScale)

getClassInit :: Text.Text -> Bits.BitGet ClassInit
getClassInit className = do
    location <-
        if Set.member className Data.locationClasses
            then do
                vector <- getVector
                return (Just vector)
            else return Nothing
    rotation <-
        if Set.member className Data.rotationClasses
            then do
                vector <- getVectorBytewise
                return (Just vector)
            else return Nothing
    return
        ClassInit
        { classInitLocation = location
        , classInitRotation = rotation
        }

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

getInt32 :: Bits.BitGet Int
getInt32 = do
    bytes <- Bits.getByteString 4
    let word = Binary.runGet
            Binary.getWord32le
            (bytes & BSL.fromStrict & BSL.map Type.reverseBits)
    word & fromIntegral & (\ x -> x :: Int.Int32) & fromIntegral & return

getInt8 :: Bits.BitGet Int
getInt8 = do
    byte <- Bits.getByteString 1
    let word = Binary.runGet
            Binary.getWord8
            (byte & BSL.fromStrict & BSL.map Type.reverseBits)
    word & fromIntegral & (\ x -> x :: Int.Int8) & fromIntegral & return

getActorId :: Bits.BitGet Int
getActorId = getInt 1024

getNumVectorBits :: Bits.BitGet Int
getNumVectorBits = getInt 19

getInt7 :: Bits.BitGet Int
getInt7 = getInt 7
