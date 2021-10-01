module Arkham.Types.Asset.Runner where

import Arkham.Prelude

import Arkham.Types.Ability
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Direction
import Arkham.Types.Id
import Arkham.Types.Matcher
import Arkham.Types.Query
import Arkham.Types.Source
import Arkham.Types.Trait

type AssetRunner env
  = ( HasQueue env
    , Query AssetMatcher env
    , Query AbilityMatcher env
    , Query LocationMatcher env
    , Query InvestigatorMatcher env
    , Query EnemyMatcher env
    , HasSkillValue env InvestigatorId
    , HasCostPayment env
    , HasModifiersFor env ()
    , HasList UsedAbility env ()
    , HasList CommittedCard env InvestigatorId
    , HasId LeadInvestigatorId env ()
    , HasCount ActionRemainingCount env InvestigatorId
    , HasCount RemainingSanity env InvestigatorId
    , HasCount AssetCount env (InvestigatorId, [Trait])
    , HasCount CardCount env InvestigatorId
    , HasCount ClueCount env LocationId
    , HasCount DamageCount env InvestigatorId
    , HasCount EnemyCount env InvestigatorId
    , HasCount HealthDamageCount env EnemyId
    , HasCount HorrorCount env InvestigatorId
    , HasCount ResourceCount env InvestigatorId
    , HasCount SanityDamageCount env EnemyId
    , HasId (Maybe LocationId) env (Direction, LocationId)
    , HasId (Maybe LocationId) env LocationMatcher
    , HasId ActiveInvestigatorId env ()
    , HasId CardCode env EnemyId
    , HasId LocationId env InvestigatorId
    , HasRecord env
    , HasSet AccessibleLocationId env LocationId
    , HasSet BlockedLocationId env ()
    , HasSet ConnectedLocationId env LocationId
    , HasSet EnemyId env ([Trait], LocationId)
    , HasSet EnemyId env InvestigatorId
    , HasSet EnemyId env LocationId
    , HasSet InScenarioInvestigatorId env ()
    , HasSet InvestigatorId env ()
    , HasSet InvestigatorId env LocationId
    , HasSet Trait env AssetId
    , HasSet Trait env EnemyId
    , HasSet Trait env Source
    )
