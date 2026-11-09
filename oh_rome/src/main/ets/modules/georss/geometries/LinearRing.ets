// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/geometries/LinearRing.java (Apache-2.0)
import { AbstractRing } from './AbstractRing';
import { PositionList } from './PositionList';

export class LinearRing extends AbstractRing {
  positionList: PositionList;

  constructor(positionList: PositionList = new PositionList()) {
    super();
    this.positionList = positionList;
  }

  clone(): LinearRing {
    return new LinearRing(this.positionList.clone());
  }
}
