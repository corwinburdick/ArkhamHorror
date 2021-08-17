module Arkham.Types.Location.Cards.FrozenSpring
  ( frozenSpring
  , FrozenSpring(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (frozenSpring)
import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Message hiding (RevealLocation)
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Window

newtype FrozenSpring = FrozenSpring LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

frozenSpring :: LocationCard FrozenSpring
frozenSpring = locationWith
  FrozenSpring
  Cards.frozenSpring
  3
  (PerPlayer 1)
  NoSymbol
  []
  ((revealedSymbolL .~ Plus)
  . (revealedConnectedSymbolsL .~ setFromList [Triangle, Hourglass])
  )

forcedAbility :: LocationAttrs -> Ability
forcedAbility a = mkAbility (toSource a) 1 LegacyForcedAbility

instance ActionRunner env => HasAbilities env FrozenSpring where
  getAbilities iid (Window Timing.After (RevealLocation who _)) (FrozenSpring attrs)
    | iid == who
    = pure [locationAbility (forcedAbility attrs)]
  getAbilities iid window (FrozenSpring attrs) = getAbilities iid window attrs

instance LocationRunner env => RunMessage env FrozenSpring where
  runMessage msg l@(FrozenSpring attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      l <$ pushAll [SetActions iid (toSource attrs) 0, ChooseEndTurn iid]
    _ -> FrozenSpring <$> runMessage msg attrs
