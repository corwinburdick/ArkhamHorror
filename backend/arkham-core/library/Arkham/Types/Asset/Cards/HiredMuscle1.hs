module Arkham.Types.Asset.Cards.HiredMuscle1
  ( hiredMuscle1
  , HiredMuscle1(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Game.Helpers
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target

newtype HiredMuscle1 = HiredMuscle1 AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

hiredMuscle1 :: AssetCard HiredMuscle1
hiredMuscle1 = ally HiredMuscle1 Cards.hiredMuscle1 (3, 1)

instance HasAbilities env HiredMuscle1 where
  getAbilities iid window (HiredMuscle1 attrs) = getAbilities iid window attrs

instance HasModifiersFor env HiredMuscle1 where
  getModifiersFor _ (InvestigatorTarget iid) (HiredMuscle1 a) =
    pure [ toModifier a (SkillModifier SkillCombat 1) | ownedBy a iid ]
  getModifiersFor _ _ _ = pure []

instance AssetRunner env => RunMessage env HiredMuscle1 where
  runMessage msg a@(HiredMuscle1 attrs@AssetAttrs {..}) = case msg of
    EndUpkeep -> do
      let iid = fromJustNote "must be owned" assetInvestigator
      a <$ push
        (chooseOne
          iid
          [ Label "Pay 1 Resource to Hired Muscle" [SpendResources iid 1]
          , Label "Discard Hired Muscle" [Discard $ toTarget attrs]
          ]
        )
    _ -> HiredMuscle1 <$> runMessage msg attrs
