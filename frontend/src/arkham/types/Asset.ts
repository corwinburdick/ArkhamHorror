import { JsonDecoder } from 'ts.data.json';

export interface Uses {
  amount: number; // eslint-disable-line
}

export const usesDecoder = JsonDecoder.object<Uses>({
  amount: JsonDecoder.number,
}, 'Uses');

export interface AssetContents {
  id: string;
  cardCode: string;
  name: string;
  health: number | null;
  healthDamage: number;
  sanity: number | null;
  sanityDamage: number;
  uses: Uses | null;
}

export const assetContentsDecoder = JsonDecoder.object<AssetContents>({
  id: JsonDecoder.string,
  cardCode: JsonDecoder.string,
  name: JsonDecoder.string,
  health: JsonDecoder.nullable(JsonDecoder.number),
  healthDamage: JsonDecoder.number,
  sanity: JsonDecoder.nullable(JsonDecoder.number),
  sanityDamage: JsonDecoder.number,
  uses: JsonDecoder.nullable(usesDecoder),
}, 'AssetContents');

export interface Asset {
  tag: string;
  contents: AssetContents;
}

export const assetDecoder = JsonDecoder.object<Asset>({
  tag: JsonDecoder.string,
  contents: assetContentsDecoder,
}, 'Asset');
