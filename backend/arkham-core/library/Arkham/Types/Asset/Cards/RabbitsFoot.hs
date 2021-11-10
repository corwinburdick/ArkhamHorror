module Arkham.Types.Asset.Cards.RabbitsFoot where

import Arkham.Prelude

import Arkham.Asset.Cards qualified as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Matcher
import Arkham.Types.Timing qualified as Timing

newtype RabbitsFoot = RabbitsFoot AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

rabbitsFoot :: AssetCard RabbitsFoot
rabbitsFoot = asset RabbitsFoot Cards.rabbitsFoot

instance HasAbilities RabbitsFoot where
  getAbilities (RabbitsFoot a) =
    [ restrictedAbility a 1 OwnsThis $ ReactionAbility
        (SkillTestResult Timing.After You AnySkillTest (FailureResult AnyValue))
        (ExhaustCost $ toTarget a)
    ]

instance AssetRunner env => RunMessage env RabbitsFoot where
  runMessage msg a@(RabbitsFoot attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ push (DrawCards iid 1 False)
    _ -> RabbitsFoot <$> runMessage msg attrs
