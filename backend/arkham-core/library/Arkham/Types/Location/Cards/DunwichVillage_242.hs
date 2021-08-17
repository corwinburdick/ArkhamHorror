module Arkham.Types.Location.Cards.DunwichVillage_242
  ( dunwichVillage_242
  , DunwichVillage_242(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (dunwichVillage_242)
import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Exception
import Arkham.Types.Game.Helpers
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Trait
import Arkham.Types.Window

newtype DunwichVillage_242 = DunwichVillage_242 LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

dunwichVillage_242 :: LocationCard DunwichVillage_242
dunwichVillage_242 = location
  DunwichVillage_242
  Cards.dunwichVillage_242
  3
  (Static 1)
  Circle
  [Triangle, Square, Diamond]

ability :: LocationAttrs -> Ability
ability attrs =
  mkAbility (toSource attrs) 1 (FastAbility Free)
    & (abilityLimitL .~ GroupLimit PerGame 1)

instance ActionRunner env => HasAbilities env DunwichVillage_242 where
  getAbilities iid window@(Window Timing.When NonFast) (DunwichVillage_242 attrs)
    = withResignAction iid window attrs
  getAbilities iid window@(Window Timing.When FastPlayerWindow) (DunwichVillage_242 attrs)
    = withBaseActions iid window attrs $ do
      investigatorsWithClues <- notNull <$> locationInvestigatorsWithClues attrs
      anyAbominations <- notNull <$> locationEnemiesWithTrait attrs Abomination
      pure
        [ locationAbility (ability attrs)
        | investigatorsWithClues && anyAbominations
        ]
  getAbilities iid window (DunwichVillage_242 attrs) =
    getAbilities iid window attrs

instance LocationRunner env => RunMessage env DunwichVillage_242 where
  runMessage msg l@(DunwichVillage_242 attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      investigatorsWithClues <- locationInvestigatorsWithClues attrs
      abominations <- locationEnemiesWithTrait attrs Abomination
      when
        (null investigatorsWithClues || null abominations)
        (throwIO $ InvalidState "should not have been able to use this ability")
      l <$ pushAll
        [ chooseOne
            iid
            [ Label
              "Place clue on Abomination"
              [ chooseOne
                  iid
                  [ TargetLabel
                      (EnemyTarget eid)
                      [ PlaceClues (EnemyTarget eid) 1
                      , InvestigatorSpendClues iid 1
                      ]
                  | eid <- abominations
                  ]
              ]
            , Label "Do not place clue on Abomination" []
            ]
        | iid <- investigatorsWithClues
        ]
    _ -> DunwichVillage_242 <$> runMessage msg attrs
