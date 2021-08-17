module Arkham.Types.Location.Cards.Gondola
  ( gondola
  , Gondola(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.GameValue
import Arkham.Types.Id
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.SkillType
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Window

newtype Gondola = Gondola LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

gondola :: LocationCard Gondola
gondola = location Gondola Cards.gondola 5 (Static 0) NoSymbol []

ability :: LocationAttrs -> Ability
ability a = mkAbility a 1 (ActionAbility Nothing $ ActionCost 1)

instance ActionRunner env => HasAbilities env Gondola where
  getAbilities iid window@(Window Timing.When NonFast) (Gondola attrs) =
    withBaseActions iid window attrs $ do
      pure [locationAbility (ability attrs)]
  getAbilities iid window (Gondola attrs) = getAbilities iid window attrs

instance LocationRunner env => RunMessage env Gondola where
  runMessage msg l@(Gondola attrs) = case msg of
    Revelation _ source | isSource attrs source -> do
      locationIds <-
        setToList . deleteSet (toId attrs) <$> getSet @LocationId ()
      l <$ pushAll
        (MoveAllTo (toId attrs) : [ RemoveLocation lid | lid <- locationIds ])
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      l <$ push
        (chooseOne
          iid
          [ Label
            "Test {combat} (2)"
            [ BeginSkillTest
                iid
                (toSource attrs)
                (toTarget attrs)
                Nothing
                SkillCombat
                2
            ]
          , Label
            "Test {agility} (2)"
            [ BeginSkillTest
                iid
                (toSource attrs)
                (toTarget attrs)
                Nothing
                SkillAgility
                2
            ]
          ]
        )
    PassedSkillTest _ _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> l <$ push (PlaceResources (toTarget attrs) 1)
    _ -> Gondola <$> runMessage msg attrs
