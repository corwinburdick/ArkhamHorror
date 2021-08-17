module Arkham.Types.Treachery.Cards.AcrossSpaceAndTime
  ( acrossSpaceAndTime
  , AcrossSpaceAndTime(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Treachery.Cards as Cards (acrossSpaceAndTime)
import Arkham.Types.Classes
import Arkham.Types.Message
import Arkham.Types.Treachery.Attrs

newtype AcrossSpaceAndTime = AcrossSpaceAndTime TreacheryAttrs
  deriving anyclass IsTreachery
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

acrossSpaceAndTime :: TreacheryCard AcrossSpaceAndTime
acrossSpaceAndTime = treachery AcrossSpaceAndTime Cards.acrossSpaceAndTime

instance HasModifiersFor env AcrossSpaceAndTime

instance HasAbilities env AcrossSpaceAndTime where
  getAbilities i window (AcrossSpaceAndTime attrs) =
    getAbilities i window attrs

instance RunMessage env AcrossSpaceAndTime where
  runMessage msg t@(AcrossSpaceAndTime attrs) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ pushAll [DiscardTopOfDeck iid 3 Nothing, Discard (toTarget attrs)]
    _ -> AcrossSpaceAndTime <$> runMessage msg attrs
