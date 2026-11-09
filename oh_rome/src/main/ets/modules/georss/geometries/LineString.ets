// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/geometries/LineString.java (Apache-2.0)
import { AbstractCurve } from './AbstractCurve';
import { PositionList } from './PositionList';

export class LineString extends AbstractCurve {
  positionList: PositionList;

  constructor(positionList: PositionList = new PositionList()) {
    super();
    this.positionList = positionList;
  }

  clone(): LineString {
    return new LineString(this.positionList.clone());
  }
}
