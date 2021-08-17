module Arkham.Types.Location.Cards.BrackishWaters
  ( BrackishWaters(..)
  , brackishWaters
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Assets
import qualified Arkham.Location.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Card
import Arkham.Types.Card.Id
import Arkham.Types.Card.PlayerCard
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Matcher
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Window

newtype BrackishWaters = BrackishWaters LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

brackishWaters :: LocationCard BrackishWaters
brackishWaters = location
  BrackishWaters
  Cards.brackishWaters
  1
  (Static 0)
  Triangle
  [Squiggle, Square, Diamond, Hourglass]

instance HasModifiersFor env BrackishWaters where
  getModifiersFor _ (InvestigatorTarget iid) (BrackishWaters attrs) =
    pure $ toModifiers
      attrs
      [ CannotPlay [(AssetType, mempty)]
      | iid `elem` locationInvestigators attrs
      ]
  getModifiersFor _ _ _ = pure []

-- TODO: Cost is an OR and we should be able to capture this
-- first idea is change discard to take a source @DiscardCost 1 [DiscardFromHand, DiscardFromPlay] (Just AssetType) mempty mempty@
instance (HasList Card env ExtendedCardMatcher, ActionRunner env) => HasAbilities env BrackishWaters where
  getAbilities iid window@(Window Timing.When NonFast) (BrackishWaters attrs@LocationAttrs {..})
    = withBaseActions iid window attrs $ do
      assetNotTaken <- isNothing <$> selectOne (assetIs Assets.fishingNet)
      inPlayAssetsCount <- getInPlayOf iid <&> count
        (\case
          PlayerCard pc -> cdCardType (toCardDef pc) == AssetType
          EncounterCard _ -> False
        )
      handCount <- length <$> getList @Card
        (InHandOf (InvestigatorWithId iid)
        <> BasicCardMatch (CardWithType AssetType)
        )
      let assetsCount = handCount + inPlayAssetsCount
      pure
        [ mkAbility attrs 1 $ ActionAbility Nothing $ ActionCost 1
        | (iid `member` locationInvestigators)
          && (assetsCount >= 2)
          && assetNotTaken
        ]
  getAbilities i window (BrackishWaters attrs) = getAbilities i window attrs

instance LocationRunner env => RunMessage env BrackishWaters where
  runMessage msg l@(BrackishWaters attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      assetIds <- selectList (AssetOwnedBy You <> DiscardableAsset)
      handAssetIds <- map unHandCardId <$> getSetList (iid, AssetType)
      l <$ pushAll
        [ chooseN iid 2
        $ [ Discard (AssetTarget aid) | aid <- assetIds ]
        <> [ DiscardCard iid cid | cid <- handAssetIds ]
        , BeginSkillTest iid source (toTarget attrs) Nothing SkillAgility 3
        ]
    PassedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        fishingNet <- PlayerCard <$> genPlayerCard Assets.fishingNet
        l <$ push (TakeControlOfSetAsideAsset iid fishingNet)
    _ -> BrackishWaters <$> runMessage msg attrs
