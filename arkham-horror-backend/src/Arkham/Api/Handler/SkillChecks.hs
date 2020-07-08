module Arkham.Api.Handler.SkillChecks
  ( postApiV1ArkhamGameSkillCheckR
  , postApiV1ArkhamGameSkillCheckApplyResultR
  )
where

import Arkham.Conversion
import Arkham.Internal.PlayerCard
import Arkham.Internal.Types
import Arkham.Internal.Util
import Arkham.Types
import Arkham.Types.Action
import Arkham.Types.Card
import Arkham.Types.ChaosToken
import Arkham.Types.Enemy
import Arkham.Types.Game
import Arkham.Types.GameState
import Arkham.Types.Investigator
import Arkham.Types.Location
import Arkham.Types.Player
import Arkham.Types.Skill
import Arkham.Util
import Data.UUID
import GHC.Stack
import Import
import Lens.Micro
import Lens.Micro.Platform ()
import Safe (fromJustNote)

postApiV1ArkhamGameSkillCheckR :: ArkhamGameId -> Handler ArkhamGameData
postApiV1ArkhamGameSkillCheckR gameId = do
  game <- runDB $ get404 gameId
  cards <- requireCheckJsonBody
  let ArkhamGameStateStepSkillCheckStep step = game ^. gameStateStep
  checkDifficulty <- getDifficulty game (ascsAction step)
  checkSkill <- getSkill game (ascsAction step)
  runAction (Entity gameId game) checkSkill cards checkDifficulty

postApiV1ArkhamGameSkillCheckApplyResultR
  :: ArkhamGameId -> Handler ArkhamGameData
postApiV1ArkhamGameSkillCheckApplyResultR gameId = do
  game <- runDB $ get404 gameId
  let
    ArkhamGameStateStepRevealTokenStep ArkhamRevealTokenStep {..} =
      game ^. gameStateStep
    tokenInternal = toInternalToken game artsToken

  case
      tokenToResult
        tokenInternal
        (game ^. currentData . gameState)
        (game ^. activePlayer)
    of
      Modifier n -> do
        checkDifficulty <- getDifficulty game artsAction
        modifiedSkillValue <- determineModifiedSkillValue
          artsType
          (game ^. activePlayer)
          artsCards
          n
        if modifiedSkillValue >= checkDifficulty
          then runDB $ successfulCheck game artsAction >>= updateGame gameId
          else runDB $ failedCheck game artsAction >>= updateGame gameId
      Failure -> runDB $ failedCheck game artsAction >>= updateGame gameId

getLocation :: HasLocations a => a -> ArkhamCardCode -> ArkhamLocation
getLocation g locationId = g ^?! locations . ix locationId

getDifficulty :: MonadIO m => ArkhamGame -> ArkhamAction -> m Int
getDifficulty g action = case action of
  (FightEnemyAction a) -> fightOf g (afeaEnemyId a)
  (EvadeEnemyAction a) -> evadeOf g (aeveaEnemyId a)
  (InvestigateAction a) -> shroudOf g $ getLocation g (aiaLocationId a)
  _ -> error "Can not get difficulty for action"

getSkill :: MonadIO m => ArkhamGame -> ArkhamAction -> m ArkhamSkillType
getSkill _ action = case action of
  (FightEnemyAction _) -> pure ArkhamSkillCombat
  (EvadeEnemyAction _) -> pure ArkhamSkillAgility
  (InvestigateAction _) -> pure ArkhamSkillIntellect
  _ -> error "Can not get difficulty for action"

shroudOf :: MonadIO m => ArkhamGame -> ArkhamLocation -> m Int
shroudOf _ location = pure $ alShroud location

determineModifiedSkillValue
  :: MonadIO m
  => ArkhamSkillType
  -> ArkhamPlayer
  -> [ArkhamCard]
  -> Int
  -> m Int
determineModifiedSkillValue skillType player' commitedCards tokenModifier =
  pure $ skillValue player' skillType + cardContributions + tokenModifier
 where
  cardContributions = length $ filter (== skillType) $ concatMap
    (maybe [] aciTestIcons . toInternalPlayerCard)
    commitedCards

