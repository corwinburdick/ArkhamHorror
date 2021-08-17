module Arkham.Types.Asset.Cards.RabbitsFoot3
  ( RabbitsFoot3(..)
  , rabbitsFoot3
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Matcher
import Arkham.Types.Message
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing

newtype RabbitsFoot3 = RabbitsFoot3 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

rabbitsFoot3 :: AssetCard RabbitsFoot3
rabbitsFoot3 = accessory RabbitsFoot3 Cards.rabbitsFoot3

instance HasAbilities env RabbitsFoot3 where
  getAbilities _ _ (RabbitsFoot3 a) = pure
    [ restrictedAbility a 1 OwnsThis $ ReactionAbility
        (SkillTestResult Timing.After You AnySkillTest (FailureResult AnyValue))
        (ExhaustCost $ toTarget a)
    ]

instance AssetRunner env => RunMessage env RabbitsFoot3 where
  runMessage msg a@(RabbitsFoot3 attrs) = case msg of
    UseCardAbility iid source (Just (IntMetadata x)) 1 _
      | isSource attrs source -> a <$ push
        (SearchTopOfDeck
          iid
          source
          (InvestigatorTarget iid)
          x
          mempty
          (ShuffleBackIn $ DrawFound iid)
        )
    _ -> RabbitsFoot3 <$> runMessage msg attrs
