{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
module Arkham.Handler.Api.Games where

import Arkham.Types
import Import
import Json

data GameJson = GameJson
  { gameCycle :: Maybe ArkhamCycle
  , gameScenario :: ArkhamScenario
  , gameInvestigators :: [ArkhamInvestigator]
  , gameActions :: [ArkhamAction]
  }
  deriving stock (Generic, Show)
  deriving (FromJSON, ToJSON) via Codec (Drop "game") GameJson

rolandBanks :: ArkhamInvestigator
rolandBanks = ArkhamInvestigator
  { arkhamInvestigatorName = "Roland Banks"
  , arkhamInvestigatorWillpower = 3
  , arkhamInvestigatorIntellect = 3
  , arkhamInvestigatorCombat = 4
  , arkhamInvestigatorAgility = 2
  , arkhamInvestigatorHealth = 9
  , arkhamInvestigatorSanity = 5
  }

getApiV1ArkhamGameR :: ArkhamHorrorGameId -> Handler GameJson
getApiV1ArkhamGameR _ = do
  cycle <- liftIO $ decodeFileStrict' "data/arkham/cycles/nightOfTheZealot.json"
  pure $ GameJson cycle scenario [rolandBanks] [ArkhamActionRevealLocation 0]
 where
  scenario = ArkhamScenario
    "The Gathering"
    [ ArkhamStackAgenda $ ArkhamAgenda $ ArkhamCard
      (ArkhamCardFront "https://arkhamdb.com/bundles/cards/01105.jpg")
      (ArkhamCardBack "https://arkhamdb.com/bundles/cards/01105b.jpg")
    , ArkhamStackAct $ ArkhamAct $ ArkhamCard
      (ArkhamCardFront "https://arkhamdb.com/bundles/cards/01108.jpg")
      (ArkhamCardBack "https://arkhamdb.com/bundles/cards/01108b.jpg")
    ]
    [ ArkhamLocation
        (ArkhamLocationFront
          "Study"
          ArkhamLocationSymbolCircle
          (ArkhamCardFront "https://arkhamdb.com/bundles/cards/01111b.png")
        )
        (ArkhamLocationBack
          "Study"
          ArkhamLocationSymbolCircle
          []
          (ArkhamCardBack "https://arkhamdb.com/bundles/cards/01111.png")
          2
          (ArkhamClueCountPerInvestigator 2)
        )
    ]
