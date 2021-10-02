module Arkham.Types.Event.Cards.AstralTravel
  ( astralTravel
  , AstralTravel(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner
import Arkham.Types.Matcher hiding (MoveAction)
import Arkham.Types.Message
import Arkham.Types.RequestedTokenStrategy
import Arkham.Types.Target
import Arkham.Types.Token
import Arkham.Types.Trait qualified as Trait

newtype AstralTravel = AstralTravel EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

astralTravel :: EventCard AstralTravel
astralTravel = event AstralTravel Cards.astralTravel

instance EventRunner env => RunMessage env AstralTravel where
  runMessage msg e@(AstralTravel attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      locations <- selectList $ RevealedLocation <> Unblocked <> NotYourLocation
      e <$ pushAll
        [ chooseOne
          iid
          [ TargetLabel (LocationTarget lid) [MoveAction iid lid Free False]
          | lid <- locations
          ]
        , RequestTokens (toSource attrs) Nothing 1 SetAside
        , Discard (toTarget attrs)
        ]
    RequestedTokens source _ tokens | isSource attrs source -> e <$ when
      (any
        ((`elem` [Skull, Cultist, Tablet, ElderThing, AutoFail]) . tokenFace)
        tokens
      )
      do
        targets <- selectList
          $ AssetOneOf (AssetWithTrait <$> [Trait.Item, Trait.Ally])
        case targets of
          [] -> push
            (InvestigatorAssignDamage (eventOwner attrs) source DamageAny 1 0)
          xs ->
            push (chooseOne (eventOwner attrs) (Discard . AssetTarget <$> xs))
    _ -> AstralTravel <$> runMessage msg attrs
