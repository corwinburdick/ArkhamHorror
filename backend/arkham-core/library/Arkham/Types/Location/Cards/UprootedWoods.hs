module Arkham.Types.Location.Cards.UprootedWoods
  ( uprootedWoods
  , UprootedWoods(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (uprootedWoods)
import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Message hiding (RevealLocation)
import Arkham.Types.Query
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Window

newtype UprootedWoods = UprootedWoods LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

uprootedWoods :: LocationCard UprootedWoods
uprootedWoods = locationWith
  UprootedWoods
  Cards.uprootedWoods
  2
  (PerPlayer 1)
  NoSymbol
  []
  ((revealedSymbolL .~ Moon)
  . (revealedConnectedSymbolsL .~ setFromList [Square, T])
  )

forcedAbility :: LocationAttrs -> Ability
forcedAbility a = mkAbility (toSource a) 1 LegacyForcedAbility

instance ActionRunner env => HasAbilities env UprootedWoods where
  getAbilities iid (Window Timing.After (RevealLocation who _)) (UprootedWoods attrs)
    | iid == who
    = do
      actionRemainingCount <- unActionRemainingCount <$> getCount iid
      pure [ locationAbility (forcedAbility attrs) | actionRemainingCount == 0 ]
  getAbilities iid window (UprootedWoods attrs) = getAbilities iid window attrs

instance LocationRunner env => RunMessage env UprootedWoods where
  runMessage msg l@(UprootedWoods attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      l <$ push (DiscardTopOfDeck iid 5 Nothing)
    _ -> UprootedWoods <$> runMessage msg attrs
