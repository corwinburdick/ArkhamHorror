{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Asset.Cards.Shotgun4 where

import Arkham.Import

import qualified Arkham.Types.Action as Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Asset.Uses (Uses(..), useCount)
import qualified Arkham.Types.Asset.Uses as Resource

newtype Shotgun4 = Shotgun4 Attrs
  deriving newtype (Show, ToJSON, FromJSON)

shotgun4 :: AssetId -> Shotgun4
shotgun4 uuid =
  Shotgun4 $ (baseAttrs uuid "01029") { assetSlots = [HandSlot, HandSlot] }

instance HasModifiersFor env Shotgun4 where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env Shotgun4 where
  getActions iid window (Shotgun4 a) | ownedBy a iid = do
    fightAvailable <- hasFightActions iid window
    pure
      [ ActivateCardAbilityAction
          iid
          (mkAbility (toSource a) 1 (ActionAbility 1 (Just Action.Fight)))
      | useCount (assetUses a) > 0 && fightAvailable
      ]
  getActions _ _ _ = pure []

instance (AssetRunner env) => RunMessage env Shotgun4 where
  runMessage msg a@(Shotgun4 attrs) = case msg of
    InvestigatorPlayAsset _ aid _ _ | aid == assetId attrs ->
      Shotgun4 <$> runMessage msg (attrs & usesL .~ Uses Resource.Ammo 2)
    UseCardAbility iid source _ 1 | isSource attrs source -> do
      unshiftMessages
        [ CreateSkillTestEffect
          (EffectModifiers [SkillModifier SkillCombat 3])
          source
          (InvestigatorTarget iid)
        , ChooseFightEnemy iid source SkillCombat False
        ]
      pure $ Shotgun4 $ attrs & usesL %~ Resource.use
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} n
      | isSource attrs source
      -> let val = min 1 (max 5 n)
         in
           a <$ unshiftMessage
             (CreateSkillTestEffect
               (EffectModifiers [DamageDealt val])
               source
               (InvestigatorTarget iid)
             )
    PassedSkillTest iid _ source SkillTestInitiatorTarget{} n
      | isSource attrs source
      -> let val = min 1 (max 5 n)
         in
           a <$ unshiftMessage
             (CreateSkillTestEffect
               (EffectModifiers [DamageDealt val])
               source
               (InvestigatorTarget iid)
             )
    _ -> Shotgun4 <$> runMessage msg attrs
