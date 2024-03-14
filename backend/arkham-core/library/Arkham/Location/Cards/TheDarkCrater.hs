module Arkham.Location.Cards.TheDarkCrater (theDarkCrater, TheDarkCrater (..)) where

import Arkham.GameValue
import Arkham.Id
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner hiding (beginSkillTest)
import Arkham.Matcher
import Arkham.Message qualified as Msg
import Arkham.Message.Lifted
import Arkham.Prelude
import Arkham.Scenarios.DarkSideOfTheMoon.Helpers

data Meta = Meta
  { discoveredCluesThisTurn :: [InvestigatorId]
  , hasUsedSuccess :: [InvestigatorId]
  }
  deriving stock (Generic)
  deriving anyclass (FromJSON, ToJSON)

newtype TheDarkCrater = TheDarkCrater LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theDarkCrater :: LocationCard TheDarkCrater
theDarkCrater =
  locationWith
    TheDarkCrater
    Cards.theDarkCrater
    2
    (PerPlayer 1)
    (metaL .~ toJSON (Meta [] []))

instance HasAbilities TheDarkCrater where
  getAbilities (TheDarkCrater attrs) =
    let meta = toResult @Meta attrs.meta
     in extendRevealed
          attrs
          [ restrictedAbility attrs 1 Here actionAbility
          , restrictedAbility
              attrs
              2
              (Here <> youExist (oneOf $ map InvestigatorWithId (discoveredCluesThisTurn meta)))
              $ forced
              $ TurnEnds #when You
          ]

instance RunMessage TheDarkCrater where
  runMessage msg l@(TheDarkCrater attrs) = runQueueT $ case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      beginSkillTest iid (attrs.ability 1) iid #intellect 5
      pure l
    PassedThisSkillTest iid (isAbilitySource attrs 1 -> True) -> do
      let meta = toResult @Meta attrs.meta
      if iid `elem` hasUsedSuccess meta
        then pure l
        else do
          reduceAlarmLevel (attrs.ability 1) iid
          pure $ TheDarkCrater $ attrs & metaL .~ toJSON (meta {hasUsedSuccess = iid : hasUsedSuccess meta})
    UseThisAbility iid (isSource attrs -> True) 2 -> do
      beginSkillTest iid (attrs.ability 2) iid #willpower 3
      pure l
    FailedThisSkillTest iid (isAbilitySource attrs 2 -> True) -> do
      raiseAlarmLevel (attrs.ability 2) iid
      pure l
    Do (Msg.DiscoverClues iid lid _ _ _ _) | lid == attrs.id -> do
      attrs' <- lift (runMessage msg attrs)
      let meta' = toResult @Meta attrs.meta
      pure
        $ TheDarkCrater
        $ attrs'
        & metaL
        .~ toJSON (meta' {discoveredCluesThisTurn = iid : discoveredCluesThisTurn meta'})
    After (EndTurn _) -> do
      let meta' = toResult @Meta attrs.meta
      pure $ TheDarkCrater $ attrs & metaL .~ toJSON (meta' {discoveredCluesThisTurn = []})
    _ -> TheDarkCrater <$> lift (runMessage msg attrs)
