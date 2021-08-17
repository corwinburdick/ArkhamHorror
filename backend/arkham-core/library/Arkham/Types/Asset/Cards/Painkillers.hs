module Arkham.Types.Asset.Cards.Painkillers
  ( painkillers
  , Painkillers(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner
import Arkham.Types.Asset.Uses
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Matcher hiding (FastPlayerWindow)
import Arkham.Types.Message
import Arkham.Types.Target

newtype Painkillers = Painkillers AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

painkillers :: AssetCard Painkillers
painkillers = asset Painkillers Cards.painkillers

instance HasAbilities env Painkillers where
  getAbilities _ _ (Painkillers a) = pure
    [ restrictedAbility
        a
        1
        (OwnsThis <> InvestigatorExists (You <> InvestigatorWithAnyDamage))
        (FastAbility
          (Costs
            [ UseCost (toId a) Supply 1
            , ExhaustCost (toTarget a)
            , HorrorCost (toSource a) YouTarget 1
            ]
          )
        )
    ]

instance AssetRunner env => RunMessage env Painkillers where
  runMessage msg a@(Painkillers attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ push (HealDamage (InvestigatorTarget iid) 1)
    _ -> Painkillers <$> runMessage msg attrs
