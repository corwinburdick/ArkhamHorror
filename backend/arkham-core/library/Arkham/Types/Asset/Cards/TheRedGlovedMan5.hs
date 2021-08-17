module Arkham.Types.Asset.Cards.TheRedGlovedMan5
  ( theRedGlovedMan5
  , TheRedGlovedMan5(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Matcher
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Phase
import Arkham.Types.SkillType
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing

newtype Metadata = Metadata { chosenSkills :: [SkillType] }
  deriving stock (Show, Generic, Eq)
  deriving anyclass (ToJSON, FromJSON)

newtype TheRedGlovedMan5 = TheRedGlovedMan5 (AssetAttrs `With` Metadata)
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theRedGlovedMan5 :: AssetCard TheRedGlovedMan5
theRedGlovedMan5 =
  ally (TheRedGlovedMan5 . (`with` Metadata [])) Cards.theRedGlovedMan5 (4, 4)

instance HasAbilities env TheRedGlovedMan5 where
  getAbilities _ _ (TheRedGlovedMan5 (x `With` _)) = pure
    [ restrictedAbility x 1 OwnsThis
      $ ReactionAbility
          (AssetEntersPlay Timing.When (AssetWithId $ toId x))
          Free
    , restrictedAbility x 2 OwnsThis
      $ ForcedAbility (PhaseEnds Timing.When $ PhaseIs MythosPhase)
    ]

instance HasModifiersFor env TheRedGlovedMan5 where
  getModifiersFor _ (InvestigatorTarget iid) (TheRedGlovedMan5 (a `With` Metadata {..}))
    | ownedBy a iid
    = pure $ toModifiers a $ map (`BaseSkillOf` 6) chosenSkills
  getModifiersFor _ _ _ = pure []

skillTypes :: [(Text, SkillType)]
skillTypes =
  [ ("Willpower", SkillWillpower)
  , ("Intellect", SkillIntellect)
  , ("Combat", SkillCombat)
  , ("Agility", SkillAgility)
  ]

instance AssetRunner env => RunMessage env TheRedGlovedMan5 where
  runMessage msg a@(TheRedGlovedMan5 (attrs `With` metadata)) = case msg of
    UseCardAbility iid source Nothing 1 p | isSource attrs source -> a <$ push
      (chooseOne
        iid
        [ Label
            label
            [UseCardAbility iid source (Just (SkillChoiceMetadata [s])) 1 p]
        | (label, s) <- skillTypes
        ]
      )
    UseCardAbility iid source (Just (SkillChoiceMetadata [c])) 1 p
      | isSource attrs source -> a <$ push
        (chooseOne
          iid
          [ Label
              label
              [ UseCardAbility
                  iid
                  source
                  (Just (SkillChoiceMetadata [c, s]))
                  1
                  p
              ]
          | (label, s) <- filter ((/= c) . snd) skillTypes
          ]
        )
    UseCardAbility _ source (Just (SkillChoiceMetadata [c, d])) 1 _
      | isSource attrs source
      -> pure $ TheRedGlovedMan5 $ attrs `with` Metadata [c, d]
    UseCardAbility _ source (Just _) 1 _ | isSource attrs source ->
      error "too many skills"
    UseCardAbility _ source _ 2 _ | isSource attrs source ->
      a <$ push (Discard $ toTarget attrs)
    _ -> TheRedGlovedMan5 . (`with` metadata) <$> runMessage msg attrs
