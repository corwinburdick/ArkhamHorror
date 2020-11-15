{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Enemy.Cards.CorpseTaker (CorpseTaker(..), corpseTaker) where

import Arkham.Import

import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner
import Arkham.Types.Game.Helpers

newtype CorpseTaker = CorpseTaker Attrs
  deriving newtype (Show, ToJSON, FromJSON)

corpseTaker :: EnemyId -> CorpseTaker
corpseTaker uuid =
  CorpseTaker
    $ baseAttrs uuid "50042"
    $ (healthDamage .~ 1)
    . (sanityDamage .~ 2)
    . (fight .~ 4)
    . (health .~ Static 3)
    . (evade .~ 3)

instance HasModifiersFor env CorpseTaker where
  getModifiersFor = noModifiersFor

instance HasModifiers env CorpseTaker where
  getModifiers _ (CorpseTaker Attrs {..}) =
    pure . concat . toList $ enemyModifiers

instance ActionRunner env => HasActions env CorpseTaker where
  getActions i window (CorpseTaker attrs) = getActions i window attrs

instance EnemyRunner env => RunMessage env CorpseTaker where
  runMessage msg e@(CorpseTaker attrs@Attrs {..}) = case msg of
    InvestigatorDrawEnemy iid _ eid | eid == enemyId -> do
      farthestEmptyLocationIds <-
        asks $ map unFarthestLocationId . setToList . getSet
          (iid, EmptyLocation)
      e <$ spawnAtOneOf iid eid farthestEmptyLocationIds
    EndMythos -> pure $ CorpseTaker $ attrs & doom +~ 1
    EndEnemy -> do
      mrivertown <- asks $ getId (LocationName "Rivertown")
      mmainPath <- asks $ getId (LocationName "Main Path")
      let
        locationId =
          fromJustNote "one of these has to exist" (mrivertown <|> mmainPath)
      if enemyLocation == locationId
        then do
          unshiftMessages (replicate enemyDoom PlaceDoomOnAgenda)
          pure $ CorpseTaker $ attrs & doom .~ 0
        else do
          leadInvestigatorId <- getLeadInvestigatorId
          closestLocationIds <-
            asks $ map unClosestLocationId . setToList . getSet
              (enemyLocation, locationId)
          case closestLocationIds of
            [lid] -> e <$ unshiftMessage (EnemyMove enemyId enemyLocation lid)
            lids -> e <$ unshiftMessage
              (chooseOne
                leadInvestigatorId
                [ EnemyMove enemyId enemyLocation lid | lid <- lids ]
              )
    _ -> CorpseTaker <$> runMessage msg attrs
