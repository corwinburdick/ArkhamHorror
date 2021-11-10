module Arkham.Types.Asset.Cards.Newspaper
  ( newspaper
  , Newspaper(..)
  ) where

import Arkham.Prelude

import Arkham.Asset.Cards qualified as Cards
import Arkham.Types.Action qualified as Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Id
import Arkham.Types.Modifier
import Arkham.Types.Query
import Arkham.Types.SkillType
import Arkham.Types.Target

newtype Newspaper = Newspaper AssetAttrs
  deriving anyclass (IsAsset, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

newspaper :: AssetCard Newspaper
newspaper = asset Newspaper Cards.newspaper

instance HasCount ClueCount env InvestigatorId => HasModifiersFor env Newspaper where
  getModifiersFor _ (InvestigatorTarget iid) (Newspaper a) | ownedBy a iid = do
    clueCount <- unClueCount <$> getCount iid
    pure
      [ toModifier a $ ActionSkillModifier Action.Investigate SkillIntellect 2
      | clueCount == 0
      ]
  getModifiersFor _ _ _ = pure []

instance AssetRunner env => RunMessage env Newspaper where
  runMessage msg (Newspaper attrs) = Newspaper <$> runMessage msg attrs
