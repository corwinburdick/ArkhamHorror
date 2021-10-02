module Arkham.Types.Event.Cards.SneakAttack2
  ( sneakAttack2
  , SneakAttack2(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Types.Classes
import Arkham.Types.DamageEffect
import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner
import Arkham.Types.Matcher hiding (NonAttackDamageEffect)
import Arkham.Types.Message

newtype SneakAttack2 = SneakAttack2 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

sneakAttack2 :: EventCard SneakAttack2
sneakAttack2 = event SneakAttack2 Cards.sneakAttack2

instance EventRunner env => RunMessage env SneakAttack2 where
  runMessage msg e@(SneakAttack2 attrs) = case msg of
    InvestigatorPlayEvent you eid _ _ _ | eid == toId attrs -> do
      yourLocation <- LocationWithId <$> getId you
      enemies <- selectList $ EnemyNotEngagedWithYou <> EnemyAt yourLocation
      e <$ pushAll
        ([ EnemyDamage enemy you (toSource attrs) NonAttackDamageEffect 2
         | enemy <- enemies
         ]
        <> [Discard $ toTarget attrs]
        )
    _ -> SneakAttack2 <$> runMessage msg attrs
