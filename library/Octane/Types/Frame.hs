module Octane.Types.Frame where

import Octane.Types.Float32LE (Float32LE)
import Octane.Utilities (flipEndianness)

import Data.Bits (setBit, zeroBits)

import qualified Data.Binary as B
import qualified Data.Binary.Bits as BB
import qualified Data.Binary.Bits.Get as BB
import qualified Data.ByteString.Lazy as BSL

data Frame = NewFrame
    { frameTime :: Float32LE
    , frameDelta :: Float32LE
    , frameHasActors :: Bool
    , frameActorID :: Maybe B.Word16
    , frameChannelOpen :: Maybe Bool
    , frameActorIsNew :: Maybe Bool
    } deriving (Show)

instance BB.BinaryBit Frame where
    getBits _ = do
        timeBytes <- BB.getByteString 4
        deltaBytes <- BB.getByteString 4
        hasActors <- BB.getBool
        let frame = NewFrame
                { frameTime = B.decode (BSL.fromStrict (flipEndianness timeBytes))
                , frameDelta = B.decode (BSL.fromStrict (flipEndianness deltaBytes))
                , frameHasActors = hasActors
                , frameActorID = Nothing
                , frameChannelOpen = Nothing
                , frameActorIsNew = Nothing
                }

        if not hasActors
        then do -- this is the end of the frame
            return frame
        else do -- there is more to the frame
            actorID <- getInt10LE
            channelOpen <- BB.getBool
            if not channelOpen
            then do -- the channel is closed and the actor is destroyed
                -- TODO: is there anything more to do here?
                return frame
                    { frameHasActors = hasActors
                    , frameActorID = Just actorID
                    , frameChannelOpen = Just channelOpen
                    }
            else do -- the channel is open
                actorIsNew <- BB.getBool
                if not actorIsNew
                then do -- the actor already exists
                    -- TODO: while readbit is true, read property
                    return frame
                        { frameActorID = Just actorID
                        , frameChannelOpen = Just channelOpen
                        , frameActorIsNew = Just actorIsNew
                        }
                else do -- the actor does not already exist
                    -- TODO: Next bit is always 0. It may be a static versus
                    --   dynamic flag
                    -- TODO: next 8? bits are actor type id?
                    -- TODO: optional initial location vector?
                    -- TODO: 3 bytes for pitch, yaw, and roll?
                    return frame
                        { frameActorID = Just actorID
                        , frameChannelOpen = Just channelOpen
                        , frameActorIsNew = Just actorIsNew
                        }

    putBits _ _ = undefined

-- TODO: This is awful. But it's the easiest way to get a 10-bit little-endian
--   integer from a frame.
getInt10LE :: BB.BitGet B.Word16
getInt10LE = do
    a <- BB.getBool
    b <- BB.getBool
    c <- BB.getBool
    d <- BB.getBool
    e <- BB.getBool
    f <- BB.getBool
    g <- BB.getBool
    h <- BB.getBool
    i <- BB.getBool
    j <- BB.getBool
    return $
        (if a then flip setBit 0 else id) $
        (if b then flip setBit 1 else id) $
        (if c then flip setBit 2 else id) $
        (if d then flip setBit 3 else id) $
        (if e then flip setBit 4 else id) $
        (if f then flip setBit 5 else id) $
        (if g then flip setBit 6 else id) $
        (if h then flip setBit 7 else id) $
        (if i then flip setBit 8 else id) $
        (if j then flip setBit 9 else id) $
        zeroBits