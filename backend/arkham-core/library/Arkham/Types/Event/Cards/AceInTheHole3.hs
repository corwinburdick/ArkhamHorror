module Arkham.Types.Event.Cards.AceInTheHole3
  ( aceInTheHole3
  , AceInTheHole3(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Message

newtype AceInTheHole3 = AceInTheHole3 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

aceInTheHole3 :: EventCard AceInTheHole3
aceInTheHole3 = event AceInTheHole3 Cards.aceInTheHole3

instance RunMessage env AceInTheHole3 where
  runMessage msg e@(AceInTheHole3 attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      e <$ pushAll
        [GainActions iid (toSource attrs) 3, Discard (toTarget attrs)]
    _ -> AceInTheHole3 <$> runMessage msg attrs
