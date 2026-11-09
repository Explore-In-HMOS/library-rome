// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Restriction.java (Apache-2.0)

export enum RestrictionRelationship {
  ALLOW = 'allow',
  DENY = 'deny'
}

export enum RestrictionType {
  COUNTRY = 'country',
  SHARING = 'sharing',
  URI = 'uri'
}

export class Restriction {
  readonly relationship: RestrictionRelationship;
  readonly value: string;
  readonly type: RestrictionType | null;

  constructor(relationship: RestrictionRelationship | null, type: RestrictionType | null, value: string | null) {
    if (value === null || relationship === null) {
      throw new Error('Value and Relationship cannot be null.');
    }
    if (type === null && !(value === 'all' || value === 'none')) {
      throw new Error('Type is required if the value is other than \'all\' or \'none\'.');
    }
    this.relationship = relationship;
    this.type = type;
    this.value = value;
  }
}
