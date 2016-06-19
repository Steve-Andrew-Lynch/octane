{-# LANGUAGE OverloadedStrings #-}

module Octane.Utility.Optimizer (optimizeFrames) where

import Data.Function ((&))

import qualified Data.Foldable as Foldable
import qualified Data.IntMap.Strict as IntMap
import qualified Data.Map.Strict as Map
import qualified Data.Text as StrictText
import qualified Octane.Type.Frame as Frame
import qualified Octane.Type.Replication as Replication
import qualified Octane.Type.State as State
import qualified Octane.Type.Value as Value


optimizeFrames :: [Frame.Frame] -> [Frame.Frame]
optimizeFrames frames = frames
    & Foldable.foldl'
        (\ (state, fs) f -> let
            newState = updateState f state
            minimalFrame = getDelta state f
            in (newState, minimalFrame : fs))
        (initialState, [])
    & snd
    & reverse


-- { actor id => (alive?, { property name => property value } ) }
type State = IntMap.IntMap (Bool, Map.Map StrictText.Text Value.Value)


initialState :: State
initialState = IntMap.empty


updateState :: Frame.Frame -> State -> State
updateState frame state1 = let
    spawned = frame
        & Frame.replications
        & filter (\ replication -> replication
            & Replication.state
            & (== State.SOpening))
        & map Replication.actorId
        & map fromIntegral
    state2 = spawned
        & foldr
            (IntMap.alter (\ maybeValue -> Just (case maybeValue of
                Nothing -> (True, Map.empty)
                Just (_, properties) -> (True, properties))))
            state1

    destroyed = frame
        & Frame.replications
        & filter (\ replication -> replication
            & Replication.state
            & (== State.SClosing))
        & map Replication.actorId
        & map fromIntegral
    state3 = destroyed
        & foldr
            (IntMap.alter (\ maybeValue -> Just (case maybeValue of
                Nothing -> (False, Map.empty)
                Just (_, properties) -> (False, properties))))
            state2

    updated = frame
        & Frame.replications
        & filter (\ replication -> replication
            & Replication.state
            & (== State.SExisting))
    state4 = updated
        & foldr
            (\ replication -> IntMap.alter
                (\ maybeValue -> Just (case maybeValue of
                    Nothing ->
                        (True, Replication.properties replication)
                    Just (alive, properties) ->
                        ( alive
                        , Map.union
                            (Replication.properties replication)
                            properties
                        )))
                (replication & Replication.actorId & fromIntegral))
            state3

    in state4


getDelta :: State -> Frame.Frame -> Frame.Frame
getDelta state frame = let
    newReplications = frame
        & Frame.replications
        -- Remove replications that aren't actually new.
        & reject (\ replication -> let
            isOpening = Replication.state replication == State.SOpening
            actorId = Replication.actorId replication
            currentState = IntMap.lookup (fromIntegral actorId) state
            isAlive = fmap fst currentState
            wasAlreadyAlive = isAlive == Just True
            in isOpening && wasAlreadyAlive)
        -- Remove properties that haven't changed.
        & map (\ replication ->
            if Replication.state replication == State.SExisting
            then let
                actorId = Replication.actorId replication
                currentState = IntMap.findWithDefault
                    (True, Map.empty) (fromIntegral actorId) state
                currentProperties = snd currentState
                newProperties = Replication.properties replication
                changes = newProperties
                    & Map.filterWithKey (\ name newValue -> let
                        oldValue = Map.lookup name currentProperties
                        in Just newValue /= oldValue)
                in replication { Replication.properties = changes }
            else replication)
    in frame { Frame.replications = newReplications }


reject :: (a -> Bool) -> [a] -> [a]
reject p xs = filter (\ x -> not (p x)) xs