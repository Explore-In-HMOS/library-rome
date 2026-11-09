// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Price.java (Apache-2.0)

export enum PriceType {
  RENT = 'RENT',
  PURCHASE = 'PURCHASE',
  PACKAGE = 'PACKAGE',
  SUBSCRIPTION = 'SUBSCRIPTION'
}

export class Price {
  type: PriceType | null = null;
  price: string | null = null;
  currency: string | null = null;
  info: string | null = null;
}
