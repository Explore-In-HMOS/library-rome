// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Status.java (Apache-2.0)

export enum StatusState {
  active = 'active',
  blocked = 'blocked',
  deleted = 'deleted'
}

export class Status {
  state: StatusState | null = null;
  reason: string | null = null;
}
