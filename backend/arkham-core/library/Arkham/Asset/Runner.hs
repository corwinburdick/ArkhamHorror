{-# OPTIONS_GHC -Wno-orphans #-}
module Arkham.Asset.Runner
  ( module X
  ) where

import Arkham.Prelude

import Arkham.Asset.Attrs as X
import Arkham.Asset.Helpers as X
import Arkham.Asset.Uses as X
import Arkham.Classes as X
import Arkham.Message as X hiding ( AssetDamage )

import Arkham.Card
import Arkham.Message qualified as Msg
import Arkham.Modifier
import Arkham.Source
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Window ( Window (..) )
import Arkham.Window qualified as Window

instance RunMessage AssetAttrs where
  runMessage msg a@AssetAttrs {..} = case msg of
    SetOriginalCardCode cardCode -> pure $ a & originalCardCodeL .~ cardCode
    ReadyExhausted -> case assetController of
      Just iid -> do
        modifiers <- getModifiers (toSource a) (InvestigatorTarget iid)
        if ControlledAssetsCannotReady `elem` modifiers
          then pure a
          else a <$ push (Ready $ toTarget a)
      Nothing -> a <$ push (Ready $ toTarget a)
    RemoveAllDoom _ -> pure $ a & doomL .~ 0
    PlaceClues target n | isTarget a target -> pure $ a & cluesL +~ n
    PlaceDoom target n | isTarget a target -> pure $ a & doomL +~ n
    RemoveDoom target n | isTarget a target ->
      pure $ a & doomL %~ min 0 . subtract n
    RemoveClues target n | isTarget a target -> do
      when (assetClues - n <= 0) $ pushAll =<< windows
        [Window.LastClueRemovedFromAsset (toId a)]
      pure $ a & cluesL %~ max 0 . subtract n
    CheckDefeated _ -> do
      when (defeated a) $ do
        whenWindow <- checkWindows
          [Window Timing.When (Window.AssetDefeated $ toId a)]
        afterWindow <- checkWindows
          [Window Timing.When (Window.AssetDefeated $ toId a)]
        pushAll
          $ [whenWindow]
          <> resolve (AssetDefeated assetId)
          <> [afterWindow]
      pure a
    AssetDefeated aid | aid == assetId -> a <$ push (Discard $ toTarget a)
    Msg.AssetDamage aid _ health sanity | aid == assetId ->
      pure $ a & damageL +~ health & horrorL +~ sanity
    HealDamage (isTarget a -> True) n ->
      pure $ a & damageL %~ max 0 . subtract n
    HealHorror (isTarget a -> True) n ->
      pure $ a & horrorL %~ max 0 . subtract n
    When (InvestigatorResigned iid) | assetController == Just iid ->
      a <$ push (ResignWith (AssetTarget assetId))
    InvestigatorEliminated iid | assetController == Just iid ->
      a <$ push (Discard (AssetTarget assetId))
    AddUses target useType' n | a `isTarget` target -> case assetUses of
      Uses useType'' m | useType' == useType'' ->
        pure $ a & usesL .~ Uses useType' (n + m)
      _ -> error "Trying to add the wrong use type"
    SpendUses target useType' n | isTarget a target -> case assetUses of
      Uses useType'' m | useType' == useType'' -> do
        let remainingUses = max 0 (m - n)
        when
          (assetDiscardWhenNoUses && remainingUses == 0)
          (push $ Discard $ toTarget a)
        pure $ a & usesL .~ Uses useType' remainingUses
      _ -> error "Trying to use the wrong use type"
    AttachAsset aid target | aid == assetId -> case target of
      LocationTarget lid ->
        pure
          $ a
          & (controllerL .~ Nothing)
          . (enemyL .~ Nothing)
          . (locationL ?~ lid)
      EnemyTarget eid ->
        pure
          $ a
          & (controllerL .~ Nothing)
          . (locationL .~ Nothing)
          . (enemyL ?~ eid)
      _ -> error "Cannot attach asset to that type"
    RemoveFromGame target | a `isTarget` target ->
      a <$ push (RemovedFromPlay $ toSource a)
    Discard target | a `isTarget` target -> do
      windows' <- windows [Window.WouldBeDiscarded (toTarget a)]
      a <$ pushAll
        (windows'
        <> [RemovedFromPlay $ toSource a, Discarded (toTarget a) (toCard a)]
        )
    Exile target | a `isTarget` target ->
      a <$ pushAll [RemovedFromPlay $ toSource a, Exiled target (toCard a)]
    RemovedFromPlay source | isSource a source -> do
      push =<< checkWindows
        ((`Window` Window.LeavePlay (toTarget a))
        <$> [Timing.When, Timing.After]
        )
      pure a
    InvestigatorPlayedAsset iid aid | aid == assetId -> do
      -- we specifically use the investigator source here because the
      -- asset has no knowledge of being owned yet, and this will allow
      -- us to bring the investigator's id into scope
      modifiers <- getModifiers (InvestigatorSource iid) (toTarget a)
      let
        startingUses = cdUses $ toCardDef a
        applyModifier (Uses uType m) (AdditionalStartingUses n) =
          Uses uType (n + m)
        applyModifier m _ = m
      whenEnterMsg <- checkWindows
        [Window Timing.When (Window.EnterPlay $ toTarget a)]
      afterEnterMsg <- checkWindows
        [Window Timing.After (Window.EnterPlay $ toTarget a)]

      pushAll [whenEnterMsg, afterEnterMsg]
      pure
        $ a
        & (controllerL ?~ iid)
        & (usesL .~ if assetUses == NoUses
            then foldl' applyModifier startingUses modifiers
            else assetUses
          )
    InvestigatorPlayDynamicAsset iid aid _ | aid == assetId -> do
      a <$ push (InvestigatorPlayAsset iid aid)
    TakeControlOfAsset iid aid | aid == assetId -> do
      push =<< checkWindows
        ((`Window` Window.TookControlOfAsset iid aid)
        <$> [Timing.When, Timing.After]
        )
      pure $ a & controllerL ?~ iid
    ReplacedInvestigatorAsset iid aid | aid == assetId ->
      pure $ a & controllerL ?~ iid
    AddToScenarioDeck key target | isTarget a target -> do
      pushAll
        [AddCardToScenarioDeck key (toCard a), RemoveFromGame (toTarget a)]
      pure $ a & controllerL .~ Nothing
    Exhaust target | a `isTarget` target -> pure $ a & exhaustedL .~ True
    Ready target | a `isTarget` target -> case assetController of
      Just iid -> do
        modifiers <- getModifiers (toSource a) (InvestigatorTarget iid)
        if ControlledAssetsCannotReady `elem` modifiers
          then pure a
          else pure $ a & exhaustedL .~ False
      Nothing -> pure $ a & exhaustedL .~ False
    PlaceUnderneath (isTarget a -> True) cards -> do
      pure $ a & cardsUnderneathL <>~ cards
    Blanked msg' -> runMessage msg' a
    _ -> pure a