skillValue :: ArkhamPlayer -> ArkhamSkillType -> Int
skillValue p skillType = case skillType of
  ArkhamSkillWillpower -> unArkhamSkill $ aiWillpower $ _investigator p
  ArkhamSkillIntellect -> unArkhamSkill $ aiIntellect $ _investigator p
  ArkhamSkillCombat -> unArkhamSkill $ aiCombat $ _investigator p
  ArkhamSkillAgility -> unArkhamSkill $ aiAgility $ _investigator p
  ArkhamSkillWild -> error "Not a possible skill"

revealToken
  :: ArkhamChaosToken
  -> Int
  -> Int
  -> [ArkhamCard]
  -> ArkhamGameStateStep
  -> ArkhamGameStateStep
revealToken token' checkDifficulty modifiedSkillValue cards (ArkhamGameStateStepSkillCheckStep ArkhamSkillCheckStep {..})
  = ArkhamGameStateStepRevealTokenStep $ ArkhamRevealTokenStep
    ascsType
    ascsAction
    token'
    checkDifficulty
    modifiedSkillValue
    cards
revealToken _ _ _ _ s = s

failedCheck :: (MonadIO m) => ArkhamGame -> ArkhamAction -> m ArkhamGame
failedCheck g _ = pure g <&> gameStateStep .~ investigatorStep

successfulCheck
  :: (HasCallStack, MonadIO m) => ArkhamGame -> ArkhamAction -> m ArkhamGame
successfulCheck g action = case action of
  (InvestigateAction a) ->
    successfulInvestigation g (getLocation g (aiaLocationId a)) 1
  (FightEnemyAction a) -> successfulFight g (afeaEnemyId a) 1
  _ -> error "Unknown check"

successfulInvestigation
  :: MonadIO m => ArkhamGame -> ArkhamLocation -> Int -> m ArkhamGame
successfulInvestigation g l clueCount =
  pure g
    <&> (locations . at (alCardCode l) . _Just . clues -~ clueCount)
    <&> (activePlayer . clues +~ clueCount)
    <&> (gameStateStep .~ investigatorStep)

successfulFight :: MonadIO m => ArkhamGame -> UUID -> Int -> m ArkhamGame
successfulFight g enemyId damage' =
  if _enemyDamage enemy' >= _enemyHealth enemy'
    then discardEnemy g enemyId <&> gameStateStep .~ investigatorStep
    else
      pure g
      <&> (enemies . at enemyId ?~ enemy')
      <&> (gameStateStep .~ investigatorStep)
  where enemy' = findEnemy g enemyId & damage +~ damage'

investigatorStep :: ArkhamGameStateStep
investigatorStep = ArkhamGameStateStepInvestigatorActionStep

findEnemy :: HasEnemies a => a -> UUID -> ArkhamEnemy
findEnemy g uuid = fromJustNote "Could not find enemy" $ g ^? enemies . ix uuid

fightOf :: (MonadIO m, HasEnemies a) => a -> UUID -> m Int
fightOf g uuid = pure . _enemyCombat $ findEnemy g uuid

evadeOf :: (MonadIO m, HasEnemies a) => a -> UUID -> m Int
evadeOf g uuid = pure . _enemyAgility $ findEnemy g uuid

commitCards :: [Int] -> [ArkhamCard] -> ([ArkhamCard], [ArkhamCard])
commitCards cardIndexes hand' =
  over both (map snd) $ partition (\(i, _) -> i `elem` cardIndexes) $ zip
    [0 ..]
    hand'

runAction
  :: Entity ArkhamGame
  -> ArkhamSkillType
  -> [Int]
  -> Int
  -> Handler ArkhamGameData
runAction (Entity gameId game) skillType cardIndexes checkDifficulty = do
  let
    (commitedCards, remainingCards) =
      commitCards cardIndexes (game ^. activePlayer . hand)

  token' <- liftIO $ drawChaosToken game
  modifiedSkillValue <- determineModifiedSkillValue
    skillType
    (game ^. activePlayer)
    commitedCards
    (tokenToModifier game (game ^. activePlayer) token')

  runDB
    $ updateGame gameId
    $ game
    & (gameStateStep
      %~ revealToken token' checkDifficulty modifiedSkillValue commitedCards
      )
    & (activePlayer . hand .~ remainingCards)
    & (activePlayer . discard %~ (commitedCards ++))

