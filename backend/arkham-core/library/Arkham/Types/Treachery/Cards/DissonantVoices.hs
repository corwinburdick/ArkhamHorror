{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Treachery.Cards.DissonantVoices where

import Arkham.Json
import Arkham.Types.Card.PlayerCard
import Arkham.Types.Classes
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner
import Arkham.Types.TreacheryId
import ClassyPrelude
import Lens.Micro

newtype DissonantVoices= DissonantVoices Attrs
  deriving newtype (Show, ToJSON, FromJSON)

dissonantVoices :: TreacheryId -> DissonantVoices
dissonantVoices uuid = DissonantVoices $ baseAttrs uuid "01165"

instance (TreacheryRunner env) => RunMessage env DissonantVoices where
  runMessage msg t@(DissonantVoices attrs@Attrs {..}) = case msg of
    RunTreachery iid tid | tid == treacheryId -> do
      unshiftMessages
        [ AttachTreacheryToInvestigator tid iid
        , AddModifier
          (InvestigatorTarget iid)
          (CannotPlay [AssetType, EventType] (TreacherySource tid))
        ]
      pure $ DissonantVoices $ attrs & attachedInvestigator ?~ iid
    EndRound -> case treacheryAttachedInvestigator of
      Just iid -> t <$ unshiftMessages
        [ RemoveAllModifiersOnTargetFrom
          (InvestigatorTarget iid)
          (TreacherySource treacheryId)
        , Discard (TreacheryTarget treacheryId)
        ]
      Nothing -> pure t -- Note: This assumes the treachery never attached for some reason
    _ -> DissonantVoices <$> runMessage msg attrs
